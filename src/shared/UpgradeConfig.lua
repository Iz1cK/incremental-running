local RunRewardsConfig = require(script.Parent:WaitForChild("RunRewardsConfig"))

local UpgradeConfig = {}

UpgradeConfig.WALL_MODEL_NAME = "FootyenUpgradeWall"
UpgradeConfig.WALL_HEADER_PART_NAME = "HeaderPanel"
UpgradeConfig.PURCHASE_COOLDOWN = 0.18

local orderedUpgradeIds = {
	"MovementSpeed",
	"StudsPerCurrency",
	"CurrencyMultiplier",
}

UpgradeConfig.Upgrades = {
	MovementSpeed = {
		displayName = "Movement Speed",
		description = "Run faster so every second of movement covers more ground.",
		baseCost = 30,
		costScale = 1.45,
		costRoundTo = 5,
		maxLevel = 12,
		baseValue = RunRewardsConfig.BASE_WALK_SPEED,
		perLevel = 2,
		valueFormatter = function(value)
			return string.format("%.0f WalkSpeed", value)
		end,
	},
	StudsPerCurrency = {
		displayName = "Studs Per Footyen",
		description = "Lower the distance needed before every Footyen payout.",
		baseCost = 45,
		costScale = 1.55,
		costRoundTo = 5,
		maxLevel = 12,
		baseValue = RunRewardsConfig.STUDS_PER_FOOTYEN,
		perLevel = -1,
		minValue = 6,
		valueFormatter = function(value)
			return string.format("%d studs / Footyen", math.round(value))
		end,
	},
	CurrencyMultiplier = {
		displayName = "Currency Multiplier",
		description = "Boost each Footyen payout before it lands in your balance.",
		baseCost = 60,
		costScale = 1.65,
		costRoundTo = 5,
		maxLevel = 10,
		baseValue = 1,
		perLevel = 0.25,
		valueFormatter = function(value)
			return string.format("x%.2f rewards", value)
		end,
	},
}

local function roundUp(value, multiple)
	return math.ceil(value / multiple) * multiple
end

function UpgradeConfig.getOrderedUpgradeIds()
	local result = table.create(#orderedUpgradeIds)

	for index, upgradeId in ipairs(orderedUpgradeIds) do
		result[index] = upgradeId
	end

	return result
end

function UpgradeConfig.getDefinition(upgradeId)
	local definition = UpgradeConfig.Upgrades[upgradeId]

	if definition == nil then
		error(string.format("Unknown upgrade id '%s'", tostring(upgradeId)))
	end

	return definition
end

function UpgradeConfig.getPanelPartName(upgradeId)
	return string.format("%sPanel", upgradeId)
end

function UpgradeConfig.isMaxLevel(upgradeId, level)
	return level >= UpgradeConfig.getDefinition(upgradeId).maxLevel
end

function UpgradeConfig.getValue(upgradeId, level)
	local definition = UpgradeConfig.getDefinition(upgradeId)
	local value = definition.baseValue + definition.perLevel * level

	if definition.minValue ~= nil then
		value = math.max(definition.minValue, value)
	end

	if definition.maxValue ~= nil then
		value = math.min(definition.maxValue, value)
	end

	return value
end

function UpgradeConfig.getCost(upgradeId, level)
	local definition = UpgradeConfig.getDefinition(upgradeId)

	if UpgradeConfig.isMaxLevel(upgradeId, level) then
		return nil
	end

	return roundUp(definition.baseCost * definition.costScale ^ level, definition.costRoundTo or 1)
end

function UpgradeConfig.getCurrentAndNextValue(upgradeId, level)
	local currentValue = UpgradeConfig.getValue(upgradeId, level)

	if UpgradeConfig.isMaxLevel(upgradeId, level) then
		return currentValue, nil
	end

	return currentValue, UpgradeConfig.getValue(upgradeId, level + 1)
end

function UpgradeConfig.formatValue(upgradeId, value)
	return UpgradeConfig.getDefinition(upgradeId).valueFormatter(value)
end

return UpgradeConfig
