--[[
	CategoryShopWindow — Unified window for Shop, Crafting, and BonFire interactions.

	Props:
		mode: ("Shop" | "Crafting" | "BonFire")?
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local TabButton = require(script.Parent.Parent.Parent.Shared.TabButton)
local ItemCard = require(script.Parent.ItemCard)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local MoneyDisplay = require(script.Parent.Parent.Parent.Shared.MoneyDisplay)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type CategoryShopWindowProps = {
	mode: ("Shop" | "Crafting" | "BonFire")?,
	onClose: (() -> ())?,
}

local DEFAULT_SHOP_CATEGORIES = {
	"Weapons",
	"Armours",
	"Food",
	"Herbs",
	"Resources",
	"Sell",
}

local DEFAULT_CRAFTING_CATEGORIES = {
	"Weapons",
	"Armours",
	"Herbs",
	"Resources",
}

local DEFAULT_BONFIRE_CATEGORIES = {
	"Food",
	"Elixirs",
	"Rest",
}

local function CategoryShopWindow(props: CategoryShopWindowProps)
	local mode = props.mode or "Shop"

	local store = React.useContext(StoreContext)

	local money = useStore(store, function(state)
		return state.money or 0
	end)

	local shopItems = useStore(store, function(state)
		return state.shopItems
	end)

	local categories = DEFAULT_SHOP_CATEGORIES
	local windowTitle = "Village Merchant"
	if mode == "Crafting" then
		categories = DEFAULT_CRAFTING_CATEGORIES
		windowTitle = "Blacksmith Forge"
	elseif mode == "BonFire" then
		categories = DEFAULT_BONFIRE_CATEGORIES
		windowTitle = "Campfire & Cooking"
	end

	local selectedCategory, setSelectedCategory = React.useState(categories[1] or "Weapons")

	local allItems = shopItems or {}
	local filteredItems = {}
	for _, itm in ipairs(allItems) do
		if itm.category == selectedCategory then
			table.insert(filteredItems, itm)
		end
	end

	local handleItemAction = function(item: any)
		if not store then return end
		if item and item.onAction then
			item.onAction(item)
			return
		end
		if mode == "Shop" then
			local price = item.price or 0
			if money >= price then
				store:dispatch(function(state)
					state.money = (state.money or 0) - price
					local inv = state.inventory or {}
					table.insert(inv, {
						id = item.id .. "_" .. tostring(os.time()),
						name = item.name,
						icon = item.icon,
						category = item.category,
						weight = item.weight or 1,
						value = math.floor(price * 0.6),
					})
					state.inventory = inv
					return state
				end)
			end
		end
	end

	-- Category Tabs (Left)
	local tabButtons: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	}
	for i, cat in ipairs(categories) do
		tabButtons[cat] = e(TabButton, {
			label = cat,
			isSelected = (cat == selectedCategory),
			onClick = function()
				setSelectedCategory(cat)
			end,
			layoutOrder = i,
		})
	end

	-- Item Cards List (Right)
	local cardElements: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	}
	for i, itm in ipairs(filteredItems) do
		local canAfford = (mode ~= "Shop") or (money >= (itm.price or 0))
		cardElements[itm.id or tostring(i)] = e(ItemCard, {
			item = itm,
			mode = mode,
			canAfford = canAfford,
			onAction = handleItemAction,
			layoutOrder = i,
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 700, 0, 480),
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
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Close = e(CloseButton, {
			onClick = function()
				if props.onClose then props.onClose() end
			end,
		}),
		Header = e(WindowLabel, {
			title = windowTitle,
			subtitle = mode .. " Catalog",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 8),
		}),

		-- Currency Display (Top Right)
		Currency = e("Frame", {
			Size = UDim2.new(0, 140, 0, 26),
			Position = UDim2.new(1, -50, 0, 18),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			Display = e(MoneyDisplay, {
				amount = money,
				textSize = 16,
			}),
		}),

		-- Left Sidebar: Category Tabs
		Sidebar = e("Frame", {
			Size = UDim2.new(0, 160, 1, -80),
			Position = UDim2.new(0, 20, 0, 68),
			BackgroundTransparency = 1,
		}, tabButtons),

		-- Right Section: Items Scrolling List
		ItemsMenu = e("ScrollingFrame", {
			Size = UDim2.new(1, -210, 1, -80),
			Position = UDim2.new(0, 190, 0, 68),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, math.max(340, #filteredItems * 90)),
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
		}, #filteredItems > 0 and cardElements or {
			Empty = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = "No items in this category",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 16,
				TextColor3 = Color3.fromHex("#888888"),
			}),
		}),
	})
end

return CategoryShopWindow
