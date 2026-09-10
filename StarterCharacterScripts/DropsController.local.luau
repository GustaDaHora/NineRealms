-- DropsHandler local script (Optimized for instant feedback)
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Constants
local INTERACTION_RANGE = 11
local UI_TWEEN_DURATION = 0.3 -- Reduced for faster animations
local UI_EASING_STYLE = Enum.EasingStyle.Quad
local UI_EASING_DIRECTION = Enum.EasingDirection.Out
local DEBOUNCE_TIME = 0.1
local UPDATE_FREQUENCY = 0.1

-- Player references
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local itemsDisplay = mainGui:WaitForChild("ItemsDisplay")
local itemTemplate = itemsDisplay:WaitForChild("ItemTemplate")

local itemEvent = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("ItemEvent")
local pickUpItem = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("PickUpItem")

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

-- Game references
local itemsFolder = workspace:WaitForChild("ItemsFolder")

-- State tracking
local displayedItems = {}
local cachedItemData = {}
local debounce = {}
local updateConnection = nil
local pickedUpItems = {} -- Track items that have been picked up but not yet confirmed by server

-- Set up character respawning
local function setupCharacter(char)
	character = char
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(setupCharacter)

-- Tween utility function
local tweenInfo = TweenInfo.new(UI_TWEEN_DURATION, UI_EASING_STYLE, UI_EASING_DIRECTION)

local function tweenObject(object, properties, onComplete)
	if not object or not object.Parent then return end

	local tween = TweenService:Create(object, tweenInfo, properties)
	tween:Play()

	if onComplete then
		tween.Completed:Connect(onComplete)
	end

	return tween
end

-- Get nearby items by calculating distance
local function getNearbyItems()
	local nearbyItems = {}
	for _, item in ipairs(itemsFolder:GetChildren()) do
		-- Skip items that have been picked up locally
		local uniqueId = item:GetAttribute("UniqueID")
		if uniqueId and pickedUpItems[uniqueId] then
			continue
		end

		-- Check for traditional MeshPart items
		if item:GetAttribute("UniqueID") then
			if item:IsA("MeshPart") then
				if uniqueId then
					local distance = (humanoidRootPart.Position - item.Position).Magnitude

					if distance <= INTERACTION_RANGE then
						nearbyItems[uniqueId] = {
							instance = item,
							distance = distance,
							itemType = "Drop"
						}
					end
				end
				-- Check for Models with CanBePicked attribute
			elseif item:IsA("Model") and item:GetAttribute("CanBePicked") then
				local primaryPart = item.PrimaryPart
				if uniqueId and primaryPart then
					local distance = (humanoidRootPart.Position - primaryPart.Position).Magnitude
					if distance <= INTERACTION_RANGE then
						nearbyItems[uniqueId] = {
							instance = item,
							distance = distance,
							itemType = "Loot"
						}
					end
				end
			end
		end
	end
	return nearbyItems
end

-- Cache item data
local function getItemData(item)
	local itemName = item.Name

	if cachedItemData[itemName] then
		return cachedItemData[itemName]
	end

	local itemData = itemsData[itemName]

	if itemData then
		cachedItemData[itemName] = itemData
		return itemData
	else
		warn("Failed to load item data for:", itemName)
		return nil
	end
end

-- Instant UI removal with feedback animation
local function removeItemFromUIInstantly(uniqueId)
	local uiItem = displayedItems[uniqueId]
	if not uiItem or not uiItem.Parent then return end

	local textButton = uiItem:FindFirstChild("TextButton")
	if textButton then
		-- Quick scale down animation for instant feedback
		tweenObject(textButton, {
			Size = UDim2.new(0, 0, 0, 0),
			TextTransparency = 1
		}, function()
			if uiItem and uiItem.Parent then
				uiItem:Destroy()
			end
		end)
	else
		uiItem:Destroy()
	end

	displayedItems[uniqueId] = nil
end

-- Remove item from UI (standard removal)
local function removeItemFromUI(uniqueId)
	local uiItem = displayedItems[uniqueId]
	if not uiItem or not uiItem.Parent then return end

	local textButton = uiItem:FindFirstChild("TextButton")
	if textButton then
		tweenObject(textButton, {TextTransparency = 1}, function()
			if uiItem and uiItem.Parent then
				uiItem:Destroy()
			end
			displayedItems[uniqueId] = nil
		end)
	else
		uiItem:Destroy()
		displayedItems[uniqueId] = nil
	end
end

