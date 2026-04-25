local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON example:
{
  "STORAGE_KEY": "lastOnlineUnix",
  "BASE_CAP_HOURS": 4,
  "MAX_CAP_HOURS": 24,
  "BASE_EFFICIENCY": 0.55,
  "IDLE_ZONE_EFFICIENCY": 0.75,
  "WORLD_CURRENCY_EFFICIENCY": 0.3,
  "DisplayRules": {
    "showBreakdown": true,
    "minimumDisplaySeconds": 60
  }
}
]]
local OfflineProgressConfig = {}

OfflineProgressConfig.STORAGE_KEY = "lastOnlineUnix"
OfflineProgressConfig.BASE_CAP_HOURS = 4
OfflineProgressConfig.MAX_CAP_HOURS = 24
OfflineProgressConfig.BASE_EFFICIENCY = 0.55
OfflineProgressConfig.IDLE_ZONE_EFFICIENCY = 0.75
OfflineProgressConfig.WORLD_CURRENCY_EFFICIENCY = 0.3

OfflineProgressConfig.DisplayRules = {
	showBreakdown = true,
	minimumDisplaySeconds = 60,
}

function OfflineProgressConfig.getEffectiveCapHours(baseHours, bonusHours)
	local totalHours = (baseHours or OfflineProgressConfig.BASE_CAP_HOURS) + (bonusHours or 0)
	return math.clamp(totalHours, OfflineProgressConfig.BASE_CAP_HOURS, OfflineProgressConfig.MAX_CAP_HOURS)
end

function OfflineProgressConfig.getOfflineSeconds(nowUnix, lastOnlineUnix, capHours)
	local safeNow = math.max(0, nowUnix or 0)
	local safeLast = math.max(0, lastOnlineUnix or 0)
	local elapsed = math.max(0, safeNow - safeLast)

	return math.min(elapsed, math.floor((capHours or OfflineProgressConfig.BASE_CAP_HOURS) * 3600))
end

OfflineProgressConfig.Live = LiveConfig.attachModule(OfflineProgressConfig, {
	key = "OfflineProgressConfig",
})

return OfflineProgressConfig
