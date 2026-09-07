--[[
	ConfigWindow — Graphics and gameplay settings panel.

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local ConfigSettings = require(script.Parent.Parent.Parent.Parent.Data.ConfigSettings)
local ConfigToggle = require(script.Parent.ConfigToggle)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type ConfigWindowProps = {
	onClose: (() -> ())?,
}

local function ConfigWindow(props: ConfigWindowProps)
	local store = React.useContext(StoreContext)

	local configState = useStore(store, function(state)
		return state.config or {}
	end)

	local handleToggle = function(settingId: string, newValue: boolean)
		if store then
			store:dispatch(function(state)
				local cfg = state.config or {}
				cfg[settingId] = newValue
				state.config = cfg
				return state
			end)
		end
	end

	local rows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	}

	for i, setting in ipairs(ConfigSettings) do
		local currentValue = configState[setting.id]
		if currentValue == nil then
			currentValue = setting.defaultValue
		end

		rows[setting.id] = e(ConfigToggle, {
			label = setting.label,
			description = setting.description,
			value = currentValue,
			layoutOrder = i,
			onToggle = function(val)
				handleToggle(setting.id, val)
			end,
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 420, 0, 360),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#0D1413"),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#B8964F"),
			Thickness = 2.5,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("#F2B705")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFF4A3")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#F2B705")),
				}),
				Rotation = 45,
			}),
		}),
		InnerStroke = e("UIStroke", { Color = Color3.fromHex("#42615B"), Thickness = 7, Transparency = 0.68 }),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Close = e(CloseButton, {
			onClick = function()
				if props.onClose then
					props.onClose()
				end
			end,
		}),
		Header = e(WindowLabel, {
			title = "Settings",
			subtitle = "Preferences & Performance",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 8),
		}),
		SettingsScroll = e("ScrollingFrame", {
			Size = UDim2.new(1, -32, 1, -80),
			Position = UDim2.new(0.5, 0, 0, 68),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
		}, rows),
	})
end

return ConfigWindow
