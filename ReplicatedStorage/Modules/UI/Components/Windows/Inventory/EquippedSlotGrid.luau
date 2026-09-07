--[[
	EquippedSlotGrid — Unified grid of equipped armor and weapon slots.

	Renders:
	  - Armors: Helmet, Chestplate, Leggings, Boots
	  - Weapons/Artifacts: MainWeapon, Artifact1, Artifact2, Artifact3
	From a single canonical slot definition array.

	Props:
		equippedItems: { [string]: any }?
		selectedSlot: string?
		onSelectSlot: ((slotId: string, item: any) -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Parent.Shared.IconRing)
local e = React.createElement

export type SlotDefinition = {
	id: string,
	label: string,
	category: "weapon" | "armor",
}

local SLOTS: { SlotDefinition } = {
	-- Weapons / Artifacts (Left Column)
	{ id = "MainWeapon", label = "Main Weapon", category = "weapon" },
	{ id = "Artifact1", label = "Artifact 1", category = "weapon" },
	{ id = "Artifact2", label = "Artifact 2", category = "weapon" },
	{ id = "Artifact3", label = "Artifact 3", category = "weapon" },
	-- Armors (Right Column)
	{ id = "Helmet", label = "Helmet", category = "armor" },
	{ id = "Chestplate", label = "Chestplate", category = "armor" },
	{ id = "Leggings", label = "Leggings", category = "armor" },
	{ id = "Boots", label = "Boots", category = "armor" },
}

export type EquippedSlotGridProps = {
	equippedItems: { [string]: any }?,
	selectedSlot: string?,
	onSelectSlot: ((slotId: string, item: any) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function EquippedSlotGrid(props: EquippedSlotGridProps)
	local equipped = props.equippedItems or {}

	local weaponSlots: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		}),
	}

	local armorSlots: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 3),
		}),
	}

	for i, slot in ipairs(SLOTS) do
		local item = equipped[slot.id]
		local isSelected = (props.selectedSlot == slot.id)

		local slotButton = e("TextButton", {
			Size = UDim2.new(1, 0, 0, 28),
			BackgroundColor3 = isSelected and Color3.fromHex("#28423D") or Color3.fromHex("#14201E"),
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = i,
			[React.Event.Activated] = function()
				if props.onSelectSlot then
					props.onSelectSlot(slot.id, item)
				end
			end,
		}, {
			Stroke = e("UIStroke", {
				Color = isSelected and Color3.fromHex("#FFF4A3") or Color3.fromHex("#42615B"),
				Thickness = isSelected and 2 or 1,
			}),
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			IconContainer = e("Frame", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
			}, {
				Ring = e(IconRing, {
					size = UDim2.new(1, 0, 1, 0),
					image = item and item.icon or nil,
					strokeColor = isSelected and Color3.fromHex("#F2B705") or Color3.fromHex("#666666"),
					strokeThickness = 1,
				}),
			}),
			Label = e("TextLabel", {
				Size = UDim2.new(1, -34, 1, 0),
				Position = UDim2.new(0, 32, 0, 0),
				BackgroundTransparency = 1,
				Text = item and item.name or slot.label,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = item and Color3.fromHex("#FFFFFF") or Color3.fromHex("#888888"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		})

		if slot.category == "weapon" then
			weaponSlots[slot.id] = slotButton
		else
			armorSlots[slot.id] = slotButton
		end
	end

	return e("Frame", {
		Size = props.size or UDim2.new(1, 0, 0, 126),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		WeaponsColumn = e("Frame", {
			Size = UDim2.new(0.48, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		}, weaponSlots),
		ArmorsColumn = e("Frame", {
			Size = UDim2.new(0.48, 0, 1, 0),
			Position = UDim2.new(0.52, 0, 0, 0),
			BackgroundTransparency = 1,
		}, armorSlots),
	})
end

return EquippedSlotGrid
