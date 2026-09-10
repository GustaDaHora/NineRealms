-- RapidInventory Module - Handles the quick equipment system
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local dropItemEvent = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("DropItem")
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

local RapidInventory = {}

-- Module variables
local Hud, hotbarModule
local equipment, backpackFrame, backpack, itemTemplate, IconButton
local equipmentFrame, selectedItem, selectedItemLabel, selectedItemDescription
local selectedItemStatus, equipButton

local player = game.Players.LocalPlayer
local playerInventory = player.Backpack
local inventoryOpened = false
local toggleDebounce = false
local showViewport = false
local itemType

local rarityColors = {
	Common = Color3.fromRGB(57, 50, 43),
	Uncommon = Color3.fromRGB(50, 200, 50),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(150, 70, 200),
	Legendary = Color3.fromRGB(255, 110, 50)
}

-- Initialize the rapid inventory system
function RapidInventory.Initialize(hudRef, hotbarRef)
	Hud = hudRef
	hotbarModule = hotbarRef

	-- Get UI references
	equipment = Hud:WaitForChild("Equipment")
	backpackFrame = equipment:WaitForChild("BackpackFrame")
	backpack = backpackFrame:WaitForChild("BackPack")
	itemTemplate = backpack:WaitForChild("ItemTemplate")
	IconButton = backpackFrame:WaitForChild("Icon")

	equipmentFrame = equipment:WaitForChild("EquipmentFrame")
	selectedItem = equipmentFrame:WaitForChild("SelectedItem")
	selectedItemLabel = selectedItem:WaitForChild("ItemName")
	selectedItemDescription = selectedItem:WaitForChild("Description")
	selectedItemStatus = selectedItem:WaitForChild("StatusFrame")
	equipButton = selectedItem:WaitForChild("EquipButton")

	-- Set up event handlers
	setupEventHandlers()
end

-- Display selected item information
local function displaySelectedItem(itemName, itemData)
	-- Clean up previous viewports
	for _, child in ipairs(selectedItem:GetChildren()) do
		if child:IsA("ViewportFrame") and child.Name ~= "ViewportF" then
			child:Destroy()
		end
	end

	-- Set basic item information
	selectedItemLabel.Text = itemName or "Unknown Item"
	selectedItemDescription.Text = itemData.Description or "No description available"

	-- Update status displays
	local function updateStatus(statusName, statusValue)
		local statusLabel = selectedItemStatus:FindFirstChild(statusName)
		if statusLabel then
			statusLabel.Text = statusValue and (statusName .. " +" .. statusValue) or ""
		end
	end

	updateStatus("Armor", itemData.Stats.Armor)
	updateStatus("ElemRes", itemData.Stats.ElemRes)
	updateStatus("Power", itemData.Stats.Power)
	updateStatus("Weight", itemData.Stats.Weight)
	updateStatus("Regen", itemData.Stats.Regen)

	-- Handle viewport display
	selectedItem:WaitForChild("ViewportF").Visible = true
	itemType = itemData.Type or "Unknown"

	if itemType ~= "" then
		local storedViewport = RS.Viewports:FindFirstChild(itemName)
		if storedViewport then
			local newViewport = storedViewport:Clone()
			newViewport.Position = UDim2.new(0.305, 0, 0.437, 0)
			newViewport.Parent = selectedItem
			selectedItem:WaitForChild("ViewportF").Visible = false
		else
			warn("Viewport for " .. itemName .. " not found!")
		end
	end
end

-- Check if item already exists in UI
local function isItemAlreadyConfigured(itemName)
	for _, child in pairs(backpack:GetChildren()) do
		if child:IsA("TextButton") and child.Name == itemName then
			return child
		end
	end
	return nil
end

