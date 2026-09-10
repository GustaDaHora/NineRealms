local NPCSmartChaseModule = {}
local Players = game:GetService("Players")
local CombatModule = require(game.ServerStorage.Modules.npc.NPCCombatModule)

-- Shared table to track which NPCs are attacking each player
local AttackingNPCs = {}
-- Table to track when NPCs last attempted to attack
local LastAttackAttempt = {}

-- Per-player queue for NPCs waiting to attack (by arrival order)
local AttackQueue = {}
local MAX_ATTACKERS = 2 -- Only this many NPCs can attack at once

-- Helper: Get or create the attack queue for a player
local function getAttackQueue(player)
	if not AttackQueue[player] then
		AttackQueue[player] = {}
	end
	return AttackQueue[player]
end

-- Helper: Add NPC to player's attack queue if not present
local function addToAttackQueue(player, npc)
	local queue = getAttackQueue(player)
	for _, v in ipairs(queue) do
		if v == npc then
			return
		end
	end
	table.insert(queue, npc)
end

-- Helper: Remove NPC from player's attack queue
local function removeFromAttackQueue(player, npc)
	local queue = getAttackQueue(player)
	for i, v in ipairs(queue) do
		if v == npc then
			table.remove(queue, i)
			break
		end
	end
end

-- Helper: Is this NPC allowed to attack (is it in the first N in the queue)?
local function canAttackNow(player, npc)
	local queue = getAttackQueue(player)
	for i = 1, math.min(MAX_ATTACKERS, #queue) do
		if queue[i] == npc then
			return true
		end
	end
	return false
end

-- Helper: Clean up queue when NPC dies or leaves
local function cleanupNPCFromAllQueues(npc)
	for player, queue in pairs(AttackQueue) do
		removeFromAttackQueue(player, npc)
	end
end

-- Helper: Clean up queue when player leaves
Players.PlayerRemoving:Connect(function(player)
	AttackQueue[player] = nil
end)

-- Find players within a certain range, considering vision angle
local function FindPlayersInRange(npc, detectionRange, visionAngle)
	local playersInRange = {}
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")

	if not npcRoot then
		return {}
	end

	local npcPos = npcRoot.Position
	local npcLookVector = npcRoot.CFrame.LookVector

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChild("Humanoid")

		if root and humanoid and humanoid.Health > 0 and not char:GetAttribute("Fallen") then
			local playerPos = root.Position
			local dirToPlayer = (playerPos - npcPos).Unit
			local distSq = (playerPos - npcPos).Magnitude ^ 2

			-- Check if player is within detection range
			if distSq <= detectionRange ^ 2 then
				local dotProduct = npcLookVector:Dot(dirToPlayer)

				-- If visionAngle is 360, detect in all directions
				-- Otherwise, check if player is within the vision cone
				if visionAngle >= 360 or dotProduct >= math.cos(math.rad(visionAngle / 2)) then
					table.insert(playersInRange, {
						character = char,
						distance = math.sqrt(distSq),
						dotProduct = dotProduct,
					})
				end
			end
		end
	end

	-- Sort by distance
	table.sort(playersInRange, function(a, b)
		return a.distance < b.distance
	end)

	return playersInRange
end

-- Rotate NPC to face target
local function RotateTowardsTarget(npcRoot, targetPos)
	if not npcRoot then
		return
	end
	local velocity = npcRoot.Velocity
	if velocity.Magnitude < 5 then
		-- Check if NPC already has a BodyGyro; if not, create one
		local bodyGyro = npcRoot:FindFirstChild("BodyGyro")
		if not bodyGyro then
			bodyGyro = Instance.new("BodyGyro")
			bodyGyro.MaxTorque = Vector3.new(0, 100000, 0) -- Only allow rotation on Y-axis
			bodyGyro.P = 10000 -- Power of the rotation
			bodyGyro.Parent = npcRoot
		end

		-- Set the rotation target
		bodyGyro.CFrame = CFrame.lookAt(npcRoot.Position, Vector3.new(targetPos.X, npcRoot.Position.Y, targetPos.Z))
	end
end

-- Function to make NPC defend/parry
local function Defend(npc, defendAnim)
	if not defendAnim or npc:GetAttribute("Defending") or npc:GetAttribute("Stunned") then
		return
	end

	npc:SetAttribute("Blocking", true)
	npc:SetAttribute("Parrying", true)
	task.delay(0.1, function()
		npc:SetAttribute("Parrying", false)
	end)

	-- Play defend animation
	local animator = npc.Humanoid:FindFirstChildOfClass("Animator")
	if animator then
		local animTrack = animator:LoadAnimation(defendAnim)
		animTrack:Play()

		-- Stop defending after animation finishes
		task.delay(animTrack.Length * 0.5, function()
			npc:SetAttribute("Defending", false)
			animTrack:Stop()
		end)
	else
		-- Failsafe if no animator
		task.delay(1, function()
			npc:SetAttribute("Defending", false)
		end)
	end
end

-- Function to make NPC circle around target with improved positioning
-- Improved function to make NPC circle around target dynamically
local function CircleAroundTarget(npc, npcHum, targetPos, npcPos, radius)
	-- Get the NPC's ID or create a unique identifier
	local npcId = npc:GetAttribute("NPCId")
	if not npcId then
		npcId = math.random(1, 1000) -- Generate random ID if none exists
		npc:SetAttribute("NPCId", npcId)
	end

	-- Calculate current angle relative to the target
	local currentAngle = math.atan2(npcPos.Z - targetPos.Z, npcPos.X - targetPos.X)

	-- Each NPC should follow a different direction based on ID
	local clockwise = (npcId % 2 == 0)

	-- Determine movement angle (amount to move around the circle)
	local moveAngle = clockwise and -0.2 or 0.2 -- How much to move around the circle

	-- Calculate the new position based on the current angle plus movement
	local newAngle = currentAngle + moveAngle

	-- Calculate the next position on the circle
	local newPos =
		Vector3.new(targetPos.X + math.cos(newAngle) * radius, targetPos.Y, targetPos.Z + math.sin(newAngle) * radius)

	-- Store the target angle for tracking
	npc:SetAttribute("CircleAngle", newAngle)

	-- Move to the calculated position
	npcHum:MoveTo(newPos)

	-- Return the position so we can check if we've reached it
	return newPos
end
-- Function to handle combat with player
local function HandleCombat(npc, npcHum, target, punchDistance, sound, animations, strength, hitboxSize)
	if not target then
		return false
	end
	local root = target:FindFirstChild("HumanoidRootPart")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	local targetHum = target:FindFirstChild("Humanoid")
	if not root or not npcRoot or not targetHum or targetHum.Health <= 0 then
		return false
	end

	local targetPlayer = Players:GetPlayerFromCharacter(target)
	if targetPlayer then
		addToAttackQueue(targetPlayer, npc)
	end

	local targetPos = root.Position
	local npcPos = npcRoot.Position
	local dist = (targetPos - npcPos).Magnitude

	-- Check if we're close enough to attack
	if dist <= punchDistance then
		npc:SetAttribute("Chasing", false)
		npc:SetAttribute("Fighting", true)
		npcHum.WalkSpeed = 12

		-- Only attack if this NPC is allowed by the queue
		if targetPlayer and not canAttackNow(targetPlayer, npc) then
			-- Not this NPC's turn: circle or wait
			CircleAroundTarget(npc, npcHum, targetPos, npcPos, 8 + math.random() * 4)
			RotateTowardsTarget(npcRoot, targetPos)
			return true
		end

		-- M1 spam detection: if player is attacking rapidly, increase block chance
		local blockChance = 0.2 -- base chance
		if target:GetAttribute("LastAttackTime") and target:GetAttribute("LastAttackType") == "M1" then
			local now = os.clock()
			local last = target:GetAttribute("LastAttackTime")
			if now - last < 0.25 then -- rapid spam
				blockChance = 0.7
			end
		end

		local playerAttacking = target:GetAttribute("Attacking") or false
		local defendAnim
		local function hasSword(n)
			for _, child in ipairs(n:GetChildren()) do
				if string.find(child.Name, "Sword") then
					return true
				end
			end
			return false
		end
		if hasSword(npc) then
			defendAnim = animations.Warrior.Defend
		else
			defendAnim = animations.Default.Defend
		end
		local canDefend = defendAnim ~= nil

		if playerAttacking and canDefend and math.random() < blockChance and not npc:GetAttribute("AttackDebounce") then
			Defend(npc, defendAnim)
			return true
		elseif not npc:GetAttribute("AttackDebounce") then
			npc:SetAttribute("AttackDebounce", true)
			CombatModule.Hit(npc, sound, animations, strength, hitboxSize)
			task.delay(0.5, function()
				npc:SetAttribute("AttackDebounce", false)
			end)
			return true
		end
	end
	return false
end

-- Function to check if ambush is possible
local function CheckForAmbush(npc, playersInRange, npcHum, npcRoot)
	-- Look for players who can't see the NPC
	for _, playerData in ipairs(playersInRange) do
		local player = playerData.character
		local playerRoot = player:FindFirstChild("HumanoidRootPart")

		if playerRoot then
			local playerLookVector = playerRoot.CFrame.LookVector
			local dirToNPC = (npcRoot.Position - playerRoot.Position).Unit
			local dotProduct = playerLookVector:Dot(dirToNPC)

			-- Player is not looking at NPC (behind player or to the side)
			if dotProduct < 0.1 then
				-- Choose a point behind the player for ambush
				local ambushPoint

				-- Improved ambush positioning - different NPCs go to different sides
				if npc:GetAttribute("NPCId") then
					-- Even IDs go left, odd IDs go right
					local sideOffset = (npc:GetAttribute("NPCId") % 2 == 0) and playerRoot.CFrame.RightVector * 3
						or playerRoot.CFrame.RightVector * -3

					ambushPoint = playerRoot.Position - (playerLookVector * 5) + sideOffset
				else
					ambushPoint = playerRoot.Position - (playerLookVector * 5)
				end

				-- Set ambush attributes
				npc:SetAttribute("Ambushing", true)
				npcHum.WalkSpeed = 16 -- Faster but not too fast

				-- Move to ambush point
				npcHum:MoveTo(ambushPoint)
				return true
			end
		end
	end

	return false
end

-- Main function to initialize smart NPC behavior
function NPCSmartChaseModule.InitializeNPC(npc, initialPosition, punchDistance, sound, animations, strength, hitboxSize)
	local npcHum = npc:WaitForChild("Humanoid")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	local running = true
	local maxDistanceFromCenter = 200
	local state = "idle"
	local currentTarget = nil
	local detectionRange = 30
	local sightCheckInterval = 1
	local lastSightCheck = 0
	local lastStateChange = 0

	-- Give each NPC a unique ID
	npc:SetAttribute("NPCId", math.random(1, 1000))

	-- Initialize attributes
	npc:SetAttribute("Chasing", false)
	npc:SetAttribute("Fighting", false)
	npc:SetAttribute("Patrolling", true)
	npc:SetAttribute("Ambushing", false)
	npc:SetAttribute("Defending", false)
	npc:SetAttribute("AttackDebounce", false)
	npc:SetAttribute("GroupLeader", false)

	-- Initialize LastAttackAttempt for this NPC
	LastAttackAttempt[npc] = 0

	-- Clean up when NPC is destroyed
	npc.AncestryChanged:Connect(function()
		if not npc:IsDescendantOf(workspace) then
			running = false
			cleanupNPCFromAllQueues(npc)

			-- Clean up attack tracking
			for _, playerRegistry in pairs(AttackingNPCs) do
				playerRegistry[npc] = nil
			end

			-- Clean up LastAttackAttempt
			LastAttackAttempt[npc] = nil
		end
	end)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		if AttackingNPCs[player] then
			AttackingNPCs[player][npc] = nil
		end

		if currentTarget == player.Character then
			currentTarget = nil
			state = "idle"
		end
	end)

	-- Main behavior loop
	task.spawn(function()
		while running do
			if npc:GetAttribute("Stunned") then
				task.wait(1)
				continue
			end

			local now = os.clock()
			local checkForNewTargets = now - lastSightCheck >= sightCheckInterval

			-- Calculate distance from spawn point
			local distanceFromCenter = (npcRoot.Position - initialPosition).Magnitude

			-- Return to spawn if too far away
			if distanceFromCenter > maxDistanceFromCenter then
				state = "returning"
				currentTarget = nil
				npc:SetAttribute("Chasing", false)
				npc:SetAttribute("Fighting", false)
				npc:SetAttribute("Ambushing", false)
				npc:SetAttribute("Patrolling", true)
				npcHum.WalkSpeed = 16
				npcHum:MoveTo(initialPosition)

				-- Wait until we get close to center
				repeat
					task.wait(0.5)
					if not npc:IsDescendantOf(workspace) then
						return
					end
				until (npcRoot.Position - initialPosition).Magnitude < 10 or not running

				state = "idle"
				task.wait(1)
				continue
			end

			-- Check for new targets periodically
			if checkForNewTargets then
				lastSightCheck = now
				local playersInRange = FindPlayersInRange(npc, detectionRange, 200) -- 200 degree vision

				-- If we already have a target, prioritize keeping that target
				if
					currentTarget
					and currentTarget:IsDescendantOf(workspace)
					and currentTarget:FindFirstChild("Humanoid")
					and currentTarget.Humanoid.Health > 0
					and not currentTarget:GetAttribute("Fallen")
				then
					local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")

					if targetRoot and (targetRoot.Position - npcRoot.Position).Magnitude <= detectionRange * 1.5 then
						-- Keep current target, but still check for ambush opportunities
						if now - lastStateChange > 5 and not npc:GetAttribute("Fighting") then
							local ambushed = CheckForAmbush(npc, playersInRange, npcHum, npcRoot)
							if ambushed then
								state = "ambushing"
								lastStateChange = now
							end
						end
					else
						-- Target moved too far, reset
						currentTarget = nil
						state = "idle"
					end
				else
					-- No valid target, look for new targets
					if #playersInRange > 0 then
						-- Find new target
						currentTarget = playersInRange[1].character

						-- Decide initial state based on situation
						if now - lastStateChange > 3 then
							if math.random() < 0.4 then
								-- Try to ambush
								local ambushed = CheckForAmbush(npc, playersInRange, npcHum, npcRoot)
								if ambushed then
									state = "ambushing"
								else
									state = "chasing"
								end
							else
								state = "chasing"
							end
							lastStateChange = now
						end
					else
						-- No players in range
						currentTarget = nil

						-- Go back to patrolling if we haven't changed state recently
						if now - lastStateChange > 3 and state ~= "patrolling" then
							state = "patrolling"
							npc:SetAttribute("Patrolling", true)
							lastStateChange = now
						end
					end
				end
			end

			-- Execute behavior based on current state
			if state == "idle" then
				npcHum.WalkSpeed = 12
				npc:SetAttribute("Chasing", false)
				npc:SetAttribute("Fighting", false)
				npc:SetAttribute("Ambushing", false)
				npc:SetAttribute("Patrolling", false)

				-- Occasionally change to patrolling
				if math.random() < 0.1 then
					state = "patrolling"
					npc:SetAttribute("Patrolling", true)
					lastStateChange = now
				end
			elseif state == "patrolling" then
				npc:SetAttribute("Patrolling", true)
				npcHum.WalkSpeed = 12
			elseif state == "ambushing" then
				-- Ambush logic is handled in CheckForAmbush
				-- If ambush is completed, transition to attacking
				if currentTarget and npc:GetAttribute("Ambushing") then
					local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")

					if targetRoot and (targetRoot.Position - npcRoot.Position).Magnitude <= punchDistance * 1.2 then
						npc:SetAttribute("Ambushing", false)
						state = "attacking"
						lastStateChange = now
					end
				else
					npc:SetAttribute("Ambushing", false)
					state = currentTarget and "chasing" or "idle"
				end
			elseif state == "chasing" then
				if currentTarget then
					local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")

					if targetRoot then
						-- Rotate to face target
						RotateTowardsTarget(npcRoot, targetRoot.Position)

						-- Try to handle combat first
						local inCombat = HandleCombat(
							npc,
							npcHum,
							currentTarget,
							punchDistance,
							sound,
							animations,
							strength,
							hitboxSize
						)

						if not inCombat then
							-- Not in combat range, chase target
							npc:SetAttribute("Chasing", true)
							npc:SetAttribute("Fighting", false)
							npcHum.WalkSpeed = 20
							npcHum:MoveTo(targetRoot.Position)
						end
					else
						state = "idle"
					end
				else
					state = "idle"
				end
			elseif state == "attacking" then
				if currentTarget then
					-- Handle combat returns true if we're in combat range
					local inCombat =
						HandleCombat(npc, npcHum, currentTarget, punchDistance, sound, animations, strength, hitboxSize)

					if not inCombat then
						-- If not in combat range anymore, go back to chasing
						state = "chasing"
					end
				else
					state = "idle"
				end
			end

			task.wait(0.2) -- Run the behavior loop more frequently for responsiveness
		end
	end)
end

return NPCSmartChaseModule
