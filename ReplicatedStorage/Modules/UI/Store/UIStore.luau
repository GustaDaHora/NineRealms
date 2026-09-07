--[[
	UIStore — Minimal reactive state store for the NineRealms UI.

	Usage:
		local store = UIStore.new(initialState)
		store:getState()           -- returns current state table
		store:dispatch(updater)    -- updater: (state) -> newState
		store:subscribe(listener)  -- listener: (newState) -> (), returns unsubscribe fn
]]

local UIStore = {}
UIStore.__index = UIStore

function UIStore.new(initialState: { [string]: any }?)
	local self = setmetatable({}, UIStore)
	self._state = initialState or UIStore._defaultState()
	self._listeners = {} :: { [number]: (any) -> () }
	self._nextId = 1
	return self
end

function UIStore._defaultState()
	return {
		-- Window management
		activeWindow = nil :: string?, -- "Inventory"|"Character"|"Skills"|"Config"|"Shop"|"Crafting"|"BonFire"|"Events"|"Guide"|"Quests"|"Clan"|nil
		-- Fast-menu interaction is global because its input is owned by a controller,
		-- while the presentation is owned by the React HUD.
		fastMenuOpen = false,
		fastMenuSelection = nil :: string?,

		-- Player identity
		playerName = "Player",
		playerAvatarUrl = "",
		level = 1,
		money = 0,

		-- Vitals
		health = 100,
		maxHealth = 100,
		souls = 0,
		maxSouls = 100,

		-- Zone
		currentZone = "",
		zoneDescription = "",

		-- Combat state
		inCombat = false,
		isDead = false,
		deathPhase = "inactive" :: "inactive" | "playing" | "complete",
		damageTaken = false,
		lowHealth = false,
		onRespawn = nil :: (() -> ())?,

		-- Equipment & Inventory
		equippedItems = {} :: { [string]: any },
		inventory = {} :: { [string]: any },
		inventoryAction = nil :: ((actionType: string, item: any) -> ())?,

		-- Stats
		playerStats = {
			strength = 0,
			vitality = 0,
			agility = 0,
			weaponPower = 0,
			weight = 0,
			armor = 0,
			soulsRatio = "0/0",
			hackSilver = 0,
		},

		-- Combat record
		combatRecord = {
			kills = 0,
			deaths = 0,
			pvpWins = 0,
			pvpLosses = 0,
			timePlayed = "0h",
		},

		-- Prestige
		prestige = {
			title = "None",
			rank = "None",
			tier = 0,
			fame = 0,
		},

		-- Skills
		skills = {} :: { [number]: any }, -- active skill slots 1-4
		skillCooldowns = {} :: { [number]: { remaining: number, total: number } },
		unlockedSkills = { Initial = true } :: { [string]: boolean },
		chosenPath = nil :: string?, -- "Aegishjalmur" | "Vegvisir" | nil
		unlockSkill = nil :: ((skillName: string) -> boolean)?,
		equipSkill = nil :: ((skillName: string, slot: number) -> ())?,
		activateSkill = nil :: ((slot: number) -> ())?,

		-- Weapons (3-weapon selector)
		equippedWeapons = {} :: { [number]: any }, -- up to 3 weapons
		activeWeaponIndex = 1,

		-- Dialog
		dialog = nil :: {
			speakerName: string,
			text: string,
			mode: ("continue" | "choice" | "options")?,
			options: { { label: string, onClick: () -> () } }?,
			onContinue: (() -> ())?,
			onAccept: (() -> ())?,
			onRefuse: (() -> ())?,
		}?,

		-- Config settings
		config = {} :: { [string]: boolean },

		-- Events
		events = {} :: { { id: string, name: string, description: string, image: string } },

		-- Shop/Crafting data (populated by NPC interaction)
		shopItems = {} :: { [string]: any },
		shopMode = "Shop" :: "Shop" | "Crafting" | "BonFire",
	}
end

function UIStore:getState()
	return self._state
end

local function cloneState(value: any, seen: { [any]: any }?): any
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy
	for key, nestedValue in value do
		copy[cloneState(key, seen)] = cloneState(nestedValue, seen)
	end
	return copy
end

function UIStore:dispatch(updater: (state: any) -> any)
	-- The store contract is immutable. Supplying a cloned draft also protects the
	-- previous snapshot from legacy callers that still assign into `state`.
	local newState = updater(cloneState(self._state))
	if newState ~= nil then
		self._state = newState
		self:_notifyListeners()
	end
end

function UIStore:subscribe(listener: (state: any) -> ()): () -> ()
	local id = self._nextId
	self._nextId += 1
	self._listeners[id] = listener

	-- Return unsubscribe function
	return function()
		self._listeners[id] = nil
	end
end

function UIStore:_notifyListeners()
	for _, listener in self._listeners do
		listener(self._state)
	end
end

return UIStore
