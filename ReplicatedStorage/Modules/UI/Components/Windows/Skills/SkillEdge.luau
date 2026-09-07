--[[
	SkillEdge — Connection line between two nodes in the skill tree graph.

	Props:
		fromX: number
		fromY: number
		toX: number
		toY: number
		isActive: boolean?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type SkillEdgeProps = {
	fromX: number,
	fromY: number,
	toX: number,
	toY: number,
	isActive: boolean?,
}

local function SkillEdge(props: SkillEdgeProps)
	local dx = props.toX - props.fromX
	local dy = props.toY - props.fromY
	local distance = math.sqrt(dx * dx + dy * dy)
	local angleDeg = math.deg(math.atan2(dy, dx))

	local midX = (props.fromX + props.toX) / 2
	local midY = (props.fromY + props.toY) / 2

	return e("Frame", {
		Size = UDim2.new(0, distance, 0, 3),
		Position = UDim2.new(0.5, midX, 0.5, midY),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Rotation = angleDeg,
		BackgroundColor3 = props.isActive and Color3.fromHex("#F2B705") or Color3.fromHex("#444444"),
		BorderSizePixel = 0,
		ZIndex = 2,
	})
end

return SkillEdge
