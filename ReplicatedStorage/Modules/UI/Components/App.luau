--[[
	App — Root component for the NineRealms UI.

	Composes:
	  - HUD (always visible)
	  - WindowManager (conditionally mounts the active window)
	  - Overlays (death, combat, damage, low health, dialog)

	Provides the UIStore via React Context to all descendants.
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

local StoreContext = require(script.Parent.Parent.Store.StoreContext)
local HUD = require(script.Parent.HUD.HUD)
local WindowManager = require(script.Parent.Windows.WindowManager)
local Overlays = require(script.Parent.Overlays.Overlays)

local function App(props: { store: any })
	return e(StoreContext.Provider, { value = props.store }, {
		MainFrame = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			HUD = e(HUD),
			WindowManager = e(WindowManager),
			Overlays = e(Overlays),
		}),
	})
end

return {
	App = App,
	StoreContext = StoreContext,
}
