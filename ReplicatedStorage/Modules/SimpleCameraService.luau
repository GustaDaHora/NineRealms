--[[
	SimpleCameraService - Advanced Camera System for Roblox
	
	A comprehensive camera system supporting multiple view modes, lock-on targeting,
	camera shake effects, and smooth transitions.
	
	OPTIMIZED FOR: First-person gameplay with smooth lock-on transitions
	
	@version 2.1
	@author Refactored with smoothing improvements
]]

--==============================================================================
-- SERVICES
--==============================================================================

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--==============================================================================
-- CONSTANTS
--==============================================================================

local CONSTANTS = {
	-- Lock-on system
	LOCK_ON_RANGE = 30,
	LOCK_ON_CAMERA_Y_OFFSET = 3,
	LOCK_ON_TARGET_Y_OFFSET = -5,
	LOCK_ON_LERP_FACTOR = 0.15,
	LOCK_ON_ROTATION_LERP_FACTOR = 0.18,
	LOCK_ON_TRANSITION_TIME = 0.3,
	TARGET_UPDATE_INTERVAL = 0.3,

	-- Camera positioning
	DEFAULT_CAMERA_HEIGHT = 2.5,
	TORSO_CAMERA_OFFSET = Vector3.new(0, 1.3, 0),

	-- Input sensitivity
	ARROW_KEY_ROTATION_SPEED = 0.05,
	MOBILE_SENSITIVITY_DIVISOR = 27,
	DESKTOP_SENSITIVITY_DIVISOR = 60,
	GAMEPAD_DEADZONE = 0.2 / 15,

	-- Smoothing (adaptive based on camera mode)
	ROTATION_SMOOTHING_FPS = 0.8, -- Very responsive for FPS
	ROTATION_SMOOTHING_TPS = 0.8, -- Smoother for third person
	ROTATION_SMOOTHING_LOCKON = 0.35, -- Smoothest for lock-on
	ZOOM_SMOOTHING = 0.18,
	ARROW_KEY_SMOOTHING = 0.8,
	INPUT_DAMPING_FPS = 0.9, -- Light damping for FPS
	INPUT_DAMPING_TPS = 0.9, -- More damping for third person

	-- Zoom
	ZOOM_STEP_DIVISOR = 4,

	-- Camera collision
	COLLISION_SAFETY_FACTOR = 0.9,
	COLLISION_NON_PART_FACTOR = 0.95,

	-- Shake
	SHAKE_FEEDBACK_INTENSITY = 0.2,
	SHAKE_FEEDBACK_DURATION = 0.2,
	SHAKE_CYCLE_FEEDBACK_INTENSITY = 0.1,
	SHAKE_CYCLE_FEEDBACK_DURATION = 0.1,

	-- Misc
	SAFE_WAIT_TIMEOUT = 5,
	CHARACTER_LOAD_DELAY = 0.2,
	ANGLE_CLAMP_MAX = 89,

	WALK_SWAY_ENABLED = true,
	WALK_SWAY_AMPLITUDE = 0.06, -- How much the camera sways
	WALK_SWAY_FREQUENCY = 5, -- How fast the sway cycles
	WALK_SWAY_VERTICAL_MULT = 0.6, -- Vertical sway multiplier
	WALK_SWAY_ROLL_MULT = 0.3, -- Camera roll/tilt multiplier
	WALK_SWAY_SMOOTHING = 0.12, -- How smoothly sway transitions
	WALK_SPEED_THRESHOLD = 0.5, -- Minimum speed to trigger sway
	SPRINT_SWAY_MULTIPLIER = 1.1, -- Sway increase when sprinting
	TORSO_ANIMATION_DAMPING = 0.5, -- How much to reduce torso animation influence (0.1 = 10%, 0.5 = 50%)

	-- Head tracking (ThirdPersonVariant - R6 only)
	HEAD_TRACKING_ENABLED = true,
	HEAD_HORIZONTAL_LIMIT = 70, -- degrees
	HEAD_VERTICAL_LIMIT = 50, -- degrees
	HEAD_ROTATION_SMOOTHING = 0.2, -- Similar to TPS camera smoothing
	HEAD_DISABLE_WHEN_RUNNING = true, -- Disable when WalkSpeed > 13
	HEAD_RUN_SPEED_THRESHOLD = 13, -- Speed threshold to disable tracking

	-- Axis configuration (found through testing)
	HEAD_YAW_MULT = -1, -- Horizontal rotation multiplier
	HEAD_PITCH_MULT = -1, -- Vertical rotation multiplier
	HEAD_YAW_AXIS = 2, -- Yaw on Z-axis (roll) for R6
	HEAD_PITCH_AXIS = 0, -- Pitch on X-axis for R6
}

local ZERO_VECTOR3 = Vector3.zero
local UP_VECTOR = Vector3.new(0, 1, 0)

--==============================================================================
-- PLAYER & CAMERA OBJECTS
--==============================================================================

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera or workspace:WaitForChild("Camera")

--==============================================================================
-- STATE VARIABLES
--==============================================================================

-- Camera state
local currentCamPosition = ZERO_VECTOR3
local cameraRotation = Vector2.zero
local currentCharacter = player.Character or player.CharacterAdded:Wait()
local cameraOffset = ZERO_VECTOR3
local updateShakeCounter = 0
local differenceVector = Vector2.zero
local arrowKeyAngle = 0
local isRespawning = false

-- Smoothing state
local targetCameraRotation = Vector2.zero
local currentSmoothedRotation = Vector2.zero
local targetZoom = 10
local currentZoom = 10
local targetArrowKeyAngle = 0
local inputVelocity = Vector2.zero
local lastFrameTime = tick()

-- Lock-on state
local isLockedOn = false
local lockedTarget = nil
local potentialTargets = {}
local currentTargetIndex = 0
local lastTargetUpdate = 0
local lockOnTransitioning = false
local lockOnStartTime = 0
local preLockOnRotation = Vector2.zero

-- Walk sway state
local walkSwayTime = 0
local currentSwayIntensity = 0
local targetSwayIntensity = 0
local lastVelocity = ZERO_VECTOR3

-- Head tracking state (ThirdPersonVariant - R6 only)
local neckMotor = nil
local originalNeckC0 = nil
local currentHeadRotation = Vector2.zero -- X = yaw, Y = pitch
local targetHeadRotation = Vector2.zero

-- Connections
local activeConnections = {}

--==============================================================================
-- CAMERA VIEW PRESETS
--==============================================================================

