-- HolyBlessingServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleSummoner = require(script.Parent.Parent.ParticleSummoner)
local soundManager = require(script.Parent.Parent.SoundManager)

local HolyBlessingServer = {}

-- Skill properties
HolyBlessingServer.Properties = {
	Class = "Paladin",
	Weapons = "Any",
	IsPassive = true,
	Cooldown = 60,
	Duration = 60,
	SoulsCost = 30,
	Description = "Buffs the defense of your equipped armor by 20% for 60 seconds and regenerates 10% of total health."
}

-- Cooldown tracking for each player
local playerCooldowns = {}

function HolyBlessingServer:Activate(player)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return false end

	-- Check if player has enough souls
	--local souls = player:FindFirstChild("Souls")
	--if not souls or souls.Value < HolyBlessingServer.Properties.SoulsCost then
	--	return false, "Not enough souls"
	--end

	-- Check if skill is on cooldown
	local playerId = player.UserId
	if playerCooldowns[playerId] and os.time() < playerCooldowns[playerId] then
		return false, "Skill is on cooldown"
	end

	-- Apply skill effects
	local humanoid = character.Humanoid

	-- Apply defense buff (This would connect to your armor system)
	-- Example: Assuming you have a DefenseMultiplier value in the player
	local defenseMultiplier = player:FindFirstChild("DefenseMultiplier")
	if defenseMultiplier then
		local originalValue = defenseMultiplier.Value
		defenseMultiplier.Value = originalValue * 1.2 -- 20% increase

		-- Reset after duration
		delay(HolyBlessingServer.Properties.Duration, function()
			if player and player:FindFirstChild("DefenseMultiplier") then
				defenseMultiplier.Value = originalValue
			end
		end)
	end

	-- Apply health regeneration
	local maxHealth = humanoid.MaxHealth
	humanoid.Health = math.min(humanoid.Health + (maxHealth * 0.1), maxHealth)

	-- Apply souls cost
	--souls.Value = souls.Value - HolyBlessingServer.Properties.SoulsCost

	-- Set cooldown
	playerCooldowns[playerId] = os.time() + HolyBlessingServer.Properties.Cooldown

	-- Visual effects
	particleSummoner.EmitParticles("HolyBlessingIndicator", character.Torso, 1, HolyBlessingServer.Properties.Duration)
	particleSummoner.EmitParticles("HolyBlessing", character.Torso, 1, 0.8)
	local Highlight = ReplicatedStorage.Particles.HolyBlessingHighlight:Clone()
	Highlight.Parent = character
	soundManager.playSound("HolyBlessing", character.Head)

	return true
end

return HolyBlessingServer