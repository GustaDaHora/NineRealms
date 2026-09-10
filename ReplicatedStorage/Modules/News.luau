local News = {}
local MessageQueue = {} -- Queue of messages
local IsShowing = false -- Flag to check if already displaying a message
local TweenService = game:GetService("TweenService")

function News.NewMessage(message, time)
	table.insert(MessageQueue, { message = message, time = time }) -- Add to queue
	if not IsShowing then
		task.spawn(News.ProcessQueue) -- If not showing, begin processing
	end
end

function News.ProcessQueue()
	IsShowing = true
	local player = game:GetService("Players").LocalPlayer
	local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
	local NewsFrame = MainGui:WaitForChild("News")

	-- Define tweening info
	local fadeInTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local fadeOutTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	while #MessageQueue > 0 do
		local current = table.remove(MessageQueue, 1) -- Get the first message from queue

		NewsFrame.BackgroundTransparency = 1
		NewsFrame.Advice.TextTransparency = 1
		NewsFrame.Advice.Text = current.message

		local fadeInTween = TweenService:Create(NewsFrame, fadeInTweenInfo, {
			BackgroundTransparency = 0,
		})

		local textFadeInTween = TweenService:Create(NewsFrame.Advice, fadeInTweenInfo, {
			TextTransparency = 0,
		})

		fadeInTween:Play()
		textFadeInTween:Play()

		task.wait(current.time) -- Wait for message display time

		local fadeOutTween = TweenService:Create(NewsFrame, fadeOutTweenInfo, {
			BackgroundTransparency = 1,
		})

		local textFadeOutTween = TweenService:Create(NewsFrame.Advice, fadeOutTweenInfo, {
			TextTransparency = 1,
		})

		fadeOutTween:Play()
		textFadeOutTween:Play()

		-- Wait for the tween to complete
		task.wait(0.5)
	end

	IsShowing = false -- Free for new messages
end

return News
