--[[
	CombatIndicator — Visual emblem indicating active combat engagement.

	Props:
		inCombat: boolean?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type CombatIndicatorProps = {
	inCombat: boolean?,
}

local function CombatIndicator(props: CombatIndicatorProps)
	if not props.inCombat then
		return nil
	end

	return e("ImageLabel", {
		Size = UDim2.new(0, 50, 0, 50),
		Position = UDim2.new(0.5, 0, 0.08, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = "rbxassetid://97239913487361",
		ImageColor3 = Color3.fromHex("#FF3333"),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 8,
	}, {
		Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
	})
end

return CombatIndicator
