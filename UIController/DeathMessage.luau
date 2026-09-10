-- Client Module Script
local DeathMessage = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ScreenGui = script.Parent.Parent
local DeathFrame = ScreenGui.DeathMessageFrame
local Skull1 = DeathFrame.Skull1
local Skull2 = DeathFrame.Skull2
local RespawnRE = game.ReplicatedStorage:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("RespawnRE")
local TextButton = DeathFrame.TextButton
local Light = ScreenGui.Light
local HeartbeatSound = script.Heartbeat

local isRespawning = false

DeathFrame.Visible = false

local BackgroundTweenInfo = TweenInfo.new(5)
local BackgroundGoal = {BackgroundColor3 = Color3.fromRGB(0, 0, 0)}

local Skull1TweenInfo1 = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local Skull1Goals1 = {Size = UDim2.new(0.133, 0, 0.305, 0), ImageTransparency = 0.3}

local Skull1TweenInfo2 = TweenInfo.new(1.5)
local Skull1Goals2 = {Size = UDim2.new(0.126, 0, 0.29, 0)}

local Skull1TweenInfo3 = TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
local Skull1Goals3 = {Size = UDim2.new(0.001, 0, 0.132, 0), ImageColor3 = Color3.fromRGB(127, 0, 0), ImageTransparency = 1}

local Skull1TweenInfo4 = TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local Skull1Goals4 = {ImageTransparency = 1}

local Skull2TweenInfo = TweenInfo.new(5, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
local Skull2Goals = {Size = UDim2.new(0.001, 0, 0.132, 0), ImageTransparency = 0.3}

local Skull2TweenInfoFinal = TweenInfo.new(2)
local Skull2GoalsFinal = {ImageTransparency = 1}

local GlobalTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local RestartText = DeathFrame.RestartText

local function resetDeathScreen()
	Light.BackgroundTransparency = 1
	DeathFrame.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
	DeathFrame.Visible = false
	DeathFrame.GroupTransparency = 0

	Skull1.ImageColor3 = Color3.fromRGB(83, 20, 20)
	RestartText.Position = UDim2.new(0.5, 0,0.532, 0)
	RestartText.Text = "Restart your heartbeat."
	Skull1.Size = UDim2.new(0.243, 0,0.544, 0)
	Skull2.Size = UDim2.new(0.133, 0,0.305, 0)
	RestartText.TextTransparency = 1
end

local function handleDeath()
	if isRespawning then
		return
	end

	RestartText.Position = UDim2.new(0.5, 0,0.532, 0)
	RestartText.Text = "Restart your heartbeat."
	Skull1.Size = UDim2.new(0.243, 0,0.544, 0)
	Skull2.Size = UDim2.new(0.133, 0,0.305, 0)
	RestartText.TextTransparency = 1
	Light.BackgroundTransparency = 1
	DeathFrame.Visible = true

	game:GetService("UserInputService").MouseIconEnabled = false
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	script.DeathSound:Play()

	local BackgroundTween = TweenService:Create(DeathFrame, BackgroundTweenInfo, BackgroundGoal)
	BackgroundTween:Play()

	local Skull1Tween1 = TweenService:Create(Skull1, Skull1TweenInfo1, Skull1Goals1)
	Skull1Tween1:Play()
	Skull1Tween1.Completed:Wait()

	local Skull1Tween2 = TweenService:Create(Skull1, Skull1TweenInfo2, Skull1Goals2)
	Skull1Tween2:Play()
	Skull1Tween2.Completed:Wait()

	local Skull1Tween3 = TweenService:Create(Skull1, Skull1TweenInfo3, Skull1Goals3)
	local Skull2Tween = TweenService:Create(Skull2, Skull2TweenInfo, Skull2Goals)
	Skull1Tween3:Play()
	Skull2Tween:Play()

	TweenService:Create(DeathFrame.YDText, GlobalTweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(DeathFrame.YDText.UIStroke, GlobalTweenInfo, {Transparency = 0}):Play()
	TweenService:Create(DeathFrame.RestartText, GlobalTweenInfo, {TextTransparency = 0}):Play()

	local Skull1Tween4 = TweenService:Create(Skull1, Skull1TweenInfo4, Skull1Goals4)
	local Skull2TweenFinal = TweenService:Create(Skull2, Skull2TweenInfoFinal, Skull2GoalsFinal)
	Skull1Tween4:Play()
	Skull2TweenFinal:Play()

	wait(1)

	TextButton.Visible = true
end

local canClick = true

TextButton.MouseButton1Click:Connect(function()
	if not canClick then return end
	canClick = false
	isRespawning = true

	RestartText.Position = UDim2.new(0.5, 0,0.5, 0)
	DeathFrame.YDText.TextTransparency = 1
	DeathFrame.YDText.UIStroke.Transparency = 1

	RestartText.Text = "Death? What is death?"

	local heartbeatClone = HeartbeatSound:Clone()
	heartbeatClone.Parent = script.Parent
	heartbeatClone.Looped = true
	heartbeatClone:Play()

	TextButton.Visible = false

	TweenService:Create(Light, TweenInfo.new(2), {BackgroundTransparency = 0}):Play()
	isRespawning = false
	wait(2)
	TweenService:Create(ScreenGui.Light, TweenInfo.new(2), {BackgroundTransparency = 1}):Play()
	DeathFrame.Visible = false
	game:GetService("UserInputService").MouseIconEnabled = true

	Skull1.ImageColor3 = Color3.fromRGB(83, 20, 20)
	RestartText.Position = UDim2.new(0.5, 0,0.532, 0)
	RestartText.Text = "Restart your heartbeat."
	Skull1.Size = UDim2.new(0.243, 0,0.544, 0)
	Skull2.Size = UDim2.new(0.133, 0,0.305, 0)
	RestartText.TextTransparency = 1

	RespawnRE:FireServer()
	DeathFrame.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
end)

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	canClick = true

	humanoid.Died:Connect(function()
		if isRespawning then
			resetDeathScreen()
		end

		handleDeath()
	end)
end

function DeathMessage.Start()
	player.CharacterAdded:Connect(setupCharacter)

	if player.Character then
		setupCharacter(player.Character)
	end
end

return DeathMessage
