local TweenService = game:GetService("TweenService")
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")
local plr = game.Players:GetPlayerFromCharacter(Character)
local stats = plr:WaitForChild("Stats")
local plrVitality = stats:WaitForChild("Vitality")
--------------------------------------------------------------------------------
-- CONFIGURABLE VALUES
--------------------------------------------------------------------------------
local DEBOUNCE_TIME = 4 -- Delay before regen starts after taking damage
--------------------------------------------------------------------------------
local previousHealth = Humanoid.Health -- Track actual health, not MaxHealth
local lastDamageTime = 0
local combatIndicator = plr.PlayerGui:FindFirstChild("MainGui")
	and plr.PlayerGui.MainGui:FindFirstChild("CombatIndicator")

local function setCombatState(active)
	if combatIndicator then
		combatIndicator.Visible = active
	end
	if active then
		if not plr:GetAttribute("InCombat") then
			plr:SetAttribute("InCombat", true)
		end
	else
		if plr:GetAttribute("InCombat") then
			plr:SetAttribute("InCombat", nil)
		end
	end
end

local function onHealthChanged(newHealth)
	if newHealth < Humanoid.MaxHealth then
		if newHealth < previousHealth then -- Player took damage
			local damageAmount = previousHealth - newHealth -- Calculate damage taken
			lastDamageTime = tick() -- Register last time they were damaged
			local damagePercentage = (damageAmount / Humanoid.MaxHealth) * 100
			local remainingHealthPercentage = newHealth / Humanoid.MaxHealth
			local healthMultiplier = 1 + (1 - remainingHealthPercentage) * 1.5 -- Boosts intensity as health drops
			local particleCount = math.clamp(math.floor((damagePercentage / 5) * healthMultiplier), 2, 20)

			if damagePercentage >= 25 or remainingHealthPercentage < 0.49 then
				-- Heavy Bleed
				require(game.ServerStorage.Modules.ParticleSummoner).EmitParticles(
					"Bleed2",
					Character.HumanoidRootPart,
					particleCount,
					1
				)
			else
				require(game.ServerStorage.Modules.ParticleSummoner).EmitParticles(
					"Bleed",
					Character.HumanoidRootPart,
					particleCount,
					1
				)
			end
			setCombatState(true)
			task.spawn(function()
				task.wait(DEBOUNCE_TIME)
				if tick() - lastDamageTime >= DEBOUNCE_TIME then
					setCombatState(false)
				end
			end)
		end
	end
	previousHealth = newHealth -- Always update to track changes
end

Humanoid.HealthChanged:Connect(onHealthChanged)