local BlinkClient = {}
local RS = game.ReplicatedStorage
local UseSkill = RS.RE.Others.UseSkill
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

-- Animation setup
local animsFolder = RS:WaitForChild("Animations"):WaitForChild("Movement")
local DashAnimations = {
	["W"] = animsFolder:WaitForChild("WDash"),
	["S"] = animsFolder:WaitForChild("SDash"),
	["A"] = animsFolder:WaitForChild("ADash"),
	["D"] = animsFolder:WaitForChild("DDash"),
}

-- Constants for Blink skill
local BLINK_SPEED = 100 -- Will be used to set walkspeed
local DASH_TIME = 0.5
local DEFAULT_WALKSPEED = 16 -- Default Roblox walkspeed

local isDashing = false
local currentDashThread = nil
local zoomFOV = 90
local defaultFOV = 70
local duration = 2
local currentAnimation = nil
local originalWalkSpeed = DEFAULT_WALKSPEED
local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Track which direction keys are being pressed
local directionKeys = {
	[Enum.KeyCode.W] = false,
	[Enum.KeyCode.A] = false,
	[Enum.KeyCode.S] = false,
	[Enum.KeyCode.D] = false,
}

-- Setup input detection
local function setupInputDetection()
	UIS.InputBegan:Connect(function(input)
		if
			input.KeyCode == Enum.KeyCode.W
			or input.KeyCode == Enum.KeyCode.A
			or input.KeyCode == Enum.KeyCode.S
			or input.KeyCode == Enum.KeyCode.D
		then
			directionKeys[input.KeyCode] = true
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if directionKeys[input.KeyCode] ~= nil then
			directionKeys[input.KeyCode] = false
		end
	end)
end

-- Get current direction based on key presses
local function getCurrentDirection()
	if directionKeys[Enum.KeyCode.W] then
		return "W"
	elseif directionKeys[Enum.KeyCode.S] then
		return "S"
	elseif directionKeys[Enum.KeyCode.A] then
		return "A"
	elseif directionKeys[Enum.KeyCode.D] then
		return "D"
	end
	return "W" -- Default
end

-- Set movement direction based on camera and controls
local function setMovementDirection(key)
	if Character:GetAttribute("ShiftLock") then
		local forward = Camera.CFrame.LookVector
		local right = Camera.CFrame.RightVector

		-- Calculate face direction based on key
		local faceDirection = forward
		if key == "S" then
			faceDirection = -forward
		elseif key == "A" then
			faceDirection = -right
		elseif key == "D" then
			faceDirection = right
		end

		-- Set look direction - convert to angle only on XZ plane
		local lookVector = Vector3.new(faceDirection.X, 0, faceDirection.Z).Unit
		local angle = math.atan2(lookVector.X, lookVector.Z)
		HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position) * CFrame.Angles(0, angle, 0)
	end
end

function BlinkClient.Activate()
	-- Cancel current dash if active
	if isDashing then
		isDashing = false
		if currentDashThread then
			task.cancel(currentDashThread)
			currentDashThread = nil
		end
		if currentAnimation then
			currentAnimation:Stop()
		end
		Humanoid.WalkSpeed = originalWalkSpeed
	end

	isDashing = true
	originalWalkSpeed = Humanoid.WalkSpeed

	-- Start FOV tween
	TweenService:Create(Camera, info, { FieldOfView = zoomFOV }):Play()

	-- Get direction key
	local key = "W"
	if Character:GetAttribute("ShiftLock") then
		key = getCurrentDirection()
	end

	-- Play new dash animation
	currentAnimation = Humanoid:LoadAnimation(DashAnimations[key])
	currentAnimation:AdjustSpeed(key == "W" and 0.9 or 1.2)
	currentAnimation:Play()

	-- Set facing direction based on key
	setMovementDirection(key)

	local forward = Camera.CFrame.LookVector
	UseSkill:FireServer("Blink", forward)

	local function handleDashMovement()
		local startTime = tick()

		-- Increase walkspeed for dash
		Humanoid.WalkSpeed = BLINK_SPEED

		-- Force movement direction by setting Humanoid's MoveDirection
		local moveDir = Vector3.zero
		if Character:GetAttribute("ShiftLock") then
			if key == "W" then
				moveDir = Camera.CFrame.LookVector
			elseif key == "S" then
				moveDir = -Camera.CFrame.LookVector
			elseif key == "D" then
				moveDir = Camera.CFrame.RightVector
			elseif key == "A" then
				moveDir = -Camera.CFrame.RightVector
			end
		else
			moveDir = HumanoidRootPart.CFrame.LookVector
		end

		-- Remove Y component to keep movement on XZ plane
		moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit

		-- Apply movement for dash duration
		while isDashing and tick() - startTime < DASH_TIME do
			-- Set Humanoid's MoveDirection for consistent movement
			Humanoid:Move(moveDir)
			task.wait(0.01)
		end

		-- Clean up after dash ends
		isDashing = false
		Humanoid.WalkSpeed = originalWalkSpeed
		if currentAnimation then
			currentAnimation:Stop()
		end

		-- Reset FOV
		task.delay(duration - (tick() - startTime), function()
			TweenService:Create(Camera, info, { FieldOfView = defaultFOV }):Play()
		end)
	end

	currentDashThread = task.spawn(handleDashMovement)
end

-- Initialize input detection
setupInputDetection()

return BlinkClient
