--// Services
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

--// Modules
local SoundManager = require(ServerStorage.Modules:WaitForChild("SoundManager"))
local SkillsInfo = require(ReplicatedStorage.Modules:WaitForChild("SkillsInfo"))

--// Remotes
local UnlockSkillRF = ReplicatedStorage.RE.Others:WaitForChild("UnlockSkill") -- RemoteFunction
local UseSkillRE = ReplicatedStorage.RE.Others:WaitForChild("UseSkill") -- RemoteEvent
local EquipSkill = ReplicatedStorage.RE.Others:WaitForChild("EquipSkill") -- RemoteEvent

--// Setup
SoundManager.preloadSounds(SoundService.Skills)

local Cooldowns = {}

-- Clean up memory when player leaves
game.Players.PlayerRemoving:Connect(function(player)
	Cooldowns[player] = nil
end)

--// Helper Functions
local function hasUnlockedSkill(player, skillName)
	local unlockedSkills = player:FindFirstChild("UnlockedSkills")
	if unlockedSkills then
		local skillFlag = unlockedSkills:FindFirstChild(skillName)
		return skillFlag and skillFlag.Value == true
	end
	return false
end

--// Remote Events
UseSkillRE.OnServerEvent:Connect(function(player, skillName, optionalDirection)
	--print(player, skillName, optionalDirection)
	if typeof(skillName) ~= "string" then return end

	-- Ensure player has unlocked the skill
	if not hasUnlockedSkill(player, skillName) then
		warn(player.Name .. " tried to use an unowned skill: " .. tostring(skillName))
		return
	end

	-- Initialize cooldown table for player
	Cooldowns[player] = Cooldowns[player] or {}

	-- Check cooldown
	if Cooldowns[player][skillName] then return end
	local skillData = SkillsInfo[skillName]
	if not skillData then
		warn("SkillInfo missing for:", skillName)
		return
	end

	-- Mark as on cooldown
	Cooldowns[player][skillName] = true

	-- Load and activate skill
	local preName = string.gsub(skillName, "'", "")
	local moduleName = string.gsub(preName, " ", "") .. "Server"

	local skillModule = ServerStorage.Modules.Skills:FindFirstChild(moduleName)
	if not skillModule then
		warn("Skill module not found:", skillName)
		return
	end

	local success, skill = pcall(require, skillModule)
	if not success then
		warn("Failed to load skill module:", skillName, skill)
		Cooldowns[player][skillName] = nil -- clear cooldown if error
		return
	end

	-- Activate skill
	if typeof(skill.Activate) == "function" then
		task.spawn(function()
			skill:Activate(player, optionalDirection)
		end)
	else
		warn("Skill module missing 'Activate' function:", skillName)
		Cooldowns[player][skillName] = nil -- clear cooldown if bad module
		return
	end

	-- Handle cooldown reset
	task.delay(skillData.Cooldown, function()
		if Cooldowns[player] then
			Cooldowns[player][skillName] = nil
		end
	end)
end)

EquipSkill.OnServerEvent:Connect(function(player, equip, _, skillName)
	if typeof(skillName) ~= "string" then return end
	if not hasUnlockedSkill(player, skillName) then
		warn(player.Name .. " tried to equip an unowned skill: " .. tostring(skillName))
		return
	end

	local playerSkills = player.Skills
	if not playerSkills then error(playerSkills) return end

	-- Get all available skill slots
	local availableSlots = {}
	
	for _, skill in ipairs(playerSkills:GetChildren()) do
		if skill.Value == "" then
			table.insert(availableSlots, skill)
		elseif skill.Value == skillName then
			skill.Value = ""
		end
	end

	-- Choose a random slot
	local randomSlot = availableSlots[math.random(1, #availableSlots)]

	if randomSlot.Value == skillName then return end

	-- Equip or unequip the skill
	if equip then
		randomSlot.Value = skillName
	else
		-- If unequipping, no need to do anything as we already cleared it above
	end
end)

UnlockSkillRF.OnServerInvoke = function(player, skillName)
	if typeof(skillName) ~= "string" then
		return false, "Invalid skill name."
	end

	local dataFolder = player:FindFirstChild("Data")
	local unlockedSkills = player:FindFirstChild("UnlockedSkills")
	if not (dataFolder and unlockedSkills) then
		error(dataFolder, unlockedSkills)
		return false, "Data not ready."
	end

	local souls = dataFolder:FindFirstChild("Souls")
	local skillData = SkillsInfo[skillName]

	if not (souls and skillData) then
		error(souls, skillData)
		return false, "Invalid skill."
	end

	if souls.Value >= skillData.SoulsCost then
		local unlockFlag = unlockedSkills:FindFirstChild(skillName)
		if unlockFlag then
			unlockFlag.Value = true
			return true, "Skill Unlocked!"
		else
			error(unlockFlag)
			return false, "Unlock flag missing."
		end
	else
		return false, "Not enough Souls!"
	end
end
