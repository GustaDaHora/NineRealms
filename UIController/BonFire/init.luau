-- UIController/BonFire/init.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local bonfireEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireEvent")
local bonfireFunction = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireFunction")
local dialogEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local itemsData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemsData"))
local newsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("News"))
local recipes = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Recipes"))
local cooking = require(script.Cooking)

local BonFire = {}

local function populateBonFire()
	local backpack = player:FindFirstChild("Backpack")
	local cookingList = {}

	for tierName, mealList in pairs(cooking) do
		for _, itemName in ipairs(mealList) do
			local data = itemsData[itemName]
			local recipe = recipes[itemName]

			local ingredients = {}
			if recipe then
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
			end

			local category = (itemName:find("Elixir") or itemName:find("Tonic") or itemName:find("Extract") or itemName:find("Brew")) and "Elixirs" or "Food"

			table.insert(cookingList, {
				id = itemName,
				name = itemName,
				category = category,
				price = data and data.BasePrice or 0,
				description = data and data.Description or ("Cooked meal (" .. tierName .. ")"),
				ingredients = ingredients,
				onAction = function()
					local success, message = bonfireFunction:InvokeServer(itemName)
					if success then
						local sound = script:FindFirstChild("Sound")
						if sound then sound:Play() end
						-- Refresh ingredients count
						populateBonFire()
					end
					if message then
						newsModule.NewMessage(message, 2)
					end
				end,
			})
		end
	end

	store:dispatch(function(state)
		state.shopItems = cookingList
		state.shopMode = "BonFire"
		state.activeWindow = "BonFire"
		return state
	end)
end

function BonFire.Start()
	bonfireEvent.OnClientEvent:Connect(function()
		populateBonFire()
	end)

	local lastActiveWindow = nil
	store:subscribe(function(state)
		if lastActiveWindow == "BonFire" and state.activeWindow ~= "BonFire" then
			dialogEvent:FireServer("EndDialog")
		end
		lastActiveWindow = state.activeWindow
	end)
end

return BonFire
