local DataStoreConfig = {
	STORE_NAME = "FootyenPlayerData",
	STORE_SCOPE = "live",
	KEY_PREFIX = "Player_",
	DATA_VERSION = 4,
	LOAD_RETRY_COUNT = 3,
	SAVE_RETRY_COUNT = 3,
	RETRY_DELAY_SECONDS = 1.5,
	DIRTY_SAVE_DELAY = 10,
	AUTOSAVE_INTERVAL = 45,
}

function DataStoreConfig.getKeyForUserId(userId)
	return string.format("%s%d", DataStoreConfig.KEY_PREFIX, userId)
end

return DataStoreConfig
