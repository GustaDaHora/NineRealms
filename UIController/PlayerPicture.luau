--// Services
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

--// Hud
local GUI = script.Parent.Parent
local ImageLabel = GUI.Hud.Face.ImageLabel -- Change to ImageLabel instead of ViewportFrame

--// Functions
local player = Players.LocalPlayer

-- Function to get the player's profile picture
local function setPlayerProfilePicture(userId)
	local url = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId)
	ImageLabel.Image = url
end

local PlayerPicture = {}

function PlayerPicture.Start()
	-- Set the player's profile picture
	setPlayerProfilePicture(player.UserId)
end

return PlayerPicture
