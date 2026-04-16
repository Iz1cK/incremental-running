local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local UiAssetConfig = require(shared:WaitForChild("UiAssetConfig"))
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))

local existingGui = playerGui:FindFirstChild("FootyenHud")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "FootyenHud"
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local function usePlayerState()
	local state, setState = React.useState(playerStateStore.getState())

	React.useEffect(function()
		return playerStateStore.subscribe(setState)
	end, {})

	return state
end

local function formatCurrency(value)
	local digits = tostring(math.max(0, math.floor(value)))

	return string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,"))):gsub("^,", "")
end

local function CurrencyBubble(props)
	return React.createElement("Frame", {
		BackgroundColor3 = props.backgroundColor,
		BorderSizePixel = 0,
		Position = props.position,
		Size = UDim2.fromOffset(220, 70),
		LayoutOrder = props.layoutOrder,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = props.strokeColor,
			Thickness = 3,
			Transparency = 0.1,
		}),
		Gradient = React.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, props.gradientLeft),
				ColorSequenceKeypoint.new(1, props.gradientRight),
			}),
			Rotation = 180,
		}),
		Shadow = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(11, 16, 24),
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(6, 48),
			Size = UDim2.fromOffset(268, 16),
			ZIndex = 0,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Orb = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, -6, 0.5, 0),
			Size = UDim2.fromOffset(78, 78),
			Image = props.image,
			ScaleType = Enum.ScaleType.Fit,
		}),
		Label = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(74, 10),
			Size = UDim2.fromOffset(180, 16),
			Font = Enum.Font.GothamMedium,
			Text = props.label,
			TextColor3 = props.labelColor,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}),
		Value = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(74, 18),
			Size = UDim2.fromOffset(190, 34),
			Font = Enum.Font.GothamBlack,
			Text = formatCurrency(props.value),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 27,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
	})
end

local function FootyenHud()
	local playerState = usePlayerState()

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 16),
		Size = UDim2.fromOffset(292, 152),
	}, {
		Layout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Footyens = React.createElement(CurrencyBubble, {
			layoutOrder = 1,
			backgroundColor = Color3.fromRGB(35, 159, 18),
			gradientLeft = Color3.fromRGB(57, 206, 26),
			gradientRight = Color3.fromRGB(28, 131, 15),
			label = "Footyens",
			labelColor = Color3.fromRGB(216, 255, 205),
			orbInnerColor = Color3.fromRGB(188, 255, 89),
			orbOuterColor = Color3.fromRGB(88, 196, 29),
			position = UDim2.fromOffset(0, 0),
			strokeColor = Color3.fromRGB(23, 90, 17),
			image = UiAssetConfig.FOOTYEN_ICON_URI,
			value = playerState.footyens,
		}),
		Footgems = React.createElement(CurrencyBubble, {
			layoutOrder = 2,
			backgroundColor = Color3.fromRGB(21, 120, 164),
			gradientLeft = Color3.fromRGB(40, 188, 255),
			gradientRight = Color3.fromRGB(22, 92, 145),
			label = "Footgems",
			labelColor = Color3.fromRGB(208, 247, 255),
			orbInnerColor = Color3.fromRGB(147, 244, 255),
			orbOuterColor = Color3.fromRGB(43, 167, 226),
			position = UDim2.fromOffset(0, 0),
			strokeColor = Color3.fromRGB(20, 67, 111),
			image = UiAssetConfig.FOOTGEM_ICON_URI,
			value = playerState.footgems,
		}),
	})
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(FootyenHud))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
