-- FullInventory Module - Handles the detailed inventory system with filtering
local RS = game:GetService("ReplicatedStorage")
local inputService = game:GetService("UserInputService")
local dropItemEvent = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("DropItem")
local equipEvent = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("Equipment")

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

local FullInventory = {}

-- Module variables
local Hud, hotbarModule
local inventoryFrame, loadout, equipView
local armorsList, weaponsList, attributes, subOptions
local equippedArmor, armorsInfo, info, stats, equippedWeapon, weaponsInfo, plrName, equipmentOptions, IconButton, WeaponsOptionsFrame, ArmorOptionsFrame, ShieldsButton, ArmorsButton, ResourceButton, FoodButton, WeaponsButton, ArtifactButton

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local playerInventory = player.Backpack

local activeConnections = {}
local slotConnections = {}
local hidden = {}

-- Filter state tracking
local armorFilters = {
	Shields = true,
	Armors = true,
	Resource = true
}

local weaponFilters = {
	Food = true,
	Weapons = true,
	Artifact = true
}

-- Icon display state
local showIcons = false

local rarityColors = {
	Common = Color3.fromRGB(57, 50, 43),
	Uncommon = Color3.fromRGB(50, 200, 50),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(150, 70, 200),
	Legendary = Color3.fromRGB(255, 110, 50)
}

-- Update button appearance based on filter state
local function updateButtonAppearance(button, isActive)
	if isActive then
		button.BackgroundColor3 = Color3.fromRGB(255,255,255) -- Green for active
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		button.TextColor3 = Color3.fromRGB(242, 183, 5)
	end
end

-- Determine item category for filtering
local function getItemCategory(itemData)
	local itemType = itemData.Type

	-- Armor categories
	if itemType == "Shield" or itemType == "HeavyShield" or itemType == "LightShield" then
		return "Shields"
	elseif itemType == "Helmet" or itemType == "Chestplate" or itemType == "Leggings" or itemType == "Boots" then
		return "Armors"
	elseif itemType == "Resource" or itemType == "Material" then
		return "Resource"

		-- Weapon categories
	elseif itemType == "Food" or itemType == "Consumable" then
		return "Food"
	elseif itemType == "Sword" or itemType == "HeavyAxe" or itemType == "Gauntlet" then
		return "Weapons"
	elseif itemType == "Artifact" then
		return "Artifact"
	end

	-- Default fallback
	return nil
end

