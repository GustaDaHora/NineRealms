--// Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

--// Modules
local ProfileService = require(script:WaitForChild("ProfileService"))
local DataTableModule = require(script:WaitForChild("DataTable"))

--// Variables
local DataTable = DataTableModule.Data
local ProfileStore = ProfileService.GetProfileStore("PlayerData", DataTable)
local Profiles = {}
local PlayerFolders = {} -- Track player folders by UserId

--// Main

local DataHandler = {}

-- * Initialize
local function PlayerAdded(player)
	-- Load profile for player
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick() -- Player is kicked if the profile is released
		end)
		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			print(Profiles[player].Data)
			print(player.UserId)

			-- Increment login times
			profile.Data.LogInTimes = (profile.Data.LogInTimes or 0) + 1

			-- Create player data folder
			DataHandler:Create(player)

			-- A profile has been successfully loaded:	
			player:WaitForChild("Loading").Value = false
		else
			profile:Release() -- Player left before the profile loaded
		end
	else
		player:Kick() -- The profile couldn't be loaded
	end
end

function DataHandler:Init()
	-- Handle any players already in-game when the script starts
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerAdded, player)
	end

	-- Handle player joining
	Players.PlayerAdded:Connect(PlayerAdded)

	-- Handle player leaving
	Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player]

		-- Save the player's data
		self:Save(player)

		-- Clean up PlayerFolders for the player
		PlayerFolders[player.UserId] = nil

		if profile ~= nil then
			profile:Release() -- Release the profile when the player leaves
		end
	end)
end

function getProfile(player)
	assert(Profiles[player], string.format("Profile does not exist for %s", player.UserId))
	return Profiles[player]
end

function DataHandler:Create(player) -- !! Create Values in Player !!
	local profile = Profiles[player]

	-- Initialize PlayerFolders for this player
	PlayerFolders[player.UserId] = {}

	local DataFolder = Instance.new("Folder")
	DataFolder.Name = "Data"
	DataFolder.Parent = player

	-- Store the DataFolder in the player's folder list
	table.insert(PlayerFolders[player.UserId], DataFolder)

	for Name, Data in pairs(DataTable) do
		if typeof(Data) == "string" then
			local Value = Instance.new("StringValue")
			Value.Name = Name
			Value.Value = profile.Data[Name] or Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "number" then
			local Value = Instance.new("NumberValue")
			Value.Name = Name
			Value.Value = profile.Data[Name] or Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "boolean" then
			local Value = Instance.new("BoolValue")
			Value.Name = Name
			Value.Value = profile.Data[Name] or Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "table" then
			local TableFolder = Instance.new("Folder")
			TableFolder.Name = Name
			TableFolder.Parent = player

			-- Store the TableFolder in the player's folder list
			table.insert(PlayerFolders[player.UserId], TableFolder)

			for TableName, TableValue in pairs(Data) do
				if typeof(TableValue) == "string" then
					local Value = Instance.new("StringValue")
					Value.Name = TableName
					Value.Value = profile.Data[Name][TableName] or TableValue
					Value.Parent = TableFolder
				elseif typeof(TableValue) == "number" then
					local Value = Instance.new("NumberValue")
					Value.Name = TableName
					Value.Value = profile.Data[Name][TableName] or TableValue
					Value.Parent = TableFolder
				elseif typeof(TableValue) == "boolean" then
					local Value = Instance.new("BoolValue")
					Value.Name = TableName
					Value.Value = profile.Data[Name][TableName] or TableValue
					Value.Parent = TableFolder
				end
			end
		end
	end
end

function DataHandler:Save(player)  -- !! DataSaver !!
	if Profiles[player] then
		Profiles[player]:Save() -- Save the player's profile data
	end
end

-- * Essentials
function DataHandler:Get(player, key)
	local profile = getProfile(player)
	
	-- Default behavior for top-level keys
	assert(profile.Data[key], string.format("Data does not exist for %s", key))
	return profile.Data[key]
end

function DataHandler:UpdateInventory(player, inventoryTable)
	local profile = Profiles[player]
	if profile then
		profile.Data.Inventory = inventoryTable
	end
end

function DataHandler:Set(player, parent, key, value) -- !! Set Data of a Player !!
	local profile = Profiles[player]

	if parent.Name ~= "Data" then
		assert(profile.Data[parent.Name][key], string.format("Data does not exist for %s", player.UserId))
		assert(type(profile.Data[parent.Name][key]) == type(value), string.format("Value does not match type"))

		profile.Data[parent.Name][key] = value
	else
		assert(profile.Data[key], string.format("Data does not exist for %s", player.UserId))
		assert(type(profile.Data[key]) == type(value), string.format("Value does not match type"))

		profile.Data[key] = value
	end
end

function DataHandler:Update(player)
	local playerFolders = PlayerFolders[player.UserId]
	if playerFolders then
		for _, Folder in ipairs(playerFolders) do
			for _, Value in pairs(Folder:GetChildren()) do
				Value.Changed:Connect(function()
					-- Update the folder value in the profile but avoid saving instantly
					self:Set(player, Value.Parent, Value.Name, Value.Value)
				end)
			end
		end
	end
end

return DataHandler
