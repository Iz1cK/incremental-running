local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local AchievementConfig = require(shared:WaitForChild("AchievementConfig"))
local BootConfig = require(shared:WaitForChild("BootConfig"))
local CurrencyConfig = require(shared:WaitForChild("CurrencyConfig"))
local dataStoreConfig = require(shared:WaitForChild("DataStoreConfig"))
local PetConfig = require(shared:WaitForChild("PetConfig"))
local PrestigeConfig = require(shared:WaitForChild("PrestigeConfig"))
local runRewardsConfig = require(shared:WaitForChild("RunRewardsConfig"))
local ShopConfig = require(shared:WaitForChild("ShopConfig"))
local SummonConfig = require(shared:WaitForChild("SummonConfig"))
local upgradeConfig = require(shared:WaitForChild("UpgradeConfig"))
local WorldConfig = require(shared:WaitForChild("WorldConfig"))
local network = require(shared:WaitForChild("ZapServer"))

local random = Random.new()
local playerStates = {}
local playerDataStore = DataStoreService:GetDataStore(dataStoreConfig.STORE_NAME, dataStoreConfig.STORE_SCOPE)
local persistenceDisabledReason = nil
local nextAutosaveAt = 0
local applyMovementSpeed
local sendStateSnapshot
local sendPetInventorySnapshot
local sendAchievementSnapshot
local refreshGamePassOwnership

local bootFolder = Workspace:FindFirstChild(BootConfig.COLLECTION_FOLDER_NAME)
if bootFolder == nil then
	bootFolder = Instance.new("Folder")
	bootFolder.Name = BootConfig.COLLECTION_FOLDER_NAME
	bootFolder.Parent = Workspace
end

local function createValueObject(className, parent, name, startingValue)
	local valueObject = Instance.new(className)
	valueObject.Name = name
	valueObject.Value = startingValue
	valueObject.Parent = parent

	return valueObject
end

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	return {
		footyens = createValueObject("IntValue", leaderstats, CurrencyConfig.FOOTYEN_NAME, CurrencyConfig.STARTING_FOOTYENS),
		footgems = createValueObject("IntValue", leaderstats, CurrencyConfig.FOOTGEM_NAME, CurrencyConfig.STARTING_FOOTGEMS),
	}
end

local function getServerNow()
	return workspace:GetServerTimeNow()
end

local function markStateDirty(state)
	state.isDirty = true
	state.dirtyToken = state.dirtyToken + 1

	local saveDeadline = getServerNow() + dataStoreConfig.DIRTY_SAVE_DELAY
	if state.nextBackgroundSaveAt == 0 then
		state.nextBackgroundSaveAt = saveDeadline
	else
		state.nextBackgroundSaveAt = math.min(state.nextBackgroundSaveAt, saveDeadline)
	end
end

local function shouldDisablePersistenceForError(errorMessage)
	if not RunService:IsStudio() then
		return false
	end

	local normalizedMessage = string.lower(errorMessage)

	return string.find(normalizedMessage, "studioaccesstoapisnotallowed", 1, true) ~= nil
		or string.find(normalizedMessage, "access to this api has been disabled", 1, true) ~= nil
		or string.find(normalizedMessage, "must publish this place", 1, true) ~= nil
		or string.find(normalizedMessage, "cannot store data in studio", 1, true) ~= nil
end

local function disablePersistence(reason)
	if persistenceDisabledReason ~= nil then
		return
	end

	persistenceDisabledReason = reason
	warn(string.format("[FootyenService] Persistence disabled for this server: %s", reason))
end

local function runDataStoreRequest(maxAttempts, callback)
	if persistenceDisabledReason ~= nil then
		return false, persistenceDisabledReason
	end

	local lastErrorMessage = "Unknown DataStore failure."

	for attempt = 1, maxAttempts do
		local success, result = pcall(callback)
		if success then
			return true, result
		end

		lastErrorMessage = tostring(result)
		if shouldDisablePersistenceForError(lastErrorMessage) then
			disablePersistence(lastErrorMessage)
			return false, lastErrorMessage
		end

		if attempt < maxAttempts then
			task.wait(dataStoreConfig.RETRY_DELAY_SECONDS * attempt)
		end
	end

	return false, lastErrorMessage
end

local function sanitizeNumber(value, defaultValue, minValue, maxValue)
	local sanitizedValue = value

	if typeof(sanitizedValue) ~= "number" or sanitizedValue ~= sanitizedValue or sanitizedValue == math.huge or sanitizedValue == -math.huge then
		sanitizedValue = defaultValue
	end

	if minValue ~= nil then
		sanitizedValue = math.max(minValue, sanitizedValue)
	end

	if maxValue ~= nil then
		sanitizedValue = math.min(maxValue, sanitizedValue)
	end

	return sanitizedValue
end

local function sanitizeInteger(value, defaultValue, minValue, maxValue)
	return math.floor(sanitizeNumber(value, defaultValue, minValue, maxValue))
end

