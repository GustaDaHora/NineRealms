--[[
	EquipView — Character preview, equipped armor/weapon slots, and stats overview.

	Composes:
	  - CharacterPreview
	  - EquippedSlotGrid
	  - StatPanel (Stats & Info)
	  - ContextMenu (Inspect, Unequip, Hide/Show)

	Props:
		equippedItems: { [string]: any }?
		stats: { [string]: any }?
		onAction: ((actionType: string, slotId: string, item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local CharacterPreview = require(script.Parent.Parent.Parent.Shared.CharacterPreview)
local StatPanel = require(script.Parent.Parent.Parent.Shared.StatPanel)
local ContextMenu = require(script.Parent.Parent.Parent.Shared.ContextMenu)
local EquippedSlotGrid = require(script.Parent.EquippedSlotGrid)
local e = React.createElement

export type EquipViewProps = {
	equippedItems: { [string]: any }?,
	stats: { [string]: any }?,
	onAction: ((actionType: string, slotId: string, item: any) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function EquipView(props: EquipViewProps)
	local selectedSlot, setSelectedSlot = React.useState(nil :: string?)
	local selectedItem, setSelectedItem = React.useState(nil :: any)
	local menuPos, setMenuPos = React.useState(UDim2.new(0.5, 0, 0.5, 0))
	local menuVisible, setMenuVisible = React.useState(false)

	local stats = props.stats or {}

	local statsData = {
		{ label = "Strength", value = stats.strength or 0 },
		{ label = "Vitality", value = stats.vitality or 0 },
		{ label = "Agility", value = stats.agility or 0 },
		{ label = "WeaponPower", value = stats.weaponPower or 0 },
	}

	local infoData = {
		{ label = "Weight", value = stats.weight or 0 },
		{ label = "Armor", value = stats.armor or 0 },
		{ label = "Souls Ratio", value = stats.soulsRatio or "0/0" },
		{ label = "HackSilver", value = stats.hackSilver or 0 },
	}

	local handleSelectSlot = function(slotId: string, item: any)
		-- Empty equipment slots are not actionable.  Opening the context menu for
		-- them exposed actions that could not succeed and made the panel look busy.
		if not item then
			setSelectedSlot(nil)
			setSelectedItem(nil)
			setMenuVisible(false)
			return
		end

		if selectedSlot == slotId and menuVisible then
			setMenuVisible(false)
			setSelectedSlot(nil)
			setSelectedItem(nil)
		else
			setSelectedSlot(slotId)
			setSelectedItem(item)
			setMenuPos(UDim2.new(0.5, 0, 0.45, 0))
			setMenuVisible(true)
		end
	end

	local contextActions = {
		{
			label = "Inspect",
			onClick = function()
				if props.onAction and selectedSlot then
					props.onAction("Inspect", selectedSlot, selectedItem)
				end
			end,
		},
		{
			label = "Unequip",
			onClick = function()
				if props.onAction and selectedSlot then
					props.onAction("Unequip", selectedSlot, selectedItem)
				end
			end,
		},
	}
	if selectedItem and selectedItem.category == "Armors" then
		table.insert(contextActions, {
			label = "Hide / Show",
			onClick = function()
				if props.onAction and selectedSlot then
					props.onAction("ToggleVisibility", selectedSlot, selectedItem)
				end
			end,
		})
	end

	return e("Frame", {
		Size = props.size or UDim2.new(1, 0, 0, 240),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Left: Stats panel
		LeftStats = e("Frame", {
			Size = UDim2.new(0, 150, 0, 112),
			Position = UDim2.new(0, 8, 0, 6),
			BackgroundTransparency = 1,
		}, {
			Panel = e(StatPanel, {
				entries = statsData,
				variant = "chip",
			}),
		}),

		-- Center: Character Viewport
		CenterPreview = e("Frame", {
			Size = UDim2.new(0, 128, 0, 124),
			Position = UDim2.new(0.5, 0, 0, 0),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Preview = e(CharacterPreview, {
				size = UDim2.new(1, 0, 1, 0),
				showName = false,
			}),
		}),

		-- Right: Info panel
		RightInfo = e("Frame", {
			Size = UDim2.new(0, 150, 0, 112),
			Position = UDim2.new(1, -158, 0, 6),
			BackgroundTransparency = 1,
		}, {
			Panel = e(StatPanel, {
				entries = infoData,
				variant = "chip",
			}),
		}),

		-- Bottom: Equipped Slots
		Slots = e(EquippedSlotGrid, {
			equippedItems = props.equippedItems,
			selectedSlot = selectedSlot,
			onSelectSlot = handleSelectSlot,
			size = UDim2.new(1, -16, 0, 126),
			position = UDim2.new(0, 8, 0, 130),
		}),

		-- Context Menu for selected equipped slot
		SlotMenu = e(ContextMenu, {
			actions = contextActions,
			visible = menuVisible,
			position = menuPos,
			anchorPoint = Vector2.new(0.5, 0.5),
			onClose = function()
				setMenuVisible(false)
			end,
		}),
	})
end

return EquipView