-- Update armor list visibility based on filters
local function updateArmorListVisibility()
	for _, child in ipairs(armorsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then
			local itemName = child.Name
			local tool = playerInventory:FindFirstChild(itemName)

			if tool then
				local itemData = itemsData[itemName]
				if not itemData then
					warn("Not Found itemData for " .. itemName)
				end
				local category = getItemCategory(itemData)

				if category and armorFilters[category] ~= nil then
					child.Visible = armorFilters[category]
				else
					child.Visible = true -- Show items that don't fit categories
				end
			end
		end
	end
end

-- Toggle icon display for all inventory items
local function toggleIconDisplay()
	-- Toggle icons in armor list
	for _, child in ipairs(armorsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then
			if showIcons then child.TextTransparency = 1 else child.TextTransparency = 0 end
			local viewport = child:FindFirstChild("ViewportFrame")
			if viewport then
				viewport.Visible = showIcons
			end
		end
	end

	-- Toggle icons in weapons list
	for _, child in ipairs(weaponsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then
			if showIcons then child.TextTransparency = 1 else child.TextTransparency = 0 end
			local viewport = child:FindFirstChild("ViewportFrame")
			if viewport then
				viewport.Visible = showIcons
			end
		end
	end
end

local function updateWeaponListVisibility()
	for _, child in ipairs(weaponsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then
			local itemName = child.Name
			local tool = playerInventory:FindFirstChild(itemName)

			if tool then
				local itemData = itemsData[itemName]
				if not itemData then
					warn("Not Found itemData for " .. itemName)
				end
				local category = getItemCategory(itemData)

				if category and weaponFilters[category] ~= nil then
					child.Visible = weaponFilters[category]
				else
					child.Visible = true -- Show items that don't fit categories
				end
			end
		end
	end
end

-- Update weapons and artifacts display
local function updateWeaponsDisplay()
	repeat
		task.wait(1)
	until char:GetAttribute("MainWeapon")

	local itemName = player:GetAttribute("MainWeapon")
	if not itemName then
		itemName = Hud.Hotbar.MainWeapon.Text
	end
	local itemData = itemsData[itemName]
	if itemData then 
		stats.WeaponPower.Text = "WeaponPower: " .. itemData.Stats.Power 
	end

	local storedViewport = RS.Viewports:FindFirstChild(itemName)
	if storedViewport then
		local newViewport = storedViewport:Clone()
		newViewport.UIStroke:Destroy()
		newViewport.Size = UDim2.new(1, 0, 1, 0)
		newViewport.Rotation = -90
		newViewport.Name = "ViewportFrame"
		newViewport.Visible = showIcons -- Apply current icon visibility state
		newViewport.Parent = equipView.Weapons.MainWeapon
	else
		warn("Viewport for " .. itemName .. " not found!")
	end

	-- Handle artifacts
	local equippedArtifacts = player:WaitForChild("EquippedArtifacts")
	local Artifacts = {
		Artifact1 = equippedArtifacts:WaitForChild("Artifact1"),
		Artifact2 = equippedArtifacts:WaitForChild("Artifact2"),
		Artifact3 = equippedArtifacts:WaitForChild("Artifact3"),
	}

	for _, artifact in pairs(Artifacts) do
		if artifact.Value ~= "" then
			weaponsInfo[artifact.Name].Text = artifact.Value
		end
	end
end

-- Update player stats display
local function updateStatsDisplay()
	local plrStats = player:WaitForChild("Stats")
	local Stats = {
		Strength = plrStats:WaitForChild("Strength"),     
		Vitality = plrStats:WaitForChild("Vitality"),     
		Agility = plrStats:WaitForChild("Agility")      
	}

	for _, stat in pairs(Stats) do
		if stat.Value ~= "" then
			stats[stat.Name].Text = stat.Name .. ": " .. stat.Value
		end
	end

	-- Update other player data
	local plrData = player:WaitForChild("Data")
	info.Souls.Text = "Souls: " .. plrData:WaitForChild("Souls").Value
	info.Weight.Text = "Weight: " .. plrData:WaitForChild("Weight").Value
	info.HackSilver.Text = "HackSilver: " .. plrData:WaitForChild("HackSilver").Value
end

-- Set up event handlers
local function setupEventHandlers()
	equipEvent.OnClientEvent:Connect(function(itemName)
		FullInventory.UpdateInventory()
	end)
end

-- Display item inspection details
local function displayItemInspection(itemName, itemData)
	attributes.ItemName.Text = itemName
	attributes.Rarity.Text = itemData.Rarity
	attributes.Description.Text = itemData.Description
	attributes.MarketValue.Text = "Market Value: " .. (itemData.BasePrice or "")

	-- Format stats
	local ItemStats = ""
	if next(itemData.Stats) then
		for key, value in pairs(itemData.Stats) do
			ItemStats = ItemStats .. key .. ": " .. tostring(value) .. ", "
		end
		ItemStats = ItemStats:sub(1, -3) -- Remove last comma
	else
		ItemStats = "No stats available"
	end
	attributes.Stats.Text = ItemStats

	-- Handle viewport
	if attributes.ViewportStroke:FindFirstChild("ViewportFrame") then
		attributes.ViewportStroke.ViewportFrame:Destroy()
	end

	local storedViewport = RS.Viewports:FindFirstChild(itemName)
	if storedViewport then
		local newViewport = storedViewport:Clone()
		newViewport.UIStroke:Destroy()
		newViewport.Size = UDim2.new(1, 0, 1, 0)
		newViewport.Name = "ViewportFrame"
		newViewport.Visible = showIcons -- Apply current icon visibility state
		newViewport.Parent = attributes.ViewportStroke
	else
		warn("Viewport for " .. itemName .. " not found!")
	end
end

-- Set up filter button event handlers
local function setupFilterButtons()
	-- Icon toggle button
	IconButton.MouseButton1Click:Connect(function()
		showIcons = not showIcons
		updateButtonAppearance(IconButton, showIcons)
		toggleIconDisplay()
	end)

	-- Armor filter buttons
	ShieldsButton.MouseButton1Click:Connect(function()
		armorFilters.Shields = not armorFilters.Shields
		updateButtonAppearance(ShieldsButton, armorFilters.Shields)
		updateArmorListVisibility()
	end)

	ArmorsButton.MouseButton1Click:Connect(function()
		armorFilters.Armors = not armorFilters.Armors
		updateButtonAppearance(ArmorsButton, armorFilters.Armors)
		updateArmorListVisibility()
	end)

	ResourceButton.MouseButton1Click:Connect(function()
		armorFilters.Resource = not armorFilters.Resource
		updateButtonAppearance(ResourceButton, armorFilters.Resource)
		updateArmorListVisibility()
	end)

	-- Weapon filter buttons
	FoodButton.MouseButton1Click:Connect(function()
		weaponFilters.Food = not weaponFilters.Food
		updateButtonAppearance(FoodButton, weaponFilters.Food)
		updateWeaponListVisibility()
	end)

	WeaponsButton.MouseButton1Click:Connect(function()
		weaponFilters.Weapons = not weaponFilters.Weapons
		updateButtonAppearance(WeaponsButton, weaponFilters.Weapons)
		updateWeaponListVisibility()
	end)

	ArtifactButton.MouseButton1Click:Connect(function()
		weaponFilters.Artifact = not weaponFilters.Artifact
		updateButtonAppearance(ArtifactButton, weaponFilters.Artifact)
		updateWeaponListVisibility()
	end)

	-- Initialize button appearances
	updateButtonAppearance(IconButton, showIcons)
	updateButtonAppearance(ShieldsButton, armorFilters.Shields)
	updateButtonAppearance(ArmorsButton, armorFilters.Armors)
	updateButtonAppearance(ResourceButton, armorFilters.Resource)
	updateButtonAppearance(FoodButton, weaponFilters.Food)
	updateButtonAppearance(WeaponsButton, weaponFilters.Weapons)
	updateButtonAppearance(ArtifactButton, weaponFilters.Artifact)
end

-- Set up context menu for inventory items
local function setupItemContextMenu(itemName, itemData)
	-- Disconnect previous connections
	if activeConnections.Equip then activeConnections.Equip:Disconnect() end
	if activeConnections.Inspect then activeConnections.Inspect:Disconnect() end
	if activeConnections.Dispose then activeConnections.Dispose:Disconnect() end

	-- Position context menu
	local pos = inputService:GetMouseLocation()
	local relativePosition = pos - loadout.AbsolutePosition
	subOptions.Position = UDim2.new(0, relativePosition.X, 0, relativePosition.Y - 50)
	subOptions.Visible = true

	-- Set up equip action
	activeConnections.Equip = subOptions.EquipButton.MouseButton1Click:Connect(function()
		if itemData.Type == "Sword" or itemData.Type == "HeavyAxe" or itemData.Type == "Gauntlet" then
			hotbarModule.EquipItem(itemName, itemData)
		elseif itemData.Type == "Shield" or itemData.Type == "HeavyShield" or itemData.Type == "LightShield" then
			hotbarModule.EquipItem(itemName, itemData)
		elseif itemData.Type == "Helmet" or itemData.Type == "Chestplate" or itemData.Type == "Leggings" or itemData.Type == "Boots" then
			equipEvent:FireServer(itemName, "equip")
		end
		subOptions.Visible = false
	end)

	-- Set up inspect action
	activeConnections.Inspect = subOptions.InspectButton.MouseButton1Click:Connect(function()
		displayItemInspection(itemName, itemData)
		subOptions.Visible = false
	end)

	-- Set up dispose action
	activeConnections.Dispose = subOptions.DisposalButton.MouseButton1Click:Connect(function()
		if itemName ~= "Fist" then
			dropItemEvent:FireServer(itemName)
			subOptions.Visible = false
		end
	end)
end

-- Create item button for full inventory
local function createItemButton(itemName, itemData, parentFrame)
	local itemTemplate = parentFrame:WaitForChild("ItemTemplate")
	local clonedItem = itemTemplate:Clone()
	clonedItem.Name = itemName
	clonedItem.Text = itemName
	clonedItem.Visible = true
	clonedItem.UIStroke.Color = rarityColors[itemData.Rarity] or Color3.fromRGB(242, 183, 5)
	clonedItem.Parent = parentFrame

	local storedViewport = RS.Viewports:FindFirstChild(itemName)
	if storedViewport then
		local newViewport = storedViewport:Clone()
		newViewport.UIStroke:Destroy()
		newViewport.Size = UDim2.new(1, 0, 1, 0)
		newViewport.Name = "ViewportFrame"
		newViewport.Visible = showIcons -- Apply current icon visibility state
		newViewport.Parent = clonedItem
	else
		warn("Viewport for " .. itemName .. " not found!")
	end

	-- Set up click event for inventory items
	clonedItem.MouseButton1Click:Connect(function()
		setupItemContextMenu(itemName, itemData)
	end)

	-- Apply initial visibility based on current filters
	local category = getItemCategory(itemData)
	if parentFrame == armorsList and category and armorFilters[category] ~= nil then
		clonedItem.Visible = armorFilters[category]
	elseif parentFrame == weaponsList and category and weaponFilters[category] ~= nil then
		clonedItem.Visible = weaponFilters[category]
	end
end

-- Set up context menu for armor slots
local function setupArmorSlotContextMenu(itemName, index, itemData)
	local armorSlotUI = equipView.Armor:FindFirstChild(index)
	if not armorSlotUI then return end

	if slotConnections[index] then
		slotConnections[index]:Disconnect()
	end

	slotConnections[index] = armorSlotUI.MouseButton1Click:Connect(function()
		-- Disconnect previous connections
		if activeConnections.HideShow then activeConnections.HideShow:Disconnect() end
		if activeConnections.Inspect then activeConnections.Inspect:Disconnect() end
		if activeConnections.Unequip then activeConnections.Unequip:Disconnect() end

		-- Position context menu
		local pos = inputService:GetMouseLocation()
		local relativePosition = pos - equipView.AbsolutePosition
		equipmentOptions.Position = UDim2.new(0, relativePosition.X, 0, relativePosition.Y - 50)
		equipmentOptions.Visible = true

		-- Set up hide/show action
		activeConnections.HideShow = equipmentOptions.HideShowButton.MouseButton1Click:Connect(function()
			if not hidden[index] then
				hidden[index] = true
				equipEvent:FireServer(itemName, "hide")
			else
				hidden[index] = false
				equipEvent:FireServer(itemName, "show")
			end
			equipmentOptions.Visible = false
		end)

		-- Set up inspect action
		activeConnections.Inspect = equipmentOptions.InspectButton.MouseButton1Click:Connect(function()
			displayItemInspection(itemData)
			equipmentOptions.Visible = false
		end)

		-- Set up unequip action
		activeConnections.Unequip = equipmentOptions.UnequipButton.MouseButton1Click:Connect(function()
			equipEvent:FireServer(itemName, "unequip")
			local viewPort = armorSlotUI:FindFirstChild("ViewportFrame")
			if viewPort then viewPort:Destroy() end
			equipmentOptions.Visible = false
		end)
	end)
end

-- Update armor display in equipment view
local function updateArmorDisplay()
	local equippedArmor = player:WaitForChild("EquippedArmor")
	local Armors = {
		Helmet = equippedArmor:WaitForChild("Helmet"),
		Chestplate = equippedArmor:WaitForChild("Chestplate"),
		Leggings = equippedArmor:WaitForChild("Leggings"),
		Boots = equippedArmor:WaitForChild("Boots"),
	}

	local totalArmor = 0

	for index, armor in pairs(Armors) do
		if armor.Value == "" then continue end

		local itemData = itemsData[armor.Value]
		totalArmor += itemData.Armor

		-- Set up equipment context menu for armor slots
		setupArmorSlotContextMenu(armor.Value, index, itemData)

		-- Update armor info text
		equipView.ArmorsInfo:FindFirstChild(index).Text = armor.Value

		-- Handle viewport display
		local armorSlotUI = equipView.Armor:FindFirstChild(index)
		if armorSlotUI then
			local existingViewport = armorSlotUI:FindFirstChild("ViewportFrame")
			if existingViewport then existingViewport:Destroy() end

			local storedViewport = RS.Viewports:FindFirstChild(armor.Value)
			if storedViewport then
				local newViewport = storedViewport:Clone()
				newViewport.UIStroke:Destroy()
				newViewport.Size = UDim2.new(0.85, 0, 0.85, 0)
				newViewport.Name = "ViewportFrame"
				newViewport.Visible = true
				newViewport.Parent = armorSlotUI
				armorSlotUI.ImageLabel.Visible = false
			else
				warn("Viewport for", armor.Value, "not found!")
			end
		end
	end

	-- Update total armor display
	info.Armor.Text = "Armor: " .. totalArmor
end

-- Update the full inventory display
function FullInventory.UpdateInventory()
	-- Clear previous items in inventory lists
	for _, child in ipairs(weaponsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then 
			child:Destroy() 
		end
	end
	for _, child in ipairs(armorsList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ItemTemplate" then 
			child:Destroy() 
		end
	end

	-- Populate weapons and armors
	for _, item in pairs(playerInventory:GetChildren()) do
		if item:IsA("Tool") then
			local itemData = itemsData[item.Name]
			if not itemData then
				warn("Not Found itemData for " .. item.Name)
			end

			if itemData.Type == "Sword" or itemData.Type == "HeavyAxe" or itemData.Type == "Gauntlet" then
				createItemButton(item.Name, itemData, weaponsList)
			elseif itemData.Type == "Helmet" or itemData.Type == "Chestplate" or itemData.Type == "Leggings" or itemData.Type == "Boots" then
				createItemButton(item.Name, itemData, armorsList)
			elseif itemData.Type == "Shield" or itemData.Type == "HeavyShield" or itemData.Type == "LightShield" then
				createItemButton(item.Name, itemData, armorsList)
			elseif itemData.Type == "Resource" or itemData.Type == "Material" then
				createItemButton(item.Name, itemData, armorsList)
			elseif itemData.Type == "Food" or itemData.Type == "Consumable" then
				createItemButton(item.Name, itemData, weaponsList)
			elseif itemData.Type == "Artifact" then
				createItemButton(item.Name, itemData, weaponsList)
			end
		end
	end

	-- Update equipment displays
	updateArmorDisplay()
	updateWeaponsDisplay()
	updateStatsDisplay()
	-- Apply filters to newly created items
	updateArmorListVisibility()
	updateWeaponListVisibility()
	-- Apply current icon visibility state to all items
	toggleIconDisplay()
end

-- Open the full inventory
function FullInventory.OpenInventory()
	FullInventory.UpdateInventory()
end

-- Initialize the full inventory system
function FullInventory.Initialize(hudRef, hotbarRef)
	Hud = hudRef
	hotbarModule = hotbarRef

	-- Get UI references
	inventoryFrame = Hud:WaitForChild("Inventory")
	loadout = inventoryFrame:WaitForChild("Loadout")
	armorsList = loadout:WaitForChild("Armor"):WaitForChild("ArmorsList")
	weaponsList = loadout:WaitForChild("Weapons"):WaitForChild("WeaponsList")
	attributes = loadout:WaitForChild("Attributes")
	subOptions = loadout:WaitForChild("SubOptions")
	IconButton = loadout:WaitForChild("IconButton")
	ArmorOptionsFrame = loadout:WaitForChild("Armor"):WaitForChild("ArmorOptionsFrame")
	ShieldsButton = ArmorOptionsFrame:WaitForChild("ShieldsButton")	
	ArmorsButton = ArmorOptionsFrame:WaitForChild("ArmorsButton")	
	ResourceButton = ArmorOptionsFrame:WaitForChild("ResourceButton")	

	WeaponsOptionsFrame = loadout:WaitForChild("Weapons"):WaitForChild("WeaponsOptionsFrame")
	ArtifactButton = WeaponsOptionsFrame:WaitForChild("ArtifactButton")	
	WeaponsButton = WeaponsOptionsFrame:WaitForChild("WeaponsButton")	
	FoodButton = WeaponsOptionsFrame:WaitForChild("FoodButton")	

	equipView = inventoryFrame:WaitForChild("EquipView")
	equippedArmor = equipView:WaitForChild("Armor")
	armorsInfo = equipView:WaitForChild("ArmorsInfo")
	info = equipView:WaitForChild("Info")
	stats = equipView:WaitForChild("Stats")
	equippedWeapon = equipView:WaitForChild("Weapons")
	weaponsInfo = equipView:WaitForChild("WeaponsInfo")
	plrName = equipView:WaitForChild("Name")
	equipmentOptions = equipView:WaitForChild("SubOptions")

	-- Set up event handlers
	setupEventHandlers()
	setupFilterButtons()
end

return FullInventory