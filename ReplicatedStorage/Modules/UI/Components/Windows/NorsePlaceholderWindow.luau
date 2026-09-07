--[[
	NorsePlaceholderWindow — deliberately read-only shell for destinations whose
	gameplay systems are not available yet. It gives every radial destination a
	consistent, usable screen without inventing quest or clan state client-side.
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local WindowLabel = require(script.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Shared.CloseButton)
local e = React.createElement

export type NorsePlaceholderWindowProps = {
	title: string,
	subtitle: string,
	emblem: string,
	message: string,
	sections: { { heading: string, text: string } },
	onClose: (() -> ())?,
}

local function NorsePlaceholderWindow(props: NorsePlaceholderWindowProps)
	local sections: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
	}

	for index, section in ipairs(props.sections) do
		sections["Section_" .. index] = e("Frame", {
			Size = UDim2.new(1, 0, 0, 62),
			BackgroundColor3 = Color3.fromHex("#182321"),
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			LayoutOrder = index,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Accent = e("Frame", {
				Size = UDim2.new(0, 3, 1, -12),
				Position = UDim2.new(0, 7, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromHex("#B8964F"),
				BorderSizePixel = 0,
			}),
			Heading = e("TextLabel", {
				Size = UDim2.new(1, -32, 0, 21),
				Position = UDim2.new(0, 18, 0, 7),
				BackgroundTransparency = 1,
				Text = string.upper(section.heading),
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#E6D0A2"),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Text = e("TextLabel", {
				Size = UDim2.new(1, -32, 0, 25),
				Position = UDim2.new(0, 18, 0, 29),
				BackgroundTransparency = 1,
				Text = section.text,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 13,
				TextColor3 = Color3.fromHex("#B7C3BC"),
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 600, 0, 390),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#0D1413"),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		OuterStroke = e("UIStroke", { Color = Color3.fromHex("#B8964F"), Thickness = 2 }),
		InnerStroke = e("UIStroke", { Color = Color3.fromHex("#42615B"), Thickness = 7, Transparency = 0.68 }),
		Close = e(CloseButton, { onClick = props.onClose }),
		Header = e(WindowLabel, {
			title = props.title,
			subtitle = props.subtitle,
			size = UDim2.new(1, -70, 0, 54),
			position = UDim2.new(0.5, 0, 0, 12),
		}),
		Emblem = e("ImageLabel", {
			Size = UDim2.new(0, 78, 0, 78),
			Position = UDim2.new(0.5, 0, 0, 86),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Image = props.emblem,
			ImageColor3 = Color3.fromHex("#B8964F"),
			ScaleType = Enum.ScaleType.Fit,
		}),
		Message = e("TextLabel", {
			Size = UDim2.new(1, -80, 0, 42),
			Position = UDim2.new(0.5, 0, 0, 170),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = props.message,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 16,
			TextColor3 = Color3.fromHex("#DEE5D8"),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
		Sections = e("Frame", {
			Size = UDim2.new(1, -56, 0, 136),
			Position = UDim2.new(0.5, 0, 1, -22),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
		}, sections),
	})
end

return NorsePlaceholderWindow
