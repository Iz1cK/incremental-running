local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local BootConfig = require(shared:WaitForChild("BootConfig"))

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
		local wallPosition = spawnPosition + spawnLocation.CFrame.LookVector * 26 - spawnLocation.CFrame.RightVector * 36
		wallPosition = Vector3.new(wallPosition.X, spawnPosition.Y + 9, wallPosition.Z)

		return CFrame.lookAt(wallPosition, Vector3.new(spawnPosition.X, wallPosition.Y, spawnPosition.Z))
	end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		local topY = baseplate.Position.Y + baseplate.Size.Y * 0.5
		local wallPosition = Vector3.new(baseplate.Position.X + 34, topY + 8.5, baseplate.Position.Z - baseplate.Size.Z * 0.3)

		return CFrame.lookAt(wallPosition, Vector3.new(baseplate.Position.X, wallPosition.Y, baseplate.Position.Z))
	end

	return CFrame.new(-34, 8.5, -32)
end

local function buildBootWall()
	local existingWall = Workspace:FindFirstChild(BootConfig.WALL_MODEL_NAME)
	if existingWall then
		existingWall:Destroy()
	end

	local wallModel = Instance.new("Model")
	wallModel.Name = BootConfig.WALL_MODEL_NAME
	wallModel.Parent = Workspace

	local pivot = getWallPivot()

	createPart(wallModel, "Platform", Vector3.new(68, 1.5, 24), pivot * CFrame.new(0, -8.75, 0), {
		Color = Color3.fromRGB(40, 32, 24),
		Material = Enum.Material.Concrete,
		CanCollide = true,
	})

	createPart(wallModel, "BackWall", Vector3.new(66, 22, 2), pivot, {
		Color = Color3.fromRGB(31, 22, 18),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
	})

	createPart(wallModel, "AccentStrip", Vector3.new(62, 0.6, 0.5), pivot * CFrame.new(0, 10.35, -1.05), {
		Color = Color3.fromRGB(255, 184, 88),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})

	createPart(wallModel, BootConfig.WALL_HEADER_PART_NAME, Vector3.new(58, 3.4, 0.4), pivot * CFrame.new(0, 7.9, -1.2), {
		Color = Color3.fromRGB(37, 26, 20),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.05,
		CanCollide = true,
	})

	local blockerProperties = {
		CanCollide = true,
		CanQuery = false,
		CastShadow = false,
		Color = Color3.fromRGB(31, 22, 18),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 1,
	}

	createPart(wallModel, "LeftSideBlocker", Vector3.new(1.5, 22, 26), pivot * CFrame.new(-34.75, 0, 1), blockerProperties)
	createPart(wallModel, "RightSideBlocker", Vector3.new(1.5, 22, 26), pivot * CFrame.new(34.75, 0, 1), blockerProperties)
	createPart(wallModel, "RearBlocker", Vector3.new(69.5, 22, 1.5), pivot * CFrame.new(0, 0, 13.25), blockerProperties)

	local panelOffsets = {
		BootValue = Vector3.new(-24, 1.9, -1.2),
		SpawnRate = Vector3.new(-8, 1.9, -1.2),
		MaxActiveBoots = Vector3.new(8, 1.9, -1.2),
		PickupRadius = Vector3.new(24, 1.9, -1.2),
		BootLifetime = Vector3.new(-16, -4.9, -1.2),
		GoldenChance = Vector3.new(0, -4.9, -1.2),
		GoldenMultiplier = Vector3.new(16, -4.9, -1.2),
	}

	for upgradeId, offset in pairs(panelOffsets) do
		createPart(wallModel, BootConfig.getPanelPartName(upgradeId), Vector3.new(11.5, 6.5, 0.4), pivot * CFrame.new(offset), {
			Color = Color3.fromRGB(44, 30, 24),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.03,
			CanCollide = true,
		})
	end
end

buildBootWall()
