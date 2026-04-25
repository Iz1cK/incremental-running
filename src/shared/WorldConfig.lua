local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON shape example.
Vectors are serialized by LiveConfig, and Lua-only formatter functions are omitted:
{
  "DEFAULT_WORLD_ID": "StarterTrack",
  "WORLD_CURRENCY_STORAGE_KEY": "worldCurrencies",
  "WORLD_UNLOCK_STORAGE_KEY": "worldUnlocks",
  "WORLD_UPGRADE_STORAGE_KEY": "worldUpgradeLevels",
  "WorldOrder": ["StarterTrack", "MarathonGrove", "BlitzDistrict", "StormArena", "CelestialCircuit"],
  "MechanicIds": {
    "ComboRun": "ComboRun",
    "IdleZones": "IdleZones",
    "SprintChains": "SprintChains",
    "RiskZones": "RiskZones",
    "RotatingModifiers": "RotatingModifiers"
  },
  "Mechanics": {
    "ComboRun": { "displayName": "Combo Run", "description": "Keep moving to build a combo multiplier for active gains." },
    "IdleZones": { "displayName": "Idle Zones", "description": "Stand inside special circles to generate strong idle rewards." }
  },
  "Worlds": {
    "StarterTrack": {
      "displayName": "Starter Track",
      "localCurrencyName": "Lace Tokens",
      "localCurrencyShort": "LT",
      "mechanicId": "ComboRun",
      "summonBannerId": "StarterTrackBanner",
      "worldPosition": { "__liveConfigType": "Vector3", "x": 0, "y": 0, "z": 0 },
      "activeFootyenMultiplier": 1,
      "bootMultiplier": 1,
      "passiveMultiplier": 1,
      "worldCompletionBonus": { "type": "PrestigeGain", "value": 0.03 },
      "unlockRequirement": null,
      "portalCost": null
    },
    "MarathonGrove": {
      "displayName": "Marathon Grove",
      "localCurrencyName": "Leaf Strides",
      "localCurrencyShort": "LS",
      "mechanicId": "IdleZones",
      "summonBannerId": "MarathonGroveBanner",
      "worldPosition": { "__liveConfigType": "Vector3", "x": 450, "y": 0, "z": 0 },
      "unlockRequirement": { "previousWorldId": "StarterTrack", "lifetimeFootyens": 250000, "localCurrency": 1200, "bestDistance": 18000, "totalSummons": 25 },
      "portalCost": 2500
    }
  },
  "WorldUpgrades": {
    "ComboCap": { "worldId": "StarterTrack", "displayName": "Combo Cap", "baseCost": 50, "costScale": 1.22, "costRoundTo": 5, "maxLevel": 15, "baseValue": 25, "perLevel": 5 },
    "ComboDecayDelay": { "worldId": "StarterTrack", "displayName": "Combo Decay Delay", "baseCost": 60, "costScale": 1.24, "costRoundTo": 5, "maxLevel": 15, "baseValue": 2.5, "perLevel": 0.12 }
  }
}
]]
local WorldConfig = {}

WorldConfig.DEFAULT_WORLD_ID = "StarterTrack"
WorldConfig.WORLD_CURRENCY_STORAGE_KEY = "worldCurrencies"
WorldConfig.WORLD_UNLOCK_STORAGE_KEY = "worldUnlocks"
WorldConfig.WORLD_UPGRADE_STORAGE_KEY = "worldUpgradeLevels"

WorldConfig.WorldOrder = {
	"StarterTrack",
	"MarathonGrove",
	"BlitzDistrict",
	"StormArena",
	"CelestialCircuit",
}

WorldConfig.MechanicIds = {
	ComboRun = "ComboRun",
	IdleZones = "IdleZones",
	SprintChains = "SprintChains",
	RiskZones = "RiskZones",
	RotatingModifiers = "RotatingModifiers",
}

WorldConfig.Mechanics = {
	ComboRun = {
		displayName = "Combo Run",
		description = "Keep moving to build a combo multiplier for active gains.",
	},
	IdleZones = {
		displayName = "Idle Zones",
		description = "Stand inside special circles to generate strong idle rewards.",
	},
	SprintChains = {
		displayName = "Sprint Chains",
		description = "Link boost gates together before the timer expires.",
	},
	RiskZones = {
		displayName = "Risk Zones",
		description = "Enter dangerous zones for much stronger rewards.",
	},
	RotatingModifiers = {
		displayName = "Rotating Modifiers",
		description = "Adapt to changing world bonuses on a fixed timer.",
	},
}

