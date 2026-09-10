local RS = game:GetService("ReplicatedStorage")
local animations = RS:WaitForChild("Animations")
local ContentProvider = game:GetService("ContentProvider")

-- Preload assets efficiently
local function preloadAnimations()
	local animationCategories = {
		"Movement",
		"Combat",
		"Others",
	}

	for _, category in ipairs(animationCategories) do
		task.spawn(function()
			local categoryFolder = animations:WaitForChild(category)
			ContentProvider:PreloadAsync(categoryFolder:GetDescendants())
		end)
	end
end

task.spawn(preloadAnimations)