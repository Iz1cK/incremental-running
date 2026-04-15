local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RunRewardsConfig = require(Shared:WaitForChild("RunRewardsConfig"))

local playerStates = {}

local function createStats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local footyens = Instance.new("IntValue")
	footyens.Name = "Footyens"
	footyens.Value = 0
	footyens.Parent = leaderstats

	local runStats = Instance.new("Folder")
	runStats.Name = "RunStats"
	runStats.Parent = player

	local totalDistance = Instance.new("NumberValue")
	totalDistance.Name = "TotalDistanceStuds"
	totalDistance.Value = 0
	totalDistance.Parent = runStats

	return footyens, totalDistance
end

local function resetCharacterTracking(state)
	state.humanoid = nil
	state.rootPart = nil
	state.lastPosition = nil
	state.sampleTimer = 0
end

local function attachCharacter(state, character)
	resetCharacterTracking(state)

	local humanoid = character:WaitForChild("Humanoid")
	local rootPart = character:WaitForChild("HumanoidRootPart")

	state.humanoid = humanoid
	state.rootPart = rootPart
	state.lastPosition = rootPart.Position
end

local function isMovementCountable(state)
	local humanoid = state.humanoid
	local rootPart = state.rootPart

	if humanoid == nil or rootPart == nil then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	if not rootPart:IsDescendantOf(workspace) then
		return false
	end

	return humanoid.MoveDirection.Magnitude >= RunRewardsConfig.MINIMUM_MOVE_DIRECTION
end

local function updatePlayerMovement(state)
	local rootPart = state.rootPart
	if rootPart == nil then
		return
	end

	local currentPosition = rootPart.Position

	if state.lastPosition == nil then
		state.lastPosition = currentPosition
		return
	end

	local movement = currentPosition - state.lastPosition
	state.lastPosition = currentPosition

	if RunRewardsConfig.TRACK_HORIZONTAL_ONLY then
		movement = Vector3.new(movement.X, 0, movement.Z)
	end

	local distance = movement.Magnitude
	if distance <= 0 then
		return
	end

	if distance > RunRewardsConfig.MAX_TRACKED_STEP_STUDS then
		return
	end

	if not isMovementCountable(state) then
		return
	end

	state.totalDistance.Value = state.totalDistance.Value + distance
	state.pendingStuds = state.pendingStuds + distance

	local earnedFootyens = math.floor(state.pendingStuds / RunRewardsConfig.STUDS_PER_FOOTYEN)
	if earnedFootyens <= 0 then
		return
	end

	state.pendingStuds = state.pendingStuds - earnedFootyens * RunRewardsConfig.STUDS_PER_FOOTYEN
	state.footyens.Value = state.footyens.Value + earnedFootyens
end

local function onPlayerAdded(player)
	local footyens, totalDistance = createStats(player)

	local state = {
		footyens = footyens,
		totalDistance = totalDistance,
		humanoid = nil,
		rootPart = nil,
		lastPosition = nil,
		pendingStuds = 0,
		sampleTimer = 0,
		characterConnection = nil,
	}

	playerStates[player] = state

	local function handleCharacter(character)
		attachCharacter(state, character)
	end

	state.characterConnection = player.CharacterAdded:Connect(handleCharacter)

	if player.Character then
		handleCharacter(player.Character)
	end
end

local function onPlayerRemoving(player)
	local state = playerStates[player]
	if state == nil then
		return
	end

	if state.characterConnection then
		state.characterConnection:Disconnect()
	end

	playerStates[player] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

RunService.Heartbeat:Connect(function(deltaTime)
	for _, state in pairs(playerStates) do
		state.sampleTimer = state.sampleTimer + deltaTime

		if state.sampleTimer >= RunRewardsConfig.SAMPLE_INTERVAL then
			state.sampleTimer = state.sampleTimer - RunRewardsConfig.SAMPLE_INTERVAL
			updatePlayerMovement(state)
		end
	end
end)
