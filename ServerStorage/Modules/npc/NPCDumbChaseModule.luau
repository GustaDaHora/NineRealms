local NPCDumbChaseModule = {}
local Players = game:GetService("Players")
local CombatModule = require(game.ServerStorage.Modules.npc.NPCCombatModule)

-- Find players within a certain range, considering vision angle
local function FindPlayersInRange(npc, detectionRange, visionAngle)
	local playersInRange = {}
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")

	if not npcRoot then
		return {}
	end

	local npcPos = npcRoot.Position
	local npcLookVector = npcRoot.CFrame.LookVector

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local humanoid = char and char:FindFirstChild("Humanoid")

		if root and humanoid and humanoid.Health > 0 and not char:GetAttribute("Fallen") then
			local playerPos = root.Position
			local dirToPlayer = (playerPos - npcPos).Unit
			local distSq = (playerPos - npcPos).Magnitude ^ 2

			-- Calculate appropriate detection range based on direction
			local dotProduct = npcLookVector:Dot(dirToPlayer)

			local maxDist = (dotProduct >= math.cos(math.rad(60)) and 30)
				or (dotProduct >= math.cos(math.rad(120)) and 20)
				or (dotProduct >= -1 and 10)
				or nil

			-- Check if player is within detection range
			if maxDist and distSq <= maxDist ^ 2 then
				table.insert(playersInRange, {
					character = char,
					distance = math.sqrt(distSq),
					dotProduct = dotProduct,
				})
			end
		end
	end

	-- Sort by distance
	table.sort(playersInRange, function(a, b)
		return a.distance < b.distance
	end)

	return playersInRange
end

local function RotateTowardsTarget(npcRoot, targetRoot)
	if not npcRoot or not targetRoot then
		return
	end

	-- Check if NPC already has a BodyGyro; if not, create one
	local bodyGyro = npcRoot:FindFirstChild("BodyGyro")
	if not bodyGyro then
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.MaxTorque = Vector3.new(0, 600000, 0) -- Only allow rotation on Y-axis
		bodyGyro.P = 4000 -- Power of the rotation
		bodyGyro.Parent = npcRoot
	end

	-- Set the rotation target
	local targetPosition = targetRoot.Position
	bodyGyro.CFrame =
		CFrame.lookAt(npcRoot.Position, Vector3.new(targetPosition.X, npcRoot.Position.Y, targetPosition.Z))
end

local function MoveToTarget(npc, npcHum, target, punchDistance, sound, animations, strength, hitboxSize)
	if target then
		local root = target:FindFirstChild("HumanoidRootPart")
		local npcRoot = npc:FindFirstChild("HumanoidRootPart")

		if root and npcRoot then
			local targetPos = root.Position
			local npcPos = npcRoot.Position
			local direction = (targetPos - npcPos).Unit
			local dot = npcRoot.CFrame.LookVector:Dot(direction)
			local dist = (targetPos - npcPos).Magnitude

			-- Rotate first, then move
			if dot < 0.7 then
				RotateTowardsTarget(npcRoot, root)
			end

			if dist <= punchDistance then
				npc:SetAttribute("Chasing", false)
				npc:SetAttribute("Fighting", true)
				npcHum.WalkSpeed = 12

				if not npc:GetAttribute("AttackDebounce") then
					npc:SetAttribute("AttackDebounce", true)
					CombatModule.Hit(npc, sound, animations, strength, hitboxSize)
					task.delay(0.5, function()
						npc:SetAttribute("AttackDebounce", false)
					end)
				end
			else
				npcHum.WalkSpeed = 19
				npc:SetAttribute("Chasing", true)
				npc:SetAttribute("Fighting", false)

				-- Only move if the target has moved significantly
				if (npcRoot.Position - targetPos).Magnitude > 2 then
					npcHum:MoveTo(targetPos)
				end
			end
		end
	end
end

function NPCDumbChaseModule.InitializeNPC(npc, initialPosition, punchDistance, sound, animations, strength, hitboxSize)
	local npcHum = npc:WaitForChild("Humanoid")
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	local target = nil
	local running = true
	local maxDistanceFromCenter = 200 -- Change this value based on how far NPCs should wander
	local sightCheckInterval = 1 -- Check for players every 1 second
	local lastSightCheck = 0

	-- Initialize attributes
	npc:SetAttribute("Chasing", false)
	npc:SetAttribute("Fighting", false)
	npc:SetAttribute("Patrolling", true)
	npc:SetAttribute("AttackDebounce", false)

	-- Clean up when NPC is destroyed
	npc.AncestryChanged:Connect(function()
		if not npc:IsDescendantOf(workspace) then
			running = false
		end
	end)

	-- Handle player leaving (prevents unnecessary iterations)
	Players.PlayerRemoving:Connect(function(player)
		if target == player.Character then
			target = nil
		end
	end)

	task.spawn(function()
		while running do
			local now = os.clock()

			if npc:GetAttribute("Stunned") then
				task.wait(0.5)
				continue
			end

			-- Calculate NPC distance from the center position
			local npcPosition = npcRoot.Position
			local distanceFromCenter = (npcPosition - initialPosition).Magnitude

			if distanceFromCenter > maxDistanceFromCenter then
				-- NPC is too far from center! Reset and return.
				target = nil
				npc:SetAttribute("Chasing", false)
				npc:SetAttribute("Fighting", false)
				npc:SetAttribute("Patrolling", true)
				npcHum.WalkSpeed = 16
				npcHum:MoveTo(initialPosition) -- Move back to center
				npcHum.MoveToFinished:Wait()
				task.wait(2) -- Wait before looking for a new target
			else
				-- Find closest player if the sight check cooldown has passed
				if now - lastSightCheck >= sightCheckInterval then
					lastSightCheck = now

					-- Use the new player detection function
					local playersInRange = FindPlayersInRange(npc, 30, 250) -- 30 units, 250 degree vision cone

					if #playersInRange > 0 then
						-- Select the closest player as target
						local newTarget = playersInRange[1].character

						if
							newTarget
							and not newTarget:GetAttribute("Fallen")
							and newTarget:FindFirstChild("Humanoid")
							and newTarget.Humanoid.Health > 0
						then
							target = newTarget
							npc:SetAttribute("Patrolling", false)
						end
					else
						-- No players in range, reset target
						target = nil
						if not npc:GetAttribute("Patrolling") then
							npc:SetAttribute("Patrolling", true)
						end
					end
				end

				-- Move NPC toward target if found
				if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 then
					MoveToTarget(npc, npcHum, target, punchDistance, sound, animations, strength, hitboxSize)
				else
					npcHum.WalkSpeed = 12
					npc:SetAttribute("Chasing", false)
					npc:SetAttribute("Fighting", false)

					-- Simple random patrol movement if no target
					if npc:GetAttribute("Patrolling") and math.random() < 0.05 then
						local randomOffset = Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
						local patrolPoint = initialPosition + randomOffset
						npcHum:MoveTo(patrolPoint)
					end
				end
			end

			task.wait(0.2) -- Controls how often the NPC runs this logic
		end
	end)
end

return NPCDumbChaseModule
