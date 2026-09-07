local React = require(game:GetService("ReplicatedStorage").Packages.React)
local NorsePlaceholderWindow = require(script.Parent.NorsePlaceholderWindow)
local e = React.createElement

return function(props)
	return e(NorsePlaceholderWindow, {
		title = "Quest Ledger",
		subtitle = "The sagas awaiting your hand",
		emblem = "rbxassetid://14916810680",
		message = "No quests are currently bound to your saga. Seek a marked NPC or return when a new tale begins.",
		sections = {
			{ heading = "Active Sagas", text = "Your active objectives will appear here." },
			{ heading = "Completed Deeds", text = "Honoured deeds and their rewards will be recorded here." },
		},
		onClose = props.onClose,
	})
end
