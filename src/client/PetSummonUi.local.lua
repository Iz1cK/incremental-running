local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(shared:WaitForChild("PetConfig"))
local SummonConfig = require(shared:WaitForChild("SummonConfig"))
local UiAssetConfig = require(shared:WaitForChild("UiAssetConfig"))
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))
local network = require(shared:WaitForChild("ZapClient"))

local existingGui = playerGui:FindFirstChild("PetSummonUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "PetSummonUi"
hostGui.IgnoreGuiInset = true
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local altarFolder = Workspace:WaitForChild(SummonConfig.WORKSPACE_FOLDER_NAME)

local function usePlayerState()
	local state, setState = React.useState(playerStateStore.getState())

	React.useEffect(function()
		return playerStateStore.subscribe(setState)
	end, {})

	return state
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

local function createImage(props)
	local imageContent = nil
	if type(props.image) == "string" and string.sub(props.image, 1, 7) == "file://" then
		imageContent = Content.fromUri(props.image)
	end

	return React.createElement("ImageLabel", {
		BackgroundTransparency = 1,
		Image = props.image,
		ImageContent = imageContent,
		ImageColor3 = props.imageColor3 or Color3.new(1, 1, 1),
		ImageTransparency = props.imageTransparency or 0,
		Position = props.position,
		Rotation = props.rotation or 0,
		ScaleType = props.scaleType or Enum.ScaleType.Fit,
		Size = props.size,
	})
end

local function createAutoDeleteList(selectedPetIds, pool)
	local autoDeleteList = {}

	for _, entry in ipairs(pool) do
		if selectedPetIds[entry.petId] == true then
			table.insert(autoDeleteList, entry.petId)
		end
	end

	return autoDeleteList
end

local function useNearestAltar()
	local nearestAltarId, setNearestAltarId = React.useState(nil)

	React.useEffect(function()
		local function updateNearestAltar()
			local character = localPlayer.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")

			if rootPart == nil then
				setNearestAltarId(nil)
				return
			end

			local nearestId = nil
			local nearestDistance = nil

			for _, altarModel in ipairs(altarFolder:GetChildren()) do
				if altarModel:IsA("Model") and altarModel.PrimaryPart then
					local altarId = altarModel:GetAttribute("AltarId")
					local distance = (altarModel.PrimaryPart.Position - rootPart.Position).Magnitude

					if distance <= SummonConfig.UI_HIDE_DISTANCE and (nearestDistance == nil or distance < nearestDistance) then
						nearestDistance = distance
						nearestId = altarId
					end
				end
			end

			if nearestDistance ~= nil and nearestDistance <= SummonConfig.UI_APPEAR_DISTANCE then
				setNearestAltarId(nearestId)
			elseif nearestDistance ~= nil and nearestAltarId ~= nil and nearestDistance <= SummonConfig.UI_HIDE_DISTANCE then
				setNearestAltarId(nearestAltarId)
			else
				setNearestAltarId(nil)
			end
		end

		updateNearestAltar()

		local connection = RunService.Heartbeat:Connect(updateNearestAltar)

		return function()
			connection:Disconnect()
		end
	end, { nearestAltarId })

	return nearestAltarId
end

local function SummonPoolCard(props)
	local entry = props.entry
	local definition = PetConfig.getDefinition(entry.petId)
	local rarityColor = SummonConfig.RarityColors[entry.rarity] or Color3.fromRGB(214, 223, 238)
	local isAutoDeleteSelected = props.isAutoDeleteSelected

	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = isAutoDeleteSelected and Color3.fromRGB(95, 39, 47) or Color3.fromRGB(17, 21, 33),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromOffset(118, 94),
		Text = "",
		[React.Event.MouseButton1Click] = function()
			props.onToggle(entry.petId)
		end,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 20),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = isAutoDeleteSelected and Color3.fromRGB(255, 128, 128) or rarityColor,
			Transparency = isAutoDeleteSelected and 0 or 0.12,
			Thickness = 2,
		}),
		Image = createImage({
			image = UiAssetConfig.getPetImageUri(entry.petId),
			position = UDim2.fromOffset(17, 10),
			size = UDim2.fromOffset(84, 50),
		}),
		Rarity = React.createElement("TextLabel", {
			BackgroundColor3 = isAutoDeleteSelected and Color3.fromRGB(255, 146, 146) or rarityColor,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 8),
			Size = UDim2.fromOffset(52, 16),
			Font = Enum.Font.GothamBold,
			Text = string.upper(string.sub(entry.rarity, 1, 3)),
			TextColor3 = Color3.fromRGB(18, 24, 36),
			TextSize = 9,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Chance = createLabel({
			position = UDim2.fromOffset(72, 10),
			size = UDim2.fromOffset(36, 12),
			font = Enum.Font.GothamBold,
			text = string.format("%.0f%%", entry.probability),
			textColor3 = isAutoDeleteSelected and Color3.fromRGB(255, 200, 200) or rarityColor,
			textSize = 11,
			alignment = Enum.TextXAlignment.Right,
		}),
		Name = createLabel({
			position = UDim2.fromOffset(8, 62),
			size = UDim2.fromOffset(102, 14),
			font = Enum.Font.GothamBold,
			text = definition.displayName,
			textColor3 = Color3.fromRGB(241, 245, 255),
			textSize = 11,
			alignment = Enum.TextXAlignment.Center,
		}),
		DeleteTag = isAutoDeleteSelected and React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(167, 54, 67),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(10, 76),
			Size = UDim2.fromOffset(98, 12),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			X = createLabel({
				position = UDim2.fromOffset(0, -1),
				size = UDim2.fromOffset(98, 14),
				font = Enum.Font.GothamBold,
				text = "X AUTO DELETE",
				textColor3 = Color3.fromRGB(255, 241, 241),
				textSize = 9,
				alignment = Enum.TextXAlignment.Center,
			}),
		}) or nil,
	})