local orderedWorldUpgradeIds = {
	StarterTrack = {
		"ComboCap",
		"ComboDecayDelay",
		"LaceTokenGain",
		"StarterBannerDiscount",
	},
	MarathonGrove = {
		"IdleZoneOutput",
		"OfflineHoursCap",
		"PassivePetWorldBoost",
		"LeafStrideGain",
	},
	BlitzDistrict = {
		"SprintChainWindow",
		"SprintSparkGain",
		"GateMultiplier",
		"SprintCooldownReduction",
	},
	StormArena = {
		"RiskMarkGain",
		"StormResistance",
		"HazardRewardBoost",
		"RareDropChance",
	},
	CelestialCircuit = {
		"ModifierStrength",
		"ModifierReroll",
		"StarThreadGain",
		"LateGamePityBoost",
	},
}

WorldConfig.Worlds = {
	StarterTrack = {
		displayName = "Starter Track",
		description = "A clean active-play opener built around movement combos and early summons.",
		localCurrencyName = "Lace Tokens",
		localCurrencyShort = "LT",
		mechanicId = WorldConfig.MechanicIds.ComboRun,
		summonBannerId = "StarterTrackBanner",
		worldPosition = Vector3.new(0, 0, 0),
		activeFootyenMultiplier = 1.0,
		bootMultiplier = 1.0,
		passiveMultiplier = 1.0,
		worldCompletionBonus = {
			type = "PrestigeGain",
			value = 0.03,
		},
		unlockRequirement = nil,
		portalCost = nil,
	},
	MarathonGrove = {
		displayName = "Marathon Grove",
		description = "An idle-focused world where passive and offline progress become meaningful.",
		localCurrencyName = "Leaf Strides",
		localCurrencyShort = "LS",
		mechanicId = WorldConfig.MechanicIds.IdleZones,
		summonBannerId = "MarathonGroveBanner",
		worldPosition = Vector3.new(450, 0, 0),
		activeFootyenMultiplier = 1.2,
		bootMultiplier = 1.15,
		passiveMultiplier = 1.5,
		worldCompletionBonus = {
			type = "OfflineEfficiency",
			value = 0.05,
		},
		unlockRequirement = {
			previousWorldId = "StarterTrack",
			lifetimeFootyens = 250000,
			localCurrency = 1200,
			bestDistance = 18000,
			totalSummons = 25,
		},
		portalCost = 2500,
	},
	BlitzDistrict = {
		displayName = "Blitz District",
		description = "A high-speed world that rewards sprint timing and chained route execution.",
		localCurrencyName = "Charge Sparks",
		localCurrencyShort = "CS",
		mechanicId = WorldConfig.MechanicIds.SprintChains,
		summonBannerId = "BlitzDistrictBanner",
		worldPosition = Vector3.new(980, 0, 0),
		activeFootyenMultiplier = 1.8,
		bootMultiplier = 1.25,
		passiveMultiplier = 1.2,
		worldCompletionBonus = {
			type = "SprintCooldownReduction",
			value = 0.05,
		},
		unlockRequirement = {
			previousWorldId = "MarathonGrove",
			lifetimeFootyens = 3000000,
			localCurrency = 2500,
			bestDistance = 75000,
			totalSummons = 80,
		},
		portalCost = 8000,
	},
	StormArena = {
		displayName = "Storm Arena",
		description = "A volatile world built around risk zones, burst rewards, and hazard resistance.",
		localCurrencyName = "Risk Marks",
		localCurrencyShort = "RM",
		mechanicId = WorldConfig.MechanicIds.RiskZones,
		summonBannerId = "StormArenaBanner",
		worldPosition = Vector3.new(1620, 0, 0),
		activeFootyenMultiplier = 2.4,
		bootMultiplier = 1.8,
		passiveMultiplier = 1.35,
		worldCompletionBonus = {
			type = "RareWeightBoost",
			value = 0.04,
		},
		unlockRequirement = {
			previousWorldId = "BlitzDistrict",
			lifetimeFootyens = 45000000,
			localCurrency = 4000,
			bestDistance = 220000,
			totalSummons = 180,
		},
		portalCost = 18000,
	},
	CelestialCircuit = {
		displayName = "Celestial Circuit",
		description = "A late-game optimization world driven by rotating modifiers and banner mastery.",
		localCurrencyName = "Star Threads",
		localCurrencyShort = "ST",
		mechanicId = WorldConfig.MechanicIds.RotatingModifiers,
		summonBannerId = "CelestialCircuitBanner",
		worldPosition = Vector3.new(2450, 0, 0),
		activeFootyenMultiplier = 2.8,
		bootMultiplier = 2.2,
		passiveMultiplier = 2.0,
		worldCompletionBonus = {
			type = "PityProgressBoost",
			value = 0.05,
		},
		unlockRequirement = {
			previousWorldId = "StormArena",
			lifetimeFootyens = 900000000,
			localCurrency = 9000,
			bestDistance = 900000,
			totalSummons = 400,
		},
		portalCost = 50000,
	},
}

