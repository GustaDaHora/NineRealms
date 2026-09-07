local React = require(game:GetService("ReplicatedStorage").Packages.React)
local NorsePlaceholderWindow = require(script.Parent.NorsePlaceholderWindow)
local e = React.createElement

return function(props)
	return e(NorsePlaceholderWindow, {
		title = "Clan Hall",
		subtitle = "Oaths, kinship, and renown",
		emblem = "rbxassetid://13850131955",
		message = "You have not sworn an oath to a clan. Clan rosters and invitations will be shown here when the realm system is available.",
		sections = {
			{ heading = "Your Clan", text = "No clan oath has been registered." },
			{ heading = "Hall Notices", text = "Clan invitations and realm announcements will appear here." },
		},
		onClose = props.onClose,
	})
end
