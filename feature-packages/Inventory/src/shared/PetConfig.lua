local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON shape example.
Colors are serialized by LiveConfig:
{
  "INVENTORY_LIMIT": 45,
  "EQUIP_LIMIT": 3,
  "MAX_UPGRADE_LEVEL": 5,
  "ACTION_COOLDOWN": 0.12,
  "UPGRADE_PLACEHOLDER_MESSAGE": "Pet upgrades are not available yet. The handler is ready once you decide the criteria.",
  "LegacyPetIdMigration": {
    "TempoFox": "Common",
    "MintBunny": "Angel",
    "RocketHound": "Demonic",
    "VaultTurtle": "Snowy",
    "SolarCapy": "Emerald",
    "StormLynx": "Galactic"
  },
  "Pets": {
    "Common": { "displayName": "Common", "rarity": "Common", "shortCode": "CM", "primaryColor": { "__liveConfigType": "Color3", "r": 0.698039, "g": 0.772549, "b": 0.890196 }, "accentColor": { "__liveConfigType": "Color3", "r": 0.92549, "g": 0.952941, "b": 1 }, "multiplierBase": 1.2, "multiplierPerLevel": 0.16, "passiveBase": 7, "passivePerLevel": 2 },
    "Angel": { "displayName": "Angel", "rarity": "Common", "shortCode": "AN", "primaryColor": { "__liveConfigType": "Color3", "r": 1, "g": 0.858824, "b": 0.556863 }, "accentColor": { "__liveConfigType": "Color3", "r": 1, "g": 0.968627, "b": 0.835294 }, "multiplierBase": 1.38, "multiplierPerLevel": 0.2, "passiveBase": 9, "passivePerLevel": 2.5 },
    "Demonic": { "displayName": "Demonic", "rarity": "Uncommon", "shortCode": "DM", "multiplierBase": 2.15, "multiplierPerLevel": 0.34, "passiveBase": 5, "passivePerLevel": 1.5 },
    "Snowy": { "displayName": "Snowy", "rarity": "Uncommon", "shortCode": "SN", "multiplierBase": 1.7, "multiplierPerLevel": 0.24, "passiveBase": 13, "passivePerLevel": 3 },
    "Emerald": { "displayName": "Emerald", "rarity": "Rare", "shortCode": "EM", "multiplierBase": 2.75, "multiplierPerLevel": 0.45, "passiveBase": 14, "passivePerLevel": 3.5 },
    "Galactic": { "displayName": "Galactic", "rarity": "Legendary", "shortCode": "GL", "multiplierBase": 5, "multiplierPerLevel": 0.8, "passiveBase": 10, "passivePerLevel": 2.5 }
  }
}
]]
local PetConfig = {}

PetConfig.INVENTORY_LIMIT = 45
PetConfig.EQUIP_LIMIT = 3
PetConfig.MAX_UPGRADE_LEVEL = 5
PetConfig.ACTION_COOLDOWN = 0.12
PetConfig.UPGRADE_PLACEHOLDER_MESSAGE = "Pet upgrades are not available yet. The handler is ready once you decide the criteria."
PetConfig.LegacyPetIdMigration = {
	TempoFox = "Common",
	MintBunny = "Angel",
	RocketHound = "Demonic",
	VaultTurtle = "Snowy",
	SolarCapy = "Emerald",
	StormLynx = "Galactic",
}