end

local function HatchResultCard(props)
	local result = props.result
	local definition = PetConfig.getDefinition(result.petId)
	local rarityColor = SummonConfig.RarityColors[result.rarity] or Color3.fromRGB(214, 223, 238)
	local wobbleAngle = 0
	local wobbleX = 0
	local wobbleY = 0

	if props.phase == "hatching" then
		local time = props.animationClock - props.startedAt
		local speed = SummonConfig.HATCH_SHAKE_SPEED
		wobbleAngle = math.sin(time * speed + props.layoutOrder) * SummonConfig.HATCH_SHAKE_ANGLE
		wobbleX = math.sin(time * (speed + 1.6) + props.layoutOrder) * SummonConfig.HATCH_SHAKE_DISTANCE
		wobbleY = math.cos(time * (speed + 0.9) + props.layoutOrder) * (SummonConfig.HATCH_SHAKE_DISTANCE * 0.45)
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		Card = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = props.phase == "hatching" and Color3.fromRGB(19, 24, 38) or Color3.fromRGB(16, 21, 34),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, wobbleX, 0.5, wobbleY),
			Rotation = wobbleAngle,
			Size = UDim2.fromScale(1, 1),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, props.isLarge and 28 or 22),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = props.phase == "hatching" and Color3.fromRGB(169, 199, 255) or rarityColor,
				Transparency = 0.08,
				Thickness = 2,
			}),
			Glow = React.createElement("Frame", {
				BackgroundColor3 = props.phase == "hatching" and Color3.fromRGB(155, 193, 255) or definition.primaryColor,
				BackgroundTransparency = 0.76,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 16),
				Size = UDim2.new(1, -36, 0, props.isLarge and 128 or 104),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, props.isLarge and 24 or 18),
				}),
			}),
			Egg = props.phase == "hatching" and createImage({
				image = UiAssetConfig.PET_PLACEHOLDER,
				position = props.isLarge and UDim2.fromOffset(34, 18) or UDim2.fromOffset(22, 16),
				size = props.isLarge and UDim2.fromOffset(176, 176) or UDim2.fromOffset(118, 118),
				imageTransparency = 0.02,
			}) or nil,
			HatchText = props.phase == "hatching" and createLabel({
				position = UDim2.fromOffset(14, props.isLarge and 188 or 132),
				size = UDim2.new(1, -28, 0, 18),
				font = Enum.Font.GothamBold,
				text = "Hatching...",
				textColor3 = Color3.fromRGB(234, 240, 255),
				textSize = props.isLarge and 18 or 13,
				alignment = Enum.TextXAlignment.Center,
			}) or nil,
			Image = props.phase == "revealed" and createImage({
				image = UiAssetConfig.getPetImageUri(result.petId),
				position = props.isLarge and UDim2.fromOffset(30, 16) or UDim2.fromOffset(18, 14),
				size = props.isLarge and UDim2.fromOffset(176, 134) or UDim2.fromOffset(124, 94),
			}) or nil,
			Name = props.phase == "revealed" and createLabel({
				position = UDim2.fromOffset(10, props.isLarge and 156 or 116),
				size = UDim2.new(1, -20, 0, 20),
				font = Enum.Font.GothamBold,
				text = definition.displayName,
				textColor3 = Color3.fromRGB(246, 249, 255),
				textSize = props.isLarge and 18 or 13,
				alignment = Enum.TextXAlignment.Center,
				verticalAlignment = Enum.TextYAlignment.Center,
				wrapped = true,
			}) or nil,
			Rarity = props.phase == "revealed" and React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = rarityColor,
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 1, result.autoDeleted and (props.isLarge and -40 or -34) or -12),
				Size = UDim2.fromOffset(props.isLarge and 116 or 92, props.isLarge and 24 or 20),
				Font = Enum.Font.GothamBold,
				Text = string.upper(result.rarity),
				TextColor3 = Color3.fromRGB(19, 27, 40),
				TextSize = props.isLarge and 12 or 10,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}) or nil,
			AutoDeleted = props.phase == "revealed" and result.autoDeleted and React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = Color3.fromRGB(171, 62, 72),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 1, -12),
				Size = UDim2.fromOffset(props.isLarge and 142 or 112, props.isLarge and 22 or 18),
				Font = Enum.Font.GothamBold,
				Text = "AUTO DELETED",
				TextColor3 = Color3.fromRGB(255, 242, 242),
				TextSize = props.isLarge and 11 or 9,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}) or nil,
		}),
	})
