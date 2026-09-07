--[[
	ZoneBanner — Displays the current zone name, decorative divider, and description.

	Props:
		zoneName: string
		zoneDescription: string?
		visible: boolean?
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type ZoneBannerProps = {
	zoneName: string,
	zoneDescription: string?,
	visible: boolean?,
	size: UDim2?,
	position: UDim2?,
}

local function Divider()
	return e("Frame", {
		Size = UDim2.new(0.8, 0, 0, 2),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#F2B705"),
		BorderSizePixel = 0,
	}, {
		Gradient = e("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
end

local function ZoneBanner(props: ZoneBannerProps)
	if props.visible == false or not props.zoneName or props.zoneName == "" then
		return nil
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0, 280, 0, 70),
		Position = props.position or UDim2.new(0.5, 0, 0.02, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
		ZoneText = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			Text = props.zoneName,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 24,
			TextColor3 = Color3.fromHex("#FFF4A3"),
			TextStrokeColor3 = Color3.fromHex("#1B1814"),
			TextStrokeTransparency = 0.2,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
		}),
		DividerContainer = e("Frame", {
			Size = UDim2.new(1, 0, 0, 6),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Line = e(Divider),
		}),
		Description = props.zoneDescription and props.zoneDescription ~= "" and e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Text = props.zoneDescription,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 15,
			TextColor3 = Color3.fromHex("#F2B705"),
			TextStrokeColor3 = Color3.fromHex("#1B1814"),
			TextStrokeTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 3,
		}) or nil,
	})
end

return ZoneBanner
