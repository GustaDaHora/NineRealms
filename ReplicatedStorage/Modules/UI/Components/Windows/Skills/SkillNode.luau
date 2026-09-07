--[[
	SkillNode — Individual skill node representation in the skill tree graph.

	Status states:
	  - "unlocked": Skill acquired (bright gold frame)
	  - "available": Can be unlocked now (glowing accent)
	  - "locked": Prerequisite not met (dim gray)
	  - "blocked": Path locked out (darkened)

	Props:
		node: { id: string, name: string, icon: string?, x: number, y: number }
		status: "unlocked" | "available" | "locked" | "blocked"
		isSelected: boolean
		onClick: () -> ()
		onHover: () -> ()
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Parent.Shared.IconRing)
local e = React.createElement

export type SkillNodeProps = {
	node: {
		id: string,
		name: string,
		icon: string?,
		x: number,
		y: number,
	},
	status: "unlocked" | "available" | "locked" | "blocked",
	isSelected: boolean,
	onClick: () -> (),
	onHover: (() -> ())?,
}

local function SkillNode(props: SkillNodeProps)
	local node = props.node
	local status = props.status
	local isSelected = props.isSelected

	local strokeColor = Color3.fromHex("#555555")
	local strokeThickness = 1.5

	if status == "unlocked" then
		strokeColor = Color3.fromHex("#F2B705")
		strokeThickness = 2.5
	elseif status == "available" then
		strokeColor = Color3.fromHex("#FFF4A3")
		strokeThickness = 2
	elseif status == "blocked" then
		strokeColor = Color3.fromHex("#3D1F1F")
		strokeThickness = 1
	end

	if isSelected then
		strokeColor = Color3.fromHex("#FFFFFF")
		strokeThickness = 3
	end

	local nodeSize = (node.id == "Initial" or node.id == "Aegishjalmur" or node.id == "Vegvisir") and 68 or 52

	return e("ImageButton", {
		Size = UDim2.new(0, nodeSize, 0, nodeSize),
		Position = UDim2.new(0.5, node.x, 0.5, node.y),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#1B1814"),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ZIndex = 4,
		[React.Event.Activated] = props.onClick,
		[React.Event.MouseEnter] = props.onHover,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Stroke = e("UIStroke", {
			Color = strokeColor,
			Thickness = strokeThickness,
		}),
		Ring = e(IconRing, {
			size = UDim2.new(0.85, 0, 0.85, 0),
			position = UDim2.new(0.5, 0, 0.5, 0),
			anchorPoint = Vector2.new(0.5, 0.5),
			image = node.icon or "rbxassetid://13847266549",
			strokeThickness = 0,
			cornerRadius = UDim.new(1, 0),
		}),
		NameTag = e("TextLabel", {
			Size = UDim2.new(0, 120, 0, 18),
			Position = UDim2.new(0.5, 0, 1, 4),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = node.name,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 14,
			TextColor3 = (status == "unlocked" or status == "available") and Color3.fromHex("#FFF4A3") or Color3.fromHex("#888888"),
			TextStrokeColor3 = Color3.fromHex("#1B1814"),
			TextStrokeTransparency = 0.2,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 5,
		}),
	})
end

return SkillNode
