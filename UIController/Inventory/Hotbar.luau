local TS = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local equipItemEvent = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("EquipItem")
local UserInputService = game:GetService("UserInputService")

local HotBarFrame = script.Parent.Parent.Parent:WaitForChild("Hotbar")
local MainWeapon = HotBarFrame:WaitForChild("MainWeapon")
local MainShield = HotBarFrame:WaitForChild("MainShield")

local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()

-- Slot type definitions (from SlotManager)
local WEAPON_SLOT = 1
local SHIELD_SLOT = 10

local SlotSlots = {}
for i = 2, 9 do
	SlotSlots["Slot" .. i] = HotBarFrame:FindFirstChild("Slot" .. i)
end

-- MainWeapon is Slot1, MainShield is Slot10
local slotMapping = {
	[Enum.KeyCode.One] = MainWeapon,
	[Enum.KeyCode.Two] = SlotSlots.Slot2,
	[Enum.KeyCode.Three] = SlotSlots.Slot3,
	[Enum.KeyCode.Four] = SlotSlots.Slot4,
	[Enum.KeyCode.Five] = SlotSlots.Slot5,
	[Enum.KeyCode.Six] = SlotSlots.Slot6,
	[Enum.KeyCode.Seven] = SlotSlots.Slot7,
	[Enum.KeyCode.Eight] = SlotSlots.Slot8,
	[Enum.KeyCode.Nine] = SlotSlots.Slot9,
	[Enum.KeyCode.Zero] = MainShield,
}

local equippedItems = {}
local slotColors = {}
local hotbar = {}

local selectedSlot = nil
local previousSlot = nil
local isWeaponAndShieldEquipped = false

-- Item type checking functions (from SlotManager)
local function isWeaponType(itemType)
	return itemType == "Sword" or itemType == "HeavyAxe" or itemType == "Gauntlet"
end

local function isShieldType(itemType)
	return itemType == "Shield" or itemType == "HeavyShield" or itemType == "LightShield"
end

-- Clear a specific slot in the hotbar (from SlotManager)
local function clearSlot(slotNumber)
	local slotName = "Slot" .. slotNumber
	local slot = HotBarFrame:FindFirstChild(slotName)
	if slot then
		slot.Text = ""
		slot.TextTransparency = 1
		equippedItems[slotName] = nil
	end

	-- Clear main weapon reference if it's slot 1
	if slotNumber == WEAPON_SLOT then
		MainWeapon.Text = ""
		MainWeapon.TextTransparency = 1
		equippedItems[MainWeapon.Name] = nil
		char:SetAttribute("MainWeapon", "")
	end

	-- Clear main shield reference if it's slot 10
	if slotNumber == SHIELD_SLOT then
		MainShield.Text = ""
		MainShield.TextTransparency = 1
		equippedItems[MainShield.Name] = nil
		char:SetAttribute("MainShield", "")
	end
end

-- Debug function to track FireServer calls
local function safeFireServer(itemName, equipped)
	if not itemName or itemName == "" then
		print("WARNING: Attempted to call equipItemEvent:FireServer with empty itemName")
		return false
	end

	equipItemEvent:FireServer(itemName, equipped)
	return true
end

local function resetFramesColor(slot)
	if not slot then return end
	local frame = slot:FindFirstChild("Frame")
	if frame then
		for _, descendant in pairs(frame:GetDescendants()) do
			if descendant:IsA("ImageLabel") then
				descendant.ImageColor3 = slotColors[slot].originalColor
			end
		end
	end
end

local function changeFramesColorToWhite(slot)
	if slot and slot:FindFirstChild("Frame") then
		for _, descendant in pairs(slot.Frame:GetDescendants()) do
			if descendant:IsA("ImageLabel") then
				slotColors[slot] = {originalColor = descendant.ImageColor3}
				descendant.ImageColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end

