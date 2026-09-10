-- FallenHandler ServerScript
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

-- Animation for the "Fallen" state
local fallenAnim = RS.Animations.Others.Fallen
local ragdollModule = require(RS:WaitForChild("Modules"):WaitForChild("RagdollModule"))

-- Track which players have already had a soul spawned
local soulSpawned = {}

-- Function to handle being saved
local function beSaved(player, character)
	if not character or not character:GetAttribute("Fallen") then
		return
	end
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		character:SetAttribute("Fallen", false)

		-- Stop the animation
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track.Animation.AnimationId == fallenAnim.AnimationId then
					track:Stop()
				end
			end
		end
	end

	-- Remove the save prompt
	local prompt = character:FindFirstChild("SavePrompt")
	if prompt then
		prompt:Destroy()
	end
end

-- Function to put the player in the "Fallen" state
local function enterFallenState(player, character)
	if not character then
		return
	end
	if character:GetAttribute("Fallen") then
		return
	end -- Prevent duplicate fallen state

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		character:SetAttribute("Fallen", true)
		local health = character:FindFirstChild("Health")
		if health then
			health.Enabled = true
		end

		-- Stop all animations
		local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop()
		end

		-- Play fallen animation
		local fallenTrack = animator:LoadAnimation(fallenAnim)
		fallenTrack:Play()

		-- Add a ProximityPrompt for saving
		local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		if rootPart then
			local prompt = Instance.new("ProximityPrompt")
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.Name = "SavePrompt"
			prompt.ActionText = "Save Player"
			prompt.ObjectText = "Fallen Player"
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = 10
			prompt.Parent = rootPart

			-- Handle the prompt interaction
			prompt.Triggered:Connect(function(saver)
				if saver and saver.Character and saver ~= player then
					beSaved(player, character)
				end
			end)
		end

		-- Auto-save after 20 seconds
		task.delay(20, function()
			if character and character:GetAttribute("Fallen") then
				beSaved(player, character)
			end
		end)
	end
end

-- Create a soul for the dead player
local function createSoul(player, character)
	-- Check if a soul was already spawned for this death
	if soulSpawned[player.UserId] then
		return
	end
	soulSpawned[player.UserId] = true

	-- Create and handle soul effect
	local soul = game.ReplicatedStorage:FindFirstChild("Will-O-Wisp")
	if soul then
		local hum = character.HumanoidRootPart.Position
		if hum then
			soul = soul:Clone()
			soul.Position = hum
			soul.Parent = workspace:FindFirstChild("SOULS") or workspace

			-- Emit particle effect
			local particleSummoner = require(game.ServerStorage.Modules.ParticleSummoner)
			particleSummoner.EmitParticles("FadeAway", soul, 6, 5)

			-- Handle soul touching another player
			soul.Touched:Connect(function(part)
				local enemy = Players:GetPlayerFromCharacter(part.Parent)

				if enemy and enemy ~= player then
					local enemyData = enemy:FindFirstChild("Data")
					local playerData = player:FindFirstChild("Data")

					if enemyData and playerData then
						local enemySouls = enemyData:FindFirstChild("Souls")
						local enemyMaxSouls = enemyData:FindFirstChild("MaxSouls")
						local playerSouls = playerData:FindFirstChild("Souls")

						if enemySouls and enemyMaxSouls and playerSouls then
							if enemySouls.Value + 10 > enemyMaxSouls.Value then
								enemySouls.Value = enemyMaxSouls.Value
							else
								enemySouls.Value += 10
							end
							if playerSouls.Value - 10 > 0 then
								playerSouls.Value -= 10
							else
								playerSouls.Value = 0
							end
						end
					end
					soul:Destroy()
				end
			end)

			-- Clear the flag when the player respawns (also handled in onCharacterAdded)
			task.delay(3, function()
				soulSpawned[player.UserId] = nil
			end)
		end
	end
end

-- Monitor health to trigger "Fallen" state
local function onCharacterAdded(player, character)
	-- Clear soul spawned flag for this player when they get a new character
	soulSpawned[player.UserId] = nil

	-- Set default attributes
	character:SetAttribute("Fallen", false)

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		if character:GetAttribute("Fallen") then
			-- Player died while in fallen state
			beSaved(player, character)
		end
		ragdollModule:Ragdoll(character)

		-- Create soul only if not already created
		createSoul(player, character)
	end)

	humanoid.HealthChanged:Connect(function(health)
		if health <= 0 then
			-- Health is zero, let the Died event handle it
			return
		elseif health <= 10 and not character:GetAttribute("Fallen") then
			enterFallenState(player, character)
		elseif health > 10 and character:GetAttribute("Fallen") then
			beSaved(player, character)
		end
	end)
end

-- Player added function
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Handle existing character
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

-- Connect player join event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle players already in the game when the script starts
for _, player in pairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
