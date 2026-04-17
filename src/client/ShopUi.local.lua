local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(packages:WaitForChild("React"))
local ReactRoblox = require(packages:WaitForChild("ReactRoblox"))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(shared:WaitForChild("ShopConfig"))
local UiAssetConfig = require(shared:WaitForChild("UiAssetConfig"))
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))

local existingGui = playerGui:FindFirstChild("ShopUi")
if existingGui then
	existingGui:Destroy()
end

local hostGui = Instance.new("ScreenGui")
hostGui.Name = "ShopUi"
hostGui.IgnoreGuiInset = true
hostGui.ResetOnSpawn = false
hostGui.Parent = playerGui

local baselineGemValue = ShopConfig.Offers.Footgems1000.footgems / ShopConfig.Offers.Footgems1000.robuxPrice

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
		LayoutOrder = props.layoutOrder,
		Position = props.position,
		Size = props.size,
		Font = props.font,
		Text = props.text,
		TextColor3 = props.textColor3,
		TextSize = props.textSize,
		TextWrapped = props.wrapped or false,
		TextXAlignment = props.alignment or Enum.TextXAlignment.Left,
		TextYAlignment = props.verticalAlignment or Enum.TextYAlignment.Top,
		ZIndex = props.zindex or 1
	})
end

local function createImage(props)
	return React.createElement("ImageLabel", {
		BackgroundTransparency = 1,
		Image = props.image,
		ImageColor3 = props.imageColor3 or Color3.new(1, 1, 1),
		ImageTransparency = props.imageTransparency or 0,
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

local function isOwned(playerState, offer)
	if offer.entitlementId == nil then
		return false
	end

	local ownedFlags = {
		FootyenGain10x = playerState.shopHasFootyenGain10x,
		MovementSpeed5x = playerState.shopHasMovementSpeed5x,
		TripleSummon = playerState.shopHasTripleSummon,
		ExtraEquipTwo = playerState.shopHasExtraEquipTwo,
		LuckySummon = playerState.shopHasLuckySummon,
		BootMagnet = playerState.shopHasBootMagnet,
		PetPassiveAura = playerState.shopHasPetPassiveAura,
	}

	return ownedFlags[offer.entitlementId] == true
end

local function getStackCount(playerState, offer)
	if offer.stackableId == "ExtraPetSlots" then
		return playerState.shopExtraPetSlotsCount
	end

	if offer.stackableId == "PetPassiveOverclock" then
		return playerState.shopPetPassiveOverclockCount
	end

	if offer.stackableId == "BootValueCore" then
		return playerState.shopBootValueCoreCount
	end

	return 0
end

local function countOwnedEntitlements(playerState)
	local ownedCount = 0

	for _, value in ipairs({
		playerState.shopHasFootyenGain10x,
		playerState.shopHasMovementSpeed5x,
		playerState.shopHasTripleSummon,
		playerState.shopHasExtraEquipTwo,
		playerState.shopHasLuckySummon,
		playerState.shopHasBootMagnet,
		playerState.shopHasPetPassiveAura,
	}) do
		if value then
			ownedCount = ownedCount + 1
		end
	end

	return ownedCount
end

local function getOfferValueText(offer)
	if offer.footgems then
		local valueRatio = (offer.footgems / offer.robuxPrice) / baselineGemValue
		return string.format("%.2fx value", valueRatio)
	end

	if offer.stackableId ~= nil then
		return "Repurchaseable"
	end

	if offer.bundle ~= nil then
		return "Featured Bundle"
	end

	return "Permanent"
end

local function getOfferArtwork(offer)
	if offer.bundle ~= nil then
		return UiAssetConfig.getPetImageUri("Galactic"), Color3.fromRGB(255, 229, 174)
	end

	if offer.footgems then
		return UiAssetConfig.FOOTGEM_ICON_URI, Color3.fromRGB(185, 245, 255)
	end

	if offer.entitlementId == "FootyenGain10x" or offer.stackableId == "BootValueCore" then
		return UiAssetConfig.FOOTYEN_ICON_URI, Color3.fromRGB(214, 255, 187)
	end

	if offer.entitlementId == "ExtraEquipTwo" or offer.stackableId == "ExtraPetSlots" then
		return UiAssetConfig.TWO_EXTRA_EQUIP, Color3.fromRGB(249, 241, 255)
	end

	if offer.entitlementId == "LuckySummon" then
		return UiAssetConfig.PET_PLACEHOLDER, Color3.fromRGB(255, 220, 158)
	end

	if offer.entitlementId == "TripleSummon" then
		return UiAssetConfig.SUMMON_EGG_URI, Color3.fromRGB(249, 241, 255)
	end

	if offer.entitlementId == "MovementSpeed5x" or offer.entitlementId == "BootMagnet" then
		return UiAssetConfig.AUTO_ICON_URI, Color3.fromRGB(206, 228, 255)
	end

	if offer.entitlementId == "PetPassiveAura" or offer.stackableId == "PetPassiveOverclock" then
		return UiAssetConfig.getPetImageUri("Angel"), Color3.fromRGB(255, 239, 210)
	end

	return UiAssetConfig.FOOTGEM_ICON_URI, Color3.fromRGB(235, 244, 255)
end

local function OfferCard(props)
	local offer = props.offer
	local owned = isOwned(props.playerState, offer)
	local stackCount = getStackCount(props.playerState, offer)
	local artwork, artworkTint = getOfferArtwork(offer)
	local buttonText = "BUY"
	local buttonColor = Color3.fromRGB(71, 140, 235)
	local buttonTextColor = Color3.fromRGB(244, 248, 255)

	if offer.offerType == "GamePass" then
		if owned then
			buttonText = "OWNED"
			buttonColor = Color3.fromRGB(86, 186, 139)
			buttonTextColor = Color3.fromRGB(18, 25, 37)
		else
			buttonText = "UNLOCK"
		end
	elseif offer.stackableId ~= nil then
		buttonText = stackCount > 0 and string.format("BUY AGAIN x%d", stackCount) or "BUY"
		buttonColor = Color3.fromRGB(121, 100, 233)
	elseif offer.bundle ~= nil then
		buttonText = "CLAIM BUNDLE"
		buttonColor = Color3.fromRGB(232, 166, 74)
		buttonTextColor = Color3.fromRGB(23, 22, 17)
	elseif offer.footgems then
		buttonText = "BUY GEMS"
		buttonColor = Color3.fromRGB(54, 185, 239)
		buttonTextColor = Color3.fromRGB(18, 25, 37)
	end

	if offer.marketplaceId <= 0 then
		buttonText = "SET ID"
		buttonColor = Color3.fromRGB(86, 92, 108)
		buttonTextColor = Color3.fromRGB(244, 248, 255)
	end

	return React.createElement("Frame", {
		BackgroundColor3 = offer.highlighted and Color3.fromRGB(26, 34, 56) or Color3.fromRGB(18, 23, 36),
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
		Size = props.size,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 18),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = offer.highlighted and Color3.fromRGB(255, 210, 114) or Color3.fromRGB(88, 103, 132),
			Transparency = 0.18,
			Thickness = offer.highlighted and 2 or 1,
		}),
		Gradient = React.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, offer.highlighted and Color3.fromRGB(37, 49, 79) or Color3.fromRGB(26, 34, 52)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 17, 28)),
			}),
			Rotation = 135,
		}),
		ArtworkGlow = React.createElement("Frame", {
			BackgroundColor3 = offer.highlighted and Color3.fromRGB(255, 222, 158) or Color3.fromRGB(96, 133, 255),
			BackgroundTransparency = 0.72,
			BorderSizePixel = 0,
			Position = UDim2.new(1, -96, 0, -12),
			Size = UDim2.fromOffset(102, 102),
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Artwork = createImage({
			image = artwork,
			imageColor3 = artworkTint,
			imageTransparency = offer.bundle and 0 or 0.08,
			position = offer.entitlementId == "TripleSummon" and UDim2.new(1, -98, 0, -15) or UDim2.new(1, -86, 0, 0),
			size = offer.entitlementId == "TripleSummon"
			and UDim2.fromOffset(105, 105)
			or UDim2.fromOffset(80, 80),
		}),
		Title = createLabel({
			position = UDim2.fromOffset(14, 12),
			size = UDim2.new(1, -106, 0, 18),
			font = Enum.Font.GothamBold,
			text = offer.displayName,
			textColor3 = Color3.fromRGB(244, 248, 255),
			textSize = 16,
			wrapped = true,
		}),
		Subtitle = createLabel({
			position = UDim2.fromOffset(14, 34),
			size = UDim2.new(1, -112, 0, props.compact and 28 or 34),
			font = Enum.Font.Gotham,
			text = offer.description,
			textColor3 = Color3.fromRGB(182, 194, 219),
			textSize = 11,
			wrapped = true,
		}),
		ValueTag = React.createElement("TextLabel", {
			BackgroundColor3 = offer.highlighted and Color3.fromRGB(255, 211, 114) or Color3.fromRGB(36, 46, 69),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, props.compact and 68 or 74),
			Size = UDim2.fromOffset(102, 22),
			Font = Enum.Font.GothamBold,
			Text = string.upper(getOfferValueText(offer)),
			TextColor3 = offer.highlighted and Color3.fromRGB(30, 25, 15) or Color3.fromRGB(216, 228, 255),
			TextSize = 10,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
		}),
		Price = createLabel({
			position = UDim2.new(1, -120, 0, props.compact and 70 or 70),
			size = UDim2.fromOffset(104, 16),
			font = Enum.Font.GothamBold,
			text = string.format("%d R$", offer.robuxPrice),
			textColor3 = Color3.fromRGB(255, 224, 149),
			textSize = 15,
			zindex = 10,
			alignment = Enum.TextXAlignment.Right,
		}),
		OwnedInfo = (owned or stackCount > 0) and createLabel({
			position = UDim2.new(1, -120, 0, props.compact and 88 or 94),
			size = UDim2.fromOffset(104, 14),
			font = Enum.Font.Gotham,
			text = owned and "Owned" or string.format("Owned x%d", stackCount),
			textColor3 = Color3.fromRGB(157, 224, 178),
			textSize = 11,
			alignment = Enum.TextXAlignment.Right,
		}) or nil,
		Button = createActionButton({
			backgroundColor = buttonColor,
			position = UDim2.new(0, 14, 1, -44),
			size = UDim2.new(1, -28, 0, 32),
			text = buttonText,
			textColor3 = buttonTextColor,
			onClick = props.onPurchase,
			cornerRadius = 12,
		}),
	})
