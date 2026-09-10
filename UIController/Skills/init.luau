--// Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

--// Modules
local skillsInfo = require(RS:WaitForChild("Modules"):WaitForChild("SkillsInfo"))
local NewsModule = require(RS:WaitForChild("Modules"):WaitForChild("News"))
local godsInfo = require(RS:WaitForChild("Modules"):WaitForChild("NorsegodsInfo"))
local SkillTree = require(script:WaitForChild("HorizontalSkillTree"))
--// Events
local UnlockSkillEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("UnlockSkill")
local equipSkillEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("EquipSkill")

--// Constants
local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local BUTTON_COLORS = {
	UNLOCK = Color3.fromRGB(118, 255, 80),
	EQUIP = Color3.fromRGB(80, 170, 255),
	ERROR = Color3.fromRGB(168, 20, 20)
}
local HOVER_OFFSET = Vector2.new(55, 95)
local ERROR_DISPLAY_TIME = 1.5

--// Player Variables
local player = Players.LocalPlayer
local mainGui = script.Parent.Parent
local skillsUI = mainGui:WaitForChild("Skills")
local skillsTree = skillsUI:WaitForChild("ScrollingFrame")
local plrSkills = skillsUI:WaitForChild("PlrSkills")
local hoverFrame = skillsUI:WaitForChild("HoverFrame")
local unlockButton = hoverFrame:WaitForChild("Unlock")
local equipButton = hoverFrame:WaitForChild("Equip")
local closeButton = hoverFrame:WaitForChild("Close")
local skillsFrame = mainGui:WaitForChild("SkillsFrame")
local playerSkills = player:WaitForChild("Skills")
local unlockedSkills = player:WaitForChild("UnlockedSkills")
local playerData = player:WaitForChild("Data")
local plrClassPath = playerData:WaitForChild("ClassPath")

--// Sound Effects
local unlockSound = script:FindFirstChild("Unlock")
local equipSound = script:FindFirstChild("Equip")
local hoverSound = script:FindFirstChild("Hover")

--// States
local Skills = {}
local isHoverLocked = false
local isDragging = false
local lastMousePosition = Vector2.zero
local selectedSkillName = nil
local isUnlocking = false
local connections = {} -- Store connections for cleanup

--// Local Functions
local function getFreeSkillSlot()
	for _, slot in ipairs(playerSkills:GetChildren()) do
		if slot:IsA("StringValue") and slot.Value == "" then
			return slot.Name
		end
	end
	return nil
end

local function updateHoverFramePosition()
	if not isHoverLocked then
		local mouseLocation = UserInputService:GetMouseLocation()
		local targetPosition = UDim2.new(0, mouseLocation.X + HOVER_OFFSET.X, 0, mouseLocation.Y + HOVER_OFFSET.Y)
		TweenService:Create(hoverFrame, TWEEN_INFO, {Position = targetPosition}):Play()
	end
end

local function showUnlockButton()
	unlockButton.Visible = true
	equipButton.Visible = false
end

local function showEquipButton()
	unlockButton.Visible = false
	equipButton.Visible = true
end

local function resetUnlockButton()
	unlockButton.BackgroundColor3 = BUTTON_COLORS.UNLOCK
	unlockButton.Text = "Unlock"
end

local function setUnlockButtonState(state, message)
	if state == "error" then
		unlockButton.BackgroundColor3 = BUTTON_COLORS.ERROR
		unlockButton.Text = message or "Error"
		showUnlockButton()
	elseif state == "equip" then
		unlockButton.BackgroundColor3 = BUTTON_COLORS.EQUIP
		unlockButton.Text = "Equip"
		showEquipButton()
	else
		resetUnlockButton()
		showUnlockButton()
	end
end

local function equipSkill(slot, skillName)
	if not slot or not skillName then return end
	equipSkillEvent:FireServer(true, slot, skillName)
	if equipSound then
		equipSound:Play()
	end
end

local function unequipSkill(slot)
	if not slot then return end
	equipSkillEvent:FireServer(false, slot)
end

local function handleEquipRequest(skillName)
	local freeSlot = getFreeSkillSlot()
	if freeSlot then
		equipSkill(freeSlot, skillName)
	else
		NewsModule.NewMessage("No available skill slot!", 2)
	end
end

