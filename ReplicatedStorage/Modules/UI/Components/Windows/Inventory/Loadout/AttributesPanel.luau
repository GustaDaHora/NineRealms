--[[
	AttributesPanel — Shows detailed stats and action buttons for a selected inventory item.

	Actions:
	  - Inspect
	  - Equip
	  - Disposal

	Props:
		item: { [string]: any }?
		onAction: ((action: "Inspect" | "Equip" | "Disposal", item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Parent.Parent.Shared.IconRing)
local ContextMenu = require(script.Parent.Parent.Parent.Parent.Shared.ContextMenu)
local e = React.createElement

export type AttributesPanelProps = {
	item: { [string]: any }?,
	onAction: ((action: "Inspect" | "Equip" | "Disposal", item: any) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function AttributesPanel(props: AttributesPanelProps)
	local item = props.item
	local menuOpen, setMenuOpen = React.useState(false)

	if not item then
		return e("Frame", {
			Size = props.size or UDim2.new(0, 220, 1, 0),
			Position = props.position or UDim2.new(1, -220, 0, 0),
			BackgroundColor3 = Color3.fromHex("#14201E"),
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
		}, {
			Placeholder = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "Select an item\nto view attributes",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 18,
				TextColor3 = Color3.fromHex("#9FB5AA"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		})
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0, 220, 1, 0),
		Position = props.position or UDim2.new(1, -220, 0, 0),
		BackgroundColor3 = Color3.fromHex("#14201E"),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#56736A"),
			Thickness = 1.25,
		}),
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),

		-- Item Icon Preview
		IconBox = e("Frame", {
			Size = UDim2.new(1, 0, 0, 64),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Ring = e(IconRing, {
				size = UDim2.new(0, 58, 0, 58),
				position = UDim2.new(0.5, 0, 0.5, 0),
				anchorPoint = Vector2.new(0.5, 0.5),
				image = item.icon,
			}),
		}),

		NameLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = item.name or "Item",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 20,
			TextColor3 = Color3.fromHex("#F2B705"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 2,
		}),

		RarityLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = item.rarity or "Common",
			Font = Enum.Font.SourceSans,
			TextSize = 13,
			TextColor3 = Color3.fromHex("#A0A0A0"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 3,
		}),

		StatsLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = string.format("Weight: %s  |  Power: %s", tostring(item.weight or 0), tostring(item.power or 0)),
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 14,
			TextColor3 = Color3.fromHex("#E5E5E5"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 4,
		}),

		ValueLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text = string.format("Value: $%s", tostring(item.value or 0)),
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 14,
			TextColor3 = Color3.fromHex("#F2E079"),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 5,
		}),

		Description = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			Text = item.description or "No description available.",
			Font = Enum.Font.SourceSans,
			TextSize = 13,
			TextColor3 = Color3.fromHex("#C8C8C8"),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LayoutOrder = 6,
		}),

		ActionsContainer = e("Frame", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			LayoutOrder = 7,
		}, {
			ActionsButton = e("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromHex("#28423D"),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Text = "ACTIONS",
				Font = Enum.Font.Fondamento,
				TextSize = 13,
				TextColor3 = Color3.fromHex("#E6D0A2"),
				[React.Event.Activated] = function()
					setMenuOpen(not menuOpen)
				end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }),
				Stroke = e("UIStroke", { Color = Color3.fromHex("#56736A"), Thickness = 1 }),
			}),
			ContextActions = e(ContextMenu, {
				visible = menuOpen,
				position = UDim2.new(0.5, 0, 0, -4),
				anchorPoint = Vector2.new(0.5, 1),
				actions = {
					{ label = "Inspect", onClick = function() if props.onAction then props.onAction("Inspect", item) end end },
					{ label = "Equip", onClick = function() if props.onAction then props.onAction("Equip", item) end end },
					{ label = "Disposal", onClick = function() if props.onAction then props.onAction("Disposal", item) end end },
				},
				onClose = function() setMenuOpen(false) end,
			}),
		}),
	})
end

return AttributesPanel
