local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local itemsEvents = RS:WaitForChild("RE"):WaitForChild("Items")
local EquipItemEvent = itemsEvents:WaitForChild("EquipItem")
local DropItem = itemsEvents:WaitForChild("DropItem")
local GetItemEvent = itemsEvents:WaitForChild("ItemEvent")
local SummonItemEvent = itemsEvents:WaitForChild("SummonItemEvent")

local itemsFolder = game.Workspace:WaitForChild("ItemsFolder")
local items = SS:WaitForChild("Items")
local lootDrops = RS:WaitForChild("LootDrops")
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))
local lootTable = require(RS:WaitForChild("Modules"):WaitForChild("LootTable"))
local dataHandler = require(SS:WaitForChild("Modules"):WaitForChild("DataHandler"))

dataHandler:Init()

local updateDelay = 1
local inventoryUpdateDebounce = {}
local playerInventories = {}

-- Function to spawn an item in the world
local function spawnItem(itemName, position)
	local itemInfo = lootTable[itemName]
	local itemData = itemsData[itemName]
	if not itemData then
		return warn("Invalid item:", itemName)
	end

	local Data = require(itemData)
	local clone = lootDrops:FindFirstChild(Data.Rarity)
	if not clone then
		return warn("Rarity not found for item:", itemName)
	end

	clone = clone:Clone()
	clone.Name = itemName
	clone.Parent = itemsFolder
	itemData:Clone().Parent = clone

	clone.CFrame = typeof(position) == "Vector3" and CFrame.new(position) or position

	local uniqueId = Instance.new("StringValue")
	uniqueId.Name = "UniqueId"
	uniqueId.Value = HttpService:GenerateGUID(false)
	uniqueId.Parent = clone
end

-- Function to update player inventory and save it
local function updateInventory(player)
	if inventoryUpdateDebounce[player] then
		task.cancel(inventoryUpdateDebounce[player])
	end

	inventoryUpdateDebounce[player] = task.delay(updateDelay, function()
		local backpack = player:FindFirstChild("Backpack")
		if not backpack then
			return
		end

		playerInventories[player] = {}

		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local itemName = tool.Name
				local amount = tool:FindFirstChild("Amount") and tool.Amount.Value or 1
				playerInventories[player][itemName] = amount
			end
		end

		dataHandler:UpdateInventory(player, playerInventories[player])
		inventoryUpdateDebounce[player] = nil
	end)
end

-- Function to give a player an item and save it
local function giveItem(player, itemName)
	if not player or not itemName then
		return warn("Invalid parameters for giveItem")
	end

	local storedItem = items:FindFirstChild(itemName)
	if not storedItem then
		return warn("Item not found in storage:", itemName)
	end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then
		return
	end

	local itemInBackpack = backpack:FindFirstChild(itemName)
	if itemInBackpack then
		local amountValue = itemInBackpack:FindFirstChild("Amount") or itemInBackpack:FindFirstChildOfClass("IntValue")
		if amountValue then
			amountValue.Value += 1
		end
	else
		local clonedItem = storedItem:Clone()
		clonedItem.Parent = backpack

		local itemData = itemsData[itemName]
		if itemData then
			local clonedData = itemData:Clone()
			clonedData.Parent = clonedItem
		end
	end

	updateInventory(player)
end

-- Equip or Unequip Item
EquipItemEvent.OnServerEvent:Connect(function(player, itemName, equip)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChild("Backpack")

	if humanoid and backpack then
		if equip then
			local tool = backpack:FindFirstChild(itemName)
			if tool then
				humanoid:EquipTool(tool)
			end
		else
			humanoid:UnequipTools()
		end
	end
end)

-- Drop Item Event
DropItem.OnServerEvent:Connect(function(player, itemName)
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")
	if not character or not backpack then
		return
	end

	local tool = backpack:FindFirstChild(itemName)
	if not tool or not tool:IsA("Tool") then
		return warn("Invalid item drop:", itemName)
	end

	local amountValue = tool:FindFirstChild("Amount") or tool:FindFirstChildOfClass("IntValue")
	if amountValue and amountValue.Value > 1 then
		amountValue.Value -= 1
	else
		tool:Destroy()
	end

	spawnItem(itemName, character.HumanoidRootPart.CFrame * CFrame.new(0, 2, -5))
end)

-- Pick Up Item Event
GetItemEvent.OnServerEvent:Connect(function(player, itemData, uniqueId)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end

	local foundItem
	for _, item in ipairs(itemsFolder:GetChildren()) do
		local id = item:FindFirstChild("UniqueId")
		if id and id.Value == uniqueId then
			foundItem = item
			break
		end
	end

	if not foundItem then
		return warn("Item not found:", uniqueId)
	end

	local distance = (character.HumanoidRootPart.Position - foundItem.Position).Magnitude
	if distance > 45 then
		warn("Suspicious activity: ", player.Name, "tried to pick up", foundItem.Name, "from", distance, "studs away!")
		player:Kick("Exploit Detected")
		return
	end

	foundItem:Destroy()
	giveItem(player, itemData)
end)

-- Player Join Handling
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		repeat
			task.wait(1)
		until not player:FindFirstChild("Loading") or not player.Loading.Value
		task.wait(1)
		playerInventories[player] = {}

		local savedInventory = dataHandler:Get(player, "Inventory") or {}
		for itemName, amount in pairs(savedInventory) do
			if itemName ~= "Fist" then
				giveItem(player, itemName)
			end
		end

		-- Track inventory changes
		player.Backpack.ChildAdded:Connect(function()
			updateInventory(player)
		end)
		player.Backpack.ChildRemoved:Connect(function()
			updateInventory(player)
		end)
	end)
end)

-- Summon Item Event
SummonItemEvent.Event:Connect(spawnItem)

-- Auto-Spawn Loot Table Items (For Testing)
for _, itemData in pairs(lootTable) do
	spawnItem(itemData.item, CFrame.new(7, 2 + math.random(1, 5), 15))
end
