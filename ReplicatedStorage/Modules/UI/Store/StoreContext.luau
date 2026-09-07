--[[
	StoreContext — React Context for providing and consuming the UIStore instance.
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)

local StoreContext = React.createContext(nil)

return StoreContext
