--[[
	UI Entry Point — Creates the React root and mounts the App into PlayerGui.

	Usage from a LocalScript:
		local UI = require(ReplicatedStorage.Modules.UI)
		-- UI is now mounted. Access store via UI.store to dispatch from game scripts.

	Game logic dispatches to the store:
		UI.store:dispatch(function(state)
			state.health = 50
			return state
		end)
]]

local Players = game:GetService("Players")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local ReactRoblox = require(game:GetService("ReplicatedStorage").Packages.ReactRoblox)

local UIStore = require(script.Store.UIStore)
local AppModule = require(script.Components.App)

local App = AppModule.App
local e = React.createElement

local UI = {}

-- Create the store singleton
UI.store = UIStore.new()

-- Expose context for external use
UI.StoreContext = require(script.Store.StoreContext)

function UI:mount()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Create a new ScreenGui for the React-managed UI
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NineRealmsUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	-- Create the React root
	local root = ReactRoblox.createRoot(Instance.new("Folder"))

	-- Render via portal into the ScreenGui
	root:render(ReactRoblox.createPortal(
		e(App, { store = UI.store }),
		screenGui
	))

	UI._root = root
	UI._screenGui = screenGui

	return UI
end

function UI:unmount()
	if UI._root then
		UI._root:unmount()
		UI._root = nil
	end
	if UI._screenGui then
		UI._screenGui:Destroy()
		UI._screenGui = nil
	end
end

-- Auto-mount on require
UI:mount()

return UI