-- Add item to UI
local function addItemToUI(uniqueId, itemInstance, itemType, itemData)
	-- First check if an existing UI element needs to be removed
	local existingItem = itemsDisplay:FindFirstChild(uniqueId)
	if existingItem then
		existingItem:Destroy()
	end

	-- Create new UI element
	local newItem = itemTemplate:Clone()
	newItem.Name = uniqueId
	newItem.TextButton.Text = itemInstance.Name
	newItem.TextButton.TextTransparency = 1
	newItem.Visible = true
	newItem.Parent = itemsDisplay

	-- Set up mouse cursor behavior
	newItem.MouseEnter:Connect(function()
		player:GetMouse().Icon = "rbxasset://SystemCursors/PointingHand"
	end)

	newItem.MouseLeave:Connect(function()
		player:GetMouse().Icon = ""
	end)

	-- Set up click handler with instant feedback
	newItem.TextButton.MouseButton1Click:Connect(function()
		if debounce[uniqueId] then return end

		debounce[uniqueId] = true

		-- INSTANT FEEDBACK: Mark item as picked up and remove UI immediately
		pickedUpItems[uniqueId] = true
		removeItemFromUIInstantly(uniqueId)

		-- Visual feedback: Change cursor briefly
		local mouse = player:GetMouse()
		mouse.Icon = "rbxasset://SystemCursors/Wait"
		task.delay(0.2, function()
			mouse.Icon = ""
		end)

		-- Send server request
		if itemType == "Drop" then
			itemEvent:FireServer(itemInstance.Name, uniqueId)
		elseif itemType == "Loot" then
			pickUpItem:FireServer(itemInstance, itemInstance.Name, itemData, uniqueId)
		end

		-- Clear debounce after a short delay
		task.delay(DEBOUNCE_TIME, function()
			debounce[uniqueId] = false
		end)

		-- Failsafe: If server doesn't respond within 3 seconds, restore the item
		task.delay(3, function()
			if pickedUpItems[uniqueId] and itemInstance.Parent then
				pickedUpItems[uniqueId] = nil
				-- Item still exists in workspace, so we can show it again
				--warn("Item pickup timed out, restoring UI for:", itemInstance.Name)
			end
		end)
	end)

	-- Animate appearance
	tweenObject(newItem.TextButton, {TextTransparency = 0})
	displayedItems[uniqueId] = newItem

	return newItem
end

-- Update the UI with nearby items
local function updateUI(nearbyItems)
	-- Remove UI elements for items that are no longer nearby
	for uniqueId in pairs(displayedItems) do
		if not nearbyItems[uniqueId] then
			removeItemFromUI(uniqueId)
		end
	end

	-- Clean up picked up items that no longer exist in workspace
	for uniqueId in pairs(pickedUpItems) do
		local itemExists = false
		for _, item in ipairs(itemsFolder:GetChildren()) do
			if item:GetAttribute("UniqueID") == uniqueId then
				itemExists = true
				break
			end
		end

		if not itemExists then
			pickedUpItems[uniqueId] = nil
		end
	end

	-- Sort nearby items by distance
	local sortedItems = {}
	for uniqueId, itemInfo in pairs(nearbyItems) do
		table.insert(sortedItems, {
			uniqueId = uniqueId,
			instance = itemInfo.instance,
			distance = itemInfo.distance,
			itemType = itemInfo.itemType
		})
	end

	table.sort(sortedItems, function(a, b)
		return a.distance < b.distance
	end)

	-- Add new items to UI
	for _, itemInfo in ipairs(sortedItems) do
		local uniqueId = itemInfo.uniqueId
		local itemInstance = itemInfo.instance
		local itemType = itemInfo.itemType

		if not displayedItems[uniqueId] then
			local itemData = getItemData(itemInstance)
			if itemData then
				addItemToUI(uniqueId, itemInstance, itemType, itemData)
			end
		end
	end

	-- Toggle UI visibility
	itemsDisplay.Visible = next(nearbyItems) ~= nil
end

-- Main update function
local function startItemTracking()
	if updateConnection then
		updateConnection:Disconnect()
	end

	-- Use a more efficient update cycle
	local lastUpdate = 0
	updateConnection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		if currentTime - lastUpdate >= UPDATE_FREQUENCY then
			local nearbyItems = getNearbyItems()
			updateUI(nearbyItems)
			lastUpdate = currentTime
		end
	end)
end

-- Clean up on script termination
local function cleanup()
	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end

	for uniqueId in pairs(displayedItems) do
		local uiItem = displayedItems[uniqueId]
		if uiItem and uiItem.Parent then
			uiItem:Destroy()
		end
	end

	displayedItems = {}
	cachedItemData = {}
	debounce = {}
	pickedUpItems = {}
end

-- Initialize the system
startItemTracking()

-- Clean up when script is terminated
script.Destroying:Connect(cleanup)