-- // Services
local rs = game:GetService("ReplicatedStorage")
local soundService = game:GetService("SoundService")
local runService = game:GetService("RunService")

-- // Variables
local sounds = soundService:WaitForChild("Footsteps")
local footstepTemplate = rs:WaitForChild("NPCFootstepTemplate")

-- // Footstep Timing
local intervals = {
	Walking = 0.55,
	Running = 0.3,
	Attacking = 0.9,
}

-- // State Variables
local isWalking = {}
local lastFootstepTime = {}
local currentFootstepInterval = intervals.Walking

-- // States that should NOT trigger footsteps
local nonWalkingStates = {
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Flying] = true,
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.Landed] = true,
}

-- // Functions
local function shootRay(rayOrigin, rayDirection, raycastParams)
	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
	return raycastResult
end

local function createFootstep(npc, foot)
	if not foot then
		return
	end -- Ensure the foot exists

	local humanoidRootPart = npc:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	local rayOrigin = foot.Position + Vector3.new(0, 0.1, 0)
	local rayDirection = Vector3.new(0, -5, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = false
	raycastParams.FilterDescendantsInstances = { npc }

	local raycastResult = shootRay(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		local material = tostring(raycastResult.Material):match("%.(%w+)$") or "Default"

		local newFootstep = footstepTemplate:Clone()
		local footstepPosition = raycastResult.Position

		-- Offset the footstep slightly forward based on movement direction
		local movementDirection = humanoidRootPart.CFrame.LookVector * 1.5 -- Adjust for placement
		footstepPosition = footstepPosition + movementDirection

		-- Slightly raise the footstep position
		footstepPosition = footstepPosition + Vector3.new(0, 0.1, 0)

		newFootstep.Position = footstepPosition
		newFootstep.CFrame = CFrame.new(footstepPosition, footstepPosition + raycastResult.Normal)
			* CFrame.Angles(math.pi / 2, 0, 0)
		newFootstep.Parent = workspace:FindFirstChild("FOOTSTEPS") or workspace

		local newSound = sounds:FindFirstChild(material) or sounds:FindFirstChild("Default")
		if newSound then
			if currentFootstepInterval == intervals.Walking then
				newSound.PlaybackSpeed = math.random(9, 11) / 10
			end
			newSound = newSound:Clone()
			newSound.Parent = newFootstep
			newSound:Play()
			game:GetService("Debris"):AddItem(newFootstep, 1)
		end
	end
end

-- // NPC Footstep Handling
local NPCFootsteps = {}

function NPCFootsteps.StartFootsteps(npc)
	local humanoid = npc:WaitForChild("Humanoid")
	local rootPart = npc:WaitForChild("HumanoidRootPart")

	isWalking[npc] = false
	lastFootstepTime[npc] = 0

	-- Get legs
	local leftFoot = npc:FindFirstChild("Left Leg")
	local rightFoot = npc:FindFirstChild("Right Leg")

	-- Track movement every frame
	local connection
	connection = runService.Heartbeat:Connect(function()
		if not npc.Parent then
			-- Cleanup if NPC is removed
			connection:Disconnect()
			isWalking[npc] = nil
			lastFootstepTime[npc] = nil
			return
		end

		if humanoid.Health <= 0 then
			return
		end -- Stop if NPC dies

		-- Stop footsteps if the NPC is in a non-walking state
		if nonWalkingStates[humanoid:GetState()] then
			isWalking[npc] = false
			return
		end

		-- Check if NPC is moving
		if humanoid.MoveDirection.Magnitude > 0 then
			if not isWalking[npc] then
				isWalking[npc] = true
			end

			-- Calculate the footstep interval dynamically
			local Xspeed = math.abs(npc.PrimaryPart.AssemblyLinearVelocity.X)
			local Zspeed = math.abs(npc.PrimaryPart.AssemblyLinearVelocity.Z)

			if npc:GetAttribute("Attacking") then
				currentFootstepInterval = intervals.Attacking
			elseif Xspeed > 12 or Zspeed > 12 then
				currentFootstepInterval = intervals.Running
			else
				currentFootstepInterval = intervals.Walking
			end

			-- Play alternating footsteps based on timing
			if tick() - lastFootstepTime[npc] >= currentFootstepInterval then
				if lastFootstepTime[npc] % 2 == 0 then
					createFootstep(npc, rightFoot)
				else
					createFootstep(npc, leftFoot)
				end

				lastFootstepTime[npc] = tick() -- Update last footstep time
			end
		else
			isWalking[npc] = false -- NPC stopped moving
		end
	end)
end

return NPCFootsteps
