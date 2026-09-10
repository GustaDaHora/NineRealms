-- StarterGui/MainGui/HudScript.client.lua

--// Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--// Tween Info
local TInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)

--// HUD Elements
local GUI = script.Parent
local Hud = GUI:WaitForChild("Hud")
local HealthFill = Hud:WaitForChild("Health"):WaitForChild("Fill")
local HealthText = Hud:WaitForChild("Health"):WaitForChild("TextLabel")
local SoulsFill = Hud:WaitForChild("Souls"):WaitForChild("Fill")
local SoulsText = Hud:WaitForChild("Souls"):WaitForChild("TextLabel")

--// Get Player & Data
local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")
local HackSilver = Data:WaitForChild("HackSilver")
local Level = Data:WaitForChild("Level")
local Souls = Data:WaitForChild("Souls")
local MaxSouls = Data:WaitForChild("MaxSouls")

--// Get Character & Humanoid
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- Set Initial UI Values
Hud.PlayerName.Text = LocalPlayer.Name
Hud.Money.Text = "$" .. HackSilver.Value
Hud.PlayerLevel.Text = Level.Value

-- Update Money Display
HackSilver.Changed:Connect(function()
	Hud.Money.Text = "$" .. HackSilver.Value
end)

-- Update Level Display
Level.Changed:Connect(function()
	Hud.PlayerLevel.Text = Level.Value
end)

-- Update Health Bar Smoothly
local ratio = Humanoid.Health / Humanoid.MaxHealth
local goalSize = UDim2.new(ratio, 0, HealthFill.Size.Y.Scale, 0)
TweenService:Create(HealthFill, TInfo, { Size = goalSize }):Play()
HealthText.Text = math.floor(Humanoid.Health) .. "/" .. math.floor(Humanoid.MaxHealth)

-- Update Health Bar
Humanoid.HealthChanged:Connect(function(health)
	local ratio = Humanoid.Health / Humanoid.MaxHealth
	local goalSize = UDim2.new(ratio, 0, HealthFill.Size.Y.Scale, 0)
	TweenService:Create(HealthFill, TInfo, { Size = goalSize }):Play()
	HealthText.Text = math.floor(Humanoid.Health) .. "/" .. math.floor(Humanoid.MaxHealth)
end)

local function updateSoulsBar()
	local ratio = Souls.Value / MaxSouls.Value
	local goalSize = UDim2.new(ratio, 0, SoulsFill.Size.Y.Scale, 0)
	TweenService:Create(SoulsFill, TInfo, { Size = goalSize }):Play()
	SoulsText.Text = math.floor(Souls.Value) .. "/" .. math.floor(MaxSouls.Value)
end

Souls.Changed:Connect(updateSoulsBar)
MaxSouls.Changed:Connect(updateSoulsBar)
updateSoulsBar() -- Initial update