local function handleUnlockRequest()
	if not selectedSkillName or isUnlocking then return end
	isUnlocking = true

	local plrSouls = playerData:WaitForChild("Souls")
	local skill = skillsInfo[selectedSkillName]

	if not skill then
		NewsModule.NewMessage("Skill data not found!", 2)
		isUnlocking = false
		return
	end

	if plrSouls.Value < skill.SoulsCost then
		setUnlockButtonState("error", "Not enough Souls!")
		task.delay(ERROR_DISPLAY_TIME, function()
			if unlockButton and unlockButton.Parent then
				resetUnlockButton()
				showUnlockButton()
			end
		end)
		isUnlocking = false
		return
	end

	local success, message = UnlockSkillEvent:InvokeServer(selectedSkillName)

	if success and message then
		if unlockSound then
			unlockSound:Play()
		end

		setUnlockButtonState("equip")

		-- Remove previous connection if exists
		if connections.equipButtonClick then
			connections.equipButtonClick:Disconnect()
			connections.equipButtonClick = nil
		end

		connections.equipButtonClick = equipButton.MouseButton1Click:Connect(function()
			handleEquipRequest(selectedSkillName)
		end)
	else
		setUnlockButtonState("error")
		task.delay(ERROR_DISPLAY_TIME, function()
			if unlockButton and unlockButton.Parent then
				resetUnlockButton()
				showUnlockButton()
			end
		end)
	end
	NewsModule.NewMessage(message or "Unknown error occurred", 2)
	isUnlocking = false
end

local function updateHoverFrameContent(skillName)
	local skillData = skillsInfo[skillName]
	if not skillData then return end

	hoverFrame.SkillName.Text = skillName
	hoverFrame.Class.Text = "Class: " .. (skillData.Class or "Any")
	hoverFrame.Weapons.Text = "Weapons: " .. (skillData.Weapons or "Any")
	hoverFrame.Cooldown.Text = "Cooldown: " .. (skillData.Cooldown or 0) .. "s"
	hoverFrame.Duration.Text = "Duration: " .. (skillData.Duration or "N/A") .. "s"
	hoverFrame.Weight.Text = "Weight: " .. (skillData.Weight or "N/A")
	hoverFrame.IsPassive.Visible = skillData.IsPassive or false
	hoverFrame.Description.Text = skillData.Description or "No description available"

	local skillUnlocked = unlockedSkills:FindFirstChild(skillName)
	local isUnlocked = skillUnlocked and skillUnlocked.Value

	if isUnlocked then
		showEquipButton()
		unlockButton.Text = "Equip"
		unlockButton.BackgroundColor3 = BUTTON_COLORS.EQUIP
	else
		showUnlockButton()
		unlockButton.Text = "Unlock"
		unlockButton.BackgroundColor3 = BUTTON_COLORS.UNLOCK
	end
end

local function configureSkillButtonEvents(skillButton)
	local skillName = skillButton.Name

	-- Cleanup existing connections if they exist
	if connections[skillName] then
		for _, connection in pairs(connections[skillName]) do
			connection:Disconnect()
		end
	end

	connections[skillName] = {}

	connections[skillName].mouseEnter = skillButton.MouseEnter:Connect(function()
		if not isHoverLocked then
			updateHoverFrameContent(skillName)
			hoverFrame.Visible = true
			if hoverSound then
				hoverSound:Play()
			end
		end
	end)

	connections[skillName].mouseLeave = skillButton.MouseLeave:Connect(function()
		if not isHoverLocked then
			hoverFrame.Visible = false
		end
	end)

	connections[skillName].mouseClick = skillButton.MouseButton1Click:Connect(function()
		isHoverLocked = not isHoverLocked
		selectedSkillName = skillName
		hoverFrame.Visible = isHoverLocked

		if isHoverLocked then
			updateHoverFrameContent(skillName)

			local skillUnlocked = unlockedSkills:FindFirstChild(skillName)
			local isUnlocked = skillUnlocked and skillUnlocked.Value

			-- Remove previous connection if exists
			if connections.equipButtonClick then
				connections.equipButtonClick:Disconnect()
				connections.equipButtonClick = nil
			end

			if isUnlocked then
				connections.equipButtonClick = equipButton.MouseButton1Click:Connect(function()
					handleEquipRequest(skillName)
				end)
			else
				connections.unlockButtonClick = unlockButton.MouseButton1Click:Connect(handleUnlockRequest)
			end
		end
	end)
end

