local Players = game:GetService("Players")
local USI = game:GetService("UserInputService")
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- Require the camera module
local CameraService = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("SimpleCameraService"))

-- Camera mode toggles
local onCombatCamera = false
local onThirdPersonVariant = false
local debounce = false

-- Icons
local combatModeIcon = "rbxassetid://118550262807270"
local defaultIcon = "rbxasset://SystemCursors/Arrow"

local function resetCameraView()
	CameraService:ClearLockOn()
	CameraService:LockCameraPanning(false, false)
	CameraService:SetCameraView("ThirdPerson")
	CameraService:SetCameraHost()
	USI.MouseIconEnabled = true
	USI.MouseIcon = defaultIcon
	onCombatCamera = false
	onThirdPersonVariant = false
	char:SetAttribute("ShiftLock", false)
end

local function toggleCombatCamera()
	if debounce then return end
	debounce = true

	-- If third person variant is on, turn it off first
	if onThirdPersonVariant then
		onThirdPersonVariant = false
	end

	onCombatCamera = not onCombatCamera

	if onCombatCamera then
		CameraService:SetCameraView("ShiftLock")
		char:SetAttribute("ShiftLock", true)
		USI.MouseIconEnabled = true
		USI.MouseIcon = combatModeIcon
	else
		-- Reset to default when turning off combat camera
		resetCameraView()
	end

	task.wait(0.2)
	debounce = false
end

local function toggleThirdPersonVariant()
	if debounce then return end
	debounce = true

	-- If combat camera is on, turn it off first
	if onCombatCamera then
		onCombatCamera = false
	end

	onThirdPersonVariant = not onThirdPersonVariant

	if onThirdPersonVariant then
		CameraService:SetCameraView("ThirdPersonVariant")
		USI.MouseIconEnabled = false
		char:SetAttribute("ShiftLock", false)
	else
		-- Reset to default when turning off third person variant
		resetCameraView()
	end

	task.wait(0.2)
	debounce = false
end

-- Input handling
USI.InputBegan:Connect(function(input, isTyping)
	if isTyping then return end

	if input.KeyCode == Enum.KeyCode.LeftAlt then
		toggleCombatCamera()
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		toggleThirdPersonVariant()
	elseif input.KeyCode == Enum.KeyCode.G then
		-- Check if already locked on
		if CameraService.IsLockedOn then
			CameraService:ClearLockOn()
		else
			-- Find and lock onto the closest target
			CameraService:FindClosestTarget()
		end
	elseif input.KeyCode == Enum.KeyCode.V and CameraService.IsLockedOn then
		-- Cycle between available targets
		CameraService:CycleTargets()
	end
end)

-- Handle player character changes
player.CharacterAdded:Connect(function(newChar)
	char = newChar
	resetCameraView()
	char:WaitForChild("Humanoid").Died:Connect(function()
		task.wait(3)
		resetCameraView()
	end)
end)

char.AttributeChanged:Connect(function(attribute)
	if attribute == "CombatMode" then
		if char:GetAttribute("CombatMode") then
			CameraService:SetHeadTrackingEnabled(false)
		else
			CameraService:SetHeadTrackingEnabled(true)
		end
	elseif attribute == "Consuming" then
		if char:GetAttribute("Consuming") then
			CameraService:SetHeadTrackingEnabled(false)
		else
			CameraService:SetHeadTrackingEnabled(true)
		end
	elseif char:GetAttribute("Ragdolled") or char:GetAttribute("Fallen") then
		CameraService:SetHeadTrackingEnabled(false)
	else
		CameraService:SetHeadTrackingEnabled(true)
	end
end)

-- Initialize view
resetCameraView()

if char:FindFirstChild("Humanoid") then
	char.Humanoid.Died:Connect(function()
		task.wait(3)
		resetCameraView()
	end)
end