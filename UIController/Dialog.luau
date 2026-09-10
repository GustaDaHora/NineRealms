local Dialog = {}

-- Services
local RS = game:GetService("ReplicatedStorage")
local dialogEvent = RS:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")
local player = game:GetService("Players").LocalPlayer

-- UI References
local MainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local DialogButton = MainGui:WaitForChild("Dialog")
local DialogSound = DialogButton.Sound
local Option1 = DialogButton.Accept
local Option2 = DialogButton.Continue
local Option3 = DialogButton.Refuse
local NpcName = DialogButton.NpcName

-- Dialog State
local DialogState = {
	currentDialogIndex = 1,
	typingSpeed = 0.05,
	isTyping = false,
	fullTextDisplayed = false,
	shouldSkip = false,
	dialogData = {},
	optionsVisible = false,
	speaker = nil,
	isResponse = false,
	currentDialogTree = nil,
}

-- Sound mappings for different NPCs
local speakerSounds = {
	InnerVoice = "rbxassetid://3620844678",
	Bjorn = "rbxassetid://418252437",
	Eldrim = "rbxassetid://9063549513",
	Haldor = "rbxassetid://9119556229",
	Leifrik = "rbxassetid://9120430448",
}

-- UI Management Functions
local function setDialogVisible(isVisible)
	DialogButton.Visible = isVisible
end

local function setOptionsVisible(isVisible)
	Option1.Visible = isVisible
	Option2.Visible = isVisible
	Option3.Visible = isVisible
	DialogState.optionsVisible = isVisible
end

local function updateOptionText(options)
	if options and #options >= 3 then
		Option1.Text = options[1].Text or "Option 1"
		Option2.Text = options[2].Text or "Option 2"
		Option3.Text = options[3].Text or "Option 3"
	else
		warn("Options not correctly provided")
	end
end

local function toggleProx(state)
	for _, npc in pairs(workspace.Alives.NPCs.DialogNPCs:GetChildren()) do
		local Root = npc:FindFirstChild("HumanoidRootPart")
		local prox = Root and Root:FindFirstChild("ProximityPrompt")
		if prox then
			prox.Enabled = state
		end
	end
end

local function setHotBarVisible(isVisible)
	MainGui.Hotbar.Visible = isVisible
end

-- Dialog Open/Close Functions
local function openDialog()
	setDialogVisible(true)
	toggleProx(false)
	setHotBarVisible(false)
end

local function resetDialogState()
	DialogState.currentDialogIndex = 1
	DialogState.isTyping = false
	DialogState.fullTextDisplayed = false
	DialogState.shouldSkip = false
	DialogState.dialogData = {}
	DialogState.optionsVisible = false
	DialogState.speaker = nil
	DialogState.isResponse = false
	DialogState.currentDialogTree = nil
end

local function closeDialog()
	setDialogVisible(false)
	toggleProx(true)
	setHotBarVisible(true)
	resetDialogState()
end

-- Text Typing Function
local function typeText(text)
	DialogState.isTyping = true
	DialogState.fullTextDisplayed = false
	DialogButton.Text = ""
	DialogState.shouldSkip = false

	for i = 1, #text do
		if DialogState.shouldSkip then
			DialogButton.Text = text
			break
		end

		DialogButton.Text = string.sub(text, 1, i)
		DialogSound:Play()

		if string.sub(text, i, i) == "." then
			task.wait(0.5)
		else
			task.wait(DialogState.typingSpeed)
		end
	end

	DialogState.isTyping = false
	DialogState.fullTextDisplayed = true
end

local function skipTyping()
	if DialogState.isTyping then
		DialogState.shouldSkip = true
	end
end

