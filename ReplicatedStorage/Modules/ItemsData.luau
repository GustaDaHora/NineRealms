-- Readonly data for items in the game.
local ItemsData = {
	-- Weapons
	["Fist"] = {
		Type = "Gauntlet",
		Rarity = "Common",
		Description = "This is your Fist you can use it to hit others.",
		Stats = { Power = 1, Weight = 1 },
	},
	["Silver Sword"] = {
		Type = "Sword",
		Rarity = "Uncommon",
		BasePrice = 150,
		Description = "A sword made of silver, good for cutting monsters.",
		Stats = { Power = 8, Weight = 1 },
	},
	["Rusty Sword"] = {
		Type = "Sword",
		Rarity = "Common",
		BasePrice = 10,
		Description = "An old sword that was used by many when dialogue was not viable.",
		Stats = { Power = 2, Weight = 1 },
	},
	["Iron Sword"] = {
		Type = "Sword",
		Rarity = "Common",
		BasePrice = 50,
		Description = "A sword made of cast iron, popular among newbies.",
		Stats = { Power = 5, Weight = 1 },
	},
	["Stormcarver"] = {
		Type = "HeavyAxe",
		Rarity = "Rare",
		BasePrice = 300,
		Description = "A heavy axe imbued with the power of the storm. It can cleave through enemies with ease.",
		Stats = { Power = 12, Weight = 5 },
	},
	["Heavy Iron Axe"] = {
		Type = "HeavyAxe",
		Rarity = "Uncommon",
		BasePrice = 125,
		Description = "A heavy axe made of cast iron, perfect for breaking through heavy armor.",
		Stats = { Power = 8, Weight = 7 },
	},

	-- Armor
	["Heavy Leggings"] = {
		Type = "Leggings",
		Rarity = "Rare",
		BasePrice = 380,
		Description = "A leggings made of cast iron that can withstand heavy blows.",
		Armorset = "HeavySet",
		Parts = { Waist = "Heavy Waist", RightLeg = "Heavy RLeg", LeftLeg = "Heavy LLeg" },
		Armor = 70,
		Stats = { Agility = 0, Weight = 15 },
	},
	["Heavy Helmet"] = {
		Type = "Helmet",
		Rarity = "Rare",
		BasePrice = 140,
		Description = "A helmet made of cast iron that can withstand heavy blows.",
		Armorset = "HeavySet",
		Parts = { Helmet = "Heavy Helmet" },
		Armor = 50,
		Stats = { Agility = 0, Weight = 7 },
	},
	["Heavy Chestplate"] = {
		Type = "Chestplate",
		Rarity = "Rare",
		BasePrice = 500,
		Description = "A chestplate made of cast iron that can withstand heavy blows.",
		Armorset = "HeavySet",
		Parts = {
			Chestplate = "Heavy Chestplate",
			RightShoulder = "Heavy RShoulder",
			LeftShoulder = "Heavy LShoulder",
			RightArm = "Heavy RArm",
			LeftArm = "Heavy LArm",
		},
		Armor = 100,
		Stats = { Agility = 0, Weight = 20 },
	},
	["Heavy Boots"] = {
		Type = "Boots",
		Rarity = "Uncommon",
		BasePrice = 180,
		Description = "A boots made of cast iron that can withstand heavy blows.",
		Armorset = "HeavySet",
		Parts = { RightBoots = "Heavy RBoots", LeftBoots = "Heavy LBoots" },
		Armor = 55, 
		Stats = { Agility = 0, Weight = 5 },
	},

	-- Artifacts & Misc
	["Firefly Rod"] = {
		Type = "Artifact",
		Rarity = "Epic",
		BasePrice = 400,
		Description = "A rod carrying a colony of bioluminescent fireflies that will glow to light your way. Grants night vision.",
		Stats = { Weight = 1 },
	},
	["Torch"] = {
		Type = "Misc",
		Rarity = "Common",
		BasePrice = 15,
		Description = "A torch that will guide you in the darkness.",
		Stats = { Armor = 0, ElemRes = 0, Power = 0, Weight = 1 },
	},
	["Lantern"] = {
		Type = "Misc",
		Rarity = "Common",
		BasePrice = 15,
		Description = "A Lantern that shines brightly",
		Stats = { Armor = 0, ElemRes = 0, Power = 0, Weight = 1 },
	},

	-- Resources
	["Wood"] = {
		Type = "Resource",
		Rarity = "Common",
		BasePrice = 5,
		Description = "Wood, can catch fire.",
		Stats = { Weight = 5 },
	},
	["Silver"] = {
		Type = "Resource",
		Rarity = "Uncommon",
		BasePrice = 25,
		Description = "A shiny piece of silver that is valued in the market",
		Stats = { Weight = 10 },
	},
	["Iron"] = {
		Type = "Resource",
		Rarity = "Common",
		BasePrice = 225,
		Description = "A tough rock that can be melted and forged into a weapon by skilled hands.",
		Stats = { Weight = 10 },
	},
	["Boar Skin"] = {
		Type = "Resource",
		Rarity = "Common",
		BasePrice = 10,
		Description = "Boar skin relatively soft.",
		Stats = { Weight = 3 },
	},

	-- Food
	["Red Mushroom"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 5,
		Description = "A red mushroom with a sour and acidic flavor.",
		Stats = { Regen = 5, Weight = 1 },
		Effects = { "Poison" },
	},
	["Red Berry"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 5,
		Description = "An ordinary berry that makes you feel better.",
		Stats = { Regen = 5, Weight = 1 },
	},
	["Red Apple"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 10,
		Description = "An ordinary apple that makes you feel better.",
		Stats = { Regen = 15, Weight = 1 },
	},
	["Orange Berry"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 10,
		Description = "An tasty orange berry that can be used in other recipes.",
		Stats = { Regen = 10, Weight = 1 },
	},
	["Green Berry"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 10,
		Description = "A green berry with a horrible bitter taste.",
		Stats = { Regen = 0, Weight = 1 },
		Effects = { "Poison" },
	},
	["Green Apple"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 50,
		Description = "A green apple that easily camouflages itself among the leaves.",
		Stats = { Regen = 30, Weight = 1 },
	},
	["Golden Apple"] = {
		Type = "Food",
		Rarity = "Legendary",
		BasePrice = 350,
		Description = "A rare berry found in cold places is highly valuable.",
		Stats = { Regen = 120, Weight = 3 },
	},
	["Frozen Berry"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 25,
		Description = "An unusual berry with medicinal properties.",
		Stats = { Regen = 30, Weight = 1 }, 
	},
	["Cooked Meat"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 30,
		Description = "Strong warriors consume a great deal of these, claiming it's the source of their strength.",
		Stats = { Regen = 50, Weight = 1 },
	},
	["Brown Mushroom"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 15,
		Description = "A brown mushroom that grows in the woods.",
		Stats = { Regen = 15, Weight = 1 },
		Effects = { "Poison" },
	},
	["Boar Flesh"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 15,
		Description = "Wild boar meat can be eaten this way, but I do not recommend it.",
		Stats = { Regen = 5, Weight = 1 },
	},
	["Blue Berry"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 40,
		Description = "An unusual berry with medicinal properties.",
		Stats = { Regen = 30, Weight = 1 },
	},
	["Cabbage"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 8,
		Description = "A leafy green vegetable, crunchy and refreshing.",
		Stats = { Regen = 7, Weight = 1 },
	},
	["Clover"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 6,
		Description = "A lucky clover, sometimes eaten for good fortune.",
		Stats = { Regen = 3, Weight = 1 },
		Effects = { "Luck" },
	},
	["Egg"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 10,
		Description = "A simple egg, can be cooked or eaten raw.",
		Stats = { Regen = 8, Weight = 1 },
	},
	["Giant Egg"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 30,
		Description = "A huge egg, packed with nutrients.",
		Stats = { Regen = 25, Weight = 2 },
	},
	["Giant Golden Egg"] = {
		Type = "Food",
		Rarity = "Legendary",
		BasePrice = 400,
		Description = "A massive golden egg, radiating with energy.",
		Stats = { Regen = 150, Weight = 3 },
		Effects = { "Luck", "Heal" },
	},
	["Golden Egg"] = {
		Type = "Food",
		Rarity = "Epic",
		BasePrice = 120,
		Description = "A rare golden egg, said to bring fortune.",
		Stats = { Regen = 60, Weight = 1 },
		Effects = { "Luck" },
	},
	["Beetroot"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 8,
		Description = "A sweet, earthy root vegetable.",
		Stats = { Regen = 7, Weight = 1 },
	},
	["Honey"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 35,
		Description = "A jar of sweet honey, restores energy quickly.",
		Stats = { Regen = 35, Weight = 1 },
		Effects = { "Heal" },
	},
	["Sorrel"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 6,
		Description = "A tangy green herb, often used in salads.",
		Stats = { Regen = 4, Weight = 1 },
	},
	["StrawBerry"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 18,
		Description = "A sweet, juicy berry loved by all.",
		Stats = { Regen = 15, Weight = 1 },
	},
	["Turnip"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 7,
		Description = "A mild root vegetable, filling and nutritious.",
		Stats = { Regen = 6, Weight = 1 },
	},
	["Yarrow"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 22,
		Description = "A medicinal herb, used for healing.",
		Stats = { Regen = 20, Weight = 1 },
		Effects = { "Heal" },
	},
	["Boar Stew"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 60,
		Description = "A warm stew made from boar meat, restores vitality.",
		Stats = { Regen = 60, Weight = 2 },
		Effects = { "Heal" },
	},
	["Herb-Grilled Fish"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 55,
		Description = "Fish seasoned with forest herbs and fire-grilled.",
		Stats = { Regen = 50, Weight = 2 },
		Effects = { "Heal" },
	},
	["Root Soup"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 35,
		Description = "A chunky soup made from turnips, beets and cabbage.",
		Stats = { Regen = 40, Weight = 2 },
		Effects = { "Heal" },
	},
	["Egg & Meat Skewer"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 65,
		Description = "Eggs and grilled meat skewered over an open fire.",
		Stats = { Regen = 65, Weight = 2 },
		Effects = { "Heal" },
	},
	["Honey Cake"] = {
		Type = "Food",
		Rarity = "Rare",
		BasePrice = 90,
		Description = "A soft cake infused with wild honey. Lightens your step.",
		Stats = { Regen = 20, Weight = 1 },
		Effects = { "Agility" },
	},
	["Berry Tart"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 75,
		Description = "A fresh tart made with strawberries and red berries.",
		Stats = { Regen = 25, Weight = 1 },
		Effects = { "Agility" },
	},
	["Golden Jam"] = {
		Type = "Food",
		Rarity = "Epic",
		BasePrice = 150,
		Description = "A rare golden apple jam that energizes your movements.",
		Stats = { Regen = 35, Weight = 1 },
		Effects = { "Agility" },
	},
	["Frostberry Sorbet"] = {
		Type = "Food",
		Rarity = "Rare",
		BasePrice = 100,
		Description = "A cold, sweet treat made from frozen berries.",
		Stats = { Regen = 20, Weight = 1 },
		Effects = { "Agility" },
	},
	["Spiced Berry Stew"] = {
		Type = "Food",
		Rarity = "Rare",
		BasePrice = 110,
		Description = "A surprising blend of meat and sweet berries.",
		Stats = { Regen = 50, Weight = 2 },
		Effects = { "Heal", "Agility" },
	},
	["Clover Pie"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 80,
		Description = "A pie made with clover and red berries — bittersweet and energizing.",
		Stats = { Regen = 30, Weight = 1 },
		Effects = { "Heal", "Agility" },
	},
	["Wild Forest Bread"] = {
		Type = "Food",
		Rarity = "Rare",
		BasePrice = 95,
		Description = "Bread baked with honey, herbs, and dried fruits. Restores both body and reflexes.",
		Stats = { Regen = 40, Weight = 2 },
		Effects = { "Heal", "Agility" },
	},
	["Yarrow Extract"] = {
		Type = "Medicine",
		Rarity = "Uncommon",
		BasePrice = 45,
		Description = "Concentrated healing from the yarrow plant.",
		Stats = { Regen = 60, Weight = 1 },
		Effects = { "Heal" },
	},
	["Mead Tonic"] = {
		Type = "Medicine",
		Rarity = "Rare",
		BasePrice = 80,
		Description = "A potent drink brewed with honey and herbs.",
		Stats = { Regen = 75, Weight = 1 },
		Effects = { "Heal" },
	},
	["Icy Root Brew"] = {
		Type = "Medicine",
		Rarity = "Rare",
		BasePrice = 100,
		Description = "A frigid herbal brew that protects against the cold.",
		Stats = { Regen = 15, Weight = 1 },
		Effects = { "ColdImmunity" },
	},
	["Frostleaf Elixir"] = {
		Type = "Medicine",
		Rarity = "Epic",
		BasePrice = 160,
		Description = "An ancient elixir brewed from frostleaf and snow herbs.",
		Stats = { Regen = 20, Weight = 1 },
		Effects = { "Heal", "ColdImmunity" },
	},
	["Charcoal Stew"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 60,
		Description = "A thick stew laced with herbs and charcoal, neutralizing toxins.",
		Stats = { Regen = 40, Weight = 2 },
		Effects = { "PoisonResistance" },
	},
	["Bitter Moss Tonic"] = {
		Type = "Medicine",
		Rarity = "Uncommon",
		BasePrice = 55,
		Description = "A pungent tonic brewed with swamp moss — tough to drink, but potent.",
		Stats = { Regen = 20, Weight = 1 },
		Effects = { "PoisonResistance" },
	},
	["Cod"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 12,
		Description = "A common freshwater fish, mild in flavor.",
		Stats = { Regen = 10, Weight = 1 },
	},
	["Blue Fish"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 22,
		Description = "A rare blue-scaled fish, prized for its taste.",
		Stats = { Regen = 18, Weight = 1 },
	},
	["Mullet"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 14,
		Description = "A small, oily fish found in rivers and lakes.",
		Stats = { Regen = 12, Weight = 1 },
	},
	["Pompano"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 28,
		Description = "A delicious, fatty fish with golden scales.",
		Stats = { Regen = 22, Weight = 1 },
	},
	["Grilled Cod"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 25,
		Description = "A lightly seasoned cod grilled over firewood. Simple and filling.",
		Stats = { Regen = 25, Weight = 1 },
		Effects = { "Heal" },
	},
	["Smoked Mullet"] = {
		Type = "Food",
		Rarity = "Common",
		BasePrice = 28,
		Description = "Mullet preserved through smoking, rich in oils and flavor.",
		Stats = { Regen = 30, Weight = 1 },
		Effects = { "Heal" },
	},
	["Fried Pompano"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 45,
		Description = "Golden pompano fried in oil with aromatic spices. A true delicacy.",
		Stats = { Regen = 40, Weight = 1 },
		Effects = { "Heal" },
	},
	["Fish Stew"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 50,
		Description = "A hearty stew made with cod, mullet, and vegetables. Restorative and warm.",
		Stats = { Regen = 50, Weight = 2 },
		Effects = { "Heal" },
	},
	["Blue Fish Skewer"] = {
		Type = "Food",
		Rarity = "Uncommon",
		BasePrice = 42,
		Description = "Tender chunks of blue fish and berries grilled on a stick.",
		Stats = { Regen = 35, Weight = 1 },
		Effects = { "Agility" },
	},
	["Golden Pompano Delight"] = {
		Type = "Food",
		Rarity = "Rare",
		BasePrice = 95,
		Description = "A rich dish of pompano glazed with honey and herbs. Both elegant and energizing.",
		Stats = { Regen = 65, Weight = 2 },
		Effects = { "Heal", "Luck" },
	},
}

