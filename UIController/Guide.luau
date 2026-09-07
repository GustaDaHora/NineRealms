-- UIController/Guide.luau
-- Migrated to React-Luau UIStore architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local Guide = {}

function Guide.OpenGuide()
	store:dispatch(function(state)
		state.activeWindow = "Guide"
		return state
	end)
end

function Guide.CloseGuide()
	store:dispatch(function(state)
		if state.activeWindow == "Guide" then
			state.activeWindow = nil
		end
		return state
	end)
end

function Guide.Start()
	-- Guide window is fully managed via React GuideWindow and UIStore.activeWindow
end

return Guide
