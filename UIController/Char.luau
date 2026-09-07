-- UIController/Char.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local player = Players.LocalPlayer
local PlayerData = player:WaitForChild("Data")
local PlayerStats = player:WaitForChild("Stats")
local Statistics = player:WaitForChild("Statistics")

local CharPage = {}

-- Helper to determine Fame title from value
local function getFameTitle(fameValue: number): string
	if fameValue >= 1000 then
		return "Legend"
	elseif fameValue >= 750 then
		return "Champion"
	elseif fameValue >= 500 then
		return "Wanderer"
	elseif fameValue >= 250 then
		return "Outlaw"
	else
		return "Dreadlord"
	end
end

local function getSafeValue(parent: Instance, name: string, default: any)
	local child = parent:FindFirstChild(name)
	return child and child.Value or default
end

local function updateCharData()
	local fameVal = getSafeValue(PlayerData, "Fame", 0)
	local fameTitle = getFameTitle(fameVal)

	local helmet = getSafeValue(PlayerData, "HelmetArmor", 0)
	local chest = getSafeValue(PlayerData, "ChestplateArmor", 0)
	local legs = getSafeValue(PlayerData, "LeggingsArmor", 0)
	local boots = getSafeValue(PlayerData, "BootsArmor", 0)
	local totalArmor = helmet + chest + legs + boots

	local souls = getSafeValue(PlayerData, "Souls", 0)
	local maxSouls = getSafeValue(PlayerData, "MaxSouls", 100)

	store:dispatch(function(state)
		state.combatRecord = {
			kills = getSafeValue(Statistics, "Kills", 0),
			deaths = getSafeValue(Statistics, "Deaths", 0),
			pvpWins = getSafeValue(Statistics, "PvPWins", 0),
			pvpLosses = getSafeValue(Statistics, "PvPLosses", 0),
			timePlayed = tostring(getSafeValue(Statistics, "TimePlayed", 0)) .. " mins",
		}

		state.prestige = {
			title = getSafeValue(PlayerData, "EquippedTitle", "None"),
			rank = tostring(getSafeValue(PlayerData, "Rank", "None")),
			tier = getSafeValue(PlayerData, "Tier", 0),
			fame = fameTitle .. " (" .. fameVal .. ")",
		}

		state.playerStats = {
			strength = getSafeValue(PlayerStats, "Strength", 0),
			vitality = getSafeValue(PlayerStats, "Vitality", 0),
			agility = getSafeValue(PlayerStats, "Agility", 0),
			weaponPower = getSafeValue(PlayerStats, "WeaponPower", 0),
			weight = getSafeValue(PlayerData, "Weight", 0),
			armor = totalArmor,
			soulsRatio = souls .. "/" .. maxSouls,
			hackSilver = getSafeValue(PlayerData, "HackSilver", 0),
		}

		state.level = getSafeValue(PlayerData, "Level", state.level or 1)
		return state
	end)
end

function CharPage.Start()
	-- Initial synchronization
	updateCharData()

	-- Watch for changes in PlayerData, Stats, and Statistics
	local function attachListeners(folder: Instance)
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("ValueBase") then
				child.Changed:Connect(updateCharData)
			elseif child:IsA("Folder") then
				attachListeners(child)
			end
		end
		folder.ChildAdded:Connect(function(child)
			if child:IsA("ValueBase") then
				child.Changed:Connect(updateCharData)
			end
			updateCharData()
		end)
	end

	attachListeners(PlayerData)
	attachListeners(PlayerStats)
	attachListeners(Statistics)
end

return CharPage
