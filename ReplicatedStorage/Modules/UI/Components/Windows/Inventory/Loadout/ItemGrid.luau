--[[
	ItemGrid — Scrollable grid of owned inventory items.

	Props:
		items: { any }
		selectedItemId: string?
		onSelectItem: ((item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Parent.Parent.Shared.IconRing)
local e = React.createElement

export type InventoryItem = {
	id: string,
	name: string,
	icon: string?,
	count: number?,
	rarity: string?,
	weight: number?,
	value: number?,
	description: string?,
	category: string?,
}

export type ItemGridProps = {
	items: { InventoryItem }?,
	selectedItemId: string?,
	onSelectItem: ((item: InventoryItem) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function ItemGrid(props: ItemGridProps)
	local items = props.items or {}
	local columns = 8

	local cells: { [string]: any } = {
		Layout = e("UIGridLayout", {
			CellSize = UDim2.new(0, 52, 0, 52),
			CellPadding = UDim2.new(0, 6, 0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	}

	for i, item in ipairs(items) do
		local isSelected = (props.selectedItemId == item.id)

		cells["Item_" .. (item.id or i)] = e("ImageButton", {
			Size = UDim2.new(0, 52, 0, 52),
			BackgroundColor3 = isSelected and Color3.fromHex("#28423D") or Color3.fromHex("#14201E"),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			LayoutOrder = i,
			[React.Event.Activated] = function()
				if props.onSelectItem then
					props.onSelectItem(item)
				end
			end,
		}, {
			Stroke = e("UIStroke", {
				Color = isSelected and Color3.fromHex("#FFF4A3") or Color3.fromHex("#F2B705"),
				Thickness = isSelected and 2 or 1,
				Transparency = isSelected and 0 or 0.4,
			}),
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Ring = e(IconRing, {
				size = UDim2.new(1, -6, 1, -6),
				position = UDim2.new(0.5, 0, 0.5, 0),
				anchorPoint = Vector2.new(0.5, 0.5),
				image = item.icon,
				strokeThickness = 0,
			}),
			Count = (item.count and item.count > 1) and e("TextLabel", {
				Size = UDim2.new(0, 20, 0, 14),
				Position = UDim2.new(1, -2, 1, -2),
				AnchorPoint = Vector2.new(1, 1),
				BackgroundColor3 = Color3.fromHex("#1B1814"),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				Text = tostring(item.count),
				Font = Enum.Font.SourceSans,
				TextSize = 12,
				TextColor3 = Color3.fromHex("#FFFFFF"),
				ZIndex = 3,
			}, {
				CountCorner = e("UICorner", { CornerRadius = UDim.new(0, 2) }),
			}) or nil,
		})
	end

	return e("ScrollingFrame", {
		Size = props.size or UDim2.new(1, 0, 1, -36),
		Position = props.position or UDim2.new(0, 0, 0, 36),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, math.ceil(#items / columns) * 58 + 8),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
	}, cells)
end

return ItemGrid
