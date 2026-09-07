-- UIController/FastMenu.luau
-- Migrated to React-Luau UIStore architecture

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local FastMenu = {}

local MOUSE_THRESHOLD = 20
local isHoldingTab = false
local selectedWindow = nil

-- `math.atan2` returns -180..180 degrees. These eight sectors deliberately
-- use that native range so the -180/180 join is Clan's continuous sector,
-- rather than a gap or an accidental fallback. Their directions exactly
-- match RadialMenu's rendered positions (0° is right; positive Y is down).
local windowsBySector = {
	[0] = "Config", -- -22.5° .. 22.5°
	[1] = "Skills",
	[2] = "Inventory",
	[3] = "Quests",
	[4] = "Clan", -- spans the -180° / 180° boundary
	[5] = "Guide",
	[6] = "Events",
	[7] = "Character",
}

local function getWindowForAngle(angle: number): string
	local sector = math.floor((angle + 22.5) / 45) % 8
	return windowsBySector[sector]
end

local function calculateSelectedWindow(): string
	local mouseLocation = UserInputService:GetMouseLocation()
	local camera = workspace.CurrentCamera
	if not camera then
		return ""
	end
	local delta = mouseLocation - (camera.ViewportSize * 0.5)
	if delta.Magnitude < MOUSE_THRESHOLD then
		return ""
	end

	return getWindowForAngle(math.deg(math.atan2(delta.Y, delta.X)))
end

local function updateSelection()
	if not isHoldingTab then
		return
	end

	local nextSelection = calculateSelectedWindow()
	if nextSelection == "" then
		nextSelection = nil
	end
	if nextSelection == selectedWindow then
		return
	end

	selectedWindow = nextSelection
	store:dispatch(function(state)
		state.fastMenuSelection = nextSelection
		return state
	end)
end

function FastMenu.Start()
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab then
			-- Tab is consumed by some CoreGui paths. It is still the game's fast-menu
			-- binding unless the player is actively typing into a text box.
			if UserInputService:GetFocusedTextBox() then
				return
			end
			isHoldingTab = true
			selectedWindow = nil
			store:dispatch(function(state)
				state.fastMenuOpen = true
				state.fastMenuSelection = nil
				return state
			end)
			updateSelection()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSelection()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab and isHoldingTab then
			isHoldingTab = false
			local targetWindow = calculateSelectedWindow()
			selectedWindow = nil

			store:dispatch(function(state)
				state.fastMenuOpen = false
				state.fastMenuSelection = nil
				if targetWindow ~= "" then
					state.activeWindow = targetWindow
				else
					-- A quick Tab opens Inventory but never closes an existing window.
					state.activeWindow = state.activeWindow or "Inventory"
				end
				return state
			end)
		end
	end)
end

return FastMenu
