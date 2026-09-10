-- NaturesGiftServer.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleSummoner = require(script.Parent.Parent.ParticleSummoner)
local soundManager = require(script.Parent.Parent.SoundManager)

local NaturesGiftServer = {}

-- Skill properties
NaturesGiftServer.Properties = {
	Class = "Warden",
	Weapons = "Any",
	IsPassive = true,
	Cooldown = 30,
	SoulsCost = 60,
	Description = "Instantly heals 30% of total health. Healing increases by 10% per tier."
}

-- Cooldown tracking for each player
local playerCooldowns = {}

function NaturesGiftServer:Activate(player:Player)
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") then return false end

	---- Check if player is of correct class
	--if player:FindFirstChild("Class") and player.Class.Value ~= "Warden" then
	--	return false, "This skill can only be used by Wardens"
	--end

	---- Check if player has enough souls
	--local souls = player:FindFirstChild("Souls")
	--if not souls or souls.Value < NaturesGiftServer.Properties.SoulsCost then
	--	return false, "Not enough souls"
	--end
	
	-- Check if skill is on cooldown
	local playerId = player.UserId
	if playerCooldowns[playerId] and os.time() < playerCooldowns[playerId] then
		return false, "Skill is on cooldown"
	end

	-- Apply skill effects
	local humanoid = character.Humanoid

	-- Get player tier (assuming tier is stored as a value in player)
	local tier = player:WaitForChild("Data"):WaitForChild("Tier") and player.Data.Tier.Value or "Newcomer"
	local increase = 1
	if string.find(tier, "Novice") then
		increase = 2
	elseif string.find(tier, "Skilled") then
		increase = 3
	elseif string.find(tier, "Veteran") then
		increase = 3
	elseif string.find(tier, "Elite") then
		increase = 3
	elseif string.find(tier, "Champion") then
		increase = 4
	end
	
	-- Calculate healing amount: 30% + 10% per tier above 1
	local healingPercent = 0.3 + (increase - 1) * 0.1
	local maxHealth = humanoid.MaxHealth
	local healAmount = maxHealth * healingPercent

	-- Apply healing
	humanoid.Health = math.min(humanoid.Health + healAmount, maxHealth)

	-- Apply souls cost
	--souls.Value = souls.Value - NaturesGiftServer.Properties.SoulsCost

	-- Set cooldown
	playerCooldowns[playerId] = os.time() + NaturesGiftServer.Properties.Cooldown

	-- Visual effects
	particleSummoner.EmitParticles("NaturesGift", character.Torso, 1, 1)
	task.wait(1.5)
	particleSummoner.EmitParticles("NaturesGiftIndicator", character.Torso, math.random(30,80), 1)
	soundManager.playSound("NaturesGift", character.HumanoidRootPart)
	character.Torso.NaturesGiftIndicator.Part.Position = character.Torso.Position
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = character.Torso
	weld.Part0 = character.Torso.NaturesGiftIndicator.Part
	weld.Parent = character.Torso.NaturesGiftIndicator.Part
	return true
end

return NaturesGiftServer