-- Modules/SoundManager.lua
local SoundManager = {}
local soundCache = {}

-- Preload and cache sounds from all descendants
function SoundManager.preloadSounds(soundFolder)
	for _, descendant in ipairs(soundFolder:GetDescendants()) do
		if descendant:IsA("Sound") then
			soundCache[descendant.Name] = descendant
		end
	end
end

-- Play a sound
function SoundManager.playSound(soundName, parent, properties)
	local soundTemplate = soundCache[soundName]
	if not soundTemplate then
		warn("Sound not found: ", soundName)
		return
	end

	-- Clone and configure sound
	local sound = soundTemplate:Clone()
	sound.Parent = parent
	if properties then
		for key, value in pairs(properties) do
			sound[key] = value
		end
	end
	-- Play sound and cleanup
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return SoundManager
