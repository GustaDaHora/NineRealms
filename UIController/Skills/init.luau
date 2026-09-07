-- UIController/Skills/init.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local UnlockSkillEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("UnlockSkill")
local equipSkillEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("EquipSkill")
local useSkillEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("UseSkill")

local skillsInfo = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SkillsInfo"))
local newsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("News"))

local Skills = {}
local skillClients = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Skills")
local clientModules = {
	["Battle Cry"] = "BattleCryClient",
	["Holy Blessing"] = "HolyBlessingClient",
	["Nature's Gift"] = "NaturesGiftClient",
	["Blink"] = "BlinkClient",
}
local keyToSlot = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
}
local cooldownTokens: { [number]: number } = {}

local function activateSkill(slotIndex: number)
	local state = store:getState()
	if state.activeWindow ~= nil or state.dialog ~= nil or state.isDead then
		return
	end

	local skill = state.skills and state.skills[slotIndex]
	local moduleName = skill and clientModules[skill.name]
	local currentCooldown = state.skillCooldowns and state.skillCooldowns[slotIndex]
	if currentCooldown and currentCooldown.remaining > 0 then
		return
	end

	local module = moduleName and skillClients:FindFirstChild(moduleName)
	if module then
		local ok, client = pcall(require, module)
		if not ok or type(client) ~= "table" or type(client.Activate) ~= "function" then
			warn("Unable to activate skill " .. tostring(skill.name))
			return
		end
		client.Activate()
	else
		-- Not every server skill has bespoke client-side movement/VFX. The generic
		-- remote keeps those equipped slots usable without coupling the HUD to them.
		useSkillEvent:FireServer(skill.name)
	end
	local total = math.max(0, skill.cooldown or 0)
	if total <= 0 then
		return
	end

	cooldownTokens[slotIndex] = (cooldownTokens[slotIndex] or 0) + 1
	local token = cooldownTokens[slotIndex]
	local expiresAt = os.clock() + total
	local function updateCooldown()
		if cooldownTokens[slotIndex] ~= token then return end
		local remaining = math.max(0, expiresAt - os.clock())
		store:dispatch(function(nextState)
			nextState.skillCooldowns[slotIndex] = { remaining = remaining, total = total }
			return nextState
		end)
		if remaining > 0 then
			task.delay(0.1, updateCooldown)
		end
	end
	updateCooldown()
end

local function syncSkillsData()
	local unlockedFolder = player:FindFirstChild("UnlockedSkills")
	local unlockedMap = { Initial = true }
	if unlockedFolder then
		for _, val in ipairs(unlockedFolder:GetChildren()) do
			if val:IsA("BoolValue") and val.Value then
				unlockedMap[val.Name] = true
			end
		end
	end

	local playerData = player:FindFirstChild("Data")
	local classPathVal = playerData and playerData:FindFirstChild("ClassPath")
	local chosenPath = classPathVal and (classPathVal.Value ~= "" and classPathVal.Value or nil) or nil

	local playerSkills = player:FindFirstChild("Skills")
	local activeSkills = {}
	if playerSkills then
		for i = 1, 4 do
			local slotVal = playerSkills:FindFirstChild("Slot" .. i)
			if slotVal and slotVal.Value ~= "" then
				local sInfo = skillsInfo[slotVal.Value]
				activeSkills[i] = {
					name = slotVal.Value,
					icon = "rbxassetid://16751205466",
					isUsable = true,
					cooldown = sInfo and sInfo.Cooldown or 0,
				}
			end
		end
	end

	store:dispatch(function(state)
		state.unlockedSkills = unlockedMap
		state.chosenPath = chosenPath
		state.skills = activeSkills
		return state
	end)
end

local function handleUnlockSkill(skillName: string): boolean
	local skillData = skillsInfo[skillName]
	local soulsVal = player:FindFirstChild("Data") and player.Data:FindFirstChild("Souls")

	if skillData and soulsVal and soulsVal.Value < (skillData.SoulsCost or 0) then
		newsModule.NewMessage("Not enough Souls!", 2)
		return false
	end

	local success, message = UnlockSkillEvent:InvokeServer(skillName)
	if success then
		local unlockSound = script:FindFirstChild("Unlock")
		if unlockSound then unlockSound:Play() end
		syncSkillsData()
	end
	if message then
		newsModule.NewMessage(message, 2)
	end
	return success == true
end

local function handleEquipSkill(skillName: string, slotIndex: number)
	local slotName = "Slot" .. slotIndex
	equipSkillEvent:FireServer(true, slotName, skillName)

	local equipSound = script:FindFirstChild("Equip")
	if equipSound then equipSound:Play() end
	-- Player.Skills replication is authoritative. Its ChildAdded/Changed
	-- listeners call syncSkillsData once the server has accepted the equip.
end

function Skills.Start()
	-- Register unlock and equip actions on UIStore
	store:dispatch(function(state)
		state.unlockSkill = handleUnlockSkill
		state.equipSkill = handleEquipSkill
		state.activateSkill = activateSkill
		return state
	end)

	-- Listen for unlocked skills folder changes
	local unlockedFolder = player:WaitForChild("UnlockedSkills", 5)
	if unlockedFolder then
		unlockedFolder.ChildAdded:Connect(syncSkillsData)
		for _, child in ipairs(unlockedFolder:GetChildren()) do
			if child:IsA("ValueBase") then
				child.Changed:Connect(syncSkillsData)
			end
		end
	end

	-- Listen for active skills slot changes
	local playerSkills = player:WaitForChild("Skills", 5)
	if playerSkills then
		playerSkills.ChildAdded:Connect(syncSkillsData)
		for _, child in ipairs(playerSkills:GetChildren()) do
			if child:IsA("ValueBase") then
				child.Changed:Connect(syncSkillsData)
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		local slotIndex = keyToSlot[input.KeyCode]
		if slotIndex then
			activateSkill(slotIndex)
		end
	end)

	-- Listen for ClassPath changes
	local dataFolder = player:WaitForChild("Data", 5)
	if dataFolder then
		local classPath = dataFolder:WaitForChild("ClassPath", 5)
		if classPath then
			classPath.Changed:Connect(syncSkillsData)
		end
	end

	syncSkillsData()
end

return Skills
