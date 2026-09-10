local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players") -- Added for player filtering
local objectHit = game.ReplicatedStorage.RE.Items.ObjectHit

-- Hitbox module
local Hitbox = {}
Hitbox.__index = Hitbox

-- Constants for better maintainability and performance
local CONSTANTS = {
	DEFAULT_SIZE = Vector3.new(10, 10, 10),
	DEFAULT_POSITION = CFrame.new(0, 5, 0),
	DEFAULT_OFFSET = CFrame.new(0, 0, 0),
	HITBOX_COLOR = Color3.fromRGB(255, 0, 0),
	HITBOX_TRANSPARENCY = 0.5,

	-- Performance settings
	CAST_FREQUENCY = 0.03, -- ~30 times per second instead of every frame
	MAX_PARTS = 100, -- Maximum number of parts to process
	FILTER_TYPES = { -- Quick lookup for filtering
		["Humanoid"] = true,
		["DetectBox"] = true,
		-- Add more types as needed
	},
}

-- CFrame getter function optimized with function memoization
local getCFrame = setmetatable({
	["Instance"] = function(point)
		return point.CFrame
	end,
	["CFrame"] = function(point)
		return point
	end,
}, {
	__index = function(t, k)
		warn("Unsupported CFrame type:", k)
		-- Default fallback
		return function(point)
			return typeof(point) == "CFrame" and point or CFrame.new()
		end
	end,
})

-- Constructor with improved defaults and options
function Hitbox.new(options)
	local self = setmetatable({}, Hitbox)
	options = options or {}

	-- Basic properties
	self.Size = options.Size or CONSTANTS.DEFAULT_SIZE
	self.CFrame = options.CFrame or CONSTANTS.DEFAULT_POSITION
	self.Offset = options.Offset or CONSTANTS.DEFAULT_OFFSET

	-- State tracking
	self.Active = false
	self.Humanoids = {} -- List of humanoids detected
	self.HitParts = {} -- Cache of hit parts for deduplication
	self.HitCharacters = {}
	self.LastCastTime = 0 -- Time tracking for optimized casting
	self.Visualizer = options.Visualizer ~= nil and options.Visualizer or false
	self.Debug = options.Debug ~= nil and options.Debug or false -- Debug flag

	-- Optional filters
	self.IgnoreList = options.IgnoreList or {}
	self.TargetWhitelist = options.TargetWhitelist or nil
	self.WhitelistMode = options.WhitelistMode or false
	self.OwnerPlayer = options.OwnerPlayer or nil -- Owner for ignoring self hits

	-- Connections and visualization
	self.Connection = nil
	self.Box = nil

	-- Cached OverlapParams for reuse
	self.Params = OverlapParams.new()
	self.Params.FilterType = Enum.RaycastFilterType.Exclude
	self.Params.FilterDescendantsInstances = self.IgnoreList
	self.Params.MaxParts = CONSTANTS.MAX_PARTS

	-- Ensure our onTouch function is valid
	if options.onTouch and typeof(options.onTouch) == "function" then
		self.onTouch = options.onTouch
	else
		-- Default callback with immediate visual feedback
		self.onTouch = function(humanoid)
			print("Hitbox touched by:", humanoid.Parent.Name)

			-- Visual feedback (optional)
			pcall(function()
				if humanoid and humanoid.Parent then
					for _, part in pairs(humanoid.Parent:GetChildren()) do
						if part:IsA("BasePart") then
							-- Create a highlight effect
							local highlight = Instance.new("Highlight")
							highlight.FillColor = Color3.fromRGB(255, 0, 0)
							highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
							highlight.FillTransparency = 0.5
							highlight.OutlineTransparency = 0
							highlight.Parent = part

							-- Remove after brief flash
							game:GetService("Debris"):AddItem(highlight, 0.5)
						end
					end
				end
			end)
		end
	end

	-- Hit validation function - can be overridden
	self.ValidateHit = options.ValidateHit
		or function(humanoid, character)
			-- Default validation - ensure part and humanoid are valid
			return humanoid and typeof(humanoid) == "Instance" and humanoid:IsA("Humanoid") and humanoid.Health > 0
		end

	return self
end

-- Update ignore list for filtered detection
function Hitbox:UpdateIgnoreList(newIgnoreList)
	self.IgnoreList = newIgnoreList or {}
	self.Params.FilterDescendantsInstances = self.IgnoreList

	-- Always ignore the visualizer box if it exists
	if self.Box then
		table.insert(self.Params.FilterDescendantsInstances, self.Box)
	end
