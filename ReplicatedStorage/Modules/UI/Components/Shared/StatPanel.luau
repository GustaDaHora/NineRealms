--[[
	StatPanel — Displays an arbitrary list of labeled stats.

	Props:
		entries: { { label: string, value: string | number } }
		variant: ("chip" | "plain")? (default: "chip")
		size: UDim2?
		position: UDim2?
		anchorPoint: Vector2?
		layoutOrder: number?

	Used by:
		- Inventory (EquipView: core stats & equipment attributes)
		- Character Window (4 panels: combat record, prestige info, equipment info, core stats)
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type StatEntry = {
	label: string,
	value: string | number,
}

export type StatPanelProps = {
	entries: { StatEntry },
	variant: ("chip" | "plain")?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function StatPanel(props: StatPanelProps)
	local variant = props.variant or "chip"
	local entries = props.entries or {}

	local children: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5),
		}),
	}

	for i, entry in ipairs(entries) do
		local displayText = string.format("%s: %s", tostring(entry.label), tostring(entry.value))

		if variant == "chip" then
			children["Entry_" .. i] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Color3.fromHex("#1C302C"),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
				}),
				Stroke = e("UIStroke", {
					Thickness = 1,
					Color = Color3.fromHex("#56736A"),
					Transparency = 0.5,
				}),
				Label = e("TextLabel", {
					Size = UDim2.new(0.65, 0, 1, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(entry.label),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 15,
					TextColor3 = Color3.fromHex("#FFFFFF"),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
				Value = e("TextLabel", {
					Size = UDim2.new(0.35, 0, 1, 0),
					Position = UDim2.new(0.65, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(entry.value),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 15,
					TextColor3 = Color3.fromHex("#F2B705"),
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			})
		else -- "plain"
			children["Entry_" .. i] = e("Frame", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = i,
			}, {
				Padding = e("UIPadding", {
					PaddingLeft = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
				}),
				Label = e("TextLabel", {
					Size = UDim2.new(0.6, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = tostring(entry.label),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#D3D3D3"),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
				Value = e("TextLabel", {
					Size = UDim2.new(0.4, 0, 1, 0),
					Position = UDim2.new(0.6, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = tostring(entry.value),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#FFFFFF"),
					TextXAlignment = Enum.TextXAlignment.Right,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),
			})
		end
	end

	return e("Frame", {
		Size = props.size or UDim2.new(1, 0, 1, 0),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, children)
end

return StatPanel
