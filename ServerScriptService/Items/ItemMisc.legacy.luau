local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")

local ss = game:GetService("ServerStorage")
local modules = ss:WaitForChild("Modules")

local particleSummoner = require(modules.ParticleSummoner)
local itemSpawner = require(modules.ItemSpawner)
local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

local itemsFolder = RS:WaitForChild("RE"):WaitForChild("Items")
local biteTaken = itemsFolder:WaitForChild("BiteTaken")
local finishedEvent = itemsFolder:WaitForChild("AppleFinished")
local EquipItemEvent = itemsFolder:WaitForChild("EquipItem")
local objectHit = itemsFolder:WaitForChild("ObjectHit")
local pickUpItem = itemsFolder:WaitForChild("PickUpItem")
local giveItemEvent = itemsFolder:WaitForChild("GiveItem")

local shakeInfo = TweenInfo.new(0.05, Enum.EasingStyle.Elastic, Enum.EasingDirection.InOut, 5, true)

local FADE_DURATION = math.random(1, 10)
local RESPAWN_MIN_TIME = 60
local RESPAWN_MAX_TIME = 600

local hitCounts = {}
local boxes = {}

local function getUniqueKey(object)
	if not object:GetAttribute("UniqueID") then
		object:SetAttribute("UniqueID", httpService:GenerateGUID(false))
	end
	return object:GetAttribute("UniqueID")
end

for _, item in ipairs(workspace.ItemsFolder:GetChildren()) do
	if item:IsA("Model") then
		local uniqueId = getUniqueKey(item)
	end
end

biteTaken.OnServerEvent:Connect(function(player, tool)
	local itemData = itemsData[tool.Name]

	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if hum then
		local healAmount = itemData.Stats.Regen
		hum.Health = math.min(hum.Health + healAmount, hum.MaxHealth)
	end
end)

finishedEvent.OnServerEvent:Connect(function(plr, tool)
	EquipItemEvent:FireClient(plr, tool)
	tool:Destroy()
end)