end

local function PetSummonUi()
	local playerState = usePlayerState()
	local activeAltarId = useNearestAltar()
	local statusMessage, setStatusMessage = React.useState("Step into the altar field to summon.")
	local isSubmitting, setIsSubmitting = React.useState(false)
	local autoSummonAltarId, setAutoSummonAltarId = React.useState(nil)
	local selectedAutoDeletePetIds, setSelectedAutoDeletePetIds = React.useState({})
	local animationQueue, setAnimationQueue = React.useState({})
	local currentAnimation, setCurrentAnimation = React.useState(nil)
	local animationClock, setAnimationClock = React.useState(0)

	local altar = activeAltarId and SummonConfig.Altars[activeAltarId] or nil
	local pool = altar and SummonConfig.getOrderedPool(activeAltarId) or {}
	local canAffordSingle = altar ~= nil and playerState.footgems >= altar.costPerSummon
	local hasTripleSummon = playerState.shopHasTripleSummon == true
	local canAffordMulti = altar ~= nil
		and hasTripleSummon
		and playerState.footgems >= altar.costPerSummon * SummonConfig.MULTI_SUMMON_COUNT
	local isAutoSummoning = autoSummonAltarId ~= nil
	local selectedAutoDeleteCount = #createAutoDeleteList(selectedAutoDeletePetIds, pool)

	React.useEffect(function()
		local validLookup = {}
		local didChange = false

		for _, entry in ipairs(pool) do
			if selectedAutoDeletePetIds[entry.petId] == true then
				validLookup[entry.petId] = true
			end
		end

		for petId in pairs(selectedAutoDeletePetIds) do
			if validLookup[petId] ~= true then
				didChange = true
				break
			end
		end

		if didChange then
			setSelectedAutoDeletePetIds(validLookup)
		end
	end, { activeAltarId, pool, selectedAutoDeletePetIds })

	React.useEffect(function()
		if currentAnimation ~= nil or #animationQueue == 0 then
			return
		end

		local nextBatch = animationQueue[1]
		local remainingQueue = table.create(math.max(#animationQueue - 1, 0))

		for index = 2, #animationQueue do
			remainingQueue[#remainingQueue + 1] = animationQueue[index]
		end

		setAnimationQueue(remainingQueue)
		setCurrentAnimation({
			token = os.clock(),
			results = nextBatch.results,
			title = nextBatch.title,
			subtitle = nextBatch.subtitle,
			startedAt = os.clock(),
			phase = "hatching",
		})
	end, { animationQueue, currentAnimation })

	React.useEffect(function()
		local animationToken = currentAnimation and currentAnimation.token or nil
		if animationToken == nil then
			return
		end

		local revealThread = task.delay(SummonConfig.HATCH_DURATION, function()
			setCurrentAnimation(function(activeAnimation)
				if activeAnimation == nil or activeAnimation.token ~= animationToken then
					return activeAnimation
				end

				return {
					token = activeAnimation.token,
					results = activeAnimation.results,
					title = activeAnimation.title,
					subtitle = activeAnimation.subtitle,
					startedAt = activeAnimation.startedAt,
					phase = "revealed",
				}
			end)
		end)

		local hideThread = task.delay(SummonConfig.HATCH_DURATION + SummonConfig.REVEAL_DURATION, function()
			setCurrentAnimation(function(activeAnimation)
				if activeAnimation == nil or activeAnimation.token ~= animationToken then
					return activeAnimation
				end

				return nil
			end)
		end)

		return function()
			task.cancel(revealThread)
			task.cancel(hideThread)
		end
	end, { currentAnimation and currentAnimation.token or nil })

	React.useEffect(function()
		local animationToken = currentAnimation and currentAnimation.token or nil
		if animationToken == nil then
			return
		end

		setAnimationClock(os.clock())

		local connection = RunService.Heartbeat:Connect(function()
			setAnimationClock(os.clock())
		end)

		return function()
			connection:Disconnect()
		end
	end, { currentAnimation and currentAnimation.token or nil })

	local function enqueueSummonAnimation(response)
		if type(response) ~= "table" or type(response.results) ~= "table" or #response.results == 0 then
			return
		end

		local nextBatch = {
			results = response.results,
			title = #response.results == 1 and "Summon Complete" or string.format("%dx Summon Complete", #response.results),
			subtitle = string.format("Spent %d Footgems | %d remaining", response.spentFootgems, response.remainingFootgems),
		}

		setAnimationQueue(function(queue)
			local nextQueue = table.clone(queue)
			table.insert(nextQueue, nextBatch)
			return nextQueue
		end)
	end

	local function performSummon(altarId, amount)
		if altarId == nil or isSubmitting then
			return false, nil
		end

		setIsSubmitting(true)

		local ok, result = pcall(function()
			return network.SummonPets.Call({
				altarId = altarId,
				amount = amount,
				autoDeletePetIds = createAutoDeleteList(selectedAutoDeletePetIds, pool),
			})
		end)

		setIsSubmitting(false)

		if not ok then
			setStatusMessage("The altar failed to answer your summon request.")
			return false, nil
		end

		if type(result) == "table" and type(result.message) == "string" then
			setStatusMessage(result.message)
			if result.success then
				enqueueSummonAnimation(result)
			end

			return result.success == true, result
		end

		setStatusMessage("Summon request completed.")
		return true, result
	end

	local function stopAutoSummon(message)
		if autoSummonAltarId == nil then
			return
		end

		setAutoSummonAltarId(nil)

		if message ~= nil then
			setStatusMessage(message)
		end
	end

	React.useEffect(function()
		if autoSummonAltarId == nil then
			return
		end

		local isCancelled = false
		local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
			if gameProcessedEvent then
				return
			end

			if input.UserInputType == Enum.UserInputType.Keyboard then
				isCancelled = true
				stopAutoSummon("Auto summon stopped.")
			end
		end)

		task.spawn(function()
			while not isCancelled do
				if activeAltarId ~= autoSummonAltarId then
					stopAutoSummon("Auto summon stopped: you left the altar.")
					break
				end

				local success, result = performSummon(autoSummonAltarId, 1)
				if not success then
					stopAutoSummon(type(result) == "table" and result.message or "Auto summon stopped.")
					break
				end

				task.wait(SummonConfig.AUTO_SUMMON_INTERVAL)
			end
		end)

		return function()
			isCancelled = true
			inputConnection:Disconnect()
		end
	end, { autoSummonAltarId, activeAltarId, selectedAutoDeletePetIds })

	local children = {}

	if altar then
		children.Banner = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = Color3.fromRGB(12, 17, 28),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromOffset(418, 330),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 28),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(97, 198, 255),
				Transparency = 0.14,
				Thickness = 2,
			}),
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 31, 54)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 22)),
				}),
				Rotation = 135,
			}),
			Status = createLabel({
				position = UDim2.fromOffset(18, 12),
				size = UDim2.fromOffset(382, 16),
				font = Enum.Font.Gotham,
				text = statusMessage,
				textColor3 = Color3.fromRGB(214, 222, 239),
				textSize = 13,
				alignment = Enum.TextXAlignment.Center,
			}),
			Pool = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(18, 34),
				Size = UDim2.fromOffset(382, 198),
			}, (function()
				local poolChildren = {
					Layout = React.createElement("UIGridLayout", {
						CellPadding = UDim2.fromOffset(10, 10),
						CellSize = UDim2.fromOffset(118, 94),
						FillDirection = Enum.FillDirection.Horizontal,
						FillDirectionMaxCells = 3,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}

				for index, entry in ipairs(pool) do
					poolChildren["Entry" .. index] = React.createElement(SummonPoolCard, {
						entry = entry,
						isAutoDeleteSelected = selectedAutoDeletePetIds[entry.petId] == true,
						layoutOrder = index,
						onToggle = function(petId)
							setSelectedAutoDeletePetIds(function(currentLookup)
								local nextLookup = table.clone(currentLookup)

								if nextLookup[petId] == true then
									nextLookup[petId] = nil
								else
									nextLookup[petId] = true
								end

								return nextLookup
							end)
						end,
					})
				end

				return poolChildren
			end)()),
			Buttons = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 242),
				Size = UDim2.fromOffset(362, 42),
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 9),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				SummonOne = React.createElement("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = canAffordSingle and Color3.fromRGB(63, 180, 255) or Color3.fromRGB(57, 76, 99),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(104, 42),
					Font = Enum.Font.GothamBold,
					Text = isSubmitting and "ROLLING..." or "SUMMON 1",
					TextColor3 = canAffordSingle and Color3.fromRGB(14, 23, 35) or Color3.fromRGB(189, 198, 214),
					TextSize = 15,
					[React.Event.MouseButton1Click] = function()
						performSummon(activeAltarId, 1)
					end,
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 14),
					}),
				}),
				SummonThree = React.createElement("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = canAffordMulti and Color3.fromRGB(255, 203, 96)
						or (hasTripleSummon and Color3.fromRGB(92, 79, 48) or Color3.fromRGB(60, 65, 83)),
					BorderSizePixel = 0,
					LayoutOrder = 2,
					Size = UDim2.fromOffset(104, 42),
					Font = Enum.Font.GothamBold,
					Text = isSubmitting and "ROLLING..."
						or (hasTripleSummon and string.format("SUMMON %d", SummonConfig.MULTI_SUMMON_COUNT) or "3X LOCKED"),
					TextColor3 = canAffordMulti and Color3.fromRGB(25, 20, 12)
						or (hasTripleSummon and Color3.fromRGB(215, 210, 190) or Color3.fromRGB(188, 197, 221)),
					TextSize = 15,
					[React.Event.MouseButton1Click] = function()
						if not hasTripleSummon then
							setStatusMessage("Unlock 3x Summon in the shop to use this button.")
							return
						end

						performSummon(activeAltarId, SummonConfig.MULTI_SUMMON_COUNT)
					end,
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 14),
					}),
				}),
				Auto = React.createElement("TextButton", {
					AutoButtonColor = false,
					BackgroundColor3 = isAutoSummoning and Color3.fromRGB(191, 92, 92) or Color3.fromRGB(38, 49, 69),
					BorderSizePixel = 0,
					LayoutOrder = 3,
					Size = UDim2.fromOffset(136, 42),
					Font = Enum.Font.GothamBold,
					Text = isAutoSummoning and "STOP AUTO" or "AUTO",
					TextColor3 = Color3.fromRGB(236, 242, 255),
					TextSize = 15,
					[React.Event.MouseButton1Click] = function()
						if isAutoSummoning then
							stopAutoSummon("Auto summon stopped.")
						elseif canAffordSingle then
							setStatusMessage("Auto summon active. Press any key to stop.")
							setAutoSummonAltarId(activeAltarId)
						else
							setStatusMessage("You need more Footgems to start auto summon.")
						end
					end,
				}, {
					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 14),
					}),
					Icon = createImage({
						image = UiAssetConfig.AUTO_ICON_URI,
						position = UDim2.fromOffset(10, 8),
						size = UDim2.fromOffset(26, 26),
					}),
				}),
			}),
			AutoDeleteHint = createLabel({
				position = UDim2.fromOffset(18, 292),
				size = UDim2.fromOffset(382, 14),
				font = Enum.Font.Gotham,
				text = selectedAutoDeleteCount > 0
					and string.format("%d pet%s marked for auto-delete on summon.", selectedAutoDeleteCount, selectedAutoDeleteCount == 1 and "" or "s")
					or "Click a pet card to auto-delete that result whenever it is summoned.",
				textColor3 = selectedAutoDeleteCount > 0 and Color3.fromRGB(255, 178, 178) or Color3.fromRGB(175, 188, 210),
				textSize = 11,
				alignment = Enum.TextXAlignment.Center,
			}),
			Guarantee = createLabel({
				position = UDim2.fromOffset(0, 308),
				size = UDim2.new(1, 0, 0, 14),
				font = Enum.Font.Gotham,
				text = altar.multiGuaranteeRarity and string.format(
					"%dx guarantee: %s or better",
					SummonConfig.MULTI_SUMMON_COUNT,
					altar.multiGuaranteeRarity
				) or "",
				textColor3 = Color3.fromRGB(154, 226, 184),
				textSize = 11,
				alignment = Enum.TextXAlignment.Center,
			}),
		})
	end

	if currentAnimation ~= nil then
		local resultCount = #currentAnimation.results
		local isLarge = resultCount == 1
		local cardSize = isLarge and UDim2.fromOffset(244, 246) or UDim2.fromOffset(170, 198)
		local panelSize = isLarge and UDim2.fromOffset(360, 332) or UDim2.fromOffset(632, 338)
		local titleText = currentAnimation.phase == "hatching"
			and (isLarge and "Something Is Hatching..." or string.format("%d Eggs Are Hatching...", resultCount))
			or currentAnimation.title
		local subtitleText = currentAnimation.phase == "hatching"
			and "The altar is cracking open."
			or currentAnimation.subtitle

		children.ResultBackdrop = React.createElement("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.22,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
		})
		children.ResultPanel = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(11, 16, 26),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.58),
			Size = panelSize,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 30),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(111, 202, 255),
				Transparency = 0.12,
				Thickness = 2,
			}),
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 35, 59)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 22)),
				}),
				Rotation = 135,
			}),
			Title = createLabel({
				position = UDim2.fromOffset(0, 18),
				size = UDim2.new(1, 0, 0, 28),
				font = Enum.Font.GothamBold,
				text = titleText,
				textColor3 = Color3.fromRGB(245, 248, 255),
				textSize = 27,
				alignment = Enum.TextXAlignment.Center,
			}),
			Subtitle = createLabel({
				position = UDim2.fromOffset(0, 50),
				size = UDim2.new(1, 0, 0, 18),
				font = Enum.Font.Gotham,
				text = subtitleText,
				textColor3 = Color3.fromRGB(188, 204, 228),
				textSize = 13,
				alignment = Enum.TextXAlignment.Center,
			}),
			Content = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.new(0.5, 0, 0, 86),
				Size = UDim2.new(1, -36, 1, -108),
			}, (function()
				local resultChildren = {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 12),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
				}

				for index, result in ipairs(currentAnimation.results) do
					resultChildren["Result" .. index] = React.createElement(HatchResultCard, {
						animationClock = animationClock,
						isLarge = isLarge,
						layoutOrder = index,
						phase = currentAnimation.phase,
						result = result,
						size = cardSize,
						startedAt = currentAnimation.startedAt,
					})
				end

				return resultChildren
			end)()),
		})
	end

	return React.createElement(React.Fragment, nil, children)
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(PetSummonUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
