--// ServerScriptService/CombatSystem/CombatLogic.luau
local CombatLogic = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerStorage:WaitForChild("Modules")
local damageGui = require(modules.DamageGui)
local HitService = require(modules.HitService)
local soundManager = require(modules.SoundManager)
local particleSummoner = require(modules.ParticleSummoner)
local BlockingSystem = require(modules.BlockingSystem)
local PartyManager = require(modules.PartyManager)

local HitboxFactory = require(script.Parent.HitboxFactory)
local WeaponConfigs = require(script.Parent.WeaponConfigs)

-- Preload Animations
local animations = ReplicatedStorage.Animations.Combat.Weapons
local animationCache = {}

-- Helper to preload animations
local function preloadAnimations()
	-- Gauntlet
	animationCache.Gauntlet = {}
	for i = 1, 5 do
		animationCache.Gauntlet[i] = animations.Gauntlet["Hit" .. i]
	end

	-- HeavyAxe
	animationCache.HeavyAxe = {}
	for i = 1, 5 do
		animationCache.HeavyAxe[i] = animations.HeavyAxe["Hit" .. i]
	end

	-- Sword
	animationCache.Sword = {}
	for i = 1, 5 do
		animationCache.Sword[i] = animations.Sword["Hit" .. i]
	end

	-- Enemy Reactions
	animationCache.Reaction = {}
	animationCache.Reaction.LightStun = ReplicatedStorage.Animations.Combat.EnemyReaction.LightStun
	animationCache.Reaction.HeavyStun = ReplicatedStorage.Animations.Combat.EnemyReaction.HeavyStun
	animationCache.Reaction.BlockBreak = ReplicatedStorage.Animations.Combat.EnemyReaction.BlockBreak
end

preloadAnimations()
soundManager.preloadSounds(game:GetService("SoundService"):WaitForChild("Combat"))

-- Player State Management
local playerStates = {}

local function initPlayerState(player)
	if not playerStates[player.UserId] then
		playerStates[player.UserId] = {
			lastPunch = 0,
			combo = 1,
			activeHitboxes = {},
			pendingAttacks = 0,
			animationComplete = true,
			lastAttackTime = 0,
			currentAttackType = "normal",
			comboResetTime = 0,
		}
	end
	return playerStates[player.UserId]
end

local function cleanupPlayerState(player)
	if playerStates[player.UserId] then
		for _, hitbox in pairs(playerStates[player.UserId].activeHitboxes) do
			if hitbox then
				hitbox:Destroy()
			end
		end
		playerStates[player.UserId] = nil
	end
end

Players.PlayerRemoving:Connect(cleanupPlayerState)

-- Helper Functions
local function isBehind(frontHRP, backHRP)
	if not frontHRP or not backHRP then
		return false
	end
	local lookVector = frontHRP.CFrame.LookVector
	local directionToBack = (backHRP.Position - frontHRP.Position).unit
	return lookVector:Dot(directionToBack) < -0.7
end

local function updateCombo(char, player, config)
	if char:GetAttribute("Stunned") then
		return 1
	end

	local playerState = initPlayerState(player)
	local passedTime = os.clock() - playerState.lastPunch

	if passedTime > config.Damage.ComboResetTime then
		char:SetAttribute("Combo", 1)
		playerState.combo = 1
	else
		if char:GetAttribute("Combo") < config.Damage.MaxCombo then
			char:SetAttribute("Combo", char:GetAttribute("Combo") + 1)
			playerState.combo = char:GetAttribute("Combo")
		else
			char:SetAttribute("Combo", 1)
			playerState.combo = 1
		end
	end

	playerState.lastPunch = os.clock()
	return playerState.combo
end

local function calculateKnockback(attacker, forwardPower, sidePower, comboStep, enemy, attackType, config)
	local forwardDirection = (enemy.HumanoidRootPart.Position - attacker.HumanoidRootPart.Position).Unit
	local rightDirection = attacker.HumanoidRootPart.CFrame.RightVector
	local multiplier = 1

	if attackType == "charged" then
		multiplier = config.ChargedAttack.KnockbackMultiplier
	end

	local knockbackDirection = forwardDirection * forwardPower

	-- Side power logic differs slightly per weapon in legacy, but we can unify or branch
	-- Gauntlet: sidePower always 0 in legacy
	-- Sword/Axe: sidePower used

	if config.WeaponType == "Gauntlet" then
		-- No side knockback for gauntlet in legacy
	else
		-- Alternating side knockback
		if comboStep % 2 == 0 then
			knockbackDirection += rightDirection * sidePower -- Right
		else
			knockbackDirection -= rightDirection * sidePower -- Left
		end
	end

	local relativeDirection = (enemy.HumanoidRootPart.Position - attacker.HumanoidRootPart.Position).Unit
	knockbackDirection += relativeDirection * forwardPower

	return knockbackDirection * multiplier
