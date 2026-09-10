--// StarterCharacterScripts/UniversalController.luau
--// Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

--// Modules
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

--// Directories
local Remotes = RS:WaitForChild("RE")
local consumableRemote = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("ConsumeItemRE")
local animsFolder = RS:WaitForChild("Animations"):WaitForChild("Combat"):WaitForChild("Weapons")

--// Player references
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:FindFirstChildOfClass("Animator")

--// Constants
local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
local ATTACK_COOLDOWN = 0.1
local CHARGED_ATTACK_THRESHOLD = 0.8
local INPUT_BUFFER_TIME = 0.8
local ATTACK_DURATION = 0.4
local CONSUME_DURATION = 2.0 -- Time it takes to consume an item

--// Default non-combat tool animation
local DEFAULT_TOOL_ANIMATION_ID = "rbxasset://animations/toolnone.rbxm"
local CUSTOM_DEFAULT_ANIMATION_ID = "http://www.roblox.com/asset/?id=182393478"
local CONSUME_ANIMATION_ID = "rbxassetid://111029312383047" -- Drinking animation

--// Tool Types
local ToolType = {
	COMBAT = "combat",
	NON_COMBAT = "non_combat",
	CONSUMABLE = "consumable",
}

--// Combat States
local CombatState = {
	IDLE = "idle",
	ATTACKING = "attacking",
	CHARGING = "charging",
	CHARGED_ATTACK = "charged_attack",
	BLOCKING = "blocking",
	STUNNED = "stunned",
	CONSUMING = "consuming",
}

--// Skill Slots
local PlrSkills = {
	E = player:WaitForChild("Skills"):FindFirstChild("E").Value,
	R = player:WaitForChild("Skills"):FindFirstChild("R").Value,
	F = player:WaitForChild("Skills"):FindFirstChild("F").Value,
	V = player:WaitForChild("Skills"):FindFirstChild("V").Value,
	C = player:WaitForChild("Skills"):FindFirstChild("C").Value,
}

--// Weapon configurations mapped to item types
local WeaponConfigs = {
	Gauntlet = {
		remoteName = "GauntletCombat",
		skillRemoteName = "GauntletSkills",
		animationFolder = "Gauntlet",
		idleAnim = "GauntletIdle",
		walkAnim = "GauntletWalk",
		blockType = "Gauntlet",
		toolType = ToolType.COMBAT,
	},
	Sword = {
		remoteName = "SwordCombat",
		skillRemoteName = "SwordSkills",
		animationFolder = "Sword",
		idleAnim = "SwordIdle",
		walkAnim = "SwordWalk",
		blockType = "Sword",
		toolType = ToolType.COMBAT,
	},
	HeavySword = {
		remoteName = "HeavySwordCombat",
		skillRemoteName = "HeavySwordSkills",
		animationFolder = "HeavySword",
		idleAnim = "HeavySwordIdle",
		walkAnim = "HeavySwordWalk",
		blockType = "HeavySword",
		toolType = ToolType.COMBAT,
	},
	Axe = {
		remoteName = "AxeCombat",
		skillRemoteName = "AxeSkills",
		animationFolder = "Axe",
		idleAnim = "AxeIdle",
		walkAnim = "AxeWalk",
		blockType = "Axe",
		toolType = ToolType.COMBAT,
	},
	HeavyAxe = {
		remoteName = "HeavyAxeCombat",
		skillRemoteName = "HeavyAxeSkills",
		animationFolder = "HeavyAxe",
		idleAnim = "HeavyAxeIdle",
		walkAnim = "HeavyAxeWalk",
		blockType = "HeavyAxe",
		toolType = ToolType.COMBAT,
	},
}

--// Non-combat tool configurations
local NonCombatConfigs = {
	default = {
		animationId = CUSTOM_DEFAULT_ANIMATION_ID,
		toolType = ToolType.NON_COMBAT,
		enableMovement = true,
	},
}

--// Current tool state
local currentWeapon = nil
local currentTool = nil
local currentItemData = nil
local currentToolType = nil
local combatEnabled = false
local nonCombatEnabled = false
local consumableEnabled = false
local isConsuming = false
local animationConnection = nil

