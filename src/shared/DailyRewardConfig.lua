local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON example:
{
  "STORAGE_KEY": "dailyReward",
  "RESET_INTERVAL_HOURS": 24,
  "STREAK_GRACE_HOURS": 48,
  "Rewards": {
    "1": { "footgems": 100 },
    "2": { "footgems": 250 },
    "3": { "worldBannerTickets": 1 },
    "4": { "footgems": 500 },
    "5": { "worldBannerTickets": 2 },
    "6": { "footgems": 1000 },
    "7": { "rarePlusTicket": 1, "pityProgress": 15 }
  }
}
]]
local DailyRewardConfig = {}

DailyRewardConfig.STORAGE_KEY = "dailyReward"
DailyRewardConfig.RESET_INTERVAL_HOURS = 24
DailyRewardConfig.STREAK_GRACE_HOURS = 48

DailyRewardConfig.Rewards = {
	[1] = {
		footgems = 100,
	},
	[2] = {
		footgems = 250,
	},
	[3] = {
		worldBannerTickets = 1,
	},
	[4] = {
		footgems = 500,
	},
	[5] = {
		worldBannerTickets = 2,
	},
	[6] = {
		footgems = 1000,
	},
	[7] = {
		rarePlusTicket = 1,
		pityProgress = 15,
	},
}

function DailyRewardConfig.getReward(dayIndex)
	return DailyRewardConfig.Rewards[dayIndex]
end

function DailyRewardConfig.getDayCount()
	return #DailyRewardConfig.Rewards
end

function DailyRewardConfig.createDefaultState()
	return {
		lastClaimUnix = 0,
		currentDay = 1,
		currentStreak = 0,
	}
end

DailyRewardConfig.Live = LiveConfig.attachModule(DailyRewardConfig, {
	key = "DailyRewardConfig",
})

return DailyRewardConfig