end

local function handleComboAndKnockback(enemy, char, combo, attackType, config)
	local attackerKnockback = Vector3.zero
	local knockback
	local ragdoll = false

	local forwardPower = (attackType == "charged") and 20 or (combo == config.Damage.MaxCombo) and 15 or 3
	local sidePower = (combo == config.Damage.MaxCombo) and 0 or 5

	if config.WeaponType == "Gauntlet" then
		forwardPower = (combo == 5) and 15 or 3
		sidePower = 0
	end

	knockback = calculateKnockback(char, forwardPower, sidePower, combo, enemy, attackType, config)

	if enemy and enemy:FindFirstChild("HumanoidRootPart") and char and char:FindFirstChild("HumanoidRootPart") then
		local relativeDirection = (char.HumanoidRootPart.Position - enemy.HumanoidRootPart.Position).Unit
		attackerKnockback = relativeDirection * -5
	end

	if combo == config.Damage.MaxCombo or attackType == "charged" then
		ragdoll = true
	end

	return attackerKnockback, knockback, ragdoll
end

-- Hit Processing
local function processHit(char, combo, hitboxWrapper, hitHumanoid, attackType, playAnimation, config, player)
	local humRp = char:WaitForChild("HumanoidRootPart")
	local enemy = hitHumanoid.Parent
	local enemyPlayer = Players:GetPlayerFromCharacter(enemy)

	-- Parry/Block Handling
	if enemy:GetAttribute("Parrying") then
		if
			enemyPlayer
			and (not enemy:GetAttribute("BlockType") or BlockingSystem.CanDefendAgainst(enemyPlayer, config.WeaponType))
		then
			soundManager.playSound(config.Sounds.Parry, enemy:FindFirstChild("Head"))
			particleSummoner.EmitParticles("Parry", enemy.HumanoidRootPart, 5, 0.2)

			local stunDuration = attackType == "charged" and 4 or 3
			char:SetAttribute("Stunned", true)
			task.delay(stunDuration, function()
				char:SetAttribute("Stunned", false)
			end)

			playAnimation:Stop()
			hitboxWrapper:Stop()
			return
		end
	elseif enemy:GetAttribute("Blocking") then
		if enemyPlayer and BlockingSystem.CanDefendAgainst(enemyPlayer, config.WeaponType) then
			if attackType == "charged" or isBehind(enemy.HumanoidRootPart, humRp) then
				BlockingSystem.ForceBlockBreak(enemy)
				soundManager.playSound(config.Sounds.BlockBreak, char:FindFirstChild("Head"))
				particleSummoner.EmitParticles("BlockBreak", enemy.HumanoidRootPart, 5, 0.2)
			else
				soundManager.playSound(config.Sounds.Block, char:FindFirstChild("Head"))
			end
			hitboxWrapper:Stop()
			return
		end
	end

	-- Hit Effects
	local soundName = (attackType == "charged") and config.ChargedAttack.Sound or (config.Sounds.HitPrefix .. combo)
	soundManager.playSound(soundName, char:FindFirstChild("Head"))

	enemy:SetAttribute("Stunned", true)

	-- Visuals
	if config.WeaponType == "Gauntlet" then
		local particleIntensity = attackType == "charged" and config.ChargedAttack.ParticleIntensity or 5
		local particleDuration = attackType == "charged" and 0.3 or 0.1
		local limbName = (combo % 2 == 0) and "Left Arm" or "Right Arm"
		local attachmentName = (combo % 2 == 0) and "LeftGripAttachment" or "RightGripAttachment"
		local limb = char:FindFirstChild(limbName)

		if limb then
			local attachment = limb:FindFirstChild(attachmentName)
			local position = attachment and attachment.Position or limb.Position

			particleSummoner.EmitParticles(
				config.Effects.ParticleName,
				limb,
				particleIntensity,
				particleDuration,
				position
			)
		end
	end

	local enemyReaction = animationCache.Reaction.LightStun
	local enemyAnimator = hitHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", hitHumanoid)
	local playStunAnim = enemyAnimator:LoadAnimation(enemyReaction)

	-- Knockback & Damage
	local attackerKnockback, knockback, ragdoll = handleComboAndKnockback(enemy, char, combo, attackType, config)

	local strength = char:GetAttribute("Strength") or 0
	local criticalChance = math.min(config.Damage.MaxCritChance, char:GetAttribute("CritChance") or 0) / 100
	local criticalMultiplier = (char:GetAttribute("CritDamage") or 100) / 100

	local enemyDefense = 0
	if enemyPlayer then
		enemyDefense = (enemyPlayer:GetAttribute("HelmetArmor") or 0)
			+ (enemyPlayer:GetAttribute("ChestplateArmor") or 0)
			+ (enemyPlayer:GetAttribute("LeggingsArmor") or 0)
			+ (enemyPlayer:GetAttribute("BootsArmor") or 0)
	end

	local damageMultiplier = char:GetAttribute("DamageMultiplier") or 1
	local isCriticalHit = math.random() < criticalChance
	local criticalHitMultiplier = isCriticalHit and criticalMultiplier or 1

	local rawDamage = (config.Damage.Base + strength) * criticalHitMultiplier * damageMultiplier
	if attackType == "charged" then
		rawDamage = (config.ChargedAttack.BaseDamageMultiplier * config.Damage.Base + strength)
			* criticalHitMultiplier
			* damageMultiplier
	end

	local enemyDefenseMultiplier = 1
	if enemyPlayer then
		enemyDefenseMultiplier = enemyPlayer:GetAttribute("DefenseMultiplier") or 1
		local damageReduction = enemyPlayer:GetAttribute("DamageReduction") or 0
		rawDamage = rawDamage * (1 - damageReduction)
	end

	local finalDamage = math.max(0, rawDamage - (enemyDefense * enemyDefenseMultiplier))
	local damageType = isCriticalHit and "Crit" or "Normal"

	damageGui.summonDamageGui(enemy, finalDamage, damageType)

	if finalDamage > 0 then
		HitService.hit(hitHumanoid, finalDamage, knockback, attackerKnockback, char, ragdoll)
		playStunAnim:Play()
	end

	local stunDuration = attackType == "charged" and config.ChargedAttack.StunDuration or config.Damage.StunDuration
	task.delay(stunDuration, function()
		if enemy and enemy:FindFirstChild("Humanoid") then
			enemy:SetAttribute("Stunned", false)
		end
	end)

	-- For spatial hitboxes, we might want to stop after one hit if it's not multi-hit?
	-- Legacy Gauntlet stops hitbox after hit? Yes: `hitbox:Stop()` at end of processHit
	-- Legacy Sword/Axe stops hitbox? No, it uses `hitbox.OnHit` which can hit multiple enemies, but checks `if hitHumanoid == hum`.
	-- Wait, legacy Gauntlet `processHit` calls `hitbox:Stop()`. This implies single target per swing?
	-- Actually, `Hitbox` module usually handles multiple hits if configured.
	-- But calling `Stop` inside `onTouch` means it stops detecting after the FIRST hit.
	-- Let's replicate legacy behavior.
	if config.HitboxType == "Spatial" then
		hitboxWrapper:Stop()
	end
