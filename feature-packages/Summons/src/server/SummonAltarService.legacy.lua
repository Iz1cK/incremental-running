local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("Shared")
local SummonConfig = require(shared:WaitForChild("SummonConfig"))

local altarFolder = Workspace:FindFirstChild(SummonConfig.WORKSPACE_FOLDER_NAME)
if altarFolder == nil then
	altarFolder = Instance.new("Folder")
	altarFolder.Name = SummonConfig.WORKSPACE_FOLDER_NAME
	altarFolder.Parent = Workspace
else
	altarFolder:ClearAllChildren()
end

local function createPart(parent, name, size, cframe, color, material, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = canCollide
	part.Color = color
	part.Material = material
	part.Size = size
	part.CFrame = cframe
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function createAccentRing(parent, name, size, cframe, color)
	local part = createPart(parent, name, size, cframe, color, Enum.Material.Neon, false)
	part.Transparency = 0.12

	return part
end

for altarId, altar in pairs(SummonConfig.Altars) do
	local model = Instance.new("Model")
	model.Name = altarId
	model:SetAttribute("AltarId", altarId)
	model.Parent = altarFolder

	local root = createPart(
		model,
		"InteractionRoot",
		Vector3.new(6, 2, 6),
		CFrame.new(altar.worldPosition),
		Color3.fromRGB(35, 46, 68),
		Enum.Material.SmoothPlastic,
		false
	)
	root.Transparency = 1

	local base = createPart(
		model,
		"Base",
		Vector3.new(altar.worldSize.X, 2, altar.worldSize.Z),
		CFrame.new(altar.worldPosition + Vector3.new(0, -2.4, 0)),
		Color3.fromRGB(38, 47, 68),
		Enum.Material.Slate,
		true
	)

	createPart(
		model,
		"Pedestal",
		Vector3.new(8, 4, 8),
		CFrame.new(altar.worldPosition + Vector3.new(0, 0, 0)),
		Color3.fromRGB(21, 28, 42),
		Enum.Material.SmoothPlastic,
		true
	)

	createAccentRing(
		model,
		"AuraRingOuter",
		Vector3.new(10, 0.3, 10),
		CFrame.new(altar.worldPosition + Vector3.new(0, 2.15, 0)),
		Color3.fromRGB(106, 204, 255)
	)

	createAccentRing(
		model,
		"AuraRingInner",
		Vector3.new(6, 0.35, 6),
		CFrame.new(altar.worldPosition + Vector3.new(0, 2.35, 0)),
		Color3.fromRGB(255, 210, 96)
	)

	local orb = createPart(
		model,
		"SummonOrb",
		Vector3.new(4, 4, 4),
		CFrame.new(altar.worldPosition + Vector3.new(0, 5.2, 0)),
		Color3.fromRGB(120, 205, 255),
		Enum.Material.Neon,
		false
	)
	orb.Shape = Enum.PartType.Ball

	local core = createPart(
		model,
		"SummonCore",
		Vector3.new(2.2, 2.2, 2.2),
		CFrame.new(altar.worldPosition + Vector3.new(0, 5.2, 0)),
		Color3.fromRGB(255, 234, 152),
		Enum.Material.Neon,
		false
	)
	core.Shape = Enum.PartType.Ball

	local pointLight = Instance.new("PointLight")
	pointLight.Name = "AltarLight"
	pointLight.Brightness = 2.4
	pointLight.Range = 18
	pointLight.Color = Color3.fromRGB(120, 205, 255)
	pointLight.Parent = orb

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "AltarBillboard"
	billboardGui.AlwaysOnTop = false
	billboardGui.Size = UDim2.fromOffset(240, 70)
	billboardGui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
	billboardGui.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.55)
	title.Font = Enum.Font.GothamBold
	title.Text = altar.displayName
	title.TextColor3 = Color3.fromRGB(244, 248, 255)
	title.TextScaled = true
	title.TextStrokeTransparency = 0.35
	title.Parent = billboardGui

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromScale(0, 0.48)
	subtitle.Size = UDim2.fromScale(1, 0.52)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = string.format("%d Footgems per summon", altar.costPerSummon)
	subtitle.TextColor3 = Color3.fromRGB(141, 223, 255)
	subtitle.TextScaled = true
	subtitle.TextStrokeTransparency = 0.45
	subtitle.Parent = billboardGui

	model.PrimaryPart = root
	model:PivotTo(CFrame.new(altar.worldPosition))

	base:SetAttribute("AltarId", altarId)
	root:SetAttribute("AltarId", altarId)
end
