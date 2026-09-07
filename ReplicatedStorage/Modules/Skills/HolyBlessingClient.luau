-- HolyBlessingClient.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UseSkillRE = ReplicatedStorage.RE.Others:WaitForChild("UseSkill") -- RemoteEvent
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local HolyBlessingClient = {}

function HolyBlessingClient.Activate()
	local character = Player.Character
	if not character then
		return
	end

	-- Check if player has enough souls (this should be validated server-side as well)
	local soulValue = Player:FindFirstChild("Souls")
	--if not soulValue or soulValue.Value < 70 then
	--	-- Notify player not enough souls
	--	return
	--end

	-- Send request to server
	UseSkillRE:FireServer("Holy Blessing")

	-- Visual effects handled by server response
	-- Could add UI effects here like cooldown display
end

return HolyBlessingClient
