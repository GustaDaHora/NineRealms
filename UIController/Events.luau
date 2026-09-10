local Events = {}

local RS = game:GetService("ReplicatedStorage")
local locations = RS.Events:GetChildren()

--// GUI References
local MainGui = script.Parent.Parent.Events
local scrollFrame = MainGui:WaitForChild("EventsFrame")
local Frame = MainGui:WaitForChild("EventFrame")

local function displayEvents()
	for _, location in pairs(locations) do
		if location.Bool.Value then
			local clone = scrollFrame.Template:Clone()
			clone.Visible = true
			clone.Name = location.Name
			clone.Text = location.Name .. " DOUBLE XP FOR " .. location.IntValue.Value
			clone.Parent = scrollFrame
			
			clone.MouseButton1Click:Connect(function()
				Frame.ImageLabel.Image = location.ImageLabel.Image
				Frame.ImageLabel.ImageTransparency = 0
				Frame.Description.Text = location.StringValue.Value
				Frame.Description.Visible = true
			end)

			location.IntValue.Changed:Connect(function()
				clone.Text = location.Name .. " DOUBLE XP FOR " .. location.IntValue.Value
				if location.IntValue.Value <= 0 then
					clone:Destroy()
				end
			end)
		end
	end
end

function Events.Start()
	task.delay(15, displayEvents)
end

return Events
