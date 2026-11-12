local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local BigNum = require(Modules:WaitForChild("BigNum"))

-- Atmosfera Sci-Fi pulita
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(35, 45, 70)
Lighting.OutdoorAmbient = Color3.fromRGB(50, 65, 95)
Lighting.ClockTime = 21.5

-- Rimuove Baseplate e Spawn predefiniti
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name == "Baseplate" or obj:IsA("SpawnLocation") then
		obj:Destroy()
	end
end

local world = Instance.new("Folder")
world.Name = "QuantumWorld"
world.Parent = workspace

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

-- 1. Piattaforma Fluttuante Principale (150x150)
makePart({
	Name = "MainPlatform",
	Size = Vector3.new(150, 2, 150),
	Position = Vector3.new(0, 0, 0),
	Color = Color3.fromRGB(15, 18, 28),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "UnderPlatform",
	Size = Vector3.new(136, 4, 136),
	Position = Vector3.new(0, -3, 0),
	Color = Color3.fromRGB(10, 12, 20),
	Material = Enum.Material.Metal,
	Parent = world,
})

-- Bordi Neon della piattaforma
local borders = {
	{ Vector3.new(152, 2.4, 1.6), Vector3.new(0, 0.2, 75.5) },
	{ Vector3.new(152, 2.4, 1.6), Vector3.new(0, 0.2, -75.5) },
	{ Vector3.new(1.6, 2.4, 152), Vector3.new(75.5, 0.2, 0) },
	{ Vector3.new(1.6, 2.4, 152), Vector3.new(-75.5, 0.2, 0) },
}
for _, b in ipairs(borders) do
	makePart({
		Name = "NeonBorder",
		Size = b[1],
		Position = b[2],
		Color = Color3.fromRGB(0, 220, 255),
		Material = Enum.Material.Neon,
		Parent = world,
	})
end

