-- UIController/Settings.luau
-- Migrated to React-Luau UIStore architecture

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Lighting:FindFirstChild("Bloom")
local sunRays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Lighting:FindFirstChild("SunRays")
local terrain = Workspace:FindFirstChildOfClass("Terrain")

local Settings = {}

local function applySetting(settingId: string, value: boolean)
	if settingId == "GlobalShadows" then
		Lighting.GlobalShadows = value
	elseif settingId == "BloomEffect" and bloom then
		bloom.Enabled = value
	elseif settingId == "SunRays" and sunRays then
		sunRays.Enabled = value
	elseif settingId == "LowerTerrainQuality" and terrain then
		terrain.WaterReflectance = value and 0 or 0.5
		terrain.WaterWaveSize = value and 0 or 0.5
		terrain.WaterWaveSpeed = value and 0 or 10
	end
end

function Settings.Start()
	-- Read current engine states
	local initialShadows = Lighting.GlobalShadows
	local initialBloom = bloom and bloom.Enabled or true
	local initialSunRays = sunRays and sunRays.Enabled or true
	local initialLowTerrain = terrain and (terrain.WaterReflectance == 0) or false

	-- Initialize store config
	store:dispatch(function(state)
		state.config = {
			GlobalShadows = initialShadows,
			BloomEffect = initialBloom,
			SunRays = initialSunRays,
			LowerTerrainQuality = initialLowTerrain,
		}
		return state
	end)

	-- Track last known config to only apply changes
	local lastConfig = {
		GlobalShadows = initialShadows,
		BloomEffect = initialBloom,
		SunRays = initialSunRays,
		LowerTerrainQuality = initialLowTerrain,
	}

	store:subscribe(function(newState)
		local currentCfg = newState.config or {}
		for key, val in pairs(currentCfg) do
			if lastConfig[key] ~= val then
				lastConfig[key] = val
				applySetting(key, val)
			end
		end
	end)
end

return Settings
