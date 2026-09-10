local CharPage = {}

--// Services
local uis = game:GetService("UserInputService")

--// GUI References
local MainGui = script.Parent.Parent.Char

-- Basic Player Info
local playerName = MainGui:WaitForChild("PlayerName")
local Deaths = MainGui:WaitForChild("Deaths")
local Fame = MainGui:WaitForChild("Fame")
local Kills = MainGui:WaitForChild("Kills")
local PvPWins = MainGui:WaitForChild("PvPWins")
local PvPLosses = MainGui:WaitForChild("PvPLosses")
local Rank = MainGui:WaitForChild("Rank")
local Tier = MainGui:WaitForChild("Tier")
local TimePlayed = MainGui:WaitForChild("TimePlayed")
local Title = MainGui:WaitForChild("Title")

-- Info Frame
local infoFrame = MainGui:WaitForChild("Info")
local HackSilver = infoFrame:WaitForChild("HackSilver")
local Armor = infoFrame:WaitForChild("Armor")
local Souls = infoFrame:WaitForChild("Souls/MaxSouls")
local Weight = infoFrame:WaitForChild("Weight")

-- Stats Frame
local statsFrame = MainGui:WaitForChild("Stats")
local Agility = statsFrame:WaitForChild("Agility")
local Level = statsFrame:WaitForChild("Level")
local Strength = statsFrame:WaitForChild("Strength")
local Vitality = statsFrame:WaitForChild("Vitality")

-- Viewport Frame
local viewportFrame = MainGui:WaitForChild("Personagem"):WaitForChild("ViewportFrame")

--// Fetching Player Data
local player = game.Players.LocalPlayer
local PlayerData = player:WaitForChild("Data")

--// Character Display Variables
local MouseInDisplay, HoldInDisplay = false, false
local currentX

-- Function to determine Fame title
local function getFameTitle(fameValue)
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

-- Function to update the character page
local function updateCharPage()
	-- Set the GUI elements based on player data
	playerName.Text = player.Name
	Deaths.Text = "Deaths: " .. player:WaitForChild("Statistics"):WaitForChild("Deaths").Value
	Kills.Text = "Kills: " .. player:WaitForChild("Statistics"):WaitForChild("Kills").Value
	PvPWins.Text = "PvP Wins: " .. player:WaitForChild("Statistics"):WaitForChild("PvPWins").Value
	PvPLosses.Text = "PvP Losses: " .. player:WaitForChild("Statistics"):WaitForChild("PvPLosses").Value
	TimePlayed.Text = "Time Played: " .. player:WaitForChild("Statistics"):WaitForChild("TimePlayed").Value .. " mins"

	local fameValue = PlayerData:WaitForChild("Fame").Value
	local fameTitle = getFameTitle(fameValue)
	Fame.Text = "Fame: " .. fameTitle .. " (" .. fameValue .. ")"

	Rank.Text = "Rank: " .. PlayerData:WaitForChild("Rank").Value
	Tier.Text = "Tier: " .. PlayerData:WaitForChild("Tier").Value
	Title.Text = "Title: " .. (PlayerData:FindFirstChild("EquippedTitle") and PlayerData.EquippedTitle.Value or "None")

	-- Info frame values
	HackSilver.Text = "HackSilver: " .. PlayerData:WaitForChild("HackSilver").Value
	Armor.Text = "Armor: " .. (PlayerData:WaitForChild("HelmetArmor").Value + PlayerData:WaitForChild("ChestplateArmor").Value + PlayerData:WaitForChild("LeggingsArmor").Value + PlayerData:WaitForChild("BootsArmor").Value)
	Souls.Text = "Souls: " .. PlayerData:WaitForChild("Souls").Value .. "/" .. PlayerData:WaitForChild("MaxSouls").Value
	Weight.Text = "Weight: " .. PlayerData:WaitForChild("Weight").Value

	-- Stats frame values
	Level.Text = "Level: " .. PlayerData:WaitForChild("Level").Value
	Agility.Text = "Agility: " .. player:WaitForChild("Stats"):WaitForChild("Agility").Value
	Strength.Text = "Strength: " .. player:WaitForChild("Stats"):WaitForChild("Strength").Value
	Vitality.Text = "Vitality: " .. player:WaitForChild("Stats"):WaitForChild("Vitality").Value
end

function CharPage.Start()
	-- Update the UI when the character page is opened
	updateCharPage()

	-- Update UI whenever player stats change
	for _, data in pairs(PlayerData:GetChildren()) do
		if data:IsA("ValueBase") then
			data.Changed:Connect(updateCharPage)
		elseif data:IsA("Folder") then
			for _, subData in pairs(data:GetChildren()) do
				if subData:IsA("ValueBase") then
					subData.Changed:Connect(updateCharPage)
				end
			end
		end
	end
end

return CharPage