-- Griglia luminosa sul pavimento
for i = -60, 60, 20 do
	makePart({
		Name = "GridX",
		Size = Vector3.new(140, 0.05, 0.22),
		Position = Vector3.new(0, 1.02, i),
		Color = Color3.fromRGB(22, 55, 85),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	makePart({
		Name = "GridZ",
		Size = Vector3.new(0.22, 0.05, 140),
		Position = Vector3.new(i, 1.02, 0),
		Color = Color3.fromRGB(22, 55, 85),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
end

-- 2. SpawnLocation orientato verso Nucleo e Muro (-Z)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "QuantumSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 0.5, 12)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 56), Vector3.new(0, 1.25, 0))
spawn.Color = Color3.fromRGB(0, 190, 255)
spawn.Material = Enum.Material.Neon
spawn.Transparency = 0.55
spawn.Parent = world

-- Sentiero energetico centrale verso il Nucleo
makePart({
	Name = "CenterConduit",
	Size = Vector3.new(2.2, 0.08, 28),
	Position = Vector3.new(0, 1.04, 39),
	Color = Color3.fromRGB(0, 210, 255),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = world,
})

-- 3. Quantum Core Centrale (Cliccabile)
local coreModel = Instance.new("Model")
coreModel.Name = "QuantumCoreAssembly"
coreModel.Parent = world

makePart({
	Name = "CorePedestal",
	Size = Vector3.new(11, 1.2, 11),
	Position = Vector3.new(0, 1.6, 24),
	Color = Color3.fromRGB(26, 30, 46),
	Material = Enum.Material.Metal,
	Parent = coreModel,
})

local corePart = makePart({
	Name = "CorePart",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(5.2, 5.2, 5.2),
	Position = Vector3.new(0, 8.2, 24),
	Color = Color3.fromRGB(0, 225, 255),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = coreModel,
})

local ring1 = makePart({
	Name = "Ring1",
	Size = Vector3.new(9.0, 0.35, 9.0),
	Position = Vector3.new(0, 8.2, 24),
	Color = Color3.fromRGB(185, 245, 255),
	Material = Enum.Material.Neon,
	Transparency = 0.35,
	CanCollide = false,
	Parent = coreModel,
})

local ring2 = makePart({
	Name = "Ring2",
	Size = Vector3.new(11.2, 0.3, 11.2),
	Position = Vector3.new(0, 8.2, 24),
	Color = Color3.fromRGB(0, 165, 255),
	Material = Enum.Material.Neon,
	Transparency = 0.5,
	CanCollide = false,
	Parent = coreModel,
})

local clickDetector = Instance.new("ClickDetector")
clickDetector.Name = "CoreClick"
clickDetector.MaxActivationDistance = 50
clickDetector.Parent = corePart

local coreBb = Instance.new("BillboardGui")
coreBb.Size = UDim2.fromOffset(250, 52)
coreBb.StudsOffset = Vector3.new(0, 6.2, 0)
coreBb.AlwaysOnTop = true
coreBb.Parent = corePart

local coreLbl = Instance.new("TextLabel")
coreLbl.Size = UDim2.fromScale(1, 1)
coreLbl.BackgroundTransparency = 1
coreLbl.Text = "⚡ CLICCA IL NUCLEO ⚡"
coreLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
coreLbl.TextStrokeTransparency = 0.2
coreLbl.Font = Enum.Font.GothamBlack
coreLbl.TextScaled = true
coreLbl.Parent = coreBb

-- 4. Muro Gigante Upgrade Tree (Front rivolto verso +Z)
local wallPos = Vector3.new(0, 25, -48)
makePart({
	Name = "UpgradeWall",
	Size = Vector3.new(92, 46, 2),
	CFrame = CFrame.lookAt(wallPos, Vector3.new(0, 25, 50)),
	Color = Color3.fromRGB(13, 16, 26),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "UpgradeWallFrame",
	Size = Vector3.new(94.5, 48.5, 1.5),
	CFrame = CFrame.lookAt(Vector3.new(0, 25, -48.5), Vector3.new(0, 25, 50)),
	Color = Color3.fromRGB(0, 215, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

-- 5. Santuario Materia Oscura (Muro Prestige a destra)
local dmPos = Vector3.new(54, 18, -18)
makePart({
	Name = "PrestigeWall",
	Size = Vector3.new(34, 32, 2),
	CFrame = CFrame.lookAt(dmPos, Vector3.new(0, 18, 12)),
	Color = Color3.fromRGB(22, 12, 32),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "PrestigeWallFrame",
	Size = Vector3.new(36, 34, 1.5),
	CFrame = CFrame.lookAt(Vector3.new(54.5, 18, -18.3), Vector3.new(0, 18, 12)),
	Color = Color3.fromRGB(255, 50, 120),
	Material = Enum.Material.Neon,
	Parent = world,
})

-- 6. I 9 Pulsanti a Terra (Griglia 3x3)
local buttonsFolder = Instance.new("Folder")
buttonsFolder.Name = "FloorButtons"
buttonsFolder.Parent = world

for _, cfg in ipairs(GameConfig.Buttons) do
	local pad = makePart({
		Name = cfg.Id,
		Size = Vector3.new(9.5, 1.2, 9.5),
		Position = cfg.Pos,
		Color = cfg.Color,
		Material = Enum.Material.Neon,
		Parent = buttonsFolder,
	})

	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoGui"
	bb.Size = UDim2.fromOffset(215, 96)
	bb.StudsOffset = Vector3.new(0, 4.0, 0)
	bb.AlwaysOnTop = false
	bb.Parent = pad

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	bg.BackgroundTransparency = 0.18
	bg.Parent = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, -8, 0.30, 0)
	title.Position = UDim2.fromOffset(4, 2)
	title.BackgroundTransparency = 1
	title.Text = cfg.Name
	title.TextColor3 = cfg.Color
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = bg

	local desc = Instance.new("TextLabel")
	desc.Name = "DescLabel"
	desc.Size = UDim2.new(1, -8, 0.22, 0)
	desc.Position = UDim2.new(0, 4, 0.31, 0)
	desc.BackgroundTransparency = 1
	desc.Text = cfg.Desc
	desc.TextColor3 = Color3.fromRGB(160, 240, 200)
	desc.Font = Enum.Font.GothamBold
	desc.TextScaled = true
	desc.Parent = bg

	local lvl = Instance.new("TextLabel")
	lvl.Name = "LevelLabel"
	lvl.Size = UDim2.new(1, -8, 0.22, 0)
	lvl.Position = UDim2.new(0, 4, 0.53, 0)
	lvl.BackgroundTransparency = 1
	lvl.Text = "Livello: 0"
	lvl.TextColor3 = Color3.fromRGB(235, 235, 235)
	lvl.Font = Enum.Font.Gotham
	lvl.TextScaled = true
	lvl.Parent = bg

	local cost = Instance.new("TextLabel")
	cost.Name = "CostLabel"
	cost.Size = UDim2.new(1, -8, 0.24, 0)
	cost.Position = UDim2.new(0, 4, 0.75, 0)
	cost.BackgroundTransparency = 1
	cost.Text = "Costo: " .. BigNum.Format(cfg.BaseCost) .. " W"
	cost.TextColor3 = Color3.fromRGB(255, 225, 90)
	cost.Font = Enum.Font.GothamBold
	cost.TextScaled = true
	cost.Parent = bg
end

-- 7. Fabbrica Droni (a destra)
local droneStation = makePart({
	Name = "DroneStation",
	Size = Vector3.new(13, 1.5, 13),
	Position = Vector3.new(48, 1.5, 22),
	Color = Color3.fromRGB(190, 60, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

makePart({
	Name = "DroneHolo",
	Size = Vector3.new(3.8, 3.8, 3.8),
	Position = Vector3.new(48, 5.8, 22),
	Color = Color3.fromRGB(230, 120, 255),
	Material = Enum.Material.ForceField,
	CanCollide = false,
	Parent = world,
})

local droneClick = Instance.new("ClickDetector")
droneClick.Name = "HatchClick"
droneClick.MaxActivationDistance = 35
droneClick.Parent = droneStation

local droneBb = Instance.new("BillboardGui")
droneBb.Size = UDim2.fromOffset(250, 80)
droneBb.StudsOffset = Vector3.new(0, 7.0, 0)
droneBb.Parent = droneStation

local droneLbl = Instance.new("TextLabel")
droneLbl.Name = "StationLabel"
droneLbl.Size = UDim2.fromScale(1, 1)
droneLbl.BackgroundColor3 = Color3.fromRGB(18, 12, 30)
droneLbl.BackgroundTransparency = 0.2
droneLbl.Text = "🛸 FABBRICA DRONI
Clicca per creare (50 Plasma)"
droneLbl.TextColor3 = Color3.fromRGB(240, 170, 255)
droneLbl.Font = Enum.Font.GothamBold
droneLbl.TextScaled = true
droneLbl.Parent = droneBb
Instance.new("UICorner", droneLbl).CornerRadius = UDim.new(0, 8)

-- 8. Pannello Classifica Globale (a sinistra)
local lbPos = Vector3.new(-54, 18, -10)
local lbWall = makePart({
	Name = "LeaderboardWall",
	Size = Vector3.new(28, 32, 2),
	CFrame = CFrame.lookAt(lbPos, Vector3.new(0, 18, 12)),
	Color = Color3.fromRGB(15, 20, 32),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "LeaderboardFrame",
	Size = Vector3.new(30, 34, 1.5),
	CFrame = CFrame.lookAt(Vector3.new(-54.5, 18, -10.3), Vector3.new(0, 18, 12)),
	Color = Color3.fromRGB(0, 180, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

local lbGui = Instance.new("SurfaceGui")
lbGui.Name = "LeaderboardGui"
lbGui.Face = Enum.NormalId.Front
lbGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
lbGui.PixelsPerStud = 25
lbGui.Parent = lbWall

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, 0, 0.14, 0)
lbTitle.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
lbTitle.Text = "🏆 TOP 10 WATT GLOBALI"
lbTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
lbTitle.Font = Enum.Font.GothamBlack
lbTitle.TextScaled = true
lbTitle.Parent = lbGui

local lbList = Instance.new("Frame")
lbList.Name = "List"
lbList.Size = UDim2.new(1, -20, 0.84, 0)
lbList.Position = UDim2.new(0, 10, 0.15, 0)
lbList.BackgroundTransparency = 1
lbList.Parent = lbGui

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = lbList
