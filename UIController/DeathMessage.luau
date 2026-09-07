-- UIController/DeathMessage.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local DeathMessage = {}

local deathSound = script:FindFirstChild("DeathSound")
local heartbeatSound = script:FindFirstChild("Heartbeat")

local function getRespawnRemote()
	local re = ReplicatedStorage:FindFirstChild("RE")
	local others = re and re:FindFirstChild("Others")
	return others and others:FindFirstChild("RespawnRE")
end

local isRespawning = false

local function handleRespawn()
	if isRespawning then return end
	isRespawning = true

	if heartbeatSound then
		local snd = heartbeatSound:Clone()
		snd.Parent = player:WaitForChild("PlayerGui")
		snd:Play()
		game:GetService("Debris"):AddItem(snd, 3)
	end

	local respawnRE = getRespawnRemote()
	if respawnRE then
		respawnRE:FireServer()
	end

	task.wait(1)

	store:dispatch(function(state)
		state.isDead = false
		state.deathPhase = "inactive"
		state.health = state.maxHealth or 100
		return state
	end)

	UserInputService.MouseIconEnabled = true
	isRespawning = false
end

local function setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	isRespawning = false

	humanoid.Died:Connect(function()
		if isRespawning then return end

		if deathSound then
			deathSound:Play()
		end

		store:dispatch(function(state)
			state.isDead = true
			state.deathPhase = "playing"
			return state
		end)

		-- Give time for visual skull sequence before enabling click
		task.delay(1.5, function()
			store:dispatch(function(state)
				if state.isDead then
					state.deathPhase = "complete"
				end
				return state
			end)
		end)
	end)
end

function DeathMessage.Start()
	-- Register respawn callback on UIStore
	store:dispatch(function(state)
		state.onRespawn = handleRespawn
		return state
	end)

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

return DeathMessage
