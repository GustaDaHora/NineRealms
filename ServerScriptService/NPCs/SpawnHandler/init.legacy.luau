-- NPC Spawning System

-- Services
local RS = game:GetService("ReplicatedStorage")
local NPCModels = RS:WaitForChild("NPCs")
local Modules = game:GetService("ServerStorage"):WaitForChild("Modules")
local NPCFolder = Modules:FindFirstChild("npc") or Modules:WaitForChild("npc")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Modules
local NPCInstance = require(NPCFolder.NPCInstance)
local PatrolModule = require(NPCFolder.NPCPatrolModule)
local FootstepsModule = require(NPCFolder.NPCFootstepsModule)

-- Constants
local TInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)
local template = RS.Templates.NpcNameTemplate
local animFolder = RS:WaitForChild("Animations")
local chars = workspace.Alives.Characters

-- NPC Pool Management
local MAX_CONCURRENT_SPAWNS = 5 -- Limit concurrent spawns to prevent lag spikes
local currentConcurrentSpawns = 0

-- Enemy Configuration Table
local enemyTypes = require(script.EnemyTypes)

-- Animations table (with shared animations and enemy-specific ones)
local animations = {
	EnemyReaction = {
		LightStun = animFolder:WaitForChild("Combat"):WaitForChild("EnemyReaction"):WaitForChild("LightStun"),
		HeavyStun = animFolder:WaitForChild("Combat"):WaitForChild("EnemyReaction"):WaitForChild("HeavyStun"),
	},

	Boars = {
		Attack = animFolder:WaitForChild("NPC"):WaitForChild("Boar"):WaitForChild("BoarAttack"),
	},
	Wolfs = {
		Attack = animFolder:WaitForChild("NPC"):WaitForChild("Wolf"):WaitForChild("WolfAttack"),
		Defend = nil,
	},
	Warrior = {
		Attack = animFolder:WaitForChild("NPC"):WaitForChild("Ordinary"):WaitForChild("SwordAttack"),
		Defend = animFolder:WaitForChild("NPC"):WaitForChild("Ordinary"):WaitForChild("SwordBlock"),
	},
	Default = {
		Attack = animFolder:WaitForChild("NPC"):WaitForChild("Ordinary"):WaitForChild("GauntletAttack"),
		Defend = animFolder:WaitForChild("NPC"):WaitForChild("Ordinary"):WaitForChild("GauntletBlock"),
	},
}

-- Validate configuration
for enemyName, config in pairs(enemyTypes) do
	if #config.modelsFolder:GetChildren() == 0 then
		warn("No " .. enemyName .. " templates available for spawning.")
	end

	if not config.spawnFolder:FindFirstChild("waypoints") or #config.spawnFolder.waypoints:GetChildren() == 0 then
		warn("No waypoints available for " .. enemyName .. " spawning.")
	end
end

-- Tracking tables
local aliveNPCs = {}
local playersInAreas = {}
local spawnTasks = {}

-- Initialize tracking tables for each enemy type
for enemyName, _ in pairs(enemyTypes) do
	aliveNPCs[enemyName] = {}
	playersInAreas[enemyName] = {}
	spawnTasks[enemyName] = nil
end

-- NPC object pooling (reuse NPCs instead of constantly creating/destroying)
local npcPools = {}

-- Initialize NPC pools
local function initializeNPCPools()
	for enemyName, config in pairs(enemyTypes) do
		npcPools[enemyName] = {}
	end
end

