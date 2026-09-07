--[[
	TabButton — Selectable category/tab button.

	Props:
		label: string
		icon: string?
		isSelected: boolean
		onClick: () -> ()
		size: UDim2?
		layoutOrder: number?

	Used by:
		- CategoryShopWindow (category tabs)
		- Inventory Loadout (category tabs)
		- EventsWindow (event list selectable rows)
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type TabButtonProps = {
	label: string,
	icon: string?,
	isSelected: boolean,
	onClick: () -> (),
	size: UDim2?,
	layoutOrder: number?,
}

local function TabButton(props: TabButtonProps)
	local isSelected = props.isSelected

	return e("TextButton", {
		Size = props.size or UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = isSelected and Color3.fromHex("#28423D") or Color3.fromHex("#14201E"),
		BackgroundTransparency = isSelected and 0.05 or 0.18,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = props.onClick,
	}, {
		Stroke = e("UIStroke", {
			Thickness = isSelected and 2 or 1,
			Color = isSelected and Color3.fromHex("#D4B26D") or Color3.fromHex("#42615B"),
			Transparency = isSelected and 0 or 0.2,
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
		Icon = props.icon and e("ImageLabel", {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = props.icon,
			ImageColor3 = isSelected and Color3.fromHex("#F2E079") or Color3.fromHex("#949494"),
		}) or nil,
		Label = e("TextLabel", {
			Size = UDim2.new(1, props.icon and -26 or 0, 1, 0),
			Position = UDim2.new(0, props.icon and 26 or 0, 0, 0),
			BackgroundTransparency = 1,
			Text = props.label,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 17,
			TextColor3 = isSelected and Color3.fromHex("#E6D0A2") or Color3.fromHex("#AABAB0"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

return TabButton
