-- Services
local runService = game:GetService("RunService")
local playerService = game:GetService("Players")

-- Constants
local HEAD_HOR_FACTOR = 1
local HEAD_VER_FACTOR = 0.6
local BODY_HOR_FACTOR = 0.5
local BODY_VER_FACTOR = 0.4
local UPDATE_SPEED = 0.25 -- Suavidade da interpolação

-- Player and Character References
local plr = playerService.LocalPlayer
local cam = workspace.CurrentCamera

local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local head = char:FindFirstChild("Head")
local root = char:FindFirstChild("HumanoidRootPart")
local torso = char:FindFirstChild("Torso")
local neck = torso:FindFirstChild("Neck")

-- Ensure necessary parts exist
if not (torso and head and neck) then return end

-- Store Initial C0 Values
local neckC0 = neck.C0

-- Set Neck Constraints for Smooth Rotation
neck.MaxVelocity = 1/3

runService.Heartbeat:Connect(function()
	-- Ensure camera is focusing on the humanoid
	if cam.CameraSubject ~= hum then return end

	local camCF = cam.CFrame
	local headCF = head.CFrame

	-- Calculate the angle differences
	local dist = (headCF.Position - camCF.Position).Magnitude
	if dist == 0 then return end -- Prevent division by zero

	local diff = headCF.Y - camCF.Y
	local asinDiffDist = math.asin(diff / dist) -- Vertical inclination
	local crossProduct = (headCF.Position - camCF.Position).Unit:Cross(torso.CFrame.LookVector)
	local horTilt = crossProduct.Y -- Horizontal tilt

	-- Apply rotations with interpolation
	neck.C0 = neck.C0:Lerp(
		neckC0 * CFrame.Angles(-asinDiffDist * HEAD_VER_FACTOR, 0, -horTilt * HEAD_HOR_FACTOR),
		UPDATE_SPEED
	)
end)
