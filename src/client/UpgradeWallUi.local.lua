local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(shared:WaitForChild("UpgradeConfig"))
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))
local network = require(shared:WaitForChild("ZapClient"))
local upgradeWall = Workspace:WaitForChild(UpgradeConfig.WALL_MODEL_NAME)
local headerPart = upgradeWall:WaitForChild(UpgradeConfig.WALL_HEADER_PART_NAME)

local function createTextLabel(position, size, font, text, textColor3, textSize, alignment, wrapped)
	return React.createElement("TextLabel", {
		BackgroundTransparency = 1,
		Position = position,
		Size = size,
		Font = font,
		Text = text,
		TextColor3 = textColor3,
		TextSize = textSize,
		TextWrapped = wrapped or false,
		TextXAlignment = alignment or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
	})
end

local function createSurfaceGui(adornee, children)
	return React.createElement("SurfaceGui", {
		Adornee = adornee,
		AlwaysOnTop = false,
		ClipsDescendants = true,
		Face = Enum.NormalId.Front,
		LightInfluence = 0,
		PixelsPerStud = 42,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		ZOffset = 0,
	}, children)
end

local function UpgradeCard(props)
	local definition = UpgradeConfig.getDefinition(props.upgradeId)
	local nextCost = UpgradeConfig.getCost(props.upgradeId, props.level)
	local _, nextValue = UpgradeConfig.getCurrentAndNextValue(props.upgradeId, props.level)
	local isMaxed = nextCost == nil
	local canAfford = nextCost ~= nil and props.currentFootyens >= nextCost

	local buttonBackgroundColor = Color3.fromRGB(60, 69, 86)
	if isMaxed then
		buttonBackgroundColor = Color3.fromRGB(72, 79, 94)
	elseif canAfford then
		buttonBackgroundColor = Color3.fromRGB(62, 183, 124)
	else
		buttonBackgroundColor = Color3.fromRGB(178, 78, 78)
	end

	local buttonText = "MAXED"
	if props.isPurchasing then
		buttonText = "PROCESSING..."
	elseif nextCost ~= nil then
		buttonText = string.format("BUY FOR %d F", nextCost)
	end

	local balanceText = "Fully upgraded"
	if nextCost ~= nil then
		balanceText = string.format("Balance: %d Footyens", props.currentFootyens)
	end

	return createSurfaceGui(props.part, {
		Card = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(14, 21, 34),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 18),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(86, 181, 255),
				Transparency = 0.28,
				Thickness = 2,
			}),
			Title = createTextLabel(
				UDim2.fromOffset(22, 20),
				UDim2.fromOffset(290, 32),
				Enum.Font.GothamBold,
				definition.displayName,
				Color3.fromRGB(243, 247, 255),
				24,
				Enum.TextXAlignment.Left,
				false
			),
			LevelBadge = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(33, 45, 67),
				BackgroundTransparency = 0.08,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(360, 20),
				Size = UDim2.fromOffset(82, 32),
				Font = Enum.Font.GothamBold,
				Text = string.format("Lv %d", props.level),
				TextColor3 = Color3.fromRGB(141, 214, 255),
				TextSize = 18,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
			Description = createTextLabel(
				UDim2.fromOffset(22, 62),
				UDim2.fromOffset(420, 54),
				Enum.Font.Gotham,
				definition.description,
				Color3.fromRGB(179, 193, 221),
				15,
				Enum.TextXAlignment.Left,
				true
			),
			Divider = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(51, 64, 86),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(22, 124),
				Size = UDim2.fromOffset(420, 2),
			}),
			Current = createTextLabel(
				UDim2.fromOffset(22, 138),
				UDim2.fromOffset(420, 24),
				Enum.Font.GothamMedium,
				string.format("Current: %s", UpgradeConfig.formatValue(props.upgradeId, props.currentValue)),
				Color3.fromRGB(242, 245, 255),
				18,
				Enum.TextXAlignment.Left,
				false
			),
			Next = createTextLabel(
				UDim2.fromOffset(22, 166),
				UDim2.fromOffset(420, 24),
				Enum.Font.Gotham,
				nextValue and string.format("Next: %s", UpgradeConfig.formatValue(props.upgradeId, nextValue)) or "Next: MAX LEVEL",
				Color3.fromRGB(144, 229, 184),
				18,
				Enum.TextXAlignment.Left,
				false
			),
			Balance = createTextLabel(
				UDim2.fromOffset(22, 194),
				UDim2.fromOffset(420, 22),
				Enum.Font.Gotham,
				balanceText,
				Color3.fromRGB(194, 204, 225),
				14,
				Enum.TextXAlignment.Left,
				false
			),
			Button = React.createElement("TextButton", {
				Active = not isMaxed and not props.isPurchasing,
				AutoButtonColor = false,
				BackgroundColor3 = buttonBackgroundColor,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(22, 232),
				Size = UDim2.fromOffset(420, 58),
				Font = Enum.Font.GothamBold,
				Text = buttonText,
				TextColor3 = Color3.fromRGB(248, 251, 255),
				TextSize = 22,
				[React.Event.MouseButton1Click] = function()
					if not isMaxed and not props.isPurchasing then
						props.onPurchase(props.upgradeId)
					end
				end,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 14),
				}),
			}),
		}),
	})
