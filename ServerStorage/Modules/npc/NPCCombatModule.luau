-- UPDATED NPC COMBAT MODULE
local NPCCombatModule = {}

-- Services
local ss = game:GetService("ServerStorage")
local modules = ss:WaitForChild("Modules")

-- Modules
local Hitbox = require(modules:WaitForChild("Hitbox"))
local HitService = require(modules:WaitForChild("HitService"))
local damageGui = require(modules.DamageGui)
local soundManager = require(modules.SoundManager)
local particleSummoner = require(modules.ParticleSummoner)
local BlockingSystem = require(modules.BlockingSystem)
local PartyManager = require(modules.PartyManager)

local Players = game:GetService("Players")

-- Preload sounds for better performance
soundManager.preloadSounds(game:GetService("SoundService"):WaitForChild("NpcGroup"))

-- Cache animation objects for better performance
local animationCache = {}
local function preloadAnimations(animations)
	if not animations then
		return
	end

	-- Cache enemy reaction animations
	if animations.EnemyReaction and animations.EnemyReaction.LightStun then
		animationCache["LightStun"] = animations.EnemyReaction.LightStun
	end

	-- Cache attack animations based on enemy types
	if animations.Warrior and animations.Warrior.Attack then
		animationCache["Warrior"] = animations.Warrior.Attack
	end

	if animations.Boars and animations.Boars.Attack then
		animationCache["Boar"] = animations.Boars.Attack
	end

	if animations.Wolfs and animations.Wolfs.Attack then
		animationCache["Wolf"] = animations.Wolfs.Attack
	end

	if animations.Default and animations.Default.Attack then
		animationCache["Default"] = animations.Default.Attack
	end
end

-- Constants for better maintainability
local CONFIG = {
	DAMAGE_TYPE = "Normal",
	ATTACK_TYPE = "Fist",
	STUN_DURATION = 0.5,
	MAX_CRITICAL_CHANCE = 100, -- Maximum allowed critical chance percentage
	HIT_DURATION = 0.08, -- How long hitbox stays active (matching player scripts)
	ATTACK_COOLDOWN = 0.1, -- Minimum time between attacks
}

-- NPC state tracking
local npcStates = {}

local function initNPCState(npc)
	if not npcStates[npc] then
		npcStates[npc] = {
			lastAttack = 0,
			activeHitboxes = {},
			pendingAttacks = 0,
			animationComplete = true,
			lastAttackTime = 0, -- Track when last attack was completed
		}
	end
	return npcStates[npc]
end

local function cleanupNPCState(npc)
	if npcStates[npc] then
		-- Clean up any active hitboxes
		for _, hitbox in pairs(npcStates[npc].activeHitboxes) do
			if hitbox and typeof(hitbox.Stop) == "function" then
				hitbox:Stop()
			end
		end
		npcStates[npc] = nil
	end
end

-- Handle NPC cleanup when removed from workspace
game.Workspace.DescendantRemoving:Connect(function(instance)
	if instance:GetAttribute("NPC") then
		cleanupNPCState(instance)
	end
end)

local function calculateKnockback(attacker, enemy, power)
	if not attacker or not enemy then
		return Vector3.new(0, 0, 0)
	end

	local attackerHRP = attacker:FindFirstChild("HumanoidRootPart")
	local enemyHRP = enemy:FindFirstChild("HumanoidRootPart")

	if not attackerHRP or not enemyHRP then
		return Vector3.new(0, 0, 0)
	end

	local direction = (enemyHRP.Position - attackerHRP.Position).Unit
	local kb = direction * power
	return kb
end

local function handleComboAndKnockback(enemy, npc)
	local attackerKnockback = Vector3.new(0, 0, 0)
	local knockback = Vector3.new(0, 0, 0)
	local ragdoll = false

	-- Calculate knockback with safety checks
	knockback = calculateKnockback(npc, enemy, 3)
	attackerKnockback = calculateKnockback(npc, enemy, 2)

	return attackerKnockback, knockback, ragdoll
end

