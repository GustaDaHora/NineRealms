--[[
	ConfigToggle — Setting row with interactive toggle pill switch.

	Props:
		label: string
		description: string?
		value: boolean
		onToggle: (boolean) -> ()
		layoutOrder: number?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type ConfigToggleProps = {
	label: string,
	description: string?,
	value: boolean,
	onToggle: (boolean) -> (),
	layoutOrder: number?,
}

local function ConfigToggle(props: ConfigToggleProps)
	local isChecked = props.value

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, props.description and 52 or 38),
		BackgroundColor3 = Color3.fromHex("#16211F"),
		BackgroundTransparency = 0.14,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#42615B"),
			Thickness = 1,
			Transparency = 0.5,
		}),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),

		-- Label & description stack
		TextContainer = e("Frame", {
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			Label = e("TextLabel", {
				Size = UDim2.new(1, 0, props.description and 0.55 or 1, 0),
				BackgroundTransparency = 1,
				Text = props.label,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 17,
				TextColor3 = Color3.fromHex("#DEE5D8"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			Desc = props.description and e("TextLabel", {
				Size = UDim2.new(1, 0, 0.45, 0),
				Position = UDim2.new(0, 0, 0.55, 0),
				BackgroundTransparency = 1,
				Text = props.description,
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				TextColor3 = Color3.fromHex("#9FB5AA"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			}) or nil,
		}),

		-- Toggle Switch Pill
		ToggleSwitch = e("ImageButton", {
			Size = UDim2.new(0, 48, 0, 24),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = isChecked and Color3.fromHex("#B8964F") or Color3.fromHex("#28423D"),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			[React.Event.Activated] = function()
				props.onToggle(not isChecked)
			end,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Thumb = e("Frame", {
				Size = UDim2.new(0, 20, 0, 20),
				Position = isChecked and UDim2.new(1, -2, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				AnchorPoint = isChecked and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromHex("#FFFFFF"),
				BorderSizePixel = 0,
			}, {
				ThumbCorner = e("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
	})
end

return ConfigToggle
