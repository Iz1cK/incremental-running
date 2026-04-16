local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local existingGui = playerGui:FindFirstChild("PetInventoryUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "PetInventoryUi"
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
		Position = props.position,
		ScaleType = props.scaleType or Enum.ScaleType.Fit,
		Size = props.size,
	})
end

local function createActionButton(props)
	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = props.backgroundColor,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Position = props.position,
		Size = props.size,
		Font = Enum.Font.GothamBold,
		Text = props.text,
		TextColor3 = props.textColor3 or Color3.fromRGB(244, 248, 255),
		TextSize = props.textSize or 13,
		[React.Event.MouseButton1Click] = props.onClick,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, props.cornerRadius or 12),
		}),
	})
end

local function getSelectedPet(pets, selectedPetUid)
	for _, pet in ipairs(pets) do
		if pet.uid == selectedPetUid then
			return pet
		end
	end

	return pets[1]
end

local function countSelectedPets(selectedDeleteUids)
	local count = 0
	for _ in pairs(selectedDeleteUids) do
		count = count + 1
	end

	return count
end

local function toggleDeleteSelection(selectedDeleteUids, petUid)
	local nextSelection = table.clone(selectedDeleteUids)

	if nextSelection[petUid] then
		nextSelection[petUid] = nil
	else
		nextSelection[petUid] = true
	end

	return nextSelection
end

local function PetSlot(props)
	local pet = props.pet
	local hasPet = pet ~= nil
	local definition = hasPet and PetConfig.getDefinition(pet.petId) or nil
	local rarityColor = hasPet and (SummonConfig.RarityColors[definition.rarity] or definition.primaryColor) or Color3.fromRGB(70, 79, 98)
	local isMarkedForDeletion = hasPet and props.isDeleteMode and props.isDeleteSelected
	local backgroundColor = Color3.fromRGB(16, 19, 29)

	if hasPet then
		backgroundColor = props.isSelected and Color3.fromRGB(32, 44, 70) or Color3.fromRGB(22, 28, 42)
	end

	if isMarkedForDeletion then
		backgroundColor = Color3.fromRGB(89, 38, 46)
		rarityColor = Color3.fromRGB(255, 132, 132)
	end

	return React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromOffset(56, 56),
		Text = "",
		[React.Event.MouseButton1Click] = function()
			if not hasPet then
				return
			end

			props.onClick(pet.uid)
		end,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 14),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = rarityColor,
			Transparency = hasPet and 0.08 or 0.52,
			Thickness = (props.isSelected or isMarkedForDeletion) and 2 or 1,
		}),
		Image = hasPet and createImage({
			image = UiAssetConfig.getPetImageUri(pet.petId),
			position = UDim2.fromOffset(5, 5),
			size = UDim2.fromOffset(46, 46),
		}) or nil,
		Empty = not hasPet and createLabel({
			position = UDim2.fromOffset(0, 0),
			size = UDim2.fromOffset(56, 56),
			font = Enum.Font.GothamBold,
			text = "+",
			textColor3 = Color3.fromRGB(74, 86, 110),
			textSize = 18,
			alignment = Enum.TextXAlignment.Center,
			verticalAlignment = Enum.TextYAlignment.Center,
		}) or nil,
		Equipped = pet and pet.isEquipped and React.createElement("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(89, 213, 156),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(12, 12),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}) or nil,
		DeleteCheck = isMarkedForDeletion and createLabel({
			position = UDim2.fromOffset(0, 0),
			size = UDim2.fromOffset(56, 56),
			font = Enum.Font.GothamBlack,
			text = "X",
			textColor3 = Color3.fromRGB(255, 234, 234),
			textSize = 15,
			alignment = Enum.TextXAlignment.Center,
			verticalAlignment = Enum.TextYAlignment.Center,
		}) or nil,
	})
end

