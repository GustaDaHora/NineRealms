task.wait(5)
local RUN_SERVICE = game:GetService("RunService")
local folder = workspace.Banners

-- Ensure outerBanners and innerBanners exist
local outerBanners = folder:FindFirstChild("outerBanners")
local innerBanners = folder:FindFirstChild("innerBanners")

if not outerBanners or not innerBanners then
	warn("Missing 'outerBanners' or 'innerBanners' folders in workspace.Banners!")
	return
end

-- Wind States (Updated to ensure dynamic randomness)
local function getWindState(state)
	if state == "Static" then
		return Vector3.new(0, 0, 0)
	elseif state == "Normal" then
		return Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))
	elseif state == "Windstorm" then
		return Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
	end
end

local function inners()
	for _, banner in pairs(innerBanners:GetChildren()) do
		if banner:IsA("Model") then 
			local part3 = banner:FindFirstChild("part3")
			if part3 then
				part3:ApplyImpulse(Vector3.new(0, 0, math.random(-2, 2)))
			end
		end
	end

	task.delay(math.random(180, 360), inners)
end

-- Function to switch wind state randomly
local function setWindState()
	local stateKeys = {"Static", "Normal", "Windstorm"}
	local chosenState = stateKeys[math.random(1, #stateKeys)]
	workspace.GlobalWind = getWindState(chosenState) -- Apply wind dynamically

	-- Schedule the next wind change in 3 to 6 minutes
	task.delay(math.random(180, 360), setWindState)
end

-- Start wind cycle
setWindState()
inners()

-- Function to apply wind force to outer banners
local function applyWindEffect()
	local wind = workspace.GlobalWind
	for _, banner in pairs(outerBanners:GetChildren()) do
		if banner:IsA("Model") then 
			local part3 = banner:FindFirstChild("part3")
			if part3 then
				local windForce = wind * Vector3.new(0.2, 0, 0.2) -- Adjust force scale
				part3:ApplyImpulse(windForce)
			end
		end
	end
end

-- Continuously update banner movement with wind
RUN_SERVICE.Heartbeat:Connect(applyWindEffect)