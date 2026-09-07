--[[
	MoneyDisplay — Currency readout with coin icon and formatted amount.

	Props:
		amount: number | string
		size: UDim2?
		position: UDim2?
		anchorPoint: Vector2?
		textColor: Color3?
		textSize: number?

	Used by:
		- HUD PlayerInfoRow
		- Shop/Crafting windows
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type MoneyDisplayProps = {
	amount: number | string,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	textColor: Color3?,
	textSize: number?,
}

local function formatNumber(n: number | string): string
	local num = tonumber(n)
	if not num then
		return tostring(n)
	end
	-- Format with commas
	local formatted = tostring(math.floor(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return formatted
end

local function MoneyDisplay(props: MoneyDisplayProps)
	local display = "$" .. formatNumber(props.amount or 0)

	return e("TextLabel", {
		Size = props.size or UDim2.new(0, 100, 0, 24),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = display,
		Font = Enum.Font.GrenzeGotisch,
		TextSize = props.textSize or 16,
		TextColor3 = props.textColor or Color3.fromHex("#F2B705"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#1B1814"),
			Thickness = 1,
		}),
	})
end

return MoneyDisplay
