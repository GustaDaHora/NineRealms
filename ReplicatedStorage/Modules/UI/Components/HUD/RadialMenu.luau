--[[
	RadialMenu — Circular expanding navigation hub with 8 buttons.

	Maps to:
	  - Settings -> "Config"
	  - Skills -> "Skills"
	  - Inventory -> "Inventory"
	  - Guide -> "Guide"
	  - Event -> "Events"
	  - Character -> "Character"
	  - Quests -> "Quests"
	  - Clan -> "Clan"

	Props:
		isOpen: boolean?
		onToggle: (() -> ())?
		onSelectWindow: ((windowName: string) -> ())?
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type RadialMenuProps = {
	isOpen: boolean?,
	selectedWindow: string?,
	onToggle: (() -> ())?,
	onSelectWindow: ((windowName: string) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

type MenuItem = {
	name: string,
	window: string?,
	image: string,
	angleDeg: number,
}

local MENU_ITEMS: { MenuItem } = {
	{ name = "Settings", window = "Config", image = "rbxassetid://13850087723", angleDeg = 0 },
	{ name = "Skills", window = "Skills", image = "rbxassetid://13847266549", angleDeg = 45 },
	{ name = "Inventory", window = "Inventory", image = "rbxassetid://14949537990", angleDeg = 90 },
	{ name = "Quests", window = "Quests", image = "rbxassetid://14916810680", angleDeg = 135 },
	{ name = "Clan", window = "Clan", image = "rbxassetid://13850131955", angleDeg = 180 },
	{ name = "Guide", window = "Guide", image = "rbxassetid://14949508699", angleDeg = 225 },
	{ name = "Events", window = "Events", image = "rbxassetid://14923140747", angleDeg = 270 },
	{ name = "Character", window = "Character", image = "rbxassetid://14958934114", angleDeg = 315 },
}

local function RadialMenu(props: RadialMenuProps)
	local isOpen = props.isOpen == true
	local hoveredItem, setHoveredItem = React.useState(nil :: MenuItem?)

	local toggleOpen = function()
		if props.onToggle then
			props.onToggle()
		end
	end

	-- Holding Tab uses the original, centered fast-menu composition. Keeping it
	-- here (rather than in the input controller) makes input state and visual
	-- state a single React tree.
	if isOpen then
		local buttons: { [string]: any } = {}
		for _, item in ipairs(MENU_ITEMS) do
			local isHovered = hoveredItem and hoveredItem.name == item.name
			local isSelected = item.window and item.window == props.selectedWindow
			buttons[item.name] = e("ImageButton", {
				Size = UDim2.fromScale(0.2, 0.2),
				Position = UDim2.fromScale(0.5 + math.cos(math.rad(item.angleDeg)) * 0.4, 0.5 + math.sin(math.rad(item.angleDeg)) * 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Image = item.image,
				ImageColor3 = (isHovered or isSelected) and Color3.fromHex("#FFF4A3") or Color3.fromHex("#F2B705"),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 11,
				[React.Event.MouseEnter] = function() setHoveredItem(item) end,
				[React.Event.MouseLeave] = function()
					if hoveredItem and hoveredItem.name == item.name then setHoveredItem(nil) end
				end,
				[React.Event.Activated] = function()
					if item.window and props.onSelectWindow then
						props.onSelectWindow(item.window)
					end
				end,
			}, {
				Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				RunePlate = e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundColor3 = Color3.fromHex("#15201E"),
					BackgroundTransparency = 0.25,
					BorderSizePixel = 0,
					ZIndex = 10,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
					Stroke = e("UIStroke", {
						Color = (isHovered or isSelected) and Color3.fromHex("#E6D0A2") or Color3.fromHex("#56736A"),
						Thickness = isSelected and 3 or 1.5,
					}),
				}),
				Name = e("TextLabel", {
					Size = UDim2.new(0, 110, 0, 18),
					Position = UDim2.new(0.5, 0, 1, 5),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundTransparency = 1,
					Text = string.upper(item.name),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 13,
					TextColor3 = (isHovered or isSelected) and Color3.fromHex("#E6D0A2") or Color3.fromHex("#B7C3BC"),
					TextStrokeColor3 = Color3.fromHex("#05070A"),
					TextStrokeTransparency = 0.15,
					ZIndex = 12,
				}),
				Selection = isSelected and e("UIStroke", {
					Color = Color3.fromHex("#FFF4A3"),
					Thickness = 3,
				}) or nil,
			})
		end

		return e("Frame", {
			Size = UDim2.fromScale(1, 1),
			-- The full-screen frame is only an input/layout host.  Giving it an
			-- opaque colour made the circular menu read as a square panel.
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 9,
		}, {
			Menu = e("Frame", {
				Size = UDim2.fromScale(0.45, 0.45),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromHex("#111615"),
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0,
				ZIndex = 10,
			}, {
				Aspect = e("UIAspectRatioConstraint", { AspectRatio = 1 }),
				MaximumSize = e("UISizeConstraint", { MaxSize = Vector2.new(560, 560) }),
				Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Ring = e("Frame", {
					Size = UDim2.fromScale(0.8, 0.8),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 10,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(1, 0) }),
					OuterStroke = e("UIStroke", {
						Color = Color3.fromHex("#B8964F"),
						Thickness = 2,
						Transparency = 0.15,
					}),
					InnerStroke = e("UIStroke", {
						Color = Color3.fromHex("#3D5C58"),
						Thickness = 7,
						Transparency = 0.65,
					}),
				}),
				CenterLabel = e("TextLabel", {
					Size = UDim2.fromScale(0.3, 0.3),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Text = props.selectedWindow or "FAST MENU",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 22,
					TextColor3 = Color3.fromHex("#E6D0A2"),
					TextStrokeColor3 = Color3.fromHex("#1B1814"),
					TextStrokeTransparency = 0.2,
					TextScaled = true,
					ZIndex = 12,
				}),
				Buttons = e("Frame", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ZIndex = 10,
				}, buttons),
			}),
		})
	end

	-- Center hub button (always visible)
	local hubSize = 48
	return e("Frame", {
		Size = props.size or UDim2.new(0, 240, 0, 240),
		Position = props.position or UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Center circular hub button
		Hub = e("ImageButton", {
			Size = UDim2.new(0, hubSize, 0, hubSize),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("#1B1814"),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Image = "rbxassetid://14949537990", -- Menu/Inventory icon
			ImageColor3 = Color3.fromHex("#F2B705"),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 6,
			[React.Event.Activated] = toggleOpen,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromHex("#F2B705"),
				Thickness = 2.5,
			}),
			Label = hoveredItem and e("TextLabel", {
				Size = UDim2.new(0, 100, 0, 20),
				Position = UDim2.new(0.5, 0, 1, 8),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Text = hoveredItem.name,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#FFF4A3"),
				TextStrokeColor3 = Color3.fromHex("#1B1814"),
				TextStrokeTransparency = 0.2,
				ZIndex = 7,
			}) or nil,
		}),

	})
end

return RadialMenu
