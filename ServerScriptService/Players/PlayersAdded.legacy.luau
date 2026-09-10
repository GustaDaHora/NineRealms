-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cached paths
local playerFolder = Workspace:WaitForChild("Alives"):WaitForChild("Characters")
local NameTemplate = ReplicatedStorage:WaitForChild("Templates"):WaitForChild("NameTemplate")
local respawnEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("RespawnRE")

-- Constants
local FAME_TITLES = {
	[1000] = "Legend",
	[750] = "Champion",
	[500] = "Wanderer",
	[250] = "Outlaw",
	[0] = "Dreadlord",
}

local Attributes = {
	-- Combos
	["Combo"] = 0,

	-- Combat Multipliers
	["DamageMultiplier"] = 1.0,
	["DefenseMultiplier"] = 1.0,
	["SpeedMultiplier"] = 1.0,
	["CooldownReduction"] = 0.0,
	["DamageReduction"] = 1.0,

	-- Elemental Resistances
	["FireResistance"] = 1.0,
	["IceResistance"] = 1.0,
	["ElectricResistance"] = 1.0,
	["WaterResistance"] = 1.0,
	["WindResistance"] = 1.0,
	["EarthResistance"] = 1.0,
	["DarkResistance"] = 1.0,
	["LightResistance"] = 1.0,

	-- Status Effects
	["Burning"] = false,
	["Poisoned"] = false,
	["Frozen"] = false,
	["Stunned"] = false,
	["Slowed"] = false,
	["Blocking"] = false,
}

local PlayersOnline = {}

local XP_GROWTH_FACTOR = 1.4
local BASE_XP = 100
local BASE_HEALTH = 100
local HEALTH_PER_DURABILITY = 6

-- Store attribute connections for cleanup
local playerConnections = {}

-- Setup character collision groups
local function setupCollision(character, groupName)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = groupName
		end
	end
end

-- Determine fame title based on fame value
local function getFameTitle(fameValue)
	for threshold, title in pairs(FAME_TITLES) do
		if fameValue >= threshold then
			return title
		end
	end
	return FAME_TITLES[0] -- Default title
end

-- Calculate XP required for a specific level
local function getXpForLevel(level)
	return BASE_XP * math.pow(XP_GROWTH_FACTOR, level - 1)
end

-- Update character's maximum health based on durability stat
local function updateMaxHealth(player)
	local durability = player:WaitForChild("Stats"):WaitForChild("Vitality").Value
	local character = player.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	local maxHealth = BASE_HEALTH + (durability - 1) * HEALTH_PER_DURABILITY
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
end

-- Handle player leveling and stat increases
local function updateLevel(player)
	local levelData = player:WaitForChild("Data"):WaitForChild("Level")
	local xpData = player.Data:WaitForChild("Experience")
	local stats = player:WaitForChild("Stats")

	local level = levelData.Value
	local xp = xpData.Value

	while xp >= getXpForLevel(level) do
		-- Level up process
		xp = xp - getXpForLevel(level)
		level = level + 1

		-- Update stats
		stats.Strength.Value += 1
		stats.Vitality.Value += 1
		stats.Agility.Value += 1
	end

	-- Update the actual values
	levelData.Value = level
	xpData.Value = xp

	-- Update health based on new stats
	updateMaxHealth(player)
end

-- Setup character name display
local function setupNameDisplay(character, player)
	local nameDisplay = NameTemplate:Clone()
	local titlesGui = nameDisplay:WaitForChild("TitlesGui")

	-- Set display name
	titlesGui.DisplayName.Text = player.DisplayName

	-- Set fame title
	local fameValue = player:WaitForChild("Data"):WaitForChild("Fame").Value or 500
	titlesGui.Fame.Text = getFameTitle(fameValue)

	-- Set custom title
	local titles = player:WaitForChild("Titles")
	titlesGui.Title.Text = titles:WaitForChild("CurrentTitle").Value or ""

	-- Parent to character head
	nameDisplay.Parent = character:WaitForChild("Head")