local function isBehind(frontHRP, backHRP)
	if not frontHRP or not backHRP then
		warn("HumanoidRootPart missing!")
		return false
	end

	local lookVector = frontHRP.CFrame.LookVector
	local directionToBack = (backHRP.Position - frontHRP.Position).unit
	local dotProduct = lookVector:Dot(directionToBack)

	return dotProduct < -0.7
end

-- Get player/character attributes instead of values
local function getPlayerAttribute(char, attributeName, defaultValue)
	local attribute = char:GetAttribute(attributeName)
	return attribute ~= nil and attribute or defaultValue
end

-- More responsive hit detection with early feedback
local function processHit(npc, hitboxInstance, hitHumanoid, sound, strength)
	-- Safety checks
	if not npc or not npc:IsDescendantOf(workspace) then
		return
	end

	-- Get humanoid root part reference
	local humRp = npc:FindFirstChild("HumanoidRootPart")
	if not humRp then
		return
	end

	-- Process hit on enemy
	local enemy = hitHumanoid.Parent
	local enemyPlayer = Players:GetPlayerFromCharacter(enemy)

	-- Check if enemy is in party (skip if they are)
	if enemyPlayer then
		local partyMembers = PartyManager:GetPartyMembers()
		if partyMembers[enemyPlayer.UserId] then
			return
		end
	end

	-- Handle parrying first for immediate feedback
	if enemy:GetAttribute("Parrying") then
		if
			enemyPlayer
			and (
				not enemy:GetAttribute("BlockType")
					or BlockingSystem.CanDefendAgainst(enemyPlayer, CONFIG.ATTACK_TYPE)
			)
		then
			-- Parry effects with immediate feedback
			soundManager.playSound("HandParry", enemy:FindFirstChild("Head"))
			particleSummoner.EmitParticles("Parry", enemy.HumanoidRootPart, 5, 0.2)

			-- Apply stun to attacker
			npc:SetAttribute("Stunned", true)
			task.delay(3, function()
				if npc and npc:IsDescendantOf(workspace) then
					npc:SetAttribute("Stunned", false)
				end
			end)

			-- Stop hitbox immediately to prevent further hits
			hitboxInstance:Stop()
			return
		end
	elseif enemy:GetAttribute("Blocking") then
		-- Check if block can defend against attacks
		if enemyPlayer and BlockingSystem.CanDefendAgainst(enemyPlayer, CONFIG.ATTACK_TYPE) then
			-- Check if attack is from behind
			if isBehind(enemy.HumanoidRootPart, humRp) then
				BlockingSystem.ForceBlockBreak(enemy)
				soundManager.playSound("BlockBreak", npc:FindFirstChild("Head"))
				particleSummoner.EmitParticles("BlockBreak", enemy.HumanoidRootPart, 5, 0.2)
			else
				soundManager.playSound("Block", npc:FindFirstChild("Head"))
			end

			-- Stop hitbox to prevent further hits
			hitboxInstance:Stop()
			return
		end
	end

	-- Handle successful hit with immediate feedback
	if sound then
		soundManager.playSound(sound, npc:FindFirstChild("Head"))
	end

	-- Apply stun to enemy
	enemy:SetAttribute("Stunned", true)

	-- Visual feedback for hit
	local hitArm = npc:FindFirstChild("Right Arm") or humRp
	particleSummoner.EmitParticles("Punch", hitArm, 5, 0.1)

	-- Enemy stun animation
	local enemyReaction = animationCache["LightStun"]
	if enemyReaction then
		local enemyAnimator = hitHumanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", hitHumanoid)
		local playStunAnim = enemyAnimator:LoadAnimation(enemyReaction)
		playStunAnim.Priority = Enum.AnimationPriority.Action2
		playStunAnim:Play()
	end

	-- Calculate knockback and ragdoll
	local attackerKnockback, knockback, ragdoll = handleComboAndKnockback(enemy, npc)

	-- Damage calculation using NPC attributes
	local npcStrength = getPlayerAttribute(npc, "Strength", 0)
	local criticalChance = math.min(CONFIG.MAX_CRITICAL_CHANCE, getPlayerAttribute(npc, "CritChance", 20)) / 100 -- 20% default for NPCs
	local criticalMultiplier = (getPlayerAttribute(npc, "CritDamage", 200) / 100) -- 2x default for NPCs

	-- Get enemy defense from attributes
	local enemyDefense = 0
	if enemyPlayer then
		enemyDefense = getPlayerAttribute(enemy, "HelmetArmor", 0)
			+ getPlayerAttribute(enemy, "ChestplateArmor", 0)
			+ getPlayerAttribute(enemy, "LeggingsArmor", 0)
			+ getPlayerAttribute(enemy, "BootsArmor", 0)
	end

	-- Apply damage multiplier
	local damageMultiplier = getPlayerAttribute(npc, "DamageMultiplier", 1)

	-- Calculate critical hit
	local isCriticalHit = math.random() < criticalChance
	local criticalHitMultiplier = isCriticalHit and criticalMultiplier or 1
	local rawDamage = (strength + npcStrength) * criticalHitMultiplier * damageMultiplier

	-- Apply defense multiplier for enemy
	local enemyDefenseMultiplier = 1
	if enemyPlayer then
		enemyDefenseMultiplier = getPlayerAttribute(enemy, "DefenseMultiplier", 1)
		-- Apply damage reduction
		local damageReduction = getPlayerAttribute(enemy, "DamageReduction", 0) / 100
		rawDamage = rawDamage * (1 - damageReduction)
	end

	local finalDamage = math.max(0, rawDamage - (enemyDefense * enemyDefenseMultiplier))

	-- Set damage type for UI
	CONFIG.DAMAGE_TYPE = isCriticalHit and "Crit" or "Normal"

	-- Show damage
	damageGui.summonDamageGui(enemy, finalDamage, CONFIG.DAMAGE_TYPE)

	-- Apply damage if any
	if finalDamage > 0 then
		HitService.hit(hitHumanoid, finalDamage, knockback, attackerKnockback, npc, ragdoll)
	end

	-- Clear stun after delay
	task.delay(CONFIG.STUN_DURATION, function()
		if enemy and enemy:FindFirstChild("Humanoid") then
			enemy:SetAttribute("Stunned", false)
		end
	end)

	-- Stop hitbox to prevent multiple hits
	hitboxInstance:Stop()
