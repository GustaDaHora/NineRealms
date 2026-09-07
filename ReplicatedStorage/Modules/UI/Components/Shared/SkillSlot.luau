--[[
	SkillSlot — Single numbered/keybound ability slot.

	Props:
		keybind: string (e.g., "1", "2", "3", "4" or "Q", "E", "R", "F")
		skillName: string?
		icon: string?
		cooldownRemaining: number?
		cooldownTotal: number?
		isUsable: boolean?
		onClick: (() -> ())?
		size: UDim2?
		position: UDim2?
		layoutOrder: number?

	Used by:
		- HUD SkillHotbar (slots 1-4)
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type SkillSlotProps = {
	keybind: string,
	skillName: string?,
	icon: string?,
	cooldownRemaining: number?,
	cooldownTotal: number?,
	isUsable: boolean?,
	onClick: (() -> ())?,
	size: UDim2?,
	position: UDim2?,
	layoutOrder: number?,
}

local function SkillSlot(props: SkillSlotProps)
	local cdRemaining = props.cooldownRemaining or 0
	local cdTotal = props.cooldownTotal or 1
	local onCooldown = cdRemaining > 0
	local cdRatio = onCooldown and math.clamp(cdRemaining / cdTotal, 0, 1) or 0

	local displayText = props.skillName or ""
	if onCooldown then
		displayText = string.format("%.1fs", cdRemaining)
	end

	return e("ImageButton", {
		Size = props.size or UDim2.new(0, 130, 0, 42),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		Image = "rbxassetid://13694032648",
		ImageColor3 = Color3.fromHex("#39322B"),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		[React.Event.Activated] = props.onClick,
	}, {
		-- Decorative keybind badge
		KeybindBadge = e("ImageLabel", {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(1, -4, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			Image = "rbxassetid://13694071270",
			ImageColor3 = Color3.fromHex("#F2B705"),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, {
			KeyText = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = props.keybind,
				Font = Enum.Font.Fantasy,
				TextSize = 14,
				TextColor3 = Color3.fromHex("#FFFFFF"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),

		-- Skill icon (if provided)
		Icon = props.icon and e("ImageLabel", {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(0, 8, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Image = props.icon,
			ImageColor3 = (props.isUsable ~= false) and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 120),
			ZIndex = 2,
		}) or nil,

		-- Skill name or cooldown readout
		SkillLabel = e("TextLabel", {
			Size = UDim2.new(1, props.icon and -65 or -35, 0.6, 0),
			Position = UDim2.new(0, props.icon and 40 or 10, 0.2, 0),
			BackgroundTransparency = 1,
			Text = displayText,
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 13,
			TextColor3 = onCooldown and Color3.fromHex("#F2B705") or Color3.fromHex("#FFFFFF"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 2,
		}),

		-- Cooldown background bar
		CooldownBg = onCooldown and e("Frame", {
			Size = UDim2.new(0.8, 0, 0, 3),
			Position = UDim2.new(0.1, 0, 0.85, 0),
			BackgroundColor3 = Color3.fromHex("#949494"),
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Fill = e("Frame", {
				Size = UDim2.new(cdRatio, 0, 1, 0),
				BackgroundColor3 = Color3.fromHex("#F2B705"),
				BorderSizePixel = 0,
			}),
		}) or nil,
	})
end

return SkillSlot
