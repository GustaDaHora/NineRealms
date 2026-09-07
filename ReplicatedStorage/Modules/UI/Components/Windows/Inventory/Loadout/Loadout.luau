--[[
	Loadout — Browsable inventory with category filtering, item grid, and attributes inspection.

	Composes:
	  - CategoryTabs
	  - ItemGrid
	  - AttributesPanel

	Props:
		inventory: { any }?
		onAction: ((action: "Inspect" | "Equip" | "Disposal", item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local CategoryTabs = require(script.Parent.CategoryTabs)
local ItemGrid = require(script.Parent.ItemGrid)
local AttributesPanel = require(script.Parent.AttributesPanel)
local e = React.createElement

export type LoadoutProps = {
	inventory: { any }?,
	onAction: ((action: "Inspect" | "Equip" | "Disposal", item: any) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function Loadout(props: LoadoutProps)
	local selectedCategory, setSelectedCategory = React.useState("Weapons")
	local selectedItem, setSelectedItem = React.useState(nil :: any)

	local rawInventory = props.inventory or {}

	-- Normalize inventory into an array and filter by category
	local filteredItems = {}
	local function includeItem(key: any, item: any)
		local itm = type(item) == "table" and table.clone(item) or { id = tostring(key), name = tostring(key) }
		itm.id = itm.id or tostring(key)
		if itm.category == selectedCategory then
			table.insert(filteredItems, itm)
		end
	end
	-- Preserve array ordering first; keyed entries are appended deterministically.
	for index, item in ipairs(rawInventory) do
		includeItem(index, item)
	end
	for key, item in pairs(rawInventory) do
		if type(key) ~= "number" then
			includeItem(key, item)
		end
	end

	return e("Frame", {
		Size = props.size or UDim2.new(1, 0, 0, 200),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Top category tabs
		Tabs = e(CategoryTabs, {
			selectedCategory = selectedCategory,
			onSelectCategory = function(cat)
				setSelectedCategory(cat)
				setSelectedItem(nil)
			end,
			size = UDim2.new(1, 0, 0, 30),
			position = UDim2.new(0, 0, 0, 0),
		}),

		-- Item grid (left/center)
		Grid = e(ItemGrid, {
			items = filteredItems,
			selectedItemId = selectedItem and selectedItem.id or nil,
			onSelectItem = function(item)
				setSelectedItem(item)
			end,
			size = UDim2.new(1, -230, 1, -34),
			position = UDim2.new(0, 0, 0, 34),
		}),

		-- Attributes inspection (right)
		Attributes = e(AttributesPanel, {
			item = selectedItem,
			onAction = props.onAction,
			size = UDim2.new(0, 220, 1, -34),
			position = UDim2.new(1, -220, 0, 34),
		}),
	})
end

return Loadout
