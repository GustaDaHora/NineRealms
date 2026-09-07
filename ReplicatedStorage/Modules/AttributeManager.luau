-- ReplicatedStorage/Modules/AttributeManager.lua
local AttributeManager = {}

local PRIORITY_ORDER = {
	"Fallen",
	"Resting",
	"Chatting",
	"Frozen",
	"Stunned",
	"Blocking",
	"HeavySlow",
	"Slowed",
	"LightSlow",
	"Normal",
}

local DEFAULTS = {
	Normal = {
		WalkSpeed = 12,
		JumpPower = 50,
	},
	LightSlow = {
		WalkSpeed = 10,
		JumpPower = 0,
	},
	Slowed = {
		WalkSpeed = 9,
		JumpPower = 0,
	},
	Blocking = {
		WalkSpeed = 5,
		JumpPower = 0,
	},
	HeavySlow = {
		WalkSpeed = 5,
		JumpPower = 0,
	},
	Stunned = {
		WalkSpeed = 2,
		JumpPower = 0,
	},
	Frozen = {
		WalkSpeed = 0,
		JumpPower = 0,
	},
	Fallen = {
		WalkSpeed = 0,
		JumpPower = 0,
	},
	Chatting = {
		WalkSpeed = 0,
		JumpPower = 0,
	},
	Resting = {
		WalkSpeed = 0,
		JumpPower = 0,
	},
}

-- Apply attribute effects to the character
function AttributeManager.applyAttributes(char, ignoreSpeed)
	local hum = char:FindFirstChild("Humanoid")
	if not hum then
		return
	end

	local activeAttribute = nil
	for _, attr in ipairs(PRIORITY_ORDER) do
		if attr == "Normal" or char:GetAttribute(attr) then
			activeAttribute = attr
			break
		end
	end

	local defaults = DEFAULTS[activeAttribute or "Normal"]

	if not ignoreSpeed then
		hum.WalkSpeed = defaults.WalkSpeed
	end

	hum.JumpPower = defaults.JumpPower
end

return AttributeManager
