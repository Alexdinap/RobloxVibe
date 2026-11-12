local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- 1. ATMOSFERA & ILLUMINAZIONE SCI-FI / NEON
Lighting.Brightness = 2.0
Lighting.Ambient = Color3.fromRGB(28, 36, 58)
Lighting.OutdoorAmbient = Color3.fromRGB(40, 52, 82)
Lighting.ClockTime = 21.5
Lighting.GeographicLatitude = 45

for _, fx in ipairs(Lighting:GetChildren()) do
	if fx:IsA("Atmosphere") or fx:IsA("BloomEffect") or fx:IsA("ColorCorrectionEffect") or fx:IsA("Sky") then
		fx:Destroy()
	end
end

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.28
atmosphere.Offset = 0.15
atmosphere.Color = Color3.fromRGB(20, 45, 85)
atmosphere.Decay = Color3.fromRGB(12, 18, 35)
atmosphere.Glare = 0.2
atmosphere.Haze = 1.8
atmosphere.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 0.65
bloom.Size = 24
bloom.Threshold = 1.1
bloom.Parent = Lighting

local colorCorr = Instance.new("ColorCorrectionEffect")
colorCorr.Saturation = 0.15
colorCorr.Contrast = 0.1
colorCorr.TintColor = Color3.fromRGB(235, 245, 255)
colorCorr.Parent = Lighting

-- Pulizia mappa precedente
for _, obj in ipairs(workspace:GetChildren()) do
	if obj.Name == "Baseplate" or obj.Name == "QuantumWorld" or obj:IsA("SpawnLocation") then
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

local function makeNeonLabel(parent, text, subText, accentColor, studsOffset, sizeOffset)
	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoGui"
	bb.Size = sizeOffset or UDim2.fromOffset(240, 85)
	bb.StudsOffset = studsOffset or Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	frame.BackgroundTransparency = 0.18
	frame.Parent = bb
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.Size = UDim2.new(1, -12, 0.52, 0)
	title.Position = UDim2.fromOffset(6, 4)
	title.BackgroundTransparency = 1
	title.Text = text
	title.TextColor3 = accentColor
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Name = "SubLabel"
	sub.Size = UDim2.new(1, -12, 0.42, 0)
	sub.Position = UDim2.new(0, 6, 0.54, 0)
	sub.BackgroundTransparency = 1
	sub.Text = subText
	sub.TextColor3 = Color3.fromRGB(230, 240, 255)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.Parent = frame

	return bb
end