end

local function getAppropriateAnimation(npc, animations)
	-- Default to fallback animation if no specific one is found
	local animationToUse = animations.Default and animations.Default.Attack

	-- Check for weapon type
	local function hasSword(character)
		for _, child in ipairs(character:GetChildren()) do
			if string.find(child.Name, "Sword") then
				return true
			end
		end
		return false
	end

	-- Determine animation based on NPC type or equipment
	if hasSword(npc) and animations.Warrior then
		animationToUse = animations.Warrior.Attack
	elseif string.find(npc.Name, "Boar") and animations.Boars then
		animationToUse = animations.Boars.Attack
	elseif string.find(npc.Name, "Wolf") and animations.Wolfs then
		animationToUse = animations.Wolfs.Attack
	end

	-- Use cached animation if available
	if string.find(npc.Name, "Boar") and animationCache["Boar"] then
		return animationCache["Boar"]
	elseif string.find(npc.Name, "Wolf") and animationCache["Wolf"] then
		return animationCache["Wolf"]
	elseif hasSword(npc) and animationCache["Warrior"] then
		return animationCache["Warrior"]
	elseif animationCache["Default"] then
		return animationCache["Default"]
	end

	return animationToUse
end

-- Main Hit Function
function NPCCombatModule.Hit(npc, sound, animations, strength, hitboxSize)
	-- Early return checks
	if not npc or not npc:IsDescendantOf(workspace) then
		return
	end

	-- Cache animations for better performance
	if not next(animationCache) and animations then
		preloadAnimations(animations)
	end

	local hum = npc:FindFirstChild("Humanoid")
	local humRp = npc:FindFirstChild("HumanoidRootPart")

	if not hum or not humRp then
		return
	end

	-- Check NPC state
	local attacking = npc:GetAttribute("Attacking") or false
	local punching = npc:GetAttribute("Punching") or false
	local stunned = npc:GetAttribute("Stunned") or false
	local ragdolled = npc:GetAttribute("Ragdolled") or false
	local fallen = npc:GetAttribute("Fallen") or false

	if attacking or punching or stunned or ragdolled or fallen then
		return
	end

	-- Setup NPC state
	local npcState = initNPCState(npc)

	local currentTime = os.clock()
	local timeSinceLastAttack = currentTime - npcState.lastAttackTime

	if not npcState.animationComplete or timeSinceLastAttack < CONFIG.ATTACK_COOLDOWN then
		return
	end

	npcState.animationComplete = false
	npc:SetAttribute("Attacking", true)
	npc:SetAttribute("Punching", true)

	-- Get animator
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end

	-- Get appropriate animation
	local punchAnim = getAppropriateAnimation(npc, animations)
	if not punchAnim then
		warn("No animation found for NPC:", npc.Name)
		npc:SetAttribute("Attacking", false)
		npc:SetAttribute("Punching", false)
		npcState.animationComplete = true
		return
	end

	-- Load and play animation
	local playAnimation = animator:LoadAnimation(punchAnim)

	-- Apply speed multiplier based on attributes
	local speedMultiplier = getPlayerAttribute(npc, "SpeedMultiplier", 1.0)
	local adjustedAnimSpeed = speedMultiplier

	if speedMultiplier ~= 1.0 then
		playAnimation:AdjustSpeed(adjustedAnimSpeed)
	end

	-- Apply slow effect during attack
	task.spawn(function()
		repeat
			task.wait()
		until playAnimation.Length > 0
		npc:SetAttribute("Slowed", true)
	end)

	-- Create hitbox with size matching player scripts
	local hitboxInstance
	hitboxInstance = Hitbox.new({
		Size = hitboxSize or Vector3.new(4, 5, 4),
		CFrame = humRp,
		Offset = CFrame.new(0, 0, -2),
		--Visualizer = game:GetService("RunService"):IsStudio(),
		Visualizer = false,
		OwnerPlayer = nil, -- NPCs don't have players
		onTouch = function(hitHumanoid)
			local isNPC = hitHumanoid.Parent:GetAttribute("NPC")
			if hitHumanoid ~= hum and not isNPC then
				print("NPC hit detected on humanoid:", hitHumanoid)
				processHit(npc, hitboxInstance, hitHumanoid, sound, strength)
			end
		end,
	})

	-- Store hitbox reference for cleanup
	npcState.activeHitboxes[npc] = hitboxInstance

	-- Handle animation keyframes for precise timing
	playAnimation:GetMarkerReachedSignal("HitStart"):Connect(function()
		if not npc or not npc:IsDescendantOf(workspace) then
			return
		end

		-- Start hitbox at exact hit frame
		hitboxInstance:Start():AddToIgnoreList(npc)

		-- Play sound
		if sound then
			soundManager.playSound(sound, npc:FindFirstChild("Head"), { PlaybackSpeed = adjustedAnimSpeed })
		end

		-- Apply visual effects
		local hitArm = npc:FindFirstChild("Right Arm") or humRp
		particleSummoner.EmitParticles("LimbTrail", hitArm, nil, CONFIG.HIT_DURATION)

		-- Stop hitbox after short duration
		task.delay(CONFIG.HIT_DURATION, function()
			if hitboxInstance then
				hitboxInstance:Stop()

				-- Remove from active hitboxes
				if npcState.activeHitboxes[npc] == hitboxInstance then
					npcState.activeHitboxes[npc] = nil
				end
			end
		end)
	end)

	-- Play the animation
	playAnimation:Play(0.1, 1, adjustedAnimSpeed)

	-- Handle animation completion
	playAnimation.Stopped:Connect(function()
		if npc and npc:IsDescendantOf(workspace) then
			npc:SetAttribute("Slowed", false)
			npc:SetAttribute("Attacking", false)
			npcState.animationComplete = true
			npcState.lastAttackTime = os.clock()

			-- Add random delay before allowing next punch
			task.wait(math.random(1, 2))

			if npc and npc:IsDescendantOf(workspace) then
				npc:SetAttribute("Punching", false)
			end
		end
	end)
end

return NPCCombatModule