-- HorizontalSkillTree.lua
-- Layout skills in horizontal columns radiating from chosenPath (string).
-- Returns uiNodes map.

local HorizontalSkillTree = {}

local DEFAULTS = {
	NodeSize = Vector2.new(80, 80),
	HSpacing = 250, -- horizontal spacing between columns
	VSpacing = 150, -- vertical spacing between nodes in same column
	LineThickness = 9,
	CanvasPadding = 0,
	DisabledAlpha = 0.55,
	ActiveLineColor = Color3.fromRGB(245, 200, 40),
	InactiveLineColor = Color3.fromRGB(140, 140, 140),
}

-- Build unlocked set from Folder/table
local function makeUnlockedSet(unlockedSource)
	local set = {}
	if not unlockedSource then
		return set
	end
	if typeof(unlockedSource) == "Instance" then
		for _, child in ipairs(unlockedSource:GetChildren()) do
			if child:IsA("StringValue") then
				set[child.Name] = child.Value and true or false
			end
		end
	elseif type(unlockedSource) == "table" then
		for k, v in pairs(unlockedSource) do
			if type(k) == "number" then
				set[v] = true
			else
				set[k] = v and true or false
			end
		end
	end
	return set
end

local function buildSkillToPathMap(pathsTable)
	local map = {}
	if not pathsTable then
		return map
	end
	for pathRoot, classes in pairs(pathsTable) do
		for _, skills in pairs(classes) do
			for skillName, _ in pairs(skills) do
				map[skillName] = pathRoot
			end
		end
	end
	return map
end

-- Compute levels using DFS
local function computeLevels(skillsInfo, chosenPath)
	local levelCache = {}
	local visiting = {}
	local maxLevel = 0
	local names = {}

	levelCache[chosenPath] = 0

	for k, _ in pairs(skillsInfo) do
		if k ~= "Paths" then
			table.insert(names, k)
		end
	end

	local function getPrereqs(name)
		local data = skillsInfo[name]
		if not data then
			return {}
		end
		local p = data.Prerequisite or data.Prerequisites or {}
		if type(p) ~= "table" then
			p = { p }
		end
		return p
	end

	local function dfs(name)
		if levelCache[name] ~= nil then
			return levelCache[name]
		end
		if visiting[name] then
			warn("Cycle detected for", name)
			levelCache[name] = 1
			return 1
		end
		visiting[name] = true

		local prereqs = getPrereqs(name)
		if #prereqs == 0 then
			levelCache[name] = 1
			visiting[name] = false
			maxLevel = math.max(maxLevel, 1)
			return 1
		end

		local localMax = 0
		for _, p in ipairs(prereqs) do
			if p == chosenPath then
				localMax = math.max(localMax, 0)
			elseif skillsInfo[p] then
				local lvl = dfs(p)
				localMax = math.max(localMax, lvl)
			else
				localMax = math.max(localMax, 0)
			end
		end

		local myLevel = localMax + 1
		levelCache[name] = myLevel
		visiting[name] = false
		maxLevel = math.max(maxLevel, myLevel)
		return myLevel
	end

	for _, name in ipairs(names) do
		if not levelCache[name] then
			dfs(name)
		end
	end

	local levels = {}
	for name, lvl in pairs(levelCache) do
		if name ~= chosenPath then
			levels[lvl] = levels[lvl] or {}
			table.insert(levels[lvl], name)
		end
	end

	return levels, maxLevel
end

-- Draw rotated line between points
local function drawLineBetween(parent, a, b, thickness, color)
	local delta = b - a
	local length = delta.Magnitude
	if length <= 1 then
		return nil
	end

	local mid = (a + b) * 0.5
	-- round to avoid half-pixel blurriness
	local pxLength = math.max(1, math.floor(length + 0.5))
	local pxX = math.floor(mid.X + 0.5)
	local pxY = math.floor(mid.Y + 0.5)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, pxLength, 0, thickness)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromOffset(pxX, pxY)
	frame.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

-- Main builder
-- opts: SkillsInfo, ChosenPath (string), Canvas (Frame/ScrollingFrame),
-- NodeTemplate (Instance), UnlockedSource (Folder/table), Config (table)
local RunService = game:GetService("RunService")

