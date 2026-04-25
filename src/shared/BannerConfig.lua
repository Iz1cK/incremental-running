local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON shape example:
{
  "DEFAULT_PITY_STATE_KEY": "bannerPity",
  "MULTI_COUNT": 3,
  "LIMITED_BANNER_ROTATION_HOURS": 72,
  "RarityOrder": {
    "Common": 1,
    "Uncommon": 2,
    "Rare": 3,
    "Epic": 4,
    "Legendary": 5,
    "Mythic": 6,
    "Secret": 7
  },
  "Banners": {
    "StarterTrackBanner": {
      "displayName": "Starter Track Banner",
      "worldId": "StarterTrack",
      "costCurrency": "LaceTokens",
      "costPerSummon": 100,
      "multiCount": 3,
      "multiGuaranteeRarity": "Uncommon",
      "pity": { "rareAt": 20, "epicAt": 60, "legendaryAt": 150 },
      "pool": [
        { "petId": "Common", "rarity": "Common", "weight": 3500 },
        { "petId": "Angel", "rarity": "Common", "weight": 3500 },
        { "petId": "Demonic", "rarity": "Uncommon", "weight": 1200 },
        { "petId": "Snowy", "rarity": "Uncommon", "weight": 1200 },
        { "petId": "Emerald", "rarity": "Rare", "weight": 500 },
        { "petId": "Galactic", "rarity": "Legendary", "weight": 100 }
      ]
    }
  }
}
]]
local BannerConfig = {}

BannerConfig.DEFAULT_PITY_STATE_KEY = "bannerPity"
BannerConfig.MULTI_COUNT = 3
BannerConfig.LIMITED_BANNER_ROTATION_HOURS = 72

BannerConfig.RarityOrder = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
	Mythic = 6,
	Secret = 7,
}

BannerConfig.Banners = {
	StarterTrackBanner = {
		displayName = "Starter Track Banner",
		worldId = "StarterTrack",
		costCurrency = "LaceTokens",
		costPerSummon = 100,
		multiCount = 3,
		multiGuaranteeRarity = "Uncommon",
		pity = {
			rareAt = 20,
			epicAt = 60,
			legendaryAt = 150,
		},
		pool = {
			{ petId = "Common", rarity = "Common", weight = 3500 },
			{ petId = "Angel", rarity = "Common", weight = 3500 },
			{ petId = "Demonic", rarity = "Uncommon", weight = 1200 },
			{ petId = "Snowy", rarity = "Uncommon", weight = 1200 },
			{ petId = "Emerald", rarity = "Rare", weight = 500 },
			{ petId = "Galactic", rarity = "Legendary", weight = 100 },
		},
	},
	MarathonGroveBanner = {
		displayName = "Marathon Grove Banner",
		worldId = "MarathonGrove",
		costCurrency = "LeafStrides",
		costPerSummon = 250,
		multiCount = 3,
		multiGuaranteeRarity = "Rare",
		pity = {
			rareAt = 18,
			epicAt = 55,
			legendaryAt = 140,
		},
		pool = {
			{ petId = "MossHare", rarity = "Common", weight = 3400 },
			{ petId = "FernSprite", rarity = "Common", weight = 3400 },
			{ petId = "LanternDoe", rarity = "Uncommon", weight = 1500 },
			{ petId = "WillowStag", rarity = "Uncommon", weight = 1300 },
			{ petId = "AncientCedar", rarity = "Rare", weight = 350 },
			{ petId = "MoonGroveGuardian", rarity = "Legendary", weight = 50 },
		},
	},
	BlitzDistrictBanner = {
		displayName = "Blitz District Banner",
		worldId = "BlitzDistrict",
		costCurrency = "ChargeSparks",
		costPerSummon = 600,
		multiCount = 3,
		multiGuaranteeRarity = "Rare",
		pity = {
			rareAt = 18,
			epicAt = 50,
			legendaryAt = 130,
		},
		pool = {
			{ petId = "VoltPup", rarity = "Common", weight = 3300 },
			{ petId = "NeonMite", rarity = "Common", weight = 3300 },
			{ petId = "TurboWisp", rarity = "Uncommon", weight = 1650 },
			{ petId = "CircuitRunner", rarity = "Uncommon", weight = 1400 },
			{ petId = "NeonTalon", rarity = "Rare", weight = 300 },
			{ petId = "TurboWarden", rarity = "Legendary", weight = 50 },
		},
	},
	StormArenaBanner = {
		displayName = "Storm Arena Banner",
		worldId = "StormArena",
		costCurrency = "RiskMarks",
		costPerSummon = 1200,
		multiCount = 3,
		multiGuaranteeRarity = "Rare",
		pity = {
			rareAt = 16,
			epicAt = 45,
			legendaryAt = 120,
		},
		pool = {
			{ petId = "ShockRam", rarity = "Common", weight = 3200 },
			{ petId = "TempestMoth", rarity = "Common", weight = 3200 },
			{ petId = "ArenaCrawler", rarity = "Uncommon", weight = 1700 },
			{ petId = "ThunderRook", rarity = "Uncommon", weight = 1450 },
			{ petId = "StormBasilisk", rarity = "Rare", weight = 380 },
			{ petId = "ArenaWyrm", rarity = "Legendary", weight = 70 },
		},
	},
	CelestialCircuitBanner = {
		displayName = "Celestial Circuit Banner",
		worldId = "CelestialCircuit",
		costCurrency = "StarThreads",
		costPerSummon = 2500,
		multiCount = 3,
		multiGuaranteeRarity = "Epic",
		pity = {
			rareAt = 15,
			epicAt = 40,
			legendaryAt = 100,
		},
		pool = {
			{ petId = "OrbitFox", rarity = "Uncommon", weight = 3200 },
			{ petId = "CometBloom", rarity = "Uncommon", weight = 3200 },
			{ petId = "NovaSeraph", rarity = "Rare", weight = 1750 },
			{ petId = "VoidDrifter", rarity = "Rare", weight = 1450 },
			{ petId = "AuroraTitan", rarity = "Epic", weight = 330 },
			{ petId = "VoidComet", rarity = "Legendary", weight = 70 },
		},
	},
}

