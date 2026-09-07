--[[
	InventoryWindow — Top-level inventory screen combining EquipView and Loadout.

	Composes:
	  - EquipView (equipped gear & stats)
	  - Loadout (browsable inventory & inspection)
	  - WindowLabel & CloseButton

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local EquipView = require(script.Parent.EquipView)
local Loadout = require(script.Parent.Loadout.Loadout)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type InventoryWindowProps = {
	onClose: (() -> ())?,
}

local function InventoryWindow(props: InventoryWindowProps)
	local store = React.useContext(StoreContext)

	local invState = useStore(store, function(state)
		return {
			equipped = state.equippedItems or {},
			inventory = state.inventory or {},
			stats = state.playerStats or {},
			inventoryAction = state.inventoryAction,
		}
	end)

	local handleEquipAction = function(actionType: string, slotId: string, item: any)
		if item and invState.inventoryAction then
			invState.inventoryAction(actionType, item)
		end
	end

	local handleLoadoutAction = function(actionType: string, item: any)
		if item and invState.inventoryAction then
			invState.inventoryAction(actionType, item)
		end
	end

	return e("Frame", {
		Size = UDim2.new(0, 760, 0, 640),
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
			title = "Inventory & Equipment",
			size = UDim2.new(1, 0, 0, 46),
			position = UDim2.new(0, 0, 0, 6),
		}),

		-- Upper half: EquipView
		EquipSection = e(EquipView, {
			equippedItems = invState.equipped,
			stats = invState.stats,
			onAction = handleEquipAction,
			size = UDim2.new(1, -32, 0, 260),
			position = UDim2.new(0.5, 0, 0, 54),
			anchorPoint = Vector2.new(0.5, 0),
		}),

		-- Divider between EquipView and Loadout
		Divider = e("Frame", {
			Size = UDim2.new(1, -40, 0, 2),
			Position = UDim2.new(0.5, 0, 0, 320),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromHex("#F2B705"),
			BorderSizePixel = 0,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("#1B1814")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("#F2B705")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#1B1814")),
				}),
			}),
		}),

		-- Lower half: Loadout
		LoadoutSection = e(Loadout, {
			inventory = invState.inventory,
			onAction = handleLoadoutAction,
			size = UDim2.new(1, -32, 0, 285),
			position = UDim2.new(0.5, 0, 0, 330),
			anchorPoint = Vector2.new(0.5, 0),
		}),
	})
end

return InventoryWindow
