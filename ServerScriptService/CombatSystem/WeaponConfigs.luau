--// ServerScriptService/CombatSystem/WeaponConfigs.luau
local WeaponConfigs = {
	Gauntlet = {
		WeaponType = "Gauntlet",
		HitboxType = "Spatial", -- Uses standard Hitbox module

		Damage = {
			Base = 5,
			MaxCombo = 5,
			ComboResetTime = 1.5,
			StunDuration = 0.5,
			MaxCritChance = 100,
			AttackCooldown = 0.1,
		},

		ChargedAttack = {
			BaseDamageMultiplier = 2.5,
			StunDuration = 1.2,
			KnockbackMultiplier = 2.0,
			SizeMultiplier = 1.8,
			ParticleIntensity = 15,
			Sound = "ChargedPunchHit",
			SwingSound = "ChargedGauntletSwing",
		},

		Sounds = {
			HitPrefix = "PunchHit",
			SwingPrefix = "Gauntlet Swing",
			Block = "Block",
			BlockBreak = "BlockBreak",
			Parry = "HandParry",
		},

		Hitbox = {
			SizeBase = Vector3.new(3, 5, 4),
			SizeGrowthPerCombo = 0.4,
			Offset = CFrame.new(0, 0, -2),
		},

		Effects = {
			ParticleName = "Punch",
			TrailName = "LimbTrail",
		},
	},

	Sword = {
		WeaponType = "Sword",
		HitboxType = "Raycast",

		Damage = {
			Base = 5,
			MaxCombo = 5,
			ComboResetTime = 1.5,
			StunDuration = 0.5,
			MaxCritChance = 100,
			AttackCooldown = 0.1,
		},

		ChargedAttack = {
			BaseDamageMultiplier = 2.5,
			StunDuration = 1.2,
			KnockbackMultiplier = 2.0,
			SizeMultiplier = 1.8,
			ParticleIntensity = 15,
			Sound = "ChargedSwordHit",
			SwingSound = "ChargedSwordSwing",
		},

		Sounds = {
			HitPrefix = "PunchHit", -- Legacy used PunchHit
			SwingPrefix = "Gauntlet Swing", -- Legacy used Gauntlet Swing for Sword? Line 431 in SwordCombat. Yes.
			Block = "Block",
			BlockBreak = "BlockBreak",
			Parry = "Parry",
		},

		Hitbox = {
			PartName = "Hitbox",
		},

		Effects = {
			SlowOnAttack = true,
			TrailEnabled = true,
		},
	},

	HeavySword = {
		WeaponType = "HeavySword",
		HitboxType = "Raycast",

		Damage = {
			Base = 5,
			MaxCombo = 5,
			ComboResetTime = 1.5,
			StunDuration = 0.5,
			MaxCritChance = 100,
			AttackCooldown = 0.1,
		},

		ChargedAttack = {
			BaseDamageMultiplier = 2.5,
			StunDuration = 1.2,
			KnockbackMultiplier = 2.0,
			SizeMultiplier = 1.8,
			ParticleIntensity = 15,
			Sound = "ChargedHeavySwordHit",
			SwingSound = "ChargedHeavySwordSwing",
		},

		Sounds = {
			HitPrefix = "PunchHit", -- Legacy used PunchHit
			SwingPrefix = "Gauntlet Swing", -- Legacy used Gauntlet Swing for Sword? Line 431 in SwordCombat. Yes.
			Block = "Block",
			BlockBreak = "BlockBreak",
			Parry = "Parry",
		},

		Hitbox = {
			PartName = "Hitbox",
		},

		Effects = {
			SlowOnAttack = true,
			TrailEnabled = true,
		},
	},

	Axe = {
		WeaponType = "Axe",
		HitboxType = "Raycast",

		Damage = {
			Base = 5,
			MaxCombo = 5,
			ComboResetTime = 1.5,
			StunDuration = 0.5,
			MaxCritChance = 100,
			AttackCooldown = 0.1,
		},

		ChargedAttack = {
			BaseDamageMultiplier = 2.5,
			StunDuration = 1.2,
			KnockbackMultiplier = 2.0,
			SizeMultiplier = 1.8,
			ParticleIntensity = 15,
			Sound = "ChargedAxeHit",
			SwingSound = "ChargedAxeSwing",
		},

		Sounds = {
			HitPrefix = "PunchHit", -- Legacy used PunchHit for Axe too? Yes, line 258 in HeavyAxe
			SwingPrefix = "HeavySwing",
			Block = "Block",
			BlockBreak = "BlockBreak",
			Parry = "Parry",
		},

		Hitbox = {
			PartName = "Hitbox",
		},

		Effects = {
			SlowOnAttack = true,
			TrailEnabled = true,
		},
	},

	HeavyAxe = {
		WeaponType = "HeavyAxe",
		HitboxType = "Raycast", -- Uses RaycastHitbox module

		Damage = {
			Base = 5,
			MaxCombo = 5,
			ComboResetTime = 1.5,
			StunDuration = 0.5,
			MaxCritChance = 100,
			AttackCooldown = 0.1,
		},

		ChargedAttack = {
			BaseDamageMultiplier = 2.5,
			StunDuration = 1.2,
			KnockbackMultiplier = 2.0,
			SizeMultiplier = 1.8,
			ParticleIntensity = 15,
			Sound = "ChargedHeavyAxeHit",
			SwingSound = "ChargedHeavyAxeSwing",
		},

		Sounds = {
			HitPrefix = "PunchHit", -- Legacy used PunchHit for Axe too? Yes, line 258 in HeavyAxe
			SwingPrefix = "HeavySwing",
			Block = "Block",
			BlockBreak = "BlockBreak",
			Parry = "Parry",
		},

		Hitbox = {
			PartName = "Hitbox", -- Part in tool to attach raycast to
		},

		Effects = {
			SlowOnAttack = true,
			TrailEnabled = true,
		},
	},
}

return WeaponConfigs