function BannerConfig.getBanner(bannerId)
	local banner = BannerConfig.Banners[bannerId]

	if banner == nil then
		error(string.format("Unknown banner id '%s'", tostring(bannerId)))
	end

	return banner
end

function BannerConfig.isAtLeastRarity(candidateRarity, minimumRarity)
	local candidateOrder = BannerConfig.RarityOrder[candidateRarity] or 0
	local minimumOrder = BannerConfig.RarityOrder[minimumRarity] or 0

	return candidateOrder >= minimumOrder
end

function BannerConfig.getTotalWeight(bannerId, minimumRarity)
	local banner = BannerConfig.getBanner(bannerId)
	local totalWeight = 0

	for _, entry in ipairs(banner.pool) do
		if minimumRarity == nil or BannerConfig.isAtLeastRarity(entry.rarity, minimumRarity) then
			totalWeight = totalWeight + entry.weight
		end
	end

	return totalWeight
end

function BannerConfig.getDisplayedProbabilities(bannerId)
	local banner = BannerConfig.getBanner(bannerId)
	local totalWeight = BannerConfig.getTotalWeight(bannerId, nil)
	local result = table.create(#banner.pool)

	for index, entry in ipairs(banner.pool) do
		result[index] = {
			petId = entry.petId,
			rarity = entry.rarity,
			probability = totalWeight > 0 and entry.weight / totalWeight or 0,
		}
	end

	return result
end

function BannerConfig.createDefaultPityState()
	local result = {}

	for bannerId in pairs(BannerConfig.Banners) do
		result[bannerId] = {
			sinceRare = 0,
			sinceEpic = 0,
			sinceLegendary = 0,
		}
	end

	return result
end

BannerConfig.Live = LiveConfig.attachModule(BannerConfig, {
	key = "BannerConfig",
})

return BannerConfig
