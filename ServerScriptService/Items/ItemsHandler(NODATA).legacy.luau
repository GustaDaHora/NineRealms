-- ItemsHandler(NODATA) data saving is disabled for better performance
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local itemsEvents = RS:WaitForChild("RE"):WaitForChild("Items")
local EquipItemEvent = itemsEvents:WaitForChild("EquipItem")
local DropItem = itemsEvents:WaitForChild("DropItem")
local GetItemEvent = itemsEvents:WaitForChild("ItemEvent")
local SummonItemEvent = itemsEvents:WaitForChild("SummonItemEvent")
local giveItemEvent = itemsEvents:WaitForChild("GiveItem")

local itemsFolder = game.Workspace:WaitForChild("ItemsFolder")
local items = SS:WaitForChild("Items")
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))
local lootDrops = RS:WaitForChild("LootDrops")
local lootTable = require(RS:WaitForChild("Modules"):WaitForChild("LootTable"))

local updateDelay = 1
local inventoryUpdateDebounce = {}
local playerInventories = {}

-- Function to spawn an item in the world
local function spawnItem(itemName, position)
	local itemInfo = lootTable[itemName]
	local itemData = itemsData[itemName]
	if not itemData then return warn("Invalid item:", itemName) end

	local clone = lootDrops:FindFirstChild(itemData.Rarity)
	if not clone then return warn("Rarity not found for item:", itemName) end

	clone = clone:Clone()
	clone.Name = itemName
	clone.Parent = itemsFolder

	clone.CFrame = typeof(position) == "Vector3" and CFrame.new(position) or position
	clone:SetAttribute("UniqueID", HttpService:GenerateGUID(false))
end

-- Function to update player inventory
local function updateInventory(player)
	if inventoryUpdateDebounce[player] then
		task.cancel(inventoryUpdateDebounce[player])
	end

	inventoryUpdateDebounce[player] = task.delay(updateDelay, function()
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then return end

		playerInventories[player] = {}

		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local itemName = tool.Name
				local amount = tool:FindFirstChild("Amount") and tool.Amount.Value or 1
				playerInventories[player][itemName] = amount
			end
		end

		inventoryUpdateDebounce[player] = nil
	end)
end

-- Function to give a player an item
local function giveItem(player, itemName)
	if not player or not itemName then return warn("Invalid parameters for giveItem") end

	local storedItem = items:FindFirstChild(itemName)
	if not storedItem then return warn("Item not found in storage:", itemName) end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	local itemInBackpack = backpack:FindFirstChild(itemName)
	if itemInBackpack then
		local amountValue = itemInBackpack:FindFirstChild("Amount") or itemInBackpack:FindFirstChildOfClass("IntValue")
		if amountValue then
			amountValue.Value += 1
		end
	else
		local clonedItem = storedItem:Clone()
		clonedItem.Parent = backpack
	end

	updateInventory(player)
end

-- Equip or Unequip Item
EquipItemEvent.OnServerEvent:Connect(function(player, itemName, equip)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChild("Backpack")
	if humanoid and backpack then
		local tool = backpack:FindFirstChild(itemName)
		if not tool then -- Tool is not in backpack because it is already equipped
			tool = character:FindFirstChild(itemName)
		end
		if tool then
			if equip then
				humanoid:EquipTool(tool)
			else
				humanoid:UnequipTools()
			end
		else
			warn(player.Name .. " tried to equip an item they don't own: " .. itemName)
		end
	end
end)

-- Table to store player drop cooldowns
local dropCooldowns = {}

DropItem.OnServerEvent:Connect(function(player, itemName)
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")

	-- Validate player & inventory
	if not character or not backpack then return end
	if not itemName or type(itemName) ~= "string" then return end  -- Prevent invalid input

	-- Check if the player is on cooldown (spam prevention)
	local currentTime = tick()
	if dropCooldowns[player] and currentTime - dropCooldowns[player] < 0.5 then
		--print(player.Name .. " is trying to drop items too fast!")
		return
	end
	dropCooldowns[player] = currentTime  -- Set cooldown

	-- Find the tool in the player's backpack
	local tool = backpack:FindFirstChild(itemName)
	if not tool or not tool:IsA("Tool") then
		warn(player.Name .. " tried to drop an invalid item:", itemName)
		return
	end

	-- Check item quantity (Prevent dropping more than they own)
	local amountValue = tool:FindFirstChild("Amount") or tool:FindFirstChildOfClass("IntValue")
	if amountValue and amountValue.Value > 1 then
		amountValue.Value -= 1  -- Reduce stack size
	else
		tool:Destroy()  -- Remove from inventory
	end

	-- Spawn the item in the world
	spawnItem(itemName, character.HumanoidRootPart.CFrame * CFrame.new(0, 2, -5))
end)

local pickedUpItems = {} -- Store picked item IDs to prevent duplication

GetItemEvent.OnServerEvent:Connect(function(player, itemName, uniqueId)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	if pickedUpItems[uniqueId] then
		--warn(player.Name .. " attempted to pick up " .. itemName .. " multiple times!")
		return
	end

	local foundItem
	for _, item in ipairs(itemsFolder:GetChildren()) do
		local id = item:GetAttribute("UniqueID")
		if id and id == uniqueId then
			foundItem = item
			break
		end
	end

	if not foundItem then return warn("Item not found:", uniqueId) end

	local distance = (character.HumanoidRootPart.Position - foundItem.Position).Magnitude
	if distance > 40 then
		warn("Suspicious activity: ", player.Name, "tried to pick up", foundItem.Name, "from", distance, "studs away!")
		player:Kick("Exploit Detected")
		return
	end

	-- Prevent duplicate pickup attempts
	pickedUpItems[uniqueId] = true

	-- Destroy item immediately
	foundItem:Destroy()

	-- Give item to player
	giveItem(player, itemName)
end)

giveItemEvent.Event:Connect(giveItem)

-- Player Join Handling
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		repeat task.wait(1) until not player:FindFirstChild("Loading") or not player.Loading.Value
		task.wait(1)
		playerInventories[player] = {}

		player.Backpack.ChildAdded:Connect(function() updateInventory(player) end)
		player.Backpack.ChildRemoved:Connect(function() updateInventory(player) end)
	end)
end)

-- Summon Item Event
SummonItemEvent.Event:Connect(spawnItem)

local itemsToSpawn = {
	{ name = "Silver", count = 10 },
	{ name = "Iron", count = 10 },
	{ name = "Wood", count = 10 },
	{ name = "Iron Sword", count = 1 },
	{ name = "Silver Sword", count = 1 },
	{ name = "Rusty Sword", count = 1},
	{ name = "Stormcarver", count = 1},
	{ name = "Heavy Helmet", count = 1 },
	{ name = "Heavy Iron Axe", count = 1 },
	{ name = "Heavy Chestplate", count = 1 },
	{ name = "Heavy Leggings", count = 1 },
	{ name = "Heavy Boots", count = 1 },
	{ name = "Firefly Rod", count = 1 },
}

for _, itemInfo in ipairs(itemsToSpawn) do
	for i = 1, itemInfo.count do
		spawnItem(itemInfo.name, workspace.SpawnLocation.Position + Vector3.new(0,2,0))
	end
end