-- Create item button for rapid inventory
local function createItemButton(itemName, itemData)
	local clonedItem = itemTemplate:Clone()
	clonedItem.Name = itemName
	clonedItem.Text = showViewport and "" or itemName
	clonedItem.Visible = true
	clonedItem.UIStroke.Color = rarityColors[itemData.Rarity] or Color3.fromRGB(242, 183, 5)
	clonedItem.Parent = backpack


	local storedViewport = RS.Viewports:FindFirstChild(itemName)
	if storedViewport then
		local newViewport = storedViewport:Clone()
		newViewport.UIStroke:Destroy()
		newViewport.Size = UDim2.new(1, 0, 1, 0)
		newViewport.Name = "ViewportFrame"
		newViewport.Visible = showViewport
		newViewport.Parent = clonedItem
	else
		warn("Viewport for " .. itemName .. " not found!")
	end

	-- Set up click events
	clonedItem.MouseButton1Click:Connect(function()
		displaySelectedItem(itemName, itemData)
	end)

	clonedItem.MouseButton2Click:Connect(function()
		if itemName ~= "Fist" then
			dropItemEvent:FireServer(itemName)
		end
	end)
end

-- Update the rapid inventory display
function RapidInventory.UpdateInventory()
	-- Clear previous items
	for _, child in ipairs(backpack:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then 
			child:Destroy() 
		end
	end

	-- Populate with current inventory items
	for _, item in pairs(playerInventory:GetChildren()) do
		if item:IsA("Tool") then
			-- FIX: Use item.Name instead of item as the key
			local itemData = itemsData[item.Name]
			if not itemData then
				warn("Not Found itemData for " .. item.Name)
			end
			-- Add error checking to help debug
			if not itemData then
				warn("No item data found for:", item.Name)
				continue
			end

			local amountValue = item:FindFirstChild("Amount") or item:FindFirstChildOfClass("IntValue")

			local existingItem = isItemAlreadyConfigured(item.Name)
			if existingItem then
				-- Update existing item
				if amountValue and amountValue.Value > 1 then
					existingItem.AmountLabel.Text = "X" .. tostring(amountValue.Value)
					existingItem.AmountLabel.Visible = true
				else
					existingItem.AmountLabel.Visible = false
				end
				existingItem.Text = item.Name

				-- Toggle viewport visibility
				local viewportFrame = existingItem:FindFirstChild("ViewportFrame")
				if viewportFrame then
					viewportFrame.Visible = showViewport
					existingItem.Text = showViewport and "" or item.Name
				end
			else
				createItemButton(item.Name, itemData)
			end
		end
	end
end

-- Toggle inventory open/close
function RapidInventory.ToggleInventory()
	if toggleDebounce then return end
	toggleDebounce = true

	if not inventoryOpened then
		RapidInventory.UpdateInventory()

		-- Animate opening
		backpackFrame:TweenPosition(UDim2.new(0.845, 0, 0.5, 0), "Out", "Sine", 0.2)
		equipmentFrame:TweenPosition(UDim2.new(0.155, 0, 0.5, 0), "Out", "Sine", 0.2)
		TweenService:Create(backpackFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
		inventoryOpened = true
	else
		-- Animate closing
		backpackFrame:TweenPosition(UDim2.new(1.3, 0, 0.5, 0), "Out", "Sine", 0.2)
		equipmentFrame:TweenPosition(UDim2.new(-0.3, 0, 0.5, 0), "Out", "Sine", 0.2)
		TweenService:Create(backpackFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		inventoryOpened = false
	end

	task.delay(0.25, function() toggleDebounce = false end)
end

-- Set up event handlers
function setupEventHandlers()
	-- Icon button (toggle viewport/text mode)
	IconButton.MouseButton1Click:Connect(function()
		showViewport = not showViewport
		RapidInventory.UpdateInventory()
		IconButton.Text = showViewport and "Text" or "Icon"
	end)

	-- Equip button
	equipButton.MouseButton1Click:Connect(function()
		if selectedItemLabel.Text ~= "..." and selectedItemLabel.Text ~= "" then
			local selectedItemData = { Type = itemType }

			hotbarModule.EquipItem(selectedItemLabel.Text, selectedItemData)
		end
	end)
end

return RapidInventory