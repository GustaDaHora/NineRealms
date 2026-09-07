-- DEFAULT SOUND DELETER
local player = game:GetService("Players").LocalPlayer
local starterGui = game:GetService("StarterGui")
local char = player.Character
local runningSound = char:WaitForChild("HumanoidRootPart"):WaitForChild("Running", 10)
if runningSound then runningSound:Destroy() end

-- PROXIMITY DELETER
script.Parent:WaitForChild("HumanoidRootPart").ChildAdded:Connect(function(child)
	if child.Name == "SavePrompt" then
		child:Destroy()
	end
end)

starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.SelfView, false)
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)

local humanoid = char:WaitForChild("Humanoid", 10)
if humanoid then
	humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
end
