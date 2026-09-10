Data = {
	-- Core Attributes
	Level = 1,                   -- Player level
	Experience = 0,              -- Current XP
	MaxHealth = 100,             -- Maximum health points
	HackSilver = 0,				 -- Current money (initial amount)
	Souls = 0,          		 -- Souls colected (initial amount)
	MaxSouls = 100,          	 -- MaxSouls Souls (initial amount)
	MaxStamina = 100,			 -- Maximum stamina points

	-- Equipment Stats
	WeaponPower = 0,        -- Additional damage from equipped weapon
	CritChance = 5,   		-- Chance of landing a critical hit (in percentage)
	CritDamage = 150,  		-- Critical hit damage multiplier (in percentage)

	HelmetArmor = 0,        -- Damage reduction from equipped helmet
	ChestplateArmor = 0,    -- Damage reduction from equipped chest
	LeggingsArmor = 0,      -- Damage reduction from equipped leggins
	BootsArmor = 0,         -- Damage reduction from equipped boot

	Weight = 0,             -- Total weight of equipped items  

	SkillPoints = 0,		-- Points to inlock new skills

	Chests = {},

	-- Heritage
	Heritage = "none",   -- Player's heritage
	HeritageRolls = 10,   -- Player's initial rolls

	LeftCombat = false, -- Player left during combat

	-- Inventory
	Inventory = {},          -- Player inventory (list of items)
	HotBar = {
		["MainWeapon"] = "",
		[1] = "",
		[2] = "",
		[3] = "",
		[4] = "",
		[5] = "",
		[6] = "",
		[7] = "",
		["MainShield"] = "",
	},

	EquippedArmor = {
		Helmet = "",    
		Chestplate = "",
		Leggings = "",  
		Boots = "",     
	},

	EquippedArtifacts = {
		Artifact1 = "none",
		Artifact2 = "none",
		Artifact3 = "none",
	},

	ClassPath = "Aegishjalmur",

	UnlockedSkills = {
		["Holy Blessing"] = false,
		["Battle Cry"] = false,
		["Nature's Gift"] = false,
		["Blink"] = false,
	},

	Skills = {
		Q = "",
		E = "",
		R = "",
		F = "",
	},

	-- Quests
	Quests = {},			 -- Player Quests

	-- Titles & Cosmetics
	Titles = {
		CurrentTitle = "",
		Title1 = "",
		Title2 = "",
		Title3 = "",
	},
	Cosmetics = {},          -- Equipped cosmetic items

	-- Faction & Reputation
	FactionsReputation = {},  -- Reputation with different factions
	Fame = 500,       	        -- 1000 = hero; 750 = good; 500 = neutral; 250 = evil; 0 = villain
	Tier = "Newcomer", 			-- Newcomer, Novice, Skilled, Veteran, Elite, Champion / Paladin Warrior Warden Mage
	Rank = "Bronze",		-- Bronze, Silver, Gold, Platinum, Diamond, Master, Grandmaster, Legend.

	-- Combat Stats
	Stats = {
		Strength = 0,     -- Affects melee damage increases when attacking
		Vitality = 0,     -- Affects health regeneration increases when damaged
		Agility = 0,       -- Affects movement speed dash distance and dodge chance increases when dashing
		Luck = 0,		-- Affects rewards
	},

	Statistics = {
		Kills = 0,            -- Total kills made by the player
		Deaths = 0,           -- Total deaths of the player
		PvPWins = 0,          -- Total PvP wins
		PvPLosses = 0,        -- Total PvP losses
		TimePlayed = 0,       -- Total time played by the player (in minutes)
	}
}

game.Players.PlayerAdded:Connect(function(player)
	local DataFolder = Instance.new("Folder")
	DataFolder.Name = "Data"
	DataFolder.Parent = player

	for Name, Data in pairs(Data) do
		if typeof(Data) == "string" then
			local Value = Instance.new("StringValue")
			Value.Name = Name
			Value.Value = Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "number" then
			local Value = Instance.new("NumberValue")
			Value.Name = Name
			Value.Value = Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "boolean" then
			local Value = Instance.new("BoolValue")
			Value.Name = Name
			Value.Value = Data
			Value.Parent = DataFolder
		elseif typeof(Data) == "table" then
			local TableFolder = Instance.new("Folder")
			TableFolder.Name = Name
			TableFolder.Parent = player

			for TableName, TableValue in pairs(Data) do
				if typeof(TableValue) == "string" then
					local Value = Instance.new("StringValue")
					Value.Name = TableName
					Value.Value = TableValue
					Value.Parent = TableFolder
				elseif typeof(TableValue) == "number" then
					local Value = Instance.new("NumberValue")
					Value.Name = TableName
					Value.Value = TableValue
					Value.Parent = TableFolder
				elseif typeof(TableValue) == "boolean" then
					local Value = Instance.new("BoolValue")
					Value.Name = TableName
					Value.Value = TableValue
					Value.Parent = TableFolder
				end
			end
		end
	end

	player:WaitForChild("Loading").Value = false
end)