local cameraPresets = {
	Default = {},

	LockOn = {
		LockMouse = true,
	},

	FirstPerson = {
		CharacterVisibility = "Body",
		Zoom = 0,
		AlignChar = true,
		Offset = CFrame.new(0, 0.75, -1),
		LockMouse = true,
		MinZoom = 0,
		MaxZoom = 0,
	},

	ThirdPerson = {
		CharacterVisibility = "All",
		Zoom = 10,
		AlignChar = false,
		Offset = CFrame.new(0, 0, 0),
		LockMouse = false,
		MinZoom = 5,
		MaxZoom = 30,
	},

	ThirdPersonVariant = {
		CharacterVisibility = "All",
		Zoom = 10,
		AlignChar = false,
		Offset = CFrame.new(0, 0, 0),
		LockMouse = true,
		MinZoom = 5,
		MaxZoom = 20,
	},

	ShiftLock = {
		CharacterVisibility = "All",
		Zoom = 7.5,
		Offset = CFrame.new(1.8, 0.6, 1),
		LockMouse = true,
		AlignChar = true,
		MinZoom = 2,
		MaxZoom = 15,
	},
}

local defaultPropertyTypes = {
	CharacterVisibility = "All",
	Zoom = 10,
	AlignChar = false,
	Offset = CFrame.new(),
	MinZoom = 5,
	MaxZoom = 20,
	LockMouse = false,
}

--==============================================================================
-- UTILITY FUNCTIONS
--==============================================================================

--[[
	Safely waits for a child with timeout and warning.
	
	@param parent Instance - The parent instance
	@param childName string - Name of the child to wait for
	@param timeout number? - Optional timeout in seconds (default: 5)
	@return Instance? - The child instance or nil if not found
]]
local function safeWaitForChild(parent, childName, timeout)
	if not parent then
		warn(`[SimpleCameraService] Cannot wait for child: parent is nil`)
		return nil
	end

	local child = parent:WaitForChild(childName, timeout or CONSTANTS.SAFE_WAIT_TIMEOUT)
	if not child then
		warn(`[SimpleCameraService] Failed to find {childName} in {parent.Name}`)
	end
	return child
end

