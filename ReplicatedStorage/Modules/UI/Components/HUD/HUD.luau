--[[
	HUD — Root container for persistent gameplay HUD elements.

	Composes:
		- PlayerInfoRow
		- VitalsRow
		- ZoneBanner
		- SkillHotbar
		- WeaponSelector
		- RadialMenu

	Reads state from UIStore and dispatches window navigation and weapon cycling.
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local useStore = require(script.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Store.StoreContext)

local PlayerInfoRow = require(script.Parent.PlayerInfoRow)
local VitalsRow = require(script.Parent.VitalsRow)
local ZoneBanner = require(script.Parent.ZoneBanner)
local SkillHotbar = require(script.Parent.SkillHotbar)
local WeaponSelector = require(script.Parent.WeaponSelector)
local RadialMenu = require(script.Parent.RadialMenu)
local IconRing = require(script.Parent.Parent.Shared.IconRing)

local e = React.createElement

local function HUD()
	local store = React.useContext(StoreContext)

	if not store then
		return nil
	end

	-- Subscriptions via useStore
	local playerInfo = useStore(store, function(state)
		return {
			name = state.playerName,
			level = state.level,
			money = state.money,
			avatarUrl = state.playerAvatarUrl,
		}
	end)

	local vitals = useStore(store, function(state)
		return {
			health = state.health,
			maxHealth = state.maxHealth,
			souls = state.souls,
			maxSouls = state.maxSouls,
		}
	end)

	local zone = useStore(store, function(state)
		return {
			name = state.currentZone,
			description = state.zoneDescription,
		}
	end)

	local skills = useStore(store, function(state)
		return state.skills
	end)

	local skillCooldowns = useStore(store, function(state)
		return state.skillCooldowns
	end)

	local weapons = useStore(store, function(state)
		return state.equippedWeapons
	end)

	local activeWeaponIndex = useStore(store, function(state)
		return state.activeWeaponIndex or 1
	end)

	local fastMenu = useStore(store, function(state)
		return {
			isOpen = state.fastMenuOpen == true,
			selection = state.fastMenuSelection,
			activateSkill = state.activateSkill,
		}
	end)

	-- Handlers
	local handleSelectWindow = function(windowName: string)
		store:dispatch(function(state)
			state.activeWindow = windowName
			state.fastMenuOpen = false
			state.fastMenuSelection = nil
			return state
		end)
	end

	local handleToggleFastMenu = function()
		store:dispatch(function(state)
			state.fastMenuOpen = not state.fastMenuOpen
			if not state.fastMenuOpen then
				state.fastMenuSelection = nil
			end
			return state
		end)
	end

	local handleCycleWeapon = function(newIndex: number)
		store:dispatch(function(state)
			state.activeWeaponIndex = newIndex
			return state
		end)
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- Top-Left Identity & Vitals Section
		TopLeftSection = e("Frame", {
			Size = UDim2.new(0, 320, 0, 130),
			Position = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			Vitals = e(VitalsRow, {
				health = vitals.health,
				maxHealth = vitals.maxHealth,
				souls = vitals.souls,
				maxSouls = vitals.maxSouls,
				position = UDim2.new(0, 0, 0, 48),
			}),
			Avatar = (playerInfo.avatarUrl and playerInfo.avatarUrl ~= "") and e(IconRing, {
				image = playerInfo.avatarUrl,
				size = UDim2.new(0, 56, 0, 56),
				position = UDim2.new(0, 8, 0, -6),
				cornerRadius = UDim.new(1, 0),
			}) or nil,
			PlayerInfo = e(PlayerInfoRow, {
				playerName = playerInfo.name,
				level = playerInfo.level,
				money = playerInfo.money,
				position = UDim2.new(0, 76, 0, 0),
			}),
		}),

		-- Top-Center Zone Announcement
		Zone = e(ZoneBanner, {
			zoneName = zone.name,
			zoneDescription = zone.description,
			visible = zone.name ~= "",
		}),

		-- Bottom-Center Abilities Hotbar
		Hotbar = e(SkillHotbar, {
			skills = skills,
			cooldowns = skillCooldowns,
			onSkillClick = fastMenu.activateSkill,
		}),

		-- Bottom-Right Weapon Selector
		Weapons = e(WeaponSelector, {
			weapons = weapons,
			activeIndex = activeWeaponIndex,
			onCycle = handleCycleWeapon,
		}),

		-- Right-Center Radial Navigation Hub
		Radial = e(RadialMenu, {
			isOpen = fastMenu.isOpen,
			selectedWindow = fastMenu.selection,
			position = UDim2.new(1, -30, 0.45, 0),
			anchorPoint = Vector2.new(1, 0.5),
			onToggle = handleToggleFastMenu,
			onSelectWindow = handleSelectWindow,
		}),
	})
end

return HUD
