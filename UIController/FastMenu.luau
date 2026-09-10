local FastMenu = {}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local gui = MainGui:WaitForChild("FastMenu")
local strokeFrame = gui:FindFirstChild("StrokeFrame")
local circularMenu = gui:WaitForChild("CircularMenu")
local tabTextLabel = circularMenu:WaitForChild("TabTextLabel") -- Label for displaying tab names

local connection
local initialMousePosition = Vector2.new(0, 0)
local hasMouseMoved = false
local MOUSE_THRESHOLD = 20 -- Minimum pixel distance mouse needs to move

-- Tween properties
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

-- Define angle ranges for each tab
local tabAngles = {
	{ name = "Events", min = 338, max = 22 },
	{ name = "Character", min = 23, max = 67 },
	{ name = "Settings", min = 68, max = 112 },
	{ name = "Skills", min = 113, max = 157 },
	{ name = "Inventory", min = 158, max = 202 },
	{ name = "Quests", min = 203, max = 247 },
	{ name = "Clan", min = 248, max = 292 },
	{ name = "Guide", min = 293, max = 337 }
}

local function getTabForAngle(angle)
	for _, tab in ipairs(tabAngles) do
		if tab.min > tab.max then
			-- Handle wrap-around case (e.g., Events: 338-22)
			if angle >= tab.min or angle <= tab.max then
				return tab.name
			end
		else
			-- Normal case
			if angle >= tab.min and angle <= tab.max then
				return tab.name
			end
		end
	end
	return "" -- No tab found
end

local function checkMouseMovement(mousePos)
	local distance = (mousePos - initialMousePosition).Magnitude
	if distance > MOUSE_THRESHOLD then
		hasMouseMoved = true
	end
	return hasMouseMoved
end

local function updateStrokeRotation()
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()
	local mousePos = Vector2.new(mouse.X, mouse.Y)
	local centerX, centerY = strokeFrame.AbsolutePosition.X + strokeFrame.AbsoluteSize.X / 2, strokeFrame.AbsolutePosition.Y + strokeFrame.AbsoluteSize.Y / 2

	-- Check if mouse has moved significantly from initial position
	checkMouseMovement(mousePos)

	local angle = math.atan2(mouse.Y - centerY, mouse.X - centerX) -- Get angle in radians
	local degrees = math.deg(angle) + 90 -- Convert to degrees and adjust for alignment

	-- Normalize the angle properly
	if degrees < -180 then
		degrees = degrees + 360
	elseif degrees > 180 then
		degrees = degrees - 360
	end

	-- Convert -180 to 180 range into 0-360
	if degrees < 0 then 
		degrees = degrees + 360 
	end

	strokeFrame.Rotation = degrees -- Rotate the stroke
	tabTextLabel.Text = getTabForAngle(degrees) -- Update tab name
end

local function showFastMenu()
	-- Store initial mouse position
	local mouse = game:GetService("Players").LocalPlayer:GetMouse()
	initialMousePosition = Vector2.new(mouse.X, mouse.Y)
	hasMouseMoved = false

	-- Make GUI visible
	gui.Visible = true

	local tweens = {}

	for _, v in pairs(gui:GetDescendants()) do
		if v:IsA("Frame") and v.Name == "CircularMenu" then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { BackgroundTransparency = 0 }))
		elseif v:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { ImageTransparency = 0 }))
		elseif v:IsA("TextLabel") then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { TextTransparency = 0 }))
		end
	end

	-- Play all tweens
	for _, tween in pairs(tweens) do
		tween:Play()
	end
	strokeFrame.Visible = true
	connection = RunService.RenderStepped:Connect(updateStrokeRotation)
end

local function hideFastMenu()
	local currentTab = tabTextLabel.Text -- Get the selected tab

	local tweens = {}

	for _, v in pairs(gui:GetDescendants()) do
		if v:IsA("Frame") and v.Name == "CircularMenu" then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { BackgroundTransparency = 1 }))
		elseif v:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { ImageTransparency = 1 }))
		elseif v:IsA("TextLabel") then
			table.insert(tweens, TweenService:Create(v, tweenInfo, { TextTransparency = 1 }))
		end
	end

	-- Play all tweens and handle completion only once
	local lastTween = tweens[#tweens]
	if lastTween then
		lastTween.Completed:Connect(function()
			gui.Visible = false
			if connection then
				connection:Disconnect()
			end

			-- Only open tab if mouse has moved significantly
			if hasMouseMoved then
				if currentTab == "Events" then
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Character" then
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Settings" then
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(0.85, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Skills" then
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Inventory" then
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 0.447, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Quests" then
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Clan" then
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				elseif currentTab == "Guide" then
					MainGui:WaitForChild("Guide"):TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Events"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Char"):TweenPosition(UDim2.new(0.5, 0, -0.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Config"):TweenPosition(UDim2.new(1.6, 0, 0.5, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Skills"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Inventory"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Quests"):TweenPosition(UDim2.new(0.5, 0, 1.6, 0), "Out", "Sine", 0.2)
					MainGui:WaitForChild("Clan"):TweenPosition(UDim2.new(-0.6, 0, 0.5, 0), "Out", "Sine", 0.2)
				end
			end
		end)
	end

	-- Play all tweens
	for _, tween in pairs(tweens) do
		tween:Play()
	end
	strokeFrame.Visible = false
end

function FastMenu.Start()
	-- Detect key press
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab and not gameProcessed then
			showFastMenu()
		end
	end)

	-- Detect key release
	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.Tab and not gameProcessed then
			hideFastMenu()
		end
	end)
end

return FastMenu