local Map = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local isMapActive = false
local camera = workspace.CurrentCamera
local mapHeight = 200 -- How high the camera goes
local ti = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateMapCamera()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	character:SetAttribute("Frozen")

	-- Tween to map view smoothly
	local targetCFrame = CFrame.new(humanoidRootPart.Position + Vector3.new(0, mapHeight, 0), humanoidRootPart.Position)
	local tween = TweenService:Create(camera, ti, {CFrame = targetCFrame})
	tween:Play()
	tween.Completed:Wait()
end

local function resetCamera()
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Tween back to normal camera smoothly
	local tween = TweenService:Create(camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = character.Head.CFrame})
	tween:Play()

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
end

local function toggleMapView()
	if isMapActive then
		resetCamera()
	else
		camera.CameraType = Enum.CameraType.Scriptable
		updateMapCamera()
	end

	isMapActive = not isMapActive
end

function Map.Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.M then
			toggleMapView()
		end
	end)
end

return Map
