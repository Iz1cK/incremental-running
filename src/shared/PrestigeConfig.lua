local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON shape example.
Lua-only formatter functions are omitted:
{
  "CURRENCY_NAME": "Footcores",
  "STORAGE_KEY": "footcores",
  "REBIRTH_COUNT_KEY": "rebirthCount",
  "PRESTIGE_UPGRADES_KEY": "prestigeUpgradeLevels",
  "BASE_REQUIREMENT": 1000000,
  "EXPONENT": 0.35,
  "REBIRTH_COOLDOWN_SECONDS": 4,
  "UNLOCK_REQUIREMENT": { "worldId": "MarathonGrove", "lifetimeFootyens": 1000000 },
  "WorldBonus": {
    "StarterTrack": 1,
    "MarathonGrove": 1.05,
    "BlitzDistrict": 1.15,
    "StormArena": 1.3,
    "CelestialCircuit": 1.5
  },
  "Resets": {
    "footyens": true,
    "worldCurrencies": true,
    "worldUpgrades": true,
    "runUpgrades": true,
    "bootUpgrades": true,
    "currentWorld": true,
    "comboState": true,
    "activeBoots": true,
    "pity": { "worldBanners": true, "limitedBanners": false }
  },
  "Persists": {
    "footgems": true,
    "pets": true,
    "petEvolutionState": true,
    "shopPurchases": true,
    "achievements": true,
    "dailyRewards": true,
    "prestigeUpgrades": true,
    "worldUnlockRecords": true
  },
  "Upgrades": {
    "FootyenMastery": { "displayName": "Footyen Mastery", "tree": "Economy", "baseCost": 1, "costScale": 1.5, "maxLevel": 20, "baseValue": 1, "perLevel": 0.12 },
    "WorldWealth": { "displayName": "World Wealth", "tree": "Economy", "baseCost": 1, "costScale": 1.56, "maxLevel": 20, "baseValue": 1, "perLevel": 0.1 }
  }
}
]]
local PrestigeConfig = {}

PrestigeConfig.CURRENCY_NAME = "Footcores"
PrestigeConfig.STORAGE_KEY = "footcores"
PrestigeConfig.REBIRTH_COUNT_KEY = "rebirthCount"
PrestigeConfig.PRESTIGE_UPGRADES_KEY = "prestigeUpgradeLevels"
PrestigeConfig.BASE_REQUIREMENT = 1000000
PrestigeConfig.EXPONENT = 0.35
PrestigeConfig.REBIRTH_COOLDOWN_SECONDS = 4

PrestigeConfig.UNLOCK_REQUIREMENT = {
	worldId = "MarathonGrove",
	lifetimeFootyens = 1000000,
}

PrestigeConfig.WorldBonus = {
	StarterTrack = 1.0,
	MarathonGrove = 1.05,
	BlitzDistrict = 1.15,
	StormArena = 1.3,
	CelestialCircuit = 1.5,
}

PrestigeConfig.Resets = {
	footyens = true,
	worldCurrencies = true,
	worldUpgrades = true,
	runUpgrades = true,
	bootUpgrades = true,
	currentWorld = true,
	comboState = true,
	activeBoots = true,
	pity = {
		worldBanners = true,
		limitedBanners = false,
	},
}

PrestigeConfig.Persists = {
	footgems = true,
	pets = true,
	petEvolutionState = true,
	shopPurchases = true,
	achievements = true,
	dailyRewards = true,
	prestigeUpgrades = true,
	worldUnlockRecords = true,
}

local orderedUpgradeIds = {
	"FootyenMastery",
	"WorldWealth",
	"OfflineStorage",
	"SwiftReboots",
	"LuckyCore",
	"BannerSaver",
	"StableExpansion",
	"BondedTeams",
}

