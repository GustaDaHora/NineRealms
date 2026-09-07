--[[
	LowHealth — Persistent red screen vignette warning when health is critically low.

	Props:
		active: boolean?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type LowHealthProps = {
	active: boolean?,
}

local function LowHealth(props: LowHealthProps)
	if not props.active then
		return nil
	end

	return e("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://14636078735",
		ImageColor3 = Color3.fromHex("#7C0000"),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 8,
	})
end

return LowHealth
