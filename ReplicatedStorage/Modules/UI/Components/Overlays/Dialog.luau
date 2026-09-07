--[[
	Dialog — NPC conversation dialog overlay.

	Modes:
	  - "continue": Single button to advance linear dialog.
	  - "choice": Branching decisions (Accept / Refuse).

	Props:
		dialog: {
			speakerName: string,
			text: string,
			mode: ("continue" | "choice")?,
			onContinue: (() -> ())?,
			onAccept: (() -> ())?,
			onRefuse: (() -> ())?,
		}?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type DialogData = {
	speakerName: string,
	text: string,
	mode: ("continue" | "choice")?,
	onContinue: (() -> ())?,
	onAccept: (() -> ())?,
	onRefuse: (() -> ())?,
}

export type DialogProps = {
	dialog: DialogData?,
}

local function Dialog(props: DialogProps)
	local dialog = props.dialog
	if not dialog then
		return nil
	end

	local mode = dialog.mode or "continue"

	return e("Frame", {
		Size = UDim2.new(0, 600, 0, 160),
		Position = UDim2.new(0.5, 0, 0.85, 0),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromHex("#050519"),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		ZIndex = 12,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#F2B705"),
			Thickness = 2,
		}),

		-- Decorative gold pillar accents on left & right
		LeftPillar = e("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromHex("#F2B705"),
			BorderSizePixel = 0,
		}),
		RightPillar = e("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(1, -4, 0, 0),
			BackgroundColor3 = Color3.fromHex("#F2B705"),
			BorderSizePixel = 0,
		}),

		-- Speaker Name Plate (Top-Left)
		SpeakerPlate = e("Frame", {
			Size = UDim2.new(0, 200, 0, 28),
			Position = UDim2.new(0, 16, 0, -14),
			BackgroundColor3 = Color3.fromHex("#1B1814"),
			BorderSizePixel = 0,
		}, {
			PlateCorner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
			PlateStroke = e("UIStroke", {
				Color = Color3.fromHex("#F2B705"),
				Thickness = 1.5,
			}),
			SpeakerName = e("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = dialog.speakerName or "Mysterious Voice",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 16,
				TextColor3 = Color3.fromHex("#FFF4A3"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),

		-- Dialogue Text Area
		DialogueText = e("TextLabel", {
			Size = UDim2.new(1, -40, 0, 80),
			Position = UDim2.new(0, 20, 0, 24),
			BackgroundTransparency = 1,
			Text = dialog.text or "...",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 17,
			TextColor3 = Color3.fromHex("#FFFFFF"),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			LineHeight = 1.25,
		}),

		-- Action Buttons Area
		ActionsContainer = e("Frame", {
			Size = UDim2.new(1, -40, 0, 32),
			Position = UDim2.new(0, 20, 1, -12),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundTransparency = 1,
		}, (dialog.options and #dialog.options > 0) and (function()
			local btns: { [string]: any } = {
				Layout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				})
			}
			for idx, opt in ipairs(dialog.options) do
				btns["Option_" .. idx] = e("TextButton", {
					Size = UDim2.new(0, 110, 1, 0),
					BackgroundColor3 = Color3.fromHex("#2A2723"),
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					Text = opt.label or ("Option " .. idx),
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 14,
					TextColor3 = Color3.fromHex("#F2B705"),
					LayoutOrder = idx,
					[React.Event.Activated] = function()
						if opt.onClick then opt.onClick() end
					end,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
					Stroke = e("UIStroke", { Color = Color3.fromHex("#F2B705"), Thickness = 1 }),
				})
			end
			return btns
		end)() or {
			-- Continue Button Mode
			ContinueBtn = (mode == "continue") and e("TextButton", {
				Size = UDim2.new(0, 110, 1, 0),
				Position = UDim2.new(1, 0, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromHex("#393939"),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Text = "CONTINUE »",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#F2B705"),
				[React.Event.Activated] = function()
					if dialog.onContinue then dialog.onContinue() end
				end,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Stroke = e("UIStroke", { Color = Color3.fromHex("#F2B705"), Thickness = 1 }),
			}) or nil,

			-- Choice Mode: Accept and Refuse
			ChoiceButtons = (mode == "choice") and e("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}, {
				AcceptBtn = e("TextButton", {
					Size = UDim2.new(0, 100, 1, 0),
					Position = UDim2.new(1, -110, 0, 0),
					BackgroundColor3 = Color3.fromHex("#1F3D1F"),
					BorderSizePixel = 0,
					Text = "ACCEPT",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 15,
					TextColor3 = Color3.fromHex("#A4FFA4"),
					[React.Event.Activated] = function()
						if dialog.onAccept then dialog.onAccept() end
					end,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
					Stroke = e("UIStroke", { Color = Color3.fromHex("#4CAF50"), Thickness = 1 }),
				}),
				RefuseBtn = e("TextButton", {
					Size = UDim2.new(0, 100, 1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					BackgroundColor3 = Color3.fromHex("#3D1F1F"),
					BorderSizePixel = 0,
					Text = "REFUSE",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 15,
					TextColor3 = Color3.fromHex("#FFA4A4"),
					[React.Event.Activated] = function()
						if dialog.onRefuse then dialog.onRefuse() end
					end,
				}, {
					Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
					Stroke = e("UIStroke", { Color = Color3.fromHex("#F44336"), Thickness = 1 }),
				}),
			}) or nil,
		}),
	})
end

return Dialog
