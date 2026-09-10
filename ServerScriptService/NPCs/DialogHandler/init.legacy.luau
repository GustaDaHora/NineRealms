-- DialogHandler Server Script
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local giveItem = RS:WaitForChild("RE"):WaitForChild("Items"):WaitForChild("GiveItem")
local dialogEvent = RS:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local shopEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("MarketEvent")
local shopFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("ShopFunction")

local craftEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftEvent")
local craftFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("CraftFunction")

local bonfireEvent = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireEvent")
local bonFireFunction = RS:WaitForChild("RE"):WaitForChild("Others"):WaitForChild("BonFireFunction")

local itemsData = require(RS:WaitForChild("Modules"):WaitForChild("ItemsData"))

local NPCDialogs = require(script.NPCDialogs)
local recipes = require(RS:WaitForChild("Modules"):WaitForChild("Recipes"))
local soundManager = require(SS:WaitForChild("Modules"):WaitForChild("SoundManager"))
local particleSystem = require(SS:WaitForChild("Modules"):WaitForChild("ParticleSummoner"))

local npcs = workspace.Alives.NPCs.DialogNPCs
local cookingStations = workspace.CookingStations

-- Table to track which NPC each player is chatting with
local Chatting = {}
local RestingPlayers = {}

for _, dialogNpc in pairs(npcs:GetChildren()) do
	local Root = dialogNpc:FindFirstChild("HumanoidRootPart")
	local prox = Root and Root:FindFirstChild("ProximityPrompt")

	if prox then
		prox.ObjectText = dialogNpc.Name
		prox.ActionText = "Chat with " .. dialogNpc.Name
		prox.Triggered:Connect(function(plr)
			if Chatting[plr] then
				return -- Prevent multiple chats per player
			end
			if plr.Character:GetAttribute("InCombat") then
				return
			end
			local dialog = NPCDialogs[dialogNpc.Name]
			if not dialog then
				warn("No dialog found for NPC: " .. dialogNpc.Name)
				return
			end
			Chatting[plr] = dialogNpc.Name
			plr.Character:SetAttribute("Chatting", true)

			dialogEvent:FireClient(plr, dialog, dialogNpc.Name)
		end)
	end
end

for _, station in pairs(cookingStations:GetChildren()) do
	local Root = station.PrimaryPart
	local prox = Root and Root:FindFirstChild("ProximityPrompt")

	if prox then
		prox.ObjectText = "Bonfire"
		prox.ActionText = "Use Bonfire"
		prox.Triggered:Connect(function(plr)
			if Chatting[plr] then
				return -- Prevent multiple chats per player
			end
			if plr.Character:GetAttribute("InCombat") then
				return
			end
			local dialog = NPCDialogs["Bonfire"]
			if not dialog then
				warn("No dialog found for Bonfire")
				return
			end
			-- Ensure Chatting[plr] is set to "Bonfire" when interacting with a bonfire
			Chatting[plr] = "Bonfire"
			plr.Character:SetAttribute("Chatting", true)

			dialogEvent:FireClient(plr, dialog, "Bonfire")
		end)
	end
end

