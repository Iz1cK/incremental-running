local UpgradeConfig = require(script.Parent:WaitForChild("UpgradeConfig"))
local BootConfig = require(script.Parent:WaitForChild("BootConfig"))
local CurrencyConfig = require(script.Parent:WaitForChild("CurrencyConfig"))
local PetConfig = require(script.Parent:WaitForChild("PetConfig"))

local defaultState = {
	footyens = 0,
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
	movementSpeed = UpgradeConfig.getValue("MovementSpeed", 0),
	studsPerCurrency = UpgradeConfig.getValue("StudsPerCurrency", 0),
	currencyMultiplier = UpgradeConfig.getValue("CurrencyMultiplier", 0),
	bootValue = BootConfig.getValue("BootValue", 0),
	bootSpawnInterval = BootConfig.getValue("SpawnRate", 0),
	bootMaxActive = BootConfig.getValue("MaxActiveBoots", 0),
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
	achievementCount = 0,
	completedAchievementCount = 0,
	claimedAchievementCount = 0,
	achievements = {},
	pets = {},
	isSprinting = false,
	sprintEndsAt = 0,
	cooldownEndsAt = 0,
}

local state = table.clone(defaultState)
local listeners = {}

local function copyState()
	local snapshot = table.clone(state)
	local pets = state.pets
	local copiedPets = table.create(#pets)

	for index, pet in ipairs(pets) do
		copiedPets[index] = table.clone(pet)
	end

	snapshot.pets = copiedPets

	local achievements = state.achievements
	local copiedAchievements = table.create(#achievements)

	for index, achievement in ipairs(achievements) do
		copiedAchievements[index] = table.clone(achievement)
	end

	snapshot.achievements = copiedAchievements

	return snapshot
end

local PlayerStateStore = {}

function PlayerStateStore.getState()
	return copyState()
end

function PlayerStateStore.setState(nextState)
	local didChange = false

	for key, value in pairs(nextState) do
		if state[key] ~= value then
			state[key] = value
			didChange = true
		end
	end

	if not didChange then
		return
	end

	local snapshot = copyState()

	for listener in pairs(listeners) do
		listener(snapshot)
	end
end

function PlayerStateStore.subscribe(listener)
	listeners[listener] = true
	listener(copyState())

	return function()
		listeners[listener] = nil
	end
end

return PlayerStateStore
