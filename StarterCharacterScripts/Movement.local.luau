local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

task.wait(1)

local MovementRequest = RS:WaitForChild("RE"):WaitForChild("Movement"):WaitForChild("MovementRequest")

local attributeManager = require(RS:WaitForChild("Modules"):WaitForChild("AttributeManager"))
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local HumRootPart = char:WaitForChild("HumanoidRootPart")
local animator = hum:WaitForChild("Animator")
local camera = workspace.CurrentCamera

-- Sound references
local miscSounds = game:GetService("SoundService"):WaitForChild("Misc")

-- Animation references
local movementFolder = RS:WaitForChild("Animations"):WaitForChild("Movement")

-- Animation preloading
local Anims = {
	runAnim = animator:LoadAnimation(movementFolder:WaitForChild("Run")),
	wAnim = animator:LoadAnimation(movementFolder:WaitForChild("WDash")),
}

-- Tween configurations
local TI = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Movement state tracking
local lastWTime = tick()
local running = false
local sprinting = false
local sprintCooldown = false
local movementKeys = {}

-- Configuration settings
local DefaultFOV = 70
local RunFOV = 80
local SprintFOV = 85
local DefaultSpeed = 12
local RunSpeed = 22
local SprintSpeed = 50
local SprintDuration = 0.4
local SprintCooldownTime = 0.15
local SprintStaminaCost = 25

local runConnection
local currentSpeedTweenConn
local currentFOVTween -- Add FOV tween tracking

-- Utility functions
local function validateState()
	local stamina = char:GetAttribute("Stamina") or 0

	if
		char:GetAttribute("Stunned")
		or char:GetAttribute("Ragdolled")
		or char:GetAttribute("Blocking")
		or char:GetAttribute("Attacking")
		or char:GetAttribute("Dead")
		or char:GetAttribute("Knocked")
		or char:GetAttribute("Fallen")
		or char:GetAttribute("Chatting")
		or char:GetAttribute("Resting")
	then
		return false, false
	else
		local canSprint = stamina >= SprintStaminaCost and not sprintCooldown
		return true, canSprint
	end
end

local function isMoving()
	return next(movementKeys) ~= nil
end

local function playSound(soundName)
	local sound = miscSounds:FindFirstChild(soundName)
	if sound then
		local soundClone = sound:Clone()
		soundClone.Parent = char
		soundClone:Play()
		Debris:AddItem(soundClone, soundClone.TimeLength)
	end
end

local function Lerp(a, b, alpha)
	return a + (b - a) * alpha
end

-- Enhanced FOV transition function
local function TransitionFOV(targetFOV)
	-- Stop any existing FOV tween
	if currentFOVTween then
		currentFOVTween:Cancel()
		currentFOVTween = nil
	end

	-- Only create new tween if FOV is different
	if math.abs(camera.FieldOfView - targetFOV) > 0.1 then
		currentFOVTween = TS:Create(camera, TI, { FieldOfView = targetFOV })
		currentFOVTween:Play()

		-- Clear reference when tween completes
		currentFOVTween.Completed:Connect(function()
			currentFOVTween = nil
		end)
	end
end

local function SmoothWalkSpeedTransition(humanoid, targetSpeed, duration)
	if currentSpeedTweenConn then
		currentSpeedTweenConn:Disconnect()
	end

	local startSpeed = humanoid.WalkSpeed
	local elapsed = 0

	currentSpeedTweenConn = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		local alpha = math.clamp(elapsed / duration, 0, 1)

		humanoid.WalkSpeed = Lerp(startSpeed, targetSpeed, alpha)

		if alpha >= 1 then
			humanoid.WalkSpeed = targetSpeed
			currentSpeedTweenConn:Disconnect()
			currentSpeedTweenConn = nil
		end
	end)
end

local function StopSprint()
	--if currentSpeedTweenConn then
	--	currentSpeedTweenConn:Disconnect()
	--	currentSpeedTweenConn = nil
	--end

	sprinting = false

	-- Stop sprint animation with smooth fade
	Anims.wAnim:Stop(0.5)

	if running then
		SmoothWalkSpeedTransition(hum, RunSpeed, 0.3)
		-- Properly transition FOV back to run FOV
		TransitionFOV(RunFOV)

		-- Resume run animation with smooth transition
		Anims.runAnim:Play(0.2, 1, 1) -- Smooth fade in with proper weight
	else
		-- Not running anymore, go back to default
		TransitionFOV(DefaultFOV)
	end

	--MovementRequest:FireServer("Sprint", false)

	-- Start cooldown
	sprintCooldown = true
	task.spawn(function()
		task.wait(SprintCooldownTime)
		sprintCooldown = false
	end)
end

