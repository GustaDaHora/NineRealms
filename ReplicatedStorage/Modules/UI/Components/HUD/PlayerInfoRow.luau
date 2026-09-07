--[[
	PlayerInfoRow — Displays Player Name, Level, and Money in a reflowing layout.

	Props:
		playerName: string
		level: number
		money: number | string
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local MoneyDisplay = require(script.Parent.Parent.Shared.MoneyDisplay)
local e = React.createElement

export type PlayerInfoRowProps = {
	playerName: string,
	level: number,
	money: number | string,
	size: UDim2?,
	position: UDim2?,
}

local function PlayerInfoRow(props: PlayerInfoRowProps)
	return e("Frame", {
		Size = props.size or UDim2.new(0, 200, 0, 50),
		Position = props.position or UDim2.new(0, 85, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
		NameLabel = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundTransparency = 1,
			Text = props.playerName or "Player",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 20,
			TextColor3 = Color3.fromHex("#FFFFFF"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 1,
		}, {
			Stroke = e("UIStroke", {
				Color = Color3.fromHex("#1B1814"),
				Thickness = 1.5,
			}),
		}),
		StatsRow = e("Frame", {
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			LayoutOrder = 2,
		}, {
			RowLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			}),
			LevelBadge = e("TextLabel", {
				Size = UDim2.new(0, 50, 1, 0),
				BackgroundTransparency = 1,
				Text = string.format("Lv. %d", props.level or 1),
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#F2B705"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				LayoutOrder = 1,
			}, {
				Stroke = e("UIStroke", {
					Color = Color3.fromHex("#1B1814"),
					Thickness = 1,
				}),
			}),
			Money = e(MoneyDisplay, {
				amount = props.money or 0,
				size = UDim2.new(0, 80, 1, 0),
				textSize = 15,
				textColor = Color3.fromHex("#F2E079"),
			}),
		}),
	})
end

return PlayerInfoRow
