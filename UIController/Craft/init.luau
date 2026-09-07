-- UIController/Craft/init.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local craftEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftEvent")
local craftFunction = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftFunction")
local dialogEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local itemsData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemsData"))
local newsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("News"))
local recipes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Recipes"))
local smiths = require(script.Smiths)

local Craft = {}

local function normalizeCategory(itemType: string?): string
	if not itemType then return "Misc" end
	if itemType == "Sword" or itemType == "HeavyAxe" or itemType == "Gauntlet" then
		return "Weapons"
	elseif itemType == "Helmet" or itemType == "Chestplate" or itemType == "Leggings" or itemType == "Boots" then
		return "Armours"
	elseif itemType == "Resource" or itemType == "Material" then
		return "Resources"
	elseif itemType == "Herb" then
		return "Herbs"
	end
	return "Misc"
end

local function populateCrafts(npcName: string)
	local smithData = smiths[npcName]
	if not smithData or not smithData.Items then
		warn("Crafting data for " .. tostring(npcName) .. " is missing or invalid!")
		return
	end

	local backpack = player:FindFirstChild("Backpack")
	local craftItemsList = {}

	for _, itemName in ipairs(smithData.Items) do
		local data = itemsData[itemName]
		local recipe = recipes[itemName]
		if data and recipe then
			local ingredients = {}
			for mat, reqAmount in pairs(recipe) do
				local owned = 0
				if backpack then
					local item = backpack:FindFirstChild(mat)
					local amountVal = item and item:FindFirstChild("Amount")
					owned = amountVal and amountVal.Value or (item and 1 or 0)
				end
				table.insert(ingredients, {
					name = mat,
					owned = owned,
					required = reqAmount,
				})
			end

			local category = normalizeCategory(data.Type)

			table.insert(craftItemsList, {
				id = itemName,
				name = itemName,
				category = category,
				price = math.floor((data.BasePrice or 0) * 0.5),
				description = data.Description or "Forged equipment.",
				ingredients = ingredients,
				onAction = function()
					local success, message = craftFunction:InvokeServer(itemName)
					if success then
						local sound = script:FindFirstChild("Sound")
						if sound then sound:Play() end
						-- Refresh ingredients count
						populateCrafts(npcName)
					end
					if message then
						newsModule.NewMessage(message, 2)
					end
				end,
			})
		end
	end

	store:dispatch(function(state)
		state.shopItems = craftItemsList
		state.shopMode = "Crafting"
		state.activeWindow = "Crafting"
		return state
	end)
end

function Craft.Start()
	craftEvent.OnClientEvent:Connect(function(npcName)
		populateCrafts(npcName)
	end)

	local lastActiveWindow = nil
	store:subscribe(function(state)
		if lastActiveWindow == "Crafting" and state.activeWindow ~= "Crafting" then
			dialogEvent:FireServer("EndDialog")
		end
		lastActiveWindow = state.activeWindow
	end)
end

return Craft