PrestigeConfig.Upgrades = {
	FootyenMastery = {
		displayName = "Footyen Mastery",
		description = "Permanent boost to all Footyen gains after rebirth.",
		tree = "Economy",
		baseCost = 1,
		costScale = 1.5,
		maxLevel = 20,
		baseValue = 1.0,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("x%.2f Footyens", value)
		end,
	},
	WorldWealth = {
		displayName = "World Wealth",
		description = "Permanent boost to all non-premium world currencies.",
		tree = "Economy",
		baseCost = 1,
		costScale = 1.56,
		maxLevel = 20,
		baseValue = 1.0,
		perLevel = 0.1,
		valueFormatter = function(value)
			return string.format("x%.2f world currency", value)
		end,
	},
	OfflineStorage = {
		displayName = "Offline Storage",
		description = "Raises the maximum amount of offline time you can bank.",
		tree = "Convenience",
		baseCost = 2,
		costScale = 1.68,
		maxLevel = 10,
		baseValue = 4,
		perLevel = 2,
		valueFormatter = function(value)
			return string.format("%dh offline cap", math.round(value))
		end,
	},
	SwiftReboots = {
		displayName = "Swift Reboots",
		description = "Permanently shortens sprint cooldown after rebirth.",
		tree = "Convenience",
		baseCost = 2,
		costScale = 1.72,
		maxLevel = 10,
		baseValue = 0.0,
		perLevel = 0.04,
		maxValue = 0.4,
		valueFormatter = function(value)
			return string.format("%.0f%% shorter sprint cooldown", value * 100)
		end,
	},
	LuckyCore = {
		displayName = "Lucky Core",
		description = "Speeds up pity and improves long summon sessions.",
		tree = "Summon",
		baseCost = 3,
		costScale = 1.75,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.02,
		valueFormatter = function(value)
			return string.format("+%.0f%% pity speed", value * 100)
		end,
	},
	BannerSaver = {
		displayName = "Banner Saver",
		description = "Reduces summon costs on world banners.",
		tree = "Summon",
		baseCost = 3,
		costScale = 1.8,
		maxLevel = 10,
		baseValue = 0.0,
		perLevel = 0.03,
		maxValue = 0.3,
		valueFormatter = function(value)
			return string.format("%.0f%% cheaper banners", value * 100)
		end,
	},
	StableExpansion = {
		displayName = "Stable Expansion",
		description = "Adds more permanent pet storage as your rebirth count grows.",
		tree = "Pet Meta",
		baseCost = 4,
		costScale = 1.85,
		maxLevel = 20,
		baseValue = 0,
		perLevel = 1,
		valueFormatter = function(value)
			return string.format("+%d pet inventory", math.floor(value / 2))
		end,
	},
	BondedTeams = {
		displayName = "Bonded Teams",
		description = "Permanent increase to pet passive generation.",
		tree = "Pet Meta",
		baseCost = 4,
		costScale = 1.9,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.04,
		valueFormatter = function(value)
			return string.format("x%.2f pet passive", value)
		end,
	},
}

function PrestigeConfig.getWorldBonus(worldId)
	return PrestigeConfig.WorldBonus[worldId] or 1
end

function PrestigeConfig.getPrestigeGain(lifetimeFootyens, worldId, multiplier)
	local sanitizedLifetime = math.max(0, lifetimeFootyens)
	if sanitizedLifetime < PrestigeConfig.BASE_REQUIREMENT then
		return 0
	end

	local gainMultiplier = multiplier or 1
	local worldBonus = PrestigeConfig.getWorldBonus(worldId)

	return math.floor((sanitizedLifetime / PrestigeConfig.BASE_REQUIREMENT) ^ PrestigeConfig.EXPONENT * worldBonus * gainMultiplier)
end

function PrestigeConfig.getOrderedUpgradeIds()
	local result = table.create(#orderedUpgradeIds)

	for index, upgradeId in ipairs(orderedUpgradeIds) do
		result[index] = upgradeId
	end

	return result
end

function PrestigeConfig.getUpgrade(upgradeId)
	local definition = PrestigeConfig.Upgrades[upgradeId]

	if definition == nil then
		error(string.format("Unknown prestige upgrade id '%s'", tostring(upgradeId)))
	end

	return definition
end

function PrestigeConfig.getUpgradeCost(upgradeId, level)
	local definition = PrestigeConfig.getUpgrade(upgradeId)

	if level >= definition.maxLevel then
		return nil
	end

	return math.ceil(definition.baseCost * definition.costScale ^ level)
end

function PrestigeConfig.getUpgradeValue(upgradeId, level)
	local definition = PrestigeConfig.getUpgrade(upgradeId)
	local value = definition.baseValue + definition.perLevel * level

	if definition.maxValue ~= nil then
		value = math.min(definition.maxValue, value)
	end

	return value
end

function PrestigeConfig.formatUpgradeValue(upgradeId, value)
	return PrestigeConfig.getUpgrade(upgradeId).valueFormatter(value)
end

function PrestigeConfig.createDefaultUpgradeState()
	local result = {}

	for _, upgradeId in ipairs(orderedUpgradeIds) do
		result[upgradeId] = 0
	end

	return result
end

PrestigeConfig.Live = LiveConfig.attachModule(PrestigeConfig, {
	key = "PrestigeConfig",
})

return PrestigeConfig
