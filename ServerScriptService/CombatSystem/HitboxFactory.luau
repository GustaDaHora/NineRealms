--// ServerScriptService/CombatSystem/HitboxFactory.luau
local HitboxFactory = {}

local ss = game:GetService("ServerStorage")
local modules = ss:WaitForChild("Modules")

-- Lazy load modules to avoid circular dependencies or load order issues
local HitboxModule
local RaycastHitboxModule

local function getHitboxModule()
	if not HitboxModule then
		HitboxModule = require(modules.Hitbox)
	end
	return HitboxModule
end

local function getRaycastHitboxModule()
	if not RaycastHitboxModule then
		RaycastHitboxModule = require(modules.RaycastHitbox)
	end
	return RaycastHitboxModule
end

-- Wrapper class for Spatial Hitbox (Gauntlet)
local SpatialHitboxWrapper = {}
SpatialHitboxWrapper.__index = SpatialHitboxWrapper

function SpatialHitboxWrapper.new(config, player, char)
	local self = setmetatable({}, SpatialHitboxWrapper)
	local Hitbox = getHitboxModule()

	self.hitbox = Hitbox.new({
		Size = config.Size,
		CFrame = char.HumanoidRootPart,
		Offset = config.Offset,
		Visualizer = false,
		OwnerPlayer = player,
		onTouch = config.OnTouch,
	})

	return self
end

function SpatialHitboxWrapper:Start(ignoreList)
	if self.hitbox then
		self.hitbox:Start():AddToIgnoreList(unpack(ignoreList))
	end
end

function SpatialHitboxWrapper:Stop()
	if self.hitbox then
		self.hitbox:Stop()
	end
end

function SpatialHitboxWrapper:Destroy()
	self:Stop()
	self.hitbox = nil
end

-- Wrapper class for Raycast Hitbox (Sword/Axe)
local RaycastHitboxWrapper = {}
RaycastHitboxWrapper.__index = RaycastHitboxWrapper

function RaycastHitboxWrapper.new(tool, onHitCallback)
	local self = setmetatable({}, RaycastHitboxWrapper)
	local RaycastHitbox = getRaycastHitboxModule()

	local hitBoxPart = tool:WaitForChild("Hitbox")
	self.hitbox = RaycastHitbox.new(hitBoxPart)

	self.connection = self.hitbox.OnHit:Connect(function(hit, hitHumanoid)
		if onHitCallback then
			onHitCallback(hitHumanoid)
		end
	end)

	return self
end

function RaycastHitboxWrapper:Start(ignoreList)
	-- RaycastHitbox usually handles ignore list via params or filter,
	-- but legacy script didn't explicitly set ignore list on Start,
	-- it just checked `if hitHumanoid == hum then return end` in the callback.
	-- We will rely on the callback check for consistency with legacy.
	if self.hitbox then
		self.hitbox:HitStart()
	end
end

function RaycastHitboxWrapper:Stop()
	if self.hitbox then
		self.hitbox:HitStop()
	end
end

function RaycastHitboxWrapper:Destroy()
	self:Stop()
	if self.connection then
		self.connection:Disconnect()
	end
	self.hitbox = nil
end

-- Factory Method
function HitboxFactory.Create(type, params)
	if type == "Spatial" then
		return SpatialHitboxWrapper.new(params.Config, params.Player, params.Character)
	elseif type == "Raycast" then
		return RaycastHitboxWrapper.new(params.Tool, params.OnHit)
	else
		warn("Unknown Hitbox Type: " .. tostring(type))
		return nil
	end
end

return HitboxFactory
