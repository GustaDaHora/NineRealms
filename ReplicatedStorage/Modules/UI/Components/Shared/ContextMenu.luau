--[[
	ContextMenu — Popup action menu anchored to a selected item/slot.

	Props:
		actions: { { label: string, onClick: () -> () } }
		visible: boolean
		position: UDim2?
		anchorPoint: Vector2?
		onClose: (() -> ())?

	Used by:
		- Inventory (EquipView: Inspect, Unequip, Hide/Show)
		- Inventory (Loadout: Inspect, Equip, Disposal)
		- Skill tree confirmation
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type ContextAction = {
	label: string,
	onClick: () -> (),
}

export type ContextMenuProps = {
	actions: { ContextAction },
	visible: boolean,
	position: UDim2?,
	anchorPoint: Vector2?,
	onClose: (() -> ())?,
}

local function ContextMenu(props: ContextMenuProps)
	if not props.visible then
		return nil
	end

	local actions = props.actions or {}
	local buttonHeight = 28
	local padding = 5
	local totalHeight = #actions * buttonHeight + (#actions + 1) * padding

	local actionButtons: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, padding),
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, padding),
			PaddingBottom = UDim.new(0, padding),
			PaddingLeft = UDim.new(0, padding),
			PaddingRight = UDim.new(0, padding),
		}),
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#B8964F"),
			Thickness = 1.5,
		}),
	}

	for i, action in ipairs(actions) do
		actionButtons["Action_" .. i] = e("TextButton", {
			Size = UDim2.new(1, 0, 0, buttonHeight),
			BackgroundColor3 = Color3.fromHex("#21332F"),
			BackgroundTransparency = 0.03,
			BorderSizePixel = 0,
			Text = string.upper(action.label),
			Font = Enum.Font.Fondamento,
			TextSize = 14,
			TextColor3 = Color3.fromHex("#E6D0A2"),
			LayoutOrder = i,
			ZIndex = 10,
			[React.Event.Activated] = function()
				action.onClick()
				if props.onClose then
					props.onClose()
				end
			end,
		}, {
			ButtonStroke = e("UIStroke", {
				Color = Color3.fromHex("#56736A"),
				Thickness = 1,
				Transparency = 0.3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 116, 0, totalHeight),
		Position = props.position or UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromHex("#0D1413"),
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ZIndex = 9,
	}, actionButtons)
end

return ContextMenu
