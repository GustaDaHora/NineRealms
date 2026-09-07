-- UIController/Zone.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local LocalZones = {
	["Wilderness"] = { pvp = false, description = "An Area in Which Plants Are Left to Grow Naturally and Untidily." },
	["Bergdalr"] = { pvp = false, description = "A Humble Village, Heart of Midgard's Frontier." },
	["Kornhavn"] = { pvp = false, description = "A Vast Wheat Field Where the Wind Stirs the Windmill's Sails." },
	["Deyjaskog"] = { pvp = true, description = "A Lifeless Forest Shrouded in Dense Fog." },
	["Isdalr"] = { pvp = true, description = "A Frozen Valley Echoing with the Wind." },
	["Veidiskog"] = { pvp = true, description = "A Dense and Ancient Forest Teeming with Wildlife." },
	["Ravencall Encampment"] = { pvp = true, description = "The Festering Den of the Ravencall Scum." },
}

local zoneModule = {}
local activeZoneToken = 0

local function announceZone(currentZone: string)
	local zoneInfo = LocalZones[currentZone] or {
		pvp = false,
		description = "A mysterious unmapped territory.",
	}

	activeZoneToken += 1
	local myToken = activeZoneToken

	local displayName = currentZone .. (zoneInfo.pvp and " - PvP On" or " - PvP Off")

	store:dispatch(function(state)
		state.currentZone = displayName
		state.zoneDescription = zoneInfo.description or ""
		return state
	end)

	-- Auto-fade out after 4 seconds
	task.delay(4, function()
		if activeZoneToken == myToken then
			store:dispatch(function(state)
				if state.currentZone == displayName then
					state.currentZone = ""
					state.zoneDescription = ""
				end
				return state
			end)
		end
	end)
end

local function setupCharacter(char: Model)
	char:GetAttributeChangedSignal("Zone"):Connect(function()
		local currentZone = char:GetAttribute("Zone")
		if currentZone and currentZone ~= "" then
			announceZone(currentZone)
		end
	end)

	local initialZone = char:GetAttribute("Zone")
	if initialZone and initialZone ~= "" then
		announceZone(initialZone)
	end
end

function zoneModule.Start()
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

return zoneModule