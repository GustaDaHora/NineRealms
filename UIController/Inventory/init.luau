-- Main Inventory Manager - Controls both systems
local RS = game:GetService("ReplicatedStorage")
local inputService = game:GetService("UserInputService")

local Hud = script.Parent.Parent

-- Module dependencies
local RapidInventory = require(script.RapidInventory)
local FullInventory = require(script.FullInventory)
local hotbarModule = require(script.Hotbar)

-- Shared references and variables
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local playerInventory = player.Backpack

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

local inventory = {}

-- Initialize both inventory systems
function inventory.Start()
	-- Initialize rapid inventory (equipment system)
	RapidInventory.Initialize(Hud, hotbarModule)

	-- Initialize full inventory system
	FullInventory.Initialize(Hud, hotbarModule)
	-- Set up global input handlers
	inputService.InputBegan:Connect(function(input, isTyping)
		if isTyping then return end

		if input.KeyCode == Enum.KeyCode.Quote or input.KeyCode == Enum.KeyCode.QuotedDouble or input.KeyCode == Enum.KeyCode.Backquote then
			RapidInventory.ToggleInventory()
		elseif input.KeyCode == Enum.KeyCode.Tab then
			FullInventory.OpenInventory()
		end
	end)

	-- Set up shared inventory change handlers
	playerInventory.ChildAdded:Connect(function()
		RapidInventory.UpdateInventory()
		FullInventory.UpdateInventory()
	end)

	playerInventory.ChildRemoved:Connect(function()
		RapidInventory.UpdateInventory()
		FullInventory.UpdateInventory()
	end)
	-- Code doesn't go beyond here
	-- Initial population
	RapidInventory.UpdateInventory()
	FullInventory.UpdateInventory()

	-- Set up default fist weapon if no main weapon equipped

	repeat
		task.wait(1)
	until char:GetAttribute("MainWeapon") or char:GetAttribute("MainShield")

	hotbarModule.EquipItem("Fist", itemsData["Fist"])
end

return inventory