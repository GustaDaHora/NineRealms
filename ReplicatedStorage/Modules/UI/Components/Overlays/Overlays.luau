--[[
	Overlays — Root container for all transient game overlays and dialogs.

	Composes:
	  - CombatIndicator
	  - DamageIndicator
	  - LowHealth
	  - Dialog
	  - DeathMessage
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local useStore = require(script.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Store.StoreContext)

local CombatIndicator = require(script.Parent.CombatIndicator)
local DamageIndicator = require(script.Parent.DamageIndicator)
local LowHealth = require(script.Parent.LowHealth)
local Dialog = require(script.Parent.Dialog)
local DeathMessage = require(script.Parent.DeathMessage)

local e = React.createElement

local function Overlays()
	local store = React.useContext(StoreContext)

	if not store then
		return nil
	end

	local overlayState = useStore(store, function(state)
		local healthPct = (state.maxHealth and state.maxHealth > 0) and (state.health / state.maxHealth) or 1
		local isLow = state.lowHealth or (healthPct < 0.25 and not state.isDead)

		return {
			inCombat = state.inCombat,
			damageTaken = state.damageTaken,
			lowHealth = isLow,
			dialog = state.dialog,
			isDead = state.isDead,
			deathPhase = state.deathPhase or (state.isDead and "complete" or "inactive"),
		}
	end)

	local handleRespawn = function()
		local currentState = store:getState()
		if currentState and currentState.onRespawn then
			currentState.onRespawn()
		else
			store:dispatch(function(state)
				state.isDead = false
				state.deathPhase = "inactive"
				state.health = state.maxHealth or 100
				return state
			end)
		end
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Combat = e(CombatIndicator, { inCombat = overlayState.inCombat }),
		Damage = e(DamageIndicator, { active = overlayState.damageTaken }),
		LowHp = e(LowHealth, { active = overlayState.lowHealth }),
		NpcDialog = e(Dialog, { dialog = overlayState.dialog }),
		Death = e(DeathMessage, {
			phase = overlayState.deathPhase,
			onRespawn = handleRespawn,
		}),
	})
end

return Overlays