local function clonePets(pets)
	local clonedPets = table.create(#pets)

	for index, pet in ipairs(pets) do
		clonedPets[index] = {
			uid = pet.uid,
			petId = pet.petId,
			level = pet.level,
			isEquipped = pet.isEquipped,
		}
	end

	return clonedPets
end

local function cloneBooleanMap(source)
	local result = {}

	for key, value in pairs(source) do
		result[key] = value == true
	end

	return result
end

local function cloneNumberMap(source)
	return table.clone(source)
end

local function createDefaultWorldUnlocks()
	local result = {}

	for _, worldId in ipairs(WorldConfig.WorldOrder) do
		result[worldId] = worldId == WorldConfig.DEFAULT_WORLD_ID
	end

	return result
end

local function sanitizeAchievementClaims(rawClaims)
	local result = AchievementConfig.createDefaultClaimState()

	if typeof(rawClaims) ~= "table" then
		return result
	end

	for _, achievementId in ipairs(AchievementConfig.getOrderedAchievementIds()) do
		result[achievementId] = rawClaims[achievementId] == true
	end

	return result
end

local function sanitizeWorldUnlocks(rawWorldUnlocks)
	local result = createDefaultWorldUnlocks()

	if typeof(rawWorldUnlocks) == "table" then
		for _, worldId in ipairs(WorldConfig.WorldOrder) do
			if rawWorldUnlocks[worldId] ~= nil then
				result[worldId] = rawWorldUnlocks[worldId] == true
			end
		end
	end

	result[WorldConfig.DEFAULT_WORLD_ID] = true

	return result
end

local function createPurchaseHistoryEntry(sourceType, offerId, purchaseId, details, grantedAtUnix)
	local offer = ShopConfig.Offers[offerId]

	return {
		sourceType = sourceType,
		offerId = offerId,
		offerType = offer and offer.offerType or "Unknown",
		displayName = offer and offer.displayName or tostring(offerId),
		marketplaceId = offer and offer.marketplaceId or 0,
		robuxPrice = offer and offer.robuxPrice or 0,
		purchaseId = purchaseId,
		details = string.sub(details or "", 1, ShopConfig.REFUND_NOTE_LIMIT),
		grantedAtUnix = grantedAtUnix or os.time(),
	}
end

local function createGeneratedPetUid(userId, serial)
	return string.format("%d-%04d", userId, serial)
end

local function buildSavePayload(state)
	return {
		version = dataStoreConfig.DATA_VERSION,
		savedAtUnix = os.time(),
		footyens = state.footyens.Value,
		footgems = state.footgems.Value,
		footcores = state.footcores,
		totalDistance = state.totalDistance,
		totalSummons = state.totalSummons,
		bootsCollected = state.bootsCollected,
		rebirthCount = state.rebirthCount,
		worldUnlocks = cloneBooleanMap(state.worldUnlocks),
		achievementClaims = cloneBooleanMap(state.achievementClaims),
		pendingStuds = state.pendingStuds,
		pendingPayout = state.pendingPayout,
		upgrades = table.clone(state.upgradeLevels),
		bootUpgrades = table.clone(state.bootUpgradeLevels),
		nextPetSerial = state.nextPetSerial,
		pets = clonePets(state.pets),
		shop = {
			permanentEntitlements = cloneBooleanMap(state.permanentEntitlements),
			gamePassOwnership = cloneBooleanMap(state.gamePassOwnership),
			stackableCounts = cloneNumberMap(state.stackableCounts),
			recordedGamePasses = cloneBooleanMap(state.recordedGamePasses),
			processedReceipts = cloneBooleanMap(state.processedReceipts),
			processedReceiptOrder = table.clone(state.processedReceiptOrder),
			purchaseHistory = table.clone(state.purchaseHistory),
		},
	}
end

local function deserializeSavePayload(userId, payload)
	local upgrades = typeof(payload) == "table" and payload.upgrades or nil
	local bootUpgrades = typeof(payload) == "table" and payload.bootUpgrades or nil
	local rawPets = typeof(payload) == "table" and payload.pets or nil
	local rawShop = typeof(payload) == "table" and payload.shop or nil
	local rawWorldUnlocks = typeof(payload) == "table" and payload.worldUnlocks or nil
	local rawAchievementClaims = typeof(payload) == "table" and payload.achievementClaims or nil
	local runUpgradeLevels = {}
	local loadedBootUpgradeLevels = {}
	local loadedEntitlements = ShopConfig.createDefaultEntitlements()
	local loadedGamePassOwnership = ShopConfig.createDefaultEntitlements()
	local loadedStackableCounts = ShopConfig.createDefaultStackables()
	local loadedRecordedGamePasses = ShopConfig.createDefaultRecordedGamePasses()
	local loadedProcessedReceipts = {}
	local loadedProcessedReceiptOrder = {}
	local loadedPurchaseHistory = {}
	local loadedPets = {}
	local usedPetUids = {}
	local equippedPetCount = 0
	local highestPetSerial = 0

	for upgradeId, definition in pairs(upgradeConfig.Upgrades) do
		local rawLevel = upgrades and upgrades[upgradeId] or 0
		runUpgradeLevels[upgradeId] = sanitizeInteger(rawLevel, 0, 0, definition.maxLevel)
	end

	for upgradeId, definition in pairs(BootConfig.Upgrades) do
		local rawLevel = bootUpgrades and bootUpgrades[upgradeId] or 0
		loadedBootUpgradeLevels[upgradeId] = sanitizeInteger(rawLevel, 0, 0, definition.maxLevel)
	end

	if typeof(rawShop) == "table" then
		local rawEntitlements = typeof(rawShop.permanentEntitlements) == "table" and rawShop.permanentEntitlements or nil
		local rawGamePassOwnership = typeof(rawShop.gamePassOwnership) == "table" and rawShop.gamePassOwnership or nil
		local rawStackableCounts = typeof(rawShop.stackableCounts) == "table" and rawShop.stackableCounts or nil
		local rawRecordedGamePasses = typeof(rawShop.recordedGamePasses) == "table" and rawShop.recordedGamePasses or nil
		local rawProcessedReceipts = typeof(rawShop.processedReceipts) == "table" and rawShop.processedReceipts or nil
		local rawProcessedReceiptOrder = typeof(rawShop.processedReceiptOrder) == "table" and rawShop.processedReceiptOrder or nil
		local rawPurchaseHistory = typeof(rawShop.purchaseHistory) == "table" and rawShop.purchaseHistory or nil

		for _, entitlementId in ipairs(ShopConfig.EntitlementIds) do
			loadedEntitlements[entitlementId] = rawEntitlements and rawEntitlements[entitlementId] == true or false
			loadedGamePassOwnership[entitlementId] = rawGamePassOwnership and rawGamePassOwnership[entitlementId] == true or false
		end

		for _, stackableId in ipairs(ShopConfig.StackableIds) do
			loadedStackableCounts[stackableId] = sanitizeInteger(
				rawStackableCounts and rawStackableCounts[stackableId] or 0,
				0,
				0,
				500
			)
		end

		for offerId, offer in pairs(ShopConfig.Offers) do
			if offer.offerType == "GamePass" then
				loadedRecordedGamePasses[offerId] = rawRecordedGamePasses and rawRecordedGamePasses[offerId] == true or false
			end
		end

		if rawProcessedReceiptOrder then
			for _, purchaseId in ipairs(rawProcessedReceiptOrder) do
				if typeof(purchaseId) == "string" and purchaseId ~= "" and loadedProcessedReceipts[purchaseId] == nil then
					loadedProcessedReceipts[purchaseId] = true
					table.insert(loadedProcessedReceiptOrder, purchaseId)
				end
			end
		elseif rawProcessedReceipts then
			for purchaseId, _ in pairs(rawProcessedReceipts) do
				if typeof(purchaseId) == "string" and purchaseId ~= "" and loadedProcessedReceipts[purchaseId] == nil then
					loadedProcessedReceipts[purchaseId] = true
					table.insert(loadedProcessedReceiptOrder, purchaseId)
				end
			end
		end

		while #loadedProcessedReceiptOrder > ShopConfig.PROCESSED_RECEIPT_LIMIT do
			local expiredPurchaseId = table.remove(loadedProcessedReceiptOrder, 1)
			if expiredPurchaseId ~= nil then
				loadedProcessedReceipts[expiredPurchaseId] = nil
			end
		end

		if rawPurchaseHistory then
			for _, entry in ipairs(rawPurchaseHistory) do
				if typeof(entry) == "table" then
					table.insert(loadedPurchaseHistory, createPurchaseHistoryEntry(
						typeof(entry.sourceType) == "string" and entry.sourceType or "Legacy",
						typeof(entry.offerId) == "string" and entry.offerId or "Unknown",
						typeof(entry.purchaseId) == "string" and entry.purchaseId or "",
						typeof(entry.details) == "string" and entry.details or "",
						sanitizeInteger(entry.grantedAtUnix, os.time(), 0)
					))
				end
			end
		end

		while #loadedPurchaseHistory > ShopConfig.PURCHASE_HISTORY_LIMIT do
			table.remove(loadedPurchaseHistory, 1)
		end
	end

	local loadedPetInventoryLimit = PetConfig.INVENTORY_LIMIT + ShopConfig.getExtraPetSlots(loadedStackableCounts.ExtraPetSlots)
	local loadedEquipLimit = PetConfig.EQUIP_LIMIT
	if loadedEntitlements.ExtraEquipTwo or loadedGamePassOwnership.ExtraEquipTwo then
		loadedEquipLimit = loadedEquipLimit + 2
	end

	if typeof(rawPets) == "table" then
		for _, rawPet in ipairs(rawPets) do
			if #loadedPets >= loadedPetInventoryLimit then
				break
			end

			local resolvedPetId = typeof(rawPet) == "table" and PetConfig.resolvePetId(rawPet.petId) or nil
			if typeof(rawPet) == "table" and resolvedPetId ~= nil then
				local petUid = typeof(rawPet.uid) == "string" and rawPet.uid or ""
				if petUid == "" or usedPetUids[petUid] then
					highestPetSerial = highestPetSerial + 1
					petUid = createGeneratedPetUid(userId, highestPetSerial)
				end

				usedPetUids[petUid] = true

				local trailingSerial = tonumber(string.match(petUid, "%-(%d+)$"))
				if trailingSerial ~= nil then
					highestPetSerial = math.max(highestPetSerial, trailingSerial)
				end

				local isEquipped = rawPet.isEquipped == true and equippedPetCount < loadedEquipLimit
				if isEquipped then
					equippedPetCount = equippedPetCount + 1
				end

				table.insert(loadedPets, {
					uid = petUid,
					petId = resolvedPetId,
					level = PetConfig.clampLevel(rawPet.level),
					isEquipped = isEquipped,
				})
			end
		end
	end

	local nextPetSerial = sanitizeInteger(
		typeof(payload) == "table" and payload.nextPetSerial or highestPetSerial + 1,
		highestPetSerial + 1,
		highestPetSerial + 1,
		999999
	)

	return {
		footyens = sanitizeInteger(typeof(payload) == "table" and payload.footyens or CurrencyConfig.STARTING_FOOTYENS, CurrencyConfig.STARTING_FOOTYENS, 0),
		footgems = sanitizeInteger(typeof(payload) == "table" and payload.footgems or CurrencyConfig.STARTING_FOOTGEMS, CurrencyConfig.STARTING_FOOTGEMS, 0),
		footcores = sanitizeInteger(typeof(payload) == "table" and payload.footcores or 0, 0, 0),
		totalDistance = sanitizeNumber(typeof(payload) == "table" and payload.totalDistance or 0, 0, 0),
		totalSummons = sanitizeInteger(typeof(payload) == "table" and payload.totalSummons or 0, 0, 0),
		bootsCollected = sanitizeInteger(typeof(payload) == "table" and payload.bootsCollected or 0, 0, 0),
		rebirthCount = sanitizeInteger(typeof(payload) == "table" and payload.rebirthCount or 0, 0, 0),
		worldUnlocks = sanitizeWorldUnlocks(rawWorldUnlocks),
		achievementClaims = sanitizeAchievementClaims(rawAchievementClaims),
		pendingStuds = sanitizeNumber(typeof(payload) == "table" and payload.pendingStuds or 0, 0, 0),
		pendingPayout = sanitizeNumber(typeof(payload) == "table" and payload.pendingPayout or 0, 0, 0, 0.999999),
		upgradeLevels = runUpgradeLevels,
		bootUpgradeLevels = loadedBootUpgradeLevels,
		nextPetSerial = nextPetSerial,
		pets = loadedPets,
		permanentEntitlements = loadedEntitlements,
		gamePassOwnership = loadedGamePassOwnership,
		stackableCounts = loadedStackableCounts,
		recordedGamePasses = loadedRecordedGamePasses,
		processedReceipts = loadedProcessedReceipts,
		processedReceiptOrder = loadedProcessedReceiptOrder,
		purchaseHistory = loadedPurchaseHistory,
	}
end

local function getUpgradeValue(state, upgradeId)
	return upgradeConfig.getValue(upgradeId, state.upgradeLevels[upgradeId])
end

local function getBootUpgradeValue(state, upgradeId)
	return BootConfig.getValue(upgradeId, state.bootUpgradeLevels[upgradeId])
end

local function appendPurchaseHistory(state, sourceType, offerId, purchaseId, details)
	table.insert(state.purchaseHistory, createPurchaseHistoryEntry(sourceType, offerId, purchaseId, details))

	while #state.purchaseHistory > ShopConfig.PURCHASE_HISTORY_LIMIT do
		table.remove(state.purchaseHistory, 1)
	end
end

local function rememberProcessedReceipt(state, purchaseId, offerId)
	if purchaseId == nil or purchaseId == "" then
		return
	end

	if state.processedReceipts[purchaseId] ~= nil then
		return
	end

	state.processedReceipts[purchaseId] = offerId or true
	table.insert(state.processedReceiptOrder, purchaseId)

	while #state.processedReceiptOrder > ShopConfig.PROCESSED_RECEIPT_LIMIT do
		local expiredPurchaseId = table.remove(state.processedReceiptOrder, 1)
		if expiredPurchaseId ~= nil then
			state.processedReceipts[expiredPurchaseId] = nil
		end
	end
end

local function hasEntitlement(state, entitlementId)
	return state.permanentEntitlements[entitlementId] == true or state.gamePassOwnership[entitlementId] == true
end

local function getStackableCount(state, stackableId)
	return state.stackableCounts[stackableId] or 0
end

local function getPetInventoryLimit(state)
	return PetConfig.INVENTORY_LIMIT + ShopConfig.getExtraPetSlots(getStackableCount(state, "ExtraPetSlots"))
end

local function getPetEquipLimit(state)
	local equipLimit = PetConfig.EQUIP_LIMIT
	if hasEntitlement(state, "ExtraEquipTwo") then
		equipLimit = equipLimit + 2
	end

	return equipLimit
end

local function getEffectiveMovementSpeed(state)
	local walkSpeed = getUpgradeValue(state, "MovementSpeed")

	if hasEntitlement(state, "MovementSpeed5x") then
		walkSpeed = walkSpeed * 5
	end

	if state.isSprinting then
		walkSpeed = walkSpeed * runRewardsConfig.SPRINT_MULTIPLIER
	end

	return walkSpeed
end

local function getEffectiveCurrencyMultiplier(state)
	local multiplier = getUpgradeValue(state, "CurrencyMultiplier")

	if hasEntitlement(state, "FootyenGain10x") then
		multiplier = multiplier * 10
	end

	return multiplier
end

local function getEffectiveBootSpawnInterval(state)
	local spawnInterval = getBootUpgradeValue(state, "SpawnRate")

	if hasEntitlement(state, "BootMagnet") then
		local entitlement = ShopConfig.Entitlements.BootMagnet
		spawnInterval = spawnInterval * (entitlement.spawnIntervalMultiplier or 1)
	end

	return spawnInterval
end

local function getEffectiveBootPickupRadius(state)
	local pickupRadius = getBootUpgradeValue(state, "PickupRadius")

	if hasEntitlement(state, "BootMagnet") then
		local entitlement = ShopConfig.Entitlements.BootMagnet
		pickupRadius = pickupRadius * (entitlement.pickupRadiusMultiplier or 1)
	end

	return pickupRadius
end

local function getEffectiveBootValue(state)
	local bootValue = getBootUpgradeValue(state, "BootValue")
	bootValue = bootValue * ShopConfig.getBootValueStackMultiplier(getStackableCount(state, "BootValueCore"))

	if hasEntitlement(state, "FootyenGain10x") then
		bootValue = bootValue * 10
	end

	return bootValue
end

local function getEffectivePetPassivePerSecond(state)
	local passivePerSecond = state.totalPetPassivePerSecond

	if hasEntitlement(state, "PetPassiveAura") then
		passivePerSecond = passivePerSecond * (ShopConfig.Entitlements.PetPassiveAura.passiveMultiplier or 1)
	end

	passivePerSecond = passivePerSecond * ShopConfig.getPetPassiveStackMultiplier(getStackableCount(state, "PetPassiveOverclock"))

	if hasEntitlement(state, "FootyenGain10x") then
		passivePerSecond = passivePerSecond * 10
	end

	return passivePerSecond
end

local function enforcePetEquipLimit(state)
	local equipLimit = getPetEquipLimit(state)
	local equippedCount = 0

	for _, pet in ipairs(state.pets) do
		if pet.isEquipped then
			equippedCount = equippedCount + 1
			if equippedCount > equipLimit then
				pet.isEquipped = false
			end
		end
	end
end

local function recalculatePetBonuses(state)
	enforcePetEquipLimit(state)

	local totalMultiplier = 1
	local totalPassivePerSecond = 0
	local equippedPetCount = 0

	for _, pet in ipairs(state.pets) do
		if pet.isEquipped then
			equippedPetCount = equippedPetCount + 1

			local multiplier, passivePerSecond = PetConfig.getBoosts(pet.petId, pet.level)
			totalMultiplier = totalMultiplier * multiplier
			totalPassivePerSecond = totalPassivePerSecond + passivePerSecond
		end
	end

	state.equippedPetCount = equippedPetCount
	state.totalPetMultiplier = totalMultiplier
	state.totalPetPassivePerSecond = totalPassivePerSecond
end

local function getPetSortScore(pet)
	local definition = PetConfig.getDefinition(pet.petId)
	local rarityWeight = SummonConfig.RarityOrder[definition.rarity] or 0
	local multiplier, passivePerSecond = PetConfig.getBoosts(pet.petId, pet.level)

	return rarityWeight * 100000 + pet.level * 1000 + multiplier * 100 + passivePerSecond
end

local function sortPets(state)
	table.sort(state.pets, function(left, right)
		if left.isEquipped ~= right.isEquipped then
			return left.isEquipped
		end

		local leftScore = getPetSortScore(left)
		local rightScore = getPetSortScore(right)
		if leftScore ~= rightScore then
			return leftScore > rightScore
		end

		if left.petId ~= right.petId then
			return left.petId < right.petId
		end

		return left.uid < right.uid
	end)
end

local function createPetRecord(state, petId, level, isEquipped)
	local pet = {
		uid = createGeneratedPetUid(state.player.UserId, state.nextPetSerial),
		petId = petId,
		level = PetConfig.clampLevel(level),
		isEquipped = isEquipped == true,
	}

	state.nextPetSerial = state.nextPetSerial + 1
	table.insert(state.pets, pet)
	sortPets(state)

	return pet
end

local function findPetByUid(state, petUid)
	for index, pet in ipairs(state.pets) do
		if pet.uid == petUid then
			return pet, index
		end
	end

	return nil, nil
end

local function removePetByUid(state, petUid)
	local _, index = findPetByUid(state, petUid)
	if index == nil then
		return false
	end

	table.remove(state.pets, index)
	return true
end

local function createAutoDeleteLookup(altar, rawAutoDeletePetIds)
	local lookup = {}
	local validPoolPetIds = {}

	for _, entry in ipairs(altar.pool) do
		validPoolPetIds[entry.petId] = true
	end

	if typeof(rawAutoDeletePetIds) ~= "table" then
		return lookup
	end

	for _, rawPetId in ipairs(rawAutoDeletePetIds) do
		local resolvedPetId = typeof(rawPetId) == "string" and PetConfig.resolvePetId(rawPetId) or nil
		if resolvedPetId ~= nil and validPoolPetIds[resolvedPetId] then
			lookup[resolvedPetId] = true
		end
	end

	return lookup
end

local function rollSummonEntry(state, altar, minimumRarity)
	local eligibleEntries = {}
	local totalWeight = 0

	for _, entry in ipairs(altar.pool) do
		if minimumRarity == nil or SummonConfig.isAtLeastRarity(entry.rarity, minimumRarity) then
			local entryWeight = entry.probability

			if hasEntitlement(state, "LuckySummon") then
				local multipliers = ShopConfig.Entitlements.LuckySummon.luckyWeightMultipliers
				entryWeight = entryWeight * (multipliers[entry.rarity] or 1)
			end

			totalWeight = totalWeight + entryWeight
			table.insert(eligibleEntries, {
				entry = entry,
				weight = entryWeight,
			})
		end
	end

	if totalWeight <= 0 then
		return nil
	end

	local roll = random:NextNumber(0, totalWeight)
	local cumulativeWeight = 0

	for _, weightedEntry in ipairs(eligibleEntries) do
		cumulativeWeight = cumulativeWeight + weightedEntry.weight
		if roll <= cumulativeWeight then
			return weightedEntry.entry
		end
	end

	return eligibleEntries[#eligibleEntries].entry
end

local function getSpawnOrigin(state)
	if state.rootPart and state.rootPart:IsDescendantOf(Workspace) then
		return state.rootPart.Position
	end

	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		return spawnLocation.Position
	end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		return Vector3.new(baseplate.Position.X, baseplate.Position.Y + baseplate.Size.Y * 0.5, baseplate.Position.Z)
	end

	return Vector3.zero
end

local function countUnlockedWorlds(state)
	local unlockedCount = 0

	for _, worldId in ipairs(WorldConfig.WorldOrder) do
		if state.worldUnlocks[worldId] == true then
			unlockedCount = unlockedCount + 1
		end
	end

	return unlockedCount
end

local function countLegendaryPets(state)
	local legendaryCount = 0

	for _, pet in ipairs(state.pets) do
		local definition = PetConfig.getDefinition(pet.petId)
		if definition.rarity == "Legendary" then
			legendaryCount = legendaryCount + 1
		end
	end

	return legendaryCount
end

local function getAchievementProgressValue(state, achievementType)
	if achievementType == "TotalDistance" then
		return state.totalDistance
	end

	if achievementType == "TotalSummons" then
		return state.totalSummons
	end

	if achievementType == "LegendaryPetsOwned" then
		return countLegendaryPets(state)
	end

	if achievementType == "BootsCollected" then
		return state.bootsCollected
	end

	if achievementType == "RebirthCount" then
		return state.rebirthCount
	end

	if achievementType == "WorldsUnlocked" then
		return countUnlockedWorlds(state)
	end

	return 0
end

local function serializeAchievements(state)
	local achievements = table.create(#AchievementConfig.ORDERED_ACHIEVEMENT_IDS)
	local completedAchievementCount = 0
	local claimedAchievementCount = 0

	for index, achievementId in ipairs(AchievementConfig.ORDERED_ACHIEVEMENT_IDS) do
		local definition = AchievementConfig.getAchievement(achievementId)
		local progress = getAchievementProgressValue(state, definition.type)
		local isComplete = progress >= definition.target
		local isClaimed = state.achievementClaims[achievementId] == true

		if isComplete then
			completedAchievementCount = completedAchievementCount + 1
		end

		if isClaimed then
			claimedAchievementCount = claimedAchievementCount + 1
		end

		achievements[index] = {
			id = achievementId,
			displayName = definition.displayName,
			description = definition.description,
			type = definition.type,
			progress = progress,
			target = definition.target,
			isComplete = isComplete,
			isClaimed = isClaimed,
			rewardFootgems = sanitizeInteger(definition.reward and definition.reward.footgems or 0, 0, 0),
			rewardFootcores = sanitizeInteger(definition.reward and definition.reward.footcores or 0, 0, 0),
		}
	end

	return {
		achievementCount = #achievements,
		completedAchievementCount = completedAchievementCount,
		claimedAchievementCount = claimedAchievementCount,
		achievements = achievements,
	}
end

local function serializeState(state)
	return {
		footyens = state.footyens.Value,
		footgems = state.footgems.Value,
		totalDistance = state.totalDistance,
		bootsCollected = state.bootsCollected,
		activeBoots = math.min(255, #state.activeBoots),
		movementSpeedLevel = state.upgradeLevels.MovementSpeed,
		studsPerCurrencyLevel = state.upgradeLevels.StudsPerCurrency,
		currencyMultiplierLevel = state.upgradeLevels.CurrencyMultiplier,
		bootValueLevel = state.bootUpgradeLevels.BootValue,
		spawnRateLevel = state.bootUpgradeLevels.SpawnRate,
		maxActiveBootsLevel = state.bootUpgradeLevels.MaxActiveBoots,
		pickupRadiusLevel = state.bootUpgradeLevels.PickupRadius,
		bootLifetimeLevel = state.bootUpgradeLevels.BootLifetime,
		goldenChanceLevel = state.bootUpgradeLevels.GoldenChance,
		goldenMultiplierLevel = state.bootUpgradeLevels.GoldenMultiplier,
		movementSpeed = getEffectiveMovementSpeed(state),
		studsPerCurrency = getUpgradeValue(state, "StudsPerCurrency"),
		currencyMultiplier = getEffectiveCurrencyMultiplier(state),
		bootValue = getEffectiveBootValue(state),
		bootSpawnInterval = getEffectiveBootSpawnInterval(state),
		bootMaxActive = math.round(getBootUpgradeValue(state, "MaxActiveBoots")),
		bootPickupRadius = getEffectiveBootPickupRadius(state),
		bootLifetime = getBootUpgradeValue(state, "BootLifetime"),
		bootGoldenChance = getBootUpgradeValue(state, "GoldenChance"),
		bootGoldenMultiplier = getBootUpgradeValue(state, "GoldenMultiplier"),
		petInventoryLimit = getPetInventoryLimit(state),
		petEmptySlots = math.max(0, getPetInventoryLimit(state) - #state.pets),
		petInventoryCount = math.min(255, #state.pets),
		petEquipLimit = getPetEquipLimit(state),
		equippedPetCount = state.equippedPetCount,
		petFootyenMultiplier = state.totalPetMultiplier,
		petPassivePerSecond = getEffectivePetPassivePerSecond(state),
		shopHasFootyenGain10x = hasEntitlement(state, "FootyenGain10x"),
		shopHasMovementSpeed5x = hasEntitlement(state, "MovementSpeed5x"),
		shopHasTripleSummon = hasEntitlement(state, "TripleSummon"),
		shopHasExtraEquipTwo = hasEntitlement(state, "ExtraEquipTwo"),
		shopHasLuckySummon = hasEntitlement(state, "LuckySummon"),
		shopHasBootMagnet = hasEntitlement(state, "BootMagnet"),
		shopHasPetPassiveAura = hasEntitlement(state, "PetPassiveAura"),
		shopExtraPetSlotsCount = math.min(65535, getStackableCount(state, "ExtraPetSlots")),
		shopPetPassiveOverclockCount = math.min(255, getStackableCount(state, "PetPassiveOverclock")),
		shopBootValueCoreCount = math.min(255, getStackableCount(state, "BootValueCore")),
		isSprinting = state.isSprinting,
		sprintEndsAt = state.sprintEndsAt,
		cooldownEndsAt = state.sprintCooldownEndsAt,
	}
end

local function serializePetInventory(state)
	return {
		petInventoryLimit = getPetInventoryLimit(state),
		petEmptySlots = math.max(0, getPetInventoryLimit(state) - #state.pets),
		petInventoryCount = math.min(255, #state.pets),
		petEquipLimit = getPetEquipLimit(state),
		equippedPetCount = state.equippedPetCount,
		pets = clonePets(state.pets),
	}
end

local function applyLoadedData(state, loadedData)
	state.footyens.Value = loadedData.footyens
	state.footgems.Value = loadedData.footgems
	state.footcores = loadedData.footcores
	state.totalDistance = loadedData.totalDistance
	state.totalSummons = loadedData.totalSummons
	state.bootsCollected = loadedData.bootsCollected
	state.rebirthCount = loadedData.rebirthCount
	state.worldUnlocks = cloneBooleanMap(loadedData.worldUnlocks)
	state.achievementClaims = cloneBooleanMap(loadedData.achievementClaims)
	state.pendingStuds = loadedData.pendingStuds
	state.pendingPayout = loadedData.pendingPayout
	state.nextPetSerial = loadedData.nextPetSerial
	state.pets = clonePets(loadedData.pets)
	state.permanentEntitlements = cloneBooleanMap(loadedData.permanentEntitlements)
	state.gamePassOwnership = cloneBooleanMap(loadedData.gamePassOwnership)
	state.stackableCounts = cloneNumberMap(loadedData.stackableCounts)
	state.recordedGamePasses = cloneBooleanMap(loadedData.recordedGamePasses)
	state.processedReceipts = cloneBooleanMap(loadedData.processedReceipts)
	state.processedReceiptOrder = table.clone(loadedData.processedReceiptOrder)
	state.purchaseHistory = table.clone(loadedData.purchaseHistory)
	sortPets(state)

	for upgradeId, level in pairs(loadedData.upgradeLevels) do
		state.upgradeLevels[upgradeId] = level
	end

	for upgradeId, level in pairs(loadedData.bootUpgradeLevels) do
		state.bootUpgradeLevels[upgradeId] = level
	end

	recalculatePetBonuses(state)

	state.isLoaded = true
	state.isDirty = false
	state.pendingSaveRequested = false
	applyMovementSpeed(state)
	sendStateSnapshot(state)
	sendPetInventorySnapshot(state)
	sendAchievementSnapshot(state)
	task.spawn(refreshGamePassOwnership, state, true)
end

local function commitPetInventoryChange(state)
	sortPets(state)
	recalculatePetBonuses(state)
	markStateDirty(state)
	sendStateSnapshot(state)
	sendPetInventorySnapshot(state)
end

local function savePlayerData(state, reason, forceSave)
	if state == nil or not state.isLoaded or persistenceDisabledReason ~= nil then
		return false
	end

	if state.isSaving then
		state.pendingSaveRequested = true
		return false
	end

	if not forceSave and not state.isDirty then
		return true
	end

	state.isSaving = true
	local payload = buildSavePayload(state)
	local saveToken = state.dirtyToken
	local key = dataStoreConfig.getKeyForUserId(state.player.UserId)
	local success, result = runDataStoreRequest(dataStoreConfig.SAVE_RETRY_COUNT, function()
		return playerDataStore:UpdateAsync(key, function()
			return payload
		end)
	end)

	state.isSaving = false

	if success then
		state.lastSaveAt = getServerNow()

		if state.dirtyToken == saveToken then
			state.isDirty = false
			state.nextBackgroundSaveAt = 0
		end
	else
		warn(string.format("[FootyenService] Failed to save %s for %s: %s", reason, state.player.Name, tostring(result)))
	end

	if state.pendingSaveRequested and playerStates[state.player] == state then
		state.pendingSaveRequested = false

		if state.isDirty then
			task.spawn(savePlayerData, state, "queued save", true)
		end
	end

	return success
end

local function loadPlayerData(state)
	local success = true
	local result = nil

	if persistenceDisabledReason == nil then
		local key = dataStoreConfig.getKeyForUserId(state.player.UserId)
		success, result = runDataStoreRequest(dataStoreConfig.LOAD_RETRY_COUNT, function()
			return playerDataStore:GetAsync(key)
		end)
	end

	if playerStates[state.player] ~= state then
		return
	end

	if not success then
		warn(string.format("[FootyenService] Failed to load data for %s: %s", state.player.Name, tostring(result)))
		result = nil
	end

	applyLoadedData(state, deserializeSavePayload(state.player.UserId, result))
end

sendStateSnapshot = function(_state)
	return nil
end

sendPetInventorySnapshot = function(_state)
	return nil
end

sendAchievementSnapshot = function(_state)
	return nil
end

applyMovementSpeed = function(state)
	if state.humanoid == nil then
		return
	end

	state.humanoid.WalkSpeed = getEffectiveMovementSpeed(state)
end

local function awardFootyens(state, amount, shouldApplyPetMultiplier)
	if amount <= 0 then
		return 0
	end

	local payout = amount
	if shouldApplyPetMultiplier then
		payout = payout * state.totalPetMultiplier
	end

	payout = payout + state.pendingPayout

	local earnedFootyens = math.floor(payout)
	state.pendingPayout = payout - earnedFootyens

	if earnedFootyens > 0 then
		state.footyens.Value = state.footyens.Value + earnedFootyens
	end

	return earnedFootyens
end

local function canAffordFootgems(state, amount)
	return state.footgems.Value >= amount
end

local function spendFootgems(state, amount)
	if amount <= 0 then
		return true
	end

	if not canAffordFootgems(state, amount) then
		return false
	end

	state.footgems.Value = state.footgems.Value - amount

	return true
end

local function grantFootgems(state, amount)
	if amount <= 0 then
		return
	end

	state.footgems.Value = state.footgems.Value + amount
	markStateDirty(state)
	sendStateSnapshot(state)
end

local function syncShopDerivedState(state)
	sortPets(state)
	recalculatePetBonuses(state)
	applyMovementSpeed(state)
	sendStateSnapshot(state)
	sendPetInventorySnapshot(state)
end

local function grantPermanentEntitlement(state, entitlementId, sourceType, offerId, purchaseId, details)
	if state.permanentEntitlements[entitlementId] == true then
		return false
	end

	state.permanentEntitlements[entitlementId] = true
	appendPurchaseHistory(state, sourceType, offerId, purchaseId, details)
	return true
end

local function grantStackable(state, stackableId, amount, sourceType, offerId, purchaseId, details)
	state.stackableCounts[stackableId] = (state.stackableCounts[stackableId] or 0) + amount
	appendPurchaseHistory(
		state,
		sourceType,
		offerId,
		purchaseId,
		string.format(
			"%s Total owned: %d",
			details,
			state.stackableCounts[stackableId]
		)
	)
end

local function grantPurchasedPet(state, petId, level, sourceType, offerId, purchaseId)
	if #state.pets >= getPetInventoryLimit(state) then
		local compensation = 12000
		grantFootgems(state, compensation)
		appendPurchaseHistory(
			state,
			sourceType,
			offerId,
			purchaseId,
			string.format("%s pet compensated with %d Footgems because inventory was full", petId, compensation)
		)
		return false
	end

	local pet = createPetRecord(state, petId, level, false)
	appendPurchaseHistory(
		state,
		sourceType,
		offerId,
		purchaseId,
		string.format("Granted %s (Lv %d)", PetConfig.getDefinition(pet.petId).displayName, pet.level)
	)
	return true
end

refreshGamePassOwnership = function(state, shouldRecordHistory)
	local anyChanged = false

	for offerId, offer in pairs(ShopConfig.Offers) do
		if offer.offerType ~= "GamePass" or offer.marketplaceId <= 0 then
			continue
		end

		local success, ownsPass = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, state.player.UserId, offer.marketplaceId)
		if success then
			local entitlementId = offer.entitlementId
			if state.gamePassOwnership[entitlementId] ~= ownsPass then
				state.gamePassOwnership[entitlementId] = ownsPass
				anyChanged = true
			end

			if ownsPass and shouldRecordHistory and not state.recordedGamePasses[offerId] then
				state.recordedGamePasses[offerId] = true
				appendPurchaseHistory(state, "GamePass", offerId, "", "Ownership synchronized from Marketplace")
				anyChanged = true
			end
		end
	end

	if anyChanged then
		markStateDirty(state)
		syncShopDerivedState(state)
	end
end

local function grantDeveloperProduct(state, offerId, offer, purchaseId)
	if state.processedReceipts[purchaseId] ~= nil then
		return true
	end

	if offer.footgems then
		grantFootgems(state, offer.footgems)
		appendPurchaseHistory(
			state,
			"DeveloperProduct",
			offerId,
			purchaseId,
			string.format("Granted %d Footgems. Balance: %d", offer.footgems, state.footgems.Value)
		)
	elseif offer.stackableId then
		local stackable = ShopConfig.Stackables[offer.stackableId]
		grantStackable(
			state,
			offer.stackableId,
			stackable and stackable.grantAmount or 1,
			"DeveloperProduct",
			offerId,
			purchaseId,
			string.format("Granted %s", offer.displayName)
		)
	elseif offer.bundle then
		if offer.bundle.footgems then
			grantFootgems(state, offer.bundle.footgems)
			appendPurchaseHistory(
				state,
				"Bundle",
				offerId,
				purchaseId,
				string.format("Granted %d Footgems. Balance: %d", offer.bundle.footgems, state.footgems.Value)
			)
		end

		if offer.bundle.entitlements then
			for _, entitlementId in ipairs(offer.bundle.entitlements) do
				grantPermanentEntitlement(
					state,
					entitlementId,
					"Bundle",
					offerId,
					purchaseId,
					string.format("Granted entitlement %s", entitlementId)
				)
			end
		end

		if offer.bundle.pets then
			for _, petGrant in ipairs(offer.bundle.pets) do
				grantPurchasedPet(state, petGrant.petId, petGrant.level or 1, "Bundle", offerId, purchaseId)
			end
		end
	else
		return false
	end

	rememberProcessedReceipt(state, purchaseId, offerId)
	markStateDirty(state)
	syncShopDerivedState(state)
	return true
end

local function resetCharacterTracking(state)
	state.humanoid = nil
	state.rootPart = nil
	state.lastPosition = nil
	state.sampleTimer = 0
end

local function attachCharacter(state, character)
	resetCharacterTracking(state)

	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	state.humanoid = humanoid
	state.rootPart = rootPart
	state.lastPosition = rootPart.Position

	applyMovementSpeed(state)
end

local function isMovementCountable(state)
	local humanoid = state.humanoid
	local rootPart = state.rootPart

	if humanoid == nil or rootPart == nil then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	if not rootPart:IsDescendantOf(workspace) then
		return false
	end

	return humanoid.MoveDirection.Magnitude >= runRewardsConfig.MINIMUM_MOVE_DIRECTION
end

local function stopSprint(state)
	if not state.isSprinting then
		return
	end

	state.isSprinting = false
	state.sprintEndsAt = 0
	state.sprintCooldownEndsAt = getServerNow() + runRewardsConfig.SPRINT_COOLDOWN_SECONDS
	applyMovementSpeed(state)
	sendStateSnapshot(state)
end

local function canSprint(state)
	local humanoid = state.humanoid
	local rootPart = state.rootPart

	if humanoid == nil or rootPart == nil then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	if not rootPart:IsDescendantOf(workspace) then
		return false
	end

	return true
end

local function tryStartSprint(player)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return
	end

	local now = os.clock()
	if now < state.nextSprintRequestTime then
		return
	end

	state.nextSprintRequestTime = now + runRewardsConfig.SPRINT_REQUEST_THROTTLE_SECONDS

	local serverNow = getServerNow()
	if state.isSprinting or state.sprintCooldownEndsAt > serverNow then
		return
	end

	if not canSprint(state) then
		return
	end

	state.isSprinting = true
	state.sprintEndsAt = serverNow + runRewardsConfig.SPRINT_DURATION_SECONDS
	state.sprintCooldownEndsAt = 0
	applyMovementSpeed(state)
	sendStateSnapshot(state)
end

local function updateSprintTimers(state, serverNow)
	if state.isSprinting and serverNow >= state.sprintEndsAt then
		stopSprint(state)
	end

	if not state.isSprinting and state.sprintCooldownEndsAt ~= 0 and serverNow >= state.sprintCooldownEndsAt then
		state.sprintCooldownEndsAt = 0
		sendStateSnapshot(state)
	end
end

local function updatePlayerMovement(state)
	local rootPart = state.rootPart
	if rootPart == nil then
		return
	end

	local currentPosition = rootPart.Position

	if state.lastPosition == nil then
		state.lastPosition = currentPosition
		return
	end

	local movement = currentPosition - state.lastPosition
	state.lastPosition = currentPosition

	if runRewardsConfig.TRACK_HORIZONTAL_ONLY then
		movement = Vector3.new(movement.X, 0, movement.Z)
	end

	local distance = movement.Magnitude
	if distance <= 0 then
		return
	end

	if distance > runRewardsConfig.MAX_TRACKED_STEP_STUDS then
		return
	end

	if not isMovementCountable(state) then
		return
	end

	state.totalDistance = state.totalDistance + distance
	state.pendingStuds = state.pendingStuds + distance

	local studsPerFootyen = getUpgradeValue(state, "StudsPerCurrency")
	local baseFootyens = math.floor(state.pendingStuds / studsPerFootyen)
	if baseFootyens > 0 then
		state.pendingStuds = state.pendingStuds - baseFootyens * studsPerFootyen
		awardFootyens(state, baseFootyens * getEffectiveCurrencyMultiplier(state), true)
	end

	markStateDirty(state)
	sendStateSnapshot(state)
end

local function updatePetPassiveIncome(state, deltaTime)
	local passivePerSecond = getEffectivePetPassivePerSecond(state)
	if passivePerSecond <= 0 then
		return
	end

	state.petPassiveBuffer = state.petPassiveBuffer + passivePerSecond * deltaTime

	local wholeFootyens = math.floor(state.petPassiveBuffer)
	if wholeFootyens <= 0 then
		return
	end

	state.petPassiveBuffer = state.petPassiveBuffer - wholeFootyens
	awardFootyens(state, wholeFootyens, false)
	markStateDirty(state)
	sendStateSnapshot(state)
end

local function destroyBootModel(boot)
	if boot.model and boot.model.Parent then
		boot.model:Destroy()
	end
end

local function removeBootAtIndex(state, index)
	local boot = state.activeBoots[index]
	if boot == nil then
		return
	end

	destroyBootModel(boot)
	table.remove(state.activeBoots, index)
end

local function createBootPart(parent, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = offset
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createBootModel(state, reward, isGolden, spawnCFrame)
	local model = Instance.new("Model")
	model.Name = string.format("Boot_%d_%d", state.player.UserId, state.bootSerial)
	model:SetAttribute("OwnerUserId", state.player.UserId)
	model:SetAttribute("Reward", reward)
	model:SetAttribute("Golden", isGolden)
	model.Parent = bootFolder

	local primaryColor = isGolden and BootConfig.GOLDEN_BOOT_COLOR or BootConfig.NORMAL_BOOT_COLOR
	local accentColor = isGolden and BootConfig.GOLDEN_BOOT_ACCENT or BootConfig.NORMAL_BOOT_ACCENT

	local root = createBootPart(model, "Sole", Vector3.new(2.8, 0.7, 4.2), CFrame.new(), primaryColor)
	createBootPart(model, "Upper", Vector3.new(1.8, 1.6, 2.1), CFrame.new(0, 1.1, -0.45), accentColor)
	createBootPart(model, "Heel", Vector3.new(1.4, 0.95, 1.25), CFrame.new(0, 0.5, -1.55), accentColor)

	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "RewardLabel"
	labelGui.AlwaysOnTop = false
	labelGui.Size = UDim2.fromOffset(130, 48)
	labelGui.StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0)
	labelGui.Parent = root

	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = isGolden and string.format("GOLDEN +%dF", reward) or string.format("+%dF BOOT", reward)
	textLabel.TextColor3 = isGolden and Color3.fromRGB(255, 234, 162) or Color3.fromRGB(235, 244, 255)
	textLabel.TextSize = 18
	textLabel.TextStrokeTransparency = 0.45
	textLabel.Parent = labelGui

	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.FillColor = primaryColor
	highlight.FillTransparency = 0.74
	highlight.OutlineColor = isGolden and Color3.fromRGB(255, 232, 136) or Color3.fromRGB(112, 182, 255)
	highlight.OutlineTransparency = 0.12
	highlight.Parent = model

	if isGolden then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 224, 124)
		light.Range = 8
		light.Brightness = 1.6
		light.Parent = root
	end

	model.PrimaryPart = root
	model:PivotTo(spawnCFrame)

	return model, root
end

local function getStructurePivots()
	local positions = {}

	for _, wallName in ipairs({ upgradeConfig.WALL_MODEL_NAME, BootConfig.WALL_MODEL_NAME }) do
		local wallModel = Workspace:FindFirstChild(wallName)
		if wallModel and wallModel:IsA("Model") then
			table.insert(positions, wallModel:GetPivot().Position)
		end
	end

	local altarFolder = Workspace:FindFirstChild(SummonConfig.WORKSPACE_FOLDER_NAME)
	if altarFolder then
		for _, altarModel in ipairs(altarFolder:GetChildren()) do
			if altarModel:IsA("Model") and altarModel.PrimaryPart then
				table.insert(positions, altarModel.PrimaryPart.Position)
			end
		end
	end

	return positions
end

local function canUseSpawnPoint(state, position)
	local origin = getSpawnOrigin(state)
	if (position - origin).Magnitude < BootConfig.MIN_DISTANCE_FROM_PLAYER then
		return false
	end

	for _, wallPosition in ipairs(getStructurePivots()) do
		if (position - wallPosition).Magnitude < BootConfig.MIN_DISTANCE_FROM_WALL then
			return false
		end
	end

	for _, boot in ipairs(state.activeBoots) do
		if boot.root and boot.root.Parent and (position - boot.root.Position).Magnitude < 6 then
			return false
		end
	end

	return true
end

local function findBootSpawnCFrame(state)
	local origin = getSpawnOrigin(state)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { bootFolder }

	for _ = 1, BootConfig.MAX_SPAWN_ATTEMPTS do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(BootConfig.BOOT_RING_MIN_DISTANCE, BootConfig.BOOT_RING_MAX_DISTANCE)
		local horizontalOffset = Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local rayOrigin = origin + horizontalOffset + Vector3.new(0, BootConfig.BOOT_RAYCAST_HEIGHT, 0)
		local result = Workspace:Raycast(rayOrigin, Vector3.new(0, -BootConfig.BOOT_RAYCAST_HEIGHT * 2, 0), raycastParams)

		if result and result.Instance and result.Instance.CanCollide and result.Position.Y <= rayOrigin.Y then
			local position = result.Position + Vector3.new(0, BootConfig.BOOT_FLOAT_HEIGHT, 0)
			if canUseSpawnPoint(state, position) then
				return CFrame.new(position) * CFrame.Angles(0, angle + math.rad(90), 0)
			end
		end
	end

	return nil
end

local function spawnBoot(state, serverNow)
	local maxActiveBoots = math.round(getBootUpgradeValue(state, "MaxActiveBoots"))
	if #state.activeBoots >= maxActiveBoots then
		return false
	end

	local spawnCFrame = findBootSpawnCFrame(state)
	if spawnCFrame == nil then
		return false
	end

	state.bootSerial = state.bootSerial + 1

	local isGolden = random:NextNumber() < getBootUpgradeValue(state, "GoldenChance")
	local bootValue = getEffectiveBootValue(state)
	local goldenMultiplier = isGolden and getBootUpgradeValue(state, "GoldenMultiplier") or 1
	local reward = math.max(1, math.floor(bootValue * goldenMultiplier + 0.5))
	local model, root = createBootModel(state, reward, isGolden, spawnCFrame)

	table.insert(state.activeBoots, {
		model = model,
		root = root,
		reward = reward,
		isGolden = isGolden,
		expiresAt = serverNow + getBootUpgradeValue(state, "BootLifetime"),
	})

	sendStateSnapshot(state)

	return true
end

local function purgeExpiredBoots(state, serverNow)
	local removedAny = false

	for index = #state.activeBoots, 1, -1 do
		local boot = state.activeBoots[index]
		if boot == nil or boot.root == nil or not boot.root:IsDescendantOf(Workspace) or serverNow >= boot.expiresAt then
			removeBootAtIndex(state, index)
			removedAny = true
		end
	end

	if removedAny then
		sendStateSnapshot(state)
	end
end

local function collectBoot(state, index)
	local boot = state.activeBoots[index]
	if boot == nil then
		return false
	end

	awardFootyens(state, boot.reward, true)
	state.bootsCollected = state.bootsCollected + 1
	removeBootAtIndex(state, index)
	markStateDirty(state)
	sendStateSnapshot(state)
	sendAchievementSnapshot(state)

	return true
end

local function scanBootPickups(state)
	local rootPart = state.rootPart
	local humanoid = state.humanoid

	if rootPart == nil or humanoid == nil then
		return
	end

	if humanoid.Health <= 0 or not rootPart:IsDescendantOf(Workspace) then
		return
	end

	local pickupRadius = getEffectiveBootPickupRadius(state)

	for index = #state.activeBoots, 1, -1 do
		local boot = state.activeBoots[index]
		if boot and boot.root and boot.root:IsDescendantOf(Workspace) then
			if (boot.root.Position - rootPart.Position).Magnitude <= pickupRadius then
				collectBoot(state, index)
			end
		end
	end
end

local function updateBootField(state, serverNow)
	purgeExpiredBoots(state, serverNow)

	if serverNow >= state.nextBootScanTime then
		state.nextBootScanTime = serverNow + BootConfig.PICKUP_SCAN_INTERVAL
		scanBootPickups(state)
	end

	local spawnInterval = getEffectiveBootSpawnInterval(state)
	local maxActiveBoots = math.round(getBootUpgradeValue(state, "MaxActiveBoots"))

	if state.nextBootSpawnTime == 0 then
		state.nextBootSpawnTime = serverNow + 0.8
	end

	local spawnGuard = 0
	while #state.activeBoots < maxActiveBoots and serverNow >= state.nextBootSpawnTime and spawnGuard < 3 do
		spawnGuard = spawnGuard + 1
		local didSpawn = spawnBoot(state, serverNow)
		state.nextBootSpawnTime = state.nextBootSpawnTime + spawnInterval

		if not didSpawn then
			state.nextBootSpawnTime = math.max(state.nextBootSpawnTime, serverNow + 0.5)
			break
		end
	end
end

local function purchaseRunUpgrade(player, upgradeId)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your upgrade data is still loading.",
		}
	end

	if typeof(upgradeId) ~= "string" then
		return {
			success = false,
			message = "That upgrade request was invalid.",
		}
	end

	local definition = upgradeConfig.Upgrades[upgradeId]
	if definition == nil then
		return {
			success = false,
			message = "That upgrade does not exist.",
		}
	end

	local now = os.clock()
	if now < state.nextPurchaseTime then
		return {
			success = false,
			message = "Give the upgrade terminal a moment.",
		}
	end

	state.nextPurchaseTime = now + upgradeConfig.PURCHASE_COOLDOWN

	local currentLevel = state.upgradeLevels[upgradeId]
	if upgradeConfig.isMaxLevel(upgradeId, currentLevel) then
		return {
			success = false,
			message = string.format("%s is already maxed out.", definition.displayName),
		}
	end

	local upgradeCost = upgradeConfig.getCost(upgradeId, currentLevel)
	if upgradeCost == nil then
		return {
			success = false,
			message = string.format("%s is already maxed out.", definition.displayName),
		}
	end

	if state.footyens.Value < upgradeCost then
		return {
			success = false,
			message = string.format("You need %d more Footyens for %s.", upgradeCost - state.footyens.Value, definition.displayName),
		}
	end

	state.footyens.Value = state.footyens.Value - upgradeCost
	state.upgradeLevels[upgradeId] = currentLevel + 1
	markStateDirty(state)
	applyMovementSpeed(state)
	sendStateSnapshot(state)

	return {
		success = true,
		message = string.format("%s upgraded to level %d.", definition.displayName, currentLevel + 1),
	}
end

local function purchaseBootUpgrade(player, upgradeId)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your boot systems are still loading.",
		}
	end

	if typeof(upgradeId) ~= "string" then
		return {
			success = false,
			message = "That boot upgrade request was invalid.",
		}
	end

	local definition = BootConfig.Upgrades[upgradeId]
	if definition == nil then
		return {
			success = false,
			message = "That boot upgrade does not exist.",
		}
	end

	local now = os.clock()
	if now < state.nextPurchaseTime then
		return {
			success = false,
			message = "Give the boot terminal a moment.",
		}
	end

	state.nextPurchaseTime = now + BootConfig.PURCHASE_COOLDOWN

	local currentLevel = state.bootUpgradeLevels[upgradeId]
	if BootConfig.isMaxLevel(upgradeId, currentLevel) then
		return {
			success = false,
			message = string.format("%s is already maxed out.", definition.displayName),
		}
	end

	local upgradeCost = BootConfig.getCost(upgradeId, currentLevel)
	if upgradeCost == nil then
		return {
			success = false,
			message = string.format("%s is already maxed out.", definition.displayName),
		}
	end

	if state.footyens.Value < upgradeCost then
		return {
			success = false,
			message = string.format("You need %d more Footyens for %s.", upgradeCost - state.footyens.Value, definition.displayName),
		}
	end

	state.footyens.Value = state.footyens.Value - upgradeCost
	state.bootUpgradeLevels[upgradeId] = currentLevel + 1
	markStateDirty(state)

	if upgradeId == "SpawnRate" then
		state.nextBootSpawnTime = math.min(state.nextBootSpawnTime, getServerNow() + getBootUpgradeValue(state, "SpawnRate"))
	end

	sendStateSnapshot(state)

	return {
		success = true,
		message = string.format("%s upgraded to level %d.", definition.displayName, currentLevel + 1),
	}
end

local function setPetEquipped(player, payload)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your pet data is still loading.",
		}
	end

	if typeof(payload) ~= "table" or typeof(payload.uid) ~= "string" or typeof(payload.equipped) ~= "boolean" then
		return {
			success = false,
			message = "That pet action request was invalid.",
		}
	end

	local now = os.clock()
	if now < state.nextPetActionTime then
		return {
			success = false,
			message = "Give the pet inventory a moment.",
		}
	end

	state.nextPetActionTime = now + PetConfig.ACTION_COOLDOWN

	local pet = findPetByUid(state, payload.uid)
	if pet == nil then
		return {
			success = false,
			message = "That pet could not be found.",
		}
	end

	if pet.isEquipped == payload.equipped then
		return {
			success = false,
			message = payload.equipped and "That pet is already equipped." or "That pet is already stored.",
		}
	end

	if payload.equipped and state.equippedPetCount >= getPetEquipLimit(state) then
		return {
			success = false,
			message = string.format("Only %d pets can be equipped at once.", getPetEquipLimit(state)),
		}
	end

	pet.isEquipped = payload.equipped
	commitPetInventoryChange(state)

	return {
		success = true,
		message = payload.equipped and string.format("%s equipped.", PetConfig.getDefinition(pet.petId).displayName)
			or string.format("%s stored.", PetConfig.getDefinition(pet.petId).displayName),
	}
end

local function deletePet(player, petUid)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your pet data is still loading.",
		}
	end

	if typeof(petUid) ~= "string" then
		return {
			success = false,
			message = "That pet deletion request was invalid.",
		}
	end

	local now = os.clock()
	if now < state.nextPetActionTime then
		return {
			success = false,
			message = "Give the pet inventory a moment.",
		}
	end

	state.nextPetActionTime = now + PetConfig.ACTION_COOLDOWN

	local pet, index = findPetByUid(state, petUid)
	if pet == nil or index == nil then
		return {
			success = false,
			message = "That pet could not be found.",
		}
	end

	local petName = PetConfig.getDefinition(pet.petId).displayName
	table.remove(state.pets, index)
	commitPetInventoryChange(state)

	return {
		success = true,
		message = string.format("%s was deleted from your inventory.", petName),
	}
end

local function deletePets(player, petUids)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your pet data is still loading.",
		}
	end

	if typeof(petUids) ~= "table" or #petUids == 0 then
		return {
			success = false,
			message = "Choose at least one pet to delete.",
		}
	end

	local now = os.clock()
	if now < state.nextPetActionTime then
		return {
			success = false,
			message = "Give the pet inventory a moment.",
		}
	end

	state.nextPetActionTime = now + PetConfig.ACTION_COOLDOWN

	local selectedUids = {}
	for _, petUid in ipairs(petUids) do
		if typeof(petUid) == "string" and petUid ~= "" then
			selectedUids[petUid] = true
		end
	end

	local deletedCount = 0
	for index = #state.pets, 1, -1 do
		local pet = state.pets[index]
		if selectedUids[pet.uid] then
			table.remove(state.pets, index)
			deletedCount = deletedCount + 1
		end
	end

	if deletedCount == 0 then
		return {
			success = false,
			message = "None of those pets could be found.",
		}
	end

	commitPetInventoryChange(state)

	return {
		success = true,
		message = string.format("Deleted %d pet%s.", deletedCount, deletedCount == 1 and "" or "s"),
	}
end

local function equipBestPets(player)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your pet data is still loading.",
		}
	end

	if #state.pets == 0 then
		return {
			success = false,
			message = "You do not have any pets to equip.",
		}
	end

	local now = os.clock()
	if now < state.nextPetActionTime then
		return {
			success = false,
			message = "Give the pet inventory a moment.",
		}
	end

	state.nextPetActionTime = now + PetConfig.ACTION_COOLDOWN

	local rankedPets = clonePets(state.pets)
	table.sort(rankedPets, function(left, right)
		local leftScore = getPetSortScore(left)
		local rightScore = getPetSortScore(right)
		if leftScore ~= rightScore then
			return leftScore > rightScore
		end

		if left.petId ~= right.petId then
			return left.petId < right.petId
		end

		return left.uid < right.uid
	end)

	local equippedLookup = {}
	for index = 1, math.min(getPetEquipLimit(state), #rankedPets) do
		equippedLookup[rankedPets[index].uid] = true
	end

	local changedCount = 0
	for _, pet in ipairs(state.pets) do
		local shouldEquip = equippedLookup[pet.uid] == true
		if pet.isEquipped ~= shouldEquip then
			pet.isEquipped = shouldEquip
			changedCount = changedCount + 1
		end
	end

	if changedCount == 0 then
		sortPets(state)
		sendPetInventorySnapshot(state)
		return {
			success = true,
			message = string.format("Your best %d pets are already equipped.", math.min(getPetEquipLimit(state), #state.pets)),
		}
	end

	commitPetInventoryChange(state)

	return {
		success = true,
		message = string.format("Equipped your best %d pets.", math.min(getPetEquipLimit(state), #state.pets)),
	}
end

local function upgradePet(player, petUid)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your pet data is still loading.",
		}
	end

	if typeof(petUid) ~= "string" then
		return {
			success = false,
			message = "That pet upgrade request was invalid.",
		}
	end

	local pet = findPetByUid(state, petUid)
	if pet == nil then
		return {
			success = false,
			message = "That pet could not be found.",
		}
	end

	if pet.level >= PetConfig.MAX_UPGRADE_LEVEL then
		return {
			success = false,
			message = "That pet is already at the maximum upgrade level.",
		}
	end

	return {
		success = false,
		message = PetConfig.UPGRADE_PLACEHOLDER_MESSAGE,
	}
end

local function summonPets(player, request)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your summon data is still loading.",
			spentFootgems = 0,
			remainingFootgems = state and state.footgems.Value or CurrencyConfig.STARTING_FOOTGEMS,
			results = {},
		}
	end

	if typeof(request) ~= "table" or typeof(request.altarId) ~= "string" or typeof(request.amount) ~= "number" then
		return {
			success = false,
			message = "That summon request was invalid.",
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	local summonAmount = math.clamp(math.floor(request.amount + 0.5), 1, SummonConfig.MULTI_SUMMON_COUNT)
	local altar = SummonConfig.Altars[request.altarId]

	if altar == nil then
		return {
			success = false,
			message = "That altar does not exist.",
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	local now = os.clock()
	if now < state.nextSummonTime then
		return {
			success = false,
			message = "The altar is still recharging.",
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	if summonAmount > 1 and not hasEntitlement(state, "TripleSummon") then
		return {
			success = false,
			message = "You need the 3x Summon unlock to use that option.",
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	local availableSlots = getPetInventoryLimit(state) - #state.pets
	if availableSlots < summonAmount then
		return {
			success = false,
			message = string.format("You need %d open pet slots for that summon.", summonAmount),
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	local summonCost = altar.costPerSummon * summonAmount
	if not canAffordFootgems(state, summonCost) then
		return {
			success = false,
			message = string.format("You need %d more Footgems.", summonCost - state.footgems.Value),
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	state.nextSummonTime = now + SummonConfig.SUMMON_BATCH_COOLDOWN
	if not spendFootgems(state, summonCost) then
		return {
			success = false,
			message = "Your Footgems changed before the summon completed.",
			spentFootgems = 0,
			remainingFootgems = state.footgems.Value,
			results = {},
		}
	end

	local rolledEntries = table.create(summonAmount)
	local autoDeleteLookup = createAutoDeleteLookup(altar, request.autoDeletePetIds)
	local hasGuaranteedRarity = false

	for summonIndex = 1, summonAmount do
		local entry = rollSummonEntry(state, altar, nil)
		if entry == nil then
			grantFootgems(state, summonCost)

			return {
				success = false,
				message = "This altar has no valid summon pool.",
				spentFootgems = 0,
				remainingFootgems = state.footgems.Value,
				results = {},
			}
		end

		rolledEntries[summonIndex] = entry

		if summonAmount >= SummonConfig.MULTI_SUMMON_COUNT and altar.multiGuaranteeRarity ~= nil then
			hasGuaranteedRarity = hasGuaranteedRarity or SummonConfig.isAtLeastRarity(entry.rarity, altar.multiGuaranteeRarity)
		end
	end

	if summonAmount >= SummonConfig.MULTI_SUMMON_COUNT and altar.multiGuaranteeRarity ~= nil and not hasGuaranteedRarity then
		local guaranteedEntry = rollSummonEntry(state, altar, altar.multiGuaranteeRarity)
		if guaranteedEntry ~= nil then
			rolledEntries[#rolledEntries] = guaranteedEntry
		end
	end

	local results = table.create(#rolledEntries)
	local autoDeletedCount = 0

	for index, entry in ipairs(rolledEntries) do
		local pet = createPetRecord(state, entry.petId, 1, false)
		local shouldAutoDelete = autoDeleteLookup[pet.petId] == true

		if shouldAutoDelete then
			removePetByUid(state, pet.uid)
			autoDeletedCount = autoDeletedCount + 1
		end

		results[index] = {
			uid = pet.uid,
			petId = pet.petId,
			rarity = entry.rarity,
			level = pet.level,
			autoDeleted = shouldAutoDelete,
		}
	end

	state.totalSummons = state.totalSummons + #results
	sortPets(state)
	recalculatePetBonuses(state)
	markStateDirty(state)
	sendStateSnapshot(state)
	sendPetInventorySnapshot(state)
	sendAchievementSnapshot(state)

	local resultMessage = summonAmount == 1
		and string.format("You summoned %s.", PetConfig.getDefinition(results[1].petId).displayName)
		or string.format("You completed a %dx summon at %s.", summonAmount, altar.displayName)

	if autoDeletedCount > 0 then
		resultMessage = string.format(
			"%s %d summon%s matched your auto-delete filter.",
			resultMessage,
			autoDeletedCount,
			autoDeletedCount == 1 and "" or "s"
		)
	end

	return {
		success = true,
		message = resultMessage,
		spentFootgems = summonCost,
		remainingFootgems = state.footgems.Value,
		results = results,
	}
end

local function claimAchievement(player, achievementId)
	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return {
			success = false,
			message = "Your achievement data is still loading.",
			awardedFootgems = 0,
			awardedFootcores = 0,
		}
	end

	if typeof(achievementId) ~= "string" then
		return {
			success = false,
			message = "That achievement request was invalid.",
			awardedFootgems = 0,
			awardedFootcores = 0,
		}
	end

	local definition = AchievementConfig.Achievements[achievementId]
	if definition == nil then
		return {
			success = false,
			message = "That achievement does not exist.",
			awardedFootgems = 0,
			awardedFootcores = 0,
		}
	end

	if state.achievementClaims[achievementId] == true then
		return {
			success = false,
			message = "That achievement has already been claimed.",
			awardedFootgems = 0,
			awardedFootcores = 0,
		}
	end

	local progress = getAchievementProgressValue(state, definition.type)
	if progress < definition.target then
		return {
			success = false,
			message = "That achievement is not complete yet.",
			awardedFootgems = 0,
			awardedFootcores = 0,
		}
	end

	local awardedFootgems = sanitizeInteger(definition.reward and definition.reward.footgems or 0, 0, 0)
	local awardedFootcores = sanitizeInteger(definition.reward and definition.reward.footcores or 0, 0, 0)

	state.achievementClaims[achievementId] = true

	if awardedFootgems > 0 then
		state.footgems.Value = state.footgems.Value + awardedFootgems
	end

	if awardedFootcores > 0 then
		state.footcores = state.footcores + awardedFootcores
	end

	markStateDirty(state)
	sendStateSnapshot(state)
	sendAchievementSnapshot(state)

	local rewardParts = {}
	if awardedFootgems > 0 then
		table.insert(rewardParts, string.format("%d Footgems", awardedFootgems))
	end
	if awardedFootcores > 0 then
		table.insert(rewardParts, string.format("%d %s", awardedFootcores, PrestigeConfig.CURRENCY_NAME))
	end

	return {
		success = true,
		message = #rewardParts > 0
			and string.format("Claimed %s: %s.", definition.displayName, table.concat(rewardParts, " and "))
			or string.format("Claimed %s.", definition.displayName),
		awardedFootgems = awardedFootgems,
		awardedFootcores = awardedFootcores,
	}
end

local function getDefaultSnapshot()
	return {
		footyens = CurrencyConfig.STARTING_FOOTYENS,
		footgems = CurrencyConfig.STARTING_FOOTGEMS,
		totalDistance = 0,
		bootsCollected = 0,
		activeBoots = 0,
		movementSpeedLevel = 0,
		studsPerCurrencyLevel = 0,
		currencyMultiplierLevel = 0,
		bootValueLevel = 0,
		spawnRateLevel = 0,
		maxActiveBootsLevel = 0,
		pickupRadiusLevel = 0,
		bootLifetimeLevel = 0,
		goldenChanceLevel = 0,
		goldenMultiplierLevel = 0,
		movementSpeed = upgradeConfig.getValue("MovementSpeed", 0),
		studsPerCurrency = upgradeConfig.getValue("StudsPerCurrency", 0),
		currencyMultiplier = upgradeConfig.getValue("CurrencyMultiplier", 0),
		bootValue = BootConfig.getValue("BootValue", 0),
		bootSpawnInterval = BootConfig.getValue("SpawnRate", 0),
		bootMaxActive = math.round(BootConfig.getValue("MaxActiveBoots", 0)),
		bootPickupRadius = BootConfig.getValue("PickupRadius", 0),
		bootLifetime = BootConfig.getValue("BootLifetime", 0),
		bootGoldenChance = BootConfig.getValue("GoldenChance", 0),
		bootGoldenMultiplier = BootConfig.getValue("GoldenMultiplier", 0),
		petInventoryLimit = PetConfig.INVENTORY_LIMIT,
		petEmptySlots = PetConfig.INVENTORY_LIMIT,
		petInventoryCount = 0,
		petEquipLimit = PetConfig.EQUIP_LIMIT,
		equippedPetCount = 0,
		petFootyenMultiplier = 1,
		petPassivePerSecond = 0,
		shopHasFootyenGain10x = false,
		shopHasMovementSpeed5x = false,
		shopHasTripleSummon = false,
		shopHasExtraEquipTwo = false,
		shopHasLuckySummon = false,
		shopHasBootMagnet = false,
		shopHasPetPassiveAura = false,
		shopExtraPetSlotsCount = 0,
		shopPetPassiveOverclockCount = 0,
		shopBootValueCoreCount = 0,
		isSprinting = false,
		sprintEndsAt = 0,
		cooldownEndsAt = 0,
	}
end

local function getDefaultPetInventorySnapshot()
	return {
		petInventoryLimit = PetConfig.INVENTORY_LIMIT,
		petEmptySlots = PetConfig.INVENTORY_LIMIT,
		petInventoryCount = 0,
		petEquipLimit = PetConfig.EQUIP_LIMIT,
		equippedPetCount = 0,
		pets = {},
	}
end

local function getDefaultAchievementSnapshot()
	local state = {
		totalDistance = 0,
		totalSummons = 0,
		bootsCollected = 0,
		rebirthCount = 0,
		pets = {},
		worldUnlocks = createDefaultWorldUnlocks(),
		achievementClaims = AchievementConfig.createDefaultClaimState(),
	}

	return serializeAchievements(state)
end

local function onPlayerAdded(player)
	local leaderstats = createLeaderstats(player)

	local state = {
		player = player,
		footyens = leaderstats.footyens,
		footgems = leaderstats.footgems,
		footcores = 0,
		totalDistance = 0,
		totalSummons = 0,
		bootsCollected = 0,
		rebirthCount = 0,
		upgradeLevels = {
			MovementSpeed = 0,
			StudsPerCurrency = 0,
			CurrencyMultiplier = 0,
		},
		bootUpgradeLevels = {
			BootValue = 0,
			SpawnRate = 0,
			MaxActiveBoots = 0,
			PickupRadius = 0,
			BootLifetime = 0,
			GoldenChance = 0,
			GoldenMultiplier = 0,
		},
		pets = {},
		worldUnlocks = createDefaultWorldUnlocks(),
		achievementClaims = AchievementConfig.createDefaultClaimState(),
		nextPetSerial = 1,
		permanentEntitlements = ShopConfig.createDefaultEntitlements(),
		gamePassOwnership = ShopConfig.createDefaultEntitlements(),
		stackableCounts = ShopConfig.createDefaultStackables(),
		recordedGamePasses = ShopConfig.createDefaultRecordedGamePasses(),
		processedReceipts = {},
		processedReceiptOrder = {},
		purchaseHistory = {},
		equippedPetCount = 0,
		totalPetMultiplier = 1,
		totalPetPassivePerSecond = 0,
		petPassiveBuffer = 0,
		activeBoots = {},
		bootSerial = 0,
		nextBootSpawnTime = 0,
		nextBootScanTime = 0,
		humanoid = nil,
		rootPart = nil,
		lastPosition = nil,
		isSprinting = false,
		sprintEndsAt = 0,
		sprintCooldownEndsAt = 0,
		pendingStuds = 0,
		pendingPayout = 0,
		sampleTimer = 0,
		nextPurchaseTime = 0,
		nextSprintRequestTime = 0,
		nextPetActionTime = 0,
		nextSummonTime = 0,
		characterConnection = nil,
		isLoaded = false,
		isDirty = false,
		isSaving = false,
		pendingSaveRequested = false,
		dirtyToken = 0,
		lastSaveAt = 0,
		nextBackgroundSaveAt = 0,
	}

	playerStates[player] = state
	applyMovementSpeed(state)

	local function handleCharacter(character)
		attachCharacter(state, character)
	end

	state.characterConnection = player.CharacterAdded:Connect(handleCharacter)

	if player.Character then
		handleCharacter(player.Character)
	end

	task.spawn(loadPlayerData, state)
end

local function onPlayerRemoving(player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	if state.characterConnection then
		state.characterConnection:Disconnect()
	end

	savePlayerData(state, "player leaving", true)

	for index = #state.activeBoots, 1, -1 do
		removeBootAtIndex(state, index)
	end

	playerStates[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	local statesToSave = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local state = playerStates[player]
		if state ~= nil then
			table.insert(statesToSave, state)
		end
	end

	local remaining = #statesToSave
	if remaining == 0 then
		return
	end

	local completed = Instance.new("BindableEvent")

	for _, state in ipairs(statesToSave) do
		task.spawn(function()
			savePlayerData(state, "server shutdown", true)
			remaining = remaining - 1
			if remaining == 0 then
				completed:Fire()
			end
		end)
	end

	local shutdownDeadline = os.clock() + 25
	while remaining > 0 and os.clock() < shutdownDeadline do
		task.wait(0.1)
	end

	completed:Destroy()
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _gamePassId, wasPurchased)
	if not wasPurchased then
		return
	end

	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return
	end

	task.spawn(refreshGamePassOwnership, state, true)
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local state = playerStates[player]
	if state == nil or not state.isLoaded then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if state.processedReceipts[receiptInfo.PurchaseId] ~= nil then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local offerId, offer = ShopConfig.getOfferByMarketplaceId(receiptInfo.ProductId, "DeveloperProduct")
	if offer == nil then
		warn(string.format("[FootyenService] Unknown developer product id %s", tostring(receiptInfo.ProductId)))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success = grantDeveloperProduct(state, offerId, offer, receiptInfo.PurchaseId)
	if not success then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	task.spawn(savePlayerData, state, string.format("receipt %s", offerId), true)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

sendStateSnapshot = function(state)
	if state == nil or playerStates[state.player] ~= state then
		return
	end

	network.PlayerStateSnapshot.Fire(state.player, serializeState(state))
end

sendPetInventorySnapshot = function(state)
	if state == nil or playerStates[state.player] ~= state then
		return
	end

	network.PetInventorySnapshot.Fire(state.player, serializePetInventory(state))
end

sendAchievementSnapshot = function(state)
	if state == nil or playerStates[state.player] ~= state then
		return
	end

	network.AchievementSnapshot.Fire(state.player, serializeAchievements(state))
end

network.RequestSprint.SetCallback(tryStartSprint)
network.PurchaseUpgrade.SetCallback(purchaseRunUpgrade)
network.PurchaseBootUpgrade.SetCallback(purchaseBootUpgrade)
network.SetPetEquipped.SetCallback(setPetEquipped)
network.DeletePet.SetCallback(deletePet)
network.DeletePets.SetCallback(deletePets)
network.UpgradePet.SetCallback(upgradePet)
network.EquipBestPets.SetCallback(equipBestPets)
network.SummonPets.SetCallback(summonPets)
network.ClaimAchievement.SetCallback(claimAchievement)

network.GetPlayerState.SetCallback(function(player)
	local state = playerStates[player]

	if state == nil then
		return getDefaultSnapshot()
	end

	return serializeState(state)
end)

network.GetPetInventory.SetCallback(function(player)
	local state = playerStates[player]

	if state == nil then
		return getDefaultPetInventorySnapshot()
	end

	return serializePetInventory(state)
end)

network.GetAchievements.SetCallback(function(player)
	local state = playerStates[player]

	if state == nil then
		return getDefaultAchievementSnapshot()
	end

	return serializeAchievements(state)
end)

RunService.Heartbeat:Connect(function(deltaTime)
	local serverNow = getServerNow()

	if nextAutosaveAt == 0 then
		nextAutosaveAt = serverNow + dataStoreConfig.AUTOSAVE_INTERVAL
	elseif serverNow >= nextAutosaveAt then
		nextAutosaveAt = serverNow + dataStoreConfig.AUTOSAVE_INTERVAL

		for _, state in pairs(playerStates) do
			if state.isLoaded and state.isDirty then
				task.spawn(savePlayerData, state, "autosave", false)
			end
		end
	end

	for _, state in pairs(playerStates) do
		if not state.isLoaded then
			continue
		end

		if state.isDirty and not state.isSaving and state.nextBackgroundSaveAt ~= 0 and serverNow >= state.nextBackgroundSaveAt then
			task.spawn(savePlayerData, state, "background save", false)
		end

		updatePetPassiveIncome(state, deltaTime)
		updateSprintTimers(state, serverNow)
		updateBootField(state, serverNow)
		state.sampleTimer = state.sampleTimer + deltaTime

		if state.sampleTimer >= runRewardsConfig.SAMPLE_INTERVAL then
			state.sampleTimer = state.sampleTimer - runRewardsConfig.SAMPLE_INTERVAL
			updatePlayerMovement(state)
		end
	end
end)
