task.wait(10)
local RS = game:GetService("ReplicatedStorage")
local locations = RS.Events:GetChildren()
while true do
	local draw = math.random(1, #locations)
	local duration = math.random(240, 600)
	local event = locations[draw].Bool
	event.Value = true
	--print(event.Parent.Name .. " is the event")
	local eventCountDown = locations[draw].IntValue
	task.spawn(function()
		eventCountDown.Value = duration
		repeat
			task.wait(1)
			eventCountDown.Value -= 1
		until eventCountDown.Value <= 0
	end)
	task.wait(duration)
	event.Value = false
end