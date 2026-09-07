--[[
	SkillTreeCanvas — Pannable canvas rendering skill nodes and connecting edges.

	Props:
		unlockedSkills: { [string]: boolean }?
		chosenPath: string? ("Aegishjalmur" | "Vegvisir" | nil)
		selectedNodeId: string?
		onSelectNode: ((node: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local SkillTreeLayout = require(script.Parent.Parent.Parent.Parent.Data.SkillTreeLayout)
local SkillNode = require(script.Parent.SkillNode)
local SkillEdge = require(script.Parent.SkillEdge)
local e = React.createElement

export type SkillTreeCanvasProps = {
	unlockedSkills: { [string]: boolean }?,
	chosenPath: string?,
	selectedNodeId: string?,
	onSelectNode: ((node: any) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function SkillTreeCanvas(props: SkillTreeCanvasProps)
	local unlocked = props.unlockedSkills or { Initial = true }
	local scrollRef = React.useRef(nil :: ScrollingFrame?)
	local chosenPath = props.chosenPath

	local nodes = SkillTreeLayout.Nodes
	local edges = SkillTreeLayout.Edges

	local canvasChildren: { [string]: any } = {}

	-- Render edges first (behind nodes)
	for i, edge in ipairs(edges) do
		local fromNode = nodes[edge.fromId]
		local toNode = nodes[edge.toId]
		if fromNode and toNode then
			local isActive = unlocked[edge.fromId] and unlocked[edge.toId]
			canvasChildren["Edge_" .. i] = e(SkillEdge, {
				fromX = fromNode.x,
				fromY = fromNode.y,
				toX = toNode.x,
				toY = toNode.y,
				isActive = isActive,
			})
		end
	end

	-- Render nodes
	for id, node in pairs(nodes) do
		local isUnlocked = unlocked[id] == true
		local isBlocked = false

		-- If a path is chosen, lock out the opposite path
		if chosenPath and node.path ~= "Root" and node.path ~= chosenPath then
			isBlocked = true
		end

		local status: "unlocked" | "available" | "locked" | "blocked" = "locked"
		if isUnlocked then
			status = "unlocked"
		elseif isBlocked then
			status = "blocked"
		else
			-- Check prerequisites
			local prereqsMet = true
			for _, pre in ipairs(node.prerequisites) do
				if not unlocked[pre] then
					prereqsMet = false
					break
				end
			end
			if prereqsMet then
				status = "available"
			else
				status = "locked"
			end
		end

		canvasChildren["Node_" .. id] = e(SkillNode, {
			node = node,
			status = status,
			isSelected = (props.selectedNodeId == id),
			onClick = function()
				if props.onSelectNode then
					props.onSelectNode(node, status)
				end
			end,
			onHover = function()
				if props.onSelectNode then
					props.onSelectNode(node, status)
				end
			end,
		})
	end

	React.useEffect(function()
		if scrollRef.current then
			scrollRef.current.CanvasPosition = Vector2.new(700, 400)
		end
	end, {})

	return e("ScrollingFrame", {
		ref = scrollRef,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.fromScale(0, 0),
		BackgroundColor3 = Color3.fromHex("#0E0D0B"),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 2000, 0, 1200),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
	}, canvasChildren)
end

return SkillTreeCanvas
