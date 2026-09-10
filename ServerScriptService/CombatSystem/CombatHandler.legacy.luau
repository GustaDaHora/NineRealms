--// ServerScriptService/CombatSystem/CombatHandler.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CombatLogic = require(script.Parent.CombatLogic)
local WeaponConfigs = require(script.Parent.WeaponConfigs)

local remotes = ReplicatedStorage:WaitForChild("RE")
local CombatRemotes = remotes:WaitForChild("Combat")

-- Initialize handlers for each weapon defined in config
for weaponName, config in pairs(WeaponConfigs) do
	local remote = CombatRemotes:FindFirstChild(weaponName .. "Combat")

	if remote then
		--print("Initializing Combat Handler for: " .. weaponName)
		remote.OnServerEvent:Connect(function(player, tool, attackType)
			CombatLogic.processAttack(player, tool, attackType, weaponName)
		end)
	else
		warn("Could not find RemoteEvent for weapon: " .. weaponName .. "Combat")
	end
end