end

-- Improved visualization with performance considerations
function Hitbox:_Visualize()
	if not self.Visualizer then
		if self.Box then
			self.Box:Destroy()
			self.Box = nil
		end
		return
	end

	local cframeType = typeof(self.CFrame)
	local realCFrame = getCFrame[cframeType](self.CFrame)
	local finalCFrame = realCFrame * self.Offset

	if not self.Box then
		self.Box = Instance.new("Part")
		self.Box.Name = "HitboxVisualizer"
		self.Box.Anchored = true
		self.Box.CanCollide = false
		self.Box.Transparency = CONSTANTS.HITBOX_TRANSPARENCY
		self.Box.Color = CONSTANTS.HITBOX_COLOR
		self.Box.Material = Enum.Material.SmoothPlastic
		self.Box.CastShadow = false

		-- Use CollisionGroup to prevent interaction with physics
		self.Box.CollisionGroup = "Hitbox"

		-- Add to ignore list
		if not table.find(self.IgnoreList, self.Box) then
			table.insert(self.IgnoreList, self.Box)
			self:UpdateIgnoreList(self.IgnoreList)
		end

		self.Box.Parent = Workspace
	end

	-- Only update if the CFrame or Size changed
	if self.Box.Size ~= self.Size or self.Box.CFrame ~= finalCFrame then
		self.Box.Size = self.Size
		self.Box.CFrame = finalCFrame
	end
end

-- Specialized handler for objects
function Hitbox:_HandleObjectHit(part: BasePart)
	if not part.Parent:GetAttribute("BeenHit") then
		objectHit:Fire(part)
	end
end

-- Cast raybox and handle hits
function Hitbox:_Cast()
	-- Throttle cast frequency for performance while maintaining responsiveness
	local now = tick()
	if now - self.LastCastTime < CONSTANTS.CAST_FREQUENCY then
		return
	end
	self.LastCastTime = now

	-- Get the current hitbox transform
	local cframeType = typeof(self.CFrame)
	local realCFrame = getCFrame[cframeType](self.CFrame)
	local hitboxCFrame = realCFrame * self.Offset

	-- Get parts using GetPartBoundsInBox with the cached params
	local parts = Workspace:GetPartBoundsInBox(hitboxCFrame, self.Size, self.Params)

	-- Ensure we have a valid parts table
	if not parts then
		parts = {}
	end

	-- Initialize HitCharacters if it doesn't exist
	if not self.HitCharacters then
		self.HitCharacters = {}
	end

	-- Process the parts with optimized filtering
	local newHitParts = {}
	local validHumanoids = {}
	local alreadyAdded = {}

	for _, part in ipairs(parts) do
		-- Skip if we've already processed this part in this cast
		if self.HitParts[part] then
			continue
		end

		-- Check for objects (optimized with direct string check)
		if part.Name == "DetectBox" then
			self:_HandleObjectHit(part)
			continue
		end

		-- Get the part's parent (potential character)
		local character = part.Parent
		if not character then
			if self.Visualizer then
				print("Skipping part with no parent:", part.Name)
			end
			continue
		end

		if self.HitCharacters[character] and self.Visualizer then
			print("Character already processed, skipping:", character.Name)
			continue
		end

		-- Try to find character by checking parent hierarchy
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		-- Skip if no humanoid found
		if not humanoid then
			if self.Visualizer then
				print("No humanoid found for part:", part.Name)
			end
			continue
		end

		-- Whitelist mode check
		if self.WhitelistMode and self.TargetWhitelist then
			local inWhitelist = false

			-- Check if character is in whitelist
			if self.TargetWhitelist[character] then
				inWhitelist = true
			else
				-- Try to find by name (for more flexible matching)
				for whitelistedChar, _ in pairs(self.TargetWhitelist) do
					if typeof(whitelistedChar) == "Instance" and whitelistedChar.Name == character.Name then
						inWhitelist = true
						break
					end
				end
			end

			if not inWhitelist then
				if self.Visualizer then
					print("Character not in whitelist:", character.Name)
				end
				continue
			else
				if self.Visualizer then
					print("Character IS in whitelist:", character.Name)
				end
			end
		end

		-- Skip this character if it's the owner
		if self.OwnerPlayer and Players:GetPlayerFromCharacter(character) == self.OwnerPlayer then
			if self.Visualizer then
				print("Skipping owner character")
			end
			continue
		end

		local isValid = true
		pcall(function()
			if self.ValidateHit then
				isValid = self.ValidateHit(humanoid, character)
			end
		end)

		if not isValid then
			if self.Visualizer then
				print("Hit validation failed for:", character.Name)
			end
			continue
		end

		-- Now mark it as hit
		self.HitCharacters[character] = true
		newHitParts[part] = true

		-- Prevent duplicate humanoid in validHumanoids
		if not alreadyAdded[humanoid] then
			table.insert(validHumanoids, humanoid)
			alreadyAdded[humanoid] = true
		end
	end

	-- Update hit parts cache
	self.HitParts = newHitParts

	-- Execute onTouch callback outside the loop
	task.spawn(function()
		if self.onTouch then
			for _, humanoid in ipairs(validHumanoids) do
				local success, err = pcall(function()
					self.onTouch(humanoid)
				end)
				print(humanoid) -- Confirmed it return the expected humanoid
				if not success then
					error("Error in onTouch callback:", err)
				end
			end
		else
			warn("onTouch callback is nil!")
		end
	end)
