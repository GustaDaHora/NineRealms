-- Improved HitService module
local debris = game:GetService("Debris")
local HitService = {}
local ragdollModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RagdollModule"))

-- Helper to create and apply LinearVelocity
local function applyVelocity(part, velocity, lifetime)
	if not part or not velocity then
		return
	end

	-- Create an attachment for LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	-- Create LinearVelocity
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = attachment
	lv.VectorVelocity = velocity
	lv.MaxForce = 100000 -- Ensure this matches the `maxForce` value from your knockback function
	lv.RelativeTo = Enum.ActuatorRelativeTo.World -- World-based velocity
	lv.Parent = part

	-- Cleanup after the lifetime
	debris:AddItem(attachment, lifetime)
	debris:AddItem(lv, lifetime)
end

-- Function to handle hits with directional knockback
function HitService.hit(enemyHum, damage, knockback, attackerKnockback, attacker, ragdoll)
	if not enemyHum or not attacker or not enemyHum:IsA("Humanoid") then
		warn("Invalid parameters passed to hitService.")
		return
	end

	local enemy = enemyHum.Parent
	local enemyHumRp = enemy:FindFirstChild("HumanoidRootPart")
	local attackerHumRp = attacker:FindFirstChild("HumanoidRootPart")

	if not enemyHumRp or not attackerHumRp then
		warn("Missing essential parts in enemy or attacker.")
		return
	end

	if damage < 1 then
		return
	end

	if ragdoll then
		ragdollModule:Ragdoll(enemy)
		if knockback then
			-- Use knockback direction and magnitude for angular impulse
			local angularAxis = knockback.Unit
			local angularStrength = knockback.Magnitude * 2 -- Adjust multiplier as needed
			enemyHumRp:ApplyAngularImpulse(angularAxis * angularStrength)
		else
			-- Fallback if no knockback is provided
			enemyHumRp:ApplyAngularImpulse(Vector3.new(45, 0, 0))
		end
		task.delay(2, function()
			if enemy then
				ragdollModule:unRagdoll(enemy)
			end
		end)
	end

	-- Apply attacker knockback (optional realism)
	if attackerKnockback then
		applyVelocity(attackerHumRp, attackerKnockback, 0.3)
	end

	-- Apply enemy knockback
	if knockback then
		applyVelocity(enemyHumRp, knockback, 0.3)
	end

	-- Apply damage
	if damage then
		enemyHum:TakeDamage(damage)
	end
end

return HitService
