--[[
	useStore — React hook that subscribes a component to a slice of store state.

	Usage:
		local money = useStore(store, function(state)
			return state.money
		end)

	The component re-renders only when the selected slice's value changes
	(shallow equality check for tables, reference equality for primitives).
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)

local function shallowEqual(a: any, b: any): boolean
	if a == b then
		return true
	end

	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end

	-- Check same number of keys
	local aCount = 0
	for _ in a do
		aCount += 1
	end
	local bCount = 0
	for _ in b do
		bCount += 1
	end
	if aCount ~= bCount then
		return false
	end

	for key, value in a do
		if b[key] ~= value then
			return false
		end
	end

	return true
end

local function useStore(store, selector: (state: any) -> any): any
	local selectorRef = React.useRef(selector)
	selectorRef.current = selector
	local value, setValue = React.useState(selector(store:getState()))

	React.useEffect(function()
		local unsubscribe = store:subscribe(function(newState)
			local newValue = selectorRef.current(newState)
			-- setValue with updater function to avoid stale closure
			setValue(function(prev)
				if shallowEqual(prev, newValue) then
					return prev
				end
				return newValue
			end)
		end)

		return unsubscribe
	end, { store } :: { any })

	return value
end

return useStore
