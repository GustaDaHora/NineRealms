--[[
	VitalsRow — Health Bar, Souls Bar, and FaceFrame container.

	Props:
		health: number
		maxHealth: number
		souls: number
		maxSouls: number
		faceImage: string?
		size: UDim2?
		position: UDim2?

	Used by:
		- HUD
]]

local Players = game:GetService("Players")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local VitalBar = require(script.Parent.Parent.Shared.VitalBar)
local e = React.createElement

export type VitalsRowProps = {
	health: number,
	maxHealth: number,
	souls: number,
	maxSouls: number,
	faceImage: string?,
	size: UDim2?,
	position: UDim2?,
}

local function VitalsRow(props: VitalsRowProps)
	local playerThumbnail, setPlayerThumbnail = React.useState(props.faceImage or "")

	React.useEffect(function()
		if props.faceImage and props.faceImage ~= "" then
			setPlayerThumbnail(props.faceImage)
			return
		end

		local player = Players.LocalPlayer
		if player and player.UserId > 0 then
			task.spawn(function()
				pcall(function()
					local thumb, isReady = Players:GetUserThumbnailAsync(
						player.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
					if isReady and thumb then
						setPlayerThumbnail(thumb)
					end
				end)
			end)
		end
	end, { props.faceImage } :: { any })

	return e("Frame", {
		Size = props.size or UDim2.new(0, 300, 0, 100),
		Position = props.position or UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		-- FaceFrame container
		FaceFrame = e("Frame", {
			Size = UDim2.new(0, 64, 0, 64),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromHex("#1B1814"),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
		}, {
			Corner = e("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Stroke = e("UIStroke", {
				Color = Color3.fromHex("#F2B705"),
				Thickness = 3,
			}, {
				Gradient = e("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHex("#F2B705")),
						ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")),
						ColorSequenceKeypoint.new(1, Color3.fromHex("#F2B705")),
					}),
					Rotation = 45,
				}),
			}),
			Portrait = playerThumbnail ~= "" and e("ImageLabel", {
				Size = UDim2.new(0.9, 0, 0.9, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = playerThumbnail,
				ScaleType = Enum.ScaleType.Fit,
			}) or nil,
		}),

		-- Bars stack
		BarsContainer = e("Frame", {
			Size = UDim2.new(0, 210, 0, 56),
			Position = UDim2.new(0, 76, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			HealthBar = e(VitalBar, {
				value = props.health or 100,
				max = props.maxHealth or 100,
				barColor = Color3.fromHex("#B60000"),
				strokeColor = Color3.fromHex("#F2B705"),
				textColor = Color3.fromHex("#FFFFFF"),
				strokeTextColor = Color3.fromHex("#000000"),
				size = UDim2.new(1, 0, 0, 20),
				layoutOrder = 1,
			}),
			SoulsBar = e(VitalBar, {
				value = props.souls or 0,
				max = props.maxSouls or 100,
				barColor = Color3.fromHex("#3A78C4"),
				strokeColor = Color3.fromHex("#569CD6"),
				textColor = Color3.fromHex("#FFFFFF"),
				strokeTextColor = Color3.fromHex("#000000"),
				size = UDim2.new(0.85, 0, 0, 16),
				layoutOrder = 2,
			}),
		}),
	})
end

return VitalsRow
