local player = game.Players.LocalPlayer
local loading = player:WaitForChild("Loading", 5)
repeat task.wait(1) until not loading.Value
for _, child in ipairs(script:GetChildren()) do
	if child:IsA("ModuleScript") then
		local success, result = pcall(function()
			local module = require(child)
			if type(module.Start) == "function" then
				module.Start()
			else
				warn(child.Name .. " does not have a Start function")
			end
		end)
		if not success then
			warn("Error in module " .. child.Name .. ": " .. tostring(result))
		end
	end
end
