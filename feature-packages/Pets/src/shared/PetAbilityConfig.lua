local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON example:
{
  "AbilityTypes": {
    "ActiveDistanceBoost": "ActiveDistanceBoost",
    "OfflineGainBoost": "OfflineGainBoost",
    "WorldCurrencyBoost": "WorldCurrencyBoost",
    "SprintGainBoost": "SprintGainBoost",
    "PityProgressBoost": "PityProgressBoost",
    "BootValueBoost": "BootValueBoost",
    "IdleZoneBoost": "IdleZoneBoost",
    "RiskZoneBoost": "RiskZoneBoost",
    "ModifierStrengthBoost": "ModifierStrengthBoost"
  },
  "TagIds": {
    "Active": "Active",
    "Idle": "Idle",
    "Sprint": "Sprint",
    "Boot": "Boot",
    "Lucky": "Lucky",
    "Storm": "Storm",
    "Celestial": "Celestial"
  },
  "PetAbilities": {
    "Common": { "type": "ActiveDistanceBoost", "baseValue": 0.06, "perLevel": 0.01, "tags": ["Active"] },
    "Angel": { "type": "OfflineGainBoost", "baseValue": 0.08, "perLevel": 0.015, "tags": ["Idle", "Lucky"] },
    "Galactic": { "type": "PityProgressBoost", "baseValue": 0.04, "perLevel": 0.01, "tags": ["Celestial", "Lucky"] }
  },
  "TagSynergies": [
    { "requiredTags": 2, "multiplier": 1.08 },
    { "requiredTags": 3, "multiplier": 1.2 }
  ],
  "WorldSynergyBonus": { "requiredMatchingPets": 3, "multiplier": 1.12 },
  "LevelShardCosts": [1, 2, 4, 6],
  "MergeRequirements": { "copiesRequired": 3, "requiredLevel": 5, "maxStars": 3 },
  "EvolutionRequirements": { "requiredStars": 3, "requiredLevel": 5 }
}
]]
local PetAbilityConfig = {}

PetAbilityConfig.AbilityTypes = {
	ActiveDistanceBoost = "ActiveDistanceBoost",
	OfflineGainBoost = "OfflineGainBoost",
	WorldCurrencyBoost = "WorldCurrencyBoost",
	SprintGainBoost = "SprintGainBoost",
	PityProgressBoost = "PityProgressBoost",
	BootValueBoost = "BootValueBoost",
	IdleZoneBoost = "IdleZoneBoost",
	RiskZoneBoost = "RiskZoneBoost",
	ModifierStrengthBoost = "ModifierStrengthBoost",
}

PetAbilityConfig.TagIds = {
	Active = "Active",
	Idle = "Idle",
	Sprint = "Sprint",
	Boot = "Boot",
	Lucky = "Lucky",
	Storm = "Storm",
	Celestial = "Celestial",
}

PetAbilityConfig.PetAbilities = {
	Common = {
		type = PetAbilityConfig.AbilityTypes.ActiveDistanceBoost,
		baseValue = 0.06,
		perLevel = 0.01,
		tags = { PetAbilityConfig.TagIds.Active },
	},
	Angel = {
		type = PetAbilityConfig.AbilityTypes.OfflineGainBoost,
		baseValue = 0.08,
		perLevel = 0.015,
		tags = { PetAbilityConfig.TagIds.Idle, PetAbilityConfig.TagIds.Lucky },
	},
	Demonic = {
		type = PetAbilityConfig.AbilityTypes.SprintGainBoost,
		baseValue = 0.08,
		perLevel = 0.015,
		tags = { PetAbilityConfig.TagIds.Active, PetAbilityConfig.TagIds.Sprint },
	},
	Snowy = {
		type = PetAbilityConfig.AbilityTypes.IdleZoneBoost,
		baseValue = 0.1,
		perLevel = 0.02,
		tags = { PetAbilityConfig.TagIds.Idle },
	},
	Emerald = {
		type = PetAbilityConfig.AbilityTypes.WorldCurrencyBoost,
		baseValue = 0.1,
		perLevel = 0.02,
		tags = { PetAbilityConfig.TagIds.Active, PetAbilityConfig.TagIds.Boot },
	},
	Galactic = {
		type = PetAbilityConfig.AbilityTypes.PityProgressBoost,
		baseValue = 0.04,
		perLevel = 0.01,
		tags = { PetAbilityConfig.TagIds.Celestial, PetAbilityConfig.TagIds.Lucky },
	},
}

PetAbilityConfig.TagSynergies = {
	{
		requiredTags = 2,
		multiplier = 1.08,
	},
	{
		requiredTags = 3,
		multiplier = 1.2,
	},
}

PetAbilityConfig.WorldSynergyBonus = {
	requiredMatchingPets = 3,
	multiplier = 1.12,
}

PetAbilityConfig.LevelShardCosts = {
	1,
	2,
	4,
	6,
}

PetAbilityConfig.MergeRequirements = {
	copiesRequired = 3,
	requiredLevel = 5,
	maxStars = 3,
}

PetAbilityConfig.EvolutionRequirements = {
	requiredStars = 3,
	requiredLevel = 5,
}

function PetAbilityConfig.getAbility(petId)
	return PetAbilityConfig.PetAbilities[petId]
end

function PetAbilityConfig.getAbilityValue(petId, level)
	local ability = PetAbilityConfig.getAbility(petId)
	if ability == nil then
		return nil
	end

	return ability.baseValue + ability.perLevel * math.max(0, level - 1)
end

PetAbilityConfig.Live = LiveConfig.attachModule(PetAbilityConfig, {
	key = "PetAbilityConfig",
})

return PetAbilityConfig
