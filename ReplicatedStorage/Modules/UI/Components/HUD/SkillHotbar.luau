--[[
	SkillHotbar — Ability bar rendering 4 SkillSlot components.

	Props:
		skills: { [number]: { name: string, icon: string?, isUsable: boolean? } }?
		cooldowns: { [number]: { remaining: number, total: number } }?
		onSkillClick: ((slotIndex: number) -> ())?
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local SkillSlot = require(script.Parent.Parent.Shared.SkillSlot)
local e = React.createElement

export type SkillInfo = {
	name: string,
	icon: string?,
	isUsable: boolean?,
}

export type SkillHotbarProps = {
	skills: { [number]: SkillInfo }?,
	cooldowns: { [number]: { remaining: number, total: number } }?,
	onSkillClick: ((slotIndex: number) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local KEYBINDS = { "1", "2", "3", "4" }

local function SkillHotbar(props: SkillHotbarProps)
	local skills = props.skills or {}
	local cooldowns = props.cooldowns or {}

	local slots: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),
	}

	for i = 1, 4 do
		local skill = skills[i]
		local cd = cooldowns[i] or { remaining = 0, total = 1 }

		slots["Slot_" .. i] = e(SkillSlot, {
			keybind = KEYBINDS[i],
			skillName = skill and skill.name or nil,
			icon = skill and skill.icon or nil,
			isUsable = skill and (skill.isUsable ~= false) or false,
			cooldownRemaining = cd.remaining,
			cooldownTotal = cd.total,
			layoutOrder = i,
			onClick = function()
				if props.onSkillClick then
					props.onSkillClick(i)
				end
			end,
		})
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0, 560, 0, 50),
		Position = props.position or UDim2.new(0.5, 0, 1, -15),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, slots)
end

return SkillHotbar
