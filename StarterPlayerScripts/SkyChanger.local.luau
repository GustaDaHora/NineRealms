-- StarterPlayerScripts/SkyChanger.luau

--// Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:WaitForChild("Terrain")
local TweenService = game:GetService("TweenService")

--// References
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local clouds = Terrain:FindFirstChildOfClass("Clouds")
local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
local blur = Lighting:FindFirstChildOfClass("BlurEffect")
local sunrays = Lighting:FindFirstChildOfClass("SunRaysEffect")

--// Configuration
local TRANSITION_DURATION = 2
local DAY_NIGHT_THRESHOLD = { NIGHT_START = 18, NIGHT_END = 6 }

--// Biome Type Map
local BiomeZones = {
	["Deyjaskog"] = "Foggy",
	["Isdalr"] = "Cold",
	["Njord's Eye"] = "Cold",
	["Vargskar Cliffs"] = "Cold",
}

--// Biome Presets
local BiomeSettings = {
	Foggy = {
		Atmosphere = { 
			Density = 0.6, 
			Offset = 1, 
			Color = Color3.fromRGB(70, 90, 110),
			Decay = Color3.fromRGB(40, 55, 75)
		},
		Clouds = { Cover = 1, Density = 1 },
		Brightness = 0.1,
		Bloom = { Intensity = 0.2, Size = 56 },
		Blur = { Size = 2 },
		SunRays = { Intensity = 0.01 }
	},
	Cold = {
		Atmosphere = { 
			Density = 0.4, 
			Offset = 0.5, 
			Color = Color3.fromRGB(230, 245, 255),
			Decay = Color3.fromRGB(150, 200, 240)
		},
		Clouds = { Cover = 0.8, Density = 0.6 },
		Brightness = 1.2,
		Bloom = { Intensity = 0.05, Size = 24 },
		Blur = { Size = 0 },
		SunRays = { Intensity = 0.05 }
	},
	NeutralDay = {
		Atmosphere = { 
			Density = 0.3, 
			Offset = 0, 
			Color = Color3.fromRGB(135, 206, 235),
			Decay = Color3.fromRGB(100, 149, 237)
		},
		Clouds = { Cover = 0.75, Density = 1 },
		Brightness = 2,
		Bloom = { Intensity = 0.05, Size = 24 },
		Blur = { Size = 0 },
		SunRays = { Intensity = 0.1 }
	},
	NeutralNight = {
		Atmosphere = { 
			Density = 0.35, 
			Offset = 0.2, 
			Color = Color3.fromRGB(40, 60, 90),
			Decay = Color3.fromRGB(20, 30, 60)
		},
		Clouds = { Cover = 0.1, Density = 0.2 },
		Brightness = 1,
		Bloom = { Intensity = 0.02, Size = 12 },
		Blur = { Size = 2 },
		SunRays = { Intensity = 0.03 }
	}
}

--// State
local currentZone = nil
local currentIsNight = nil
local activeTweens = {}

--// Utility: Check if night time
local function isNightTime()
	local clock = Lighting.ClockTime
	return clock >= DAY_NIGHT_THRESHOLD.NIGHT_START or clock <= DAY_NIGHT_THRESHOLD.NIGHT_END
end

--// Utility: Determine target settings
local function getTargetSettings(zone)
	local biomeType = BiomeZones[zone]
	local isNight = isNightTime()

	if biomeType then
		return BiomeSettings[biomeType]
	end

	return isNight and BiomeSettings.NeutralNight or BiomeSettings.NeutralDay
end

--// Cancel all active tweens
local function cancelActiveTweens()
	for _, tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	table.clear(activeTweens)
end

--// Apply settings via TweenService
local function transitionToSettings(targetSettings)
	if not targetSettings then return end

	cancelActiveTweens()

	local tweenInfo = TweenInfo.new(
		TRANSITION_DURATION,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)

	-- Atmosphere
	if atmosphere and targetSettings.Atmosphere then
		local tween = TweenService:Create(atmosphere, tweenInfo, {
			Density = targetSettings.Atmosphere.Density,
			Offset = targetSettings.Atmosphere.Offset,
			Color = targetSettings.Atmosphere.Color
		})
		table.insert(activeTweens, tween)
		tween:Play()
	end

	-- Clouds
	if clouds and targetSettings.Clouds then
		local tween = TweenService:Create(clouds, tweenInfo, {
			Cover = targetSettings.Clouds.Cover,
			Density = targetSettings.Clouds.Density
		})
		table.insert(activeTweens, tween)
		tween:Play()
	end

	-- Lighting
	local lightingTween = TweenService:Create(Lighting, tweenInfo, {
		Brightness = targetSettings.Brightness
	})
	table.insert(activeTweens, lightingTween)
	lightingTween:Play()

	-- Bloom
	if bloom and targetSettings.Bloom then
		local tween = TweenService:Create(bloom, tweenInfo, {
			Intensity = targetSettings.Bloom.Intensity,
			Size = targetSettings.Bloom.Size
		})
		table.insert(activeTweens, tween)
		tween:Play()
	end

	-- Blur
	if blur and targetSettings.Blur then
		local tween = TweenService:Create(blur, tweenInfo, {
			Size = targetSettings.Blur.Size
		})
		table.insert(activeTweens, tween)
		tween:Play()
	end

	-- Sun Rays
	if sunrays and targetSettings.SunRays then
		local tween = TweenService:Create(sunrays, tweenInfo, {
			Intensity = targetSettings.SunRays.Intensity
		})
		table.insert(activeTweens, tween)
		tween:Play()
	end
end

--// Update sky based on current state
local function updateSky()
	local zone = character:GetAttribute("Zone")
	local isNight = isNightTime()

	-- Only transition if zone or day/night changed
	if zone == currentZone and isNight == currentIsNight then
		return
	end

	currentZone = zone
	currentIsNight = isNight

	local targetSettings = getTargetSettings(zone)
	transitionToSettings(targetSettings)
end

--// Listen to Zone attribute changes
character:GetAttributeChangedSignal("Zone"):Connect(updateSky)

--// Listen to time changes for day/night cycle
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
	local isNight = isNightTime()
	if isNight ~= currentIsNight then
		updateSky()
	end
end)

--// Initial update
updateSky()