end

-- Initialize character attributes
local function initializeAttributes(plr, char)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	for attribute, value in pairs(Attributes) do
		char:SetAttribute(attribute, value)
	end

	-- Set health
	local maxHealth = plr:WaitForChild("Data"):WaitForChild("MaxHealth").Value
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
end

-- Clean up existing connections for a player
local function cleanupPlayerConnections(player)
	if playerConnections[player] then
		for _, connection in pairs(playerConnections[player]) do
			if connection and connection.Connected then
				connection:Disconnect()
			end
		end
		playerConnections[player] = nil
	end
end

-- Reset player combat state
local function resetCombatState(player)
	local data = player:WaitForChild("Data")

	-- Reset combat flags
	if data:FindFirstChild("InCombat") then
		data.InCombat.Value = false
	end

	if data:FindFirstChild("LeftCombat") then
		data.LeftCombat.Value = false
	end

	-- Reset any combat timers or debuffs
	if player.Character then
		player.Character:SetAttribute("InCombat", false)
		player.Character:SetAttribute("Combo", 0)

		-- Reset status effects
		for attribute, defaultValue in pairs(Attributes) do
			if typeof(defaultValue) == "boolean" then
				player.Character:SetAttribute(attribute, defaultValue)
			end
		end
	end
end

local function updateAttributes(plr, char)
	if not char then
		return
	end

	-- Clean up any existing connections for this player
	cleanupPlayerConnections(plr)
	playerConnections[plr] = {}

	local data = plr:WaitForChild("Data")
	local stats = plr:WaitForChild("Stats")
	local hotBar = plr:WaitForChild("HotBar")

	repeat
		task.wait(1)
	until hotBar.MainWeapon and hotBar.MainShield

	if hotBar.MainWeapon.Value == "" then 
		hotBar.MainWeapon.Value = "Fist" 
	end

	-- Setup weapon and shield attributes with connections
	char:SetAttribute("MainWeapon", hotBar.MainWeapon.Value)
	playerConnections[plr]["MainWeapon"] = hotBar.MainWeapon.Changed:Connect(function()
		if char.Parent then
			char:SetAttribute("MainWeapon", hotBar.MainWeapon.Value)
		end
	end)

	char:SetAttribute("MainShield", hotBar.MainShield.Value)
	playerConnections[plr]["MainShield"] = hotBar.MainShield.Changed:Connect(function()
		if char.Parent then
			char:SetAttribute("MainShield", hotBar.MainShield.Value)
		end
	end)

	-- Update combat-related attributes with connections
	local combatAttributes = {
		"WeaponPower", "CritChance", "CritDamage", 
		"HelmetArmor", "ChestplateArmor", "LeggingsArmor", "BootsArmor", "MaxStamina"
	}

	for _, attributeName in ipairs(combatAttributes) do
		char:SetAttribute(attributeName, data[attributeName].Value)
		playerConnections[plr][attributeName] = data[attributeName].Changed:Connect(function()
			if char.Parent then	
				char:SetAttribute(attributeName, data[attributeName].Value)
			end
		end)
	end

	-- Update core stats with connections
	local coreStats = {"Strength", "Vitality", "Agility", "Luck"}

	for _, statName in ipairs(coreStats) do
		char:SetAttribute(statName, stats[statName].Value)
		playerConnections[plr][statName] = stats[statName].Changed:Connect(function()
			if char.Parent then
				char:SetAttribute(statName, stats[statName].Value)
			end
		end)
	end

	-- Special handling for Vitality affecting health
	playerConnections[plr]["VitalityHealth"] = stats.Vitality.Changed:Connect(function()
		updateMaxHealth(plr)
	end)

	-- Update stamina attribute
	local charMaxStamina = char:GetAttribute("MaxStamina")
	char:SetAttribute("Stamina", charMaxStamina)
