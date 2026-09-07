--[[
	GuideWindow — Lore and gameplay tutorial manual.

	Features:
	  - 10 pages driven by GuidePages data.
	  - Next/Back pagination controls.
	  - Page indicator.
	  - CloseButton to dismiss.

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local GuidePages = require(script.Parent.Parent.Parent.Parent.Data.GuidePages)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local e = React.createElement

export type GuideWindowProps = {
	onClose: (() -> ())?,
}

local function GuideWindow(props: GuideWindowProps)
	local pageIndex, setPageIndex = React.useState(1)
	local totalPages = #GuidePages
	local currentPage = GuidePages[pageIndex]

	local handlePrev = function()
		if pageIndex > 1 then
			setPageIndex(pageIndex - 1)
		end
	end

	local handleNext = function()
		if pageIndex < totalPages then
			setPageIndex(pageIndex + 1)
		end
	end

	return e("Frame", {
		Size = UDim2.new(0, 580, 0, 420),
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
			title = "Chronicles & Guide",
			subtitle = currentPage.title,
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 8),
		}),

		-- Page Content Container
		ContentScroll = e("ScrollingFrame", {
			Size = UDim2.new(1, -40, 1, -130),
			Position = UDim2.new(0.5, 0, 0, 68),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
		}, {
			Text = e("TextLabel", {
				Size = UDim2.new(1, -10, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Text = currentPage.content,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 16,
				TextColor3 = Color3.fromHex("#E5E5E5"),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LineHeight = 1.25,
			}),
		}),

		-- Pagination footer
		Footer = e("Frame", {
			Size = UDim2.new(1, -40, 0, 36),
			Position = UDim2.new(0.5, 0, 1, -12),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			PrevButton = e("TextButton", {
				Size = UDim2.new(0, 80, 0, 30),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromHex("#393939"),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Text = "Back",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = (pageIndex > 1) and Color3.fromHex("#F2B705") or Color3.fromHex("#666666"),
				AutoButtonColor = (pageIndex > 1),
				[React.Event.Activated] = handlePrev,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Stroke = e("UIStroke", {
					Color = (pageIndex > 1) and Color3.fromHex("#F2B705") or Color3.fromHex("#555555"),
					Thickness = 1,
				}),
			}),
			PageCount = e("TextLabel", {
				Size = UDim2.new(0, 120, 1, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Text = string.format("Page %d of %d", pageIndex, totalPages),
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = Color3.fromHex("#F2B705"),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			NextButton = e("TextButton", {
				Size = UDim2.new(0, 80, 0, 30),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromHex("#393939"),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				Text = "Next",
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 15,
				TextColor3 = (pageIndex < totalPages) and Color3.fromHex("#F2B705") or Color3.fromHex("#666666"),
				AutoButtonColor = (pageIndex < totalPages),
				[React.Event.Activated] = handleNext,
			}, {
				Corner = e("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Stroke = e("UIStroke", {
					Color = (pageIndex < totalPages) and Color3.fromHex("#F2B705") or Color3.fromHex("#555555"),
					Thickness = 1,
				}),
			}),
		}),
	})
end

return GuideWindow