end

-- Clear the hitbox and clean up resources
function Hitbox:_Clear()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end

	if self.Box then
		self.Box:Destroy()
		self.Box = nil
	end

	self.Active = false
	self.Humanoids = {}
	self.HitParts = {}
	self.HitCharacters = {}
end

-- Start the hitbox with optimized update cycle
function Hitbox:Start()
	if self.Active then
		return
	end
	self.Active = true

	-- Create visualizer immediately if enabled
	self:_Visualize()

	-- Set up a stepped connection for more consistent performance
	self.Connection = RunService.Heartbeat:Connect(function()
		if not self.Active then
			return
		end
		-- Perform cast
		self:_Cast()
	end)

	return self -- For method chaining
end

-- Stop the hitbox but maintain instance
function Hitbox:Stop()
	self.Active = false
	self:_Clear()
	return self -- For method chaining
end

-- Complete cleanup and destroy the hitbox
function Hitbox:Destroy()
	self:Stop()
	self.onTouch = nil
	self.ValidateHit = nil
	self.Params = nil
	setmetatable(self, nil)
end

-- Resize the hitbox dynamically
function Hitbox:Resize(newSize)
	self.Size = newSize
	return self -- For method chaining
end

-- Reposition the hitbox dynamically
function Hitbox:Reposition(newCFrame)
	self.CFrame = newCFrame
	return self -- For method chaining
end

-- Add a single object to the ignore list
function Hitbox:AddToIgnoreList(...)
	local objects = { ... }

	-- If the first argument is a table, use that as the list
	if #objects == 1 and typeof(objects[1]) == "table" then
		objects = objects[1]
	end

	for _, object in ipairs(objects) do
		if not table.find(self.IgnoreList, object) then
			table.insert(self.IgnoreList, object)
		end
	end

	-- Update the ignore list in the OverlapParams
	self:UpdateIgnoreList(self.IgnoreList)

	return self -- For method chaining
end

-- Set a whitelist of valid targets
function Hitbox:SetTargetWhitelist(whitelist, enabled)
	if self.Debug then
		print("Setting target whitelist:")
		if type(whitelist) == "table" then
			for entity, _ in pairs(whitelist) do
				if typeof(entity) == "Instance" then
					print("- Added to whitelist:", entity.Name)
				else
					print("- Added to whitelist:", tostring(entity))
				end
			end
		else
			print("Whitelist is not a table:", typeof(whitelist))
		end
		print("Whitelist mode enabled:", enabled ~= false)
	end

	-- Convert array-like table to dictionary for faster lookups
	local whitelistDict = {}
	if type(whitelist) == "table" then
		-- Handle both array and dictionary formats
		if #whitelist > 0 then
			-- It's an array-like table, convert to dictionary
			for _, entity in ipairs(whitelist) do
				whitelistDict[entity] = true
			end
		else
			-- Assume it's already a dictionary
			whitelistDict = whitelist
		end
	end

	self.TargetWhitelist = whitelistDict
	self.WhitelistMode = enabled ~= false
	return self -- For method chaining
end

-- Reset the hit tracking to allow re-hitting the same targets
function Hitbox:ResetHits()
	self.Humanoids = {}
	self.HitParts = {}
	self.HitCharacters = {}
	return self -- For method chaining
end

return Hitbox
