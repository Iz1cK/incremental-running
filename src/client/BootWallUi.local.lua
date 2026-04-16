local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local BootConfig = require(shared:WaitForChild("BootConfig"))
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))
local network = require(shared:WaitForChild("ZapClient"))
local bootWall = Workspace:WaitForChild(BootConfig.WALL_MODEL_NAME)
local headerPart = bootWall:WaitForChild(BootConfig.WALL_HEADER_PART_NAME)

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
		PixelsPerStud = 34,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		ZOffset = 0,
	}, children)
end

local function usePlayerState()
	local state, setState = React.useState(playerStateStore.getState())

	React.useEffect(function()
		return playerStateStore.subscribe(setState)
	end, {})

	return state
end

local function BootUpgradeCard(props)
	local definition = BootConfig.getDefinition(props.upgradeId)
	local nextCost = BootConfig.getCost(props.upgradeId, props.level)
	local _, nextValue = BootConfig.getCurrentAndNextValue(props.upgradeId, props.level)
	local isMaxed = nextCost == nil
	local canAfford = nextCost ~= nil and props.currentFootyens >= nextCost

	local buttonBackgroundColor = Color3.fromRGB(84, 60, 49)
	if isMaxed then
		buttonBackgroundColor = Color3.fromRGB(94, 76, 62)
	elseif canAfford then
		buttonBackgroundColor = Color3.fromRGB(214, 128, 72)
	else
		buttonBackgroundColor = Color3.fromRGB(142, 74, 74)
	end

	local buttonText = "MAXED"
	if props.isPurchasing then
		buttonText = "PROCESSING..."
	elseif nextCost ~= nil then
		buttonText = string.format("BUY FOR %d F", nextCost)
	end

	return createSurfaceGui(props.part, {
		Card = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(34, 24, 20),
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 18),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 190, 102),
				Transparency = 0.24,
				Thickness = 2,
			}),
			Title = createTextLabel(
				UDim2.fromOffset(16, 14),
				UDim2.fromOffset(200, 24),
				Enum.Font.GothamBold,
				definition.displayName,
				Color3.fromRGB(255, 245, 228),
				18,
				Enum.TextXAlignment.Left,
				false
			),
			Level = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(84, 56, 40),
				BackgroundTransparency = 0.06,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(264, 14),
				Size = UDim2.fromOffset(62, 24),
				Font = Enum.Font.GothamBold,
				Text = string.format("Lv %d", props.level),
				TextColor3 = Color3.fromRGB(255, 222, 166),
				TextSize = 14,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
			Description = createTextLabel(
				UDim2.fromOffset(16, 44),
				UDim2.fromOffset(312, 34),
				Enum.Font.Gotham,
				definition.description,
				Color3.fromRGB(224, 201, 182),
				11,
				Enum.TextXAlignment.Left,
				true
			),
			Divider = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(87, 67, 55),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(16, 84),
				Size = UDim2.fromOffset(312, 2),
			}),
			Current = createTextLabel(
				UDim2.fromOffset(16, 94),
				UDim2.fromOffset(312, 18),
				Enum.Font.GothamMedium,
				string.format("Current: %s", BootConfig.formatValue(props.upgradeId, props.currentValue)),
				Color3.fromRGB(255, 247, 238),
				13,
				Enum.TextXAlignment.Left,
				false
			),
			Next = createTextLabel(
				UDim2.fromOffset(16, 116),
				UDim2.fromOffset(312, 18),
				Enum.Font.Gotham,
				nextValue and string.format("Next: %s", BootConfig.formatValue(props.upgradeId, nextValue)) or "Next: MAX LEVEL",
				Color3.fromRGB(255, 208, 132),
				13,
				Enum.TextXAlignment.Left,
				false
			),
			Footnote = createTextLabel(
				UDim2.fromOffset(16, 138),
				UDim2.fromOffset(312, 16),
				Enum.Font.Gotham,
				string.format("Boots collected: %d", props.bootsCollected),
				Color3.fromRGB(201, 184, 167),
				11,
				Enum.TextXAlignment.Left,
				false
			),
			Button = React.createElement("TextButton", {
				Active = not isMaxed and not props.isPurchasing,
				AutoButtonColor = false,
				BackgroundColor3 = buttonBackgroundColor,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(16, 162),
				Size = UDim2.fromOffset(312, 38),
				Font = Enum.Font.GothamBold,
				Text = buttonText,
				TextColor3 = Color3.fromRGB(255, 248, 240),
				TextSize = 16,
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

local existingGui = playerGui:FindFirstChild("BootWallUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "BootWallUi"
hostGui.IgnoreGuiInset = true
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local function BootWallUi()
	local playerState = usePlayerState()
	local isPurchasing, setIsPurchasing = React.useState(false)
	local statusMessage, setStatusMessage = React.useState("Build your personal boot field: more spawns, richer boots, sharper golden luck.")

	local function purchaseUpgrade(upgradeId)
		if isPurchasing then
			return
		end

		setIsPurchasing(true)

		local ok, result = pcall(function()
			return network.PurchaseBootUpgrade.Call(upgradeId)
		end)

		setIsPurchasing(false)

		if not ok then
			setStatusMessage("The boot upgrade request failed to reach the server.")
			return
		end

		if type(result) == "table" and type(result.message) == "string" then
			setStatusMessage(result.message)
			return
		end

		setStatusMessage("Boot upgrade response received.")
	end

	local children = {
		Header = createSurfaceGui(headerPart, {
			Frame = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(30, 22, 18),
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 18),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 190, 102),
					Transparency = 0.18,
					Thickness = 2,
				}),
				Title = createTextLabel(
					UDim2.fromOffset(24, 16),
					UDim2.fromOffset(540, 30),
					Enum.Font.GothamBold,
					"BOOT FIELD CONTROL WALL",
					Color3.fromRGB(255, 246, 232),
					25,
					Enum.TextXAlignment.Left,
					false
				),
				Status = createTextLabel(
					UDim2.fromOffset(24, 48),
					UDim2.fromOffset(540, 24),
					Enum.Font.Gotham,
					statusMessage,
					Color3.fromRGB(223, 205, 188),
					14,
					Enum.TextXAlignment.Left,
					false
				),
				Balance = React.createElement("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(89, 58, 40),
					BackgroundTransparency = 0.05,
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(584, 18),
					Size = UDim2.fromOffset(208, 36),
					Font = Enum.Font.GothamBold,
					Text = string.format("%d Footyens", playerState.footyens),
					TextColor3 = Color3.fromRGB(255, 221, 153),
					TextSize = 20,
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}),
				Boots = createTextLabel(
					UDim2.fromOffset(584, 60),
					UDim2.fromOffset(250, 20),
					Enum.Font.Gotham,
					string.format("Collected %d boots | %d active", playerState.bootsCollected, playerState.activeBoots),
					Color3.fromRGB(239, 219, 200),
					14,
					Enum.TextXAlignment.Left,
					false
				),
			}),
		}),
	}

	for _, upgradeId in ipairs(BootConfig.getOrderedUpgradeIds()) do
		local levelField = string.format("%sLevel", string.sub(upgradeId, 1, 1):lower() .. string.sub(upgradeId, 2))
		local valueField

		if upgradeId == "BootValue" then
			valueField = "bootValue"
		elseif upgradeId == "SpawnRate" then
			valueField = "bootSpawnInterval"
		elseif upgradeId == "MaxActiveBoots" then
			valueField = "bootMaxActive"
		elseif upgradeId == "PickupRadius" then
			valueField = "bootPickupRadius"
		elseif upgradeId == "BootLifetime" then
			valueField = "bootLifetime"
		elseif upgradeId == "GoldenChance" then
			valueField = "bootGoldenChance"
		else
			valueField = "bootGoldenMultiplier"
		end

		children[upgradeId] = React.createElement(BootUpgradeCard, {
			bootsCollected = playerState.bootsCollected,
			currentFootyens = playerState.footyens,
			currentValue = playerState[valueField],
			isPurchasing = isPurchasing,
			level = playerState[levelField],
			onPurchase = purchaseUpgrade,
			part = bootWall:WaitForChild(BootConfig.getPanelPartName(upgradeId)),
			upgradeId = upgradeId,
		})
	end

	return React.createElement(React.Fragment, nil, children)
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(BootWallUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
