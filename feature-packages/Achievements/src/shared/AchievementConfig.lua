local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON example:
{
  "STORAGE_KEY": "achievementClaims",
  "Achievements": {
    "Distance1000": {
      "displayName": "Warm-Up",
      "description": "Run 1,000 total studs.",
      "type": "TotalDistance",
      "target": 1000,
      "reward": { "footgems": 100 }
    },
    "Summons25": {
      "displayName": "First Stable",
      "description": "Complete 25 total summons.",
      "type": "TotalSummons",
      "target": 25,
      "reward": { "footgems": 250 }
    },
    "WorldUnlock5": {
      "displayName": "Across The Circuit",
      "description": "Unlock all 5 worlds.",
      "type": "WorldsUnlocked",
      "target": 5,
      "reward": { "footcores": 8 }
    }
  }
}
]]
local AchievementConfig = {}

AchievementConfig.STORAGE_KEY = "achievementClaims"
AchievementConfig.ORDERED_ACHIEVEMENT_IDS = {
	"Distance1000",
	"Distance10000",
	"Distance100000",
	"Summons25",
	"Summons100",
	"Legendary1",
	"Boots100",
	"Boots1000",
	"Rebirth1",
	"Rebirth10",
	"WorldUnlock3",
	"WorldUnlock5",
}

AchievementConfig.Achievements = {
	Distance1000 = {
		displayName = "Warm-Up",
		description = "Run 1,000 total studs.",
		type = "TotalDistance",
		target = 1000,
		reward = {
			footgems = 100,
		},
	},
	Distance10000 = {
		displayName = "Finding Your Pace",
		description = "Run 10,000 total studs.",
		type = "TotalDistance",
		target = 10000,
		reward = {
			footgems = 250,
		},
	},
	Distance100000 = {
		displayName = "Marathoner",
		description = "Run 100,000 total studs.",
		type = "TotalDistance",
		target = 100000,
		reward = {
			footcores = 2,
		},
	},
	Summons25 = {
		displayName = "First Stable",
		description = "Complete 25 total summons.",
		type = "TotalSummons",
		target = 25,
		reward = {
			footgems = 250,
		},
	},
	Summons100 = {
		displayName = "Collector",
		description = "Complete 100 total summons.",
		type = "TotalSummons",
		target = 100,
		reward = {
			footgems = 750,
		},
	},
	Legendary1 = {
		displayName = "Lucky Pull",
		description = "Obtain your first Legendary pet.",
		type = "LegendaryPetsOwned",
		target = 1,
		reward = {
			footgems = 1000,
			footcores = 1,
		},
	},
	Boots100 = {
		displayName = "Field Work",
		description = "Collect 100 boots.",
		type = "BootsCollected",
		target = 100,
		reward = {
			footgems = 150,
		},
	},
	Boots1000 = {
		displayName = "Cleat Magnet",
		description = "Collect 1,000 boots.",
		type = "BootsCollected",
		target = 1000,
		reward = {
			footgems = 800,
		},
	},
	Rebirth1 = {
		displayName = "Fresh Legs",
		description = "Perform your first rebirth.",
		type = "RebirthCount",
		target = 1,
		reward = {
			footgems = 500,
		},
	},
	Rebirth10 = {
		displayName = "Seasoned Runner",
		description = "Perform 10 rebirths.",
		type = "RebirthCount",
		target = 10,
		reward = {
			footcores = 5,
		},
	},
	WorldUnlock3 = {
		displayName = "Explorer",
		description = "Unlock 3 worlds.",
		type = "WorldsUnlocked",
		target = 3,
		reward = {
			footgems = 1250,
		},
	},
	WorldUnlock5 = {
		displayName = "Across The Circuit",
		description = "Unlock all 5 worlds.",
		type = "WorldsUnlocked",
		target = 5,
		reward = {
			footcores = 8,
		},
	},
}

function AchievementConfig.getAchievement(achievementId)
	local achievement = AchievementConfig.Achievements[achievementId]

	if achievement == nil then
		error(string.format("Unknown achievement id '%s'", tostring(achievementId)))
	end

	return achievement
end

function AchievementConfig.createDefaultClaimState()
	local result = {}

	for _, achievementId in ipairs(AchievementConfig.ORDERED_ACHIEVEMENT_IDS) do
		result[achievementId] = false
	end

	return result
end

function AchievementConfig.getOrderedAchievementIds()
	return table.clone(AchievementConfig.ORDERED_ACHIEVEMENT_IDS)
end

AchievementConfig.Live = LiveConfig.attachModule(AchievementConfig, {
	key = "AchievementConfig",
})

return AchievementConfig
