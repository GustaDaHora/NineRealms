--[[
	DamageIndicator — Red screen border flash when taking damage.

	Props:
		active: boolean?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type DamageIndicatorProps = {
	active: boolean?,
}

local function DamageIndicator(props: DamageIndicatorProps)
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
		ImageColor3 = Color3.fromHex("#B60000"),
		ImageTransparency = 0.3,
		ScaleType = Enum.ScaleType.Crop,
		ZIndex = 9,
	})
end

return DamageIndicator
