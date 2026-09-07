--[[
	SkillHoverPanel — Detailed skill inspection card with Unlock and Equip actions.

	Props:
		node: { [string]: any }?
		status: ("unlocked" | "available" | "locked" | "blocked")?
		onUnlock: ((nodeId: string) -> ())?
		onEquip: ((nodeId: string, slotIndex: number) -> ())?
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local e = React.createElement

export type SkillHoverPanelProps = {
	node: { [string]: any }?,
	status: ("unlocked" | "available" | "locked" | "blocked")?,
	onUnlock: ((nodeId: string) -> ())?,
	onEquip: ((nodeId: string, slotIndex: number) -> ())?,
	onClose: (() -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local function SkillHoverPanel(props: SkillHoverPanelProps)
	local node = props.node
	if not node then
		return nil
	end

	local status = props.status or "locked"

	return e("Frame", {
		Size = props.size or UDim2.new(0, 280, 0, 320),
		Position = props.position or UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromHex("#14201E"),
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		ZIndex = 15,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#F2B705"),
			Thickness = 2,
		}),
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Close = e(CloseButton, {
			onClick = function()
				if props.onClose then props.onClose() end
			end,
		}),
		Padding = e("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),

		-- Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, -30, 0, 24),
			BackgroundTransparency = 1,
			Text = node.name,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 20,
			TextColor3 = Color3.fromHex("#F2B705"),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}),

		-- Class & Type
		ClassRow = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = string.format("Path: %s %s", node.path or "Root", node.class and ("| " .. node.class) or ""),
			Font = Enum.Font.SourceSans,
			TextSize = 14,
			TextColor3 = Color3.fromHex("#A0A0A0"),
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 2,
		}),

		-- Description
		Description = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 80),
			BackgroundTransparency = 1,
			Text = node.description or "",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 16,
			TextColor3 = Color3.fromHex("#E5E5E5"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LineHeight = 1.2,
			LayoutOrder = 3,
		}),

		-- Stats row
		StatsRow = e("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Cooldown = e("TextLabel", {
				Size = UDim2.new(0.5, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = string.format("Cooldown: %ds", node.cooldown or 0),
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				TextColor3 = Color3.fromHex("#FFF4A3"),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Cost = e("TextLabel", {
				Size = UDim2.new(0.5, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = string.format("Souls: %d", node.soulsCost or 0),
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				TextColor3 = Color3.fromHex("#80D0FF"),
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),

		-- Action Button: Unlock or Equip
		ActionContainer = e("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			LayoutOrder = 5,
		}, {
			UnlockBtn = (status == "available") and e("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromHex("#28423D"),
				BorderSizePixel = 0,
				Text = "UNLOCK SKILL",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 16,
				TextColor3 = Color3.fromHex("#F2B705"),
				[React.Event.Activated] = function()
					if props.onUnlock then props.onUnlock(node.id) end
				end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Stroke = e("UIStroke", { Color = Color3.fromHex("#F2B705"), Thickness = 1.5 }),
			}) or nil,

			EquipRow = (status == "unlocked" and not node.isPassive) and e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 4),
				}),
				Slot1 = e("TextButton", {
					Size = UDim2.new(0.23, 0, 1, 0),
					BackgroundColor3 = Color3.fromHex("#1C302C"),
					BorderSizePixel = 0,
					Text = "Slot 1",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#FFF4A3"),
					[React.Event.Activated] = function() if props.onEquip then props.onEquip(node.id, 1) end end,
				}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
				Slot2 = e("TextButton", {
					Size = UDim2.new(0.23, 0, 1, 0),
					BackgroundColor3 = Color3.fromHex("#1C302C"),
					BorderSizePixel = 0,
					Text = "Slot 2",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#FFF4A3"),
					[React.Event.Activated] = function() if props.onEquip then props.onEquip(node.id, 2) end end,
				}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
				Slot3 = e("TextButton", {
					Size = UDim2.new(0.23, 0, 1, 0),
					BackgroundColor3 = Color3.fromHex("#1C302C"),
					BorderSizePixel = 0,
					Text = "Slot 3",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#FFF4A3"),
					[React.Event.Activated] = function() if props.onEquip then props.onEquip(node.id, 3) end end,
				}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
				Slot4 = e("TextButton", {
					Size = UDim2.new(0.23, 0, 1, 0),
					BackgroundColor3 = Color3.fromHex("#1C302C"),
					BorderSizePixel = 0,
					Text = "Slot 4",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#FFF4A3"),
					[React.Event.Activated] = function() if props.onEquip then props.onEquip(node.id, 4) end end,
				}, { Corner = e("UICorner", { CornerRadius = UDim.new(0, 3) }) }),
			}) or nil,

			LockedText = (status == "locked" or status == "blocked") and e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = (status == "blocked") and "Path Blocked" or "Prerequisites Not Met",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#888888"),
				TextXAlignment = Enum.TextXAlignment.Center,
			}) or nil,
		}),
	})
end

return SkillHoverPanel
