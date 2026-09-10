local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local modules = ServerStorage:WaitForChild("Modules")
local itemSpawner = require(modules.ItemSpawner)
local chestTemplates = ServerStorage:WaitForChild("Storage"):WaitForChild("Chests")
local spawnLocations = workspace:WaitForChild("ChestsLocations"):GetChildren()

local chestChances = {
	["Chest"] = 69,
	["Bronze Chest"] = 20,
	["Silver Chest"] = 10,
	["Golden Chest"] = 1,
}

local chestOrder = { "Chest", "Bronze Chest", "Silver Chest", "Golden Chest" }
local activeChests = {} -- [Model] = {spawnTime = os.time(), location = BasePart, upgradeTimer = thread}
local chestConnections = {} -- Store connections per chest for cleanup
local occupiedLocations = {} -- Track which locations have chests [BasePart] = true

-- Utility: pick chest based on weighted chance
local function getRandomChestName()
	local totalWeight = 0
	for _, weight in pairs(chestChances) do
		totalWeight += weight
	end
	local rand = math.random(1, totalWeight)
	local cumulative = 0
	for chestName, weight in pairs(chestChances) do
		cumulative += weight
		if rand <= cumulative then
			return chestName
		end
	end
end

-- Upgrade to next tier if possible
local function getUpgradedChestName(current)
	for i = 1, #chestOrder - 1 do
		if chestOrder[i] == current then
			return chestOrder[i + 1]
		end
	end
	return current -- already at max tier
end

-- Check if chest is at max tier
local function isMaxTier(chestName)
	return chestName == "Golden Chest"
end

-- Get available spawn locations (not occupied)
local function getAvailableLocations(excludeLocation)
	local available = {}
	for _, loc in ipairs(spawnLocations) do
		if not occupiedLocations[loc] and loc ~= excludeLocation then
			table.insert(available, loc)
		end
	end
	return available
end

-- Mark location as occupied/free
local function setLocationOccupied(location, occupied)
	occupiedLocations[location] = occupied or nil
end

-- Clean up chest connections and timers
local function cleanupChest(chest)
	if chestConnections[chest] then
		if chestConnections[chest].upgradeTimer then
			pcall(function()
				task.cancel(chestConnections[chest].upgradeTimer)
			end)
		end
		if chestConnections[chest].despawnTimer then
			pcall(function()
				task.cancel(chestConnections[chest].despawnTimer)
			end)
		end
		if chestConnections[chest].ancestryConnection then
			chestConnections[chest].ancestryConnection:Disconnect()
		end
		chestConnections[chest] = nil
	end

	-- Free up the location
	if activeChests[chest] then
		setLocationOccupied(activeChests[chest].location, false)
		activeChests[chest] = nil
	end
end

-- Chest opening animation
local function playChestOpenAnimation(chest)
	local chestTop = chest:FindFirstChild("ChestTop")
	if not chestTop then
		return
	end

	-- Store original pivot for reference
	local originalPivot = chestTop:GetPivot()

	-- Create a dummy part to tween (invisible part that drives the animation)
	local tweenPart = Instance.new("Part")
	tweenPart.Anchored = true
	tweenPart.CanCollide = false
	tweenPart.Transparency = 1
	tweenPart.Size = Vector3.new(0.1, 0.1, 0.1)
	tweenPart.CFrame = originalPivot
	tweenPart.Parent = workspace

	-- Opening rotation animation
	local rotationTarget = originalPivot * CFrame.Angles(0, 0, math.rad(-65))
	local openTween = TweenService:Create(
		tweenPart,
		TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ CFrame = rotationTarget }
	)

	-- Lift animation
	local liftTarget = rotationTarget + Vector3.new(0, 0.7, 1)
	local liftTween = TweenService:Create(
		tweenPart,
		TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = liftTarget }
	)

	-- Update model position continuously during animation
	local connection = game:GetService("RunService").Stepped:Connect(function()
		if tweenPart.Parent then
			chestTop:PivotTo(tweenPart.CFrame)
		end
	end)

	chest.ChestBottom.Wood.Sound.PlaybackSpeed = math.random(90, 110) / 100
	chest.ChestBottom.Wood.Sound:Play()

	-- Play animations in sequence
	openTween:Play()
	liftTween:Play()

	-- Clean up when lift animation completes
	task.wait(1)
	connection:Disconnect()
	tweenPart:Destroy()
end

-- Helper function to set up proximity prompts
local function setupChestPrompt(chest, location)
	for _, child in ipairs(chest:GetDescendants()) do
		if child:IsA("ProximityPrompt") then
			child.ObjectText = chest.Name
			child.ActionText = "Open Chest"
			child.Triggered:Connect(function(plr)
				child.Enabled = false
				-- Play opening animation first
				playChestOpenAnimation(chest)

				-- Wait spawning items
				task.wait(0.1)

				local parentPart = child.Parent
				local pos
				if parentPart and parentPart:IsA("BasePart") then
					pos = parentPart.Position + Vector3.new(math.random(1, 2), math.random(1, 2), math.random(1, 2))
				else
					pos = chest.PrimaryPart and chest.PrimaryPart.Position or chest.Position
				end
				itemSpawner.SpawnItem(pos, chest.Name)

				-- Clean up and despawn
				despawnChest(chest, location)
				child:Destroy()
			end)
		end
	end
