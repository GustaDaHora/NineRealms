-- UIController/Dialog.luau
-- Migrated to React-Luau UIStore architecture

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local UI = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UI"))
local store = UI.store
local player = Players.LocalPlayer

local dialogEvent = ReplicatedStorage:WaitForChild("RE"):WaitForChild("NPCs"):WaitForChild("Dialog")

local Dialog = {}

local speakerSounds = {
	InnerVoice = "rbxassetid://3620844678",
	Bjorn = "rbxassetid://418252437",
	Eldrim = "rbxassetid://9063549513",
	Haldor = "rbxassetid://9119556229",
	Leifrik = "rbxassetid://9120430448",
}

local currentSound = nil

local function playVoice(speakerName: string)
	local soundId = speakerSounds[speakerName]
	if soundId then
		if not currentSound then
			currentSound = Instance.new("Sound")
			currentSound.Name = "DialogVoice"
			currentSound.Parent = SoundService
		end
		currentSound.SoundId = soundId
		currentSound:Play()
	end
end

local function toggleProximityPrompts(enabled: boolean)
	local alives = workspace:FindFirstChild("Alives")
	local npcs = alives and alives:FindFirstChild("NPCs")
	local dialogNpcs = npcs and npcs:FindFirstChild("DialogNPCs")
	if dialogNpcs then
		for _, npc in ipairs(dialogNpcs:GetChildren()) do
			local root = npc:FindFirstChild("HumanoidRootPart")
			local prompt = root and root:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = enabled
			end
		end
	end
end

local function closeDialog()
	store:dispatch(function(state)
		state.dialog = nil
		return state
	end)
	toggleProximityPrompts(true)
end

function Dialog.Start()
	dialogEvent.OnClientEvent:Connect(function(dialogData, npcName)
		if not dialogData then
			closeDialog()
			return
		end

		toggleProximityPrompts(false)
		playVoice(npcName)

		local greetings = dialogData.Greetings or { "..." }
		local currentGreetingIndex = 1
		local options = dialogData.Options or {}

		local function showOptions(opts: { any })
			local uiOptions = {}
			for idx, opt in ipairs(opts) do
				table.insert(uiOptions, {
					label = opt.Text or ("Option " .. idx),
					onClick = function()
						playVoice(npcName)

						-- Check for immediate closing actions
						local action = opt.Action or "ContinueDialog"
						dialogEvent:FireServer(action, idx)

						if action == "EndDialog" or action == "OpenShop" or action == "OpenCrafting" or action == "OpenBonfire" then
							closeDialog()
							return
						end

						-- If option has responses, show them
						if opt.Responses and #opt.Responses > 0 then
							local respIdx = 1
							local function advanceResponse()
								if respIdx <= #opt.Responses then
									local text = opt.Responses[respIdx]
									respIdx += 1
									store:dispatch(function(state)
										state.dialog = {
											speakerName = npcName,
											text = text,
											mode = "continue",
											onContinue = advanceResponse,
										}
										return state
									end)
								else
									if opt.NextOptions and #opt.NextOptions > 0 then
										showOptions(opt.NextOptions)
									else
										closeDialog()
									end
								end
							end
							advanceResponse()
						elseif opt.NextOptions and #opt.NextOptions > 0 then
							showOptions(opt.NextOptions)
						else
							closeDialog()
						end
					end,
				})
			end

			store:dispatch(function(state)
				state.dialog = {
					speakerName = npcName,
					text = "What would you like to discuss?",
					mode = "options",
					options = uiOptions,
				}
				return state
			end)
		end

		local function advanceGreeting()
			if currentGreetingIndex <= #greetings then
				local text = greetings[currentGreetingIndex]
				currentGreetingIndex += 1

				store:dispatch(function(state)
					state.dialog = {
						speakerName = npcName,
						text = text,
						mode = "continue",
						onContinue = advanceGreeting,
					}
					return state
				end)
			else
				if #options > 0 then
					showOptions(options)
				else
					closeDialog()
				end
			end
		end

		advanceGreeting()
	end)

	player.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.Died:Connect(closeDialog)
	end)
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid.Died:Connect(closeDialog)
	end
end

return Dialog
