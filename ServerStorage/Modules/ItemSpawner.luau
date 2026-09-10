local ItemSpawner = {}

local SummonItem = game.ReplicatedStorage.RE.Items.SummonItemEvent

-- Drop tables with item chances
ItemSpawner.DropTables = {
	Tree = {
		{Name = "Wood", Chance = 25},
		{Name = "Red Apple", Chance = 12},
		{Name = "Green Apple", Chance = 7},
		{Name = "Golden Apple", Chance = 1}
	},
	Bush = {
		{Name = "Red Berry", Chance = 25},
		{Name = "Blue Berry", Chance = 14},
		{Name = "Frozen Berry", Chance = 7}
	},
	IronOre = {
		{Name = "Iron", Chance = 100}
	},
	SilverOre = {
		{Name = "Silver", Chance = 100}	
	},
	Boar = {
		{Name = "Boar Skin", Chance = 50},
		{Name = "Boar Flesh", Chance = 50}
	},
	Draug = {
		{Name = "Bone", Chance = 60},
		{Name = "Rusty Sword", Chance = 30}
	},
	GenericBox = {
		{Name = "Wood", Chance = 10},
		{Name = "Red Apple", Chance = 10},
		{Name = "Red Berry", Chance = 9},
		{Name = "Green Apple", Chance = 7},
		{Name = "Blue Berry", Chance = 6},
		{Name = "Boar Skin", Chance = 5},
		{Name = "Boar Flesh", Chance = 5},
		{Name = "Iron", Chance = 4},
		{Name = "Silver", Chance = 3},
		{Name = "Frozen Berry", Chance = 2},
		{Name = "Torch", Chance = 4},
		{Name = "Cooked Meat", Chance = 3},
		{Name = "Red Mushroom", Chance = 2},
		{Name = "Cabbage", Chance = 2},
		{Name = "Brown Mushroom", Chance = 2},
		{Name = "Turnip", Chance = 1},
	},
	BigBox = {
		{Name = "Wood", Chance = 10},
		{Name = "Iron", Chance = 7},
		{Name = "Silver", Chance = 5},
		{Name = "Golden Apple", Chance = 2},
		{Name = "Frozen Berry", Chance = 3},
		{Name = "Blue Berry", Chance = 6},
		{Name = "Green Apple", Chance = 5},
		{Name = "Boar Skin", Chance = 4},
		{Name = "Cooked Meat", Chance = 5},
		{Name = "Charcoal Stew", Chance = 2},
		{Name = "Torch", Chance = 3},
		{Name = "Lantern", Chance = 3},
		{Name = "Red Apple", Chance = 5},
		{Name = "Berry Tart", Chance = 1},
		{Name = "Honey", Chance = 2},
		{Name = "Cod", Chance = 2},
		{Name = "Mead Tonic", Chance = 1},
	},
	["Chest"] = {
		{Name = "Red Apple", Chance = 8},
		{Name = "Green Apple", Chance = 6},
		{Name = "Golden Apple", Chance = 2},
		{Name = "Frozen Berry", Chance = 2},
		{Name = "Boar Flesh", Chance = 5},
		{Name = "Silver", Chance = 5},
		{Name = "Iron", Chance = 7},
		{Name = "Torch", Chance = 3},
		{Name = "Cooked Meat", Chance = 5},
		{Name = "Red Berry", Chance = 5},
		{Name = "Blue Berry", Chance = 5},
		{Name = "Orange Berry", Chance = 4},
		{Name = "Turnip", Chance = 3},
		{Name = "Clover", Chance = 2},
		{Name = "Honey", Chance = 3},
		{Name = "Boar Stew", Chance = 2},
		{Name = "Yarrow", Chance = 1},
	},
	["Bronze Chest"] = {
		{Name = "Silver Sword", Chance = 3},
		{Name = "Rusty Sword", Chance = 4},
		{Name = "Iron", Chance = 5},
		{Name = "Silver", Chance = 5},
		{Name = "Golden Apple", Chance = 2},
		{Name = "Frozen Berry", Chance = 2},
		{Name = "Yarrow", Chance = 2},
		{Name = "Red Apple", Chance = 5},
		{Name = "Red Berry", Chance = 4},
		{Name = "Cooked Meat", Chance = 4},
		{Name = "Honey", Chance = 3},
		{Name = "Boar Flesh", Chance = 4},
		{Name = "Torch", Chance = 2},
		{Name = "Brown Mushroom", Chance = 2},
		{Name = "Berry Tart", Chance = 2},
		{Name = "Charcoal Stew", Chance = 2},
	},
	["Silver Chest"] = {
		{Name = "Silver Sword", Chance = 4},
		{Name = "Iron Sword", Chance = 5},
		{Name = "Heavy Boots", Chance = 2},
		{Name = "Firefly Rod", Chance = 1},
		{Name = "Silver", Chance = 6},
		{Name = "Golden Apple", Chance = 4},
		{Name = "Frozen Berry", Chance = 3},
		{Name = "Cooked Meat", Chance = 4},
		{Name = "Yarrow Extract", Chance = 2},
		{Name = "Honey Cake", Chance = 2},
		{Name = "Berry Tart", Chance = 3},
		{Name = "Mead Tonic", Chance = 2},
		{Name = "Charcoal Stew", Chance = 2},
		{Name = "Blue Fish", Chance = 2},
	},
	["Golden Chest"] = {
		{Name = "Stormcarver", Chance = 4},
		{Name = "Firefly Rod", Chance = 4},
		{Name = "Golden Apple", Chance = 10},
		{Name = "Frozen Berry", Chance = 5},
		{Name = "Heavy Chestplate", Chance = 3},
		{Name = "Heavy Helmet", Chance = 2},
		{Name = "Golden Pompano Delight", Chance = 2},
		{Name = "Frostleaf Elixir", Chance = 3},
		{Name = "Mead Tonic", Chance = 3},
		{Name = "Honey Cake", Chance = 2},
		{Name = "Blue Fish Skewer", Chance = 2},
		{Name = "Wild Forest Bread", Chance = 2},
		{Name = "Giant Golden Egg", Chance = 2},
		{Name = "Golden Jam", Chance = 1},
	},
}

-- Function to select an item based on chance
local function getRandomItem(dropTable)
	local roll = math.random(1, 100) -- Roll a number between 1-100
	local cumulativeChance = 0

	for _, item in ipairs(dropTable) do
		cumulativeChance = cumulativeChance + item.Chance
		if roll <= cumulativeChance then
			return item.Name
		end
	end
end

-- Function to spawn an item
function ItemSpawner.SpawnItem(position, category)
	local dropTable = ItemSpawner.DropTables[category]
	if not dropTable then
		warn("Invalid category:", category)
		return nil
	end

	local selectedItem = getRandomItem(dropTable)

	if selectedItem then
		SummonItem:Fire(selectedItem, position)
		return selectedItem
	end

	return nil
end

return ItemSpawner
