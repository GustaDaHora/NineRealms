-- UIController/Inventory/init.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local player = Players.LocalPlayer
local itemsData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemsData"))

local equipItemEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("EquipItem")

local Inventory = {}

local function normalizeCategory(itemType: string?): string
	if not itemType then return "Misc" end
	if itemType == "Sword" or itemType == "HeavyAxe" or itemType == "Gauntlet" then
		return "Weapons"
	elseif itemType == "Helmet" or itemType == "Chestplate" or itemType == "Leggings" or itemType == "Boots" then
		return "Armors"
	elseif itemType == "Shield" or itemType == "HeavyShield" or itemType == "LightShield" then
		return "Shields"
	elseif itemType == "Food" or itemType == "Consumable" then
		return "Food"
	elseif itemType == "Herb" then
		return "Herbs"
	elseif itemType == "Resource" or itemType == "Material" then
		return "Resources"
	end
	return "Misc"
end

local function syncInventory()
	local backpack = player:FindFirstChild("Backpack")
	local invList = {}

	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name ~= "Fist" then
				local data = itemsData[tool.Name]
				local category = data and normalizeCategory(data.Type) or "Misc"
				local amountVal = tool:FindFirstChild("Amount")
				local count = amountVal and amountVal.Value or 1

				table.insert(invList, {
					id = tool.Name .. "_" .. tostring(tool:GetDebugId(0)),
					name = tool.Name,
					category = category,
					slot = data and data.Type or "Misc",
					weight = data and data.Weight or 1,
					value = data and data.BasePrice or 0,
					amount = count,
					icon = "rbxassetid://16751205466",
				})
			end
		end
	end

	store:dispatch(function(state)
		state.inventory = invList
		return state
	end)
end

local function syncEquipment(char: Model)
	local equipped = {}
	local weaponList = {}

	local mainWep = char:GetAttribute("MainWeapon")
	if mainWep and mainWep ~= "" then
		equipped["MainWeapon"] = {
			name = mainWep,
			category = "Weapons",
			icon = "rbxassetid://16751205466",
		}
		table.insert(weaponList, {
			name = mainWep,
			icon = "rbxassetid://16751205466",
		})
	end

	local mainShield = char:GetAttribute("MainShield")
	if mainShield and mainShield ~= "" then
		equipped["MainShield"] = {
			name = mainShield,
			category = "Shields",
			icon = "rbxassetid://16751205466",
		}
	end

	local armorSlots = { "Helmet", "Chestplate", "Leggings", "Boots" }
	for _, slotName in ipairs(armorSlots) do
		local val = char:GetAttribute(slotName)
		if val and val ~= "" then
			equipped[slotName] = {
				name = val,
				category = "Armors",
				slot = slotName,
				icon = "rbxassetid://16751205466",
			}
		end
	end

	local equippedArtifacts = player:FindFirstChild("EquippedArtifacts")
	if equippedArtifacts then
		for index = 1, 3 do
			local slotName = "Artifact" .. index
			local artifact = equippedArtifacts:FindFirstChild(slotName)
			if artifact and artifact:IsA("ValueBase") and artifact.Value ~= "" then
				equipped[slotName] = {
					name = artifact.Value,
					category = "Artifacts",
					icon = "rbxassetid://16751205466",
				}
			end
		end
	end

	store:dispatch(function(state)
		state.equippedItems = equipped
		state.equippedWeapons = weaponList
		state.activeWeaponIndex = math.clamp(state.activeWeaponIndex or 1, 1, math.max(#weaponList, 1))
		return state
	end)
end

function Inventory.Start()
	local itemsRemotes = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Items")
	local equipmentEvent = itemsRemotes:WaitForChild("Equipment")
	local dropItemEvent = itemsRemotes:WaitForChild("DropItem")
	local hiddenEquipment: { [string]: boolean } = {}

	store:dispatch(function(state)
		state.inventoryAction = function(actionType: string, item: any)
			if not item or not item.name then
				return
			end
			if actionType == "Equip" then
				if item.category == "Armors" then
					equipmentEvent:FireServer(item.name, "equip")
				else
					equipItemEvent:FireServer(item.name, true)
				end
			elseif actionType == "Unequip" then
				if item.category == "Armors" then
					equipmentEvent:FireServer(item.name, "unequip")
				else
					equipItemEvent:FireServer(item.name, false)
				end
			elseif actionType == "ToggleVisibility" then
				hiddenEquipment[item.name] = not hiddenEquipment[item.name]
				equipmentEvent:FireServer(item.name, hiddenEquipment[item.name] and "hide" or "show")
			elseif actionType == "Disposal" and item.name ~= "Fist" then
				dropItemEvent:FireServer(item.name)
			end
		end
		return state
	end)
	-- Connect Backpack changes
	local backpack = player:WaitForChild("Backpack", 5)
	if backpack then
		backpack.ChildAdded:Connect(syncInventory)
		backpack.ChildRemoved:Connect(syncInventory)
	end
	player.ChildAdded:Connect(function(child)
		if child.Name == "Backpack" then
			child.ChildAdded:Connect(syncInventory)
			child.ChildRemoved:Connect(syncInventory)
			syncInventory()
		end
	end)

	local artifactConnections: { RBXScriptConnection } = {}
	local function setupCharacter(char: Model)
		for _, connection in ipairs(artifactConnections) do
			connection:Disconnect()
		end
		artifactConnections = {}
		char.AttributeChanged:Connect(function()
			syncEquipment(char)
		end)
		local equippedArtifacts = player:FindFirstChild("EquippedArtifacts")
		if equippedArtifacts then
			for _, child in ipairs(equippedArtifacts:GetChildren()) do
				if child:IsA("ValueBase") then
					table.insert(artifactConnections, child.Changed:Connect(function()
						syncEquipment(char)
					end))
				end
			end
			table.insert(artifactConnections, equippedArtifacts.ChildAdded:Connect(function(child)
				if child:IsA("ValueBase") then
					table.insert(artifactConnections, child.Changed:Connect(function()
						syncEquipment(char)
					end))
					syncEquipment(char)
				end
			end))
		end
		syncEquipment(char)
	end

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end

	-- Input shortcuts
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Quote or input.KeyCode == Enum.KeyCode.QuotedDouble or input.KeyCode == Enum.KeyCode.Backquote then
			store:dispatch(function(state)
				-- Keyboard shortcuts may open the inventory, but dismissal is owned by
				-- the visible X control so accidental repeat input cannot close a UI.
				state.activeWindow = state.activeWindow or "Inventory"
				return state
			end)
		end
	end)

	-- Initial sync
	syncInventory()
end

return Inventory
