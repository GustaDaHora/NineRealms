--[[
	SkillsWindow — Full-screen interactive skill tree window.

	Composes:
	  - SkillTreeCanvas (pannable graph)
	  - SkillHoverPanel (inspected node & unlock/equip actions)
	  - WindowLabel & CloseButton
	  - Integrates with UIStore (unlockedSkills, chosenPath, skills hotbar)

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local SkillTreeCanvas = require(script.Parent.SkillTreeCanvas)
local SkillHoverPanel = require(script.Parent.SkillHoverPanel)
local ContextMenu = require(script.Parent.Parent.Parent.Shared.ContextMenu)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type SkillsWindowProps = {
	onClose: (() -> ())?,
}

local function SkillsWindow(props: SkillsWindowProps)
	local store = React.useContext(StoreContext)

	local selectedNode, setSelectedNode = React.useState(nil :: any)
	local selectedStatus, setSelectedStatus = React.useState("locked")
	local pendingPathNode, setPendingPathNode = React.useState(nil :: any)

	local skillState = useStore(store, function(state)
		return {
			unlocked = state.unlockedSkills or { Initial = true },
			chosenPath = state.chosenPath,
			skills = state.skills or {},
			souls = state.souls or 0,
		}
	end)

	local commitUnlock = function(nodeId: string)
		if not store or not selectedNode then return end
		local currentState = store:getState()
		local didUnlock = false
		if currentState and currentState.unlockSkill then
			didUnlock = currentState.unlockSkill(selectedNode.name or nodeId)
		end
		-- The server is authoritative for unlocks, chosen paths, and soul costs.
		-- Never make a rejected request look successful in the client UI.
		if didUnlock then
			setSelectedNode(nil)
		end
	end

	local handleUnlock = function(nodeId: string)
		if (nodeId == "Aegishjalmur" or nodeId == "Vegvisir") and not skillState.chosenPath then
			setPendingPathNode(selectedNode)
			return
		end
		commitUnlock(nodeId)
	end

	local handleEquip = function(nodeId: string, slotIndex: number)
		if not store or not selectedNode then return end
		local currentState = store:getState()
	if currentState and currentState.equipSkill then
		currentState.equipSkill(selectedNode.name or nodeId, slotIndex)
	end
	-- Active skill slots are replicated from Player.Skills by the controller.
	-- Do not synthesize a successful assignment here: the server may reject it
	-- (or replace the slot) and a local draft would leave the hotbar incorrect.
	end

	return e("Frame", {
		Size = UDim2.new(0, 860, 0, 580),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#0D1413"),
		BackgroundTransparency = 0.03,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#B8964F"),
			Thickness = 2.5,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("#F2B705")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFF4A3")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#F2B705")),
				}),
				Rotation = 45,
			}),
		}),
		InnerStroke = e("UIStroke", { Color = Color3.fromHex("#42615B"), Thickness = 7, Transparency = 0.68 }),
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Close = e(CloseButton, {
			onClick = function()
				if props.onClose then props.onClose() end
			end,
		}),
		Header = e(WindowLabel, {
			title = "Skill Constellations",
			subtitle = skillState.chosenPath and ("Path of " .. skillState.chosenPath) or "Choose Your Path",
			size = UDim2.new(1, 0, 0, 48),
			position = UDim2.new(0, 0, 0, 6),
		}),

		-- Central Pannable Graph Canvas
		CanvasArea = e("Frame", {
			Size = UDim2.new(1, -24, 1, -64),
			Position = UDim2.new(0.5, 0, 0, 54),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Canvas = e(SkillTreeCanvas, {
				unlockedSkills = skillState.unlocked,
				chosenPath = skillState.chosenPath,
				selectedNodeId = selectedNode and selectedNode.id or nil,
				onSelectNode = function(node, status)
					setSelectedNode(node)
					setSelectedStatus(status)
				end,
			}),

			-- Detail / Hover Inspection Overlay
			HoverCard = selectedNode and e(SkillHoverPanel, {
				node = selectedNode,
				status = selectedStatus,
				onUnlock = handleUnlock,
				onEquip = handleEquip,
				onClose = function()
					setSelectedNode(nil)
				end,
			}) or nil,
			PathConfirmation = pendingPathNode and e(ContextMenu, {
				visible = true,
				position = UDim2.new(0.5, 0, 0.5, 0),
				anchorPoint = Vector2.new(0.5, 0.5),
				actions = {
					{
						label = "Choose " .. pendingPathNode.name,
						onClick = function()
							commitUnlock(pendingPathNode.id)
							setPendingPathNode(nil)
						end,
					},
					{
						label = "Cancel",
						onClick = function() setPendingPathNode(nil) end,
					},
				},
				onClose = function() setPendingPathNode(nil) end,
			}) or nil,
		}),
	})
end

return SkillsWindow