--// Combat tracking
local lastAttackTime = 0
local chargeStartTime = 0

--// Input system
local InputBuffer = {}
local inputBufferConnection = nil
local leftMouseDown = false
local rightMouseDown = false

--// Animation tracks
local idleTrack = nil
local walkingTrack = nil
local currentAttackTrack = nil
local defaultToolTrack = nil
local consumeTrack = nil

--// Remote references
local currentRemotes = {}

--// Input Buffer System
local function addToInputBuffer(inputType, timestamp)
	table.insert(InputBuffer, {
		type = inputType,
		timestamp = timestamp or tick(),
	})
end

--// Get item data and determine tool type
local function getItemDataAndToolType(tool)
	if not tool then
		return nil, nil, nil
	end

	local itemData = itemsData[tool.Name]
	if not itemData then
		warn("No item data found for tool: " .. tool.Name)
		return nil, ToolType.NON_COMBAT, nil
	end

	local itemType = itemData.Type or itemData.type
	if not itemType then
		warn("No type found in item data for tool: " .. tool.Name)
		return itemData, ToolType.NON_COMBAT, nil
	end

	-- Check if it's a consumable
	if itemType == "Consumable" then
		return itemData, ToolType.CONSUMABLE, itemType
	end

	-- Check if it's a combat weapon
	if WeaponConfigs[itemType] then
		return itemData, ToolType.COMBAT, itemType
	else
		return itemData, ToolType.NON_COMBAT, itemType
	end
end

--// Load weapon configuration for combat tools
local function loadWeaponConfig(weaponType)
	local config = WeaponConfigs[weaponType]
	if not config then
		warn("Unknown weapon type: " .. tostring(weaponType))
		return false
	end

	currentRemotes = {
		Combat = Remotes.Combat:WaitForChild(config.remoteName),
		Block = Remotes.Combat:WaitForChild("Block"),
		Skills = Remotes.Skills:WaitForChild(config.skillRemoteName)
	}

	local weaponAnimFolder = animsFolder:WaitForChild(config.animationFolder)
	idleTrack = animator:LoadAnimation(weaponAnimFolder[config.idleAnim])
	walkingTrack = animator:LoadAnimation(weaponAnimFolder[config.walkAnim])

	return true
end

--// Load non-combat tool configuration
local function loadNonCombatConfig(tool, itemType)
	local config = NonCombatConfigs[tool.Name] or NonCombatConfigs[itemType] or NonCombatConfigs.default

	local animationObject = Instance.new("Animation")
	animationObject.AnimationId = config.animationId

	defaultToolTrack = animator:LoadAnimation(animationObject)

	return config
end

--// Load consumable configuration
local function loadConsumableConfig()
	local animationObject = Instance.new("Animation")
	animationObject.AnimationId = CONSUME_ANIMATION_ID

	consumeTrack = animator:LoadAnimation(animationObject)

	-- Hold animation for consumables (similar to tools)
	local holdAnimObject = Instance.new("Animation")
	holdAnimObject.AnimationId = CUSTOM_DEFAULT_ANIMATION_ID
	defaultToolTrack = animator:LoadAnimation(holdAnimObject)

	return true
end

--// Check if tool is equipped
local function isToolEquipped()
	return currentTool and currentTool.Parent == character
end

--// Consume item
local function consumeItem()
	if not isToolEquipped() or not consumableEnabled or currentToolType ~= ToolType.CONSUMABLE then
		return
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return
	end

	if isConsuming then
		return
	end

	isConsuming = true
	character:SetAttribute("Consuming", true)

	-- Stop default hold animation
	if defaultToolTrack and defaultToolTrack.IsPlaying then
		defaultToolTrack:Stop(0.2)
	end

	-- Play consume animation
	if consumeTrack then
		consumeTrack:Play(0.2)
	end

	-- Wait for consumption
	task.wait(CONSUME_DURATION)

	-- Stop consume animation
	if consumeTrack and consumeTrack.IsPlaying then
		consumeTrack:Stop(0.2)
	end

	-- Fire server event to apply effects and remove item
	consumableRemote:FireServer(currentTool, currentItemData)

	isConsuming = false
	character:SetAttribute("Consuming", false)

	-- Tool will be removed by server, which will trigger unequip
