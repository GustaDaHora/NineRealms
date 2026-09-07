--[[
	IconRing — Decorative aspect-ratio-locked icon wrapper with gold stroke framing.

	Props:
		image: string?
		imageColor: Color3?
		size: UDim2?
		position: UDim2?
		anchorPoint: Vector2?
		strokeColor: Color3?
		strokeThickness: number?
		cornerRadius: UDim?
		layoutOrder: number?
		children: any?

	Used by:
		- HUD RadialMenu buttons
		- SkillHotbar / SkillSlot
		- Inventory equipment slot icons
		- Shop/Crafting item icons
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type IconRingProps = {
	image: string?,
	imageColor: Color3?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	strokeColor: Color3?,
	strokeThickness: number?,
	cornerRadius: UDim?,
	layoutOrder: number?,
	children: { [string]: any }?,
}

local function IconRing(props: IconRingProps)
	local strokeColor = props.strokeColor or Color3.fromHex("#B8964F")
	local highlightColor = strokeColor:Lerp(Color3.fromHex("#F4E6C0"), 0.45)
	local innerChildren: { [string]: any } = {
		AspectRatio = e("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
		Stroke = e("UIStroke", {
			Color = strokeColor,
			Thickness = props.strokeThickness or 2,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, strokeColor),
					ColorSequenceKeypoint.new(0.5, highlightColor),
					ColorSequenceKeypoint.new(1, strokeColor),
				}),
				Rotation = 45,
			}),
		}),
		Corner = e("UICorner", {
			CornerRadius = props.cornerRadius or UDim.new(0, 4),
		}),
	}

	if props.image and props.image ~= "" then
		innerChildren.Icon = e("ImageLabel", {
			Size = UDim2.new(0.85, 0, 0.85, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.image,
			ImageColor3 = props.imageColor or Color3.new(1, 1, 1),
			ScaleType = Enum.ScaleType.Fit,
		})
	end

	if props.children then
		for key, child in pairs(props.children) do
			innerChildren[key] = child
		end
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0, 44, 0, 44),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		BackgroundColor3 = Color3.fromHex("#14201E"),
		BackgroundTransparency = 0.16,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, innerChildren)
end

return IconRing
