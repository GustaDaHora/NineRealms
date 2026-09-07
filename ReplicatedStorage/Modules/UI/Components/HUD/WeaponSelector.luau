--[[
	WeaponSelector — Rotating orb with 3 weapon bubbles on the right side of the screen.

	Features:
	  - 3 weapon bubbles arranged in a circular ring.
	  - Cycles via keybind (default: Z).
	  - Smoothly rotates active weapon to the front indicator position.
	  - Weapon artwork stays upright.
	  - Fixed gold indicator marks active front position.

	Props:
		weapons: { [number]: { name: string, icon: string? } }?
		activeIndex: number? (1, 2, or 3)
		onCycle: ((newIndex: number) -> ())?
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local IconRing = require(script.Parent.Parent.Shared.IconRing)
local e = React.createElement

export type WeaponItem = {
	name: string,
	icon: string?,
}

export type WeaponSelectorProps = {
	weapons: { [number]: WeaponItem }?,
	activeIndex: number?,
	onCycle: ((newIndex: number) -> ())?,
	size: UDim2?,
	position: UDim2?,
}

local RADIUS = 42
local FRONT_ANGLE = -math.pi / 2 -- Top is the active/front position

local function WeaponSelector(props: WeaponSelectorProps)
	local weapons = props.weapons or {}
	local weaponCount = #weapons
	local activeIndex = math.clamp(props.activeIndex or 1, 1, math.max(weaponCount, 1))
	local currentAngle, setCurrentAngle = React.useBinding(FRONT_ANGLE)
	local targetAngleRef = React.useRef(FRONT_ANGLE)

	-- Update target angle when activeIndex changes
	React.useEffect(function()
		-- Angle offset for slot: slot 1 -> 0, slot 2 -> 2pi/3, slot 3 -> 4pi/3
		-- To bring slot activeIndex to FRONT_ANGLE: currentRotation + slotAngle = FRONT_ANGLE
		local slotAngle = (activeIndex - 1) * (2 * math.pi / 3)
		targetAngleRef.current = FRONT_ANGLE - slotAngle
	end, { activeIndex } :: { any })

	-- Smooth rotation animation loop
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function(dt)
			local target = targetAngleRef.current
			local current = currentAngle:getValue()
			local diff = target - current

			-- Normalize diff to shortest turn
			while diff > math.pi do diff = diff - 2 * math.pi end
			while diff < -math.pi do diff = diff + 2 * math.pi end

			if math.abs(diff) > 0.005 then
				local step = diff * math.clamp(dt * 12, 0, 1)
				setCurrentAngle(current + step)
			else
				setCurrentAngle(target)
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	-- Keybind listener for cycling
	React.useEffect(function()
		local connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end
			-- Cycle key: Z (customizable)
		if input.KeyCode == Enum.KeyCode.Z and weaponCount > 1 then
			local nextIdx = (activeIndex % weaponCount) + 1
				if props.onCycle then
					props.onCycle(nextIdx)
				end
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, { activeIndex, weaponCount, props.onCycle } :: { any })

	-- Compute bubble positions mapped from currentAngle binding
	local bubbles: { [string]: any } = {}
	for i = 1, 3 do
		local initialSlotAngle = (i - 1) * (2 * math.pi / 3)
		local isActive = (i == activeIndex)
		local weapon = weapons[i]

		local posBinding = currentAngle:map(function(ang)
			local effAngle = ang + initialSlotAngle
			local x = math.cos(effAngle) * RADIUS
			local y = math.sin(effAngle) * RADIUS
			return UDim2.new(0.5, x, 0.5, y)
		end)

		bubbles["Slot_" .. i] = e("Frame", {
			Size = UDim2.new(0, 36, 0, 36),
			Position = posBinding,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = isActive and 3 or 2,
		}, {
			Ring = e(IconRing, {
				size = UDim2.new(1, 0, 1, 0),
				image = weapon and weapon.icon or nil,
				strokeColor = isActive and Color3.fromHex("#F2B705") or Color3.fromHex("#666666"),
				strokeThickness = isActive and 2.5 or 1.5,
				cornerRadius = UDim.new(1, 0), -- circular bubble
			}),
		})
	end

	return e("Frame", {
		Size = props.size or UDim2.new(0, 120, 0, 120),
		Position = props.position or UDim2.new(1, -20, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromHex("#1B1814"),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
	}, {
		-- Central orb styling
		Corner = e("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		OuterStroke = e("UIStroke", {
			Color = Color3.fromHex("#F2B705"),
			Thickness = 2,
			Transparency = 0.3,
		}),

		-- Fixed active position indicator (pointing to top front position)
		ActiveIndicator = e("Frame", {
			Size = UDim2.new(0, 8, 0, 8),
			Position = UDim2.new(0.5, 0, 0, 4),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromHex("#F2B705"),
			Rotation = 45,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, {
			Glow = e("UIStroke", {
				Color = Color3.fromHex("#FFF4A3"),
				Thickness = 1.5,
			}),
		}),

		-- Keybind hint label
		KeybindHint = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "[Z]",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 13,
			TextColor3 = Color3.fromHex("#F2B705"),
			TextStrokeColor3 = Color3.fromHex("#1B1814"),
			TextStrokeTransparency = 0.2,
			ZIndex = 1,
		}),

		BubblesContainer = e("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, bubbles),
	})
end

return WeaponSelector
