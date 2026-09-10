local TS = game:GetService("TweenService")
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local gui = script.Parent.Parent
local zoneGUI = gui:WaitForChild("ZoneFrame")
local description = zoneGUI:WaitForChild("Description")
local zoneText = zoneGUI:WaitForChild("ZoneText")
local frame1 = zoneText:WaitForChild("Frame1")
local frame2 = zoneText:WaitForChild("Frame2")
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- List of zones with PvP status and descriptions
local LocalZones = {
	["Wilderness"] = {pvp = false, description = "An Area in Which Plants Are Left to Grow Naturally and Untidily."},

	-- Settlements & Known Areas
	["Bergdalr"] = {pvp = false, description = "A Humble Village, Heart of Midgard's Frontier."},
	--["Klipprug Peaks"] = {pvp = false, description = "A Rugged Terrain of Sharp Peaks."},
	--["Klipprug Caves"] = {pvp = false, description = "A Rugged Terrain of Narrow Paths."},
	["Kornhavn"] = {pvp = false, description = "A Vast Wheat Field Where the Wind Stirs the Windmill's Sails."},
	--["Vetrgardr"] = {pvp = false, description = "A Proud and Fortified Norse Village Known for Its Resilience and Strength."},
	--["Eldurheim Ruins"] = { pvp = true, description = "Crumbled Stones and Shattered Arches Whisper of a Once-Great Civilization."},
	--["Hegrholt"] = { pvp = false, description = "A Modest Hamlet Nestled Beneath the Cliffs."},
	--["Coliseum"] = {pvp = true, description = "Blood painted place where warriors prove their value."},
	
	---- Hostile Biomes
	["Deyjaskog"] = {pvp = true, description = "A Lifeless Forest Shrouded in Dense Fog."},

	---- Cold Areas
	["Isdalr"] = {pvp = true, description = "A Frozen Valley Echoing with the Wind."},
	--["Blódheim"] = {pvp = true, description = "Where Blood Once Froze Into the Snow. A Silent Battleground Lost to Time."},
	--["Skelbrekka"] = {pvp = true, description = "Jagged Ridges Carved by Relentless Winds and Ancient Glacierflows."},
	--["Frostgardr"] = {pvp = true, description = "Once a Border Fort, Now a Frozen Wreck Claimed by the Elements."},
	--["Njord's Eye"] = {pvp = true, description = "A Watchful Cliff Over the Eastern Sea, Claimed by the Chill of the North Wind."},
	--["Vargskar Cliffs"] = {pvp = true, description = "A wind-battered mountain face once said to guard the gods' secrets."},

	---- Forest Expansions
	["Veidiskog"] = {pvp = true, description = "A Dense and Ancient Forest Teeming with Wildlife."},
	--["Ljoslund"] = {pvp = true, description = "Where the Canopy Parts and Moonlight Touches the Forest Floor."},
	--["Dimholt"] = {pvp = true, description = "A Denser Forest Where Little Light Penetrates and Old Creatures Stir."},
	--["Eikthyrnir Reach"] = {pvp = true, description = "Said to Be Wandered by the Spirit of a Celestial Stag. Few Return."},
	--["Huldraholt"] = {pvp = true, description = "The Forest is Beautiful… and It Watches You."},
	--["Galdrskog"] = {pvp = true, description = "Moss-Covered Stones, Forgotten Circles—Magic Lingers Here Still."},

	---- Ravencall-Controlled Plains
	["Ravencall Encampment"] = {pvp = true, description = "The Festering Den of the Ravencall Scum."},
	--["Skorval Outlands"] = {pvp = true, description = "Twilight Fields Patrolled by the Scars of War."},
	--["Askrey Fields"] = {pvp = true, description = "Barren Lands Where the Forests Were Cut to Feed the Fires of War."},
	--["Drekkahlid"] = {pvp = true, description = "This Field Marks the Threshold to Ravencall's Fortress—Many Drank Death Here."},
	--["Vargholt Expanse"] = {pvp = true, description = "Wolves Run Freely In These Wilds, Unchecked and Unchained."},

	---- Points & Events
	--["Svartrholt"] = {pvp = true, description = "A Gloomy Grove Where Light Dares Not Enter."},
	--["Draumstein"] = {pvp = false, description = "A Lonely Boulder Said to Whisper in Dreams."},
	--["Hrafnvik"] = {pvp = false, description = "A Wind-Battered Bay Once Used by Ravencall Raiders."},

	---- Unique Zones
	--["Svaðilfari's Tread"] = {pvp = true, description = "A Strange Road of Stone Hooves and Broken Oaths. The Air Here Is Unnatural."},
	--["Wanderer’s End"] = {pvp = false, description = "Where the Trees Turn and Paths Vanish."},
	--["Wanderer’s Fall"] = {pvp = true, description = "A Sheer Drop Into Fog and Forest Below. Many Took the Wrong Step."},
	--["Uruz' Crossing"] = {pvp = true, description = "A Rocky Terrain Once Used by Giants and War Beasts to Cross Realms."}
}

local zone = {}
local cooldown = false 

-- Function to handle text and frame visibility tweens
local function tweenZone(currentZone)
	if cooldown then return end -- Prevent triggering if cooldown is active
	cooldown = true
	-- Get zone info from the Zones table
	local zoneInfo = LocalZones[currentZone]
	if not zoneInfo then return end

	-- Update text elements with zone information
	zoneText.Text = currentZone
	description.Text = zoneInfo["description"]

	-- Set PvP indicator text
	local pvpStatus = zoneInfo.PVP and "PvP On" or "PvP Off"
	zoneText.Text = currentZone .. " - " .. pvpStatus
	-- Fade in the text and frames
	local showTextTween = TS:Create(zoneText, tweenInfo, { TextTransparency = 0 })
	local showPVPTween = TS:Create(description, tweenInfo, { TextTransparency = 0 })
	local showFrame1Tween = TS:Create(frame1, tweenInfo, { BackgroundTransparency = 0 })
	local showFrame2Tween = TS:Create(frame2, tweenInfo, { BackgroundTransparency = 0 })

	showTextTween:Play()
	showPVPTween:Play()
	showFrame1Tween:Play()
	showFrame2Tween:Play()

	showTextTween.Completed:Wait() -- Wait for the text tween to finish

	-- Wait before fading out
	task.wait(3)

	-- Fade out the text and frames
	local hideTextTween = TS:Create(zoneText, tweenInfo, { TextTransparency = 1 })
	local hidePVPTween = TS:Create(description, tweenInfo, { TextTransparency = 1 })
	local hideFrame1Tween = TS:Create(frame1, tweenInfo, { BackgroundTransparency = 1 })
	local hideFrame2Tween = TS:Create(frame2, tweenInfo, { BackgroundTransparency = 1 })

	hideTextTween:Play()
	hidePVPTween:Play()
	hideFrame1Tween:Play()
	hideFrame2Tween:Play()

	-- Wait for fade-out completion and reset cooldown
	hideTextTween.Completed:Wait()
	cooldown = false
end

function zone.Start()
	char:GetAttributeChangedSignal("Zone"):Connect(function()
		local currentZone = char:GetAttribute("Zone")
		if currentZone then
			tweenZone(currentZone) -- Pass the current zone to tweenZone
		end
	end)
end

return zone