end

-- Main Attack Function
function CombatLogic.processAttack(player, tool, attackType, weaponName)
	local config = WeaponConfigs[weaponName]
	if not config then
		warn("No config for " .. weaponName)
		return
	end

	local char = player.Character
	if not char or not char:FindFirstChild("Humanoid") then
		return
	end

	if
		char:GetAttribute("Attacking")
		or char:GetAttribute("Blocking")
		or char:GetAttribute("Stunned")
		or char:GetAttribute("Fallen")
	then
		return
	end

	local playerState = initPlayerState(player)
	local currentTime = os.clock()

	if
		not playerState.animationComplete or (currentTime - playerState.lastAttackTime < config.Damage.AttackCooldown)
	then
		return
	end

	playerState.currentAttackType = attackType
	playerState.animationComplete = false
	char:SetAttribute("Attacking", true)

	local combo
	if attackType == "charged" then
		combo = 1
		char:SetAttribute("Combo", 1)
		playerState.combo = 1
	else
		combo = updateCombo(char, player, config)
	end

	local hum = char:WaitForChild("Humanoid")
	local speedMultiplier = char:GetAttribute("SpeedMultiplier") or 1
	local adjustedAnimSpeed = speedMultiplier - 0.1

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

	local animToPlay
	if attackType == "charged" then
		animToPlay = animationCache[weaponName] and animationCache[weaponName][5] -- Charged usually uses Hit5 or special
		-- Legacy Gauntlet: Hit5. Legacy Sword/Axe: Hit5.
		-- Wait, legacy says `animationCache[5]` for charged.
		if not animToPlay then
			animToPlay = animationCache[weaponName][5]
		end
	else
		animToPlay = animationCache[weaponName][combo]
	end

	if not animToPlay then
		warn("Missing animation for " .. weaponName .. " combo " .. combo)
		return
	end

	local playAnimation = animator:LoadAnimation(animToPlay)
	playAnimation:AdjustSpeed(adjustedAnimSpeed)

	-- Slow Effect
	task.spawn(function()
		repeat
			task.wait()
		until playAnimation.Length > 0
		char:SetAttribute("Slowed", true)
		if config.Effects.TrailEnabled and tool:FindFirstChild("Blade") and tool.Blade:FindFirstChild("Trail") then
			tool.Blade.Trail.Enabled = true
		elseif
			config.Effects.TrailEnabled
			and tool:FindFirstChild("Blade")
			and tool.Blade:FindFirstChild("Att1")
			and tool.Blade.Att1:FindFirstChild("Trail")
		then
			-- Heavy Axe trail location
			tool.Blade.Att1.Trail.Enabled = true
		end
	end)

	-- Visual Trails (Gauntlet)
	if config.WeaponType == "Gauntlet" then
		local limb = (combo % 2 == 0) and char["Left Arm"] or char["Right Arm"]
		particleSummoner.EmitParticles(config.Effects.TrailName, limb, nil, playAnimation.Length)
	end

	-- Create Hitbox
	local hitboxWrapper
	local hitboxKey = attackType == "charged" and "charged" or combo

	if config.HitboxType == "Spatial" then
		local hitboxSize = config.Hitbox.SizeBase
			+ Vector3.new(combo * config.Hitbox.SizeGrowthPerCombo, 0, combo * config.Hitbox.SizeGrowthPerCombo)
		if attackType == "charged" then
			hitboxSize = hitboxSize * config.ChargedAttack.SizeMultiplier
		end

		hitboxWrapper = HitboxFactory.Create("Spatial", {
			Config = {
				Size = hitboxSize,
				Offset = config.Hitbox.Offset,
				OnTouch = function(hitHumanoid)
					processHit(char, combo, hitboxWrapper, hitHumanoid, attackType, playAnimation, config, player)
				end,
			},
			Player = player,
			Character = char,
		})
	else
		hitboxWrapper = HitboxFactory.Create("Raycast", {
			Tool = tool,
			OnHit = function(hitHumanoid)
				if hitHumanoid == hum then
					return
				end
				processHit(char, combo, hitboxWrapper, hitHumanoid, attackType, playAnimation, config, player)
			end,
		})
	end

	playerState.activeHitboxes[hitboxKey] = hitboxWrapper

	-- Animation Events
	playAnimation:GetMarkerReachedSignal("HitStart"):Connect(function()
		local ignoreList = { char }
		if PartyManager then
			for _, member in pairs(PartyManager:GetPartyMembers()) do
				table.insert(ignoreList, member)
			end
		end

		hitboxWrapper:Start(ignoreList)

		task.delay(0.1, function()
			local swingSound
			if attackType == "charged" then
				swingSound = config.ChargedAttack.SwingSound
			else
				swingSound = config.Sounds.SwingPrefix .. math.random(1, 2)
			end
			soundManager.playSound(swingSound, char:FindFirstChild("Head"), { PlaybackSpeed = adjustedAnimSpeed })

			-- For Spatial, legacy stops it here after 0.1s delay?
			if config.HitboxType == "Spatial" then
				if hitboxWrapper then
					hitboxWrapper:Stop()
					if playerState.activeHitboxes[hitboxKey] == hitboxWrapper then
						playerState.activeHitboxes[hitboxKey] = nil
					end
				end
			end
		end)
	end)

	if config.HitboxType == "Raycast" then
		playAnimation:GetMarkerReachedSignal("HitStop"):Connect(function()
			if hitboxWrapper then
				hitboxWrapper:Stop()
				if playerState.activeHitboxes[hitboxKey] == hitboxWrapper then
					playerState.activeHitboxes[hitboxKey] = nil
				end
			end
		end)
	end

	playAnimation:Play(0.1, 1, adjustedAnimSpeed)

	local animLength = playAnimation.Length
	if speedMultiplier >= 1 then
		animLength = animLength / speedMultiplier
		task.wait(animLength)
	else
		task.wait(animLength - 0.1)
	end

	if char and char:FindFirstChild("Humanoid") then
		char:SetAttribute("Attacking", false)
		char:SetAttribute("Slowed", false)
		playerState.animationComplete = true
		playerState.lastAttackTime = os.clock()

		-- Cleanup trails
		if config.Effects.TrailEnabled then
			if tool:FindFirstChild("Blade") then
				if tool.Blade:FindFirstChild("Trail") then
					tool.Blade.Trail.Enabled = false
				end
				if tool.Blade:FindFirstChild("Att1") and tool.Blade.Att1:FindFirstChild("Trail") then
					tool.Blade.Att1.Trail.Enabled = false
				end
			end
		end
	end
end

return CombatLogic
