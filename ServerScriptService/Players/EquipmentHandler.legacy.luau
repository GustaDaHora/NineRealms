local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local itemsEvents = RS:WaitForChild("RE"):WaitForChild("Items")
local equipEvent = itemsEvents:WaitForChild("Equipment")
local giveItemEvent = itemsEvents:WaitForChild("GiveItem")
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

-- Helper function to unequip armor pieces
local function unequipArmorPiece(plr, char, plrData, EquippedArmor, itemName, storage)
	local RS = game:GetService("ReplicatedStorage")
	local currentItemData = itemsData[itemName]

	if currentItemData then
		local armorType = currentItemData.Type

		-- Verify this is the currently equipped item
		if EquippedArmor[armorType].Value ~= itemName then
			warn("Cannot unequip - item not currently equipped:", itemName)
			return false
		end

		-- Reset stats
		plrData:WaitForChild("Weight").Value -= currentItemData.Stats.Weight
		plrData[armorType.. "Armor"].Value -= currentItemData.Armor

		-- Remove armor parts
		for _, name in pairs(currentItemData.Parts) do
			local armor = char:FindFirstChild(name)
			if armor then armor:Destroy() end
		end

		-- If removing a helmet, restore hair and accessories
		if armorType == "Helmet" then
			for _, accessory in ipairs(storage:GetChildren()) do
				accessory.Parent = char
			end
		end

		-- Return the item to the player's inventory
		giveItemEvent:Fire(plr, itemName)

		-- Clear the equipped slot
		EquippedArmor[armorType].Value = ""

		return true
	else
		warn("Module not found for unequipping:", itemName)
		return false
	end
end

-- Helper function to recursively set transparency
local function setTransparencyRecursive(object, transparencyValue)
	-- Apply to the object itself if applicable
	if object:IsA("BasePart") or object:IsA("MeshPart") or object:IsA("UnionOperation") then
		object.Transparency = transparencyValue
	elseif object:IsA("Decal") or object:IsA("Texture") then
		object.Transparency = transparencyValue
	end

	-- Apply to any applicable Special objects
	if object:IsA("SpecialMesh") then
		object.Transparency = transparencyValue
	end

	-- Apply to all children recursively
	for _, child in ipairs(object:GetChildren()) do
		setTransparencyRecursive(child, transparencyValue)
	end
end

-- Helper function to toggle armor visibility
local function toggleArmorVisibility(plr, char, itemName, action)
	print(plr, char, itemName, action)
	local RS = game:GetService("ReplicatedStorage")
	local currentItemData = itemsData[itemName]

	if currentItemData then
		local armorType = currentItemData.Type
		local EquippedArmor = plr:WaitForChild("EquippedArmor")

		-- Verify this is the currently equipped item
		if EquippedArmor[armorType].Value ~= itemName then
			warn("Cannot toggle visibility - item not currently equipped:", itemName)
			return false
		end

		-- Set transparency value based on action
		local transparencyValue = (action == "hide") and 1 or 0

		-- Apply transparency to all armor parts
		for _, partName in pairs(currentItemData.Parts) do
			local armorPart = char:FindFirstChild(partName)
			if armorPart then
				-- Apply transparency to all descendants that can be transparent
				setTransparencyRecursive(armorPart, transparencyValue)
			end
		end

		-- Handle accessories for helmet
		if armorType == "Helmet" and action == "show" then
			local storage = plr:FindFirstChild("HiddenAccessories")
			if storage and #storage:GetChildren() > 0 then
				-- Keep accessories hidden when showing helmet
				-- (This maintains the helmet's functionality of hiding hair/accessories)
			end
		end

		return true
	else
		warn("Module not found for visibility toggle:", itemName)
		return false
	end
end

equipEvent.OnServerEvent:Connect(function(plr, itemName, action)
	local plrData = plr:WaitForChild("Data")
	local EquippedArmor = plr:WaitForChild("EquippedArmor")
	local Helmet = EquippedArmor:WaitForChild("Helmet")
	local Chestplate = EquippedArmor:WaitForChild("Chestplate")
	local Leggings = EquippedArmor:WaitForChild("Leggings")
	local Boots = EquippedArmor:WaitForChild("Boots")

	-- Get the player's character
	local char = plr.Character
	if not char then return end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return end

	-- **Handling Hair and Accessories Storage**
	local storage = plr:FindFirstChild("HiddenAccessories")
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = "HiddenAccessories"
		storage.Parent = plr
	end

	if action == "equip" then
		-- Equipping Logic
		-- Fetch item module
		local itemData = itemsData[itemName]
		if itemData then
			local armorType = itemData.Type
			local currentEquipped = EquippedArmor[armorType].Value

			-- **Unequip Current Armor**
			if currentEquipped ~= "" then
				unequipArmorPiece(plr, char, plrData, EquippedArmor, currentEquipped, storage)
			end

			-- **Equip New Armor**
			EquippedArmor[armorType].Value = itemName
			plrData:WaitForChild("Weight").Value += itemData.Stats.Weight
			plrData[armorType.. "Armor"].Value += itemData.Armor

			-- If the player is equipping a helmet, hide hair and accessories
			if armorType == "Helmet" then
				for _, accessory in ipairs(char:GetChildren()) do
					if accessory:IsA("Accessory") and accessory.AccessoryType ~= Enum.AccessoryType.Unknown then
						accessory.Parent = storage -- Move to storage
					end
				end
			end

			-- Attach new armor pieces
			for _, name in pairs(itemData.Parts) do
				local armor = RS.Armors[itemData.Armorset]:FindFirstChild(name)
				if armor then armor:Clone().Parent = char end
			end

			-- Remove the item from inventory
			local itemOnPlr = plr.Backpack:FindFirstChild(itemName) or char:FindFirstChild(itemName)
			if itemOnPlr then itemOnPlr:Destroy() end
		else
			warn("Module not found for", itemName)
			return
		end
	elseif action == "unequip" then
		-- Unequipping Logic
		unequipArmorPiece(plr, char, plrData, EquippedArmor, itemName, storage)
	elseif action == "hide" or action == "show" then
		-- Visibility Toggle Logic
		toggleArmorVisibility(plr, char, itemName, action)
	else
		warn("Invalid action:", action)
		return
	end

	equipEvent:FireClient(plr, action, itemName)
end)