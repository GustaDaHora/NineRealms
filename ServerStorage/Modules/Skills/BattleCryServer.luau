-- BattleCryServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleSummoner = require(script.Parent.Parent.ParticleSummoner)
local soundManager = require(script.Parent.Parent.SoundManager)

local BattleCryServer = {}

-- Skill properties
BattleCryServer.Properties = {
	Class = "Warrior",
	Weapons = "Any",
	IsPassive = true,
	Cooldown = 45,
	Duration = 15,
	SoulsCost = 50,
	Description = "Increases physical damage by 25% for 15 seconds and reduces incoming damage by 10%."
}

-- Cooldown tracking for each player
local playerCooldowns = {}

function BattleCryServer:Activate(player:Player)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return false end

	-- Check if skill is on cooldown
	local playerId = player.UserId
	if playerCooldowns[playerId] and os.time() < playerCooldowns[playerId] then
		return false, "Skill is on cooldown"
	end
	local dataFolder = player:FindFirstChild("Data")
	local souls = dataFolder:FindFirstChild("Souls")

	-- Apply skill effects
	local damageMultiplier = player:GetAttribute("DamageMultiplier")
	if damageMultiplier then
		local originalDamageValue = damageMultiplier.Value
		damageMultiplier.Value = originalDamageValue * 1.25 -- 25% increase

		-- Reset after duration
		delay(BattleCryServer.Properties.Duration, function()
			if player and player:GetAttribute("DamageMultiplier") then
				damageMultiplier.Value = originalDamageValue
			end
		end)
	end

	local damageReduction = player:GetAttribute("DamageReduction")
	if damageReduction then
		local originalReductionValue = damageReduction.Value
		damageReduction.Value = originalReductionValue + 0.1 -- 10% reduction

		-- Reset after duration
		delay(BattleCryServer.Properties.Duration, function()
			if player and player:GetAttribute("DamageReduction") then
				damageReduction.Value = originalReductionValue
			end
		end)
	end

	-- Apply souls cost
	--souls.Value = souls.Value - BattleCryServer.Properties.SoulsCost

	-- Set cooldown
	playerCooldowns[playerId] = os.time() + BattleCryServer.Properties.Cooldown

	-- Visual effects
	particleSummoner.EmitParticles("BattleCry", character.Torso, 1, 1)
	particleSummoner.EmitParticles("BattleCryIndicator", character.Torso, nil, BattleCryServer.Properties.Duration)
	local Highlight = ReplicatedStorage.Particles.BattleCryHighlight:Clone()
	Highlight.Parent = character
	soundManager.playSound("BattleCry", character.Head)

	return true
end

return BattleCryServer