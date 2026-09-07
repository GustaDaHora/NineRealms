--[[
	EventDetailPanel — Detailed view of the currently selected game event.

	Props:
		name: string?
		description: string?
		image: string?
		size: UDim2?
		position: UDim2?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type EventDetailPanelProps = {
	name: string?,
	description: string?,
	image: string?,
	size: UDim2?,
	position: UDim2?,
}

local function EventDetailPanel(props: EventDetailPanelProps)
	return e("Frame", {
		Size = props.size or UDim2.new(0.6, 0, 1, 0),
		Position = props.position or UDim2.new(0.4, 0, 0, 0),
		BackgroundColor3 = Color3.fromHex("#14201E"),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#56736A"),
			Thickness = 1.25,
		}),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 12),
			PaddingBottom = UDim.new(0, 12),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Text = props.name or "Select an Event",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 22,
			TextColor3 = Color3.fromHex("#F2B705"),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}),

		Banner = props.image and props.image ~= "" and e("ImageLabel", {
			Size = UDim2.new(1, 0, 0, 120),
			BackgroundColor3 = Color3.fromHex("#101A18"),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Image = props.image,
			ScaleType = Enum.ScaleType.Crop,
			LayoutOrder = 2,
		}, {
			BannerCorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			BannerStroke = e("UIStroke", {
				Color = Color3.fromHex("#F2B705"),
				Thickness = 1,
				Transparency = 0.5,
			}),
		}) or nil,

		Description = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 120),
			BackgroundTransparency = 1,
			Text = props.description or "No active event selected.",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 17,
			TextColor3 = Color3.fromHex("#E5E5E5"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LineHeight = 1.2,
			LayoutOrder = 3,
		}),
	})
end

return EventDetailPanel
