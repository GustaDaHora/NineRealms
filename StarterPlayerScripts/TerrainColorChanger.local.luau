-- StarterPlayerScripts/TerrainColorChanger.luau

--// Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Terrain = workspace:WaitForChild("Terrain")

--// References
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

--// Configuration
local TRANSITION_DURATION = 3

--// Biome Type Map
local BiomeZones = {
	["Deyjaskog"] = "Foggy",
	["Isdalr"] = "Cold",
	["Njord's Eye"] = "Cold",
	["Vargskar Cliffs"] = "Cold",
}

--// Biome Settings
local BiomeSettings = {
	Neutral = {
		Grass = Color3.fromRGB(73, 76, 57),
		Ground = Color3.fromRGB(84, 84, 85),
		LeafyGrass = Color3.fromRGB(108, 116, 104),
		Mud = Color3.fromRGB(80, 80, 80),
		Rock = Color3.fromRGB(58, 66, 77),
		Snow = Color3.fromRGB(255, 255, 255)
	},
	Cold = {
		Grass = Color3.fromRGB(183, 200, 174),
		Ground = Color3.fromRGB(194, 200, 235),
		LeafyGrass = Color3.fromRGB(184, 200, 216),
		Mud = Color3.fromRGB(160, 184, 200),
		Rock = Color3.fromRGB(125, 140, 171),
		Snow = Color3.fromRGB(207, 229, 255)
	},
	Foggy = {
		Grass = Color3.fromRGB(90, 111, 90),
		Ground = Color3.fromRGB(107, 91, 79),
		LeafyGrass = Color3.fromRGB(122, 138, 122),
		Mud = Color3.fromRGB(79, 64, 51),
		Rock = Color3.fromRGB(90, 90, 90),
		Snow = Color3.fromRGB(216, 224, 232)
	}
}

--// Material Enum Mapping
local MaterialMap = {
	Grass = Enum.Material.Grass,
	Ground = Enum.Material.Ground,
	LeafyGrass = Enum.Material.LeafyGrass,
	Mud = Enum.Material.Mud,
	Rock = Enum.Material.Rock,
	Snow = Enum.Material.Snow
}

--// State
local currentZone = nil
local activeTweens = {}

--// Lerp function for color interpolation
local function lerpColor(start, target, alpha)
	return Color3.new(
		start.R + (target.R - start.R) * alpha,
		start.G + (target.G - start.G) * alpha,
		start.B + (target.B - start.B) * alpha
	)
end

--// Get target settings based on zone
local function getTargetSettings(zone)
	local biomeType = BiomeZones[zone]
	return biomeType and BiomeSettings[biomeType] or BiomeSettings.Neutral
end

--// Cancel active tweens
local function cancelActiveTweens()
	for _, tween in pairs(activeTweens) do
		if tween then
			tween:Cancel()
		end
	end
	table.clear(activeTweens)
end

--// Transition terrain colors
local function transitionToSettings(targetSettings)
	if not targetSettings then return end

	cancelActiveTweens()

	local startTime = tick()
	local startColors = {}

	-- Store initial colors
	for materialName, material in pairs(MaterialMap) do
		startColors[materialName] = Terrain:GetMaterialColor(material)
	end

	-- Create transition
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local alpha = math.min(elapsed / TRANSITION_DURATION, 1)

		-- Apply easing (Sine InOut)
		alpha = alpha < 0.5 
			and 2 * alpha * alpha 
			or 1 - math.pow(-2 * alpha + 2, 2) / 2

		-- Interpolate each material
		for materialName, material in pairs(MaterialMap) do
			if targetSettings[materialName] then
				local newColor = lerpColor(
					startColors[materialName],
					targetSettings[materialName],
					alpha
				)
				Terrain:SetMaterialColor(material, newColor)
			end
		end

		-- Cleanup when complete
		if alpha >= 1 then
			connection:Disconnect()
		end
	end)

	table.insert(activeTweens, { Cancel = function() connection:Disconnect() end })
end

--// Update terrain colors
local function updateTerrainColors()
	local zone = character:GetAttribute("Zone")

	if zone == currentZone then return end

	currentZone = zone
	local targetSettings = getTargetSettings(zone)
	transitionToSettings(targetSettings)
end

--// Listen to Zone attribute changes
character:GetAttributeChangedSignal("Zone"):Connect(updateTerrainColors)

--// Initial update
updateTerrainColors()