local function deselectSlot()
	if not selectedSlot then return end
	resetFramesColor(selectedSlot)

	local frame = selectedSlot:FindFirstChild("Frame")
	if frame then
		local layout = frame:FindFirstChild("UIListLayout")
		if layout then
			TS:Create(layout, TweenInfo.new(0.2), {Padding = UDim.new(0, 0)}):Play()
		end
	end

	-- Special case: when weapon+shield are equipped together
	if isWeaponAndShieldEquipped then
		if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" then
			safeFireServer(equippedItems[MainWeapon.Name], false)
		end
		if equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
			safeFireServer(equippedItems[MainShield.Name], false)
		end
		resetFramesColor(MainWeapon)
		resetFramesColor(MainShield)
		isWeaponAndShieldEquipped = false
	elseif selectedSlot and equippedItems[selectedSlot.Name] and equippedItems[selectedSlot.Name] ~= "" then
		safeFireServer(equippedItems[selectedSlot.Name], false)
	end

	previousSlot = nil
	selectedSlot = nil
end

local function selectWeaponAndShield()
	-- Deselect previous selection if any
	if selectedSlot then
		deselectSlot()
	end

	-- Change visuals for both weapon and shield
	changeFramesColorToWhite(MainWeapon)
	changeFramesColorToWhite(MainShield)

	-- Apply UI effects to both
	for _, slot in pairs({MainWeapon, MainShield}) do
		local frame = slot:FindFirstChild("Frame")
		if frame then
			local layout = frame:FindFirstChild("UIListLayout")
			if layout then
				TS:Create(layout, TweenInfo.new(0.2), {Padding = UDim.new(0.4, 0)}):Play()
			end
		end
	end

	-- Equip both items if they exist
	if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" then
		safeFireServer(equippedItems[MainWeapon.Name], true)
	end

	if equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
		safeFireServer(equippedItems[MainShield.Name], true)
	end

	-- Set state variables
	isWeaponAndShieldEquipped = true
	selectedSlot = MainWeapon -- We'll use MainWeapon as the "primary" selected slot
	previousSlot = MainWeapon
end

local function selectSlot(slot)
	if not slot then 
		print("WARNING: Attempted to select nil slot")
		return 
	end

	-- Special case for weapon+shield combo
	if (slot == MainWeapon or slot == MainShield) and 
		(equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" and 
			equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "") then
		if isWeaponAndShieldEquipped then
			deselectSlot()
			return
		else
			selectWeaponAndShield()
			return
		end
	end

	-- Normal slot selection logic
	if selectedSlot == slot then
		deselectSlot()
		return
	end

	if selectedSlot then
		if isWeaponAndShieldEquipped then
			if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" then
				safeFireServer(equippedItems[MainWeapon.Name], false)
			end
			if equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
				safeFireServer(equippedItems[MainShield.Name], false)
			end
			resetFramesColor(MainWeapon)
			resetFramesColor(MainShield)
			isWeaponAndShieldEquipped = false
		elseif equippedItems[selectedSlot.Name] and equippedItems[selectedSlot.Name] ~= "" then
			safeFireServer(equippedItems[selectedSlot.Name], false)
		end
		deselectSlot()
	end

	if previousSlot then
		resetFramesColor(previousSlot)
	end

	changeFramesColorToWhite(slot)
	previousSlot = slot
	selectedSlot = slot

	local frame = slot:FindFirstChild("Frame")
	if frame then
		local layout = frame:FindFirstChild("UIListLayout")
		if layout then
			TS:Create(layout, TweenInfo.new(0.2), {Padding = UDim.new(0.4, 0)}):Play()
		end
	end

	if equippedItems[selectedSlot.Name] and equippedItems[selectedSlot.Name] ~= "" then
		safeFireServer(equippedItems[selectedSlot.Name], true)
	end
end

