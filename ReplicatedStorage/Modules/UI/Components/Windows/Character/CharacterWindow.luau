--[[
	CharacterWindow — Player profile, equipment attributes, core stats, prestige, and combat record.

	Composes:
	  - CharacterPreview (center top)
	  - StatPanel (chip variant, left: core stats)
	  - StatPanel (chip variant, right: equipment info)
	  - StatPanel (plain variant, center-left: prestige)
	  - StatPanel (plain variant, center-right: combat record)
	  - CloseButton + WindowLabel

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local StatPanel = require(script.Parent.Parent.Parent.Shared.StatPanel)
local CharacterPreview = require(script.Parent.Parent.Parent.Shared.CharacterPreview)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type CharacterWindowProps = {
	onClose: (() -> ())?,
}

local function CharacterWindow(props: CharacterWindowProps)
	local store = React.useContext(StoreContext)

	local charState = useStore(store, function(state)
		return {
			name = state.playerName,
			level = state.level,
			stats = state.playerStats or {},
			combat = state.combatRecord or {},
			prestige = state.prestige or {},
		}
	end)

	local coreStats = {
		{ label = "Strength", value = charState.stats.strength or 0 },
		{ label = "Vitality", value = charState.stats.vitality or 0 },
		{ label = "Agility", value = charState.stats.agility or 0 },
		{ label = "Level", value = charState.level or 1 },
	}

	local equipInfo = {
		{ label = "Weight", value = charState.stats.weight or 0 },
		{ label = "Armor", value = charState.stats.armor or 0 },
		{ label = "Souls Ratio", value = charState.stats.soulsRatio or "0/0" },
		{ label = "HackSilver", value = charState.stats.hackSilver or 0 },
	}

	local prestigeEntries = {
		{ label = "Title", value = charState.prestige.title or "None" },
		{ label = "Rank", value = charState.prestige.rank or "None" },
		{ label = "Tier", value = charState.prestige.tier or 0 },
		{ label = "Fame", value = charState.prestige.fame or 0 },
	}

	local combatEntries = {
		{ label = "Kills", value = charState.combat.kills or 0 },
		{ label = "Deaths", value = charState.combat.deaths or 0 },
		{ label = "PvP Wins", value = charState.combat.pvpWins or 0 },
		{ label = "PvP Losses", value = charState.combat.pvpLosses or 0 },
		{ label = "Time Played", value = charState.combat.timePlayed or "0h" },
	}

	return e("Frame", {
		Size = UDim2.new(0, 680, 0, 500),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#0D1413"),
		BackgroundTransparency = 0.04,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#B8964F"),
			Thickness = 2.5,
		}, {
			Gradient = e("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHex("#F2B705")),
					ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFF4A3")),
					ColorSequenceKeypoint.new(1, Color3.fromHex("#F2B705")),
				}),
				Rotation = 45,
			}),
		}),
		InnerStroke = e("UIStroke", { Color = Color3.fromHex("#42615B"), Thickness = 7, Transparency = 0.68 }),
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		Close = e(CloseButton, {
			onClick = function()
				if props.onClose then
					props.onClose()
				end
			end,
		}),
		Header = e(WindowLabel, {
			title = "Character Profile",
			subtitle = charState.name,
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 8),
		}),

		-- Left Column: Core Stats (Chip variant)
		LeftCol = e("Frame", {
			Size = UDim2.new(0, 160, 0, 160),
			Position = UDim2.new(0, 24, 0, 75),
			BackgroundTransparency = 1,
		}, {
			SectionTitle = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "CORE STATS",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 17,
				TextColor3 = Color3.fromHex("#F2B705"),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Stats = e(StatPanel, {
				entries = coreStats,
				variant = "chip",
				position = UDim2.new(0, 0, 0, 24),
			}),
		}),

		-- Center Column: Character 3D Viewport
		CenterPreview = e("Frame", {
			Size = UDim2.new(0, 180, 0, 210),
			Position = UDim2.new(0.5, 0, 0, 65),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
		}, {
			Preview = e(CharacterPreview, {
				playerName = charState.name,
				size = UDim2.new(1, 0, 1, 0),
				showName = false,
			}),
		}),

		-- Right Column: Equipment Stats (Chip variant)
		RightCol = e("Frame", {
			Size = UDim2.new(0, 160, 0, 160),
			Position = UDim2.new(1, -24, 0, 75),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			SectionTitle = e("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "EQUIPMENT INFO",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 17,
				TextColor3 = Color3.fromHex("#F2B705"),
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Info = e(StatPanel, {
				entries = equipInfo,
				variant = "chip",
				position = UDim2.new(0, 0, 0, 24),
			}),
		}),

		-- Bottom Section: Prestige (left) and Combat Record (right) (Plain variant)
		BottomSection = e("Frame", {
			Size = UDim2.new(1, -48, 0, 170),
			Position = UDim2.new(0.5, 0, 1, -16),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromHex("#14201E"),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, {
			SectionCorner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
			SectionStroke = e("UIStroke", {
				Color = Color3.fromHex("#42615B"),
				Thickness = 1,
				Transparency = 0.5,
			}),
			PrestigeCol = e("Frame", {
				Size = UDim2.new(0.5, -12, 1, -16),
				Position = UDim2.new(0, 12, 0, 8),
				BackgroundTransparency = 1,
			}, {
				PrestigeTitle = e("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "PRESTIGE & TITLES",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 17,
					TextColor3 = Color3.fromHex("#F2B705"),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Prestige = e(StatPanel, {
					entries = prestigeEntries,
					variant = "plain",
					position = UDim2.new(0, 0, 0, 22),
				}),
			}),
			CombatCol = e("Frame", {
				Size = UDim2.new(0.5, -12, 1, -16),
				Position = UDim2.new(0.5, 6, 0, 8),
				BackgroundTransparency = 1,
			}, {
				CombatTitle = e("TextLabel", {
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = "COMBAT RECORD",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 17,
					TextColor3 = Color3.fromHex("#F2B705"),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Combat = e(StatPanel, {
					entries = combatEntries,
					variant = "plain",
					position = UDim2.new(0, 0, 0, 22),
				}),
			}),
		}),
	})
end

return CharacterWindow