return ItemsData

--[[
| Rarity     | Power (Weapon)| Regen (Food) | Armor (Armor) | Price Range |
|------------|---------------|--------------|---------------|-------------|
| Common     | 1–5           | 0–15         | 0–40          | 5–50        |
| Uncommon   | 6–10          | 16–30        | 41–70         | 51–150      |
| Rare       | 11–15         | 31–60        | 71–100        | 151–400     |
| Epic       | 16–20         | 61–100       | 101–150       | 401–600     |
| Legendary  | 21+           | 101+         | 151+          | 601+        |

| Type         | Description                                            | Stats                        | Effects                |
|--------------|--------------------------------------------------------|-------------------------------|------------------------|
| Weapon       | A weapon used to attack enemies.                       | Power, Weight                 | None                   |
| HeavyWeapon  | A heavy weapon that deals more damage but is slower.   | Power, Weight                 | None                   |
| Leggings     | Armor for the legs.                                    | Armor, Agility, Weight        | None                   |
| Helmet       | Armor for the head.                                    | Armor, Agility, Weight        | None                   |
| Chestplate   | Armor for the chest.                                   | Armor, Agility, Weight        | None                   |
| Boots        | Armor for the feet.                                    | Armor, Agility, Weight        | None                   |
| Artifact     | A special item with unique properties.                 | Weight                        | None                   |
| Misc         | A miscellaneous item with no special properties.       | Armor, ElemRes, Power, Weight | None                   |
| Resource     | A resource used for crafting or trading.               | Weight                        | None                   |
| Food         | Consumable to restore health or provide effects.       | Regen, Weight                 | Poison, Healing, Buffs |

| Rarity     | Description                                                        |
|------------|--------------------------------------------------------------------|
| Common     | Easily found, low value.                                           |
| Uncommon   | More valuable, harder to find.                                     |
| Rare       | Valuable, often unique properties.                                 |
| Epic       | Very valuable, powerful properties.                                |
| Legendary  | Extremely rare, powerful, highly sought after.                     |

| Stats     | Description                                                        |
|------------|--------------------------------------------------------------------|
| Power      | Damage dealt by a weapon.                                          |
| Regen      | Health restored by food.                                           |
| Armor      | Protection provided by armor.                                      |
| Agility    | Speed from armor.                                                  |
| Weight     | Item weight, affects inventory/movement.                           |
| ElemRes    | Elemental resistance from armor.                                   |
| Effects    | Special effects from food/artifacts (e.g., poison, healing).       |

| Effects    | Description                                                        |
|------------|--------------------------------------------------------------------|
| Poison     | Causes damage over time or negative effects when consumed.         |
| Healing    | Restores health when consumed.                                     |
| Buffs      | Temporary boosts to stats or abilities when consumed.              |

| Parts         | Description                                               | <-- Based on character rigging.
|---------------|-----------------------------------------------------------|
| Helmet        | Armor part that goes on the head. (Helmet)                |
| Waist         | Armor part that goes on the waist. (Chestplate)           |
| RightShoulder | Armor part that goes on the right shoulder. (Chestplate)  |
| LeftShoulder  | Armor part that goes on the left shoulder. (Chestplate)   |
| RightArm      | Armor part that goes on the right arm. (Chestplate)       |
| LeftArm       | Armor part that goes on the left arm. (Chestplate)        |
| RightLeg      | Armor part that goes on the right leg. (Leggings)         |
| LeftLeg       | Armor part that goes on the left leg. (Leggings)          |
| RightBoots    | Armor part that goes on the right foot. (Boots)           |
| LeftBoots     | Armor part that goes on the left foot. (Boots)            |

| Armorset   | Description                                                                      |
|------------|----------------------------------------------------------------------------------|
| HeavySet   | High protection, reduces agilityn all parts (Boots, Leggings, Chestplate, Helmet)|
| LightSet   | Moderate protection, high agility 2-3 parts                                      |
| MediumSet  | Balanced protection and agility 1-2 parts                                        |
]]