-- Dialog Progression Functions
local function displayNextDialog()
	if DialogState.currentDialogIndex <= #DialogState.dialogData then
		typeText(DialogState.dialogData[DialogState.currentDialogIndex])
		DialogState.currentDialogIndex = DialogState.currentDialogIndex + 1
	else
		if not DialogState.isResponse then
			-- Show initial options
			setOptionsVisible(true)
		else
			-- Check if we should continue with NextOptions
			if DialogState.currentDialogTree and DialogState.currentDialogTree.NextOptions then
				-- Set up the next set of options
				Dialog.CurrentOptions = DialogState.currentDialogTree.NextOptions
				updateOptionText(DialogState.currentDialogTree.NextOptions)
				setOptionsVisible(true)
			else
				-- If there are no NextOptions, handle end of dialog based on Action
				if DialogState.currentDialogTree and DialogState.currentDialogTree.Action ~= "ContinueDialog" then
					repeat
						task.wait(1)
					until not DialogState.isTyping
					print(DialogState.currentDialogTree.Action)
					closeDialog()
					toggleProx(true)
				else
					-- Handle the case when currentDialogTree is nil (initial dialog state)
					if not DialogState.currentDialogTree then
						-- This is likely the initial greeting, just close the dialog
						repeat
							task.wait(1)
						until not DialogState.isTyping
						closeDialog()
						toggleProx(true)
					end
				end
			end
		end
		DialogState.isResponse = false -- Reset for the next interaction
	end
end

-- Option Selection Handler
local function handleOptionClick(optionIndex)
	setOptionsVisible(false)

	local options = Dialog.CurrentOptions or {}
	local selectedOption = options[optionIndex]

	if not selectedOption then
		warn("No response found for Option " .. optionIndex)
		closeDialog()
		toggleProx(true)
		return
	end

	-- Store the current dialog tree position for later reference
	DialogState.currentDialogTree = selectedOption

	-- Process responses if they exist
	if selectedOption.Responses and #selectedOption.Responses > 0 then
		DialogState.dialogData = selectedOption.Responses
		DialogState.currentDialogIndex = 1
		DialogState.isResponse = true
		displayNextDialog()
	else
		-- If no responses but has NextOptions, immediately show the next options
		if selectedOption.NextOptions then
			Dialog.CurrentOptions = selectedOption.NextOptions
			updateOptionText(selectedOption.NextOptions)
			setOptionsVisible(true)
		end
	end

	-- Only close dialog for specific actions that should end the conversation
	local immediateCloseActions = {
		"EndDialog",
		"OpenShop", 
		"OpenCrafting", 
		"OpenBonfire"
	}

	-- Check if this action should close dialog immediately
	local shouldCloseImmediately = false
	for _, action in pairs(immediateCloseActions) do
		if selectedOption.Action == action then
			shouldCloseImmediately = true
			break
		end
	end

	repeat
		task.wait(0.5)
	until not DialogState.isTyping
	task.wait(0.5)
	dialogEvent:FireServer(selectedOption.Action, optionIndex)
	
	-- Close dialog for immediate actions or non-NPCs
	local nonNPCs = { Bonfire = true, Statue = true }
	if shouldCloseImmediately or nonNPCs[DialogState.speaker] then
		closeDialog()
	end
end

-- Main
function Dialog.Start()
	dialogEvent.OnClientEvent:Connect(function(dialog, npcName)
		if not dialog then
			warn("Received an empty dialog from the server!")
			return
		end

		-- Reset dialog state before starting new dialog
		resetDialogState()

		DialogState.speaker = npcName
		DialogState.dialogData = dialog.Greetings or {}
		DialogState.currentDialogIndex = 1
		NpcName.Text = npcName

		-- Set appropriate voice sound
		if speakerSounds[npcName] then
			DialogSound.SoundId = speakerSounds[npcName]
		else
			print("Speaker not found in sound mapping:", npcName)
		end

		-- Open the dialog UI
		openDialog()
		setOptionsVisible(false)

		-- Store and set up options
		local options = dialog.Options or {}
		Dialog.CurrentOptions = options
		updateOptionText(options)

		-- Start the dialog
		displayNextDialog()
	end)

	-- Assign event handlers
	Option1.MouseButton1Click:Connect(function()
		handleOptionClick(1)
	end)
	Option2.MouseButton1Click:Connect(function()
		handleOptionClick(2)
	end)
	Option3.MouseButton1Click:Connect(function()
		handleOptionClick(3)
	end)

	DialogButton.MouseButton1Click:Connect(function()
		if DialogState.isTyping then
			skipTyping()
		elseif DialogState.fullTextDisplayed and not DialogState.optionsVisible then
			displayNextDialog()
		end
	end)
	
	player.Character.Humanoid.Died:Connect(function()
		resetDialogState()
		toggleProx(true)
	end)
end

return Dialog
