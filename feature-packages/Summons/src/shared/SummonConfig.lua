local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON shape example.
Colors and vectors are serialized by LiveConfig:
{
  "WORKSPACE_FOLDER_NAME": "SummonAltars",
  "DEFAULT_ALTAR_ID": "StarterSanctum",
  "UI_APPEAR_DISTANCE": 24,
  "UI_HIDE_DISTANCE": 30,
  "SUMMON_BATCH_COOLDOWN": 1.35,
  "AUTO_SUMMON_INTERVAL": 1.45,
  "RESULT_POPUP_DURATION": 2.4,
  "MULTI_SUMMON_COUNT": 3,
  "HATCH_DURATION": 3,
  "REVEAL_DURATION": 1.25,
  "HATCH_SHAKE_SPEED": 11,
  "HATCH_SHAKE_ANGLE": 7,
  "HATCH_SHAKE_DISTANCE": 6,
  "RarityOrder": { "Common": 1, "Uncommon": 2, "Rare": 3, "Legendary": 4 },
  "RarityColors": {
    "Common": { "__liveConfigType": "Color3", "r": 0.705882, "g": 0.741176, "b": 0.807843 },
    "Uncommon": { "__liveConfigType": "Color3", "r": 0.415686, "g": 0.878431, "b": 0.635294 },
    "Rare": { "__liveConfigType": "Color3", "r": 0.403922, "g": 0.690196, "b": 1 },
    "Legendary": { "__liveConfigType": "Color3", "r": 1, "g": 0.796078, "b": 0.376471 }
  },
  "Altars": {
    "StarterSanctum": {
      "displayName": "Starter Sanctum",
      "description": "A compact starter banner with six summonable pets and one legendary chase.",
      "costPerSummon": 100,
      "multiGuaranteeRarity": "Uncommon",
      "worldPosition": { "__liveConfigType": "Vector3", "x": -22, "y": 5, "z": -8 },
      "worldSize": { "__liveConfigType": "Vector3", "x": 14, "y": 12, "z": 10 },
      "pool": [
        { "petId": "Common", "rarity": "Common", "probability": 35 },
        { "petId": "Angel", "rarity": "Common", "probability": 35 },
        { "petId": "Demonic", "rarity": "Uncommon", "probability": 12 },
        { "petId": "Snowy", "rarity": "Uncommon", "probability": 12 },
        { "petId": "Emerald", "rarity": "Rare", "probability": 5 },
        { "petId": "Galactic", "rarity": "Legendary", "probability": 1 }
      ]
    }
  }
}
]]
local SummonConfig = {}

SummonConfig.WORKSPACE_FOLDER_NAME = "SummonAltars"
SummonConfig.DEFAULT_ALTAR_ID = "StarterSanctum"
SummonConfig.UI_APPEAR_DISTANCE = 24
SummonConfig.UI_HIDE_DISTANCE = 30
SummonConfig.SUMMON_BATCH_COOLDOWN = 1.35
SummonConfig.AUTO_SUMMON_INTERVAL = 1.45
SummonConfig.RESULT_POPUP_DURATION = 2.4
SummonConfig.MULTI_SUMMON_COUNT = 3
SummonConfig.HATCH_DURATION = 3
SummonConfig.REVEAL_DURATION = 1.25
SummonConfig.HATCH_SHAKE_SPEED = 11
SummonConfig.HATCH_SHAKE_ANGLE = 7
SummonConfig.HATCH_SHAKE_DISTANCE = 6

SummonConfig.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Legendary = 4,
}

SummonConfig.RarityColors = {
	Common = Color3.fromRGB(180, 189, 206),
	Uncommon = Color3.fromRGB(106, 224, 162),
	Rare = Color3.fromRGB(103, 176, 255),
	Legendary = Color3.fromRGB(255, 203, 96),
}

SummonConfig.Altars = {
	StarterSanctum = {
		displayName = "Starter Sanctum",
		description = "A compact starter banner with six summonable pets and one legendary chase.",
		costPerSummon = 100,
		multiGuaranteeRarity = "Uncommon",
		worldPosition = Vector3.new(-22, 5, -8),
		worldSize = Vector3.new(14, 12, 10),
		pool = {
			{ petId = "Common", rarity = "Common", probability = 35 },
			{ petId = "Angel", rarity = "Common", probability = 35 },
			{ petId = "Demonic", rarity = "Uncommon", probability = 12 },
			{ petId = "Snowy", rarity = "Uncommon", probability = 12 },
			{ petId = "Emerald", rarity = "Rare", probability = 5 },
			{ petId = "Galactic", rarity = "Legendary", probability = 1 },
		},
	},
}

function SummonConfig.getAltar(altarId)
	local altar = SummonConfig.Altars[altarId]

	if altar == nil then
		error(string.format("Unknown summon altar id '%s'", tostring(altarId)))
	end

	return altar
end

function SummonConfig.getOrderedPool(altarId)
	local altar = SummonConfig.getAltar(altarId)
	local pool = table.clone(altar.pool)

	table.sort(pool, function(left, right)
		local leftOrder = SummonConfig.RarityOrder[left.rarity] or 999
		local rightOrder = SummonConfig.RarityOrder[right.rarity] or 999

		if leftOrder == rightOrder then
			return left.petId < right.petId
		end

		return leftOrder < rightOrder
	end)

	return pool
end

function SummonConfig.isAtLeastRarity(candidateRarity, minimumRarity)
	local candidateOrder = SummonConfig.RarityOrder[candidateRarity] or 0
	local minimumOrder = SummonConfig.RarityOrder[minimumRarity] or 0

	return candidateOrder >= minimumOrder
end

SummonConfig.Live = LiveConfig.attachModule(SummonConfig, {
	key = "SummonConfig",
})

return SummonConfig
