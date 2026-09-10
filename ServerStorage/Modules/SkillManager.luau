local SkillManager = {
	Aegishjalmur = {
		Paladin = {
			{
				Name = "Holy Blessing",
				Class = "Paladin",
				Weapons = "Any",
				IsPassive = true,
				Cooldown = 60,
				Duration = 60,
				SoulsCost = 70,
				Description = "Grants a temporary buff that increases defense by 20% for 60 seconds and regenerates 10% of total health."
			}
		},
		Warrior = {
			{
				Name = "Battle Cry",
				Class = "Warrior",
				Weapons = "Any",
				IsPassive = true,
				Cooldown = 45,
				Duration = 15,
				SoulsCost = 50,
				Description = "Increases the player's attack power by 25% for 15 seconds and reduces incoming damage by 10%."
			}
		}
	},
	Vegvisir = {
		Warden = {
			{
				Name = "Nature's Gift",
				Class = "Warden",
				Weapons = "Any",
				IsPassive = true,
				Cooldown = 30,
				SoulsCost = 60,
				Description = "Instantly heals 20% of total health. Healing increases by 10% per tier."
			}
		},
		Mage = {
			{
				Name = "Blink",
				Class = "Mage",
				Weapons = "Any",
				IsPassive = false,
				Cooldown = 10,
				SoulsCost = 40,
				Description = "Teleports the player a short distance forward, allowing for quick repositioning."
			}
		}
	}
}

return SkillManager
