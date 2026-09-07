--[[
	GuidePages — Tutorial and lore guidebook pages data.
	Extracted from original game documentation.
]]

export type GuidePage = {
	pageNumber: number,
	title: string,
	content: string,
	image: string?,
}

local GuidePages: { GuidePage } = {
	{
		pageNumber = 1,
		title = "Page 1: Game Controls",
		content = "Defend\n- PC: Right Mouse Button\n- Controller: L2 Button\n- Mobile: Guard Button\n\nAttack\n- PC: Left Mouse Button\n- Controller: R2 Button\n- Mobile: Attack Button\n\nDash\n- PC: Q / Double Tap W/A/S/D\n- Controller: B Button",
	},
	{
		pageNumber = 2,
		title = "Page 2: Attacking",
		content = "At the start, you can use your fists as your initial weapon to deal damage. However, you can only block or parry attacks from enemies who are also using fists. Once you acquire other weapons, each with its own unique combo and timing, you'll gain access to a more diverse combat experience.\n\nAdditionally, you can unlock weapon-based skills through the skill tree, further enhancing your fighting abilities.",
	},
	{
		pageNumber = 3,
		title = "Page 3: Weapons",
		content = "You can choose from nine different weapons: Fist, Sword, Heavy Sword, Axe, Heavy Axe, Rapier, Saber, Scythe, and Spear.\n\nWeapons can be placed in your hotbar, and you can carry as many as you like. However, your skills and Weapon Power will be based solely on the stats of your main weapon.\n\nBase damage:\n• Fist – 5\n• Sword – 10\n• Heavy Sword – 20\n• Axe – 10\n• Heavy Axe – 20\n• Rapier – 7\n• Saber – 12\n• Scythe – 17\n• Spear – 15",
	},
	{
		pageNumber = 4,
		title = "Page 4: Blocking / Parrying",
		content = "Parry Window: Press the Defend command with precise timing (within 0.2 seconds of an enemy's attack) to parry successfully. A successful parry stuns the enemy for 0.3 seconds, leaving them open to attacks.\n\nCooldown: The Defend command has a 2-second cooldown after each use.\n\nWeakness: If an enemy attacks from behind while defending, your guard breaks, disabling blocking for 10 seconds.",
	},
	{
		pageNumber = 5,
		title = "Page 5: Skill Tree",
		content = "The skill tree is divided into two distinct paths:\n- Ægishjálmur – Representing protection and power.\n- Vegvísir – Symbolizing guidance and direction.\n\nÆgishjálmur Branch (Combat-Focused)\n• Paladin (Defensive/Support) – Healing abilities, protective skills, buffs.\n• Warrior (Offensive) – Weapon skills, damage boosts, devastating strikes.\n\nVegvísir Branch (Magic/Nature-Focused)\n• Warden (Nature/Survival) – Herbalism, foresight, camouflage.\n• Mage (Elemental/Utility) – Elemental magic, movement, arcane skills.",
	},
	{
		pageNumber = 6,
		title = "Page 6: Stats",
		content = "There are only three core stats, each influencing different aspects of gameplay:\n\n- Strength – Increases melee damage.\n- Vitality – Enhances health regeneration.\n- Agility – Affects movement speed and dash distance.\n\nStats naturally develop based on your actions:\n• Dealing damage increases Strength.\n• Tanking damage increases Vitality.\n• Dashing increases Agility.\n\nEquipping three artifacts of the same type grants a special advantage.",
	},
	{
		pageNumber = 7,
		title = "Page 7: Forging & Cooking",
		content = "Gathering & Cooking (Under Development)\nAs you explore the world, you'll come across minerals, apples, fruits, and herbs. While some can be consumed raw, cooking meals at a campfire restores significantly more health and provides temporary boosts.\n\nForging & Upgrading\nEvery village has a blacksmith who sells weapons in exchange for Hacksilver. You can forge weapons using gathered resources, or upgrade existing ones up to +10 using Hacksilver and Soul Points.",
	},
	{
		pageNumber = 8,
		title = "Page 8: Enemy Drops",
		content = "When defeating an enemy, you have a chance to obtain their equipment—what you see is what you get. Drops are logical (e.g. a boar will never drop a sword).\n\nBoss Rewards\nAfter a victorious boss battle, you have a chance to obtain rare boss weapons, artifacts, or armor sets.\n\nMore players in the boss area increase battle difficulty and reward drop chances.",
	},
	{
		pageNumber = 9,
		title = "Page 9: Chests",
		content = "Chests can be found throughout the world in five rarities:\nOrdinary, Uncommon, Rare, Exquisite, Relic.\n\nChest Mechanics\n• Chest rarity is random when spawned.\n• If unclaimed for 20 minutes, it upgrades to a higher rarity.\n• Once opened, it disappears and respawns elsewhere.\n\nHacksilver Rewards:\nOrdinary – 7 | Uncommon – 15 | Rare – 30 | Exquisite – 55 | Relic – 100",
	},
	{
		pageNumber = 10,
		title = "Page 10: Heritage",
		content = "When you first join, you receive 10 rolls to determine ancestry from Norse gods for passive abilities:\n\n• Common (50%) – Helgi, Eir, Modi\n• Uncommon (30%) – Njord, Forseti, Sif\n• Rare (15%) – Tyr, Freyr, Skadi\n• Epic (4%) – Thor, Freyja, Heimdall\n• Legendary (1%) – Odin, Loki, Fenrir\n\nResetting\nYou can reset level and stats with the village Völva for new rolls. This process is irreversible!",
	},
}

return GuidePages
