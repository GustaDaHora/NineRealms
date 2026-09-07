--[[
	EventsWindow — Master-detail view of active game world events.

	Props:
		onClose: (() -> ())?
]]

local React = require(game:GetService("ReplicatedStorage").Packages.React)
local TabButton = require(script.Parent.Parent.Parent.Shared.TabButton)
local WindowLabel = require(script.Parent.Parent.Parent.Shared.WindowLabel)
local CloseButton = require(script.Parent.Parent.Parent.Shared.CloseButton)
local EventDetailPanel = require(script.Parent.EventDetailPanel)
local useStore = require(script.Parent.Parent.Parent.Parent.Store.useStore)
local StoreContext = require(script.Parent.Parent.Parent.Parent.Store.StoreContext)
local e = React.createElement

export type EventItem = {
	id: string,
	name: string,
	description: string,
	image: string?,
}

export type EventsWindowProps = {
	onClose: (() -> ())?,
}

local function EventsWindow(props: EventsWindowProps)
	local store = React.useContext(StoreContext)

	local storeEvents = useStore(store, function(state)
		return state.events
	end)

	local eventsList = storeEvents or {}
	local selectedId, setSelectedId = React.useState(eventsList[1] and eventsList[1].id or "")

	local selectedEvent = nil
	for _, ev in ipairs(eventsList) do
		if ev.id == selectedId then
			selectedEvent = ev
			break
		end
	end
	if not selectedEvent then
		selectedEvent = eventsList[1]
	end

	local eventRows: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),
	}

	for i, ev in ipairs(eventsList) do
		eventRows["Event_" .. ev.id] = e(TabButton, {
			label = ev.name,
			isSelected = (ev.id == (selectedEvent and selectedEvent.id)),
			onClick = function()
				setSelectedId(ev.id)
			end,
			layoutOrder = i,
		})
	end

	return e("Frame", {
		Size = UDim2.new(0, 620, 0, 400),
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
			title = "Realm Events",
			subtitle = "Active Challenges & World Quests",
			size = UDim2.new(1, 0, 0, 50),
			position = UDim2.new(0, 0, 0, 8),
		}),

		-- Body Master-Detail Layout
		Body = e("Frame", {
			Size = UDim2.new(1, -36, 1, -80),
			Position = UDim2.new(0.5, 0, 0, 68),
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			EventsList = e("ScrollingFrame", {
				Size = UDim2.new(0.38, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.new(0, 0, 0, #eventsList * 40),
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Color3.fromHex("#F2B705"),
			}, next(eventsList) and eventRows or {
				Empty = e("TextLabel", {
					Size = UDim2.new(1, 0, 0, 42),
					BackgroundTransparency = 1,
					Text = "No active events",
					Font = Enum.Font.GrenzeGotisch,
					TextSize = 16,
					TextColor3 = Color3.fromHex("#888888"),
				}),
			}),

			Detail = e(EventDetailPanel, {
				name = selectedEvent and selectedEvent.name or "",
				description = selectedEvent and selectedEvent.description or "",
				image = selectedEvent and selectedEvent.image or nil,
				size = UDim2.new(0.6, 0, 1, 0),
				position = UDim2.new(0.4, 0, 0, 0),
			}),
		}),
	})
end

return EventsWindow