-- 2. PIATTAFORMA FLUTTUANTE PRINCIPALE (CITTADELLA QUANTICA 180x180)
makePart({
	Name = "MainPlatform",
	Size = Vector3.new(180, 2, 180),
	Position = Vector3.new(0, 0, 0),
	Color = Color3.fromRGB(15, 18, 28),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

-- Struttura inferiore metallica a gradoni
makePart({
	Name = "SubDeck1",
	Size = Vector3.new(164, 4, 164),
	Position = Vector3.new(0, -3, 0),
	Color = Color3.fromRGB(22, 26, 40),
	Material = Enum.Material.Metal,
	Parent = world,
})

makePart({
	Name = "SubDeck2",
	Size = Vector3.new(120, 6, 120),
	Position = Vector3.new(0, -8, 0),
	Color = Color3.fromRGB(12, 14, 22),
	Material = Enum.Material.DiamondPlate,
	Parent = world,
})

makePart({
	Name = "ReactorCoreBottom",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(26, 26, 26),
	Position = Vector3.new(0, -13, 0),
	Color = Color3.fromRGB(0, 195, 255),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = world,
})

-- Bordi Neon perimetrali
local perimeter = {
	{ Vector3.new(182, 2.5, 1.8), Vector3.new(0, 0.25, 90.5) },
	{ Vector3.new(182, 2.5, 1.8), Vector3.new(0, 0.25, -90.5) },
	{ Vector3.new(1.8, 2.5, 182), Vector3.new(90.5, 0.25, 0) },
	{ Vector3.new(1.8, 2.5, 182), Vector3.new(-90.5, 0.25, 0) },
}
for _, b in ipairs(perimeter) do
	makePart({
		Name = "PerimeterNeon",
		Size = b[1],
		Position = b[2],
		Color = Color3.fromRGB(0, 220, 255),
		Material = Enum.Material.Neon,
		Parent = world,
	})
end

-- Griglia luminosa sul pavimento
for i = -75, 75, 25 do
	makePart({
		Name = "GridLineX",
		Size = Vector3.new(170, 0.05, 0.22),
		Position = Vector3.new(0, 1.02, i),
		Color = Color3.fromRGB(22, 52, 82),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	makePart({
		Name = "GridLineZ",
		Size = Vector3.new(0.22, 0.05, 170),
		Position = Vector3.new(i, 1.02, 0),
		Color = Color3.fromRGB(22, 52, 82),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
end

-- 4 Piloni Energetici agli angoli della mappa
local animatedCrystals = {}
local cornerCoords = {
	Vector3.new(-82, 1, -82),
	Vector3.new(82, 1, -82),
	Vector3.new(-82, 1, 82),
	Vector3.new(82, 1, 82),
}
for idx, pos in ipairs(cornerCoords) do
	makePart({
		Name = "PylonBase_" .. idx,
		Size = Vector3.new(10, 3, 10),
		Position = pos + Vector3.new(0, 1.5, 0),
		Color = Color3.fromRGB(26, 30, 45),
		Material = Enum.Material.Metal,
		Parent = world,
	})
	makePart({
		Name = "PylonShaft_" .. idx,
		Size = Vector3.new(4.5, 28, 4.5),
		Position = pos + Vector3.new(0, 17, 0),
		Color = Color3.fromRGB(18, 22, 34),
		Material = Enum.Material.SmoothPlastic,
		Parent = world,
	})
	makePart({
		Name = "PylonStripe_" .. idx,
		Size = Vector3.new(4.8, 26, 0.6),
		Position = pos + Vector3.new(0, 17, 0),
		Color = Color3.fromRGB(0, 215, 255),
		Material = Enum.Material.Neon,
		Parent = world,
	})
	local crystal = makePart({
		Name = "PylonCrystal_" .. idx,
		Size = Vector3.new(4.5, 4.5, 4.5),
		Position = pos + Vector3.new(0, 36, 0),
		Color = Color3.fromRGB(0, 235, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	table.insert(animatedCrystals, crystal)
end

-- 3. PIAZZA DI SPAWN (SUD) CON ARCO OLOGRAFICO
local spawn = Instance.new("SpawnLocation")
spawn.Name = "QuantumSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(14, 0.5, 14)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 72), Vector3.new(0, 1.25, 0))
spawn.Color = Color3.fromRGB(0, 195, 255)
spawn.Material = Enum.Material.Neon
spawn.Transparency = 0.55
spawn.Parent = world

-- Portale d'ingresso davanti allo spawn
makePart({ Name = "SpawnPillarL", Size = Vector3.new(2, 16, 2), Position = Vector3.new(-10, 9, 60), Color = Color3.fromRGB(28, 34, 52), Material = Enum.Material.Metal, Parent = world })
makePart({ Name = "SpawnPillarR", Size = Vector3.new(2, 16, 2), Position = Vector3.new(10, 9, 60), Color = Color3.fromRGB(28, 34, 52), Material = Enum.Material.Metal, Parent = world })
makePart({ Name = "SpawnArchTop", Size = Vector3.new(22, 1.6, 2.2), Position = Vector3.new(0, 17.5, 60), Color = Color3.fromRGB(0, 220, 255), Material = Enum.Material.Neon, Parent = world })

-- Condotti energetici principali sul pavimento
makePart({ Name = "ConduitMain", Size = Vector3.new(2.4, 0.08, 92), Position = Vector3.new(0, 1.04, 16), Color = Color3.fromRGB(0, 210, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
makePart({ Name = "ConduitEast", Size = Vector3.new(54, 0.08, 2.0), Position = Vector3.new(28, 1.04, 34), Color = Color3.fromRGB(190, 70, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
makePart({ Name = "ConduitWest", Size = Vector3.new(54, 0.08, 2.0), Position = Vector3.new(-28, 1.04, 34), Color = Color3.fromRGB(0, 255, 170), Material = Enum.Material.Neon, CanCollide = false, Parent = world })

-- 4. QUANTUM CORE CENTRALE (CON STABILIZZATORI E ANELLI ROTANTI)
local coreModel = Instance.new("Model")
coreModel.Name = "QuantumCoreAssembly"
coreModel.Parent = world

local coreCenter = Vector3.new(0, 9.8, 34)

makePart({
	Name = "CorePedestalBase",
	Size = Vector3.new(16, 1.2, 16),
	Position = Vector3.new(0, 1.6, 34),
	Color = Color3.fromRGB(24, 28, 44),
	Material = Enum.Material.Metal,
	Parent = coreModel,
})

makePart({
	Name = "CorePedestalRing",
	Size = Vector3.new(13, 0.6, 13),
	Position = Vector3.new(0, 2.4, 34),
	Color = Color3.fromRGB(0, 215, 255),
	Material = Enum.Material.Neon,
	Parent = coreModel,
})

-- 4 Stabilizzatori inclinati attorno al nucleo
for i = 0, 3 do
	local ang = i * (math.pi / 2) + (math.pi / 4)
	local dist = 9.5
	local stabPos = Vector3.new(math.cos(ang) * dist, 5.2, 34 + math.sin(ang) * dist)
	local stab = makePart({
		Name = "Stabilizer_" .. i,
		Size = Vector3.new(2, 7.5, 2),
		CFrame = CFrame.lookAt(stabPos, coreCenter) * CFrame.Angles(math.rad(65), 0, 0),
		Color = Color3.fromRGB(30, 36, 54),
		Material = Enum.Material.Metal,
		Parent = coreModel,
	})
	local tipPos = Vector3.new(math.cos(ang) * 7.2, 7.2, 34 + math.sin(ang) * 7.2)
	makePart({
		Name = "StabilizerTip_" .. i,
		Size = Vector3.new(1.2, 1.2, 1.2),
		Position = tipPos,
		Color = Color3.fromRGB(0, 235, 255),
		Material = Enum.Material.Neon,
		Parent = coreModel,
	})
end

local corePart = makePart({
	Name = "CorePart",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(6.2, 6.2, 6.2),
	Position = coreCenter,
	Color = Color3.fromRGB(0, 230, 255),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = coreModel,
})

local coreLight = Instance.new("PointLight")
coreLight.Color = Color3.fromRGB(0, 225, 255)
coreLight.Range = 45
coreLight.Brightness = 2.5
coreLight.Parent = corePart

local ring1 = makePart({
	Name = "Ring1",
	Size = Vector3.new(10.5, 0.35, 10.5),
	Position = coreCenter,
	Color = Color3.fromRGB(190, 245, 255),
	Material = Enum.Material.Neon,
	Transparency = 0.3,
	CanCollide = false,
	Parent = coreModel,
})

local ring2 = makePart({
	Name = "Ring2",
	Size = Vector3.new(13.2, 0.3, 13.2),
	Position = coreCenter,
	Color = Color3.fromRGB(0, 170, 255),
	Material = Enum.Material.Neon,
	Transparency = 0.45,
	CanCollide = false,
	Parent = coreModel,
})

local clickDetector = Instance.new("ClickDetector")
clickDetector.Name = "CoreClick"
clickDetector.MaxActivationDistance = 50
clickDetector.Parent = corePart

makeNeonLabel(corePart, "⚡ QUANTUM CORE ⚡", "Clicca per generare energia", Color3.fromRGB(0, 235, 255), Vector3.new(0, 6.8, 0), UDim2.fromOffset(260, 75))

-- 5. I 9 PULSANTI A TERRA (GRIGLIA 3x3 CON CORNICI)
local buttonsFolder = Instance.new("Folder")
buttonsFolder.Name = "FloorButtons"
buttonsFolder.Parent = world

local buttonDefs = {
	{ Id = "btn1", Name = "Generatore Base", Sub = "+1 Watt/s | Costo: 10 W", Color = Color3.fromRGB(0, 225, 255), Pos = Vector3.new(-20, 1.5, 10) },
	{ Id = "btn2", Name = "Amplificatore", Sub = "+8 Watt/s | Costo: 100 W", Color = Color3.fromRGB(0, 255, 165), Pos = Vector3.new(0, 1.5, 10) },
	{ Id = "btn3", Name = "Condensatore", Sub = "x1.25 Watt/s | Costo: 500 W", Color = Color3.fromRGB(255, 205, 0), Pos = Vector3.new(20, 1.5, 10) },
	{ Id = "btn4", Name = "Turbina Quantica", Sub = "+65 Watt/s | Costo: 2.5K W", Color = Color3.fromRGB(130, 105, 255), Pos = Vector3.new(-20, 1.5, -6) },
	{ Id = "btn5", Name = "Sovralimentatore", Sub = "x1.50 Watt/s | Costo: 15K W", Color = Color3.fromRGB(255, 80, 160), Pos = Vector3.new(0, 1.5, -6) },
	{ Id = "btn6", Name = "Sintetizzatore", Sub = "+850 Watt/s | Costo: 100K W", Color = Color3.fromRGB(255, 115, 45), Pos = Vector3.new(20, 1.5, -6) },
	{ Id = "btn7", Name = "Reattore ad Arco", Sub = "+12K Watt/s | Costo: 1.5M W", Color = Color3.fromRGB(60, 175, 255), Pos = Vector3.new(-20, 1.5, -22) },
	{ Id = "btn8", Name = "Matrice Fotonica", Sub = "x2.00 Watt/s | Costo: 25M W", Color = Color3.fromRGB(210, 70, 255), Pos = Vector3.new(0, 1.5, -22) },
	{ Id = "btn9", Name = "Motore Singolarità", Sub = "+250K Watt/s | Costo: 500M W", Color = Color3.fromRGB(255, 50, 85), Pos = Vector3.new(20, 1.5, -22) },
}

for _, cfg in ipairs(buttonDefs) do
	-- Cornice scura alla base del pulsante
	makePart({
		Name = cfg.Id .. "_Frame",
		Size = Vector3.new(11.5, 0.6, 11.5),
		Position = cfg.Pos - Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(26, 30, 44),
		Material = Enum.Material.Metal,
		Parent = buttonsFolder,
	})
	-- Pad luminoso centrale
	local pad = makePart({
		Name = cfg.Id,
		Size = Vector3.new(9.5, 1.0, 9.5),
		Position = cfg.Pos,
		Color = cfg.Color,
		Material = Enum.Material.Neon,
		Parent = buttonsFolder,
	})
	makeNeonLabel(pad, cfg.Name, cfg.Sub, cfg.Color, Vector3.new(0, 4.2, 0), UDim2.fromOffset(220, 80))
end

-- 6. MURO GIGANTE UPGRADE TREE (NORD)
local wallPos = Vector3.new(0, 26, -54)
local upgradeWall = makePart({
	Name = "UpgradeWall",
	Size = Vector3.new(96, 48, 2.5),
	CFrame = CFrame.lookAt(wallPos, Vector3.new(0, 26, 50)),
	Color = Color3.fromRGB(13, 16, 26),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "UpgradeWallFrame",
	Size = Vector3.new(99, 51, 1.8),
	CFrame = CFrame.lookAt(Vector3.new(0, 26, -54.6), Vector3.new(0, 26, 50)),
	Color = Color3.fromRGB(0, 215, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

-- Contrafforti laterali del muro principale
makePart({ Name = "WallButtressL", Size = Vector3.new(5, 52, 7), Position = Vector3.new(-51, 26, -53), Color = Color3.fromRGB(24, 28, 42), Material = Enum.Material.Metal, Parent = world })
makePart({ Name = "WallButtressR", Size = Vector3.new(5, 52, 7), Position = Vector3.new(51, 26, -53), Color = Color3.fromRGB(24, 28, 42), Material = Enum.Material.Metal, Parent = world })

-- SurfaceGui di intestazione sul muro principale
local wallGui = Instance.new("SurfaceGui")
wallGui.Name = "UpgradeWallPreview"
wallGui.Face = Enum.NormalId.Front
wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
wallGui.PixelsPerStud = 20
wallGui.Parent = upgradeWall

local wallHeader = Instance.new("TextLabel")
wallHeader.Size = UDim2.new(1, 0, 0.12, 0)
wallHeader.BackgroundColor3 = Color3.fromRGB(0, 150, 215)
wallHeader.Text = "🧬 ALBERO DEI POTENZIAMENTI QUANTICI"
wallHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
wallHeader.Font = Enum.Font.GothamBlack
wallHeader.TextScaled = true
wallHeader.Parent = wallGui

-- 7. SANTUARIO MATERIA OSCURA / PRESTIGE (ALA EST)
local dmPos = Vector3.new(64, 19, -16)
local prestigeWall = makePart({
	Name = "PrestigeWall",
	Size = Vector3.new(36, 34, 2),
	CFrame = CFrame.lookAt(dmPos, Vector3.new(0, 19, 14)),
	Color = Color3.fromRGB(22, 12, 32),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "PrestigeWallFrame",
	Size = Vector3.new(38.5, 36.5, 1.5),
	CFrame = CFrame.lookAt(Vector3.new(64.6, 19, -16.3), Vector3.new(0, 19, 14)),
	Color = Color3.fromRGB(255, 45, 115),
	Material = Enum.Material.Neon,
	Parent = world,
})

local dmGui = Instance.new("SurfaceGui")
dmGui.Face = Enum.NormalId.Front
dmGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
dmGui.PixelsPerStud = 20
dmGui.Parent = prestigeWall

local dmTitle = Instance.new("TextLabel")
dmTitle.Size = UDim2.new(1, 0, 0.16, 0)
dmTitle.BackgroundColor3 = Color3.fromRGB(185, 25, 85)
dmTitle.Text = "🌌 SANTUARIO MATERIA OSCURA"
dmTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
dmTitle.Font = Enum.Font.GothamBlack
dmTitle.TextScaled = true
dmTitle.Parent = dmGui

-- 8. FABBRICA DRONI (SUD-EST)
local dronePos = Vector3.new(56, 1.5, 34)
local droneStation = makePart({
	Name = "DroneStation",
	Size = Vector3.new(15, 1.5, 15),
	Position = dronePos,
	Color = Color3.fromRGB(185, 55, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

makePart({
	Name = "DroneOuterRing",
	Size = Vector3.new(18, 0.8, 18),
	Position = dronePos - Vector3.new(0, 0.2, 0),
	Color = Color3.fromRGB(26, 20, 42),
	Material = Enum.Material.Metal,
	Parent = world,
})

local droneHolo = makePart({
	Name = "DroneHolo",
	Size = Vector3.new(4.2, 4.2, 4.2),
	Position = dronePos + Vector3.new(0, 5.5, 0),
	Color = Color3.fromRGB(230, 130, 255),
	Material = Enum.Material.ForceField,
	CanCollide = false,
	Parent = world,
})

local droneClick = Instance.new("ClickDetector")
droneClick.Name = "HatchClick"
droneClick.MaxActivationDistance = 35
droneClick.Parent = droneStation

makeNeonLabel(droneStation, "🛸 FABBRICA DRONI", "Crea satelliti orbitanti (50 Plasma)", Color3.fromRGB(220, 120, 255), Vector3.new(0, 8.5, 0), UDim2.fromOffset(250, 80))

-- 9. MONUMENTO CLASSIFICA GLOBALE (ALA OVEST)
local lbPos = Vector3.new(-64, 19, -12)
local lbWall = makePart({
	Name = "LeaderboardWall",
	Size = Vector3.new(30, 34, 2),
	CFrame = CFrame.lookAt(lbPos, Vector3.new(0, 19, 14)),
	Color = Color3.fromRGB(15, 20, 32),
	Material = Enum.Material.SmoothPlastic,
	Parent = world,
})

makePart({
	Name = "LeaderboardFrame",
	Size = Vector3.new(32.5, 36.5, 1.5),
	CFrame = CFrame.lookAt(Vector3.new(-64.6, 19, -12.3), Vector3.new(0, 19, 14)),
	Color = Color3.fromRGB(0, 185, 255),
	Material = Enum.Material.Neon,
	Parent = world,
})

local lbGui = Instance.new("SurfaceGui")
lbGui.Name = "LeaderboardGui"
lbGui.Face = Enum.NormalId.Front
lbGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
lbGui.PixelsPerStud = 20
lbGui.Parent = lbWall

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, 0, 0.15, 0)
lbTitle.BackgroundColor3 = Color3.fromRGB(0, 145, 215)
lbTitle.Text = "🏆 TOP 10 WATT GLOBALI"
lbTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
lbTitle.Font = Enum.Font.GothamBlack
lbTitle.TextScaled = true
lbTitle.Parent = lbGui

-- 10. CAMERA DI RICARICA / ZONA AFK (SUD-OVEST)
local afkPos = Vector3.new(-56, 1.5, 34)
local afkPad = makePart({
	Name = "AfkZonePad",
	Size = Vector3.new(16, 1.2, 16),
	Position = afkPos,
	Color = Color3.fromRGB(0, 255, 165),
	Material = Enum.Material.Neon,
	Parent = world,
})

makePart({
	Name = "AfkDomeRing",
	Size = Vector3.new(19, 0.6, 19),
	Position = afkPos + Vector3.new(0, 11, 0),
	Color = Color3.fromRGB(0, 255, 165),
	Material = Enum.Material.Neon,
	Transparency = 0.3,
	CanCollide = false,
	Parent = world,
})

makeNeonLabel(afkPad, "🔋 CAMERA DI RICARICA AFK", "Resta qui per ricaricare l'energia", Color3.fromRGB(0, 255, 165), Vector3.new(0, 6.5, 0), UDim2.fromOffset(250, 75))

-- 11. ANIMAZIONI AMBIENTALI IN TEMPO REALE
task.spawn(function()
	local t = 0
	while world and world.Parent do
		local dt = task.wait(0.03)
		t += dt

		ring1.CFrame = CFrame.new(coreCenter) * CFrame.Angles(t * 1.1, t * 0.8, 0)
		ring2.CFrame = CFrame.new(coreCenter) * CFrame.Angles(-t * 0.7, 0, t * 1.2)
		corePart.Position = coreCenter + Vector3.new(0, math.sin(t * 2.5) * 0.45, 0)

		droneHolo.CFrame = CFrame.new(dronePos + Vector3.new(0, 5.5 + math.sin(t * 2.2) * 0.5, 0))
			* CFrame.Angles(t * 0.9, t * 1.4, 0)

		for idx, crys in ipairs(animatedCrystals) do
			local baseP = cornerCoords[idx] + Vector3.new(0, 36 + math.sin(t * 2 + idx) * 0.8, 0)
			crys.CFrame = CFrame.new(baseP) * CFrame.Angles(t * 1.2, t * 1.5, 0)
		end
	end
end)