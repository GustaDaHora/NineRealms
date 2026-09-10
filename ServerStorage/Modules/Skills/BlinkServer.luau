-- SERVER MODULE
local Blink = {}

Blink.Properties = {
	Class = "Mage",
	Weapons = "Any",
	IsPassive = false,
	Cooldown = 5,
	SoulsCost = 50,
	Description = "Quickly teleports, allowing for quick repositioning while invulnerable."
}

-- Services
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local particleSummoner = require(script.Parent.Parent.ParticleSummoner)
local soundManager = require(script.Parent.Parent.SoundManager)
local TI = TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)

local Folder = workspace.CLONES

-- Store currently active clones and tweens per player
local ActiveBlinks = {}

function Blink:Activate(player, direction)
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
	local char = player.Character

	-- Cancel previous Blink if any
	if ActiveBlinks[player] then
		local previous = ActiveBlinks[player]
		if previous.Clone and previous.Clone.Parent then
			previous.Clone:Destroy()
		end
		if previous.Tweens then
			for _, tween in pairs(previous.Tweens) do
				if tween.PlaybackState == Enum.PlaybackState.Playing then
					tween:Cancel()
				end
			end
		end
		for _, v in ipairs(char:GetChildren()) do
			if v.Name == "HumanoidRootPart" then continue end
			if v:IsA("Accessory") then 
				for _, i in ipairs(v:GetDescendants()) do
					if i:IsA("BasePart") or i:IsA("MeshPart") or i:IsA("Handle") and i.Name ~= "HumanoidRootPart" then
						i.Transparency = 0
					end
				end
			end
			if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Handle") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 0
			end
		end
	end

	-- Emit particles
	particleSummoner.EmitParticles("Blink", char.Torso, 1, 0.25)
	particleSummoner.EmitParticles("SideLines", char.Torso, nil, 0.6)

	char.Archivable = true
	local clone = char:Clone()
	local tweens = {}
	
	soundManager.playSound("Blink", char.HumanoidRootPart)
	
	-- Make character transparent
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") then 
			for _, i in ipairs(v:GetDescendants()) do
				if i:IsA("BasePart") or i:IsA("MeshPart") or i:IsA("Handle") and i.Name ~= "HumanoidRootPart" then
					i.Transparency = 1
					local tween = TweenService:Create(i, TI, {Transparency = 0})
					table.insert(tweens, tween)
					task.delay(0.5, function()
						tween:Play()
					end)
				end
			end
		end
		if v.Name ~= "HumanoidRootPart" and (v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Handle")) then
			v.Transparency = 1
			local tween = TweenService:Create(v, TI, {Transparency = 0})
			table.insert(tweens, tween)
			task.delay(0.5, function()
				tween:Play()
			end)
		end
	end

	-- Setup ghost clone
	for _, v in ipairs(clone:GetDescendants()) do
		if v:IsA("LocalScript") or v:IsA("Script") then
			v:Destroy()
		elseif v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("Handle") and v.Name ~= "HumanoidRootPart" then
			v.Anchored = true
			v.CanCollide = false
			v.BrickColor = BrickColor.new("Fossil")
			local ghostTween = TweenService:Create(v, TI, {Transparency = 1})
			table.insert(tweens, ghostTween)
			ghostTween:Play()
		end
	end

	-- Add clone to workspace
	clone.Parent = Folder

	-- Auto-remove ghost clone
	task.delay(0.5, function()
		Debris:AddItem(clone, 0.2)
		particleSummoner.EmitParticles("Blink", char.Torso, 1, 0.25)
	end)

	-- Track this activation
	ActiveBlinks[player] = {
		Clone = clone,
		Tweens = tweens
	}
end

return Blink
