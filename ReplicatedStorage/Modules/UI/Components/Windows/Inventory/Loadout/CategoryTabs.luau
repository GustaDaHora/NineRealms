--[[
	CategoryTabs — Horizontal row of category selection tabs for Loadout.

	Props:
		categories: { string }
		selectedCategory: string
		onSelectCategory: (category: string) -> ()
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local TabButton = require(script.Parent.Parent.Parent.Parent.Shared.TabButton)
local e = React.createElement

export type CategoryTabsProps = {
	categories: { string }?,
	selectedCategory: string,
	onSelectCategory: (category: string) -> (),
	size: UDim2?,
	position: UDim2?,
}

local DEFAULT_CATEGORIES = {
	"Weapons",
	"Armors",
	"Shields",
	"Food",
	"Herbs",
	"Resources",
	"Artifacts",
}

local function CategoryTabs(props: CategoryTabsProps)
	local categories = props.categories or DEFAULT_CATEGORIES

	local tabs: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	}

	for i, cat in ipairs(categories) do
		tabs[cat] = e(TabButton, {
			label = cat,
			isSelected = (cat == props.selectedCategory),
			onClick = function()
				props.onSelectCategory(cat)
			end,
			size = UDim2.new(0, 80, 0, 28),
			layoutOrder = i,
		})
	end

	return e("ScrollingFrame", {
		Size = props.size or UDim2.new(1, 0, 0, 32),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, #categories * 86, 0, 0),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
	}, tabs)
end

return CategoryTabs
