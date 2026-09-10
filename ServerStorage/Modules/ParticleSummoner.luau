local ParticleSummoner = {}
local particleFolder = game.ReplicatedStorage.Particles
local emitterDelays = {} -- Track active delays for emitters

function ParticleSummoner.EmitParticles(particleName, parent, quantity, lifeTime, position, properties)
	local attachment = parent:FindFirstChild(particleName)
	if not attachment then
		local template = particleFolder:FindFirstChild(particleName)
		if not template then
			warn("Particle not found:", particleName)
			return
		end
		attachment = template:Clone()
		attachment.Parent = parent
	end

	if position then
		attachment.Position = position
	end

	for _, child in ipairs(attachment:GetDescendants()) do
		if child:IsA("ParticleEmitter") or child:IsA("Trail") then
			if properties then
				for key, value in pairs(properties) do
					child[key] = value
				end
			end

			child.Enabled = true
			if quantity then
				child:Emit(quantity)
			end

			-- Cancel existing delay for this emitter if any
			if emitterDelays[child] then
				task.cancel(emitterDelays[child])
			end

			-- Start a new delay to disable the emitter
			emitterDelays[child] = task.delay(lifeTime, function()
				child.Enabled = false
				emitterDelays[child] = nil
			end)
		end
	end
end

return ParticleSummoner