-- Get an NPC from the pool or create a new one
local function getOrCreateNPC(enemyType)
	local pool = npcPools[enemyType]
	if #pool > 0 then
		return table.remove(pool)
	end

	local enemyConfig = enemyTypes[enemyType]
	local modelTemplates = enemyConfig.modelsFolder:GetChildren()

	if #modelTemplates == 0 then
		warn("No templates available for " .. enemyType)
		return nil
	end

	return modelTemplates[math.random(1, #modelTemplates)]:Clone()
end

-- Return an NPC to the pool (instead of destroying)
local function returnNPCToPool(npc, enemyType)
	-- Only pool a certain number of NPCs to prevent memory bloat
	local MAX_POOLED = 10
	if #npcPools[enemyType] < MAX_POOLED then
		-- Reset the NPC state to be reused
		npc.Parent = nil
		table.insert(npcPools[enemyType], npc)
	else
		-- If pool is full, destroy the NPC
		npc:Destroy()
	end
end

-- Function to clear enemies with improved error handling and pooling
local function clearEnemies(enemyType)
	-- Cancel any active spawn task
	if spawnTasks[enemyType] then
		task.cancel(spawnTasks[enemyType])
		spawnTasks[enemyType] = nil
	end

	-- Remove NPCs gradually to prevent fps drops
	for i = #aliveNPCs[enemyType], 1, -1 do
		if next(playersInAreas[enemyType]) ~= nil then
			return -- Stop clearing if players entered the area
		end

		local npcInstance = aliveNPCs[enemyType][i]
		if npcInstance and npcInstance.npc then
			if npcInstance.npc.Parent then
				-- Return NPC to pool instead of destroying
				local npc = npcInstance.npc
				npcInstance:Cleanup()
				returnNPCToPool(npc, enemyType)
			else
				-- Just cleanup if NPC is already removed
				npcInstance:Cleanup()
			end
			table.remove(aliveNPCs[enemyType], i)
		end
		task.wait(0.2) -- Stagger despawning to prevent frame drops
	end
end

-- Function to spawn an enemy with improved error handling
local function spawnEnemy(enemyType)
	local enemyConfig = enemyTypes[enemyType]

	-- Don't spawn if we've reached the limit
	if #aliveNPCs[enemyType] >= enemyConfig.maxNPCs then
		return
	end

	-- Throttle concurrent spawns
	if currentConcurrentSpawns >= MAX_CONCURRENT_SPAWNS then
		task.delay(0.5, function() 
			spawnEnemy(enemyType) 
		end)
		return
	end

	currentConcurrentSpawns += 1

	-- Safe spawning with pcall
	local success, result = pcall(function()
		local waypointsFolder = enemyConfig.spawnFolder:FindFirstChild("waypoints")
		if not waypointsFolder then
			warn("No waypoints folder found for " .. enemyType)
			return false
		end

		local waypoints = waypointsFolder:GetChildren()
		if #waypoints == 0 then
			warn("No waypoints found for " .. enemyType)
			return false
		end

		local centerPart = waypointsFolder:FindFirstChild("Center")
		if not centerPart then
			centerPart = waypoints[1] -- Fallback to first waypoint
		end

		-- Select random level based on enemy configuration
		local level = math.random(enemyConfig.levelRange.min, enemyConfig.levelRange.max)
		enemyConfig.strength = level + 6

		-- Get NPC from pool or create new
		local newNPC = getOrCreateNPC(enemyType)
		if not newNPC then return false end

		newNPC.Name = enemyType .. " Lv" .. level

		-- Setup health bar UI
		local templateClone = template:Clone()
		templateClone.TitlesGui.DisplayName.Text = newNPC.Name
		local healthFillBar = templateClone.TitlesGui.Health.Fill
		local healthText = templateClone.TitlesGui.Health.TextLabel

		-- Make sure Humanoid exists
		if not newNPC:FindFirstChild("Humanoid") then
			warn("No Humanoid found in NPC model: " .. newNPC.Name)
			newNPC:Destroy()
			return false
		end

		healthText.Text = math.floor(newNPC.Humanoid.Health) .. "/" .. math.floor(newNPC.Humanoid.MaxHealth)

		local healthConnection
		healthConnection = newNPC.Humanoid.HealthChanged:Connect(function(health)
			if not newNPC or not newNPC.Parent or not newNPC:FindFirstChild("Humanoid") then
				if healthConnection then
					healthConnection:Disconnect()
				end
				return
			end

			local ratio = health / newNPC.Humanoid.MaxHealth
			local goalSize = UDim2.new(ratio, 0, healthFillBar.Size.Y.Scale, 0)
			TS:Create(healthFillBar, TInfo, { Size = goalSize }):Play()
			healthText.Text = math.floor(health) .. "/" .. math.floor(newNPC.Humanoid.MaxHealth)
		end)

		templateClone.Parent = newNPC:FindFirstChild("Head")

		-- Position at random waypoint (away from other NPCs if possible)
		local validWaypoints = {}
		for _, waypoint in ipairs(waypoints) do
			local tooClose = false
			for _, npcInst in ipairs(aliveNPCs[enemyType]) do
				if npcInst.npc and npcInst.npc.PrimaryPart and 
					(npcInst.npc.PrimaryPart.Position - waypoint.Position).Magnitude < 10 then
					tooClose = true
					break
				end
			end

			if not tooClose then
				table.insert(validWaypoints, waypoint)
			end
		end

		local randomWaypoint
		if #validWaypoints > 0 then
			randomWaypoint = validWaypoints[math.random(1, #validWaypoints)]
		else
			randomWaypoint = waypoints[math.random(1, #waypoints)]
		end

		-- Make sure NPC has a PrimaryPart
		if not newNPC.PrimaryPart then
			if newNPC:FindFirstChild("HumanoidRootPart") then
				newNPC.PrimaryPart = newNPC.HumanoidRootPart
			else
				warn("No PrimaryPart found in NPC model: " .. newNPC.Name)
				newNPC:Destroy()
				return false
			end
		end

		newNPC.Parent = enemyConfig.spawnFolder
		newNPC.PrimaryPart.CFrame = randomWaypoint.CFrame + Vector3.new(0, enemyConfig.spawnHeight, 0)

		-- Initialize NPCInstance (handles chase, death, drops, etc)
		local npcInstance = NPCInstance.new(newNPC, enemyType, enemyConfig, animations, randomWaypoint.Position)

		-- Store healthConnection for cleanup
		table.insert(npcInstance.connections, healthConnection)

		table.insert(aliveNPCs[enemyType], npcInstance)

		-- Initialize patrol/footsteps modules
		PatrolModule.InitializeNPC(newNPC)
		FootstepsModule.StartFootsteps(newNPC)

		return true
	end)

	currentConcurrentSpawns -= 1

	if not success or not result then
		warn("Failed to spawn " .. enemyType .. " enemy: " .. tostring(result))
	end
end

-- Improved spawning manager with coroutine tracking
local function manageSpawning(enemyType)
	if spawnTasks[enemyType] then
		-- Already spawning
		return
	end

	spawnTasks[enemyType] = task.spawn(function()
		while next(playersInAreas[enemyType]) ~= nil do
			local enemyConfig = enemyTypes[enemyType]

			-- Spawn up to max NPCs with rate limiting
			while #aliveNPCs[enemyType] < enemyConfig.maxNPCs do
				spawnEnemy(enemyType)
				task.wait(enemyConfig.spawnRate or 1) -- Use configured spawn rate
			end

			task.wait(1) -- Check population every second
		end

		-- No players left, clear NPCs
		clearEnemies(enemyType)
		spawnTasks[enemyType] = nil
	end)
end

-- More efficient player area tracking with debounce
local playerZoneDebounce = {}
local ZONE_CHANGE_DEBOUNCE = 0.5 -- seconds

local function updatePlayersInAreas()
	-- Track changes to avoid unnecessary processing
	local changes = false
	local oldPlayerCounts = {}

	-- Store previous player counts for comparison
	for enemyType, players in pairs(playersInAreas) do
		oldPlayerCounts[enemyType] = 0
		for _ in pairs(players) do
			oldPlayerCounts[enemyType] += 1
		end
	end

	-- Reset all area player tracking
	for enemyType, _ in pairs(enemyTypes) do
		playersInAreas[enemyType] = {}
	end

	-- Check all characters and assign to appropriate areas
	for _, char in ipairs(chars:GetChildren()) do
		local player = game.Players:GetPlayerFromCharacter(char)
		if player then
			local currentZone = char:GetAttribute("Zone")

			-- Check each enemy type's spawn area
			for enemyType, config in pairs(enemyTypes) do
				if currentZone == config.spawnArea.Name then
					playersInAreas[enemyType][player] = true
				end
			end
		end
	end

	-- Check for changes
	for enemyType, players in pairs(playersInAreas) do
		local newCount = 0
		for _ in pairs(players) do
			newCount += 1
		end

		if newCount ~= oldPlayerCounts[enemyType] then
			changes = true
		end
	end

	-- Only update spawning if there were changes
	if changes then
		-- Start or stop spawning as needed for each area
		for enemyType, playersInArea in pairs(playersInAreas) do
			if next(playersInArea) ~= nil then
				manageSpawning(enemyType)
			else
				clearEnemies(enemyType)
			end
		end
	end
end

-- Connect zone change events for all characters with debounce
local function connectCharacterZoneEvents(char)
	char:GetAttributeChangedSignal("Zone"):Connect(function()
		local player = game.Players:GetPlayerFromCharacter(char)
		if not player then return end

		-- Apply debounce to prevent rapid updates
		if playerZoneDebounce[player] then return end
		playerZoneDebounce[player] = true

		task.delay(ZONE_CHANGE_DEBOUNCE, function()
			updatePlayersInAreas()
			playerZoneDebounce[player] = nil
		end)
	end)
end

-- Add cleanup on player leaving
game.Players.PlayerRemoving:Connect(function(player)
	playerZoneDebounce[player] = nil
	updatePlayersInAreas()
end)

-- Connect existing characters
for _, char in ipairs(chars:GetChildren()) do
	connectCharacterZoneEvents(char)
end

-- Monitor new characters
chars.ChildAdded:Connect(function(char)
	-- Wait for character to be fully loaded
	task.wait(0.5)
	if char:IsA("Model") and char:FindFirstChild("Humanoid") then
		connectCharacterZoneEvents(char)
	end
end)

-- Initialize NPC pools
initializeNPCPools()

-- Heartbeat check for NPCs that may be stuck or invalid
local CLEANUP_INTERVAL = 30 -- seconds
local lastCleanupTime = 0

RunService.Heartbeat:Connect(function(deltaTime)
	lastCleanupTime += deltaTime

	-- Periodically check for stuck or broken NPCs
	if lastCleanupTime >= CLEANUP_INTERVAL then
		lastCleanupTime = 0

		for enemyType, npcs in pairs(aliveNPCs) do
			for i = #npcs, 1, -1 do
				local npcInstance = npcs[i]

				-- Remove invalid NPCs
				if not npcInstance or not npcInstance.npc or not npcInstance.npc.Parent then
					table.remove(npcs, i)
					continue
				end

				-- Check for stuck NPCs (not moving for too long)
				if npcInstance.lastPosition and npcInstance.stuckTime then
					local currentPos = npcInstance.npc.PrimaryPart.Position
					if (currentPos - npcInstance.lastPosition).Magnitude < 1 then
						npcInstance.stuckTime += CLEANUP_INTERVAL
						if npcInstance.stuckTime > 120 then -- 2 minutes stuck
							npcInstance:Cleanup()
							table.remove(npcs, i)
						end
					else
						npcInstance.stuckTime = 0
						npcInstance.lastPosition = currentPos
					end
				else
					npcInstance.lastPosition = npcInstance.npc.PrimaryPart.Position
					npcInstance.stuckTime = 0
				end
			end
		end
	end
end)

-- Initial update
updatePlayersInAreas()