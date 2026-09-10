local DamageGui = {}
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Function to summon and animate the BillboardGui
function DamageGui.summonDamageGui(target, damageAmount, damageType)
	-- Get the BillboardGui from ReplicatedStorage
	local billboardTemplate = ReplicatedStorage.Damages[damageType]
	
	-- Clone the BillboardGui and set it up
	local billboardGui = billboardTemplate:Clone()
	local targetRootPart = target:FindFirstChild("HumanoidRootPart")
	billboardGui.Adornee = targetRootPart
	if not billboardGui.Adornee then
		warn("Target does not have a HumanoidRootPart!")
		return
	end
	billboardGui.Parent = targetRootPart
	billboardGui.AlwaysOnTop = true

	-- Set the damage text
	local textLabel = billboardGui:FindFirstChild("Damage")
	if textLabel then
		if damageType == "Crit" then
			textLabel.Text = tostring(damageAmount) .. "!"
		else
			textLabel.Text = tostring(damageAmount)
		end
	else
		warn("TextLabel not found in BillboardGui!")
		return
	end

	-- Start the animation
	local startOffset = Vector3.new(0, -3, 0) -- Starting position (off-screen)
	local endOffset = Vector3.new(0, 2, 0) -- Ending position (visible above the target)
	billboardGui.StudsOffset = startOffset

	local tweenInfo = TweenInfo.new(
		1, -- Duration
		Enum.EasingStyle.Bounce, -- Style
		Enum.EasingDirection.Out -- Direction
	)
	local tween = TweenService:Create(billboardGui, tweenInfo, {StudsOffset = endOffset})
	tween:Play()

	-- Add to debris after 2 seconds
	Debris:AddItem(billboardGui, 2)
end

return DamageGui
