-- Services
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Constants
local MODULES_PATH = RS:WaitForChild("Modules")
local SKILLS_INFO = require(MODULES_PATH:WaitForChild("SkillsInfo"))
local SKILLS_MODULE_PATH = MODULES_PATH:WaitForChild("Skills")
local KEY_BINDINGS = {
	[Enum.KeyCode.C] = "C",
	[Enum.KeyCode.R] = "R",
	[Enum.KeyCode.F] = "F",
	[Enum.KeyCode.V] = "V",
}

-- Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local skillsFrame = mainGui:WaitForChild("SkillsFrame")
local playerSkills = player:WaitForChild("Skills")
local cooldowns = {}
local skillModules = {}
local connections = {}
local isEnabled = true

local EnableSkills = function()
	isEnabled = true
end

local DisableSkills = function()
	isEnabled = false
end

local GetCooldownStatus = function(keyBinding)
	return cooldowns[keyBinding] or false
end

local GetRemainingCooldown = function(keyBinding)
	local button = skillsFrame:FindFirstChild(keyBinding)
	if not button then return 0 end

	local cooldownText = button:FindFirstChild("CooldownText")
	if not cooldownText or cooldownText.Text == "" then return 0 end

	return tonumber(cooldownText.Text) or 0
end

local Cleanup = function()
	for _, connection in ipairs(connections) do
		if connection then connection:Disconnect() end
	end
	connections = {}
	cooldowns = {}
	isEnabled = false
end

-- Utility Functions
local function getSkillModule(skillName)
	if not skillName then return nil end

	-- Remove spaces from skill name to match module naming convention
	local preName = string.gsub(skillName, "'", "")
	local moduleName = string.gsub(preName, " ", "") .. "Client"
	-- Cache the module to avoid requiring it each time
	if not skillModules[moduleName] then
		local moduleScript = SKILLS_MODULE_PATH:FindFirstChild(moduleName)
		if not moduleScript then
			warn("Skill module not found:", moduleName)
			return nil
		end

		-- Try to require the module, handle any errors
		local success, result = pcall(function()
			return require(moduleScript)
		end)

		if success then
			skillModules[moduleName] = result
		else
			warn("Failed to require skill module:", moduleName, "Error:", result)
			return nil
		end
	end

	return skillModules[moduleName]
end

-- Core Functions
local function animateCooldown(button, bar, cooldownText, duration)
	-- Reset the bar to initial state
	bar.Size = UDim2.new(0, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)

	-- Create and play the tween
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local finalSize = UDim2.new(0.8, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
	local tween = TweenService:Create(bar, tweenInfo, {Size = finalSize})
	tween:Play()

	-- Update the countdown text
	local startTime = tick()
	local connection

	connection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local remaining = math.max(0, duration - elapsed)

		if remaining <= 0 then
			cooldownText.Text = ""
			if connection then
				connection:Disconnect()
			end
		else
			cooldownText.Text = string.format("%.1f", remaining)
		end
	end)

	table.insert(connections, connection)

	return tween
end

local function useSkill(keyBinding)
	-- Get skill name from player's skills
	local skillValue = playerSkills:FindFirstChild(keyBinding)
	if not skillValue then
		warn("Skill value not found for key binding:", keyBinding)
		return
	end

	local skillName = skillValue.Value
	if not skillName or skillName == "" then
		return
	end

	-- Get skill info
	local skillInfo = SKILLS_INFO[skillName]
	if not skillInfo then
		warn("Skill info not found for skill:", skillName)
		return
	end

	-- Get and initialize the skill button
	local button = skillsFrame:FindFirstChild(keyBinding)
	local cooldownText = button:WaitForChild("CooldownText")
	local bar = button:WaitForChild("Bar")

	-- Get the skill module
	local skillModule = getSkillModule(skillName)

	-- Mark the skill as on cooldown
	cooldowns[keyBinding] = true

	-- Try to activate the skill
	local success, result = pcall(function()
		return skillModule.Activate()
	end)

	if not success then
		warn("Failed to activate skill:", skillName, "Error:", result)
		cooldowns[keyBinding] = false
		return
	end

	-- Get cooldown duration from skill info
	local cooldownTime = skillInfo.Cooldown

	-- Animate the cooldown
	local tween = animateCooldown(button, bar, cooldownText, cooldownTime)

	-- Reset the cooldown when the tween completes
	tween.Completed:Connect(function()
		cooldowns[keyBinding] = false
		cooldownText.Text = ""
	end)
end

-- Input Handler
local function onInputBegan(input, gameProcessed)
	if gameProcessed or not isEnabled then return end

	local binding = KEY_BINDINGS[input.KeyCode]
	if binding then
		useSkill(binding)
	end
end

-- Connect input handler
local inputConnection = UIS.InputBegan:Connect(onInputBegan)
table.insert(connections, inputConnection)

-- Listen for player added skills
for _, keyBinding in pairs(KEY_BINDINGS) do
	local skillValue = playerSkills:FindFirstChild(keyBinding)
	if not skillValue then
		skillValue = Instance.new("StringValue")
		skillValue.Name = keyBinding
		skillValue.Parent = playerSkills
	end

	local valueChanged = skillValue.Changed:Connect(function()
		-- Update the button UI when the skill changes
		local button = skillsFrame:FindFirstChild(keyBinding)
		if button then
			local skillName = skillValue.Value
			local skillInfo = SKILLS_INFO[skillName]
			if skillInfo and skillInfo.Icon then
				-- Update the icon
				local icon = button:FindFirstChild("Icon")
				if icon then
					icon.Image = skillInfo.Icon
				end
			end
		end
	end)

	table.insert(connections, valueChanged)
end