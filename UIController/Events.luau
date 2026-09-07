-- UIController/Events.luau
-- Migrated to React-Luau UIStore architecture

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store

local Events = {}

local function scanEvents()
	local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
	if not eventsFolder then return end

	local activeList = {}

	for _, location in ipairs(eventsFolder:GetChildren()) do
		local boolVal = location:FindFirstChild("Bool")
		local intVal = location:FindFirstChild("IntValue")
		local strVal = location:FindFirstChild("StringValue")
		local imgLabel = location:FindFirstChild("ImageLabel")

		local isEventActive = boolVal and boolVal.Value
		if isEventActive then
			local multiplierText = intVal and tostring(intVal.Value) or "2"
			local desc = strVal and strVal.Value or "Active realm bonus event."
			local img = (imgLabel and imgLabel:IsA("ImageLabel")) and imgLabel.Image or "rbxassetid://14923140747"

			table.insert(activeList, {
				id = location.Name,
				name = location.Name .. " (DOUBLE XP: " .. multiplierText .. "x)",
				description = desc,
				image = img,
			})
		end
	end

	store:dispatch(function(state)
		state.events = activeList
		return state
	end)
end

function Events.Start()
	local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)
	if not eventsFolder then return end

	scanEvents()

	-- Connect listeners
	for _, location in ipairs(eventsFolder:GetChildren()) do
		local boolVal = location:FindFirstChild("Bool")
		local intVal = location:FindFirstChild("IntValue")
		if boolVal then
			boolVal.Changed:Connect(scanEvents)
		end
		if intVal then
			intVal.Changed:Connect(scanEvents)
		end
	end

	eventsFolder.ChildAdded:Connect(function(child)
		task.wait(0.5)
		scanEvents()
	end)
end

return Events
