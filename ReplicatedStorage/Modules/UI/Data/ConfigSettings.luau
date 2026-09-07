--[[
	ConfigSettings — Visual and gameplay configuration options.
]]

export type SettingDefinition = {
	id: string,
	label: string,
	description: string?,
	defaultValue: boolean,
}

local ConfigSettings: { SettingDefinition } = {
	{
		id = "LowerTerrainQuality",
		label = "Lower Terrain Quality",
		description = "Reduces voxel terrain fidelity for improved performance.",
		defaultValue = false,
	},
	{
		id = "GlobalShadows",
		label = "Global Shadows",
		description = "Enables detailed dynamic shadows from light sources.",
		defaultValue = true,
	},
	{
		id = "SunRays",
		label = "Sun Rays",
		description = "Enables atmospheric sun ray light scattering.",
		defaultValue = true,
	},
	{
		id = "BloomEffect",
		label = "Bloom Effect",
		description = "Enables blooming glow around bright lights and magic effects.",
		defaultValue = true,
	},
}

return ConfigSettings