end

-- Handle character setup for a player
local function setupCharacter(character, player)
	-- Set parent folder
	character.Parent = playerFolder

	-- Get loading state
	local loading = player:FindFirstChild("Loading")
	if loading then
		repeat
			task.wait(1)
		until not loading.Value
	else
		error("Loading bool not found" .. tostring(loading))
	end

	-- Setup character collision
	setupCollision(character, "Players")

	-- Setup name display
	setupNameDisplay(character, player)

	-- Initialize attributes
	initializeAttributes(player, character)
	updateAttributes(player, character)

	-- Update level and health
	updateLevel(player)
	updateMaxHealth(player)

	for _, child in pairs(character:GetDescendants()) do
		if child:IsA("CharacterMesh") then
			child:Destroy()
		end
	end

	local hum:Humanoid = character.Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
end

-- Handle experience changes
local function setupExperienceListener(player)
	local xp = player:WaitForChild("Data"):WaitForChild("Experience")
	xp.Changed:Connect(function()
		updateLevel(player)
	end)
end

-- Enhanced respawn function
local function respawnPlayer(player)
	print("Respawning player: " .. player.Name)

	-- Clean up existing connections
	cleanupPlayerConnections(player)

	-- Reset combat state
	resetCombatState(player)

	-- Destroy existing character if it exists
	if player.Character then
		player.Character:Destroy()
	end

	-- Reset loading state
	local loading = player:FindFirstChild("Loading")
	if not loading then
		loading = Instance.new("BoolValue")
		loading.Name = "Loading"
		loading.Parent = player
	end
	loading.Value = true

	-- Reset any temporary data modifications
	local data = player:WaitForChild("Data")
	if data:FindFirstChild("LeftCombat") then
		data.LeftCombat.Value = false
	end

	-- Respawn the player
	task.defer(function()
		-- Mark loading as complete after a short delay
		task.wait(1)
		loading.Value = false

		-- Load new character
		player:LoadCharacter()
	end)
end

-- Main initialization
local function initializePlayer(player)
	if not PlayersOnline[player] then
		PlayersOnline[player] = true

		-- Create loading flag
		local loading = Instance.new("BoolValue")
		loading.Name = "Loading"
		loading.Value = true
		loading.Parent = player

		local leftCombat = player:WaitForChild("Data", 5):WaitForChild("LeftCombat", 5)
		if leftCombat then
			leftCombat.Value = false -- Reset left combat state
		end

		-- Setup experience listener
		setupExperienceListener(player)

		-- Mark loading as complete after a short delay
		task.delay(1, function()
			loading.Value = false
		end)
	end

	-- Setup character added handling
	player.CharacterAdded:Connect(function(character)
		setupCharacter(character, player)
	end)

	-- Defer character loading to avoid race conditions
	task.defer(function()
		player:LoadCharacter()
	end)
end

-- Enhanced respawn event handler
respawnEvent.OnServerEvent:Connect(function(player)
	print("Respawn event received from: " .. player.Name)
	respawnPlayer(player)
end)

-- Initialize
Players.PlayerAdded:Connect(initializePlayer)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up connections
	cleanupPlayerConnections(player)

	PlayersOnline[player] = nil
	local character = player.Character

	-- Cleanup player data if needed
	if character then
		if character:GetAttribute("InCombat") then
			local data = player:WaitForChild("Data")
			data.Fame.Value = math.max(0, data.Fame.Value - 50) -- Decrease fame on leaving in combat
			data.HackSilver.Value = math.max(0, data.HackSilver.Value - 200) -- Decrease hack silver on leaving in combat
			data.LeftCombat.Value = true -- Mark player as left combat
			print("Player " .. player.Name .. " left in combat")
		end
		character:Destroy()
	end
end)

-- Handle existing players (in case the script restarts)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		initializePlayer(player)
	end)
end