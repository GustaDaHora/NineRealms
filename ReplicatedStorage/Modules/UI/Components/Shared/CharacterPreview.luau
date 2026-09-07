--[[
	CharacterPreview — 3D Viewport character preview and name plate.

	Props:
		character: Model? (defaults to LocalPlayer's character)
		playerName: string?
		size: UDim2?
		position: UDim2?
		anchorPoint: Vector2?
		showName: boolean?

	Used by:
		- Inventory (EquipView)
		- Character window
]]

local Players = game:GetService("Players")
local React = require(game:GetService("ReplicatedStorage").Packages.React)
local e = React.createElement

export type CharacterPreviewProps = {
	character: Model?,
	playerName: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	showName: boolean?,
}

local function CharacterPreview(props: CharacterPreviewProps)
	local viewportRef = React.useRef(nil :: ViewportFrame?)
	local worldModelRef = React.useRef(nil :: WorldModel?)
	local cameraRef = React.useRef(nil :: Camera?)
	local observedCharacter, setObservedCharacter = React.useState(Players.LocalPlayer and Players.LocalPlayer.Character or nil)

	local playerName = props.playerName or (Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player")

	React.useEffect(function()
		local player = Players.LocalPlayer
		if not player then return end
		local connection = player.CharacterAdded:Connect(function(character)
			setObservedCharacter(character)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return
		end

		-- Setup camera
		local camera = Instance.new("Camera")
		camera.FieldOfView = 30
		camera.Parent = viewport
		viewport.CurrentCamera = camera
		cameraRef.current = camera

		-- Setup WorldModel
		local worldModel = Instance.new("WorldModel")
		worldModel.Parent = viewport
		worldModelRef.current = worldModel

		-- Clone character model
		local sourceChar = props.character or observedCharacter
		local charClone: Model? = nil

		if sourceChar then
			local wasArchivable = sourceChar.Archivable
			sourceChar.Archivable = true
			local success, result = pcall(function()
				return sourceChar:Clone()
			end)
			sourceChar.Archivable = wasArchivable
			if success then
				charClone = result
			end

			if charClone then
				-- Remove scripts, physics constraints, sounds from preview
				for _, desc in charClone:GetDescendants() do
					if desc:IsA("LuaSourceContainer") or desc:IsA("Sound") then
						desc:Destroy()
					elseif desc:IsA("BasePart") then
						desc.Anchored = true
						desc.CanCollide = false
					end
				end

				charClone.Parent = worldModel

				local rootPart = charClone:FindFirstChild("HumanoidRootPart") or charClone:FindFirstChild("Torso") or charClone.PrimaryPart
				if rootPart and rootPart:IsA("BasePart") then
					local cf = rootPart.CFrame
					camera.CFrame = CFrame.lookAt(cf.Position + cf.LookVector * 7.5 + Vector3.new(0, 0.8, 0), cf.Position + Vector3.new(0, 0.4, 0))
				end
			end
		end

		return function()
			if charClone then
				charClone:Destroy()
			end
			if camera then
				camera:Destroy()
			end
			if worldModel then
				worldModel:Destroy()
			end
		end
	end, { props.character, observedCharacter } :: { any })

	return e("Frame", {
		Size = props.size or UDim2.new(0, 160, 0, 220),
		Position = props.position or UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromHex("#FFFFFF"),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
	}, {
		Stroke = e("UIStroke", {
			Color = Color3.fromHex("#F2B705"),
			Thickness = 2,
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
		Corner = e("UICorner", {
			CornerRadius = UDim.new(0, 4),
		}),
		Viewport = e("ViewportFrame", {
			ref = viewportRef,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Ambient = Color3.fromRGB(180, 180, 180),
			LightColor = Color3.fromRGB(255, 255, 255),
			LightDirection = Vector3.new(-1, -1, -1),
		}),
		NamePlate = (props.showName ~= false) and e("Frame", {
			Size = UDim2.new(1, -12, 0, 24),
			Position = UDim2.new(0.5, 0, 1, -6),
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromHex("#1B1814"),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
		}, {
			NameStroke = e("UIStroke", {
				Color = Color3.fromHex("#F2B705"),
				Thickness = 1,
			}),
			NameText = e("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = playerName,
				Font = Enum.Font.GrenzeGotisch,
				TextSize = 16,
				TextColor3 = Color3.fromHex("#F2B705"),
				TextScaled = false,
				TextWrapped = true,
			}),
		}) or nil,
	})
end

return CharacterPreview
