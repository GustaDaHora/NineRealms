local NPCPatrolModule = {}
local PathfindingService = game:GetService("PathfindingService")

local function isNpcStationary(npcHum)
	if not npcHum or not npcHum.Parent or not npcHum.RootPart then
		return true
	end
	local moveDirection = npcHum.MoveDirection.Magnitude
	local velocity = npcHum.RootPart.AssemblyLinearVelocity.Magnitude
	return moveDirection == 0 and velocity < 0.1
end

local function moveToWaypoint(npcHum, waypoint)
	if not npcHum or not npcHum.RootPart then
		return false
	end

	npcHum:MoveTo(waypoint.Position)
	local success = npcHum.MoveToFinished:Wait()
	return success
end

local function patrol(npc, waypoints, npcHum)
	while npc and npc:IsDescendantOf(workspace) do
		-- **Check if NPC should NOT patrol**
		if npc:GetAttribute("Chasing") or npc:GetAttribute("Fighting") or npc:GetAttribute("Ragdolled") then
			npc:SetAttribute("Patrolling", false)
			task.wait(1) -- Reduce CPU usage
			continue
		end

		if not npc:GetAttribute("Patrolling") then
			task.wait(1)
			continue
		end

		if isNpcStationary(npcHum) then
			local randomWaypoint = waypoints[math.random(1, #waypoints)]
			local path = PathfindingService:CreatePath({
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				AgentMaxSlope = 45,
			})

			path:ComputeAsync(npc.HumanoidRootPart.Position, randomWaypoint.Position)
			if path.Status == Enum.PathStatus.Success then
				for _, waypoint in ipairs(path:GetWaypoints()) do
					-- **Check if NPC should stop patrolling**
					if
						npc:GetAttribute("Chasing")
						or npc:GetAttribute("Fighting")
						or not npc:GetAttribute("Patrolling")
					then
						npcHum:Move(Vector3.zero)
						return
					end

					if not moveToWaypoint(npcHum, waypoint) then
						break
					end

					if waypoint.Action == Enum.PathWaypointAction.Jump then
						npcHum.Jump = true
					end
				end
			else
				warn("Pathfinding failed for NPC:", npc.Name)
			end
		end

		task.wait(math.random(5, 20)) -- Random delay between patrols
	end
end

function NPCPatrolModule.InitializeNPC(npc)
	local waypoints = npc.Parent:FindFirstChild("waypoints"):GetChildren()
	local npcHum = npc:WaitForChild("Humanoid")

	task.spawn(function()
		patrol(npc, waypoints, npcHum)
	end)
end

return NPCPatrolModule
