local BlockingSystem = {}

-- Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("RE"):WaitForChild("Combat")
local BlockRemote = Remotes:WaitForChild("Block") 
local AnimsFolder = RS.Animations.Combat.Weapons

-- Constants
local PARRY_WINDOW = 0.2
local BLOCK_COOLDOWN = 1
local BLOCK_BREAK_COOLDOWN = 0.75

-- Player state trackers
local CanBlock = {}
local blockBroken = {}
local BlockAnims = {}
local PlayerBlockType = {} -- Track what type each player is blocking with

-- Animation data
local BlockAnimsData = {
	Gauntlet = AnimsFolder.Gauntlet.Block,
	Sword = AnimsFolder.Sword.Block,
	HeavyAxe = AnimsFolder.HeavyAxe.Block
}
local BlockBreakAnim = RS.Animations.Combat.EnemyReaction.BlockBreak

-- Block type categories
local BLOCK_TYPES = {
	WEAPON = {"Sword", "HeavySword", "Axe", "HeavyAxe"},
	GAUNTLET = {"Gauntlet"}
}

-- Check if a given tool type belongs to a category
local function isBlockType(toolType, category)
	if category == "ANY" then return true end

	for _, validType in ipairs(BLOCK_TYPES[category]) do
		if toolType == validType then
			return true
		end
	end
	return false
end

-- Check if one block type can block attacks from another
local function canBlockAttack(blockType, attackType)
	-- Weapons can block weapons and Gauntlets
	if isBlockType(blockType, "WEAPON") then
		return true
	end

	-- Gauntlets can only block Gauntlets
	if isBlockType(blockType, "GAUNTLET") and isBlockType(attackType, "GAUNTLET") then
		return true
	end

	return false
end

local function OnBlockBegin(player, char, hum, toolType)
	if not toolType or not BlockAnimsData[toolType] then
		warn("Invalid tool type for blocking:", toolType)
		return
	end

	if char:GetAttribute("Blocking") or 
		char:GetAttribute("Attacking") or 
		not CanBlock[player] or 
		char:GetAttribute("Stunned") then
		return
	end

	-- Set block state and store block type
	char:SetAttribute("Blocking", true)
	char:SetAttribute("Parrying", true)
	PlayerBlockType[player] = toolType -- Store what type of block they're using

	-- Set attribute to indicate if it's a weapon or Gauntlet block
	char:SetAttribute("BlockType", toolType)
	char:SetAttribute("IsWeaponBlock", isBlockType(toolType, "WEAPON"))

	-- Parry window
	task.delay(PARRY_WINDOW, function()
		if char and char:GetAttribute("Parrying") then
			char:SetAttribute("Parrying", false)
		end
	end)

	-- Play block animation
	if BlockAnims[player] then
		BlockAnims[player]:Stop()
	end

	local animObj = BlockAnimsData[toolType]
	if animObj then
		BlockAnims[player] = hum.Animator:LoadAnimation(animObj)
		BlockAnims[player]:Play(0, 1, 1.1)
	end

	CanBlock[player] = false
end

local function OnBlockEnd(player, char, hum)
	if not char:GetAttribute("Blocking") or blockBroken[player] then
		return
	end

	char:SetAttribute("Blocking", false)
	char:SetAttribute("Parrying", false)
	char:SetAttribute("BlockType", nil)
	char:SetAttribute("IsWeaponBlock", nil)
	PlayerBlockType[player] = nil

	if BlockAnims[player] then
		BlockAnims[player]:Stop()
		BlockAnims[player] = nil
	end

	-- Reset the block cooldown
	task.delay(BLOCK_COOLDOWN, function()
		if player and CanBlock[player] ~= nil then -- Check if player still exists
			CanBlock[player] = true
		end
	end)
end

local function OnBlockBreak(char, hum, player)
	local playerKey = player or "NPC"

	if not blockBroken[playerKey] and char:GetAttribute("Blocking") then
		blockBroken[playerKey] = true
		CanBlock[playerKey] = false

		if BlockAnims[playerKey] then
			BlockAnims[playerKey]:Stop()
			BlockAnims[playerKey] = nil
		end

		local blockBreakAnim = hum.Animator:LoadAnimation(BlockBreakAnim)
		blockBreakAnim:Play()

		char:SetAttribute("Blocking", false)
		char:SetAttribute("Parrying", false)
		char:SetAttribute("BlockType", nil)
		char:SetAttribute("IsWeaponBlock", nil)
		PlayerBlockType[playerKey] = nil

		task.spawn(function()
			task.wait(BLOCK_BREAK_COOLDOWN)
			if playerKey ~= "NPC" and (not Players:FindFirstChild(playerKey) or CanBlock[playerKey] == nil) then
				return -- Player left during cooldown
			end
			CanBlock[playerKey] = true
			blockBroken[playerKey] = false
		end)
	end
end

-- Public API
function BlockingSystem.CanDefendAgainst(player, attackToolType)
	local blockType = PlayerBlockType[player]
	if not blockType then return false end

	return canBlockAttack(blockType, attackToolType)
end

function BlockingSystem.GetPlayerBlockType(player)
	return PlayerBlockType[player]
end

function BlockingSystem.IsParrying(player)
	local char = player.Character
	return char and char:GetAttribute("Parrying") or false
end

function BlockingSystem.IsBlocking(player)
	local char = player.Character
	return char and char:GetAttribute("Blocking") or false
end

function BlockingSystem.ForceBlockBreak(character)
	local player = Players:GetPlayerFromCharacter(character)
	local hum = character and character:FindFirstChild("Humanoid")
	if character and hum then
		OnBlockBreak(character, hum, player)
	end
end

BlockRemote.OnServerEvent:Connect(function(player, block, toolType)
	local char = player.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if char and hum then
		if block then
			OnBlockBegin(player, char, hum, toolType)
		else
			OnBlockEnd(player, char, hum)
		end
	end
end)

-- Player Management
Players.PlayerAdded:Connect(function(player)
	CanBlock[player] = true
	blockBroken[player] = false
	PlayerBlockType[player] = nil
end)

Players.PlayerRemoving:Connect(function(player)
	CanBlock[player] = nil
	blockBroken[player] = nil
	BlockAnims[player] = nil
	PlayerBlockType[player] = nil
end)

return BlockingSystem