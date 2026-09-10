-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- Day-Night Cycle Settings
local dayDuration = 60 * 15 -- 15 minutes for the day
local nightDuration = 60 * 7 -- 7 minutes for the night
local totalMinutesInDay = 24 * 60 -- Total in-game minutes in a day

-- Lighting Time Ranges
local dayStartTime = 6 * 60 -- 6:00 AM
local nightStartTime = 18 * 60 -- 6:00 PM

-- State Variables
local currentPhase = "Day" -- Start with "Day"
local timeScale = 1 -- Multiplier for time speed

-- Function to calculate time scale for the current phase
local function updateTimeScale()
	if currentPhase == "Day" then
		timeScale = (12 * 60) / dayDuration -- 12 in-game hours for the day
	else
		timeScale = (12 * 60) / nightDuration -- 12 in-game hours for the night
	end
end

-- Update time scale for the starting phase
updateTimeScale()

-- Heartbeat Connection
RunService.Heartbeat:Connect(function(deltaTime)
	-- Increment the in-game time by the scaled deltaTime
	local newTime = Lighting:GetMinutesAfterMidnight() + (deltaTime * timeScale)

	-- Handle day-night transitions
	if currentPhase == "Day" and newTime >= nightStartTime then
		currentPhase = "Night"
		updateTimeScale()
	elseif currentPhase == "Night" and newTime >= totalMinutesInDay then
		currentPhase = "Day"
		newTime = newTime % totalMinutesInDay -- Reset to the next day
		updateTimeScale()
	end

	-- Apply the updated time to Lighting
	Lighting:SetMinutesAfterMidnight(newTime)
end)
