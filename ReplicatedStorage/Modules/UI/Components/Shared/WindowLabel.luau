--[[
	WindowLabel — Standard window header title with gold underline accent.

	Props:
		title: string
		subtitle: string?
		size: UDim2?
		position: UDim2?

	Used by:
		- All modal and full-screen windows (Inventory, Character, Skills, Config, Shop, Events, Guide)
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type WindowLabelProps = {
	title: string,
	subtitle: string?,
	size: UDim2?,
	position: UDim2?,
}

local function WindowLabel(props: WindowLabelProps)
	return e("Frame", {
		Size = props.size or UDim2.new(1, 0, 0, 44),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		LeftRune = e("TextLabel", {
			Size = UDim2.new(0, 28, 0, 24),
			Position = UDim2.new(0.5, -150, 0.18, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "ᛉ",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 20,
			TextColor3 = Color3.fromHex("#56736A"),
		}),
		RightRune = e("TextLabel", {
			Size = UDim2.new(0, 28, 0, 24),
			Position = UDim2.new(0.5, 150, 0.18, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = "ᛉ",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 20,
			TextColor3 = Color3.fromHex("#56736A"),
		}),
		Title = e("TextLabel", {
			Size = UDim2.new(1, -88, 0.65, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = string.upper(props.title),
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 30,
			TextColor3 = Color3.fromHex("#E6D0A2"),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, {
			Stroke = e("UIStroke", {
				Color = Color3.fromHex("#05070A"),
				Thickness = 1.5,
			}),
		}),
		Subtitle = props.subtitle and e("TextLabel", {
			Size = UDim2.new(1, -88, 0.28, 0),
			Position = UDim2.new(0.5, 0, 0.65, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Text = props.subtitle,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 15,
			TextColor3 = Color3.fromHex("#9FB5AA"),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}) or nil,
		Underline = e("Frame", {
			Size = UDim2.new(0.7, 0, 0, 2),
			Position = UDim2.new(0.5, 0, 1, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromHex("#B8964F"),
			BorderSizePixel = 0,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("#0D1413")),
					ColorSequenceKeypoint.new(0.35, Color3.fromHex("#56736A")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("#E6D0A2")),
					ColorSequenceKeypoint.new(0.65, Color3.fromHex("#56736A")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#0D1413")),
				}),
			}),
		}),
	})
end

return WindowLabel
