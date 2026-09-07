--[[
	WindowManager — Controls mounting and unmounting of top-level game windows.

	Subscribes to UIStore.activeWindow:
	  - "Guide" -> GuideWindow
	  - "Config" -> ConfigWindow
	  - "Events" -> EventsWindow
	  - "Character" -> CharacterWindow
	  - "Inventory" -> InventoryWindow
	  - "Shop" | "Crafting" | "BonFire" -> CategoryShopWindow
	  - "Skills" -> SkillsWindow
	  - "Quests" -> QuestsWindow
	  - "Clan" -> ClanWindow
	  - nil -> nothing mounted
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local useStore = require(script.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Store.StoreContext)

local GuideWindow = require(script.Parent.Guide.GuideWindow)
local ConfigWindow = require(script.Parent.Config.ConfigWindow)
local EventsWindow = require(script.Parent.Events.EventsWindow)

local e = React.createElement

local function WindowManager()
	local store = React.useContext(StoreContext)
	local viewportSize, setViewportSize = React.useState(function()
		local camera = workspace.CurrentCamera
		return camera and camera.ViewportSize or Vector2.new(1920, 1080)
	end)

	local activeWindow = useStore(store, function(state)
		return state.activeWindow
	end)

	local closeWindow = function()
		if store then
			store:dispatch(function(state)
				state.activeWindow = nil
				return state
			end)
		end
	end

	-- All windows share an offset-based desktop composition. Scale that
	-- composition as one unit on smaller viewports so it remains centered and
	-- never extends beyond the screen while retaining its internal alignment.
	React.useEffect(function()
		local cameraConnection: RBXScriptConnection? = nil
		local function observeCamera()
			if cameraConnection then
				cameraConnection:Disconnect()
				cameraConnection = nil
			end
			local camera = workspace.CurrentCamera
			if camera then
				setViewportSize(camera.ViewportSize)
				cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
					setViewportSize(camera.ViewportSize)
				end)
			end
		end
		observeCamera()
		local currentCameraConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(observeCamera)
		return function()
			if cameraConnection then cameraConnection:Disconnect() end
			currentCameraConnection:Disconnect()
		end
	end, {})

	if not activeWindow then
		return nil
	end

	local windowScale = math.clamp(math.min(1, (viewportSize.X - 28) / 920, (viewportSize.Y - 28) / 690), 0.15, 1)

	local windowElement = nil

	if activeWindow == "Guide" then
		windowElement = e(GuideWindow, { onClose = closeWindow })
	elseif activeWindow == "Config" then
		windowElement = e(ConfigWindow, { onClose = closeWindow })
	elseif activeWindow == "Events" then
		windowElement = e(EventsWindow, { onClose = closeWindow })
	elseif activeWindow == "Character" then
		local CharacterWindow = require(script.Parent.Character.CharacterWindow)
		windowElement = e(CharacterWindow, { onClose = closeWindow })
	elseif activeWindow == "Inventory" then
		local InventoryWindow = require(script.Parent.Inventory.InventoryWindow)
		windowElement = e(InventoryWindow, { onClose = closeWindow })
	elseif activeWindow == "Shop" or activeWindow == "Crafting" or activeWindow == "BonFire" then
		local CategoryShopWindow = require(script.Parent.Shop.CategoryShopWindow)
		windowElement = e(CategoryShopWindow, { mode = activeWindow, onClose = closeWindow })
	elseif activeWindow == "Skills" then
		local SkillsWindow = require(script.Parent.Skills.SkillsWindow)
		windowElement = e(SkillsWindow, { onClose = closeWindow })
	elseif activeWindow == "Quests" then
		local QuestsWindow = require(script.Parent.QuestsWindow)
		windowElement = e(QuestsWindow, { onClose = closeWindow })
	elseif activeWindow == "Clan" then
		local ClanWindow = require(script.Parent.ClanWindow)
		windowElement = e(ClanWindow, { onClose = closeWindow })
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5, -- Dark scrim backdrop
		BorderSizePixel = 0,
		ZIndex = 4,
	}, {
		-- Blocks pointer/touch input from reaching the HUD while a window is open.
		-- It intentionally has no event handler: only each window's X may dismiss.
		InputShield = e("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 4,
		}),
		ScaledWindow = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, {
			Scale = e("UIScale", { Scale = windowScale }),
			Window = windowElement,
		}),
	})
end

return WindowManager