end

local function StatChip(props)
	return React.createElement("Frame", {
		BackgroundColor3 = props.backgroundColor,
		BorderSizePixel = 0,
		Position = props.position,
		Size = props.size,
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = props.strokeColor,
			Transparency = 0.22,
		}),
		Icon = createImage({
			image = props.image,
			position = UDim2.fromOffset(8, 6),
			size = UDim2.fromOffset(22, 22),
		}),
		Label = createLabel({
			position = UDim2.fromOffset(36, 5),
			size = UDim2.new(1, -44, 0, 11),
			font = Enum.Font.GothamMedium,
			text = props.label,
			textColor3 = props.labelColor,
			textSize = 10,
		}),
		Value = createLabel({
			position = UDim2.fromOffset(36, 13),
			size = UDim2.new(1, -44, 0, 14),
			font = Enum.Font.GothamBold,
			text = props.value,
			textColor3 = props.valueColor,
			textSize = 12,
		}),
	})
end

local function ShopUi()
	local playerState = usePlayerState()
	local isOpen, setIsOpen = React.useState(false)
	local statusMessage, setStatusMessage = React.useState("")

	local function promptOffer(offerId)
		local offer = ShopConfig.getOffer(offerId)
		if offer.marketplaceId <= 0 then
			setStatusMessage(string.format("%s still needs a real Marketplace ID in ShopConfig.", offer.displayName))
			return
		end

		if offer.offerType == "GamePass" then
			if isOwned(playerState, offer) then
				setStatusMessage(string.format("%s is already owned.", offer.displayName))
				return
			end

			MarketplaceService:PromptGamePassPurchase(localPlayer, offer.marketplaceId)
			setStatusMessage(string.format("Prompted %s.", offer.displayName))
			return
		end

		MarketplaceService:PromptProductPurchase(localPlayer, offer.marketplaceId)
		setStatusMessage(string.format("Prompted %s.", offer.displayName))
	end

	local children = {
		Opener = createActionButton({
			backgroundColor = Color3.fromRGB(234, 177, 73),
			position = UDim2.new(0, 18, 0.5, -48),
			size = UDim2.fromOffset(72, 34),
			text = "SHOP",
			textColor3 = Color3.fromRGB(33, 24, 15),
			onClick = function()
				setIsOpen(not isOpen)
			end,
			cornerRadius = 18,
		}),
	}

	if not isOpen then
		return React.createElement(React.Fragment, nil, children)
	end

	local function buildGrid(category, compact)
		local offerChildren = {
			Layout = React.createElement("UIGridLayout", {
				CellPadding = UDim2.fromOffset(10, 10),
				CellSize = compact and UDim2.fromOffset(206, 132) or UDim2.fromOffset(286, 132),
				FillDirectionMaxCells = compact and 3 or 2,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		}

		for index, offerId in ipairs(ShopConfig.getOffersByCategory(category)) do
			offerChildren["Offer" .. index] = React.createElement(OfferCard, {
				compact = compact,
				layoutOrder = index,
				offer = ShopConfig.getOffer(offerId),
				onPurchase = function()
					promptOffer(offerId)
				end,
				playerState = playerState,
				size = compact and UDim2.fromOffset(206, 132) or UDim2.fromOffset(286, 132),
			})
		end

		return offerChildren
	end

	children.Backdrop = React.createElement("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.42,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		[React.Event.MouseButton1Click] = function()
			setIsOpen(false)
		end,
	})

	children.Panel = React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 17, 28),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.54, 0.5),
		Size = UDim2.fromOffset(680, 640),
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = UDim.new(0, 28),
		}),
		Stroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 204, 112),
			Transparency = 0.16,
			Thickness = 2,
		}),
		Header = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(23, 31, 47),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(18, 16),
			Size = UDim2.new(1, -36, 0, 64)
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 22),
			}),
			Title = createLabel({
				position = UDim2.fromOffset(18, 14),
				size = UDim2.fromOffset(160, 22),
				font = Enum.Font.GothamBold,
				text = "SHOP",
				textColor3 = Color3.fromRGB(248, 248, 255),
				textSize = 28,
			}),
			Status = createLabel({
				position = UDim2.fromOffset(18, 42),
				size = UDim2.fromOffset(640, 16),
				font = Enum.Font.Gotham,
				text = statusMessage,
				textColor3 = Color3.fromRGB(196, 206, 228),
				textSize = 12,
				wrapped = true,
			}),
			FootgemsChip = React.createElement(StatChip, {
				backgroundColor = Color3.fromRGB(18, 52, 76),
				image = UiAssetConfig.FOOTGEM_ICON_URI,
				label = "Footgems",
				labelColor = Color3.fromRGB(177, 234, 255),
				position = UDim2.new(1, -320, 0, 12),
				size = UDim2.fromOffset(122, 34),
				strokeColor = Color3.fromRGB(88, 181, 225),
				value = string.format("%d", playerState.footgems),
				valueColor = Color3.fromRGB(245, 252, 255),
			}),
			FootyensChip = React.createElement(StatChip, {
				backgroundColor = Color3.fromRGB(20, 71, 34),
				image = UiAssetConfig.FOOTYEN_ICON_URI,
				label = "Footyens",
				labelColor = Color3.fromRGB(206, 255, 198),
				position = UDim2.new(1, -180, 0, 12),
				size = UDim2.fromOffset(122, 34),
				strokeColor = Color3.fromRGB(84, 201, 111),
				value = string.format("%d", playerState.footyens),
				valueColor = Color3.fromRGB(250, 255, 245),
			}),
			Entitlements = createLabel({
				position = UDim2.new(1, -320, 0, 46),
				size = UDim2.fromOffset(256, 16),
				font = Enum.Font.Gotham,
				text = string.format("%d / %d perks owned", countOwnedEntitlements(playerState), #ShopConfig.EntitlementIds),
				textColor3 = Color3.fromRGB(173, 218, 255),
				textSize = 12,
				alignment = Enum.TextXAlignment.Right,
			}),
			Close = createActionButton({
				backgroundColor = Color3.fromRGB(45, 57, 82),
				position = UDim2.new(1, -50, 0, 18),
				size = UDim2.fromOffset(42, 42),
				text = "X",
				onClick = function()
					setIsOpen(false)
				end,
				cornerRadius = 21,
			}),
		}),
		Content = React.createElement("ScrollingFrame", {
			Active = true,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			Position = UDim2.fromOffset(18, 106),
			ScrollBarImageColor3 = Color3.fromRGB(116, 145, 196),
			ScrollBarThickness = 6,
			Size = UDim2.fromOffset(944, 514),
		}, {
			Layout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			FeaturedHeader = createLabel({
				layoutOrder = 1,
				position = UDim2.fromOffset(0, 0),
				size = UDim2.fromOffset(240, 18),
				font = Enum.Font.GothamBold,
				text = "Featured",
				textColor3 = Color3.fromRGB(247, 233, 162),
				textSize = 20,
			}),
			Featured = React.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.fromOffset(944, 132),
			}, buildGrid(ShopConfig.OfferCategories.Featured, false)),
			FootgemsHeader = createLabel({
				layoutOrder = 3,
				position = UDim2.fromOffset(0, 0),
				size = UDim2.fromOffset(240, 18),
				font = Enum.Font.GothamBold,
				text = "Footgems",
				textColor3 = Color3.fromRGB(161, 224, 255),
				textSize = 20,
			}),
			Footgems = React.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 4,
				Size = UDim2.fromOffset(944, 274),
			}, buildGrid(ShopConfig.OfferCategories.Footgems, true)),
			GamePassHeader = createLabel({
				layoutOrder = 5,
				position = UDim2.fromOffset(0, 0),
				size = UDim2.fromOffset(240, 18),
				font = Enum.Font.GothamBold,
				text = "Permanent Perks",
				textColor3 = Color3.fromRGB(183, 236, 194),
				textSize = 20,
			}),
			GamePasses = React.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 6,
				Size = UDim2.fromOffset(944, 560),
			}, buildGrid(ShopConfig.OfferCategories.GamePasses, false)),
			StackableHeader = createLabel({
				layoutOrder = 7,
				position = UDim2.fromOffset(0, 0),
				size = UDim2.fromOffset(240, 18),
				font = Enum.Font.GothamBold,
				text = "Stackable Permanents",
				textColor3 = Color3.fromRGB(214, 194, 255),
				textSize = 20,
			}),
			Stackables = React.createElement("Frame", {
				BackgroundTransparency = 1,
				LayoutOrder = 8,
				Size = UDim2.fromOffset(944, 132),
			}, buildGrid(ShopConfig.OfferCategories.Stackables, false)),
		}),
	})

	return React.createElement(React.Fragment, nil, children)
end

local root = ReactRoblox.createRoot(hostGui)

root:render(React.createElement(ShopUi))

script.Destroying:Connect(function()
	root:unmount()
	hostGui:Destroy()
end)