function HorizontalSkillTree.Build(opts)
	assert(
		opts and opts.SkillsInfo and opts.ChosenPath and opts.Canvas and opts.NodeTemplate,
		"Build requires SkillsInfo, ChosenPath, Canvas, NodeTemplate"
	)

	local cfg = {}
	for k, v in pairs(DEFAULTS) do
		cfg[k] = v
	end
	if opts.Config then
		for k, v in pairs(opts.Config) do
			cfg[k] = v
		end
	end

	local skillsInfo = opts.SkillsInfo
	local chosenPath = opts.ChosenPath
	local canvas = opts.Canvas
	local nodeTemplate = opts.NodeTemplate
	local unlockedSet = makeUnlockedSet(opts.UnlockedSource)
	unlockedSet[chosenPath] = true

	for _, v in pairs(canvas:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy() -- clear previous nodes
		end
	end

	local skillToPath = buildSkillToPathMap(skillsInfo.Paths)
	local levels, maxLevel = computeLevels(skillsInfo, chosenPath)

	-- compute the canvas *content* pixel size (Scale + Offset) once (used only for fallback center)
	local canvasContentWidth = canvas.CanvasSize.X.Scale * canvas.AbsoluteSize.X + canvas.CanvasSize.X.Offset
	local canvasContentHeight = canvas.CanvasSize.Y.Scale * canvas.AbsoluteSize.Y + canvas.CanvasSize.Y.Offset

	-- wait a frame so AbsolutePosition/Size are valid (important if UI just created)
	-- RunService.Heartbeat is slightly more deterministic for GUI layout than task.wait()
	-- Give the engine one frame to update AbsolutePosition/Size so we can read accurate centers
	RunService.Heartbeat:Wait()

	-- helper: convert a UI instance absolute center to canvas-content coordinates
	local function centerInCanvasContent(btn)
		-- btn: Instance (ImageButton) that is a child somewhere in GUI (may be descendant of canvas)
		local absPos = btn.AbsolutePosition -- screen coords
		local absSize = btn.AbsoluteSize
		local canvasAbs = canvas.AbsolutePosition
		local canvasPos = canvas.CanvasPosition -- Vector2 of scroll offset inside content

		-- top-left of btn in canvas-content coordinates
		local contentTopLeft =
			Vector2.new((absPos.X - canvasAbs.X) + canvasPos.X, (absPos.Y - canvasAbs.Y) + canvasPos.Y)

		-- center = top-left + half size
		return contentTopLeft + (absSize * 0.5)
	end

	-- discover path buttons by name (recursive find) and compute centers in canvas-content coords
	local pathCenters = {}
	local pathRadii = {} -- radius in pixels for connecting visuals
	local aegBtn = canvas:FindFirstChild("Aegishjalmur", true)
	local vegBtn = canvas:FindFirstChild("Vegvisir", true)

	if aegBtn then
		pathCenters["Aegishjalmur"] = centerInCanvasContent(aegBtn)
		pathRadii["Aegishjalmur"] = aegBtn.AbsoluteSize.X * 0.5
	end
	if vegBtn then
		pathCenters["Vegvisir"] = centerInCanvasContent(vegBtn)
		pathRadii["Vegvisir"] = vegBtn.AbsoluteSize.X * 0.5
	end

	local fallbackCenter = Vector2.new(canvasContentWidth * 0.5, canvasContentHeight * 0.5)
	pathCenters["Aegishjalmur"] = pathCenters["Aegishjalmur"] or fallbackCenter
	pathCenters["Vegvisir"] = pathCenters["Vegvisir"] or fallbackCenter

	-- path radii fallback
	pathRadii["Aegishjalmur"] = pathRadii["Aegishjalmur"] or (cfg.NodeSize.X * 0.5)
	pathRadii["Vegvisir"] = pathRadii["Vegvisir"] or (cfg.NodeSize.X * 0.5)

	-- chosen center uses the chosenPath root
	local centerLocal = pathCenters[chosenPath] or fallbackCenter
	pathCenters[chosenPath] = pathCenters[chosenPath] or centerLocal

	-- debug visual markers (optional, enable via opts.Debug)
	if opts.Debug then
		local function markPoint(p, color)
			local m = Instance.new("Frame")
			m.Size = UDim2.new(0, 8, 0, 8)
			m.AnchorPoint = Vector2.new(0.5, 0.5)
			m.Position = UDim2.fromOffset(p.X, p.Y)
			m.BackgroundColor3 = color
			m.BorderSizePixel = 0
			m.Parent = canvas
		end
		markPoint(pathCenters["Aegishjalmur"], Color3.fromRGB(0, 200, 0))
		markPoint(pathCenters["Vegvisir"], Color3.fromRGB(0, 0, 200))
		markPoint(centerLocal, Color3.fromRGB(255, 0, 0))
		print("Path centers:", pathCenters["Aegishjalmur"], pathCenters["Vegvisir"], "chosen center:", centerLocal)
	end

	-- layout nodes: split skills in each level into (samePath vs otherPath) groups
	local uiNodes = {}
	local nodeCenters = {}

	for level = 1, (maxLevel or 1) do
		local items = levels[level] or {}
		if #items == 0 then
			-- skip empty level
		else
			-- separate by path
			local samePath = {}
			local otherPath = {}
			for _, name in ipairs(items) do
				if skillToPath[name] == chosenPath then
					table.insert(samePath, name)
				else
					table.insert(otherPath, name)
				end
			end

			-- determine the other root (we only have two known roots: Aegishjalmur / Vegvisir)
			local otherRoot = (chosenPath == "Vegvisir") and "Aegishjalmur" or "Vegvisir"

			local function layoutColumnForPath(list, pathRoot)
				local count = #list
				if count == 0 then
					return
				end

				-- base center for this path (fall back to chosen center if path button not present)
				local baseCenter = pathCenters[pathRoot] or centerLocal

				-- path direction: Vegvisir -> left (-1), others -> right (+1)
				local dir = (pathRoot == "Vegvisir") and -1 or 1

				local x = baseCenter.X + dir * (level * cfg.HSpacing)
				local bandHeight = (count - 1) * cfg.VSpacing
				local startY = baseCenter.Y - bandHeight * 0.5

				for i, name in ipairs(list) do
					local y = startY + (i - 1) * cfg.VSpacing
					local pos = Vector2.new(x, y)
					local node = nodeTemplate:Clone()
					node.Name = name
					node.AnchorPoint = Vector2.new(0.5, 0.5)
					node.Position = UDim2.fromOffset(pos.X, pos.Y) -- content coords
					node.Size = UDim2.fromOffset(cfg.NodeSize.X, cfg.NodeSize.Y)
					node.Parent = canvas
					node.Visible = true

					-- set label/icon if present
					local label = node:FindFirstChild("SkillName")
					if label and label:IsA("TextLabel") then
						label.Text = name
					end
					local icon = node:FindFirstChild("Icon")
					if icon and icon:IsA("ImageLabel") and skillsInfo[name] and skillsInfo[name].Icon then
						icon.Image = skillsInfo[name].Icon
					end

					-- attributes for your logic
					local data = skillsInfo[name] or {}
					node:SetAttribute("SoulsCost", data.SoulsCost or 0)
					node:SetAttribute("Class", data.Class or "Any")
					node:SetAttribute("Weapons", data.Weapons or "Any")
					node:SetAttribute("IsPassive", data.IsPassive or false)
					node:SetAttribute("Cooldown", data.Cooldown or 0)
					node:SetAttribute("Duration", data.Duration or 0)
					node:SetAttribute("Description", data.Description or "")

					-- visually disable if not in chosenPath
					local pathOfSkill = skillToPath[name]
					if pathOfSkill and pathOfSkill ~= chosenPath then
						node.Active = false
						node.AutoButtonColor = false
						node.BackgroundTransparency = node.BackgroundTransparency + cfg.DisabledAlpha
						local childIcon = node:FindFirstChild("Icon")
						if childIcon and childIcon:IsA("ImageLabel") then
							childIcon.ImageTransparency =
								math.min(1, (childIcon.ImageTransparency or 0) + cfg.DisabledAlpha)
						end
						local lbl = node:FindFirstChild("SkillName")
						if lbl and lbl:IsA("TextLabel") then
							lbl.TextTransparency = math.min(1, (lbl.TextTransparency or 0) + cfg.DisabledAlpha)
						end
					end

					uiNodes[name] = node
					-- Give the engine one frame to update AbsolutePosition/Size so we can read accurate centers
					RunService.Heartbeat:Wait()

					-- Recompute nodeCenters from actual rendered AbsolutePosition/Size to avoid layout drift
					for name, node in pairs(uiNodes) do
						nodeCenters[name] = centerInCanvasContent(node)
					end
				end
			end

			-- layout chosen path using its own center
			layoutColumnForPath(samePath, chosenPath)
			-- layout other path using *its* center (otherRoot)
			layoutColumnForPath(otherPath, otherRoot)
		end
	end

	-- Draw edges - connect skills to their respective path buttons or prereq skill
	local function getPrereqs(name)
		local data = skillsInfo[name]
		if not data then
			return {}
		end
		local p = data.Prerequisite or data.Prerequisites or {}
		if type(p) ~= "table" then
			p = { p }
		end
		return p
	end

	for name, node in pairs(uiNodes) do
		local prereqs = getPrereqs(name)
		local targetPos = nodeCenters[name]
		local skillPath = skillToPath[name]

		for _, p in ipairs(prereqs) do
			local sourcePos = nodeCenters[p]
			if sourcePos then
				local color = unlockedSet[p] and cfg.ActiveLineColor or cfg.InactiveLineColor
				drawLineBetween(canvas, sourcePos, targetPos, cfg.LineThickness, color)
			else
				local pathCenter = pathCenters[skillPath] or pathCenters[chosenPath] or centerLocal
				local color = unlockedSet[skillPath] and cfg.ActiveLineColor or cfg.InactiveLineColor
				drawLineBetween(canvas, pathCenter, targetPos, cfg.LineThickness, color)
			end
		end

		if #prereqs == 0 and skillPath then
			local pathCenter = pathCenters[skillPath] or pathCenters[chosenPath] or centerLocal
			local color = unlockedSet[skillPath] and cfg.ActiveLineColor or cfg.InactiveLineColor
			drawLineBetween(canvas, pathCenter, targetPos, cfg.LineThickness, color)
		end
	end

	return {
		uiNodes = uiNodes,
		nodeCenters = nodeCenters,
		centerLocal = centerLocal,
	}
end

return HorizontalSkillTree