local function unequipFromPreviousSlot(itemName)
	if not itemName or itemName == "" then
		print("WARNING: Attempted to unequip empty itemName")
		return
	end

	for slotName, item in pairs(equippedItems) do
		if item == itemName then
			local slot = HotBarFrame:FindFirstChild(slotName)
			if slot then
				-- Only unequip if the slot is the currently selected one
				if isWeaponAndShieldEquipped and (slot == MainWeapon or slot == MainShield) then
					safeFireServer(itemName, false)
				elseif selectedSlot == slot then
					safeFireServer(itemName, false)
				end

				slot.Text = ""
				slot.TextTransparency = 1
				equippedItems[slotName] = nil

				-- Update attributes if needed
				if slot == MainWeapon then
					char:SetAttribute("MainWeapon", "")
				elseif slot == MainShield then
					char:SetAttribute("MainShield", "")
				end

				-- If we're unequipping either weapon or shield, exit weapon+shield mode
				if slot == MainWeapon or slot == MainShield then
					isWeaponAndShieldEquipped = false
				end
			end
			break
		end
	end
end

-- SlotManager API functions
local function IsSlotAllowed(itemType, slotNumber)
	if isWeaponType(itemType) then
		return slotNumber == WEAPON_SLOT
	elseif isShieldType(itemType) then
		return slotNumber == SHIELD_SLOT
	elseif slotNumber ~= 1 or slotNumber ~= 10 then
		return true
	else
		warn("Error processing IsSlotAllowed " .. itemType, slotNumber)
		return nil
	end
end

local function GetAppropriateSlot(itemType)
	if isWeaponType(itemType) then
		return WEAPON_SLOT
	elseif isShieldType(itemType) then
		return SHIELD_SLOT
	else
		return nil
	end
end

function hotbar.EquipItem(itemName, itemData, slotNumber)
	if not itemData then
		print("WARNING: Attempted to equip nil itemData")
		return false
	end

	if not itemName or itemName == "" then
		print("WARNING: Attempted to equip item with empty name")
		return false
	end

	if not itemData.Type then
		warn("Invalid item data provided - missing Type field")
		return false
	end

	-- Determine the target slot using SlotManager logic
	local targetSlot = slotNumber

	-- If no slot specified, determine appropriate slot based on item type
	if not targetSlot then
		targetSlot = GetAppropriateSlot(itemData.Type)
		if not targetSlot then
			-- If not a weapon or shield, search for first free slot between 2-9
			for i = 2, 9 do
				local slotName = "Slot" .. i
				if not equippedItems[slotName] or equippedItems[slotName] == "" then
					targetSlot = i
					break
				end
			end

			if not targetSlot then
				print("No free slots available for item " .. itemData.Type)
				return false
			end
		end
	end

	-- Enforce slot restrictions using SlotManager logic
	if not IsSlotAllowed(itemData.Type, targetSlot) then
		if isWeaponType(itemData.Type) then
			warn("Weapons can only be equipped to slot " .. WEAPON_SLOT)
		elseif isShieldType(itemData.Type) then
			warn("Shields can only be equipped to slot " .. SHIELD_SLOT)
		end
		return false
	end
	-- Clear conflicting items based on type (SlotManager logic)
	if isWeaponType(itemData.Type) then
		-- Clear any existing weapon from slot 1
		clearSlot(WEAPON_SLOT)
	elseif isShieldType(itemData.Type) then
		-- Clear any existing shield from slot 10
		clearSlot(SHIELD_SLOT)
	end

	-- Unequip any previous instance of this item
	unequipFromPreviousSlot(itemName)

	-- Determine the actual UI slot object
	local targetSlotObject
	if targetSlot == 1 or targetSlot == WEAPON_SLOT then
		targetSlotObject = MainWeapon
		char:SetAttribute("MainWeapon", itemName)
	elseif targetSlot == 10 or targetSlot == SHIELD_SLOT then
		targetSlotObject = MainShield
		char:SetAttribute("MainShield", itemName)
	else
		targetSlotObject = SlotSlots["Slot" .. targetSlot]
	end

	if not targetSlotObject then
		warn("Slot " .. targetSlot .. " not found in hotbar")
		return false
	end

	-- Equip the item
	targetSlotObject.Text = itemName
	targetSlotObject.TextTransparency = 0
	equippedItems[targetSlotObject.Name] = itemName

	-- Handle selection logic
	--if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" and
	--	equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" and 
	--	(targetSlotObject == MainWeapon or targetSlotObject == MainShield) then
	--	-- If we're already in weapon+shield mode, stay in it
	--	if isWeaponAndShieldEquipped then
	--		safeFireServer(itemName, true)
	--		selectWeaponAndShield()
	--	else
	--		safeFireServer(itemName, true)
	--		selectSlot(targetSlotObject)
	--	end
	--else
	--	safeFireServer(itemName, true)
	--	selectSlot(targetSlotObject)
	--end

	return true