objectHit.Event:Connect(function(part: BasePart)
	local object: Model = part.Parent
	if object:GetAttribute("BeenHit") then
		return
	end
	object:SetAttribute("BeenHit", true)

	local spawnPosition = part.CFrame.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))

	local shakeOffset = CFrame.new(math.random(-20, 20) / 100, 0, math.random(-20, 20) / 100)

	if string.find(object.Name, "Tree") then
		-- Tree handling
		itemSpawner.SpawnItem(spawnPosition + Vector3.new(math.random(0, 4), 0, math.random(0, 4)), "Tree")

		-- Improved shake effect with proper cleanup
		local originalCFrame = object.Trunk.CFrame
		local shakeTween = TweenService:Create(object.Trunk, shakeInfo, { CFrame = originalCFrame * shakeOffset })
		shakeTween:Play()

		shakeTween.Completed:Connect(function()
			-- Reset to original position
			object.Trunk.CFrame = originalCFrame
			shakeTween:Destroy()
		end)
		task.delay(1, function()
			object:SetAttribute("BeenHit", false)
		end)
	elseif object.Name == "Bush" then
		-- Bush handling with hit counting
		local hitKey = getUniqueKey(object)
		hitCounts[hitKey] = (hitCounts[hitKey] or 0) + 1

		-- Shake effect
		local originalCFrame = object.Bush.CFrame
		local shakeTween = TweenService:Create(object.Bush, shakeInfo, { CFrame = originalCFrame * shakeOffset })
		shakeTween:Play()

		shakeTween.Completed:Connect(function()
			object.Bush.CFrame = originalCFrame
			shakeTween:Destroy()
		end)

		-- Check if bush should be destroyed
		if hitCounts[hitKey] >= 3 then
			itemSpawner.SpawnItem(spawnPosition + Vector3.new(math.random(0, 3), 0, math.random(0, 3)), "Bush")
			particleSummoner.EmitParticles(
				"Break",
				part,
				50,
				0.2,
				nil,
				{ Color = ColorSequence.new(Color3.fromRGB(49, 97, 0)) }
			)

			-- Store original properties (just like ore handling)
			local originalProperties = {}
			for _, child in pairs(object:GetChildren()) do
				if child:IsA("BasePart") then
					originalProperties[child] = {
						Transparency = child.Transparency,
						CanCollide = child.CanCollide,
						CanTouch = child.CanTouch,
					}

					local fadeTween = TweenService:Create(child, TweenInfo.new(1), { Transparency = 1 })
					fadeTween:Play()
					child.CanCollide = false
					child.CanTouch = false
				end
			end

			-- Wait for respawn
			task.spawn(function()
				task.wait(math.random(60, 600))

				-- Restore original properties using TweenService (just like ore handling)
				for child, props in pairs(originalProperties) do
					if child and child.Parent then
						local fadeTween = TweenService:Create(child, TweenInfo.new(1), props)
						fadeTween:Play()
					end
				end

				-- Cleanup
				hitCounts[hitKey] = nil
				object:SetAttribute("BeenHit", false)
			end)
		else
			-- Reset BeenHit after shake completes
			task.delay(1, function()
				object:SetAttribute("BeenHit", false)
			end)
		end
	elseif object.Name == "SilverOre" or object.Name == "IronOre" then
		-- Ore handling
		local hitKey = getUniqueKey(object)
		hitCounts[hitKey] = (hitCounts[hitKey] or 0) + 1

		if hitCounts[hitKey] >= 10 then
			itemSpawner.SpawnItem(spawnPosition + Vector3.new(math.random(0, 2), 0, math.random(0, 2)), object.Name)
			particleSummoner.EmitParticles(
				"Break",
				part,
				50,
				0.2,
				nil,
				{ Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) }
			)
			local BreakSound = part:FindFirstChild("BreakSound") or object:FindFirstChild("BreakSound")
			if BreakSound then
				BreakSound.PlaybackSpeed = math.random(90, 110) / 100
				BreakSound:Play()
			else
				-- Debug: print if sound not found
				warn("BreakSound not found in", part.Name, "or", object.Name)
			end
			-- Store original properties
			local originalProperties = {}
			for _, child in pairs(object:GetChildren()) do
				if child:IsA("BasePart") then
					originalProperties[child] = {
						Transparency = child.Transparency,
						CanCollide = child.CanCollide,
						CanTouch = child.CanTouch,
					}

					local fadeTween = TweenService:Create(child, TweenInfo.new(1), { Transparency = 1 })
					fadeTween:Play()
					child.CanCollide = false
					child.CanTouch = false
				end
			end

			-- Respawn ore after delay
			task.spawn(function()
				task.wait(math.random(256, 600))

				for child, props in pairs(originalProperties) do
					if child and child.Parent then
						local fadeTween = TweenService:Create(child, TweenInfo.new(1), props)
						fadeTween:Play()
					end
				end

				hitCounts[hitKey] = nil
				object:SetAttribute("BeenHit", false)
			end)
		else
			local HitSound = part:FindFirstChild("HitSound") or object:FindFirstChild("HitSound")
			if HitSound then
				HitSound.PlaybackSpeed = math.random(90, 110) / 100
				HitSound:Play()
			else
				-- Debug: print if sound not found
				warn("HitSound not found in", part.Name, "or", object.Name)
			end
			task.delay(1, function()
				object:SetAttribute("BeenHit", false)
			end)
		end
	elseif object.Name == "GenericBox" or object.Name == "BigBox" then
		local boxId = getUniqueKey(object)
		local partsData = {}

		itemSpawner.SpawnItem(spawnPosition + Vector3.new(math.random(0, 2), 0, math.random(0, 2)), object.Name)
		if object.Name == "BigBox" then
			itemSpawner.SpawnItem(spawnPosition + Vector3.new(math.random(0, 2), 0, math.random(0, 2)), object.Name)
		end
	
		-- Store state and apply single velocity
		for _, part in pairs(object:GetChildren()) do
			if part:IsA("BasePart") then
				partsData[part] = {
					CFrame = part.CFrame,
					Anchored = part.Anchored,
					Transparency = part.Transparency,
				}
				part.Anchored = false
				part.CanCollide = true
				part.AssemblyLinearVelocity =
					Vector3.new(math.random(-15, 15), math.random(10, 25), math.random(-15, 15))
				part.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), math.random(-8, 8))
			end
		end
		
		local BreakSound = part:FindFirstChild("BreakSound") or object:FindFirstChild("BreakSound")
		if BreakSound then
			BreakSound.PlaybackSpeed = math.random(90, 110) / 100
			BreakSound:Play()
		else
			-- Debug: print if sound not found
			warn("BreakSound not found in", part.Name, "or", object.Name)
		end

		boxes[boxId] = partsData

		-- Fade out and respawn
		task.delay(3, function()
			for part, _ in pairs(partsData) do
				local fadeTween = TweenService:Create(part, TweenInfo.new(FADE_DURATION), { Transparency = 1 })
				fadeTween:Play()
				part.Anchored = true
				part.CanCollide = false
			end

			task.wait(FADE_DURATION + 0.1)

			task.delay(math.random(RESPAWN_MIN_TIME, RESPAWN_MAX_TIME), function()
				for part, data in pairs(partsData) do
					if part and part.Parent then
						part.CFrame = data.CFrame
						part.Anchored = data.Anchored
						part.CanCollide = false
						local restoreTween = TweenService:Create(
							part,
							TweenInfo.new(FADE_DURATION),
							{ Transparency = data.Transparency }
						)
						restoreTween:Play()
					end
				end

				boxes[boxId] = nil
				object:SetAttribute("BeenHit", false)
			end)
		end)
	end
end)

pickUpItem.OnServerEvent:Connect(function(player, itemInstance: Model, itemName, itemData, uniqueId)
	if not itemInstance:GetAttribute("CanBePicked") then
		return
	end
	itemInstance:SetAttribute("CanBePicked", false)

	giveItemEvent:Fire(player, itemName)

	local originalProperties = {}

	for _, child in pairs(itemInstance:GetChildren()) do
		if child:IsA("MeshPart") or child:IsA("BasePart") then
			local props = {
				Transparency = child.Transparency,
				CanCollide = child.CanCollide,
				CanTouch = child.CanTouch,
				ParticleEmitters = {},
			}

			for _, descendant in pairs(child:GetChildren()) do
				if descendant:IsA("ParticleEmitter") then
					table.insert(props.ParticleEmitters, descendant)
					descendant.Enabled = false
				end
			end

			originalProperties[child] = props

			-- Fade out the item
			local fadeTween = TweenService:Create(child, TweenInfo.new(1), { Transparency = 1 })
			fadeTween:Play()

			child.CanCollide = false
			child.CanTouch = false
		end
	end

	local respawnDelay = math.random(100, 600)
	task.delay(respawnDelay, function()
		itemInstance:SetAttribute("CanBePicked", true)

		for child, props in pairs(originalProperties) do
			if child and child.Parent then
				-- Re-enable particle emitters
				for _, emitter in pairs(props.ParticleEmitters) do
					if emitter:IsA("ParticleEmitter") then
						emitter.Enabled = true
					end
				end

				-- Restore properties
				child.CanCollide = props.CanCollide
				child.CanTouch = props.CanTouch

				local fadeTween = TweenService:Create(child, TweenInfo.new(1), { Transparency = props.Transparency })
				fadeTween:Play()
			end
		end
	end)
end)
