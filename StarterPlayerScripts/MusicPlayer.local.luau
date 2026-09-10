local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local areasGroup = SoundService:FindFirstChild("AreasGroup")

if not areasGroup then
	warn("AreasGroup not found in SoundService!")
	return
end

local currentZone = nil
local debounce = false
local DEBOUNCE_TIME = 5 -- Time before checking again

-- Zone music with weighted probability (Snow Ambient = default)
local zoneMusic = {
	["Wilderness"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"), 
		tracks = {
			areasGroup:FindFirstChild("Forest Ambient"),
			areasGroup:FindFirstChild("Glacial"),
			areasGroup:FindFirstChild("It's Alone")
		}
	},
	["Bergdalr"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"), 
		tracks = {
			areasGroup:FindFirstChild("Nordic Accordion Mood"),
			areasGroup:FindFirstChild("Glow Worm Cave C"),
			areasGroup:FindFirstChild("Promise Of Snow Underscore B"),
		}
	},
	["Klipprug Peaks"] = {
		default = areasGroup:FindFirstChild("Crystal Citadel"), 
		tracks = {
			areasGroup:FindFirstChild("Glow Worm Cave C"),
		}
	},
	["Klipprug Caves"] = {
		default = areasGroup:FindFirstChild("Cave"), 
		tracks = {
			areasGroup:FindFirstChild("Beneath the Dread Moon"),
			areasGroup:FindFirstChild("cave dweller"),
		}
	},
	["Vetrgardr"] = {
		default = areasGroup:FindFirstChild("Starlight"), 
		tracks = {
			areasGroup:FindFirstChild("Nordic Accordion Mood"),
			areasGroup:FindFirstChild("Discovering Snow"),
			areasGroup:FindFirstChild("Nordic Dream"),
		}
	},
	["Hegrholt"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"), 
		tracks = {
			areasGroup:FindFirstChild("Snow Ambient"),
			areasGroup:FindFirstChild("Nordic Accordion Mood"),
		}
	},		
	["Deyjaskog"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"), 
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
			areasGroup:FindFirstChild("Nordic Landscape")
		}
	},
	-- Cold Areas
	["Isdalr"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"), 
		tracks = {
			areasGroup:FindFirstChild("Alone In The Snow"),
			areasGroup:FindFirstChild("Mirage Portal")
		}
	},
	["Blódheim"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Arctic Panorama"),
			areasGroup:FindFirstChild("Beneath the Dread Moon")
		}
	},
	["Skelbrekka"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
			areasGroup:FindFirstChild("Arctic Panorama2"),
		}
	},
	["Frostgardr"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
			areasGroup:FindFirstChild("Glacial"),
		}
	},
	["Njord's Eye"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Endless Winter"),
			areasGroup:FindFirstChild("Shadow in the Room"),
		}
	},
	["Vargskar Cliffs"] = {
		default = areasGroup:FindFirstChild("Snow Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Discovering Snow"),
			areasGroup:FindFirstChild("Promise Of Snow Underscore B"),
		}
	},

	-- Forest Expansions
	["Veidiskog"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
		}
	},
	["Ljoslund"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
		}
	},
	["Dimholt"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Nordic Drama"),
		}
	},
	["Eikthyrnir Reach"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Mars Dome"),
		}
	},
	["Huldraholt"] = {
		default = areasGroup:FindFirstChild("Forest Ambient"),
		tracks = {
			areasGroup:FindFirstChild("Velvet Night Tides"),
		}
	},
	["Ravencall Encampment"] = {
		default = areasGroup:FindFirstChild("The Cage"),
		tracks = {
			areasGroup:FindFirstChild("Forest Ambient"),
		}
	},
	["Drekkahlid"] = {
		default = areasGroup:FindFirstChild("The Cage"),
		tracks = {
			areasGroup:FindFirstChild("Forest Ambient"),
		}
	},
}

-- Currently playing sound
local currentSound

-- Function to get the player's current zone
local function getPlayerZone()
	return character:GetAttribute("Zone") -- Gets the "Zone" attribute from the character
end

-- Function to stop currently playing music smoothly
local function stopCurrentMusic()
	if currentSound then
		currentSound:Stop()
		currentSound = nil
	end
end

-- Function to select a music track with weighted probability
local function chooseTrackForZone(zone)
	local zoneData = zoneMusic[zone]
	if not zoneData or not zoneData.default then return nil end

	local defaultTrack = zoneData.default
	local tracks = zoneData.tracks

	-- 70% chance to play "Snow Ambient", 30% chance to play a random track
	local chance = math.random(1, 100)
	if chance <= 70 or #tracks == 0 then
		return defaultTrack
	else
		return tracks[math.random(1, #tracks)]
	end
end

-- Function to play music for a given zone
local function playMusicForZone(zone)
	local sound = chooseTrackForZone(zone)

	if sound and sound ~= currentSound then
		stopCurrentMusic() -- Stop the previous music smoothly

		currentSound = sound
		currentSound.Volume = 0 -- Start at zero volume
		currentSound.Looped = true
		currentSound:Play()

		-- Smooth fade-in effect
		while currentSound.Volume < 0.1 do
			currentSound.Volume = math.min(0.4, currentSound.Volume + 0.05)
			task.wait(1)
		end

		print("Now playing: " .. currentSound.Name .. " for zone: " .. zone)
	end
end

-- Function to handle area entry logic
local function handleArea(zone)
	if not zone or debounce then return end

	debounce = true -- Activate debounce

	if zone ~= currentZone then
		playMusicForZone(zone) -- Play new zone music
		currentZone = zone
	end

	task.wait(DEBOUNCE_TIME)
	debounce = false
end

-- Main loop to check player's zone
RunService.Heartbeat:Connect(function()
	local newZone = getPlayerZone()

	if newZone and newZone ~= currentZone then
		handleArea(newZone)
	end
	task.wait(10)
end)

player.CharacterAdded:Connect(function(char)
	character = char
	currentZone = nil
	currentSound = nil
end)