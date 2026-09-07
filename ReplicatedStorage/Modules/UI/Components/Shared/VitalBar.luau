--[[
	VitalBar — Labeled resource fill bar (Health, Souls).

	Props:
		label: string?
		value: number
		max: number
		barColor: Color3?
		strokeColor: Color3?
		textColor: Color3?
		strokeTextColor: Color3?
		size: UDim2?
		position: UDim2?
		anchorPoint: Vector2?
		layoutOrder: number?

	Used by:
		- HUD VitalsRow (Health & Souls bars)
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type VitalBarProps = {
	label: string?,
	value: number,
	max: number,
	barColor: Color3?,
	strokeColor: Color3?,
	textColor: Color3?,
	strokeTextColor: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	layoutOrder: number?,
}

local function VitalBar(props: VitalBarProps)
	local current = math.max(0, props.value or 0)
	local max = math.max(1, props.max or 100)
	local ratio = math.clamp(current / max, 0, 1)
	local strokeColor = props.strokeColor or Color3.fromHex("#B8964F")

	local displayText = string.format("%d/%d", math.floor(current), math.floor(max))
	if props.label and props.label ~= "" then
		displayText = string.format("%s: %s", props.label, displayText)
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0.75, 0, 0.3, 0),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromHex("#14201E"),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Stroke = e("UIStroke", {
			Color = strokeColor,
			Thickness = 3.1,
			LineJoinMode = Enum.LineJoinMode.Bevel,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, strokeColor),
					ColorSequenceKeypoint.new(0.5, strokeColor:Lerp(Color3.fromHex("#F4E6C0"), 0.45)),
					ColorSequenceKeypoint.new(1, strokeColor),
				}),
			}),
		}),
		Fill = e("Frame", {
			Size = UDim2.new(ratio, 0, 1, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = props.barColor or Color3.fromHex("#B60000"),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
		}, {
			FillGradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(0.9, 0.9, 0.9)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				}),
			}),
		}),
		Border = e("ImageLabel", {
			Size = UDim2.new(1, 30, 1, 6),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://4637242007",
			ImageColor3 = strokeColor,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(22, 15, 22, 15),
			BorderSizePixel = 0,
		}),
		TextLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = displayText,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 14,
			TextColor3 = props.textColor or Color3.fromHex("#39322B"),
			TextStrokeColor3 = props.strokeTextColor or Color3.fromHex("#F2B705"),
			TextStrokeTransparency = 0.2,
			TextScaled = false,
			BorderSizePixel = 0,
			ZIndex = 2,
		}),
	})
end

return VitalBar
