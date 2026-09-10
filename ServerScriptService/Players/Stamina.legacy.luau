local RS = game:GetService("ReplicatedStorage")
local movementRequest = RS:WaitForChild("RE"):WaitForChild("Movement"):WaitForChild("MovementRequest")
local RunService = game:GetService("RunService")

local Particles = RS:WaitForChild("Particles")

local RunningStaminaCost = 1
local SprintStaminaCost = 25

local function emitParticles(char)
	local humRoot = char:WaitForChild("HumanoidRootPart")

	-- Only create one weld if it doesn't already exist
	local weld = humRoot:FindFirstChild("SPEEDWELD")
	if not weld then
		weld = Instance.new("WeldConstraint")
		weld.Name = "SPEEDWELD"
		weld.Part0 = humRoot
		weld.Parent = humRoot
	end

	-- Only create one particle attachment if not exists
	local speedParticle = humRoot:FindFirstChild("SPEEDPARTICLE")
	if not speedParticle then
		speedParticle = Particles.Speed:Clone()
		speedParticle.Name = "SPEEDPARTICLE"
		speedParticle.CFrame = humRoot.CFrame
		speedParticle.Parent = humRoot

		weld.Part1 = speedParticle
	end
	

	-- Emit particles
	for _, emitter in speedParticle:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true
		end
	end

	task.wait(0.3)

	for _, emitter in speedParticle:GetChildren() do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = false
		end
	end
end

movementRequest.OnServerEvent:Connect(function(player, action, state)
	local char = player.Character
	local hum = char:WaitForChild("Humanoid")
	local stamina = char:GetAttribute("Stamina") or 0

	if stamina > 1  then
		if action == "Sprint" then
			if state then
				--local newStamina = stamina - SprintStaminaCost
				--char:SetAttribute("Stamina", math.max(0, newStamina))
				emitParticles(char)
			end
		elseif action == "Running" then
		end
	end
end)