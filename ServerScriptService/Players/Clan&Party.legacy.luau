-- ReplicatedStorage/PartyRemote
local partyRemote = game.ReplicatedStorage.RE.Others.PartyRemote

-- Server Script to Handle Client Requests
local PartyManager = require(game.ServerStorage.Modules.PartyManager)

partyRemote.OnServerEvent:Connect(function(player, action, data)
	if action == "CreateParty" then
		local partyId = PartyManager:CreateParty(player, data.xpShare)
		-- Inform client of the new party ID
		partyRemote:FireClient(player, "PartyCreated", { partyId = partyId })
	elseif action == "JoinParty" then
		PartyManager:AddToParty(data.partyId, player)
	elseif action == "LeaveParty" then
		PartyManager:RemoveFromParty(data.partyId, player)
	elseif action == "DisbandParty" then
		PartyManager:DisbandParty(data.partyId)
	end
end)