end

--// Regular Attack (Combat tools only)
local function processAttack()
	if not isToolEquipped() or not combatEnabled or currentToolType ~= ToolType.COMBAT then
		return
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return
	end

	if idleTrack and idleTrack.IsPlaying then
		idleTrack:Stop(0.1)
	end
	if walkingTrack and walkingTrack.IsPlaying then
		walkingTrack:Stop(0.1)
	end

	currentRemotes.Combat:FireServer(currentTool, "normal")
end

--// Charged Attack (Combat tools only)
local function processChargedAttack()
	if not isToolEquipped() or not combatEnabled or currentToolType ~= ToolType.COMBAT then
		return
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return
	end

	if idleTrack and idleTrack.IsPlaying then
		idleTrack:Stop(0.1)
	end
	if walkingTrack and walkingTrack.IsPlaying then
		walkingTrack:Stop(0.1)
	end

	currentRemotes.Combat:FireServer(currentTool, "charged")
end

--// Process Skill Input
local function processSkill(skillSlot)
	if not isToolEquipped() or not combatEnabled or currentToolType ~= ToolType.COMBAT then
		return
	end

	if not currentRemotes.Skills then
		return
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return
	end

	currentRemotes.Skills:FireServer(currentTool, skillSlot)
end

local function processInputBuffer()
	local currentTime = tick()

	for i = #InputBuffer, 1, -1 do
		if currentTime - InputBuffer[i].timestamp > INPUT_BUFFER_TIME then
			table.remove(InputBuffer, i)
		end
	end

	if currentToolType == ToolType.COMBAT then
		for i, input in ipairs(InputBuffer) do
			if input.type == "attack" then
				processAttack()
				table.remove(InputBuffer, i)
				break
			elseif input.type == "charged_attack" then
				processChargedAttack()
				table.remove(InputBuffer, i)
				break
			end
		end
	end
end

--// Handle animations for combat tools
local function updateCombatAnimations()
	if animationConnection then
		animationConnection:Disconnect()
	end

	animationConnection = RunService.RenderStepped:Connect(function()
		if not combatEnabled or not isToolEquipped() or currentToolType ~= ToolType.COMBAT then
			return
		end

		processInputBuffer()

		local speed = humanoid.MoveDirection.Magnitude
		local walkingAnimWeight = math.min(1, speed * 2)

		if speed > 0.1 then
			if not walkingTrack.IsPlaying then
				walkingTrack:Play(0.15)
				walkingTrack:AdjustWeight(walkingAnimWeight, 0.1)
			end

			if idleTrack.IsPlaying then
				idleTrack:AdjustWeight(1 - walkingAnimWeight, 0.1)
				if walkingAnimWeight > 0.9 then
					idleTrack:Stop(0.1)
				end
			end
		else
			if walkingTrack.IsPlaying then
				walkingTrack:Stop(0.15)
			end

			if not idleTrack.IsPlaying then
				idleTrack:Play(0.15)
			end
		end
	end)
end

--// Handle animations for non-combat tools
local function updateNonCombatAnimations()
	if animationConnection then
		animationConnection:Disconnect()
	end

	if defaultToolTrack and not defaultToolTrack.IsPlaying then
		defaultToolTrack:Play(0.3)
		defaultToolTrack.Looped = true
	end

	animationConnection = RunService.RenderStepped:Connect(function()
		if not nonCombatEnabled or not isToolEquipped() or currentToolType ~= ToolType.NON_COMBAT then
			return
		end

		if defaultToolTrack and not defaultToolTrack.IsPlaying then
			defaultToolTrack:Play(0.1)
		end
	end)
end

--// Handle animations for consumables
local function updateConsumableAnimations()
	if animationConnection then
		animationConnection:Disconnect()
	end

	if defaultToolTrack and not defaultToolTrack.IsPlaying then
		defaultToolTrack:Play(0.3)
		defaultToolTrack.Looped = true
	end

	animationConnection = RunService.RenderStepped:Connect(function()
		if not consumableEnabled or not isToolEquipped() or currentToolType ~= ToolType.CONSUMABLE then
			return
		end

		if not isConsuming and defaultToolTrack and not defaultToolTrack.IsPlaying then
			defaultToolTrack:Play(0.1)
		end
	end)
