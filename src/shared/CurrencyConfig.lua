local LiveConfig = require(script.Parent:WaitForChild("LiveConfig"))

--[[
LiveConfig default JSON example:
{
  "FOOTYEN_NAME": "Footyens",
  "FOOTGEM_NAME": "Footgems",
  "STARTING_FOOTYENS": 0,
  "STARTING_FOOTGEMS": 1000
}
]]
local CurrencyConfig = {
	FOOTYEN_NAME = "Footyens",
	FOOTGEM_NAME = "Footgems",
	STARTING_FOOTYENS = 0,
	STARTING_FOOTGEMS = 1000,
}

CurrencyConfig.Live = LiveConfig.attachModule(CurrencyConfig, {
	key = "CurrencyConfig",
})

return CurrencyConfig
