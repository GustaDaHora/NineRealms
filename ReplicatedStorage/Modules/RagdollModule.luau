--// Services
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

--// Modules
local RagdollModule = {}
RagdollModule.PlayersCollisionGroup = "Players" -->> idk, if u have another name for the players collision group just change it
RagdollModule.CanCollide = false -->> set true if you want the parts to collide with each other

-- Ensure both collision groups are registered before setting collidability
if not PhysicsService:IsCollisionGroupRegistered(RagdollModule.PlayersCollisionGroup) then
	PhysicsService:RegisterCollisionGroup(RagdollModule.PlayersCollisionGroup)
end
if not PhysicsService:IsCollisionGroupRegistered("Uncollidable") then
	PhysicsService:RegisterCollisionGroup("Uncollidable")
end

PhysicsService:CollisionGroupSetCollidable("Uncollidable", RagdollModule.PlayersCollisionGroup, false)
PhysicsService:CollisionGroupSetCollidable("Uncollidable", "Uncollidable", RagdollModule.CanCollide)

--// Main Function's
function RagdollModule:Ragdoll(Character)
	if not Character:GetAttribute("Ragdoll") then
		local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
		local Animator = Humanoid and Humanoid:FindFirstChildWhichIsA("Animator")

		if not Humanoid then
			return
		end

		if Animator then
			for _, Animation in ipairs(Animator:GetPlayingAnimationTracks()) do
				Animation:Stop()
			end
		end

		Character:SetAttribute("Ragdoll", true)

		Humanoid.BreakJointsOnDeath = false
		Humanoid.AutoRotate = false
		Humanoid.RequiresNeck = true

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)

		local root = Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.CanCollide = false
		end

		if IsNpc then
			Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		end

		self:ReplaceJoints(Character)
	end
end

function RagdollModule:unRagdoll(Character)
	if Character:GetAttribute("Ragdoll") then
		local IsNpc = Players:GetPlayerFromCharacter(Character) == nil
		local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

		if not Humanoid then
			return
		end
		if Humanoid.Health <= 0.1 then
			return
		end

		Character:SetAttribute("Ragdoll", false)

		Humanoid.AutoRotate = true
		Humanoid.RequiresNeck = false

		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)

		local root = Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.CanCollide = true
		end

		if IsNpc then
			Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end

		self:ResetJoints(Character)
	end
end

--// Attachments CFrame's
local AttachmentCFrames = {
	["Neck"] = { CFrame.new(0, 1, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1), CFrame.new(0, -0.5, 0, 0, -1, 0, 1, 0, -0, 0, 0, 1) },
	["Left Shoulder"] = {
		CFrame.new(-1.3, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
		CFrame.new(0.2, 0.75, 0, -1, 0, 0, 0, -1, 0, 0, 0, 1),
	},
	["Right Shoulder"] = {
		CFrame.new(1.3, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
		CFrame.new(-0.2, 0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	},
	["Left Hip"] = {
		CFrame.new(-0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
	["Right Hip"] = {
		CFrame.new(0.5, -1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
		CFrame.new(0, 1, 0, 0, 1, -0, -1, 0, 0, 0, 0, 1),
	},
}

local RagdollInstanceNames = {
	["RagdollAttachment"] = true,
	["RagdollConstraint"] = true,
	["ColliderPart"] = true,
}

function RagdollModule:CreateColliderPart(Part)
	if not Part then
		return
	end
	local RagdollColliderPart = Instance.new("Part")
	RagdollColliderPart.Name = "ColliderPart"
	RagdollColliderPart.Size = Part.Size / 1.7
	RagdollColliderPart.Massless = true
	RagdollColliderPart.CFrame = Part.CFrame
	RagdollColliderPart.Transparency = 1

	RagdollColliderPart.CollisionGroup = "Uncollidable"

	local WeldConstraint = Instance.new("WeldConstraint")
	WeldConstraint.Part0 = RagdollColliderPart
	WeldConstraint.Part1 = Part

	WeldConstraint.Parent = RagdollColliderPart
	RagdollColliderPart.Parent = Part
end

function RagdollModule:ReplaceJoints(Character)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	for _, Motor in ipairs(Character:GetDescendants()) do
		if Motor:IsA("Motor6D") then
			if not AttachmentCFrames[Motor.Name] then
				return
			end
			Motor.Enabled = false
			local Attachment0, Attachment1 = Instance.new("Attachment"), Instance.new("Attachment")
			Attachment0.CFrame = AttachmentCFrames[Motor.Name][1]
			Attachment1.CFrame = AttachmentCFrames[Motor.Name][2]

			Attachment0.Name = "RagdollAttachment"
			Attachment1.Name = "RagdollAttachment"

			self:CreateColliderPart(Motor.Part1)

			local BallSocketConstraint = Instance.new("BallSocketConstraint")
			BallSocketConstraint.Attachment0 = Attachment0
			BallSocketConstraint.Attachment1 = Attachment1
			BallSocketConstraint.Name = "RagdollConstraint"

			BallSocketConstraint.Radius = 0.15
			BallSocketConstraint.LimitsEnabled = true
			BallSocketConstraint.TwistLimitsEnabled = true
			BallSocketConstraint.MaxFrictionTorque = 0
			BallSocketConstraint.Restitution = 0
			BallSocketConstraint.UpperAngle = 45
			BallSocketConstraint.TwistLowerAngle = -70
			BallSocketConstraint.TwistUpperAngle = 70
			BallSocketConstraint.Restitution = 0

			Attachment0.Parent = Motor.Part0
			Attachment1.Parent = Motor.Part1
			BallSocketConstraint.Parent = Motor.Parent
		end
	end
end

function RagdollModule:ResetJoints(Character)
	local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")

	if Humanoid then
		if Humanoid.Health < 0.1 then
			return
		end
		for _, Instance in ipairs(Character:GetDescendants()) do
			if RagdollInstanceNames[Instance.Name] then
				Instance:Destroy()
			end

			if Instance:IsA("Motor6D") then
				Instance.Enabled = true
			end
		end
	end
end

return RagdollModule