local function setupSkillSlots()
	for _, skill in ipairs(playerSkills:GetChildren()) do
		if not skill:IsA("StringValue") then continue end

		local skillSlot = skillsFrame:FindFirstChild(skill.Name)
		local equippedSkillSlot = plrSkills:FindFirstChild(skill.Name)

		if skillSlot and equippedSkillSlot then
			local function updateSlot()
				local skillName = skill.Value
				skillSlot.SkillName.Text = skillName
				skillSlot.Visible = skillName ~= ""
				equippedSkillSlot.SkillName.Text = skillName
			end

			updateSlot()

			-- Track connections
			connections["slot_" .. skill.Name] = skill:GetPropertyChangedSignal("Value"):Connect(updateSlot)

			-- Replace existing connection if it exists
			if connections["slotClick_" .. skill.Name] then
				connections["slotClick_" .. skill.Name]:Disconnect()
			end

			connections["slotClick_" .. skill.Name] = equippedSkillSlot.MouseButton1Click:Connect(function()
				unequipSkill(skill.Name)
			end)
		end
	end
end

local function setupDraggingLogic()
	if connections.dragBegin then connections.dragBegin:Disconnect() end
	if connections.dragChange then connections.dragChange:Disconnect() end
	if connections.dragEnd then connections.dragEnd:Disconnect() end

	connections.dragBegin = skillsTree.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = true
			hoverFrame.Visible = false
			isHoverLocked = false
			lastMousePosition = input.Position
		end
	end)

	connections.dragChange = skillsTree.InputChanged:Connect(function(input)
		if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - lastMousePosition
			skillsTree.CanvasPosition = skillsTree.CanvasPosition - Vector2.new(delta.X, delta.Y)
			lastMousePosition = input.Position
		end
	end)

	connections.dragEnd = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			isDragging = false
		end
	end)
end

local function centerTree()
	skillsTree.CanvasPosition = Vector2.new(
		math.max((skillsTree.CanvasSize.X.Offset - skillsTree.AbsoluteSize.X) * 0.5, 0),
		math.max((skillsTree.CanvasSize.Y.Offset - skillsTree.AbsoluteSize.Y) * 0.5, 0)
	)
end

function Skills.Start()
	-- Initialize default button states
	unlockButton.Visible = false
	equipButton.Visible = false
	hoverFrame.Visible = false

	-- Setup input events
	if connections.inputChanged then connections.inputChanged:Disconnect() end
	connections.inputChanged = UserInputService.InputChanged:Connect(updateHoverFramePosition)

	-- Setup dragging
	setupDraggingLogic()

	-- Center skill tree
	centerTree()

	local plrHeritage = playerData:WaitForChild("Heritage")
	if plrHeritage.Value ~= "none" then
		skillsTree:WaitForChild("Initial").Image = godsInfo[plrHeritage.Value].icon
	else
		skillsTree:WaitForChild("Initial").Image = "rbxassetid://90292565597637"
	end


	if plrClassPath.Value ~= "" then
		local opts = {
			SkillsInfo = skillsInfo,
			ChosenPath = plrClassPath.Value,
			Canvas = skillsTree,
			NodeTemplate = skillsTree:WaitForChild("NodeTemplate"),
		}
		SkillTree.Build(opts)
		skillsTree:WaitForChild("GuidanceText").Visible = false
	else
		skillsTree:WaitForChild("GuidanceText").Visible = true
	end
	
	plrClassPath.Changed:Connect(function()
		if plrClassPath.Value ~= "" then
			local opts = {
				SkillsInfo = skillsInfo,
				ChosenPath = plrClassPath.Value,
				Canvas = skillsTree,
				NodeTemplate = skillsTree:WaitForChild("NodeTemplate"),
			}
			SkillTree.Build(opts)
			skillsTree:WaitForChild("GuidanceText").Visible = false
		else
			skillsTree:WaitForChild("GuidanceText").Visible = true
		end
	end)

	-- Initialize all skill buttons
	for _, skillButton in ipairs(skillsTree:GetChildren()) do
		if skillButton:IsA("TextButton") then
			configureSkillButtonEvents(skillButton)
		end
	end

	-- Setup button events
	if connections.unlockButtonMain then connections.unlockButtonMain:Disconnect() end
	connections.unlockButtonMain = unlockButton.MouseButton1Click:Connect(handleUnlockRequest)

	if connections.closeButton then connections.closeButton:Disconnect() end
	connections.closeButton = closeButton.MouseButton1Click:Connect(function()
		isHoverLocked = false
		hoverFrame.Visible = false
		TweenService:Create(hoverFrame, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 1.6, 0)}):Play()
		selectedSkillName = nil
		resetUnlockButton()
		unlockButton.Visible = false
		equipButton.Visible = false
	end)

	-- Setup skill slots
	setupSkillSlots()

	return Skills
end

return Skills