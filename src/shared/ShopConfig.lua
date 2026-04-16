local ShopConfig = {}

ShopConfig.PURCHASE_HISTORY_LIMIT = 120
ShopConfig.PROCESSED_RECEIPT_LIMIT = 180
ShopConfig.REFUND_NOTE_LIMIT = 140

ShopConfig.EntitlementIds = {
	"FootyenGain10x",
	"MovementSpeed5x",
	"TripleSummon",
	"ExtraEquipTwo",
	"LuckySummon",
	"BootMagnet",
	"PetPassiveAura",
}

ShopConfig.StackableIds = {
	"ExtraPetSlots",
	"PetPassiveOverclock",
	"BootValueCore",
}

ShopConfig.Entitlements = {
	FootyenGain10x = {
		displayName = "Permanent x10 Footyen Gain",
	},
	MovementSpeed5x = {
		displayName = "Permanent x5 Movement Speed",
	},
	TripleSummon = {
		displayName = "3x Summon Unlock",
	},
	ExtraEquipTwo = {
		displayName = "+2 Equipped Pets",
	},
	LuckySummon = {
		displayName = "Lucky Summon Chance",
		luckyWeightMultipliers = {
			Common = 0.82,
			Uncommon = 1.15,
			Rare = 1.75,
			Legendary = 2.8,
		},
	},
	BootMagnet = {
		displayName = "Boot Magnet",
		pickupRadiusMultiplier = 1.6,
		spawnIntervalMultiplier = 0.86,
	},
	PetPassiveAura = {
		displayName = "Pet Passive Aura",
		passiveMultiplier = 1.5,
	},
}

ShopConfig.Stackables = {
	ExtraPetSlots = {
		displayName = "+5 Pet Slots",
		grantAmount = 1,
		slotIncreasePerStack = 5,
	},
	PetPassiveOverclock = {
		displayName = "Pet Passive Overclock",
		grantAmount = 1,
		passiveMultiplierPerStack = 0.15,
	},
	BootValueCore = {
		displayName = "Boot Value Core",
		grantAmount = 1,
		bootValueMultiplierPerStack = 0.12,
	},
}

ShopConfig.OfferCategories = {
	Footgems = "Footgems",
	GamePasses = "GamePasses",
	Stackables = "Stackables",
	Featured = "Featured",
}

local orderedOfferIds = {
	"Footgems1000",
	"Footgems4000",
	"Footgems8000",
	"Footgems16000",
	"Footgems32000",
	"Footgems64000",
	"FootyenGain10xPass",
	"MovementSpeed5xPass",
	"TripleSummonPass",
	"ExtraEquipTwoPass",
	"LuckySummonPass",
	"BootMagnetPass",
	"PetPassiveAuraPass",
	"ExtraPetSlotsPack",
	"PetPassiveOverclockPack",
	"BootValueCorePack",
	"GalacticCompanionBundle",
}