local function StartSprint()
	local canMove, canSprint = validateState()
	if not canMove or not canSprint or not isMoving() then
		return
	end
	-- Cancel any existing speed tween
	if currentSpeedTweenConn then
		currentSpeedTweenConn:Disconnect()
		currentSpeedTweenConn = nil
	end

	sprinting = true
	-- Immediately set sprint speed
	hum.WalkSpeed = SprintSpeed

	-- Stop run animation with quick fade and play sprint animation
	Anims.runAnim:Stop(0.2) 
	Anims.wAnim:Play(0.15, 2, 1)
	playSound("Sprint")

	-- FOV change for sprint
	TransitionFOV(SprintFOV)

	MovementRequest:FireServer("Sprint", true)

	-- Auto-stop sprint after duration
	task.spawn(function()
		task.wait(SprintDuration)
		if sprinting then
			StopSprint()
		end
	end)
end

local function StopRun()
	if runConnection then
		runConnection:Disconnect()
		runConnection = nil
	end

	if sprinting then
		StopSprint()
	end

	running = false

	-- Stop all animations with smooth fade
	Anims.runAnim:Stop(0.2)
	Anims.wAnim:Stop(0.5)

	hum.WalkSpeed = DefaultSpeed
	TransitionFOV(DefaultFOV)
	attributeManager.applyAttributes(char) -- Restore attribute-based speed
end

local function StartRun()
	local canMove, hasStamina = validateState()
	if not canMove or not isMoving() or not hasStamina then 
		hum.WalkSpeed = DefaultSpeed
		return 
	end

	if runConnection then
		runConnection:Disconnect()
	end

	running = true

	-- Set initial running speed
	hum.WalkSpeed = RunSpeed

	-- Start run animation immediately with smooth fade
	if not sprinting then
		Anims.runAnim:Play(0.2, 1, 1) -- Smooth fade in with proper weight
	end

	-- Transition to run FOV if not sprinting
	if not sprinting then
		TransitionFOV(RunFOV)
	end

	-- Start run loop
	runConnection = RunService.Heartbeat:Connect(function()
		local canMove, _ = validateState()
		local stamina = char:GetAttribute("Stamina") or 0

		-- Stop running if out of stamina, can't move, or no movement keys pressed
		if not canMove or (stamina <= 0 and not sprinting) or not isMoving() then
			StopRun()
			return
		end

		-- Set speed based on current state (only if not tweening)
		if not sprinting and not currentSpeedTweenConn then
			hum.WalkSpeed = RunSpeed
		end

		-- Handle animation - ensure smooth continuation
		if not sprinting then
			if not Anims.runAnim.IsPlaying then
				Anims.runAnim:Play(0.2, 1, 1) -- Quick fade in if animation stopped
			end
		end
	end)
end

-- Context Action handlers
local function handleMovement(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then
		-- Update movement keys tracking
		if
			inputObject.KeyCode == Enum.KeyCode.W
			or inputObject.KeyCode == Enum.KeyCode.A
			or inputObject.KeyCode == Enum.KeyCode.S
			or inputObject.KeyCode == Enum.KeyCode.D
		then
			movementKeys[inputObject.KeyCode] = nil

			-- Stop running if no movement keys are pressed
			if not isMoving() then
				StopRun()
			end
		end
	elseif inputState == Enum.UserInputState.Begin then
		-- Track movement keys
		if
			inputObject.KeyCode == Enum.KeyCode.W
			or inputObject.KeyCode == Enum.KeyCode.A
			or inputObject.KeyCode == Enum.KeyCode.S
			or inputObject.KeyCode == Enum.KeyCode.D
		then
			movementKeys[inputObject.KeyCode] = true
		end
	end

	return Enum.ContextActionResult.Pass
end

local function handleSprintRun(actionName, inputState, inputObject)
	if inputState == Enum.UserInputState.End then
		-- When Shift is released, only stop sprint if sprinting
		if sprinting then
			StopSprint()
		end
		-- Don't stop running when shift is released - only when movement keys are released
	elseif inputState == Enum.UserInputState.Begin then
		local canMove, canSprint = validateState()
		if not canMove or not isMoving() then
			return Enum.ContextActionResult.Sink
		end

		-- If already running, try to sprint
		if running then
			if canSprint and not sprinting then
				StartSprint()
			end
			return Enum.ContextActionResult.Sink
		else
			-- Sprint first, then start running
			if canSprint and not sprinting then
				StartSprint()
				task.wait(0.3)
			end
			-- Not running, start running
			StartRun()
		end
	end

	return Enum.ContextActionResult.Sink
end

repeat
	task.wait(1)
until char and char:GetAttribute("Stamina")

-- Bind context actions
CAS:BindAction("Movement", handleMovement, false, 
	Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)

CAS:BindAction("SprintRun", handleSprintRun, false, Enum.KeyCode.LeftShift)

-- Handle attribute changes
char.AttributeChanged:Connect(function()
	attributeManager.applyAttributes(char)
end)
