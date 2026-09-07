--[[
	ItemCard — Card display for shop items and crafting recipes.

	Adapts depending on mode:
	  - "Shop": Displays purchase price and "Buy" action.
	  - "Crafting": Displays ingredient requirements and "Craft" action.
	  - "BonFire": Displays fuel/cooking ingredients and "Cook" action.

	Props:
		item: { [string]: any }
		mode: ("Shop" | "Crafting" | "BonFire")?
		canAfford: boolean?
		onAction: ((item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Parent.Shared.IconRing)
local e = React.createElement

export type ItemCardProps = {
	item: { [string]: any },
	mode: ("Shop" | "Crafting" | "BonFire")?,
	canAfford: boolean?,
	onAction: ((item: any) -> ())?,
	layoutOrder: number?,
}

local function ItemCard(props: ItemCardProps)
	local item = props.item or {}
	local mode = props.mode or "Shop"
	local canAfford = (props.canAfford ~= false)

	local actionText = "Buy"
	if mode == "Crafting" then
		actionText = "Craft"
	elseif mode == "BonFire" then
		actionText = "Cook"
	end

	-- Subtitle/price/ingredients readout
	local subText = ""
	if mode == "Shop" then
		subText = string.format("Price: $%s", tostring(item.price or 0))
	elseif item.ingredients then
		local ingList = {}
		for _, ing in ipairs(item.ingredients) do
			table.insert(ingList, string.format("%s (%d/%d)", ing.name, ing.owned or 0, ing.required or 1))
		end
		subText = table.concat(ingList, ", ")
	end

	return e("Frame", {
		Size = UDim2.new(1, 0, 0, 82),
		BackgroundColor3 = Color3.fromHex("#16211F"),
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#56736A"),
			Thickness = 1.5,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHex("#42615B")),
				ColorSequenceKeypoint.new(0.5, Color3.fromHex("#B8964F")),
				ColorSequenceKeypoint.new(1, Color3.fromHex("#42615B")),
				}),
			}),
		}),
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),

		-- Item icon slot (left)
		IconSlot = e("Frame", {
			Size = UDim2.new(0, 64, 0, 64),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
		}, {
			Ring = e(IconRing, {
				size = UDim2.new(1, 0, 1, 0),
				image = item.icon or "rbxassetid://16751205466",
				strokeThickness = 1.5,
			}),
		}),

		-- Info text stack (center)
		InfoStack = e("Frame", {
			Size = UDim2.new(1, -164, 1, 0),
			Position = UDim2.new(0, 72, 0, 0),
			BackgroundTransparency = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),
			NameText = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				Text = item.name or "Unknown Item",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 18,
				TextColor3 = Color3.fromHex("#DEE5D8"),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 1,
			}),
			SubLabel = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = subText,
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				TextColor3 = canAfford and Color3.fromHex("#F2E079") or Color3.fromHex("#B60000"),
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 2,
			}),
			DescText = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = item.description or "",
				Font = Enum.Font.SourceSans,
				TextSize = 13,
				TextColor3 = Color3.fromHex("#A0A0A0"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = 3,
			}),
		}),

		-- Action Button (right)
		ActionButton = e("TextButton", {
			Size = UDim2.new(0, 78, 0, 36),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = canAfford and Color3.fromHex("#28423D") or Color3.fromHex("#242827"),
			BackgroundTransparency = 0.05,
			BorderSizePixel = 0,
			Text = actionText,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 16,
			TextColor3 = canAfford and Color3.fromHex("#E6D0A2") or Color3.fromHex("#777777"),
			AutoButtonColor = canAfford,
			[React.Event.Activated] = function()
				if canAfford and props.onAction then
					props.onAction(item)
				end
			end,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Stroke = e("UIStroke", {
				Color = canAfford and Color3.fromHex("#B8964F") or Color3.fromHex("#3D4A46"),
				Thickness = 1,
			}),
		}),
	})
end

return ItemCard