end

local existingGui = playerGui:FindFirstChild("UpgradeWallUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "UpgradeWallUi"
hostGui.IgnoreGuiInset = true
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local function usePlayerState()
	local state, setState = React.useState(playerStateStore.getState())

	React.useEffect(function()
		return playerStateStore.subscribe(setState)
	end, {})

	return state
end

local function UpgradeWallUi()
	local playerState = usePlayerState()
	local isPurchasing, setIsPurchasing = React.useState(false)
	local statusMessage, setStatusMessage = React.useState("Click any panel to spend Footyens on stronger runs.")

	local function purchaseUpgrade(upgradeId)
		if isPurchasing then
			return
		end

		setIsPurchasing(true)

		local ok, result = pcall(function()
			return network.PurchaseUpgrade.Call(upgradeId)
		end)

		setIsPurchasing(false)

		if not ok then
			setStatusMessage("The upgrade request failed to reach the server.")
			return
		end

		if type(result) == "table" and type(result.message) == "string" then
			setStatusMessage(result.message)
			return
		end

		setStatusMessage("Upgrade response received.")
	end

	local children = {
		Header = createSurfaceGui(headerPart, {
			Frame = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(12, 18, 28),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 18),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(86, 181, 255),
					Transparency = 0.18,
					Thickness = 2,
				}),
				Title = createTextLabel(
					UDim2.fromOffset(24, 20),
					UDim2.fromOffset(720, 30),
					Enum.Font.GothamBold,
					"FOOTYEN UPGRADE WALL",
					Color3.fromRGB(244, 248, 255),
					26,
					Enum.TextXAlignment.Left,
					false
				),
				Status = createTextLabel(
					UDim2.fromOffset(24, 56),
					UDim2.fromOffset(720, 24),
					Enum.Font.Gotham,
					statusMessage,
					Color3.fromRGB(194, 207, 230),
					15,
					Enum.TextXAlignment.Left,
					false
				),
				Balance = React.createElement("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(33, 45, 67),
					BackgroundTransparency = 0.06,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(734, 22),
					Size = UDim2.fromOffset(210, 40),
					Font = Enum.Font.GothamBold,
					Text = string.format("%d Footyens", playerState.footyens),
					TextColor3 = Color3.fromRGB(255, 224, 124),
					TextSize = 22,
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}),
			}),
		}),
	}

	for _, upgradeId in ipairs(UpgradeConfig.getOrderedUpgradeIds()) do
		local currentLevel
		local currentValue

		if upgradeId == "MovementSpeed" then
			currentLevel = playerState.movementSpeedLevel
			currentValue = playerState.movementSpeed
		elseif upgradeId == "StudsPerCurrency" then
			currentLevel = playerState.studsPerCurrencyLevel
			currentValue = playerState.studsPerCurrency
		else
			currentLevel = playerState.currencyMultiplierLevel
			currentValue = playerState.currencyMultiplier
		end

		children[upgradeId] = React.createElement(UpgradeCard, {
			currentFootyens = playerState.footyens,
			currentValue = currentValue,
			isPurchasing = isPurchasing,
			level = currentLevel,
			onPurchase = purchaseUpgrade,
			part = upgradeWall:WaitForChild(UpgradeConfig.getPanelPartName(upgradeId)),
			upgradeId = upgradeId,
		})
	end

	return React.createElement(React.Fragment, nil, children)
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(UpgradeWallUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
