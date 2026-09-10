local Settings = {}

local lighting = game:GetService("Lighting")
local bloom = lighting:FindFirstChild("Bloom")
local sunRays = lighting:FindFirstChild("SunRays")
local terrain = workspace:FindFirstChildOfClass("Terrain")

--// GUI References
local MainGui = script.Parent.Parent.Config
local scrollFrame = MainGui:WaitForChild("ScrollingFrame")

function Settings.Start()
	for _, frame in pairs(scrollFrame:GetChildren()) do
		if frame:IsA("Frame") then
			local checkBox = frame:FindFirstChild("CheckBox")
			if checkBox then
				-- Determine if the setting is enabled
				local isEnabled = (frame.Name == "GlobalShadows" and lighting.GlobalShadows)
					or (frame.Name == "BloomEffect" and bloom and bloom.Enabled)
					or (frame.Name == "SunRays" and sunRays and sunRays.Enabled)
					or (frame.Name == "LowerTerrainQuality" and terrain and terrain.WaterReflectance == 0)

				-- Set initial checkbox color based on enabled state
				checkBox.BackgroundColor3 = isEnabled and Color3.fromRGB(99, 209, 68) or Color3.fromRGB(165, 36, 36)

				-- Connect click event to toggle settings
				checkBox.MouseButton1Click:Connect(function()
					if frame.Name == "GlobalShadows" then
						lighting.GlobalShadows = not lighting.GlobalShadows
					elseif frame.Name == "BloomEffect" and bloom then
						bloom.Enabled = not bloom.Enabled
					elseif frame.Name == "SunRays" and sunRays then
						sunRays.Enabled = not sunRays.Enabled
					elseif frame.Name == "LowerTerrainQuality" and terrain then
						-- Toggle Terrain Quality
						local isLowQuality = terrain.WaterReflectance == 0
						terrain.WaterReflectance = isLowQuality and 0.5 or 0
						terrain.WaterWaveSize = isLowQuality and 0.5 or 0
						terrain.WaterWaveSpeed = isLowQuality and 10 or 0
					end

					-- Update CheckBox Color (Green for ON, Red for OFF)
					local newEnabled = (frame.Name == "GlobalShadows" and lighting.GlobalShadows)
						or (frame.Name == "BloomEffect" and bloom and bloom.Enabled)
						or (frame.Name == "SunRays" and sunRays and sunRays.Enabled)
						or (frame.Name == "LowerTerrainQuality" and terrain and terrain.WaterReflectance == 0)

					checkBox.BackgroundColor3 = newEnabled and Color3.fromRGB(99, 209, 68) or Color3.fromRGB(165, 36, 36)
				end)
			end
		end
	end
end

return Settings
