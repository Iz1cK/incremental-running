local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local playerStateStore = require(shared:WaitForChild("PlayerStateStore"))
local network = require(shared:WaitForChild("ZapClient"))

network.PlayerStateSnapshot.SetCallback(function(snapshot)
	playerStateStore.setState(snapshot)
end)

network.PetInventorySnapshot.SetCallback(function(snapshot)
	playerStateStore.setState(snapshot)
end)

network.AchievementSnapshot.SetCallback(function(snapshot)
	playerStateStore.setState(snapshot)
end)

local function fetchInitialState(shouldWarn)
	local ok, snapshot = pcall(function()
		return network.GetPlayerState.Call()
	end)

	if ok and type(snapshot) == "table" then
		playerStateStore.setState(snapshot)
		return true
	end

	if shouldWarn then
		warn("Failed to fetch a Zap player state snapshot.", snapshot)
	end

	return false
end

local function fetchInitialInventory(shouldWarn)
	local ok, snapshot = pcall(function()
		return network.GetPetInventory.Call()
	end)

	if ok and type(snapshot) == "table" then
		playerStateStore.setState(snapshot)
		return true, snapshot
	end

	if shouldWarn then
		warn("Failed to fetch a Zap pet inventory snapshot.", snapshot)
	end

	return false, nil
end

local function fetchInitialAchievements(shouldWarn)
	local ok, snapshot = pcall(function()
		return network.GetAchievements.Call()
	end)

	if ok and type(snapshot) == "table" then
		playerStateStore.setState(snapshot)
		return true
	end

	if shouldWarn then
		warn("Failed to fetch a Zap achievement snapshot.", snapshot)
	end

	return false
end

task.spawn(function()
	for _ = 1, 8 do
		fetchInitialState(true)
		local _, inventorySnapshot = fetchInitialInventory(true)
		fetchInitialAchievements(true)

		if inventorySnapshot and inventorySnapshot.petInventoryCount > 0 then
			break
		end

		task.wait(0.75)
	end
end)

task.spawn(function()
	while script.Parent ~= nil do
		fetchInitialState(false)
		task.wait(0.25)
	end
end)

task.spawn(function()
	while script.Parent ~= nil do
		fetchInitialInventory(false)
		task.wait(0.75)
	end
end)

task.spawn(function()
	while script.Parent ~= nil do
		fetchInitialAchievements(false)
		task.wait(1)
	end
end)
