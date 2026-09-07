-- StarterPlayer/StarterPlayerScripts/HudScript.client.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")
local HackSilver = Data:WaitForChild("HackSilver")
local Level = Data:WaitForChild("Level")
local Souls = Data:WaitForChild("Souls")
local MaxSouls = Data:WaitForChild("MaxSouls")

-- Update store with player identification and currency
local function syncPlayerData()
	store:dispatch(function(state)
		state.playerName = LocalPlayer.Name
		state.money = HackSilver.Value
		state.level = Level.Value
		state.souls = Souls.Value
		state.maxSouls = MaxSouls.Value
		return state
	end)
end

HackSilver.Changed:Connect(function(newVal)
	store:dispatch(function(state)
		state.money = newVal
		return state
	end)
end)

Level.Changed:Connect(function(newVal)
	store:dispatch(function(state)
		state.level = newVal
		return state
	end)
end)

local function updateSouls()
	store:dispatch(function(state)
		state.souls = Souls.Value
		state.maxSouls = MaxSouls.Value
		return state
	end)
end

Souls.Changed:Connect(updateSouls)
MaxSouls.Changed:Connect(updateSouls)

-- Character & Humanoid health synchronization
local healthConn = nil
local maxHealthConn = nil
local damageToken = 0

local function syncCombatState()
	store:dispatch(function(state)
		state.inCombat = LocalPlayer:GetAttribute("InCombat") == true
		return state
	end)
end

LocalPlayer:GetAttributeChangedSignal("InCombat"):Connect(syncCombatState)
syncCombatState()

local function setupCharacter(character)
	if healthConn then healthConn:Disconnect() end
	if maxHealthConn then maxHealthConn:Disconnect() end

	local humanoid = character:WaitForChild("Humanoid")
	local previousHealth = humanoid.Health

	local function syncHealth(newHealth)
		local currentHealth = newHealth or humanoid.Health
		local tookDamage = currentHealth < previousHealth
		previousHealth = currentHealth
		store:dispatch(function(state)
			state.health = currentHealth
			state.maxHealth = humanoid.MaxHealth
			if tookDamage then
				state.damageTaken = true
			end
			return state
		end)
		if tookDamage then
			damageToken += 1
			local token = damageToken
			task.delay(0.25, function()
				if token == damageToken then
					store:dispatch(function(state)
						state.damageTaken = false
						return state
					end)
				end
			end)
		end
	end

	healthConn = humanoid.HealthChanged:Connect(syncHealth)
	maxHealthConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(syncHealth)

	syncHealth()
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then
	task.spawn(setupCharacter, LocalPlayer.Character)
end

-- Initial sync
syncPlayerData()
