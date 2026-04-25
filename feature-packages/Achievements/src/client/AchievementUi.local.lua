local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))
local network = require(shared:WaitForChild("ZapClient"))

local existingGui = playerGui:FindFirstChild("AchievementUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "AchievementUi"
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

local function formatWholeNumber(value)
	local rounded = math.max(0, math.floor(value + 0.5))
	local text = tostring(rounded)

	while true do
		local nextText, replacements = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
		text = nextText
		if replacements == 0 then
			break
		end
	end

	return text
end

local function formatProgressValue(achievement)
	return string.format("%s / %s", formatWholeNumber(achievement.progress), formatWholeNumber(achievement.target))
end

local function buildRewardText(achievement)
	local rewardParts = {}

	if achievement.rewardFootgems > 0 then
		table.insert(rewardParts, string.format("%s Footgems", formatWholeNumber(achievement.rewardFootgems)))
	end

	if achievement.rewardFootcores > 0 then
		table.insert(rewardParts, string.format("%s Footcores", formatWholeNumber(achievement.rewardFootcores)))
	end

	if #rewardParts == 0 then
		return "Reward tracked for a future update."
	end

	return table.concat(rewardParts, " + ")
end

local function getAchievementStatus(achievement)
	if achievement.isClaimed then
		return {
			label = "CLAIMED",
			cardColor = Color3.fromRGB(22, 38, 31),
			strokeColor = Color3.fromRGB(90, 199, 142),
			progressColor = Color3.fromRGB(90, 199, 142),
			chipColor = Color3.fromRGB(90, 199, 142),
			chipTextColor = Color3.fromRGB(15, 26, 21),
		}
	end

	if achievement.isComplete then
		return {
			label = "READY",
			cardColor = Color3.fromRGB(42, 35, 20),
			strokeColor = Color3.fromRGB(239, 198, 102),
			progressColor = Color3.fromRGB(239, 198, 102),
			chipColor = Color3.fromRGB(239, 198, 102),
			chipTextColor = Color3.fromRGB(29, 24, 12),
		}
	end

	return {
		label = "TRACKING",
		cardColor = Color3.fromRGB(19, 24, 38),
		strokeColor = Color3.fromRGB(86, 118, 189),
		progressColor = Color3.fromRGB(86, 118, 189),
		chipColor = Color3.fromRGB(58, 72, 112),
		chipTextColor = Color3.fromRGB(232, 239, 255),
	}
end

local function createLabel(props)
	return React.createElement("TextLabel", {
		BackgroundTransparency = 1,
		Position = props.position,
		Size = props.size,
		Font = props.font,
		Text = props.text,
		TextColor3 = props.textColor3,
		TextSize = props.textSize,
		TextWrapped = props.wrapped or false,
		TextXAlignment = props.alignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.verticalAlignment or Enum.TextYAlignment.Top,
	})
end

local function createActionButton(props)
	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = props.backgroundColor,
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
		Font = Enum.Font.GothamBold,
		Text = props.text,
		TextColor3 = props.textColor3 or Color3.fromRGB(245, 248, 255),
		TextSize = props.textSize or 13,
		[React.Event.MouseButton1Click] = props.onClick,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, props.cornerRadius or 12),
		}),
	})
end

local function AchievementCard(props)
	local achievement = props.achievement
	local status = getAchievementStatus(achievement)
	local fillRatio = 0

	if achievement.target > 0 then
		fillRatio = math.clamp(achievement.progress / achievement.target, 0, 1)
	end

	local children = {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 16),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = status.strokeColor,
			Transparency = 0.18,
			Thickness = 1,
		}),
		Title = createLabel({
			position = UDim2.fromOffset(16, 12),
			size = UDim2.new(1, -172, 0, 20),
			font = Enum.Font.GothamBold,
			text = achievement.displayName,
			textColor3 = Color3.fromRGB(245, 248, 255),
			textSize = 18,
		}),
		Description = createLabel({
			position = UDim2.fromOffset(16, 34),
			size = UDim2.new(1, -172, 0, 32),
			font = Enum.Font.Gotham,
			text = achievement.description,
			textColor3 = Color3.fromRGB(189, 201, 228),
			textSize = 13,
			wrapped = true,
		}),
		Reward = createLabel({
			position = UDim2.fromOffset(16, 68),
			size = UDim2.new(1, -172, 0, 16),
			font = Enum.Font.GothamBold,
			text = buildRewardText(achievement),
			textColor3 = Color3.fromRGB(162, 226, 198),
			textSize = 12,
		}),
		ProgressLabel = createLabel({
			position = UDim2.new(1, -188, 0, 14),
			size = UDim2.fromOffset(108, 18),
			font = Enum.Font.GothamBold,
			text = formatProgressValue(achievement),
			textColor3 = Color3.fromRGB(231, 236, 248),
			textSize = 13,
			alignment = Enum.TextXAlignment.Right,
		}),
		ProgressBar = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 15, 24),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(16, 92),
			Size = UDim2.new(1, -124, 0, 12),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			Fill = React.createElement("Frame", {
				BackgroundColor3 = status.progressColor,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(fillRatio, 1),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
		StatusChip = React.createElement("Frame", {
			BackgroundColor3 = status.chipColor,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -136, 0, 60),
			Size = UDim2.fromOffset(120, 24),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			Label = createLabel({
				position = UDim2.fromOffset(0, 0),
				size = UDim2.fromOffset(120, 24),
				font = Enum.Font.GothamBold,
				text = status.label,
				textColor3 = status.chipTextColor,
				textSize = 12,
				alignment = Enum.TextXAlignment.Center,
				verticalAlignment = Enum.TextYAlignment.Center,
			}),
		}),
	}

	if achievement.isComplete and not achievement.isClaimed then
		children.ClaimButton = createActionButton({
			position = UDim2.new(1, -136, 1, -38),
			size = UDim2.fromOffset(120, 28),
			text = props.isSubmitting and "CLAIMING..." or "CLAIM",
			backgroundColor = props.isSubmitting and Color3.fromRGB(132, 118, 70) or Color3.fromRGB(239, 198, 102),
			textColor3 = Color3.fromRGB(30, 24, 11),
			textSize = 12,
			onClick = function()
				if props.isSubmitting then
					return
				end

				props.onClaim(achievement.id)
			end,
		})
	end

	return React.createElement("Frame", {
		BackgroundColor3 = status.cardColor,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.new(1, -8, 0, 116),
	}, children)
