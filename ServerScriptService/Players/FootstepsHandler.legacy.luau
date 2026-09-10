-- // Improved Footstep System
-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- // Constants
local FOOTSTEP_CONTAINER_NAME = "FOOTSTEPS"
local FOOTSTEP_LIFETIME = 1
local RAYCAST_DISTANCE = 5
local RAYCAST_OFFSET = 0.1
local FOOTSTEP_SURFACE_OFFSET = 0.05

-- // References
local sounds = SoundService:WaitForChild("Footsteps")
local footstepTemplate = ReplicatedStorage:WaitForChild("FootstepTemplate")

-- // Configuration
local FOOTSTEP_CONFIG = {
	INTERVALS = {
		MinWalking = 0.76, -- Slowest walking interval
		MaxRunning = 0.25, -- Fastest running interval
		Attacking = 1, -- Fixed interval when attacking
	},
	SPEED_THRESHOLDS = {
		MinWalking = 1, -- Minimum speed to be considered walking
		MaxRunning = 26, -- Speed at which maximum running speed is reached
	},
}

-- // Cached tables for performance
local playerStates = {}

-- // Non-Walking States (using table for O(1) lookup)
local nonWalkingStates = {
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Flying] = true,
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Landed] = true,
	[Enum.HumanoidStateType.Dead] = true,
}

-- // Utility Functions
local function getFootstepContainer()
	local container = workspace:FindFirstChild(FOOTSTEP_CONTAINER_NAME)
	if not container then
		container = Instance.new("Folder")
		container.Name = FOOTSTEP_CONTAINER_NAME
		container.Parent = workspace
	end
	return container
end

local function shootRay(origin, direction, ignoreList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false
	params.FilterDescendantsInstances = ignoreList

	return workspace:Raycast(origin, direction, params)
end

local function getMaterialName(material)
	return tostring(material):match("%.(%w+)$") or "Default"
end

local function playFootstepSound(footstep, materialName, velocity)
	local sound = sounds:FindFirstChild(materialName) or sounds:FindFirstChild("Default")
	if sound then
		local clonedSound = sound:Clone()
		clonedSound.Parent = footstep

		-- Calculate horizontal speed (ignoring Y/vertical velocity)
		local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

		-- Calculate playback speed based on velocity
		-- Map speed to a range between 0.8-1.4 for walking/running
		-- Base pitch + speed modifier + small random variation
		local minSpeed = 1 -- Walking pace
		local maxSpeed = 26 -- Sprint pace
		local minPitch = 0.8 -- Slower footsteps (walking)
		local maxPitch = 1.3 -- Faster footsteps (running)
		local randomVariation = (math.random(-10, 10) / 100) -- ±0.1 random variation

		-- Clamp speed between min and max values
		local clampedSpeed = math.clamp(horizontalSpeed, minSpeed, maxSpeed)

		-- Calculate normalized speed (0-1 range)
		local normalizedSpeed = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)

		-- Map to pitch range with small random variation
		local calculatedPitch = minPitch + (normalizedSpeed * (maxPitch - minPitch)) + randomVariation

		-- Apply the calculated pitch
		clonedSound.PlaybackSpeed = calculatedPitch

		-- Also adjust speed based on speed
		local speedMultiplier = 0.9 + (normalizedSpeed * 0.1)
		clonedSound.PlaybackSpeed = clonedSound.PlaybackSpeed * speedMultiplier

		clonedSound:Play()
	end
end

local function createFootstepEffect(position, normal, materialName, velocity)
	local footstep = footstepTemplate:Clone()

	-- Align with surface and offset slightly
	local adjustedPosition = position + (normal * FOOTSTEP_SURFACE_OFFSET)
	footstep.CFrame = CFrame.lookAt(adjustedPosition, adjustedPosition + normal) * CFrame.Angles(math.pi / 2, 0, 0)

	-- Play sound with velocity-based parameters
	playFootstepSound(footstep, materialName, velocity)

	-- Parent and clean up
	footstep.Parent = getFootstepContainer()
	Debris:AddItem(footstep, FOOTSTEP_LIFETIME)

	return footstep
end

local function createFootstep(character, foot, velocity)
	if not foot or not character:IsDescendantOf(workspace) then
		return
	end

	local rayOrigin = foot.Position + Vector3.new(0, RAYCAST_OFFSET, 0)
	local rayDirection = Vector3.new(0, -RAYCAST_DISTANCE, 0)

	local raycastResult = shootRay(rayOrigin, rayDirection, { character })
	if raycastResult then
		local materialName = getMaterialName(raycastResult.Material)
		createFootstepEffect(raycastResult.Position, raycastResult.Normal, materialName, velocity)
	end