WorldConfig.WorldUpgrades = {
	ComboCap = {
		worldId = "StarterTrack",
		displayName = "Combo Cap",
		baseCost = 50,
		costScale = 1.22,
		costRoundTo = 5,
		maxLevel = 15,
		baseValue = 25,
		perLevel = 5,
		valueFormatter = function(value)
			return string.format("%d combo cap", math.round(value))
		end,
	},
	ComboDecayDelay = {
		worldId = "StarterTrack",
		displayName = "Combo Decay Delay",
		baseCost = 60,
		costScale = 1.24,
		costRoundTo = 5,
		maxLevel = 15,
		baseValue = 2.5,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("%.2fs grace", value)
		end,
	},
	LaceTokenGain = {
		worldId = "StarterTrack",
		displayName = "Lace Token Gain",
		baseCost = 70,
		costScale = 1.26,
		costRoundTo = 5,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.1,
		valueFormatter = function(value)
			return string.format("x%.2f LT", value)
		end,
	},
	StarterBannerDiscount = {
		worldId = "StarterTrack",
		displayName = "Starter Banner Discount",
		baseCost = 80,
		costScale = 1.28,
		costRoundTo = 5,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.02,
		maxValue = 0.25,
		valueFormatter = function(value)
			return string.format("%.0f%% cheaper", value * 100)
		end,
	},
	IdleZoneOutput = {
		worldId = "MarathonGrove",
		displayName = "Idle Zone Output",
		baseCost = 120,
		costScale = 1.24,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("x%.2f idle zone gain", value)
		end,
	},
	OfflineHoursCap = {
		worldId = "MarathonGrove",
		displayName = "Offline Hours Cap",
		baseCost = 140,
		costScale = 1.25,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 4,
		perLevel = 0.75,
		maxValue = 16,
		valueFormatter = function(value)
			return string.format("%.1fh cap", value)
		end,
	},
	PassivePetWorldBoost = {
		worldId = "MarathonGrove",
		displayName = "Passive Pet World Boost",
		baseCost = 160,
		costScale = 1.27,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.08,
		valueFormatter = function(value)
			return string.format("x%.2f passive pets", value)
		end,
	},
	LeafStrideGain = {
		worldId = "MarathonGrove",
		displayName = "Leaf Stride Gain",
		baseCost = 180,
		costScale = 1.29,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.1,
		valueFormatter = function(value)
			return string.format("x%.2f LS", value)
		end,
	},
	SprintChainWindow = {
		worldId = "BlitzDistrict",
		displayName = "Sprint Chain Window",
		baseCost = 260,
		costScale = 1.27,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 4.0,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("%.2fs chain", value)
		end,
	},
	SprintSparkGain = {
		worldId = "BlitzDistrict",
		displayName = "Charge Spark Gain",
		baseCost = 290,
		costScale = 1.29,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.11,
		valueFormatter = function(value)
			return string.format("x%.2f CS", value)
		end,
	},
	GateMultiplier = {
		worldId = "BlitzDistrict",
		displayName = "Gate Multiplier",
		baseCost = 320,
		costScale = 1.31,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("x%.2f gate burst", value)
		end,
	},
	SprintCooldownReduction = {
		worldId = "BlitzDistrict",
		displayName = "Sprint Cooldown Reduction",
		baseCost = 350,
		costScale = 1.33,
		costRoundTo = 10,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.025,
		maxValue = 0.35,
		valueFormatter = function(value)
			return string.format("%.0f%% shorter cooldown", value * 100)
		end,
	},
	RiskMarkGain = {
		worldId = "StormArena",
		displayName = "Risk Mark Gain",
		baseCost = 480,
		costScale = 1.3,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.14,
		valueFormatter = function(value)
			return string.format("x%.2f RM", value)
		end,
	},
	StormResistance = {
		worldId = "StormArena",
		displayName = "Storm Resistance",
		baseCost = 520,
		costScale = 1.32,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.04,
		maxValue = 0.5,
		valueFormatter = function(value)
			return string.format("%.0f%% safer", value * 100)
		end,
	},
	HazardRewardBoost = {
		worldId = "StormArena",
		displayName = "Hazard Reward Boost",
		baseCost = 560,
		costScale = 1.34,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.15,
		valueFormatter = function(value)
			return string.format("x%.2f hazard rewards", value)
		end,
	},
	RareDropChance = {
		worldId = "StormArena",
		displayName = "Rare Drop Chance",
		baseCost = 600,
		costScale = 1.36,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.015,
		maxValue = 0.25,
		valueFormatter = function(value)
			return string.format("+%.1f%% rare drops", value * 100)
		end,
	},
	ModifierStrength = {
		worldId = "CelestialCircuit",
		displayName = "Modifier Strength",
		baseCost = 900,
		costScale = 1.34,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.12,
		valueFormatter = function(value)
			return string.format("x%.2f modifiers", value)
		end,
	},
	ModifierReroll = {
		worldId = "CelestialCircuit",
		displayName = "Modifier Reroll",
		baseCost = 980,
		costScale = 1.36,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 1,
		valueFormatter = function(value)
			return string.format("%d rerolls", math.round(value))
		end,
	},
	StarThreadGain = {
		worldId = "CelestialCircuit",
		displayName = "Star Thread Gain",
		baseCost = 1060,
		costScale = 1.38,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 1.0,
		perLevel = 0.14,
		valueFormatter = function(value)
			return string.format("x%.2f ST", value)
		end,
	},
	LateGamePityBoost = {
		worldId = "CelestialCircuit",
		displayName = "Late-Game Pity Boost",
		baseCost = 1140,
		costScale = 1.4,
		costRoundTo = 25,
		maxLevel = 15,
		baseValue = 0.0,
		perLevel = 0.03,
		maxValue = 0.45,
		valueFormatter = function(value)
			return string.format("+%.0f%% pity speed", value * 100)
		end,
	},
}