--[[
	Clears all active connections in the connection list.
]]
local function clearConnections()
	for _, connection in pairs(activeConnections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
	activeConnections = {}
end

--[[
	Adds a connection to the active connections list.
	
	@param connection RBXScriptConnection - The connection to track
]]
local function addConnection(connection)
	table.insert(activeConnections, connection)
end

--[[
	Gets cached character components for performance.
	
	@return Humanoid?, BasePart?, BasePart? - humanoid, rootPart, torso
]]
local function getCachedCharacterParts()
	if not currentCharacter then
		return nil, nil, nil
	end

	local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")
	local torso = currentCharacter:FindFirstChild("Torso")

	return humanoid, rootPart, torso
end

--[[
	Gets the appropriate smoothing factor based on current camera mode.
	
	@return number, number - rotation smoothing, input damping
]]
local function getAdaptiveSmoothingFactors()
	local self = SimpleCameraService

	if isLockedOn then
		return CONSTANTS.ROTATION_SMOOTHING_LOCKON, 0.4
	elseif self.Zoom <= 2 or self.CameraView == "FirstPerson" then
		-- First person or very close: highly responsive
		return CONSTANTS.ROTATION_SMOOTHING_FPS, CONSTANTS.INPUT_DAMPING_FPS
	else
		-- Third person: more smoothing
		return CONSTANTS.ROTATION_SMOOTHING_TPS, CONSTANTS.INPUT_DAMPING_TPS
	end
end

--==============================================================================
-- CAMERA UTILITY FUNCTIONS
--==============================================================================

--[[
	Handles character part visibility for different camera modes.
	
	@param visibilityType string? - "All", "Body", "None", or nil to hide everything
]]
local function setCharacterVisibility(visibilityType)
	if not currentCharacter then
		warn("[SimpleCameraService] Cannot set visibility: no character found")
		return
	end

	local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = not SimpleCameraService.AlignChar
	end

	for _, child in ipairs(currentCharacter:GetChildren()) do
		if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
			-- Handle descendants of body parts
			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") or descendant:IsA("Decal") then
					if visibilityType == "All" then
						descendant.LocalTransparencyModifier = 0
					elseif visibilityType == "Body" then
						descendant.LocalTransparencyModifier = child.Name == "Head" and 1 or 0
					else
						descendant.LocalTransparencyModifier = 1
					end
				end
			end

			-- Handle the body part itself
			if visibilityType == "All" then
				child.LocalTransparencyModifier = 0
			elseif visibilityType == "Body" then
				child.LocalTransparencyModifier = child.Name == "Head" and 1 or 0
			else
				child.LocalTransparencyModifier = 1
			end
		elseif child:IsA("Accessory") then
			local isHeadAccessory = false
			local attachmentName = child:FindFirstChild("Handle") and child.Handle:FindFirstChildOfClass("Attachment")

			if attachmentName then
				local attachmentParent = attachmentName.Name
				isHeadAccessory = attachmentParent:match("Hair")
					or attachmentParent:match("Hat")
					or attachmentParent:match("Face")
					or attachmentParent:match("Head")
			end

			if not isHeadAccessory and child:IsA("Accessory") then
				local accessoryType = child.AccessoryType
				isHeadAccessory = accessoryType == Enum.AccessoryType.Hat
					or accessoryType == Enum.AccessoryType.Hair
					or accessoryType == Enum.AccessoryType.Face
					or accessoryType == Enum.AccessoryType.Eyelash
					or accessoryType == Enum.AccessoryType.Eyebrow
			end

			for _, descendant in ipairs(child:GetDescendants()) do
				if descendant:IsA("BasePart") or descendant:IsA("Decal") then
					if visibilityType == "All" then
						descendant.LocalTransparencyModifier = 0
					elseif visibilityType == "Body" then
						descendant.LocalTransparencyModifier = isHeadAccessory and 1 or 0
					else
						descendant.LocalTransparencyModifier = 1
					end
				end
			end
		end
	end
end

--[[
	Calculates camera shake offset with smooth sine waves.
	
	@param intensity number - Shake intensity
	@return Vector3 - Offset vector for camera shake
]]
local function calculateShakeOffset(intensity, deltaTime)
	local time = tick() * 20
	local shakeOffset = ZERO_VECTOR3
	local shakeRotation = CFrame.new()

	-- Manual shake effect (from Shake() method)
	if intensity > 0 then
		local x = math.sin(time * 2.5) * intensity * 0.5
		local y = math.abs(math.cos(time * 3.1)) * intensity * 0.3
		local z = SimpleCameraService.CharacterVisibility == "All" and math.sin(time * 1.8) * intensity * 0.2 or 0
		shakeOffset = Vector3.new(x, y, z)
	end

	-- Walk sway system
	if CONSTANTS.WALK_SWAY_ENABLED and not isLockedOn then
		local humanoid, rootPart = getCachedCharacterParts()

		if humanoid and rootPart and humanoid.Health > 0 then
			-- Calculate movement speed
			local currentVelocity = rootPart.AssemblyLinearVelocity
			local horizontalVelocity = Vector3.new(currentVelocity.X, 0, currentVelocity.Z)
			local speed = horizontalVelocity.Magnitude

			-- Check if character is grounded
			local isGrounded = humanoid.FloorMaterial ~= Enum.Material.Air

			-- Determine if sprinting (you can adjust this based on your game's sprint system)
			local isSprinting = speed > 16 and humanoid.WalkSpeed > 16
			local sprintMult = isSprinting and CONSTANTS.SPRINT_SWAY_MULTIPLIER or 1

			-- Calculate target sway intensity based on movement
			if speed > CONSTANTS.WALK_SPEED_THRESHOLD and isGrounded then
				-- Normalize speed to 0-1 range (assuming max walk speed ~16)
				local normalizedSpeed = math.min(speed / 16, 1.5)
				targetSwayIntensity = normalizedSpeed * sprintMult
			else
				targetSwayIntensity = 0
			end

			-- Smooth intensity transitions (frame-rate independent)
			local smoothFactor = math.min(1, CONSTANTS.WALK_SWAY_SMOOTHING * deltaTime * 60)
			currentSwayIntensity = currentSwayIntensity + (targetSwayIntensity - currentSwayIntensity) * smoothFactor

			-- Only update sway time when moving
			if currentSwayIntensity > 0.01 then
				walkSwayTime = walkSwayTime + deltaTime * CONSTANTS.WALK_SWAY_FREQUENCY * currentSwayIntensity

				-- Calculate sway using sine waves for smooth motion
				local swayPhase = walkSwayTime

				-- Horizontal sway (left-right) - sine wave
				local horizontalSway = math.sin(swayPhase) * CONSTANTS.WALK_SWAY_AMPLITUDE * currentSwayIntensity

				-- Vertical sway (up-down) - double frequency for realistic bob
				local verticalSway = math.abs(math.sin(swayPhase * 2))
					* CONSTANTS.WALK_SWAY_AMPLITUDE
					* CONSTANTS.WALK_SWAY_VERTICAL_MULT
					* currentSwayIntensity

				-- Forward-back sway - subtle
				local depthSway = math.cos(swayPhase * 2) * CONSTANTS.WALK_SWAY_AMPLITUDE * 0.3 * currentSwayIntensity

				-- Apply sway offset
				local swayOffset = Vector3.new(horizontalSway, verticalSway, depthSway)
				shakeOffset = shakeOffset + swayOffset

				-- Camera roll/tilt (adds personality to the movement)
				local rollAngle = math.sin(swayPhase) * CONSTANTS.WALK_SWAY_ROLL_MULT * currentSwayIntensity
				local pitchAngle = math.sin(swayPhase * 2) * CONSTANTS.WALK_SWAY_ROLL_MULT * 0.5 * currentSwayIntensity

				shakeRotation = CFrame.Angles(math.rad(pitchAngle), 0, math.rad(rollAngle))
			else
				-- Gradually reset sway time when not moving
				walkSwayTime = walkSwayTime * 0.9
			end

			lastVelocity = currentVelocity
		end
	end

	return shakeOffset, shakeRotation
end

--[[
	Performs raycast to prevent camera clipping through walls.
	Uses multiple cast points for more robust collision detection.
	
	@param origin Vector3 - Starting position
	@param direction Vector3 - Direction vector
	@return Vector3 - Adjusted camera position
]]
local function performCameraRaycast(origin, direction)
	local params = RaycastParams.new()
	params.IgnoreWater = true

	local filterInstances = { currentCharacter }
	if
		SimpleCameraService.Host
		and SimpleCameraService.Host.Parent
		and SimpleCameraService.Host.Parent ~= workspace
		and SimpleCameraService.Host.Parent:IsA("Model")
	then
		table.insert(filterInstances, SimpleCameraService.Host.Parent)
	elseif SimpleCameraService.Host then
		table.insert(filterInstances, SimpleCameraService.Host)
	end
	params.FilterDescendantsInstances = filterInstances

	local rayResult = workspace:Raycast(origin, direction, params)

	if rayResult and rayResult.Distance and rayResult.Instance then
		local factor = (rayResult.Instance:IsA("BasePart") or rayResult.Instance:IsA("UnionOperation"))
				and CONSTANTS.COLLISION_SAFETY_FACTOR
			or CONSTANTS.COLLISION_NON_PART_FACTOR

		direction *= (rayResult.Distance * factor / direction.Magnitude)
	end

	return origin + direction
end

--==============================================================================
-- LOCK-ON SYSTEM
--==============================================================================

--[[
	Gathers all potential lock-on targets within range.
	Caches results for performance.
	
	@return boolean - True if targets were found
]]
local function gatherPotentialTargets()
	local now = tick()

	if now - lastTargetUpdate < CONSTANTS.TARGET_UPDATE_INTERVAL and #potentialTargets > 0 then
		return true
	end

	lastTargetUpdate = now
	potentialTargets = {}

	local _, rootPart = getCachedCharacterParts()
	if not rootPart then
		return false
	end

	local playerPosition = rootPart.Position

	-- Gather player targets
	for _, otherPlayer in pairs(Players:GetPlayers()) do
		if
			otherPlayer ~= player
			and otherPlayer.Character
			and otherPlayer.Character:FindFirstChild("HumanoidRootPart")
		then
			local otherHumanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
			if otherHumanoid and otherHumanoid.Health > 0 then
				local otherRootPart = otherPlayer.Character.HumanoidRootPart
				local distance = (playerPosition - otherRootPart.Position).Magnitude

				if distance <= CONSTANTS.LOCK_ON_RANGE then
					table.insert(potentialTargets, {
						hrp = otherRootPart,
						dist = distance,
						type = "player",
						character = otherPlayer.Character,
					})
				end
			end
		end
	end

	-- Gather NPC targets
	local enemyFolder = workspace:FindFirstChild("Alives")
	if enemyFolder then
		enemyFolder = enemyFolder:FindFirstChild("NPCs")
		if enemyFolder then
			enemyFolder = enemyFolder:FindFirstChild("Enemies")
		end
	end

	if enemyFolder then
		for _, model in pairs(enemyFolder:GetDescendants()) do
			if
				model:IsA("Model")
				and model:FindFirstChild("HumanoidRootPart")
				and model:FindFirstChildOfClass("Humanoid")
			then
				local npcHumanoid = model.Humanoid
				if npcHumanoid.Health > 0 then
					local npcRootPart = model.HumanoidRootPart
					local distance = (playerPosition - npcRootPart.Position).Magnitude

					if distance <= CONSTANTS.LOCK_ON_RANGE then
						table.insert(potentialTargets, {
							hrp = npcRootPart,
							dist = distance,
							type = "npc",
							character = model,
						})
					end
				end
			end
		end
	end

	table.sort(potentialTargets, function(a, b)
		return a.dist < b.dist
	end)

	return #potentialTargets > 0
end

--[[
	Updates camera position and character rotation for lock-on mode.
	Uses frame-rate independent smoothing for consistent feel.
]]
local function updateLockOnCamera(deltaTime)
	if not isLockedOn or not lockedTarget or not lockedTarget:IsDescendantOf(workspace) then
		SimpleCameraService:ClearLockOn()
		return
	end

	local _, rootPart = getCachedCharacterParts()
	if not rootPart then
		return
	end

	-- Calculate transition progress
	local transitionProgress = 1
	if lockOnTransitioning then
		local elapsed = tick() - lockOnStartTime
		transitionProgress = math.min(elapsed / CONSTANTS.LOCK_ON_TRANSITION_TIME, 1)
		-- Smooth easing
		transitionProgress = transitionProgress * transitionProgress * (3 - 2 * transitionProgress)

		if transitionProgress >= 1 then
			lockOnTransitioning = false
		end
	end

	-- Calculate positions
	local targetPosition = lockedTarget.Position
	local cameraPosition = rootPart.Position + Vector3.new(0, CONSTANTS.LOCK_ON_CAMERA_Y_OFFSET, 0)

	-- Current and target CFrames
	local currentCFrame = camera.CFrame
	local targetCFrame =
		CFrame.new(cameraPosition, targetPosition + Vector3.new(0, CONSTANTS.LOCK_ON_TARGET_Y_OFFSET, 0))

	-- Frame-rate independent smoothing
	local lerpFactor = math.min(1, CONSTANTS.LOCK_ON_LERP_FACTOR * deltaTime * 60)

	-- During transition, blend between manual and lock-on control
	if lockOnTransitioning then
		-- Blend from current rotation to lock-on
		camera.CFrame = currentCFrame:Lerp(targetCFrame, lerpFactor * transitionProgress)
	else
		camera.CFrame = currentCFrame:Lerp(targetCFrame, lerpFactor)
	end

	-- Rotate character toward target
	local humanoid = getCachedCharacterParts()
	if humanoid then
		local direction =
			Vector3.new(targetPosition.X - rootPart.Position.X, 0, targetPosition.Z - rootPart.Position.Z).Unit

		local currentRotation = rootPart.CFrame
		local targetRotation = CFrame.new(rootPart.Position, rootPart.Position + direction)

		-- Frame-rate independent character rotation
		local rotationLerpFactor = math.min(1, CONSTANTS.LOCK_ON_ROTATION_LERP_FACTOR * deltaTime * 60)
		humanoid.AutoRotate = false
		rootPart.CFrame = currentRotation:Lerp(targetRotation, rotationLerpFactor)
	end
end

--[[
	Gets the screen-space distance from screen center to a 3D position.
	
	@param hrp BasePart - The part to check
	@return number - Distance in pixels, or math.huge if off-screen
]]
local function getScreenSpaceDistance(hrp)
	local screenPos, onScreen = camera:WorldToScreenPoint(hrp.Position)
	if not onScreen then
		return math.huge
	end

	local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local targetScreen = Vector2.new(screenPos.X, screenPos.Y)

	return (screenCenter - targetScreen).Magnitude
end

--[[
	Updates head rotation for ThirdPersonVariant camera mode.
	Smoothly rotates the head to follow camera direction within limits,
	and triggers body rotation when limits are exceeded.
	
	@param deltaTime number - Time since last frame
]]
local function updateHeadTracking(deltaTime)
	if not CONSTANTS.HEAD_TRACKING_ENABLED then
		return
	end

	local self = SimpleCameraService
	if self.CameraView ~= "ThirdPersonVariant" then
		-- Reset head rotation when not in ThirdPersonVariant
		if neckMotor and originalNeckC0 then
			neckMotor.C0 = originalNeckC0
		end
		currentHeadRotation = Vector2.zero
		targetHeadRotation = Vector2.zero
		return
	end

	local humanoid, rootPart, torso = getCachedCharacterParts()
	if not humanoid or not rootPart or not torso then
		return
	end

	-- Disable head tracking when running (if enabled)
	if CONSTANTS.HEAD_DISABLE_WHEN_RUNNING then
		local currentSpeed = rootPart.AssemblyLinearVelocity.Magnitude
		if currentSpeed > CONSTANTS.HEAD_RUN_SPEED_THRESHOLD then
			-- Reset head to neutral position when running
			if neckMotor and originalNeckC0 then
				neckMotor.C0 = neckMotor.C0:Lerp(originalNeckC0, 0.1)
			end
			return
		end
	end

	-- Initialize neck motor if needed
	if not neckMotor then
		neckMotor = torso:FindFirstChild("Neck")
		if neckMotor and neckMotor:IsA("Motor6D") then
			originalNeckC0 = neckMotor.C0
		else
			return
		end
	end

	-- Calculate target head rotation from camera
	local cameraCFrame = camera.CFrame

	-- Use TORSO as reference for head tracking
	local torsoCFrame = torso.CFrame

	-- Get camera look direction as a vector
	local cameraLookVector = cameraCFrame.LookVector

	-- Convert camera look direction to torso's local space
	local relativeDirection = torsoCFrame:VectorToObjectSpace(cameraLookVector)

	-- Calculate yaw (horizontal) and pitch (vertical) angles
	local targetYaw = math.atan2(relativeDirection.X, -relativeDirection.Z)
	local targetPitch = math.asin(math.clamp(relativeDirection.Y, -1, 1))

	-- Apply limits
	local maxYaw = math.rad(CONSTANTS.HEAD_HORIZONTAL_LIMIT)
	local maxPitch = math.rad(CONSTANTS.HEAD_VERTICAL_LIMIT)

	-- Clamp head rotation to limits
	targetYaw = math.clamp(targetYaw, -maxYaw, maxYaw)
	targetPitch = math.clamp(targetPitch, -maxPitch, maxPitch)

	-- Apply multipliers (for testing different directions)
	local adjustedYaw = targetYaw * CONSTANTS.HEAD_YAW_MULT
	local adjustedPitch = targetPitch * CONSTANTS.HEAD_PITCH_MULT

	targetHeadRotation = Vector2.new(adjustedYaw, adjustedPitch)

	-- Smooth head rotation (frame-rate independent)
	local headSmoothFactor = math.min(1, CONSTANTS.HEAD_ROTATION_SMOOTHING * deltaTime * 60)
	currentHeadRotation = currentHeadRotation:Lerp(targetHeadRotation, headSmoothFactor)

	-- Apply rotation to neck Motor6D using configurable axes
	if neckMotor and originalNeckC0 then
		-- Build rotation array based on axis settings
		local rotations = { 0, 0, 0 }
		rotations[CONSTANTS.HEAD_YAW_AXIS + 1] = currentHeadRotation.X -- Yaw on configured axis
		rotations[CONSTANTS.HEAD_PITCH_AXIS + 1] = currentHeadRotation.Y -- Pitch on configured axis

		local rotationCFrame = CFrame.Angles(rotations[1], rotations[2], rotations[3])
		neckMotor.C0 = originalNeckC0 * rotationCFrame
	end
end

--==============================================================================
-- MAIN CAMERA UPDATE
--==============================================================================

--[[
	Main camera update function called every frame.
	Handles both normal and lock-on camera modes with smooth interpolation.
	
	@param deltaTime number - Time since last frame
]]
local function updateCamera(deltaTime)
	local self = SimpleCameraService

	if not self.Host then
		return
	end

	-- Handle lock-on camera separately
	if isLockedOn and lockedTarget then
		updateLockOnCamera(deltaTime)
		return
	end

	-- Handle gamepad input
	if UserInputService.GamepadEnabled then
		cameraRotation -= differenceVector
	end
	differenceVector = Vector2.zero

	-- Get adaptive smoothing factors
	local rotationSmoothing, inputDamping = getAdaptiveSmoothingFactors()

	-- Calculate target rotation with clamping
	targetCameraRotation = Vector2.new(
		self.xLock and self.atX or cameraRotation.X,
		self.yLock and self.atY or math.clamp(cameraRotation.Y, math.rad(-self.Angle), math.rad(self.Angle))
	)

	-- Smooth rotation interpolation (frame-rate independent)
	local rotationSmoothFactor = math.min(1, rotationSmoothing * deltaTime * 60)
	currentSmoothedRotation = currentSmoothedRotation:Lerp(targetCameraRotation, rotationSmoothFactor)

	-- Calculate camera position
	currentCamPosition = self.Host.Position
		+ Vector3.new(0, self.Host.Parent == currentCharacter and CONSTANTS.DEFAULT_CAMERA_HEIGHT or 0, 0)

	if currentCharacter then
		local humanoid, rootPart, torso = getCachedCharacterParts()
		if torso and rootPart then
			local cameraAttachmentOffset = rootPart.CFrame:ToObjectSpace(torso.CFrame).Position
			-- DAMPEN the animation influence instead of using it fully
			cameraAttachmentOffset = cameraAttachmentOffset * CONSTANTS.TORSO_ANIMATION_DAMPING
			currentCamPosition = currentCamPosition + cameraAttachmentOffset
		end
	end

	-- Handle arrow key camera rotation with smoothing
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		targetArrowKeyAngle += CONSTANTS.ARROW_KEY_ROTATION_SPEED
	elseif UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		targetArrowKeyAngle -= CONSTANTS.ARROW_KEY_ROTATION_SPEED
	end

	-- Smooth arrow key angle (frame-rate independent)
	local arrowSmoothFactor = math.min(1, CONSTANTS.ARROW_KEY_SMOOTHING * deltaTime * 60)
	arrowKeyAngle = arrowKeyAngle + (targetArrowKeyAngle - arrowKeyAngle) * arrowSmoothFactor

	-- Smooth zoom interpolation (frame-rate independent)
	local zoomSmoothFactor = math.min(1, CONSTANTS.ZOOM_SMOOTHING * deltaTime * 60)
	currentZoom = currentZoom + (targetZoom - currentZoom) * zoomSmoothFactor
	self.Zoom = currentZoom

	-- Create rotation CFrame using smoothed rotation
	local rotationCFrame =
		CFrame.fromEulerAnglesYXZ(currentSmoothedRotation.Y, currentSmoothedRotation.X - arrowKeyAngle, 0)

	-- Handle camera shake
	updateShakeCounter = updateShakeCounter < math.random(2, 3) and updateShakeCounter + 1 or 0

	cameraOffset = self.Shaking and updateShakeCounter == 0 and calculateShakeOffset(self.ShakingIntensity)
		or ZERO_VECTOR3

	local shakeOffset, shakeRotation
	if self.Shaking and updateShakeCounter == 0 then
		shakeOffset, shakeRotation = calculateShakeOffset(self.ShakingIntensity, deltaTime)
	else
		shakeOffset, shakeRotation = calculateShakeOffset(0, deltaTime)
	end

	-- Calculate camera CFrame
	local camCFrame = (rotationCFrame * self.Offset * self.TiltFactor * shakeRotation)
		+ currentCamPosition
		+ cameraOffset
		+ (rotationCFrame * Vector3.new(0, 0, currentZoom))

	-- Apply raycast collision detection
	local camPos =
		performCameraRaycast(currentCamPosition + cameraOffset, camCFrame.p - cameraOffset - currentCamPosition)
	camCFrame = (camCFrame - camCFrame.p) + camPos

	-- Set camera
	camera.CFrame = camCFrame

	-- Handle character alignment
	if self.Host.Parent == currentCharacter then
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled

		-- Update head tracking for ThirdPersonVariant
		updateHeadTracking(deltaTime)

		local humanoid, rootPart = getCachedCharacterParts()
		if humanoid and humanoid.Health > 0 and rootPart then
			if self.AlignChar and humanoid.FloorMaterial ~= Enum.Material.Water then
				local _, x, _ = camCFrame:ToEulerAnglesYXZ()
				rootPart.CFrame = CFrame.fromEulerAnglesYXZ(0, x + math.rad(self.Offset.X == 0 and 0 or -6), 0)
					+ rootPart.Position
			end
		end
	end
end

--==============================================================================
-- INPUT HANDLING
--==============================================================================

--[[
	Handles camera zoom input from mouse wheel, keyboard, or gamepad.
	
	@param input InputObject - The input object
	@param gameProcessedEvent boolean - Whether the game already processed this input
]]
local function handleZoomInput(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	local self = SimpleCameraService
	local zoomStep = (self.MaxZoom - self.MinZoom) / CONSTANTS.ZOOM_STEP_DIVISOR

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		-- Mouse wheel zoom
		local multiplier = input.Position.Z
		targetZoom = math.clamp(targetZoom - (multiplier * zoomStep), self.MinZoom, self.MaxZoom)
	elseif
		input.UserInputState == Enum.UserInputState.Begin
		and (input.KeyCode == Enum.KeyCode.I or input.KeyCode == Enum.KeyCode.O)
	then
		-- Keyboard zoom (I/O keys)
		local multiplier = input.KeyCode == Enum.KeyCode.I and 1 or -1
		targetZoom = math.clamp(targetZoom - (multiplier * zoomStep), self.MinZoom, self.MaxZoom)
	elseif input.KeyCode == Enum.KeyCode.ButtonR3 and input.UserInputState == Enum.UserInputState.Begin then
		-- Gamepad zoom (R3 button)
		targetZoom = targetZoom - zoomStep < self.MinZoom and self.MaxZoom or targetZoom - zoomStep
	end
end

--[[
	Handles camera rotation input from mouse, touch, or gamepad.
	Uses adaptive smoothing based on camera mode.
	
	@param input InputObject - The input object
	@param gameProcessedEvent boolean - Whether the game already processed this input
]]
local function handleCameraInput(input, gameProcessedEvent)
	handleZoomInput(input, gameProcessedEvent)

	local self = SimpleCameraService
	local rightMouseHeld = self.LockMouse or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	local isMobile = input.UserInputType == Enum.UserInputType.Touch
	local isGamepad = input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.Thumbstick2

	if
		(not gameProcessedEvent or (not isMobile and not isGamepad))
		and (rightMouseHeld or isMobile or isGamepad)
		and input.UserInputState == Enum.UserInputState.Change
	then
		-- Get delta
		local delta = isGamepad and input.Position / 15 * math.sqrt(UserInputService.MouseDeltaSensitivity)
			or input.Delta

		-- Calculate difference vector
		if isGamepad then
			local deadzone = CONSTANTS.GAMEPAD_DEADZONE * math.sqrt(UserInputService.MouseDeltaSensitivity)
			differenceVector = Vector2.new(
				math.abs(delta.X) < deadzone and 0 or delta.X,
				math.abs(delta.Y) < deadzone and 0 or -delta.Y
			)
		else
			local sensitivity = isMobile and CONSTANTS.MOBILE_SENSITIVITY_DIVISOR
				or CONSTANTS.DESKTOP_SENSITIVITY_DIVISOR

			local rawInput = Vector2.new(
				math.sqrt(math.abs(delta.X)) / sensitivity * (delta.X > 0 and 1 or -1),
				math.sqrt(math.abs(delta.Y)) / sensitivity * (delta.Y > 0 and 1 or -1)
			)

			-- Apply adaptive input damping
			local _, inputDamping = getAdaptiveSmoothingFactors()
			inputVelocity = inputVelocity:Lerp(rawInput, inputDamping)
			differenceVector = inputVelocity
		end

		-- Update rotation for non-gamepad
		if not isGamepad then
			cameraRotation -= differenceVector
			cameraRotation = Vector2.new(
				self.xLock and self.atX or cameraRotation.X,
				self.yLock and self.atY or math.clamp(cameraRotation.Y, math.rad(-self.Angle), math.rad(self.Angle))
			)
		end
	end

	-- Update mouse behavior
	UserInputService.MouseBehavior = self.LockMouse and Enum.MouseBehavior.LockCenter
		or rightMouseHeld and Enum.MouseBehavior.LockCurrentPosition
		or Enum.MouseBehavior.Default
end

--[[
	Sets up input connections for camera control.
]]
local function setupInputConnections()
	addConnection(UserInputService.InputBegan:Connect(handleCameraInput))
	addConnection(UserInputService.InputChanged:Connect(handleCameraInput))
	addConnection(UserInputService.InputEnded:Connect(handleCameraInput))

	-- Mobile touch controls
	if UserInputService.TouchEnabled then
		addConnection(UserInputService.TouchPan:Connect(handleCameraInput))
		addConnection(UserInputService.TouchRotate:Connect(handleCameraInput))

		local pinchDelta = 0
		addConnection(UserInputService.TouchPinch:Connect(function(_, scale, _, state, gpe)
			local self = SimpleCameraService
			if gpe or state == Enum.UserInputState.Begin then
				if state == Enum.UserInputState.Begin then
					pinchDelta = scale
				end
				return
			end

			targetZoom = math.clamp(targetZoom - ((scale - pinchDelta) * 20), self.MinZoom, self.MaxZoom)
			pinchDelta = scale
		end))
	end
end

--==============================================================================
-- MODULE DEFINITION
--==============================================================================

SimpleCameraService = {
	-- Camera properties
	Offset = CFrame.new(),
	TiltFactor = CFrame.fromEulerAnglesYXZ(0, 0, 0),
	Angle = 60,
	Host = nil,
	CameraView = "Default",

	-- Camera settings
	CharacterVisibility = "All",
	Zoom = 10,
	AlignChar = false,
	MinZoom = 5,
	MaxZoom = 20,
	LockMouse = false,

	-- Shake properties
	Shaking = false,
	ShakingIntensity = 0,

	-- Lock-on properties
	IsLockedOn = false,
	LockOnTarget = nil,

	-- Internal state
	xLock = false,
	yLock = false,
	atX = 0,
	atY = 0,
	_lastCameraView = nil,
}

-- Initialize host
SimpleCameraService.Host = safeWaitForChild(currentCharacter, "HumanoidRootPart")
if not SimpleCameraService.Host then
	local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 then
		SimpleCameraService.Host = safeWaitForChild(currentCharacter, "Torso")
	end
end

--==============================================================================
-- PUBLIC METHODS - CAMERA VIEWS
--==============================================================================

--[[
	Changes the camera to a specific view mode with smooth transitions.
	
	@param viewType string - The camera view type
	@param transitionTime number? - Optional smooth transition duration
]]
function SimpleCameraService:SetCameraView(viewType, transitionTime)
	assert(cameraPresets[viewType] ~= nil, `[SimpleCameraService] Camera view not found: {viewType}`)

	transitionTime = transitionTime or 0
	self.CameraView = viewType

	-- Store starting values for smooth transition
	local startZoom = currentZoom
	local startOffset = self.Offset

	-- Apply settings
	for property, value in pairs(cameraPresets[viewType]) do
		self[property] = value
	end

	-- Update target zoom
	targetZoom = self.Zoom

	-- Clear existing connections
	clearConnections()

	-- Handle smooth transitions
	if transitionTime > 0 and viewType ~= "Default" and viewType ~= "LockOn" then
		local startTime = tick()
		local targetOffsetValue = self.Offset

		local transitionConnection
		transitionConnection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - startTime
			local alpha = math.min(elapsed / transitionTime, 1)

			-- Smoothstep easing
			alpha = alpha * alpha * (3 - 2 * alpha)

			-- Interpolate zoom
			currentZoom = startZoom + (self.Zoom - startZoom) * alpha

			if alpha >= 1 then
				transitionConnection:Disconnect()
			end
		end)
	end

	-- Handle different view types
	if viewType == "Default" then
		-- Reset to Roblox default camera
		self.LockMouse = false
		camera.CameraSubject = safeWaitForChild(currentCharacter, "Humanoid")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		camera.CameraType = Enum.CameraType.Custom
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Default

		local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
	elseif viewType == "LockOn" then
		-- Lock-on mode handled in updateCamera
		self.LockMouse = true
		camera.CameraSubject = safeWaitForChild(currentCharacter, "Humanoid")
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		camera.CameraType = Enum.CameraType.Scriptable
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Default

		local humanoid = currentCharacter:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
	elseif cameraPresets[viewType] then
		-- Custom scriptable camera
		workspace.Retargeting = Enum.AnimatorRetargetingMode.Disabled

		if self.Host and self.Host.Parent == currentCharacter then
			setCharacterVisibility(self.CharacterVisibility ~= "None" and self.CharacterVisibility or nil)
		end

		UserInputService.MouseBehavior = self.LockMouse and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CameraSubject = nil

		-- Setup input and update connections
		setupInputConnections()
		addConnection(RunService.RenderStepped:Connect(function(dt)
			updateCamera(dt)
		end))
	end
end

--[[
	Creates a new custom camera view with specified settings.
	
	@param id string - Unique identifier for the camera view
	@param settings table - Table of camera properties
]]
function SimpleCameraService:CreateNewCameraView(id, settings)
	assert(typeof(settings) == "table", "[SimpleCameraService] Settings must be a table for :CreateNewCameraView()")

	cameraPresets[id] = settings

	for property, defaultValue in pairs(defaultPropertyTypes) do
		if cameraPresets[id][property] == nil then
			warn(`[SimpleCameraService] Property "{property}" not specified, using default: {defaultValue}`)
			cameraPresets[id][property] = defaultValue
		end
	end
end

--==============================================================================
-- PUBLIC METHODS - CAMERA CONTROL
--==============================================================================

--[[
	Sets the host object that the camera focuses on.
	
	@param newHost BasePart? - The part to focus on, or nil to reset
]]
function SimpleCameraService:SetCameraHost(newHost)
	if newHost then
		assert(
			typeof(newHost) == "Instance" and newHost:IsA("BasePart"),
			"[SimpleCameraService] Camera host must be a BasePart"
		)
	end

	self.Host = newHost or safeWaitForChild(currentCharacter, "HumanoidRootPart")
end

--[[
	Locks camera panning on specific axes.
	
	@param lockXAxis boolean - Whether to lock horizontal rotation
	@param lockYAxis boolean - Whether to lock vertical rotation
	@param lockAtX number? - Optional X angle to lock at (in degrees)
	@param lockAtY number? - Optional Y angle to lock at (in degrees)
]]
function SimpleCameraService:LockCameraPanning(lockXAxis, lockYAxis, lockAtX, lockAtY)
	self.atX = lockAtX and math.rad(lockAtX) or 0
	self.atY = lockAtY and math.rad(lockAtY) or 0
	self.xLock = lockXAxis
	self.yLock = lockYAxis
end

--[[
	Changes a specific camera property.
	
	@param property string - Property name to change
	@param newValue any - New value for the property
	@param updateDefault boolean? - Whether to update the default for current view
]]
function SimpleCameraService:Change(property, newValue, updateDefault)
	assert(defaultPropertyTypes[property] ~= nil, `[SimpleCameraService] "{property}" is not a valid camera property`)

	self[property] = newValue

	-- Update target values for smooth properties
	if property == "Zoom" then
		targetZoom = newValue
	end

	if updateDefault and self.CameraView then
		cameraPresets[self.CameraView][property] = newValue
	end
end

--[[
	Changes the mouse sensitivity.
	
	@param sensitivity number - Sensitivity multiplier (must be > 0)
]]
function SimpleCameraService:ChangeSensitivity(sensitivity)
	assert(
		type(sensitivity) == "number" and sensitivity > 0,
		"[SimpleCameraService] Sensitivity must be a positive number"
	)

	UserInputService.MouseDeltaSensitivity = sensitivity
end

--[[
	Changes the camera field of view with optional smooth transition.
	
	@param fov number - New field of view value
	@param instant boolean? - If true, changes instantly; if false, tweens
]]
function SimpleCameraService:ChangeFOV(fov, instant)
	assert(type(fov) == "number" and fov > 0, "[SimpleCameraService] FOV must be a positive number")

	if instant then
		camera.FieldOfView = fov
	else
		local tween = TweenService:Create(
			camera,
			TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ FieldOfView = fov }
		)
		tween:Play()
		tween.Completed:Wait()
		tween:Destroy()
	end
end

--[[
	Sets the vertical angle range for camera rotation.
	
	@param angle number - Maximum vertical angle in degrees (0-89)
]]
function SimpleCameraService:SetVerticalRange(angle)
	self.Angle = math.clamp(math.abs(angle), 0, CONSTANTS.ANGLE_CLAMP_MAX)
end

--[[
	Tilts the camera on the Z axis (roll).
	
	@param degrees number - Tilt angle in degrees
]]
function SimpleCameraService:Tilt(degrees)
	self.TiltFactor = CFrame.fromEulerAnglesYXZ(0, 0, math.rad(degrees) or 0)
end

--[[
	Tilts the camera on all three axes.
	
	@param x number? - X-axis rotation in degrees
	@param y number? - Y-axis rotation in degrees
	@param z number? - Z-axis rotation in degrees
]]
function SimpleCameraService:TiltAllAxes(x, y, z)
	self.TiltFactor = CFrame.fromEulerAnglesYXZ(y and math.rad(y) or 0, x and math.rad(x) or 0, z and math.rad(z) or 0)
end

--[[
	Applies a camera shake effect for visual feedback.
	
	@param intensity number - Shake intensity (must be > 0)
	@param duration number - Duration in seconds (must be > 0)
]]
function SimpleCameraService:Shake(intensity, duration)
	assert(duration > 0 and intensity > 0, "[SimpleCameraService] Shake intensity and duration must be positive")

	self.ShakingIntensity = intensity
	self.Shaking = true

	task.delay(duration, function()
		self.Shaking = false
	end)
end

--==============================================================================
-- PUBLIC METHODS - LOCK-ON SYSTEM
--==============================================================================

--[[
	Locks the camera onto a specific target with smooth tracking.
	OPTIMIZED: Smooth transition from first-person to lock-on.
	
	@param targetHRP BasePart - The target to lock onto
	@return boolean - True if lock-on successful
]]
function SimpleCameraService:LockOnToTarget(targetHRP)
	if not targetHRP or not targetHRP:IsA("BasePart") then
		warn("[SimpleCameraService] Invalid lock-on target")
		return false
	end

	-- Toggle off if already locked to this target
	if isLockedOn and lockedTarget == targetHRP then
		self:ClearLockOn()
		return false
	end

	-- Store current rotation for smooth transition
	preLockOnRotation = currentSmoothedRotation

	-- Set up lock-on state
	lockedTarget = targetHRP
	isLockedOn = true
	self.IsLockedOn = true
	self.LockOnTarget = targetHRP

	-- Initialize smooth transition
	lockOnTransitioning = true
	lockOnStartTime = tick()

	-- Configure camera and character
	currentCharacter:SetAttribute("ShiftLock", true)
	self:SetCameraView("LockOn")
	self:LockCameraPanning(true, true)

	-- Hide cursor
	UserInputService.MouseIconEnabled = false

	-- Visual feedback
	self:Shake(CONSTANTS.SHAKE_FEEDBACK_INTENSITY, CONSTANTS.SHAKE_FEEDBACK_DURATION)

	return true
end

--[[
	Clears the current lock-on target and returns to normal camera.
	OPTIMIZED: Smooth transition back to first-person.
]]
function SimpleCameraService:ClearLockOn()
	-- Store lock state for smooth transition out
	local wasLocked = isLockedOn

	-- Reset camera state
	self:LockCameraPanning(false, false)
	self:SetCameraView("FirstPerson", 0.2) -- Smooth 0.2s transition
	self:SetCameraHost()

	-- Restore cursor
	UserInputService.MouseIconEnabled = true
	UserInputService.MouseIcon = "rbxasset://SystemCursors/Arrow"

	-- Clear lock-on state
	isLockedOn = false
	lockedTarget = nil
	lockOnTransitioning = false
	self.IsLockedOn = false
	self.LockOnTarget = nil

	-- Clear character attribute
	if currentCharacter then
		currentCharacter:SetAttribute("ShiftLock", false)
	end

	-- Reset target tracking
	potentialTargets = {}
	currentTargetIndex = 0

	-- If we were locked on, restore some camera control
	if wasLocked then
		-- Restore rotation gradually
		targetCameraRotation = preLockOnRotation
	end
end

--[[
	Finds and locks onto the closest valid target within range.
	
	@return boolean - True if a target was found and locked
]]
function SimpleCameraService:FindClosestTarget()
	if gatherPotentialTargets() and #potentialTargets > 0 then
		currentTargetIndex = 1
		return self:LockOnToTarget(potentialTargets[currentTargetIndex].hrp)
	end
	return false
end

--[[
	Cycles to the next available target.
	OPTIMIZED: Smooth transition between targets.
	
	@return boolean - True if successfully cycled
]]
function SimpleCameraService:CycleTargets()
	if not isLockedOn then
		return self:FindClosestTarget()
	end

	if #potentialTargets == 0 then
		if not gatherPotentialTargets() then
			return false
		end
	end

	if #potentialTargets == 0 then
		return false
	end

	currentTargetIndex = currentTargetIndex + 1
	if currentTargetIndex > #potentialTargets then
		currentTargetIndex = 1
	end

	local targetInfo = potentialTargets[currentTargetIndex]
	if targetInfo and targetInfo.hrp and targetInfo.hrp:IsDescendantOf(workspace) then
		-- Smooth transition to new target
		lockOnTransitioning = true
		lockOnStartTime = tick()

		self:LockOnToTarget(targetInfo.hrp)

		-- Lighter feedback for cycling
		self:Shake(CONSTANTS.SHAKE_CYCLE_FEEDBACK_INTENSITY, CONSTANTS.SHAKE_CYCLE_FEEDBACK_DURATION)
		return true
	else
		gatherPotentialTargets()
		if #potentialTargets > 0 then
			return self:CycleTargets()
		end
		return false
	end
end

--[[
	Gets a list of all potential lock-on targets within range.
	
	@return table - Array of target info tables
]]
function SimpleCameraService:GetPotentialTargets()
	gatherPotentialTargets()
	return potentialTargets
end

--[[
	Finds the target closest to the screen center (crosshair).
	BEST FOR FPS: Most intuitive targeting.
	
	@return boolean - True if a target was found and locked
]]
function SimpleCameraService:FindScreenCenterTarget()
	if not gatherPotentialTargets() or #potentialTargets == 0 then
		return false
	end

	local screenTargets = {}
	for _, targetInfo in ipairs(potentialTargets) do
		local screenDist = getScreenSpaceDistance(targetInfo.hrp)
		if screenDist < math.huge then
			table.insert(screenTargets, {
				targetInfo = targetInfo,
				screenDist = screenDist,
			})
		end
	end

	if #screenTargets == 0 then
		return false
	end

	table.sort(screenTargets, function(a, b)
		return a.screenDist < b.screenDist
	end)

	return self:LockOnToTarget(screenTargets[1].targetInfo.hrp)
end

--[[
	Enables or disables walk sway effect.
	
	@param enabled boolean - Whether walk sway should be active
]]
function SimpleCameraService:SetWalkSwayEnabled(enabled)
	CONSTANTS.WALK_SWAY_ENABLED = enabled
	if not enabled then
		currentSwayIntensity = 0
		targetSwayIntensity = 0
		walkSwayTime = 0
	end
end

--[[
	Adjusts walk sway intensity.
	
	@param amplitude number - Sway strength (0.05 = subtle, 0.15 = noticeable)
]]
function SimpleCameraService:SetWalkSwayIntensity(amplitude)
	CONSTANTS.WALK_SWAY_AMPLITUDE = math.clamp(amplitude, 0, 0.3)
end

--[[
	Gets current walk sway state.
	
	@return boolean, number - enabled, current intensity
]]
function SimpleCameraService:GetWalkSwayState()
	return CONSTANTS.WALK_SWAY_ENABLED, currentSwayIntensity
end

--[[
	Enables or disables head tracking for ThirdPersonVariant mode.
	Useful for disabling during specific scenarios like running, combat, etc.
	
	@param enabled boolean - Whether head tracking should be active
]]
function SimpleCameraService:SetHeadTrackingEnabled(enabled)
	CONSTANTS.HEAD_TRACKING_ENABLED = enabled

	-- Reset head to neutral when disabling
	if not enabled and neckMotor and originalNeckC0 then
		neckMotor.C0 = originalNeckC0
		currentHeadRotation = Vector2.zero
		targetHeadRotation = Vector2.zero
	end
end

--[[
	Gets the current head tracking enabled state.
	
	@return boolean - Whether head tracking is currently enabled
]]
function SimpleCameraService:IsHeadTrackingEnabled()
	return CONSTANTS.HEAD_TRACKING_ENABLED
end

--==============================================================================
-- CHARACTER RESPAWN HANDLING
--==============================================================================

player.CharacterRemoving:Connect(function(char)
	isRespawning = true
	SimpleCameraService._lastCameraView = SimpleCameraService.CameraView
	SimpleCameraService:ClearLockOn()
	clearConnections()
	camera.CameraType = Enum.CameraType.Custom
	workspace.Retargeting = Enum.AnimatorRetargetingMode.Default
end)

player.CharacterAdded:Connect(function(char)
	task.wait(CONSTANTS.CHARACTER_LOAD_DELAY)
	isRespawning = false

	local humanoid = safeWaitForChild(char, "Humanoid")
	local rootPart = safeWaitForChild(char, "HumanoidRootPart")

	if not humanoid or not rootPart then
		warn("[SimpleCameraService] Failed to load character components")
		return
	end

	currentCharacter = char
	SimpleCameraService:SetCameraHost(rootPart)
	SimpleCameraService:ClearLockOn()

	-- Reset smoothing state
	currentSmoothedRotation = cameraRotation
	currentZoom = SimpleCameraService.Zoom
	targetZoom = SimpleCameraService.Zoom
	inputVelocity = Vector2.zero
	arrowKeyAngle = 0
	targetArrowKeyAngle = 0

	-- Reset head tracking state
	neckMotor = nil
	originalNeckC0 = nil
	currentHeadRotation = Vector2.zero
	targetHeadRotation = Vector2.zero

	local viewToRestore = SimpleCameraService._lastCameraView or "FirstPerson"
	SimpleCameraService:SetCameraView(viewToRestore)
	SimpleCameraService._lastCameraView = nil
end)

--==============================================================================
-- INITIALIZATION
--==============================================================================

if not isRespawning then
	SimpleCameraService:SetCameraView("FirstPerson")
end

return SimpleCameraService
