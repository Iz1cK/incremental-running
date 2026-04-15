local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local leaderstats = localPlayer:WaitForChild("leaderstats")
local runStats = localPlayer:WaitForChild("RunStats")
local shared = ReplicatedStorage:WaitForChild("Shared")
local runRewardsConfig = require(shared:WaitForChild("RunRewardsConfig"))

local footyens = leaderstats:WaitForChild("Footyens")
local totalDistance = runStats:WaitForChild("TotalDistanceStuds")
local hostGui = Instance.new("ScreenGui")
hostGui.Name = "FootyenHud"
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local function useValueState(valueObject)
	local value, setValue = React.useState(valueObject.Value)

	React.useEffect(function()
		local connection = valueObject:GetPropertyChangedSignal("Value"):Connect(function()
			setValue(valueObject.Value)
		end)

		setValue(valueObject.Value)

		return function()
			connection:Disconnect()
		end
	end, {valueObject})

	return value
end

local function FootyenLabel(props)
	return React.createElement("TextLabel", {
		BackgroundTransparency = 1,
		Position = props.Position,
		Size = props.Size,
		Font = props.Font,
		Text = props.Text,
		TextColor3 = props.TextColor3,
		TextSize = props.TextSize,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function FootyenHud()
	local currentFootyens = useValueState(footyens)
	local currentDistance = useValueState(totalDistance)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(20, 20),
		Size = UDim2.fromOffset(240, 104),
		BackgroundColor3 = Color3.fromRGB(24, 24, 32),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(88, 187, 255),
			Transparency = 0.25,
		}),
		Title = React.createElement(FootyenLabel, {
			Name = "Title",
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.fromOffset(212, 24),
			Font = Enum.Font.GothamBold,
			Text = "Run To Earn Footyens",
			TextColor3 = Color3.fromRGB(240, 245, 255),
			TextSize = 18,
		}),
		Footyens = React.createElement(FootyenLabel, {
			Name = "Footyens",
			Position = UDim2.fromOffset(14, 40),
			Size = UDim2.fromOffset(212, 22),
			Font = Enum.Font.GothamMedium,
			Text = string.format("Footyens: %d", currentFootyens),
			TextColor3 = Color3.fromRGB(255, 215, 95),
			TextSize = 20,
		}),
		Distance = React.createElement(FootyenLabel, {
			Name = "Distance",
			Position = UDim2.fromOffset(14, 66),
			Size = UDim2.fromOffset(212, 18),
			Font = Enum.Font.Gotham,
			Text = string.format("Distance Run: %.1f studs", currentDistance),
			TextColor3 = Color3.fromRGB(206, 219, 255),
			TextSize = 15,
		}),
		Rate = React.createElement(FootyenLabel, {
			Name = "Rate",
			Position = UDim2.fromOffset(14, 84),
			Size = UDim2.fromOffset(212, 14),
			Font = Enum.Font.Gotham,
			Text = string.format("%d studs = 1 Footyen", runRewardsConfig.STUDS_PER_FOOTYEN),
			TextColor3 = Color3.fromRGB(148, 166, 204),
			TextSize = 12,
		}),
	})
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(FootyenHud))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