ShopConfig.Offers = {
	Footgems1000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576623872,
		displayName = "1,000 Footgems",
		description = "A starter bundle for early summons and upgrades.",
		robuxPrice = 29,
		footgems = 1000,
		valueTag = "Starter",
	},
	Footgems4000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576623974,
		displayName = "4,000 Footgems",
		description = "More pulls and more flexibility for fast progression.",
		robuxPrice = 99,
		footgems = 4000,
		valueTag = "Bonus Value",
	},
	Footgems8000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576624061,
		displayName = "8,000 Footgems",
		description = "A strong mid-tier pack with noticeably better value.",
		robuxPrice = 179,
		footgems = 8000,
		valueTag = "Better Value",
	},
	Footgems16000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576624171,
		displayName = "16,000 Footgems",
		description = "Big summon sessions with a healthy per-Robux boost.",
		robuxPrice = 329,
		footgems = 16000,
		valueTag = "Great Value",
	},
	Footgems32000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576624263,
		displayName = "32,000 Footgems",
		description = "A deep stockpile built for banner chasing and rerolls.",
		robuxPrice = 599,
		footgems = 32000,
		valueTag = "Huge Value",
	},
	Footgems64000 = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Footgems,
		marketplaceId = 3576624344,
		displayName = "64,000 Footgems",
		description = "The most cost-efficient Footgem pack in the whole shop.",
		robuxPrice = 999,
		footgems = 64000,
		valueTag = "Best Value",
		highlighted = true,
	},
	FootyenGain10xPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1796083712,
		displayName = "Permanent x10 Footyen Gain",
		description = "Multiplies all earned Footyens from running, boots, and pets.",
		robuxPrice = 1299,
		entitlementId = "FootyenGain10x",
	},
	MovementSpeed5xPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1795993674,
		displayName = "Permanent x5 Movement Speed",
		description = "Turns every walk speed upgrade into a much stronger movement spike.",
		robuxPrice = 999,
		entitlementId = "MovementSpeed5x",
	},
	TripleSummonPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1796755552,
		displayName = "3x Summon Unlock",
		description = "Unlocks the 3x summon button on every altar.",
		robuxPrice = 349,
		entitlementId = "TripleSummon",
	},
	ExtraEquipTwoPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1797049563,
		displayName = "+2 Equipped Pets",
		description = "Raises the equip cap by two for a permanent power spike.",
		robuxPrice = 549,
		entitlementId = "ExtraEquipTwo",
	},
	LuckySummonPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1800091132,
		displayName = "Lucky Summon Chance",
		description = "Improves Rare and Legendary summon odds on every altar.",
		robuxPrice = 699,
		entitlementId = "LuckySummon",
	},
	BootMagnetPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1799276213,
		displayName = "Boot Magnet",
		description = "Wider pickup radius and a faster boot field loop.",
		robuxPrice = 399,
		entitlementId = "BootMagnet",
	},
	PetPassiveAuraPass = {
		offerType = "GamePass",
		category = ShopConfig.OfferCategories.GamePasses,
		marketplaceId = 1797501476,
		displayName = "Pet Passive Aura",
		description = "Boosts all pet passive Footyen income forever.",
		robuxPrice = 449,
		entitlementId = "PetPassiveAura",
	},
	ExtraPetSlotsPack = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Stackables,
		marketplaceId = 3576629963,
		displayName = "+5 Pet Slots",
		description = "Permanent and repurchaseable extra space for your collection.",
		robuxPrice = 79,
		stackableId = "ExtraPetSlots",
	},
	PetPassiveOverclockPack = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Stackables,
		marketplaceId = 3576630098,
		displayName = "Pet Passive Overclock",
		description = "Permanent stackable pet passive income boost.",
		robuxPrice = 99,
		stackableId = "PetPassiveOverclock",
	},
	BootValueCorePack = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Stackables,
		marketplaceId = 3576630257,
		displayName = "Boot Value Core",
		description = "Permanent stackable bonus to all boot payouts.",
		robuxPrice = 109,
		stackableId = "BootValueCore",
	},
	GalacticCompanionBundle = {
		offerType = "DeveloperProduct",
		category = ShopConfig.OfferCategories.Featured,
		marketplaceId = 3576623751,
		displayName = "Galactic Companion Bundle",
		description = "A Galactic pet, a permanent +2 equip unlock, and bonus Footgems.",
		robuxPrice = 699,
		highlighted = true,
		bundle = {
			footgems = 8000,
			pets = {
				{ petId = "Galactic", level = 1 },
			},
			entitlements = {
				"ExtraEquipTwo",
			},
		},
	},
}

function ShopConfig.getOrderedOfferIds()
	local result = table.create(#orderedOfferIds)

	for index, offerId in ipairs(orderedOfferIds) do
		result[index] = offerId
	end

	return result
end

function ShopConfig.getOffersByCategory(category)
	local result = {}

	for _, offerId in ipairs(orderedOfferIds) do
		local offer = ShopConfig.Offers[offerId]
		if offer.category == category then
			table.insert(result, offerId)
		end
	end

	return result
end

function ShopConfig.getOffer(offerId)
	local offer = ShopConfig.Offers[offerId]

	if offer == nil then
		error(string.format("Unknown shop offer id '%s'", tostring(offerId)))
	end

	return offer
end

function ShopConfig.getOfferByMarketplaceId(marketplaceId, offerType)
	if typeof(marketplaceId) ~= "number" then
		return nil, nil
	end

	for offerId, offer in pairs(ShopConfig.Offers) do
		if offer.offerType == offerType and offer.marketplaceId == marketplaceId and marketplaceId > 0 then
			return offerId, offer
		end
	end

	return nil, nil
end

function ShopConfig.createDefaultEntitlements()
	local result = {}

	for _, entitlementId in ipairs(ShopConfig.EntitlementIds) do
		result[entitlementId] = false
	end

	return result
end

function ShopConfig.createDefaultStackables()
	local result = {}

	for _, stackableId in ipairs(ShopConfig.StackableIds) do
		result[stackableId] = 0
	end

	return result
end

function ShopConfig.createDefaultRecordedGamePasses()
	local result = {}

	for offerId, offer in pairs(ShopConfig.Offers) do
		if offer.offerType == "GamePass" then
			result[offerId] = false
		end
	end

	return result
end

function ShopConfig.getExtraPetSlots(stackCount)
	local definition = ShopConfig.Stackables.ExtraPetSlots
	return math.max(0, stackCount) * definition.slotIncreasePerStack
end

function ShopConfig.getPetPassiveStackMultiplier(stackCount)
	local definition = ShopConfig.Stackables.PetPassiveOverclock
	return 1 + math.max(0, stackCount) * definition.passiveMultiplierPerStack
end

function ShopConfig.getBootValueStackMultiplier(stackCount)
	local definition = ShopConfig.Stackables.BootValueCore
	return 1 + math.max(0, stackCount) * definition.bootValueMultiplierPerStack
end

return ShopConfig