end

-- Upgrade chest to next tier
local function upgradeChest(chestModel, data)
	if not (chestModel and chestModel.Parent and data) then
		return
	end

	local upgradedName = getUpgradedChestName(chestModel.Name)
	if upgradedName ~= chestModel.Name then
		local template = chestTemplates:FindFirstChild(upgradedName)
		if template then
			local newChest = template:Clone()
			newChest:SetPrimaryPartCFrame(chestModel:GetPrimaryPartCFrame())
			newChest.Parent = workspace

			-- Clean up old chest (but keep location occupied)
			if chestConnections[chestModel] then
				if chestConnections[chestModel].upgradeTimer then
					pcall(function()
						task.cancel(chestConnections[chestModel].upgradeTimer)
					end)
				end
				if chestConnections[chestModel].despawnTimer then
					pcall(function()
						task.cancel(chestConnections[chestModel].despawnTimer)
					end)
				end
				if chestConnections[chestModel].ancestryConnection then
					chestConnections[chestModel].ancestryConnection:Disconnect()
				end
				chestConnections[chestModel] = nil
			end
			activeChests[chestModel] = nil
			chestModel:Destroy()

			-- Set up new chest data (keep same location)
			activeChests[newChest] = {
				spawnTime = os.time(),
				location = data.location,
			}

			-- Initialize connections table
			chestConnections[newChest] = {}

			-- Set up ancestry connection for cleanup
			chestConnections[newChest].ancestryConnection = newChest.AncestryChanged:Connect(function()
				if not newChest.Parent then
					cleanupChest(newChest)
				end
			end)

			-- Check if this is max tier
			if isMaxTier(newChest.Name) then
				-- Golden Chest: Wait 20 minutes before despawning
				chestConnections[newChest].despawnTimer = task.delay(1200, function() -- 20 minutes
					despawnChest(newChest, data.location)
				end)
			else
				-- Regular upgrade timer: 10 minutes
				chestConnections[newChest].upgradeTimer = task.delay(600, function() -- 10 minutes
					upgradeChest(newChest, activeChests[newChest])
				end)
			end

			setupChestPrompt(newChest, data.location)
		end
	end
end

-- Despawn chest and spawn new one
function despawnChest(chest, location)
	if not (chest and chest.Parent) then
		return
	end

	cleanupChest(chest) -- This will free the location

	-- Fade out and destroy
	for _, part in ipairs(chest:GetDescendants()) do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(1), { Transparency = 1 }):Play()
		end
	end

	task.delay(1.2, function()
		if chest then
			chest:Destroy()
		end

		-- Spawn new chest in available location
		local available = getAvailableLocations(location)
		if #available > 0 then
			spawnChest(available[math.random(1, #available)])
		end
	end)
end

-- Spawn chest at a location
function spawnChest(location)
	if not location or occupiedLocations[location] then
		return -- Location is occupied or invalid
	end

	local chestName = getRandomChestName()
	local chestTemplate = chestTemplates:FindFirstChild(chestName)
	if not chestTemplate then
		return
	end

	local newChest = chestTemplate:Clone()
	newChest:SetPrimaryPartCFrame(location.CFrame)
	newChest.Parent = workspace

	-- Mark location as occupied
	setLocationOccupied(location, true)

	activeChests[newChest] = {
		spawnTime = os.time(),
		location = location,
	}

	-- Initialize connections table
	chestConnections[newChest] = {}

	-- Set up ancestry connection for cleanup
	chestConnections[newChest].ancestryConnection = newChest.AncestryChanged:Connect(function()
		if not newChest.Parent then
			cleanupChest(newChest)
		end
	end)

	-- Check if this is max tier (Golden Chest)
	if isMaxTier(newChest.Name) then
		-- Golden Chest: Wait 20 minutes before despawning
		chestConnections[newChest].despawnTimer = task.delay(1200, function() -- 20 minutes
			despawnChest(newChest, location)
		end)
	else
		-- Regular upgrade timer: 10 minutes
		chestConnections[newChest].upgradeTimer = task.delay(600, function() -- 10 minutes
			upgradeChest(newChest, activeChests[newChest])
		end)
	end

	setupChestPrompt(newChest, location)
end

-- Initial spawn on half of locations
local shuffled = table.clone(spawnLocations)
for i = #shuffled, 2, -1 do
	local j = math.random(1, i)
	shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
end

for i = 1, math.floor(#shuffled / 2) do
	spawnChest(shuffled[i])
end
