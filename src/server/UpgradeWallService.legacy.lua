local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local UpgradeConfig = require(shared:WaitForChild("UpgradeConfig"))

local function createPart(parent, name, size, cframe, properties)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.CFrame = cframe

	for propertyName, value in pairs(properties) do
		part[propertyName] = value
	end

	part.Parent = parent

	return part
end

local function getWallPivot()
	local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawnLocation then
		local spawnPosition = spawnLocation.Position
		local wallPosition = spawnPosition + spawnLocation.CFrame.LookVector * 20 + spawnLocation.CFrame.RightVector * 24
		wallPosition = Vector3.new(wallPosition.X, spawnPosition.Y + 7, wallPosition.Z)

		return CFrame.lookAt(wallPosition, Vector3.new(spawnPosition.X, wallPosition.Y, spawnPosition.Z))
	end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		local topY = baseplate.Position.Y + baseplate.Size.Y * 0.5
		local wallPosition = Vector3.new(baseplate.Position.X, topY + 7, baseplate.Position.Z - baseplate.Size.Z * 0.35)

		return CFrame.lookAt(wallPosition, wallPosition + Vector3.new(0, 0, 1))
	end

	return CFrame.new(0, 7, -30)
end

local function buildUpgradeWall()
	local existingWall = Workspace:FindFirstChild(UpgradeConfig.WALL_MODEL_NAME)
	if existingWall then
		existingWall:Destroy()
	end

	local wallModel = Instance.new("Model")
	wallModel.Name = UpgradeConfig.WALL_MODEL_NAME
	wallModel.Parent = Workspace

	local pivot = getWallPivot()

	createPart(wallModel, "Platform", Vector3.new(44, 1.5, 16), pivot * CFrame.new(0, -6.5, 0), {
		Color = Color3.fromRGB(33, 38, 52),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	})

	createPart(wallModel, "BackWall", Vector3.new(42, 16, 2), pivot, {
		Color = Color3.fromRGB(18, 23, 34),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
	})

	createPart(wallModel, "AccentStrip", Vector3.new(40, 0.5, 0.5), pivot * CFrame.new(0, 7.5, -1.05), {
		Color = Color3.fromRGB(82, 176, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})

	createPart(wallModel, UpgradeConfig.WALL_HEADER_PART_NAME, Vector3.new(36, 3.2, 0.4), pivot * CFrame.new(0, 5.7, -1.2), {
		Color = Color3.fromRGB(16, 23, 36),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.08,
		CanCollide = true,
	})

	local blockerProperties = {
		CanCollide = true,
		CanQuery = false,
		CastShadow = false,
		Color = Color3.fromRGB(18, 23, 34),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 1,
	}

	createPart(wallModel, "LeftSideBlocker", Vector3.new(1.5, 16, 18), pivot * CFrame.new(-21.75, 0, 0.5), blockerProperties)
	createPart(wallModel, "RightSideBlocker", Vector3.new(1.5, 16, 18), pivot * CFrame.new(21.75, 0, 0.5), blockerProperties)
	createPart(wallModel, "RearBlocker", Vector3.new(43.5, 16, 1.5), pivot * CFrame.new(0, 0, 9.25), blockerProperties)

	local panelXOffsets = {
		MovementSpeed = -13,
		StudsPerCurrency = 0,
		CurrencyMultiplier = 13,
	}

	for upgradeId, xOffset in pairs(panelXOffsets) do
		createPart(wallModel, UpgradeConfig.getPanelPartName(upgradeId), Vector3.new(11.5, 8.4, 0.4), pivot * CFrame.new(xOffset, -0.3, -1.2), {
			Color = Color3.fromRGB(20, 28, 43),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.04,
			CanCollide = true,
		})
	end
end

buildUpgradeWall()
