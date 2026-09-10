local Shop = {}

local player = game:GetService("Players").LocalPlayer

local RS = game:GetService("ReplicatedStorage")
local shopEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("MarketEvent")
local shopFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("ShopFunction")
local dialogEvent = RS:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))
local newsModule = require(RS:WaitForChild("Modules"):WaitForChild("News"))
local markets = require(script.Markets)

--// GUI References
local MainGui = script.Parent.Parent
local ShopFrame = MainGui.Shop
local ItemsFrame = ShopFrame.ItemsMenu.ScrollingFrame
local Sections = ShopFrame.IndexSection

local Categories = {
	Weapons = Sections.Weapons,
	Armors = Sections.Armors,
	Food = Sections.Food,
	Herbs = Sections.Herbs,
	Resourses = Sections.Resourses,
	Misc = Sections.Misc,
	Sell = Sections.Sell
}

local rarityColors = {
	Common = Color3.fromRGB(57, 50, 43),
	Uncommon = Color3.fromRGB(50, 200, 50),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(150, 70, 200),
	Legendary = Color3.fromRGB(255, 110, 50)
}

local TypePriority = {"Weapons", "Armors", "Food", "Herbs", "Resourses", "Misc"}
local ActiveItems = {}

local function clearItems()
	for _, v in pairs(ItemsFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v.Visible = false
		end
	end
end

local function clearSections()
	for _, section in pairs(Categories) do
		section.Visible = false
	end
end

local function displayItems(category)
	clearItems()

	if ActiveItems[category] and #ActiveItems[category] > 0 then
		for _, itemFrame in pairs(ActiveItems[category]) do
			itemFrame.Parent = ItemsFrame
			itemFrame.Visible = true
		end
	else
		warn("No items found for category: " .. category)
	end
end

local function populateMarket(npcName)
	if not markets[npcName] or not markets[npcName].Items then
		warn("Market data for " .. npcName .. " is missing or invalid!")
		return
	end

	clearItems()

	-- Reset ActiveItems for each category
	for _, category in pairs(TypePriority) do
		ActiveItems[category] = {}
		Categories[category].Visible = false  -- Hide all categories at the start
	end

	local ItemTemplate = ItemsFrame:FindFirstChild("Template")
	if not ItemTemplate then
		warn("Template not found in ScrollingFrame!")
		return
	end

	-- Organize items into categories
	for _, itemName in pairs(markets[npcName].Items) do
		local ItemData = itemsData[itemName]
		if ItemData then

			-- Normalize category for weapons
			local category = ItemData.Type or "Misc"
			if category == "Sword" or category == "HeavyAxe" or category == "Gauntlet" then
				category = "Weapons"
			elseif category == "Helmet" or category == "Chestplate" or category == "Leggings" or category == "Boots" then
				category = "Armors"
			end

			if not ActiveItems[category] then
				ActiveItems[category] = {}
			end

			local ItemFrame = ItemTemplate:Clone()
			ItemFrame.Name = itemName
			ItemFrame.Background.NameText.Text = itemName
			ItemFrame.Background.Type.Text = ItemData.Type
			ItemFrame.Background.Price.Text = "Price: " .. ItemData.BasePrice
			ItemFrame.Background.Description.Text = ItemData.Description

			-- Format item stats
			local ItemStats = ""
			if ItemData.Stats and next(ItemData.Stats) then
				for key, value in pairs(ItemData.Stats) do
					ItemStats = ItemStats .. key .. ": " .. tostring(value) .. ", "
				end
				ItemStats = ItemStats:sub(1, -3)
			else
				ItemStats = "No stats available"
			end
			ItemFrame.Background.Stats.Text = ItemStats
			ItemFrame.Background.MainItemSlot.UIStroke.Color = rarityColors[ItemData.Rarity]

			local storedViewport = game.ReplicatedStorage.Viewports:FindFirstChild(itemName)
			if storedViewport then
				local newViewport = storedViewport:Clone()
				newViewport.UIStroke:Destroy()
				newViewport.Size = UDim2.new(1, 0, 1, 0)
				newViewport.Name = "ViewportFrame"
				newViewport.Visible = true -- Show or hide based on the toggle
				newViewport.Parent = ItemFrame.Background.MainItemSlot
			else
				warn("Viewport for " .. itemName .. " not found!")
			end

			-- Store in ActiveItems table
			table.insert(ActiveItems[category], ItemFrame)

			-- Purchase logic
			ItemFrame.BuyButton.MouseButton1Click:Connect(function()
				local success, message = shopFunction:InvokeServer("buy", itemName)

				if success then
					script.Sound:Play()
				else
					ItemFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
					task.wait(1.5)
					ItemFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
				end
				newsModule.NewMessage(message, 2)
			end)
		else
			warn("Item data for " .. itemName .. " not found in ItemsData!")
		end
	end

	-- Show only sections with items
	local firstCategory = nil
	for _, category in ipairs(TypePriority) do
		if ActiveItems[category] and #ActiveItems[category] > 0 then
			Categories[category].Visible = true
			if not firstCategory then
				firstCategory = category
			end
		end
	end

	-- Display first available category
	if firstCategory then
		displayItems(firstCategory)
	else
		warn("No items found for any category!")
	end
	Categories.Sell.Visible = true
end

local function populateSellMenu()
	clearItems()
	ActiveItems["Sell"] = {}

	local ItemTemplate = ItemsFrame:FindFirstChild("Template")
	if not ItemTemplate then
		warn("Template not found in ScrollingFrame!")
		return
	end

	-- Get player's items from Backpack
	for _, item in pairs(player.Backpack:GetChildren()) do
		if item:IsA("Tool") and item.Name ~= "Fist" then -- Ensure it's an item the player can sell
			local itemName = item.Name
			-- Updated: Access item data directly from the single module
			local ItemData = itemsData[itemName]
			if ItemData then
				local category = ItemData.Type or "Misc"

				if not ActiveItems[category] then
					ActiveItems[category] = {}
				end

				local ItemFrame = ItemTemplate:Clone()
				ItemFrame.Name = itemName
				ItemFrame.Background.NameText.Text = itemName
				ItemFrame.Background.Type.Text = ItemData.Type
				ItemFrame.Background.Price.Text = "Sell Price: " .. math.floor(ItemData.BasePrice * 0.5) -- 50% of buy price
				ItemFrame.Background.Description.Text = ItemData.Description
				ItemFrame.Background.MainItemSlot.Amount.Text = tostring(item.Amount.Value)
				ItemFrame.Background.MainItemSlot.UIStroke.Color = rarityColors[ItemData.Rarity]
				-- Format item stats
				local ItemStats = ""
				if next(ItemData.Stats) then
					for key, value in pairs(ItemData.Stats) do
						ItemStats = ItemStats .. key .. ": " .. tostring(value) .. ", "
					end
					ItemStats = ItemStats:sub(1, -3)
				else
					ItemStats = "No stats available"
				end
				ItemFrame.Background.Stats.Text = ItemStats

				-- Display item viewport
				local storedViewport = game.ReplicatedStorage.Viewports:FindFirstChild(itemName)
				if storedViewport then
					local newViewport = storedViewport:Clone()
					newViewport.UIStroke:Destroy()
					newViewport.Size = UDim2.new(1, 0, 1, 0)
					newViewport.Name = "ViewportFrame"
					newViewport.Visible = true
					newViewport.Parent = ItemFrame.Background.MainItemSlot
				else
					warn("Viewport for " .. itemName .. " not found!")
				end

				-- Store in ActiveItems table
				table.insert(ActiveItems["Sell"], ItemFrame)

				-- Sell Button Logic
				ItemFrame.BuyButton.Text = "Sell"
				ItemFrame.BuyButton.MouseButton1Click:Connect(function()
					local success, message = shopFunction:InvokeServer("sell", itemName)

					if success then
						if not item then
							ItemFrame:Destroy()
						else
							local amount = item:FindFirstChild("Amount") or nil
							if amount and amount.Value > 0 then
								ItemFrame.Background.MainItemSlot.Amount.Text = tostring(amount.Value)
							else
								ItemFrame:Destroy()
							end
						end
						script.Sound:Play()
					else
						ItemFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
						task.wait(1.5)
						ItemFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
					end		
					newsModule.NewMessage(message, 2)
				end)
			else
				warn("Item data for " .. itemName .. " not found in ItemsData!")
			end
		end
	end

	-- Show only sections with items
	local firstCategory = nil
	for _, category in ipairs(TypePriority) do
		if ActiveItems[category] and #ActiveItems[category] > 0 then
			Categories[category].Visible = true
			if not firstCategory then
				firstCategory = category
			end
		end
	end


	displayItems("Sell")
	Categories.Sell.Visible = true
end

function Shop.Start()

	-- Connect section buttons to display items
	for category, button in pairs(Categories) do
		button.MouseButton1Click:Connect(function()
			if category == "Sell" then
				populateSellMenu()
			else
				displayItems(category)
			end
		end)
	end

	shopEvent.OnClientEvent:Connect(function(npcName)
		populateMarket(npcName)
		ShopFrame:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = false
		MainGui.Dialog.Visible = false
	end)

	ShopFrame.Close.MouseButton1Click:Connect(function()
		ShopFrame:TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = true
		MainGui.Hotbar.Visible = true
		dialogEvent:FireServer("EndDialog")
	end)

	Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	player:WaitForChild("Data"):WaitForChild("HackSilver").Changed:Connect(function()
		Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	end)
end

return Shop
