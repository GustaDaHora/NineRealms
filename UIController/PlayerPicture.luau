-- UIController/PlayerPicture.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local PlayerPicture = {}

function PlayerPicture.Start()
	local url = string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png",
		player.UserId
	)
	store:dispatch(function(state)
		state.playerAvatarUrl = url
		return state
	end)
end

return PlayerPicture