end

function hotbar.UnequipItem(itemName)
	if not itemName or itemName == "" then
		print("WARNING: Attempted to unequip nil or empty itemName")
		return
	end

	local targetSlot = nil

	-- Find the slot containing the item
	for slotName, equippedItem in pairs(equippedItems) do
		if equippedItem == itemName then
			targetSlot = HotBarFrame:FindFirstChild(slotName)
			break
		end
	end

	if not targetSlot then
		print("WARNING: Could not find slot containing item: " .. itemName)
		return
	end

	-- Only unequip if the item is currently selected in the hotbar
	if isWeaponAndShieldEquipped and (targetSlot == MainWeapon or targetSlot == MainShield) then
		safeFireServer(itemName, false)

		-- If we're unequipping either weapon or shield, exit weapon+shield mode
		isWeaponAndShieldEquipped = false
	elseif selectedSlot == targetSlot then
		safeFireServer(itemName, false)
	end

	equippedItems[targetSlot.Name] = nil

	-- Reset the slot text
	targetSlot.Text = ""
	targetSlot.TextTransparency = 1

	-- Update attributes if needed
	if targetSlot == MainWeapon then
		char:SetAttribute("MainWeapon", "")
	elseif targetSlot == MainShield then
		char:SetAttribute("MainShield", "")
	end

	-- If the selected slot is the one being unequipped, deselect it
	if selectedSlot == targetSlot then
		deselectSlot()
	end
end

local function selectSlotByKey(key)
	local slot = slotMapping[key]
	if not slot then
		return
	end

	if key == Enum.KeyCode.One or key == Enum.KeyCode.Zero then
		-- When pressing 1 or 0, check if both weapon and shield are equipped
		if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" and
			equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
			selectWeaponAndShield()
		else
			-- If not both equipped, behave normally
			selectSlot(slot)
		end
	else
		selectSlot(slot)
	end
end

-- Set up click handlers for all slots
for _, slot in pairs(SlotSlots) do
	slot.MouseButton1Click:Connect(function()
		selectSlot(slot)
	end)
end

MainWeapon.MouseButton1Click:Connect(function()
	if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" and
		equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
		selectWeaponAndShield()
	else
		selectSlot(MainWeapon)
	end
end)

MainShield.MouseButton1Click:Connect(function()
	if equippedItems[MainWeapon.Name] and equippedItems[MainWeapon.Name] ~= "" and
		equippedItems[MainShield.Name] and equippedItems[MainShield.Name] ~= "" then
		selectWeaponAndShield()
	else
		selectSlot(MainShield)
	end
end)

-- Debug event to track key presses
UserInputService.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end

	-- Debug line to see what key is being pressed
	if slotMapping[input.KeyCode] then
		--print("DEBUG: Selecting slot with key:", input.KeyCode)
		selectSlotByKey(input.KeyCode)
	end
end)

equipItemEvent.OnClientEvent:Connect(function(itemName)
	if not itemName or itemName == "" then 
		print("WARNING: Received empty itemName from server")
		return
	end
	unequipFromPreviousSlot(itemName)
end)

-- Initialize hotbar (clear any leftover state)
for _, slot in pairs(SlotSlots) do
	slot.Text = ""
	slot.TextTransparency = 1
end
MainWeapon.Text = ""
MainWeapon.TextTransparency = 1
MainShield.Text = ""
MainShield.TextTransparency = 1

return hotbar