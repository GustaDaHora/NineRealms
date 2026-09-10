-- NPCInstance.luau
-- Handles a single NPC's lifecycle, state, and cleanup

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local ParticleSummoner = require(ServerStorage.Modules.ParticleSummoner)
local ItemSpawner = require(ServerStorage.Modules.ItemSpawner)
local NPCDumbChaseModule = require(ServerStorage.Modules.npc.NPCDumbChaseModule)
local NPCSmartChaseModule = require(ServerStorage.Modules.npc.NPCSmartChaseModule)

local NPCInstance = {}
NPCInstance.__index = NPCInstance

function NPCInstance.new(npcModel, enemyType, enemyConfig, animations, initialPosition)
	local self = setmetatable({}, NPCInstance)
	self.npc = npcModel
	self.enemyType = enemyType
	self.enemyConfig = enemyConfig
	self.animations = animations
	self.initialPosition = initialPosition
	self.connections = {}
	self.alive = true

	-- Set up per-NPC attributes
	self.npc:SetAttribute("NPCType", enemyType)
	self.npc:SetAttribute("Alive", true)
	self.npc:SetAttribute("NPCId", math.random(1, 1000000))

	-- Initialize chase/behavior module
	if enemyConfig.type == "Smart" then
		NPCSmartChaseModule.InitializeNPC(
			self.npc,
			initialPosition,
			enemyConfig.punchDistance,
			enemyConfig.sound,
			animations,
			enemyConfig.strength,
			enemyConfig.hitboxSize
		)
	else
		NPCDumbChaseModule.InitializeNPC(
			self.npc,
			initialPosition,
			enemyConfig.punchDistance,
			enemyConfig.sound,
			animations,
			enemyConfig.strength,
			enemyConfig.hitboxSize
		)
	end

	-- Connect death handler
	local diedConn = self.npc.Humanoid.Died:Connect(function()
		self:OnDeath()
	end)
	self.connections[#self.connections + 1] = diedConn

	return self
end

function NPCInstance:OnDeath()
	if not self.alive then
		return
	end
	self.alive = false
	self.npc:SetAttribute("Alive", false)

	-- Remove from aliveNPCs handled by spawnhandler

	-- Soul spawning
	local soul = ReplicatedStorage["Will-O-Wisp"]:Clone()
	soul.Position = self.npc.PrimaryPart.Position
	soul.Parent = workspace.SOULS
	ParticleSummoner.EmitParticles("FadeAway", soul, 6, 5)

	-- Destroy all parts except torso for fade effect
	for _, child in pairs(self.npc:GetChildren()) do
		if child.Name ~= "Torso" then
			child:Destroy()
		end
	end

	-- Soul collection
	local soulConn
	soulConn = soul.Touched:Connect(function(part)
		local player = Players:GetPlayerFromCharacter(part.Parent)
		if player then
			if player:FindFirstChild("Data") and player.Data:FindFirstChild("Souls") then
				player.Data.Souls.Value += self.enemyConfig.soulValue
			end
			soul:Destroy()
			soulConn:Disconnect()
		end
	end)
	self.connections[#self.connections + 1] = soulConn

	-- Fade effect
	local fadeOut = TweenService:Create(
		self.npc.Torso,
		TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Transparency = 1 }
	)
	fadeOut:Play()
	fadeOut.Completed:Wait()

	-- Spawn item drops
	ItemSpawner.SpawnItem(self.npc.Torso.Position, self.enemyConfig.dropTable)
	self:Cleanup()
end

function NPCInstance:Cleanup()
	for _, conn in ipairs(self.connections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	self.connections = {}
	if self.npc and self.npc.Parent then
		self.npc:Destroy()
	end
end

return NPCInstance