PetConfig.Pets = {
	Common = {
		displayName = "Common",
		description = "A steady starter pet with dependable passive Footyen flow.",
		rarity = "Common",
		shortCode = "CM",
		primaryColor = Color3.fromRGB(178, 197, 227),
		accentColor = Color3.fromRGB(236, 243, 255),
		multiplierBase = 1.2,
		multiplierPerLevel = 0.16,
		passiveBase = 7,
		passivePerLevel = 2,
	},
	Angel = {
		displayName = "Angel",
		description = "A bright support summon with gentle multiplier growth and stronger passive income.",
		rarity = "Common",
		shortCode = "AN",
		primaryColor = Color3.fromRGB(255, 219, 142),
		accentColor = Color3.fromRGB(255, 247, 213),
		multiplierBase = 1.38,
		multiplierPerLevel = 0.2,
		passiveBase = 9,
		passivePerLevel = 2.5,
	},
	Demonic = {
		displayName = "Demonic",
		description = "A hungry uncommon pet that leans hard into raw Footyen multiplier power.",
		rarity = "Uncommon",
		shortCode = "DM",
		primaryColor = Color3.fromRGB(220, 88, 107),
		accentColor = Color3.fromRGB(255, 190, 200),
		multiplierBase = 2.15,
		multiplierPerLevel = 0.34,
		passiveBase = 5,
		passivePerLevel = 1.5,
	},
	Snowy = {
		displayName = "Snowy",
		description = "A calm uncommon pet that trades some damage for a bigger passive drip.",
		rarity = "Uncommon",
		shortCode = "SN",
		primaryColor = Color3.fromRGB(138, 208, 255),
		accentColor = Color3.fromRGB(226, 245, 255),
		multiplierBase = 1.7,
		multiplierPerLevel = 0.24,
		passiveBase = 13,
		passivePerLevel = 3,
	},
	Emerald = {
		displayName = "Emerald",
		description = "A rare collector pet with strong all-around value and premium passive output.",
		rarity = "Rare",
		shortCode = "EM",
		primaryColor = Color3.fromRGB(94, 233, 165),
		accentColor = Color3.fromRGB(206, 255, 227),
		multiplierBase = 2.75,
		multiplierPerLevel = 0.45,
		passiveBase = 14,
		passivePerLevel = 3.5,
	},
	Galactic = {
		displayName = "Galactic",
		description = "A legendary chase pet with explosive multiplier scaling and elite passive gains.",
		rarity = "Legendary",
		shortCode = "GL",
		primaryColor = Color3.fromRGB(147, 110, 255),
		accentColor = Color3.fromRGB(230, 214, 255),
		multiplierBase = 5.0,
		multiplierPerLevel = 0.8,
		passiveBase = 10,
		passivePerLevel = 2.5,
	},
}

function PetConfig.resolvePetId(petId)
	if PetConfig.Pets[petId] ~= nil then
		return petId
	end

	return PetConfig.LegacyPetIdMigration[petId]
end

function PetConfig.getDefinition(petId)
	local resolvedPetId = PetConfig.resolvePetId(petId)
	local definition = resolvedPetId and PetConfig.Pets[resolvedPetId] or nil

	if definition == nil then
		error(string.format("Unknown pet id '%s'", tostring(petId)))
	end

	return definition
end

function PetConfig.clampLevel(level)
	local numericLevel = typeof(level) == "number" and level or 1
	return math.clamp(math.floor(numericLevel + 0.5), 1, PetConfig.MAX_UPGRADE_LEVEL)
end

function PetConfig.getMultiplier(petId, level)
	local definition = PetConfig.getDefinition(petId)
	local clampedLevel = PetConfig.clampLevel(level)

	return definition.multiplierBase + definition.multiplierPerLevel * (clampedLevel - 1)
end

function PetConfig.getPassivePerSecond(petId, level)
	local definition = PetConfig.getDefinition(petId)
	local clampedLevel = PetConfig.clampLevel(level)

	return definition.passiveBase + definition.passivePerLevel * (clampedLevel - 1)
end

function PetConfig.getBoosts(petId, level)
	return PetConfig.getMultiplier(petId, level), PetConfig.getPassivePerSecond(petId, level)
end

function PetConfig.formatMultiplier(value)
	return string.format("x%.2f Footyens", value)
end

function PetConfig.formatPassive(value)
	if math.abs(value - math.round(value)) < 0.01 then
		return string.format("%dF / s", math.round(value))
	end

	return string.format("%.1fF / s", value)
end

PetConfig.Live = LiveConfig.attachModule(PetConfig, {
	key = "PetConfig",
})

return PetConfig