local function roundUp(value, multiple)
	return math.ceil(value / multiple) * multiple
end

function WorldConfig.getOrderedWorldIds()
	local result = table.create(#WorldConfig.WorldOrder)

	for index, worldId in ipairs(WorldConfig.WorldOrder) do
		result[index] = worldId
	end

	return result
end

function WorldConfig.getWorld(worldId)
	local world = WorldConfig.Worlds[worldId]

	if world == nil then
		error(string.format("Unknown world id '%s'", tostring(worldId)))
	end

	return world
end

function WorldConfig.getMechanic(worldId)
	local world = WorldConfig.getWorld(worldId)
	local mechanic = WorldConfig.Mechanics[world.mechanicId]

	if mechanic == nil then
		error(string.format("Unknown mechanic id '%s'", tostring(world.mechanicId)))
	end

	return mechanic
end

function WorldConfig.getOrderedWorldUpgradeIds(worldId)
	local orderedIds = orderedWorldUpgradeIds[worldId]

	if orderedIds == nil then
		error(string.format("Unknown world upgrade track for '%s'", tostring(worldId)))
	end

	local result = table.create(#orderedIds)

	for index, upgradeId in ipairs(orderedIds) do
		result[index] = upgradeId
	end

	return result
end

function WorldConfig.getWorldUpgrade(upgradeId)
	local definition = WorldConfig.WorldUpgrades[upgradeId]

	if definition == nil then
		error(string.format("Unknown world upgrade id '%s'", tostring(upgradeId)))
	end

	return definition
end

function WorldConfig.getWorldUpgradeValue(upgradeId, level)
	local definition = WorldConfig.getWorldUpgrade(upgradeId)
	local value = definition.baseValue + definition.perLevel * level

	if definition.minValue ~= nil then
		value = math.max(definition.minValue, value)
	end

	if definition.maxValue ~= nil then
		value = math.min(definition.maxValue, value)
	end

	return value
end

function WorldConfig.getWorldUpgradeCost(upgradeId, level)
	local definition = WorldConfig.getWorldUpgrade(upgradeId)

	if level >= definition.maxLevel then
		return nil
	end

	return roundUp(definition.baseCost * definition.costScale ^ level, definition.costRoundTo or 1)
end

function WorldConfig.formatWorldUpgradeValue(upgradeId, value)
	return WorldConfig.getWorldUpgrade(upgradeId).valueFormatter(value)
end

function WorldConfig.createDefaultWorldCurrencyState()
	local result = {}

	for _, worldId in ipairs(WorldConfig.WorldOrder) do
		result[worldId] = 0
	end

	return result
end

function WorldConfig.createDefaultWorldUnlockState()
	local result = {}

	for index, worldId in ipairs(WorldConfig.WorldOrder) do
		result[worldId] = index == 1
	end

	return result
end

function WorldConfig.createDefaultWorldUpgradeState()
	local result = {}

	for worldId, orderedIds in pairs(orderedWorldUpgradeIds) do
		result[worldId] = {}

		for _, upgradeId in ipairs(orderedIds) do
			result[worldId][upgradeId] = 0
		end
	end

	return result
end

WorldConfig.Live = LiveConfig.attachModule(WorldConfig, {
	key = "WorldConfig",
})

return WorldConfig
