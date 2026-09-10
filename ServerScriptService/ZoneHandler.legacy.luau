task.wait(5)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Areas/Zones
local areaParts = {
	-- Core Regions
	["Bergdalr"] = workspace.Areas.Bergdalr.Bergdalr,
	["Klipprug Peaks"] = workspace.Areas.Klipprug["Klipprug Peaks"],
	["Klipprug Caves"] = workspace.Areas.Klipprug["Klipprug Caves"],
	["Vetrgardr"] = workspace.Areas.Vetrgardr.Vetrgardr,
	["Hegrholt"] = workspace.Areas.Hegrholt.Hegrholt,

	-- Hostile Biomes
	["Deyjaskog"] = workspace.Areas.Deyjaskog.Deyjaskog,

	-- Cold Areas
	["Isdalr"] = workspace.Areas.Isdalr.Isdalr,
	["Njord's Eye"] = workspace.Areas["Njord's Eye"]["Njord's Eye"],
}


local isPlayerInsideArea = {}

-- Function to check if a player is inside a specific part
local function isPlayerInPart(player, part)
	if not part then return false end -- Prevent nil error

	local character = player.Character
	if character and character.PrimaryPart then
		local position = character.PrimaryPart.Position
		local relativePosition = part.CFrame:PointToObjectSpace(position)
		local halfSize = part.Size / 2

		return (math.abs(relativePosition.X) <= halfSize.X) and
			(math.abs(relativePosition.Y) <= halfSize.Y) and
			(math.abs(relativePosition.Z) <= halfSize.Z)
	end
	return false
end

-- Function to update each player's zone
local function updatePlayerZones()
	for _, player in ipairs(Players:GetPlayers()) do
		local previousZone = isPlayerInsideArea[player]
		local newZone = "Wilderness" -- Default zone

		for zoneName, part in pairs(areaParts) do
			if isPlayerInPart(player, part) then
				newZone = zoneName
				break -- No need to check further if the player is in a zone
			end
		end

		if previousZone ~= newZone then
			isPlayerInsideArea[player] = newZone
			local character = player.Character
			if character then
				character:SetAttribute("Zone", newZone)
			end
		end
	end
end

-- Run the update function every second (optimized for performance)
task.spawn(function()
	while task.wait(2) do
		updatePlayerZones()
	end
end)