end

-- // Character Tracking
local function setupCharacter(player, character)
	-- Wait for essential parts
	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	-- Cache foot parts
	local leftFoot = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftFoot")
	local rightFoot = character:FindFirstChild("Right Leg") or character:FindFirstChild("RightFoot")

	-- Initialize player state data
	local playerState = {
		isWalking = false,
		lastFootstepTime = 0,
		footstepSide = true, -- true = Right, false = Left
		connections = {},
	}

	-- Store player state
	playerStates[player] = playerState

	-- Handle state changes
	local function onStateChange(_, newState)
		if nonWalkingStates[newState] then
			playerState.isWalking = false
		end
	end

	-- Movement processing
	local function processMovement(deltaTime)
		-- Check if character is still valid
		if not character:IsDescendantOf(workspace) or humanoid.Health <= 0 then
			playerState.isWalking = false
			return
		end

		-- Check if moving
		local isMoving = humanoid.MoveDirection.Magnitude > 0
		local currentState = humanoid:GetState()
		local canStep = isMoving and not nonWalkingStates[currentState]

		-- Update walking state
		playerState.isWalking = canStep

		if canStep then
			-- Calculate velocity and determine footstep interval
			local velocity = rootPart.AssemblyLinearVelocity
			local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

			local isAttacking = character:GetAttribute("Attacking") == true

			local footstepInterval
			if isAttacking then
				footstepInterval = FOOTSTEP_CONFIG.INTERVALS.Attacking
			else
				-- Dynamically calculate interval based on speed
				-- Map from slowest interval (walking) to fastest interval (running)
				local minSpeed = FOOTSTEP_CONFIG.SPEED_THRESHOLDS.MinWalking
				local maxSpeed = FOOTSTEP_CONFIG.SPEED_THRESHOLDS.MaxRunning
				local slowInterval = FOOTSTEP_CONFIG.INTERVALS.MinWalking
				local fastInterval = FOOTSTEP_CONFIG.INTERVALS.MaxRunning

				-- Clamp speed between min and max
				local clampedSpeed = math.clamp(horizontalSpeed, minSpeed, maxSpeed)

				-- Calculate normalized speed (0-1 range)
				local normalizedSpeed = (clampedSpeed - minSpeed) / (maxSpeed - minSpeed)

				-- Inverse lerp from slow to fast interval (higher speed = lower interval)
				footstepInterval = slowInterval - (normalizedSpeed * (slowInterval - fastInterval))
			end

			-- Create footstep at appropriate intervals
			if os.clock() - playerState.lastFootstepTime >= footstepInterval then
				local foot = playerState.footstepSide and rightFoot or leftFoot

				-- Pass the full velocity vector to affect sound properties
				createFootstep(character, foot, rootPart.AssemblyLinearVelocity)

				-- Toggle foot and update time
				playerState.footstepSide = not playerState.footstepSide
				playerState.lastFootstepTime = os.clock()
			end
		end
	end

	-- Connect events
	table.insert(playerState.connections, humanoid.StateChanged:Connect(onStateChange))
	table.insert(playerState.connections, RunService.Heartbeat:Connect(processMovement))

	-- Cleanup function
	local function cleanupCharacter()
		if playerStates[player] then
			for _, connection in ipairs(playerState.connections) do
				connection:Disconnect()
			end
			playerStates[player] = nil
		end
	end

	-- Connect cleanup
	character.Destroying:Connect(cleanupCharacter)

	-- Handle player leaving
	local state = playerStates[player]
	if state then
		if not state.playerRemoving then
			state.playerRemoving = Players.PlayerRemoving:Connect(function(leavingPlayer)
				-- Re-check state in case it was cleaned up before this fires
				local currentState = playerStates[player]
				if leavingPlayer == player and currentState then
					if currentState.playerRemoving then
						currentState.playerRemoving:Disconnect()
					end
					cleanupCharacter()
				end
			end)
		end
	end
end

-- // Player Tracking
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)

	-- Handle existing character
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

-- // Initialize
local function initialize()
	-- Set up footstep container
	getFootstepContainer()

	-- Connect to new players
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
end

-- // Start the system
initialize()