end

--// Input Handlers (Combat tools only)
local function onAttackInputBegan()
	if currentToolType ~= ToolType.COMBAT then
		return
	end

	processAttack()

	local holdTime = tick()
	local charging = 0
	if leftMouseDown then
		while leftMouseDown do
			task.wait(0.1)
			charging += 0.1
			if not leftMouseDown then
				return
			end
			if charging >= CHARGED_ATTACK_THRESHOLD then
				break
			end
		end

		if holdTime >= CHARGED_ATTACK_THRESHOLD then
			addToInputBuffer("charged_attack")
		end
	end
end

local function onBlockInputBegan()
	if currentToolType ~= ToolType.COMBAT then
		return
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return
	end

	if currentRemotes.Block and currentWeapon then
		local config = WeaponConfigs[currentWeapon]
		currentRemotes.Block:FireServer(true, config.blockType)
	end
end

local function onBlockInputEnded()
	if currentToolType ~= ToolType.COMBAT then
		return
	end

	if currentRemotes.Block then
		currentRemotes.Block:FireServer(false)
	end
end

--// Consumable input handler
local function onConsumeInputBegan()
	if currentToolType ~= ToolType.CONSUMABLE then
		return Enum.ContextActionResult.Pass
	end

	if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
		return Enum.ContextActionResult.Pass
	end

	consumeItem()
	return Enum.ContextActionResult.Sink
end

--// Setup combat bindings
local function setupCombatBindings()
	ContextActionService:UnbindAction("UniversalAttack")
	ContextActionService:UnbindAction("UniversalBlock")

	ContextActionService:BindActionAtPriority("UniversalAttack", function(_, state)
		if currentToolType ~= ToolType.COMBAT then
			return Enum.ContextActionResult.Pass
		end

		if state == Enum.UserInputState.End then
			leftMouseDown = false
		elseif state == Enum.UserInputState.Begin then
			if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
				return Enum.ContextActionResult.Pass
			end

			leftMouseDown = true
			onAttackInputBegan()
		end

		return Enum.ContextActionResult.Pass
	end, true, INPUT_PRIORITY, Enum.UserInputType.MouseButton1)

	ContextActionService:BindActionAtPriority("UniversalBlock", function(_, state)
		if currentToolType ~= ToolType.COMBAT then
			return Enum.ContextActionResult.Pass
		end

		if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
			return Enum.ContextActionResult.Pass
		end

		if state == Enum.UserInputState.Begin then
			rightMouseDown = true
			onBlockInputBegan()
		elseif state == Enum.UserInputState.End then
			rightMouseDown = false
			onBlockInputEnded()
		end

		return Enum.ContextActionResult.Pass
	end, true, INPUT_PRIORITY, Enum.UserInputType.MouseButton2)
end

--// Setup consumable bindings
local function setupConsumableBindings()
	ContextActionService:UnbindAction("ConsumeItem")

	ContextActionService:BindActionAtPriority("ConsumeItem", function(_, state)
		if currentToolType ~= ToolType.CONSUMABLE then
			return Enum.ContextActionResult.Pass
		end

		if state == Enum.UserInputState.Begin then
			return onConsumeInputBegan()
		end

		return Enum.ContextActionResult.Pass
	end, true, INPUT_PRIORITY, Enum.UserInputType.MouseButton1, Enum.KeyCode.E)
end

--// Setup skill bindings
local function setupSkillBindings()
	local config = WeaponConfigs[currentWeapon]
	if not config then
		return
	end

	for keyCode, skillSlot in pairs(PlrSkills) do
		local actionName = "Skill_" .. keyCode

		ContextActionService:BindActionAtPriority(actionName, function(_, state)
			if currentToolType ~= ToolType.COMBAT then
				return Enum.ContextActionResult.Pass
			end

			if state == Enum.UserInputState.Begin then
				if character:GetAttribute("Ragdolled") or character:GetAttribute("Fallen") then
					return Enum.ContextActionResult.Pass
				end

				processSkill(skillSlot)
			end

			return Enum.ContextActionResult.Pass
		end, true, INPUT_PRIORITY, Enum.KeyCode[keyCode])
	end