local function performAction(plr, npcName, Action)
	local char = plr.Character
	if Action == "ContinueDialog" then
		Chatting[plr] = npcName
		char:SetAttribute("Chatting", true)
	elseif Action == "EndDialog" then
		Chatting[plr] = nil
		char:SetAttribute("Chatting", false)
		char:SetAttribute("Resting", false)
		if RestingPlayers[plr] then
			RestingPlayers[plr].cancel = true
		end
	elseif Action == "OpenShop" then
		shopEvent:FireClient(plr, npcName)
	elseif Action == "OpenCrafting" then
		craftEvent:FireClient(plr, npcName)
	elseif Action == "OpenBonfire" then
		bonfireEvent:FireClient(plr)
	elseif Action == "ChoosePathVegvisir" then
		char:SetAttribute("Chatting", true)
		local plrClassPath = plr:WaitForChild("Data"):FindFirstChild("ClassPath")
		if plrClassPath.Value ~= "" then
			local dialog = NPCDialogs["Volva2"]
			dialogEvent:FireClient(plr, dialog, "Volva")
			return -- Prevent action if player already has a class path
		end

		plrClassPath.Value = "Vegvisir"
		local humRootPart = char:FindFirstChild("HumanoidRootPart")
		particleSystem.EmitParticles("Vegvisir", humRootPart, 1, 1)
		soundManager.playSound("NaturesGift", char.HumanoidRootPart)
		task.wait(4)
		Chatting[plr] = nil
		char:SetAttribute("Chatting", false)
	elseif Action == "ChoosePathAegishjalmur" then
		char:SetAttribute("Chatting", true)
		local plrClassPath = plr:WaitForChild("Data"):FindFirstChild("ClassPath")
		if plrClassPath.Value ~= "" then
			local dialog = NPCDialogs["Volva2"]
			dialogEvent:FireClient(plr, dialog, "Volva")
			return -- Prevent action if player already has a class path
		end

		plrClassPath.Value = "Aegishjalmur"
		local humRootPart = char:FindFirstChild("HumanoidRootPart")
		particleSystem.EmitParticles("Aegishjalmur", humRootPart, 1, 1)
		soundManager.playSound("HolyBlessing", char.Head)
		task.wait(4)
		Chatting[plr] = nil
		char:SetAttribute("Chatting", false)
	elseif Action == "RestAtBonfire" then
		local char = plr.Character
		if not char then
			return
		end

		Chatting[plr] = nil
		plr.Character:SetAttribute("Chatting", false)
		plr.Character:SetAttribute("Resting", true)

		local hum = char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChild("Animator")
		local anim = RS:WaitForChild("Animations"):WaitForChild("Others"):WaitForChild("BonFireRest")

		-- If already resting, cancel the rest
		if RestingPlayers[plr] then
			RestingPlayers[plr].cancel = true
			return
		end

		if animator and anim then
			local playAnim = animator:LoadAnimation(anim)
			RestingPlayers[plr] = { cancel = false, animation = playAnim }
			playAnim:Play()

			while playAnim.IsPlaying do
				if RestingPlayers[plr].cancel then
					playAnim:Stop()
					break
				end
				if hum.Health < hum.MaxHealth then
					hum.Health += 1
				end
				task.wait(0.5)
			end

			playAnim.Stopped:Wait()
			RestingPlayers[plr] = nil
			plr.Character:SetAttribute("Resting", false)
		end
	elseif Action == "ResetDialog" then
		local dialog = NPCDialogs[npcName]

		if not dialog then
			warn("No dialog found for NPC: " .. npcName)
			return
		end
		task.wait(2)
		dialogEvent:FireClient(plr, dialog, npcName)
		plr.Character:SetAttribute("Chatting", true)
	elseif Action == "ResetPath" then
		local plrClassPath = plr:WaitForChild("Data"):FindFirstChild("ClassPath")
		if not plrClassPath then
			warn("Player", plr.Name, "does not have a ClassPath attribute.")
			return
		end

		if plrClassPath.Value == "" then
			warn(
				"Player",
				plr,
				npcName,
				Action,
				"does not have a class path to reset code shouldn't be able to reach this point"
			)
			return
		end

		plrClassPath.Value = ""
		local unlockedSkills = plr:WaitForChild("UnlockedSkills")
		for _, skill in pairs(unlockedSkills:GetChildren()) do
			skill.Value = false
		end
		local equippedSkills = plr:WaitForChild("Skills")
		for _, skill in pairs(equippedSkills:GetChildren()) do
			skill.Value = ""
		end

		char.Humanoid.Health = 0 -- Reset health to 0 to respawn the player
	else
		warn("Unknown action:", plr, npcName, Action)
	end
end

-- Handle client responses
dialogEvent.OnServerEvent:Connect(function(plr, Action, Option)
	local npcName = Chatting[plr] -- Retrieve the NPC the player is chatting with
	if not npcName then
		warn("Player", plr.Name, "tried to respond, but no NPC was found.")
		return
	end

	performAction(plr, npcName, Action)
end)

