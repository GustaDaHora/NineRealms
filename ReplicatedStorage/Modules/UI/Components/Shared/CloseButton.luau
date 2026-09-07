--[[
	CloseButton — Standard window close button with gold styling and hover feedback.

	Props:
		onClick: () -> ()
		position: UDim2?
		anchorPoint: Vector2?
		size: UDim2?

	Used by:
		- All modal and full-screen windows
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type CloseButtonProps = {
	onClick: () -> (),
	position: UDim2?,
	anchorPoint: Vector2?,
	size: UDim2?,
}

local function CloseButton(props: CloseButtonProps)
	local isHovered, setIsHovered = React.useState(false)

	return e("TextButton", {
		Size = props.size or UDim2.new(0, 32, 0, 32),
		Position = props.position or UDim2.new(1, -12, 0, 12),
		AnchorPoint = props.anchorPoint or Vector2.new(1, 0),
		BackgroundColor3 = isHovered and Color3.fromHex("#6D3029") or Color3.fromHex("#15201E"),
		BackgroundTransparency = isHovered and 0.05 or 0.15,
		BorderSizePixel = 0,
		Text = "X",
		Font = Enum.Font.GrenzeGotisch,
		TextSize = 18,
		TextColor3 = isHovered and Color3.fromHex("#FFE1D6") or Color3.fromHex("#E6D0A2"),
		AutoButtonColor = false,
		ZIndex = 10,
		[React.Event.Activated] = props.onClick,
		[React.Event.MouseEnter] = function()
			setIsHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setIsHovered(false)
		end,
	}, {
		Stroke = e("UIStroke", {
			Color = isHovered and Color3.fromHex("#D67B68") or Color3.fromHex("#56736A"),
			Thickness = 1,
		}),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
	})
end

return CloseButton
