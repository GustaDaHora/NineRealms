-- UIController/Shop/init.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local shopEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("MarketEvent")
local shopFunction = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("ShopFunction")
local dialogEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local itemsData = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ItemsData"))
local newsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("News"))
local markets = require(script.Markets)

local Shop = {}

local function normalizeCategory(itemType: string?): string
	if not itemType then return "Misc" end
	if itemType == "Sword" or itemType == "HeavyAxe" or itemType == "Gauntlet" then
		return "Weapons"
	elseif itemType == "Helmet" or itemType == "Chestplate" or itemType == "Leggings" or itemType == "Boots" then
		return "Armours"
	elseif itemType == "Resource" or itemType == "Material" then
		return "Resources"
	elseif itemType == "Food" or itemType == "Consumable" then
		return "Food"
	elseif itemType == "Herb" then
		return "Herbs"
	end
	return "Misc"
end

local function populateMarket(npcName: string)
	local marketData = markets[npcName]
	if not marketData or not marketData.Items then
		warn("Market data for " .. tostring(npcName) .. " is missing or invalid!")
		return
	end

	local shopItemsList = {}

	-- Buy items from NPC
	for _, itemName in ipairs(marketData.Items) do
		local data = itemsData[itemName]
		if data then
			local category = normalizeCategory(data.Type)
			table.insert(shopItemsList, {
				id = itemName,
				name = itemName,
				category = category,
				price = data.BasePrice or 0,
				description = data.Description or "",
				onAction = function()
					local success, message = shopFunction:InvokeServer("buy", itemName)
					if success then
						local sound = script:FindFirstChild("Sound")
						if sound then sound:Play() end
					end
					if message then
						newsModule.NewMessage(message, 2)
					end
				end,
			})
		end
	end

	-- Sell items from Player Backpack
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name ~= "Fist" then
				local itemName = tool.Name
				local data = itemsData[itemName]
				if data then
					local sellPrice = math.floor((data.BasePrice or 0) * 0.5)
					local amountVal = tool:FindFirstChild("Amount")
					local count = amountVal and amountVal.Value or 1

					table.insert(shopItemsList, {
						id = "sell_" .. itemName,
						name = itemName .. " (x" .. count .. ")",
						category = "Sell",
						price = sellPrice,
						description = data.Description or "Sell to merchant.",
						onAction = function()
							local success, message = shopFunction:InvokeServer("sell", itemName)
							if success then
								local sound = script:FindFirstChild("Sound")
								if sound then sound:Play() end
								-- Refresh shop items after sell
								populateMarket(npcName)
							end
							if message then
								newsModule.NewMessage(message, 2)
							end
						end,
					})
				end
			end
		end
	end

	store:dispatch(function(state)
		state.shopItems = shopItemsList
		state.shopMode = "Shop"
		state.activeWindow = "Shop"
		return state
	end)
end

function Shop.Start()
	shopEvent.OnClientEvent:Connect(function(npcName)
		populateMarket(npcName)
	end)

	-- Listen for window closing to fire EndDialog
	local lastActiveWindow = nil
	store:subscribe(function(state)
		if lastActiveWindow == "Shop" and state.activeWindow ~= "Shop" then
			dialogEvent:FireServer("EndDialog")
		end
		lastActiveWindow = state.activeWindow
	end)
end

return Shop
