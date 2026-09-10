-- ServerStorage/PartyManager
local PartyManager = {
	Parties = {} -- { [partyId] = { leader = Player, members = { [player.UserId] = Player, ... }, xpShare = true/false } }
}

local HttpService = game:GetService("HttpService")

function PartyManager:CreateParty(leader, xpShare)
	local partyId = HttpService:GenerateGUID(false)
	self.Parties[partyId] = {
		leader = leader,
		members = { [leader.UserId] = leader },
		xpShare = xpShare or false
	}
	return partyId
end

function PartyManager:AddToParty(partyId, player)
	local party = self.Parties[partyId]
	if party then
		party.members[player.UserId] = player
	end
end

function PartyManager:RemoveFromParty(partyId, player)
	local party = self.Parties[partyId]
	if party then
		party.members[player.UserId] = nil
		-- If the leader leaves, disband or reassign leadership
		if party.leader == player then
			if next(party.members) then
				party.leader = next(party.members)
			else
				self.Parties[partyId] = nil
			end
		end
	end
end

function PartyManager:DisbandParty(partyId)
	self.Parties[partyId] = nil
end

function PartyManager:GetPartyMembers(partyId)
	local party = self.Parties[partyId]
	return party and party.members or {}
end

return PartyManager