end

--// Remove combat bindings
local function removeCombatBindings()
	ContextActionService:UnbindAction("UniversalAttack")
	ContextActionService:UnbindAction("UniversalBlock")

	leftMouseDown = false
	rightMouseDown = false
	InputBuffer = {}
end

--// Remove skill bindings
local function removeSkillBindings()
	for keyCode, _ in pairs(PlrSkills) do
		local actionName = "Skill_" .. keyCode
		ContextActionService:UnbindAction(actionName)
	end
end

--// Remove consumable bindings
local function removeConsumableBindings()
	ContextActionService:UnbindAction("ConsumeItem")
end

--// Handle combat tool equip
local function onCombatToolEquipped(tool, itemData, weaponType)
	currentWeapon = weaponType

	if not loadWeaponConfig(weaponType) then
		return
	end

	character:SetAttribute("CombatMode", true)
	combatEnabled = true

	lastAttackTime = 0
	InputBuffer = {}

	if idleTrack then
		idleTrack:Play(0.3)
	end

	updateCombatAnimations()
	setupCombatBindings()
	setupSkillBindings()
end

--// Handle non-combat tool equip
local function onNonCombatToolEquipped(tool, itemData, itemType)
	local config = loadNonCombatConfig(tool, itemType)

	nonCombatEnabled = true

	updateNonCombatAnimations()
end

--// Handle consumable tool equip
local function onConsumableToolEquipped(tool, itemData)
	loadConsumableConfig()

	consumableEnabled = true

	updateConsumableAnimations()
	setupConsumableBindings()

	print("Consumable equipped:", tool.Name, "- Click or press E to consume")
end

--// Handle tool equip
local function onToolEquipped(tool)
	if character:GetAttribute("Fallen") then
		return
	end

	currentTool = tool

	local itemData, toolType, itemType = getItemDataAndToolType(tool)
	currentItemData = itemData
	currentToolType = toolType

	if toolType == ToolType.COMBAT then
		if not itemType then
			warn("Combat tool " .. tool.Name .. " has no valid weapon type")
			return
		end
		onCombatToolEquipped(tool, itemData, itemType)
	elseif toolType == ToolType.CONSUMABLE then
		onConsumableToolEquipped(tool, itemData)
	elseif toolType == ToolType.NON_COMBAT then
		onNonCombatToolEquipped(tool, itemData, itemType)
	else
		warn("Unknown tool type for tool:", tool.Name)
	end
end

--// Handle tool unequip
local function onToolUnequipped(tool)
	if combatEnabled then
		character:SetAttribute("CombatMode", false)
		combatEnabled = false
		if currentRemotes.Block then
			currentRemotes.Block:FireServer(false)
		end
		removeCombatBindings()
		removeSkillBindings()
	end

	if nonCombatEnabled then
		nonCombatEnabled = false
	end

	if consumableEnabled then
		consumableEnabled = false
		isConsuming = false
		character:SetAttribute("Consuming", false)
		removeConsumableBindings()
	end

	if idleTrack then
		idleTrack:Stop(0.3)
		idleTrack = nil
	end
	if walkingTrack then
		walkingTrack:Stop(0.3)
		walkingTrack = nil
	end
	if defaultToolTrack then
		defaultToolTrack:Stop(0.3)
		defaultToolTrack = nil
	end
	if consumeTrack then
		consumeTrack:Stop(0.3)
		consumeTrack = nil
	end

	if animationConnection then
		animationConnection:Disconnect()
		animationConnection = nil
	end

	currentTool = nil
	currentWeapon = nil
	currentItemData = nil
	currentToolType = nil
	currentRemotes = {}
	InputBuffer = {}
end

--// Handle character respawn
local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:FindFirstChildOfClass("Animator")

	if currentTool then
		onToolUnequipped(currentTool)
	end
end

--// Main Event Connections
ContextActionService.LocalToolEquipped:Connect(function(tool)
	onToolEquipped(tool)
end)

ContextActionService.LocalToolUnequipped:Connect(function(tool)
	onToolUnequipped(tool)
end)

player.CharacterAdded:Connect(onCharacterAdded)