shopFunction.OnServerInvoke = function(plr, action, itemName)
	local dataFolder = plr:FindFirstChild("Data")
	if not dataFolder then
		return false, "Data not found"
	end -- Prevent errors if data is missing

	local hackSilver = dataFolder:FindFirstChild("HackSilver")
	if not hackSilver then
		return false, "Invalid currency"
	end -- Ensure valid currency

	local inventory = plr:FindFirstChild("Backpack")
	if not inventory then
		return false, "Inventory not found"
	end -- Ensure inventory exists

	local ItemData = itemsData[itemName]
	if not ItemData then
		return false, "Item does not exist"
	end -- Prevent invalid item interactions

	if action == "buy" then
		if hackSilver.Value < ItemData.BasePrice then
			return false, "Not enough HackSilver"
		end

		-- Deduct currency and grant the item
		hackSilver.Value = hackSilver.Value - ItemData.BasePrice
		giveItem:Fire(plr, itemName) -- Send event to give item

		return true, "Purchase successful"
	elseif action == "sell" then
		local itemInInventory = inventory:FindFirstChild(itemName)
		if not itemInInventory then
			return false, "Item already sold"
		end

		local sellPrice = ItemData.SellPrice or (ItemData.BasePrice * 0.5) -- Default to half price if SellPrice not set

		-- Remove item from inventory and refund currency
		local amount = itemInInventory.Amount
		print(amount.Value)
		if amount.Value > 1 then
			amount.Value = amount.Value - 1
		else
			itemInInventory:Destroy() -- Remove the item if its count reaches zero
		end
		hackSilver.Value = hackSilver.Value + sellPrice

		return true, "Item sold for " .. sellPrice .. " HackSilver"
	else
		return false, "Invalid action"
	end
end

craftFunction.OnServerInvoke = function(plr, itemName)
	local dataFolder = plr:FindFirstChild("Data")
	if not dataFolder then
		return false, "Data not found"
	end -- Prevent errors if data is missing

	local hackSilver = dataFolder:FindFirstChild("HackSilver")
	if not hackSilver then
		return false, "Invalid currency"
	end -- Ensure valid currency

	local itemDataModule = itemsData:FindFirstChild(itemName)
	if not itemDataModule then
		return false, "Item does not exist"
	end -- Prevent invalid item crafting

	local itemRecipe = recipes[itemName]
	if not itemRecipe then
		return false, "Recipe not found for the item"
	end

	for material, amount in pairs(recipes[itemName]) do
		local materialInBack = plr.Backpack:FindFirstChild(material)
		local plrAmount = materialInBack and materialInBack:FindFirstChild("Amount") and materialInBack.Amount.Value
			or 0

		if not materialInBack or plrAmount < amount then
			return false, "Not enough resources"
		end
	end

	local ItemData = require(itemDataModule)
	local craftingPrice = ItemData.BasePrice / 2
	if hackSilver.Value < craftingPrice then
		return false, "Not enough HackSilver"
	end

	-- Deduct currency and grant the item
	hackSilver.Value = hackSilver.Value - craftingPrice
	giveItem:Fire(plr, itemName) -- Send event to give item

	return true, "Crafting successful"
end

bonFireFunction.OnServerInvoke = function(plr, itemName)
	local dataFolder = plr:FindFirstChild("Data")
	if not dataFolder then
		return false, "Data not found"
	end -- Prevent errors if data is missing

	local hackSilver = dataFolder:FindFirstChild("HackSilver")
	if not hackSilver then
		return false, "Invalid currency"
	end -- Ensure valid currency

	local itemDataModule = itemsData:FindFirstChild(itemName)
	if not itemDataModule then
		return false, "Item does not exist"
	end -- Prevent invalid item crafting

	local itemRecipe = recipes[itemName]
	if not itemRecipe then
		return false, "Recipe not found for the item"
	end

	for material, amount in pairs(recipes[itemName]) do
		local materialInBack = plr.Backpack:FindFirstChild(material)
		local plrAmount = materialInBack and materialInBack:FindFirstChild("Amount") and materialInBack.Amount.Value
			or 0

		if not materialInBack or plrAmount < amount then
			return false, "Not enough resources"
		end
	end

	giveItem:Fire(plr, itemName) -- Send event to give item

	return true, "Crafting successful"
end

game.Players.PlayerAdded:Connect(function(plr)
	Chatting[plr] = nil
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid").Died:Connect(function()
			Chatting[plr] = nil
		end)
	end)
end)

game.Players.PlayerRemoving:Connect(function(plr)
	Chatting[plr] = nil
end)
