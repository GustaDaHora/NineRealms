--[[
	DeathMessage — Full-screen death screen sequence with respawn handler.

	Phase states:
	  - "inactive": Hidden / unmounted.
	  - "playing": Reveal animation active.
	  - "complete": Reveal complete; respawn click target interactive.

	Props:
		phase: ("inactive" | "playing" | "complete")?
		onRespawn: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type DeathMessageProps = {
	phase: ("inactive" | "playing" | "complete")?,
	onRespawn: (() -> ())?,
}

local function DeathMessage(props: DeathMessageProps)
	local phase = props.phase or "inactive"
	if phase == "inactive" then
		return nil
	end

	local isComplete = (phase == "complete")

	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#100000"),
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 25,
	}, {
		-- Vignette overlay
		Vignette = e("ImageLabel", {
			Size = UDim2.fromScale(1.1, 1.1),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxassetid://14636078735",
			ImageColor3 = Color3.fromHex("#1A0000"),
			ImageTransparency = 0.4,
			ScaleType = Enum.ScaleType.Crop,
			ZIndex = 26,
		}),

		-- Outer decorative skull
		Skull1 = e("ImageLabel", {
			Size = UDim2.new(0, 180, 0, 180),
			Position = UDim2.fromScale(0.5, 0.42),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxassetid://14635346640",
			ImageColor3 = Color3.fromHex("#531414"),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 27,
		}),

		-- Inner skull accent
		Skull2 = e("ImageLabel", {
			Size = UDim2.new(0, 90, 0, 90),
			Position = UDim2.fromScale(0.5, 0.42),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = "rbxassetid://14635380271",
			ImageColor3 = Color3.fromHex("#270000"),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 28,
		}),

		-- "YOU DIED" Title
		Title = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 50),
			Position = UDim2.fromScale(0.5, 0.56),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = "YOU DIED",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 42,
			TextColor3 = Color3.fromHex("#B60000"),
			TextStrokeColor3 = Color3.fromHex("#000000"),
			TextStrokeTransparency = 0.1,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 29,
		}),

		-- Subtext: "Restart your heartbeat."
		Subtitle = e("TextLabel", {
			Size = UDim2.new(1, 0, 0, 30),
			Position = UDim2.fromScale(0.5, 0.63),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = isComplete and "Click anywhere to restart your heartbeat." or "Restart your heartbeat...",
			Font = Enum.Font.GrenzeGotisch,
			TextSize = 18,
			TextColor3 = isComplete and Color3.fromHex("#FFF4A3") or Color3.fromHex("#790D0D"),
			TextStrokeColor3 = Color3.fromHex("#000000"),
			TextStrokeTransparency = 0.3,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 29,
		}),

		-- Full-screen click-to-respawn hit target
		RespawnTarget = isComplete and e("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 30,
			[React.Event.Activated] = function()
				if props.onRespawn then
					props.onRespawn()
				end
			end,
		}) or nil,
	})
end

return DeathMessage
