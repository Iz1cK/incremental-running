local BootConfig = {}

BootConfig.COLLECTION_FOLDER_NAME = "FootyenBoots"
BootConfig.WALL_MODEL_NAME = "FootyenBootWall"
BootConfig.WALL_HEADER_PART_NAME = "HeaderPanel"
BootConfig.PURCHASE_COOLDOWN = 0.18

BootConfig.BOOT_RING_MIN_DISTANCE = 14
BootConfig.BOOT_RING_MAX_DISTANCE = 40
BootConfig.BOOT_RAYCAST_HEIGHT = 60
BootConfig.MAX_SPAWN_ATTEMPTS = 18
BootConfig.PICKUP_SCAN_INTERVAL = 0.08
BootConfig.BOOT_FLOAT_HEIGHT = 1
BootConfig.BOOT_DESPAWN_FADE_TIME = 0.18
BootConfig.MIN_DISTANCE_FROM_WALL = 14
BootConfig.MIN_DISTANCE_FROM_PLAYER = 10

BootConfig.NORMAL_BOOT_COLOR = Color3.fromRGB(74, 148, 255)
BootConfig.NORMAL_BOOT_ACCENT = Color3.fromRGB(22, 36, 58)
BootConfig.GOLDEN_BOOT_COLOR = Color3.fromRGB(255, 209, 88)
BootConfig.GOLDEN_BOOT_ACCENT = Color3.fromRGB(125, 82, 19)

local orderedUpgradeIds = {
	"BootValue",
	"SpawnRate",
	"MaxActiveBoots",
	"PickupRadius",
	"BootLifetime",
	"GoldenChance",
	"GoldenMultiplier",
}

BootConfig.Upgrades = {
	BootValue = {
		displayName = "Boot Value",
		description = "Raise the Footyens paid by every boot you collect.",
		baseCost = 40,
		costScale = 1.42,
		costRoundTo = 5,
		maxLevel = 12,
		baseValue = 5,
		perLevel = 2,
		valueFormatter = function(value)
			return string.format("%d Footyens / boot", math.round(value))
		end,
	},
	SpawnRate = {
		displayName = "Spawn Rate",
		description = "Shorten the time between fresh boots spawning around you.",
		baseCost = 55,
		costScale = 1.48,
		costRoundTo = 5,
		maxLevel = 12,
		baseValue = 4.5,
		perLevel = -0.25,
		minValue = 1.4,
		valueFormatter = function(value)
			return string.format("%.2fs / spawn", value)
		end,
	},
	MaxActiveBoots = {
		displayName = "Max Active Boots",
		description = "Keep more boots on the ground at once so your route stays loaded.",
		baseCost = 65,
		costScale = 1.5,
		costRoundTo = 5,
		maxLevel = 10,
		baseValue = 6,
		perLevel = 1,
		valueFormatter = function(value)
			return string.format("%d active boots", math.round(value))
		end,
	},
	PickupRadius = {
		displayName = "Pickup Radius",
		description = "Collect nearby boots without needing to step exactly on top of them.",
		baseCost = 50,
		costScale = 1.46,
		costRoundTo = 5,
		maxLevel = 10,
		baseValue = 5.5,
		perLevel = 0.75,
		valueFormatter = function(value)
			return string.format("%.1f stud radius", value)
		end,
	},
	BootLifetime = {
		displayName = "Boot Lifetime",
		description = "Let spawned boots stay on the field longer before fading away.",
		baseCost = 45,
		costScale = 1.44,
		costRoundTo = 5,
		maxLevel = 10,
		baseValue = 28,
		perLevel = 4,
		valueFormatter = function(value)
			return string.format("%ds lifetime", math.round(value))
		end,
	},
	GoldenChance = {
		displayName = "Golden Chance",
		description = "Increase how often a rare golden boot appears in your personal field.",
		baseCost = 80,
		costScale = 1.56,
		costRoundTo = 5,
		maxLevel = 8,
		baseValue = 0.08,
		perLevel = 0.03,
		maxValue = 0.32,
		valueFormatter = function(value)
			return string.format("%.0f%% golden chance", value * 100)
		end,
	},
	GoldenMultiplier = {
		displayName = "Golden Multiplier",
		description = "Make every golden boot payout hit much harder.",
		baseCost = 95,
		costScale = 1.6,
		costRoundTo = 5,
		maxLevel = 8,
		baseValue = 3,
		perLevel = 0.5,
		valueFormatter = function(value)
			return string.format("x%.1f golden payout", value)
		end,
	},
}

local function roundUp(value, multiple)
	return math.ceil(value / multiple) * multiple
end

function BootConfig.getOrderedUpgradeIds()
	local result = table.create(#orderedUpgradeIds)

	for index, upgradeId in ipairs(orderedUpgradeIds) do
		result[index] = upgradeId
	end

	return result
end

function BootConfig.getDefinition(upgradeId)
	local definition = BootConfig.Upgrades[upgradeId]

	if definition == nil then
		error(string.format("Unknown boot upgrade id '%s'", tostring(upgradeId)))
	end

	return definition
end

function BootConfig.getPanelPartName(upgradeId)
	return string.format("%sPanel", upgradeId)
end

function BootConfig.isMaxLevel(upgradeId, level)
	return level >= BootConfig.getDefinition(upgradeId).maxLevel
end

function BootConfig.getValue(upgradeId, level)
	local definition = BootConfig.getDefinition(upgradeId)
	local value = definition.baseValue + definition.perLevel * level

	if definition.minValue ~= nil then
		value = math.max(definition.minValue, value)
	end

	if definition.maxValue ~= nil then
		value = math.min(definition.maxValue, value)
	end

	return value
end

function BootConfig.getCost(upgradeId, level)
	local definition = BootConfig.getDefinition(upgradeId)

	if BootConfig.isMaxLevel(upgradeId, level) then
		return nil
	end

	return roundUp(definition.baseCost * definition.costScale ^ level, definition.costRoundTo or 1)
end

function BootConfig.getCurrentAndNextValue(upgradeId, level)
	local currentValue = BootConfig.getValue(upgradeId, level)

	if BootConfig.isMaxLevel(upgradeId, level) then
		return currentValue, nil
	end

	return currentValue, BootConfig.getValue(upgradeId, level + 1)
end

function BootConfig.formatValue(upgradeId, value)
	return BootConfig.getDefinition(upgradeId).valueFormatter(value)
end

return BootConfig