local function PetInventoryUi()
	local playerState = usePlayerState()
	local isOpen, setIsOpen = React.useState(false)
	local selectedPetUid, setSelectedPetUid = React.useState(nil)
	local selectedDeleteUids, setSelectedDeleteUids = React.useState({})
	local statusMessage, setStatusMessage = React.useState("Equip your best pets or enter delete mode to clean your inventory fast.")
	local isSubmitting, setIsSubmitting = React.useState(false)
	local isDeleteMode, setIsDeleteMode = React.useState(false)

	local pets = playerState.pets
	local selectedPet = getSelectedPet(pets, selectedPetUid)
	local selectedDeleteCount = countSelectedPets(selectedDeleteUids)

	React.useEffect(function()
		if selectedPet then
			if selectedPetUid ~= selectedPet.uid then
				setSelectedPetUid(selectedPet.uid)
			end
		elseif selectedPetUid ~= nil then
			setSelectedPetUid(nil)
		end
	end, { pets, selectedPetUid, selectedPet })

	React.useEffect(function()
		local validDeleteUids = {}
		local didChange = false

		for _, pet in ipairs(pets) do
			if selectedDeleteUids[pet.uid] then
				validDeleteUids[pet.uid] = true
			end
		end

		for petUid in pairs(selectedDeleteUids) do
			if validDeleteUids[petUid] == nil then
				didChange = true
				break
			end
		end

		if didChange then
			setSelectedDeleteUids(validDeleteUids)
		end
	end, { pets, selectedDeleteUids })

	local function submitPetAction(requestLabel, callback, afterSuccess)
		if isSubmitting then
			return
		end

		setIsSubmitting(true)

		local ok, result = pcall(callback)
		setIsSubmitting(false)

		if not ok then
			setStatusMessage(requestLabel .. " failed to reach the server.")
			return
		end

		if type(result) == "table" and type(result.message) == "string" then
			setStatusMessage(result.message)
			if result.success and afterSuccess then
				afterSuccess()
			end
			return
		end

		setStatusMessage(requestLabel .. " completed.")
		if afterSuccess then
			afterSuccess()
		end
	end

	local function handleSlotClick(petUid)
		if isDeleteMode then
			setSelectedDeleteUids(toggleDeleteSelection(selectedDeleteUids, petUid))
			return
		end

		setSelectedPetUid(petUid)
	end

	local inventoryChildren = {
		Opener = React.createElement("ImageButton", {
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Image = UiAssetConfig.PETS_ICON_URI,
			ImageContent = Content.fromUri(UiAssetConfig.PETS_ICON_URI),
			Position = UDim2.new(0, 18, 0.5, 58),
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(76, 76),
			[React.Event.MouseButton1Click] = function()
				setIsOpen(not isOpen)
			end,
		}, {
			Aspect = React.createElement("UIAspectRatioConstraint", {
				AspectRatio = 1,
			}),
		}),
	}

	if not isOpen then
		return React.createElement(React.Fragment, nil, inventoryChildren)
	end

	local panelChildren = {
		Backdrop = React.createElement("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.42,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			[React.Event.MouseButton1Click] = function()
				setIsOpen(false)
			end,
		}),
		Panel = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(12, 17, 28),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.54, 0.5),
			Size = UDim2.fromOffset(792, 448),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 26),
			}),
			Stroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(97, 198, 255),
				Transparency = 0.18,
				Thickness = 2,
			}),
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(19, 29, 48)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 13, 22)),
				}),
				Rotation = 135,
			}),
			TopBanner = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(18, 27, 44),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 16),
				Size = UDim2.fromOffset(756, 62),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 18),
				}),
				Title = createLabel({
					position = UDim2.fromOffset(16, 12),
					size = UDim2.fromOffset(180, 18),
					font = Enum.Font.GothamBold,
					text = "PET INVENTORY",
					textColor3 = Color3.fromRGB(245, 248, 255),
					textSize = 21,
				}),
				Status = createLabel({
					position = UDim2.fromOffset(16, 34),
					size = UDim2.fromOffset(420, 16),
					font = Enum.Font.Gotham,
					text = statusMessage,
					textColor3 = Color3.fromRGB(183, 198, 225),
					textSize = 12,
				}),
				Counts = createLabel({
					position = UDim2.fromOffset(432, 12),
					size = UDim2.fromOffset(248, 16),
					font = Enum.Font.GothamBold,
					text = string.format("%d pets | %d empty / %d", playerState.petInventoryCount, playerState.petEmptySlots, playerState.petInventoryLimit),
					textColor3 = Color3.fromRGB(255, 224, 144),
					textSize = 15,
					alignment = Enum.TextXAlignment.Right,
				}),
				Equipped = createLabel({
					position = UDim2.fromOffset(432, 32),
					size = UDim2.fromOffset(248, 16),
					font = Enum.Font.Gotham,
					text = string.format("%d / %d equipped", playerState.equippedPetCount, playerState.petEquipLimit),
					textColor3 = Color3.fromRGB(174, 223, 255),
					textSize = 12,
					alignment = Enum.TextXAlignment.Right,
				}),
				Close = createActionButton({
					backgroundColor = Color3.fromRGB(36, 48, 72),
					layoutOrder = 1,
					position = UDim2.new(1, -50, 0, 14),
					size = UDim2.fromOffset(34, 34),
					text = "X",
					textSize = 15,
					cornerRadius = 17,
					onClick = function()
						setIsOpen(false)
					end,
				}),
			}),
			LeftFrame = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(15, 20, 31),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(18, 94),
				Size = UDim2.fromOffset(338, 334),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 20),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(79, 95, 124),
					Transparency = 0.4,
				}),
				Header = createLabel({
					position = UDim2.fromOffset(16, 14),
					size = UDim2.fromOffset(160, 18),
					font = Enum.Font.GothamBold,
					text = isDeleteMode and "Delete Mode" or "Your Pets",
					textColor3 = Color3.fromRGB(242, 246, 255),
					textSize = 18,
				}),
				Subheader = createLabel({
					position = UDim2.fromOffset(16, 34),
					size = UDim2.fromOffset(294, 14),
					font = Enum.Font.Gotham,
					text = isDeleteMode and string.format("Selected %d pet%s.", selectedDeleteCount, selectedDeleteCount == 1 and "" or "s")
						or "Compact 5-column grid with scrolling storage.",
					textColor3 = Color3.fromRGB(155, 172, 201),
					textSize = 11,
				}),
				Grid = React.createElement("ScrollingFrame", {
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					Position = UDim2.fromOffset(14, 60),
					ScrollBarImageColor3 = Color3.fromRGB(93, 123, 168),
					ScrollBarThickness = 5,
					Size = UDim2.fromOffset(310, 208),
				}, (function()
					local children = {
						Layout = React.createElement("UIGridLayout", {
							CellPadding = UDim2.fromOffset(6, 8),
							CellSize = UDim2.fromOffset(56, 56),
							FillDirectionMaxCells = 5,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					}

					for slotIndex = 1, playerState.petInventoryLimit do
						local pet = pets[slotIndex]
						children["Slot" .. slotIndex] = React.createElement(PetSlot, {
							isDeleteMode = isDeleteMode,
							isDeleteSelected = pet and selectedDeleteUids[pet.uid] == true or false,
							isSelected = selectedPet and pet and selectedPet.uid == pet.uid or false,
							layoutOrder = slotIndex,
							onClick = handleSlotClick,
							pet = pet,
						})
					end

					return children
				end)()),
				Actions = React.createElement("Frame", {
					BackgroundTransparency = 1,
					Position = UDim2.fromOffset(14, 280),
					Size = UDim2.fromOffset(310, 40),
				}, {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					EquipBest = createActionButton({
						backgroundColor = Color3.fromRGB(71, 141, 236),
						layoutOrder = 1,
						size = UDim2.fromOffset(96, 38),
						text = isSubmitting and "WAIT..." or "BEST",
						onClick = function()
							submitPetAction("Equip best", function()
								return network.EquipBestPets.Call()
							end)
						end,
					}),
					DeleteMode = createActionButton({
						backgroundColor = isDeleteMode and Color3.fromRGB(182, 93, 93) or Color3.fromRGB(67, 77, 99),
						layoutOrder = 2,
						size = UDim2.fromOffset(96, 38),
						text = isDeleteMode and "CANCEL" or "DELETE",
						onClick = function()
							if isDeleteMode then
								setIsDeleteMode(false)
								setSelectedDeleteUids({})
								setStatusMessage("Delete mode closed.")
							else
								setIsDeleteMode(true)
								setSelectedDeleteUids({})
								setStatusMessage("Select pets, then submit the deletion.")
							end
						end,
					}),
					DeleteSubmit = createActionButton({
						backgroundColor = isDeleteMode and (selectedDeleteCount > 0 and Color3.fromRGB(214, 103, 103) or Color3.fromRGB(79, 60, 64))
							or Color3.fromRGB(63, 74, 98),
						layoutOrder = 3,
						size = UDim2.fromOffset(110, 38),
						text = isSubmitting and "WAIT..." or (isDeleteMode and string.format("SUBMIT %d", selectedDeleteCount) or "CLEAR"),
						onClick = function()
							if not isDeleteMode then
								setSelectedDeleteUids({})
								setStatusMessage("Selection cleared.")
								return
							end

							if selectedDeleteCount == 0 then
								setStatusMessage("Select at least one pet before deleting.")
								return
							end

							local selectedUids = {}
							for petUid in pairs(selectedDeleteUids) do
								table.insert(selectedUids, petUid)
							end

							submitPetAction("Mass delete", function()
								return network.DeletePets.Call(selectedUids)
							end, function()
								setSelectedDeleteUids({})
								setIsDeleteMode(false)
							end)
						end,
					}),
				}),
			}),
			RightFrame = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(15, 20, 31),
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(372, 94),
				Size = UDim2.fromOffset(402, 334),
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 20),
				}),
				Stroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(79, 95, 124),
					Transparency = 0.4,
				}),
				DeleteSummary = isDeleteMode and React.createElement(React.Fragment, nil, {
					Header = createLabel({
						position = UDim2.fromOffset(20, 18),
						size = UDim2.fromOffset(220, 22),
						font = Enum.Font.GothamBold,
						text = "Bulk Delete",
						textColor3 = Color3.fromRGB(248, 249, 255),
						textSize = 22,
					}),
					Info = createLabel({
						position = UDim2.fromOffset(20, 50),
						size = UDim2.fromOffset(360, 56),
						font = Enum.Font.Gotham,
						text = string.format("Marked %d pet%s for deletion.\nThis updates instantly after the server confirms it.", selectedDeleteCount, selectedDeleteCount == 1 and "" or "s"),
						textColor3 = Color3.fromRGB(196, 206, 226),
						textSize = 15,
						wrapped = true,
					}),
					Tip = createLabel({
						position = UDim2.fromOffset(20, 118),
						size = UDim2.fromOffset(360, 40),
						font = Enum.Font.GothamMedium,
						text = "Tip: equipped pets can be selected too, so this doubles as a quick reset tool.",
						textColor3 = Color3.fromRGB(255, 209, 176),
						textSize = 13,
						wrapped = true,
					}),
				}) or nil,
				Empty = not isDeleteMode and not selectedPet and createLabel({
					position = UDim2.fromOffset(32, 54),
					size = UDim2.fromOffset(338, 120),
					font = Enum.Font.GothamBold,
					text = "No pet selected.\nPick a slot to inspect it here.",
					textColor3 = Color3.fromRGB(183, 195, 221),
					textSize = 23,
					alignment = Enum.TextXAlignment.Center,
					verticalAlignment = Enum.TextYAlignment.Center,
					wrapped = true,
				}) or nil,
				Content = not isDeleteMode and selectedPet and (function()
					local definition = PetConfig.getDefinition(selectedPet.petId)
					local multiplier, passivePerSecond = PetConfig.getBoosts(selectedPet.petId, selectedPet.level)
					local rarityColor = SummonConfig.RarityColors[definition.rarity] or Color3.fromRGB(218, 226, 240)

					return React.createElement(React.Fragment, nil, {
						EquippedTag = React.createElement("TextLabel", {
							AnchorPoint = Vector2.new(1, 0),
							BackgroundColor3 = selectedPet.isEquipped and Color3.fromRGB(84, 205, 152) or Color3.fromRGB(65, 77, 108),
							BorderSizePixel = 0,
							Position = UDim2.new(1, -16, 0, 16),
							Size = UDim2.fromOffset(110, 30),
							Font = Enum.Font.GothamBold,
							Text = selectedPet.isEquipped and "EQUIPPED" or "STORED",
							TextColor3 = selectedPet.isEquipped and Color3.fromRGB(12, 34, 21) or Color3.fromRGB(234, 239, 255),
							TextSize = 12,
						}, {
							Corner = React.createElement("UICorner", {
								CornerRadius = UDim.new(1, 0),
							}),
						}),
						Preview = React.createElement("Frame", {
							BackgroundColor3 = Color3.fromRGB(22, 31, 47),
							BorderSizePixel = 0,
							Position = UDim2.fromOffset(18, 36),
							Size = UDim2.fromOffset(366, 132),
						}, {
							Corner = React.createElement("UICorner", {
								CornerRadius = UDim.new(0, 20),
							}),
							Gradient = React.createElement("UIGradient", {
								Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, definition.primaryColor),
									ColorSequenceKeypoint.new(1, definition.accentColor),
								}),
								Rotation = 140,
							}),
							Overlay = React.createElement("Frame", {
								BackgroundColor3 = Color3.fromRGB(10, 14, 22),
								BackgroundTransparency = 0.34,
								BorderSizePixel = 0,
								Size = UDim2.fromScale(1, 1),
							}, {
								Corner = React.createElement("UICorner", {
									CornerRadius = UDim.new(0, 20),
								}),
							}),
							Image = createImage({
								image = UiAssetConfig.getPetImageUri(selectedPet.petId),
								position = UDim2.fromOffset(16, 12),
								size = UDim2.fromOffset(116, 108),
							}),
							Rarity = React.createElement("TextLabel", {
								BackgroundColor3 = rarityColor,
								BorderSizePixel = 0,
								Position = UDim2.fromOffset(148, 18),
								Size = UDim2.fromOffset(96, 24),
								Font = Enum.Font.GothamBold,
								Text = string.upper(definition.rarity),
								TextColor3 = Color3.fromRGB(22, 28, 39),
								TextSize = 11,
							}, {
								Corner = React.createElement("UICorner", {
									CornerRadius = UDim.new(1, 0),
								}),
							}),
							Level = React.createElement("TextLabel", {
								BackgroundColor3 = Color3.fromRGB(24, 34, 49),
								BorderSizePixel = 0,
								Position = UDim2.fromOffset(250, 18),
								Size = UDim2.fromOffset(86, 24),
								Font = Enum.Font.GothamBold,
								Text = string.format("LV %d", selectedPet.level),
								TextColor3 = Color3.fromRGB(234, 240, 255),
								TextSize = 11,
							}, {
								Corner = React.createElement("UICorner", {
									CornerRadius = UDim.new(1, 0),
								}),
							}),
							MultiplierCard = React.createElement("Frame", {
								BackgroundColor3 = Color3.fromRGB(16, 23, 36),
								BorderSizePixel = 0,
								Position = UDim2.fromOffset(148, 52),
								Size = UDim2.fromOffset(188, 30),
							}, {
								Corner = React.createElement("UICorner", {
									CornerRadius = UDim.new(0, 12),
								}),
								Label = createLabel({
									position = UDim2.fromOffset(10, 4),
									size = UDim2.fromOffset(72, 10),
									font = Enum.Font.Gotham,
									text = "Multiplier",
									textColor3 = Color3.fromRGB(165, 199, 230),
									textSize = 10,
								}),
								Value = createLabel({
									position = UDim2.fromOffset(10, 13),
									size = UDim2.fromOffset(160, 14),
									font = Enum.Font.GothamBold,
									text = PetConfig.formatMultiplier(multiplier),
									textColor3 = Color3.fromRGB(234, 241, 255),
									textSize = 13,
								}),
							}),
							PassiveCard = React.createElement("Frame", {
								BackgroundColor3 = Color3.fromRGB(16, 23, 36),
								BorderSizePixel = 0,
								Position = UDim2.fromOffset(148, 88),
								Size = UDim2.fromOffset(188, 30),
							}, {
								Corner = React.createElement("UICorner", {
									CornerRadius = UDim.new(0, 12),
								}),
								Label = createLabel({
									position = UDim2.fromOffset(10, 4),
									size = UDim2.fromOffset(72, 10),
									font = Enum.Font.Gotham,
									text = "Passive",
									textColor3 = Color3.fromRGB(255, 214, 150),
									textSize = 10,
								}),
								Value = createLabel({
									position = UDim2.fromOffset(10, 13),
									size = UDim2.fromOffset(160, 14),
									font = Enum.Font.GothamBold,
									text = PetConfig.formatPassive(passivePerSecond),
									textColor3 = Color3.fromRGB(248, 243, 232),
									textSize = 13,
								}),
							}),
						}),
						-- LevelTitle = createLabel({
						-- 	position = UDim2.fromOffset(24, 166),
						-- 	size = UDim2.fromOffset(180, 18),
						-- 	font = Enum.Font.GothamBold,
						-- 	text = string.format("Upgrade %d / %d", selectedPet.level, PetConfig.MAX_UPGRADE_LEVEL),
						-- 	textColor3 = Color3.fromRGB(242, 246, 255),
						-- 	textSize = 16,
						-- }),
						-- LevelTrack = React.createElement(LevelTrack, {
						-- 	activeColor = definition.primaryColor,
						-- 	level = selectedPet.level,
						-- 	position = UDim2.fromOffset(24, 190),
						-- }),
						Buttons = React.createElement("Frame", {
							BackgroundTransparency = 1,
							Position = UDim2.fromOffset(20, 222),
							Size = UDim2.fromOffset(362, 40),
						}, {
							Layout = React.createElement("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								Padding = UDim.new(0, 8),
								SortOrder = Enum.SortOrder.LayoutOrder,
							}),
							Equip = createActionButton({
								backgroundColor = selectedPet.isEquipped and Color3.fromRGB(70, 86, 113) or Color3.fromRGB(76, 191, 144),
								layoutOrder = 1,
								size = UDim2.fromOffset(112, 38),
								text = isSubmitting and "WAIT..." or (selectedPet.isEquipped and "UNEQUIP" or "EQUIP"),
								onClick = function()
									submitPetAction("Pet equip", function()
										return network.SetPetEquipped.Call({
											uid = selectedPet.uid,
											equipped = not selectedPet.isEquipped,
										})
									end)
								end,
							}),
							Delete = createActionButton({
								backgroundColor = Color3.fromRGB(181, 84, 84),
								layoutOrder = 2,
								size = UDim2.fromOffset(112, 38),
								text = isSubmitting and "WAIT..." or "DELETE",
								onClick = function()
									submitPetAction("Pet deletion", function()
										return network.DeletePet.Call(selectedPet.uid)
									end)
								end,
							}),
							Upgrade = createActionButton({
								backgroundColor = Color3.fromRGB(93, 120, 201),
								layoutOrder = 3,
								size = UDim2.fromOffset(122, 38),
								text = isSubmitting and "WAIT..." or "UPGRADE",
								onClick = function()
									submitPetAction("Pet upgrade", function()
										return network.UpgradePet.Call(selectedPet.uid)
									end)
								end,
							}),
						}),
						QolHint = createLabel({
							position = UDim2.fromOffset(24, 274),
							size = UDim2.fromOffset(340, 34),
							font = Enum.Font.Gotham,
							text = "QoL: equipped pets float to the first slots, and BEST refreshes your top three.",
							textColor3 = Color3.fromRGB(156, 172, 199),
							textSize = 11,
							wrapped = true,
						}),
					})
				end)() or nil,
			}),
		}),
	}

	for key, value in pairs(panelChildren) do
		inventoryChildren[key] = value
	end

	return React.createElement(React.Fragment, nil, inventoryChildren)
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(PetInventoryUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