end

local function AchievementUi()
	local playerState = usePlayerState()
	local isOpen, setIsOpen = React.useState(false)
	local statusMessage, setStatusMessage = React.useState("Claim completed milestones here. Progress is tracked automatically.")
	local submittingAchievementId, setSubmittingAchievementId = React.useState(nil)

	local function claimAchievement(achievementId)
		if submittingAchievementId ~= nil then
			return
		end

		setSubmittingAchievementId(achievementId)

		local ok, result = pcall(function()
			return network.ClaimAchievement.Call(achievementId)
		end)

		setSubmittingAchievementId(nil)

		if not ok then
			setStatusMessage("Achievement claim failed to reach the server.")
			return
		end

		if type(result) == "table" and type(result.message) == "string" then
			setStatusMessage(result.message)
			return
		end

		setStatusMessage("That achievement request returned an invalid response.")
	end

	local achievementChildren = {
		ListLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}

	for index, achievement in ipairs(playerState.achievements) do
		achievementChildren["Achievement" .. index] = React.createElement(AchievementCard, {
			achievement = achievement,
			layoutOrder = index,
			isSubmitting = submittingAchievementId == achievement.id,
			onClaim = claimAchievement,
		})
	end

	local contentHeight = math.max(0, #playerState.achievements * 126)

	return React.createElement(React.Fragment, nil, {
		Opener = createActionButton({
			position = UDim2.new(0, 18, 0.5, -100),
			size = UDim2.fromOffset(68, 34),
			text = "ACH",
			backgroundColor = Color3.fromRGB(246, 203, 92),
			textColor3 = Color3.fromRGB(34, 28, 13),
			onClick = function()
				setIsOpen(not isOpen)
			end,
		}),
		Backdrop = isOpen and React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(4, 7, 14),
			BackgroundTransparency = 0.28,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			[React.Event.MouseButton1Click] = function()
				setIsOpen(false)
			end,
		}) or nil,
		Panel = isOpen and React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(10, 13, 22),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.52, 0.5),
			Size = UDim2.fromOffset(760, 560),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 22),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(88, 109, 159),
				Transparency = 0.08,
				Thickness = 1,
			}),
			Header = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(18, 24, 38),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 16),
				Size = UDim2.new(1, -36, 0, 80),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 18),
				}),
				Title = createLabel({
					position = UDim2.fromOffset(18, 12),
					size = UDim2.fromOffset(260, 26),
					font = Enum.Font.GothamBold,
					text = "Achievements",
					textColor3 = Color3.fromRGB(247, 249, 255),
					textSize = 28,
				}),
				Status = createLabel({
					position = UDim2.fromOffset(18, 42),
					size = UDim2.new(1, -180, 0, 18),
					font = Enum.Font.Gotham,
					text = statusMessage,
					textColor3 = Color3.fromRGB(180, 194, 223),
					textSize = 12,
				}),
				CompletedChip = React.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(54, 84, 134),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -312, 0, 16),
					Size = UDim2.fromOffset(120, 26),
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 13),
					}),
					Text = createLabel({
						position = UDim2.fromOffset(0, 0),
						size = UDim2.fromOffset(120, 26),
						font = Enum.Font.GothamBold,
						text = string.format("%d / %d done", playerState.completedAchievementCount, playerState.achievementCount),
						textColor3 = Color3.fromRGB(234, 240, 255),
						textSize = 12,
						alignment = Enum.TextXAlignment.Center,
						verticalAlignment = Enum.TextYAlignment.Center,
					}),
				}),
				ClaimedChip = React.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(45, 113, 80),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -180, 0, 16),
					Size = UDim2.fromOffset(120, 26),
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 13),
					}),
					Text = createLabel({
						position = UDim2.fromOffset(0, 0),
						size = UDim2.fromOffset(120, 26),
						font = Enum.Font.GothamBold,
						text = string.format("%d claimed", playerState.claimedAchievementCount),
						textColor3 = Color3.fromRGB(227, 255, 239),
						textSize = 12,
						alignment = Enum.TextXAlignment.Center,
						verticalAlignment = Enum.TextYAlignment.Center,
					}),
				}),
				CloseButton = createActionButton({
					position = UDim2.new(1, -50, 0, 18),
					size = UDim2.fromOffset(34, 34),
					text = "X",
					backgroundColor = Color3.fromRGB(61, 72, 101),
					onClick = function()
						setIsOpen(false)
					end,
				}),
			}),
			List = React.createElement("ScrollingFrame", {
				Active = true,
				AutomaticCanvasSize = Enum.AutomaticSize.None,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				CanvasSize = UDim2.fromOffset(0, contentHeight),
				Position = UDim2.fromOffset(18, 114),
				ScrollBarImageColor3 = Color3.fromRGB(118, 144, 195),
				ScrollBarThickness = 6,
				Size = UDim2.new(1, -36, 1, -132),
			}, achievementChildren),
		}) or nil,
	})
end

local root = ReactRoblox.createRoot(hostGui)
root:render(React.createElement(AchievementUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
