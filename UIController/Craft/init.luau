local Craft = {}

local player = game:GetService("Players").LocalPlayer

local backpack = player:WaitForChild("Backpack") 

local RS = game:GetService("ReplicatedStorage")
local craftEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftEvent")
local craftFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftFunction")
local dialogEvent = RS:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))
local newsModule = require(RS:WaitForChild("Modules"):WaitForChild("News"))
local smiths = require(script.Smiths)
local recipes = require(RS:WaitForChild("Modules"):WaitForChild("Recipes"))

--// GUI References
local MainGui = script.Parent.Parent
local CraftFrame = MainGui.Crafting
local ItemsFrame = CraftFrame.ItemsMenu.ScrollingFrame
local Sections = CraftFrame.IndexSection

local Categories = {
	Weapons = Sections.Weapons,
	Armors = Sections.Armors,
	Food = Sections.Food,
	Herbs = Sections.Herbs,
	Resourses = Sections.Resourses,
	Misc = Sections.Misc
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
			v:Destroy()
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
	if ActiveItems[category] then
		for _, itemFrame in pairs(ActiveItems[category]) do
			itemFrame.Parent = ItemsFrame
			itemFrame.Visible = true
		end
	end
end

local function populateCrafts(npcName)
	if not smiths[npcName] then
		warn("Crafting data for " .. npcName .. " is missing or invalid!")
		return
	end

	clearItems()
	clearSections()
	ActiveItems = {}

	local ItemTemplate = ItemsFrame:FindFirstChild("Template")
	if not ItemTemplate then
		warn("Template not found in ScrollingFrame!")
		return
	end

	-- Organize items into categories
	for _, itemName in pairs(smiths[npcName].Items) do
		-- Updated: Access item data directly from the single module
		local ItemData = itemsData[itemName]
		if ItemData then
			-- Normalize category for weapons
			local category = ItemData.Type or "Misc"
			if category == "Sword" or category == "HeavyAxe" or category == "Gauntlet" then
				category = "Weapons"
			end

			if not ActiveItems[category] then
				ActiveItems[category] = {}
			end

			local ItemFrame = ItemTemplate:Clone()
			ItemFrame.Name = itemName
			ItemFrame.Background.NameText.Text = itemName
			ItemFrame.Background.Type.Text = ItemData.Type
			ItemFrame.Background.MainItemSlot.UIStroke.Color = rarityColors[ItemData.Rarity]
			local craftingPrice = ItemData.BasePrice/2
			ItemFrame.Background.CraftingPrice.Text = craftingPrice

			-- Display crafting recipe
			local step = 1 -- Move step outside the loop

			for material, amount in pairs(recipes[itemName]) do
				-- Ensure the slot exists before trying to modify it
				local item = backpack:FindFirstChild(material)

				local slotName = "ItemSlot" .. step
				local slotFrame = ItemFrame.Background:FindFirstChild(slotName)

				if slotFrame then
					if item then
						slotFrame.Amount.Text = item.Amount.Value .. "/" .. amount
						item.Amount.Changed:Connect(function()
							slotFrame.Amount.Text = item.Amount.Value .. "/" .. amount
						end)
					end

					local storedViewport = game.ReplicatedStorage.Viewports:FindFirstChild(material)
					if storedViewport then
						local newViewport = storedViewport:Clone()
						newViewport.UIStroke:Destroy()
						newViewport.Size = UDim2.new(0.9, 0, 0.9, 0)
						newViewport.Name = "ViewportFrame"
						newViewport.Visible = true
						newViewport.Parent = slotFrame
					else
						warn("Viewport for " .. material .. " not found!")
					end
				else
					warn("Slot " .. slotName .. " not found!")
				end

				step += 1 -- Increment step correctly
			end
			if step == 3 then
				ItemFrame.Background.ItemSlot3.Visible = false
			end

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
			table.insert(ActiveItems[category], ItemFrame)

			-- Crafting logic
			ItemFrame.CraftingButton.MouseButton1Click:Connect(function()
				local success, message = craftFunction:InvokeServer(itemName)

				if success then
					script.Sound:Play()
				else
					ItemFrame.CraftingButton.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
					task.delay(2, function()
						if ItemFrame and ItemFrame:FindFirstChild("CraftingButton") then
							ItemFrame.CraftingButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
						end
					end)
				end
				newsModule.NewMessage(message, 2)
			end)
		else
			warn("Item data for " .. itemName .. " not found in ItemsData!")
		end
	end

	-- Display only the sections that have items
	local firstCategory = nil
	for _, category in ipairs(TypePriority) do
		if ActiveItems[category] then
			Categories[category].Visible = true
			if not firstCategory then
				firstCategory = category
			end
		end
	end

	-- Display the first available category
	if firstCategory then
		displayItems(firstCategory)
	end
end

function Craft.Start()
	-- Connect section buttons to display items
	for category, button in pairs(Categories) do
		button.MouseButton1Click:Connect(function()
			displayItems(category)
		end)
	end

	craftEvent.OnClientEvent:Connect(function(npcName)
		populateCrafts(npcName)
		CraftFrame:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = false
		MainGui.Dialog.Visible = false
	end)

	CraftFrame.Close.MouseButton1Click:Connect(function()
		CraftFrame:TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = true
		MainGui.Hotbar.Visible = true
		MainGui.Dialog.Visible = true
		dialogEvent:FireServer("EndDialog")
	end)

	Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	player:WaitForChild("Data"):WaitForChild("HackSilver").Changed:Connect(function()
		Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	end)
end

return Craft