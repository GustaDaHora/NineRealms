local BonFire = {}

local player = game:GetService("Players").LocalPlayer

local RS = game:GetService("ReplicatedStorage")
local bonfireEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireEvent")
local bonfireFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireFunction")
local dialogEvent = RS:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local newsModule = require(RS:WaitForChild("Modules"):WaitForChild("News"))
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))
local recipes = require(RS:WaitForChild("Modules"):WaitForChild("Recipes"))
local cooking = require(script.Cooking)

--// GUI References
local MainGui = script.Parent.Parent
local BonFireFrame = MainGui.BonFire
local ItemsFrame = BonFireFrame.ItemsMenu.ScrollingFrame
local Sections = BonFireFrame.IndexSection

local rarityColors = {
	Common = Color3.fromRGB(57, 50, 43),
	Uncommon = Color3.fromRGB(50, 200, 50),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(150, 70, 200),
	Legendary = Color3.fromRGB(255, 110, 50),
}

local cookingLevelOrder = {
	Beginner = 1,
	Intermediate = 2,
	Advanced = 3,
	Expert = 4,
}

local ActiveMeals = {}

local tierOrder = {
	"Newcomer",
	"Novice",
	"Skilled",
	"Veteran",
	"Elite",
	"Champion",
}

local tierIndex = {}
for i, tier in ipairs(tierOrder) do
	tierIndex[tier] = i
end

local function clearItems()
	for _, v in pairs(ItemsFrame:GetChildren()) do
		if v:IsA("Frame") and v.Name ~= "Template" then
			v:Destroy()
		end
	end
end

local function displayMeals()
	clearItems()
	for _, mealFrame in pairs(ActiveMeals) do
		mealFrame.Parent = ItemsFrame
		mealFrame.Visible = true
	end
end

local function getMealRequiredLevel(mealName, recipeTiers)
	for tier, meals in pairs(recipeTiers) do
		for _, name in ipairs(meals) do
			if name == mealName then
				return tier
			end
		end
	end
	warn("Meal \"" .. tostring(mealName) .. "\" not found in any tier.")
	return nil
end

local function populateMeals()
	clearItems()
	ActiveMeals = {}

	local ItemTemplate = ItemsFrame:FindFirstChild("Template")
	if not ItemTemplate then
		warn("Template not found in ScrollingFrame!")
		return
	end

	for mealName, recipe in pairs(recipes) do
		local ItemData = itemsData[mealName]
		if ItemData.Type ~= "Food" then continue end
		local requiredTier = getMealRequiredLevel(mealName, cooking) -- e.g., "Novice"
		local playerTier = player:WaitForChild("Data"):WaitForChild("Tier").Value
		local requiredIndex = tierIndex[requiredTier]
		local playerIndex = tierIndex[playerTier]
		if requiredIndex == nil then
			warn("Required tier \"" .. tostring(requiredTier) .. "\" is not defined in tierIndex.")
			return
		end

		if playerIndex == nil then
			warn("Player tier \"" .. tostring(playerTier) .. "\" is not defined in tierIndex.")
			return
		end
		local hasRequiredTier = playerIndex >= requiredIndex
		if hasRequiredTier then
			local MealFrame = ItemTemplate:Clone()
			MealFrame.Background.NameText.Text = mealName
			MealFrame.Background.Type.Text = ItemData.Type
			MealFrame.Background.CraftingPrice = ItemData.BasePrice
			MealFrame.Background.MainItemSlot.UIStroke.Color = rarityColors[ItemData.Rarity]
			-- Recipe display
			local step = 1
			for ingredient, amount in pairs(recipe) do
				local slotName = "ItemSlot" .. step
				local slotFrame = MealFrame.Background:FindFirstChild(slotName)
				local item = player.Backpack:FindFirstChild(ingredient)
				if slotFrame then
					if item then
						slotFrame.Amount.Text = item.Amount.Value .. "/" .. amount
						item.Amount.Changed:Connect(function()
							slotFrame.Amount.Text = item.Amount.Value .. "/" .. amount
						end)
					else
						slotFrame.Amount.Text = "0/" .. amount
					end
					local storedViewport = game.ReplicatedStorage.Viewports:FindFirstChild(ingredient)
					if storedViewport then
						local newViewport = storedViewport:Clone()
						newViewport.UIStroke:Destroy()
						newViewport.Size = UDim2.new(0.9, 0, 0.9, 0)
						newViewport.Name = "ViewportFrame"
						newViewport.Visible = true
						newViewport.Parent = slotFrame
					end
				end
				step += 1
			end
			if step == 3 then
				MealFrame.Background.ItemSlot3.Visible = false
			end
			-- Stats
			local ItemStats = ""
			if ItemData.Stats and next(ItemData.Stats) then
				for key, value in pairs(ItemData.Stats) do
					ItemStats = ItemStats .. key .. ": " .. tostring(value) .. ", "
				end
				ItemStats = ItemStats:sub(1, -3)
			else
				ItemStats = "No stats available"
			end
			MealFrame.Background.Stats.Text = ItemStats

			-- Main viewport
			local storedViewport = game.ReplicatedStorage.Viewports:FindFirstChild(mealName)
			if storedViewport then
				local newViewport = storedViewport:Clone()
				newViewport.UIStroke:Destroy()
				newViewport.Size = UDim2.new(1, 0, 1, 0)
				newViewport.Name = "ViewportFrame"
				newViewport.Visible = true
				newViewport.Parent = MealFrame.Background.MainItemSlot
			end

			table.insert(ActiveMeals, MealFrame)

			MealFrame.Name = mealName
			-- Cook logic
			MealFrame.CraftingButton.Text = "Cook"
			MealFrame.CraftingButton.MouseButton1Click:Connect(function()
				local success, message = bonfireFunction:InvokeServer(mealName)
				if success then
					script.Sound:Play()
				else
					MealFrame.CraftingButton.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
					task.delay(2, function()
						if MealFrame and MealFrame:FindFirstChild("CraftingButton") then
							MealFrame.CraftingButton.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
						end
					end)
				end
				newsModule.NewMessage(message, 2)
			end)
		end
	end
end


function BonFire.Start()
	bonfireEvent.OnClientEvent:Connect(function()
		populateMeals()
		displayMeals()
		BonFireFrame:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = false
		MainGui.Dialog.Visible = false
	end)

	BonFireFrame.Close.MouseButton1Click:Connect(function()
		BonFireFrame:TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
		MainGui.Hud.Visible = true
		MainGui.Hotbar.Visible = true
		dialogEvent:FireServer("EndDialog")
	end)

	Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	player:WaitForChild("Data"):WaitForChild("HackSilver").Changed:Connect(function()
		Sections.Money.Text = "$" .. player:WaitForChild("Data"):WaitForChild("HackSilver").Value
	end)
end

return BonFire
