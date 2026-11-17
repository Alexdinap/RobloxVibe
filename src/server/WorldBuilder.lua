local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local WorldBuilder = {}

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

local function makeCylinder(pos, radius, height, color, material, parent, name)
	return makePart({
		Name = name or "Cylinder",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
end

local function setupAtmosphere()
	Lighting.ClockTime = 0.2
	Lighting.Brightness = 1.0
	Lighting.Ambient = Color3.fromRGB(16, 18, 28)
	Lighting.OutdoorAmbient = Color3.fromRGB(22, 25, 38)
	Lighting.FogColor = Color3.fromRGB(10, 12, 20)
	Lighting.FogStart = 200
	Lighting.FogEnd = 1350

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere", Lighting)
		atm.Density = 0.26
		atm.Color = Color3.fromRGB(22, 25, 42)
		atm.Decay = Color3.fromRGB(12, 14, 24)
	end
end

local function buildSinglePlot(index, origin, plotsFolder)
	local plotModel = Instance.new("Model", plotsFolder)
	plotModel.Name = "Plot_" .. index

	-- 1. Isola Circolare in Pietra Antica (Sobria per far risaltare il Braciere)
	makeCylinder(origin + Vector3.new(0, -1.5, 0), 62, 3, Color3.fromRGB(24, 26, 36), Enum.Material.Slate, plotModel, "IslandBase")
	makeCylinder(origin + Vector3.new(0, 0.05, 0), 62.5, 0.4, Color3.fromRGB(68, 56, 42), Enum.Material.Marble, plotModel, "IslandRim")
	makeCylinder(origin + Vector3.new(0, 0.15, 0), 38, 0.35, Color3.fromRGB(32, 35, 48), Enum.Material.Marble, plotModel, "InnerSanctuary")

	makePart({
		Name = "EntryPath",
		Size = Vector3.new(9, 0.45, 36),
		Position = origin + Vector3.new(0, 0.2, 20),
		Color = Color3.fromRGB(44, 48, 64),
		Material = Enum.Material.Cobblestone,
		Parent = plotModel,
	})

	-- Colonne Decorative sobrie (SENZA luci extra per dare priorità al Braciere)
	for p = 1, 8 do
		local ang = (p - 1) * (math.pi * 2 / 8) + math.pi / 8
		local pPos = origin + Vector3.new(math.cos(ang) * 56, 5.0, math.sin(ang) * 56)
		makePart({
			Name = "Pillar_" .. p,
			Size = Vector3.new(2.8, 10, 2.8),
			Position = pPos,
			Color = Color3.fromRGB(34, 37, 50),
			Material = Enum.Material.Marble,
			Parent = plotModel,
		})
		makePart({
			Name = "PillarCap_" .. p,
			Size = Vector3.new(3.4, 0.8, 3.4),
			Position = pPos + Vector3.new(0, 5.4, 0),
			Color = Color3.fromRGB(52, 56, 74),
			Material = Enum.Material.Slate,
			Parent = plotModel,
		})
	end

	-- 2. Cartello Proprietario della Zona (Scritte compatte)
	local signBoard = makePart({
		Name = "PlotSign",
		Size = Vector3.new(13, 4.4, 1.0),
		Position = origin + Vector3.new(0, 4.5, 42),
		Color = Color3.fromRGB(20, 22, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = plotModel,
	})
	local signGui = Instance.new("SurfaceGui", signBoard)
	signGui.Name = "SignGui"
	signGui.Face = Enum.NormalId.Back
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 32

	local signTitle = Instance.new("TextLabel", signGui)
	signTitle.Name = "OwnerTitle"
	signTitle.Size = UDim2.new(1, -16, 0.5, 0)
	signTitle.Position = UDim2.fromOffset(8, 6)
	signTitle.BackgroundTransparency = 1
	signTitle.Text = "ZONA " .. index .. " — LIBERA"
	signTitle.TextColor3 = Color3.fromRGB(255, 200, 75)
	signTitle.Font = Enum.Font.GothamBlack
	signTitle.TextSize = 24

	local signSub = Instance.new("TextLabel", signGui)
	signSub.Name = "OwnerSub"
	signSub.Size = UDim2.new(1, -16, 0.4, 0)
	signSub.Position = UDim2.new(0, 8, 0.54, 0)
	signSub.BackgroundTransparency = 1
	signSub.Text = "In attesa di un Custode"
	signSub.TextColor3 = Color3.fromRGB(175, 185, 205)
	signSub.Font = Enum.Font.GothamBold
	signSub.TextSize = 17

	local signGuiFront = signGui:Clone()
	signGuiFront.Name = "SignGuiFront"
	signGuiFront.Face = Enum.NormalId.Front
	signGuiFront.Parent = signBoard

	-- 3. Il Braciere Centrale dell'Isola (Punto focale luminoso principale)
	local brazierFolder = Instance.new("Folder", plotModel)
	brazierFolder.Name = "Brazier"

	makeCylinder(origin + Vector3.new(0, 0.7, 0), 10.2, 1.2, Color3.fromRGB(34, 36, 48), Enum.Material.Basalt, brazierFolder, "PedestalStep1")
	makeCylinder(origin + Vector3.new(0, 1.6, 0), 8.0, 1.0, Color3.fromRGB(46, 48, 66), Enum.Material.Marble, brazierFolder, "PedestalStep2")
	makeCylinder(origin + Vector3.new(0, 2.5, 0), 6.0, 1.4, Color3.fromRGB(24, 24, 32), Enum.Material.Slate, brazierFolder, "BrazierBowl")

	-- Anello di braci incandescenti dentro la coppa del Braciere
	local emberRing = makeCylinder(origin + Vector3.new(0, 3.25, 0), 4.8, 0.35, Color3.fromRGB(255, 145, 45), Enum.Material.Neon, brazierFolder, "EmberRing")
	emberRing.CanCollide = false

	local flameCore = makePart({
		Name = "FlameCore",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6.8, 8.6, 6.8),
		Position = origin + Vector3.new(0, 6.5, 0),
		Color = Color3.fromRGB(255, 145, 45),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = brazierFolder,
	})
	local fLight = Instance.new("PointLight", flameCore)
	fLight.Color = Color3.fromRGB(255, 165, 65)
	fLight.Range = 46
	fLight.Brightness = 3.8
	fLight.Shadows = true

	local particles = Instance.new("ParticleEmitter", flameCore)
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 185, 65))
	particles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
	particles.Lifetime = NumberRange.new(1.1, 2.0)
	particles.Rate = 38
	particles.Speed = NumberRange.new(4, 9)
	particles.SpreadAngle = Vector2.new(26, 26)

	local flameHitbox = makePart({
		Name = "FlameHitbox",
		Size = Vector3.new(14, 15, 14),
		Position = origin + Vector3.new(0, 6.8, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = brazierFolder,
	})

	local flameBbg = Instance.new("BillboardGui", flameHitbox)
	flameBbg.Name = "FlameBillboard"
	flameBbg.Size = UDim2.fromOffset(180, 34)
	flameBbg.StudsOffset = Vector3.new(0, 8.2, 0)
	flameBbg.AlwaysOnTop = false

	local flameTitle = Instance.new("TextLabel", flameBbg)
	flameTitle.Name = "Title"
	flameTitle.Size = UDim2.fromScale(1, 1)
	flameTitle.BackgroundTransparency = 1
	flameTitle.Text = "FIAMMA ZONA " .. index
	flameTitle.TextColor3 = Color3.fromRGB(255, 215, 95)
	flameTitle.TextStrokeTransparency = 0.25
	flameTitle.Font = Enum.Font.GothamBlack
	flameTitle.TextSize = 15

	-- 4. Gli 8 Pulsanti a Terra del Braciere (Scritte compatte)
	local altarsFolder = Instance.new("Folder", plotModel)
	altarsFolder.Name = "Altars"

	for _, alt in ipairs(GameConfig.Altars) do
		local padPos = origin + alt.Pos
		makeCylinder(padPos - Vector3.new(0, 0.25, 0), 4.5, 0.5, Color3.fromRGB(26, 28, 38), Enum.Material.Marble, altarsFolder, alt.Id .. "_Base")

		local pad = makeCylinder(padPos, 3.7, 0.6, alt.Color, Enum.Material.SmoothPlastic, altarsFolder, alt.Id)
		pad.CanCollide = false

		local bbg = Instance.new("BillboardGui", pad)
		bbg.Size = UDim2.fromOffset(175, 44)
		bbg.StudsOffset = Vector3.new(0, 3.6, 0)
		bbg.AlwaysOnTop = false

		local t1 = Instance.new("TextLabel", bbg)
		t1.Name = "TitleLabel"
		t1.Size = UDim2.new(1, 0, 0.5, 0)
		t1.Position = UDim2.fromScale(0, 0)
		t1.BackgroundTransparency = 1
		t1.Text = string.format("%s [0/%d]", alt.Name, alt.MaxLevel or 1)
		t1.TextColor3 = alt.Color
		t1.TextStrokeTransparency = 0.25
		t1.Font = Enum.Font.GothamBold
		t1.TextSize = 13

		local t2 = Instance.new("TextLabel", bbg)
		t2.Name = "CostLabel"
		t2.Size = UDim2.new(1, 0, 0.48, 0)
		t2.Position = UDim2.fromScale(0, 0.52)
		t2.BackgroundTransparency = 1
		t2.Text = NumberFormat.Format(alt.BaseCost) .. " Luce"
		t2.TextColor3 = Color3.fromRGB(235, 240, 250)
		t2.TextStrokeTransparency = 0.3
		t2.Font = Enum.Font.Gotham
		t2.TextSize = 12
	end

	-- 5. Pulsante della Vittoria (Parte NASCOSTO finché non finisci tutti i potenziamenti)
	local vCfg = GameConfig.VictoryButton
	local vPos = origin + vCfg.Pos
	local vModel = Instance.new("Model", plotModel)
	vModel.Name = "VictoryButtonPedestal"

	local vBase = makeCylinder(vPos, 6.8, 0.7, Color3.fromRGB(32, 34, 46), Enum.Material.Marble, vModel, "Base")
	vBase.Transparency = 1
	vBase.CanCollide = false

	local vRim = makeCylinder(vPos + Vector3.new(0, 0.1, 0), 5.9, 0.85, Color3.fromRGB(255, 190, 45), Enum.Material.Neon, vModel, "GoldRim")
	vRim.Transparency = 1
	vRim.CanCollide = false

	local victoryPad = makeCylinder(vPos + Vector3.new(0, 0.22, 0), 5.0, 1.0, Color3.fromRGB(255, 225, 85), Enum.Material.Neon, vModel, "VictoryPad")
	victoryPad.Transparency = 1
	victoryPad.CanCollide = false

	local vBbg = Instance.new("BillboardGui", victoryPad)
	vBbg.Name = "VictoryBillboard"
	vBbg.Size = UDim2.fromOffset(200, 48)
	vBbg.StudsOffset = Vector3.new(0, 4.8, 0)
	vBbg.AlwaysOnTop = false
	vBbg.Enabled = false

	local vTitle = Instance.new("TextLabel", vBbg)
	vTitle.Name = "TitleLabel"
	vTitle.Size = UDim2.new(1, 0, 0.5, 0)
	vTitle.BackgroundTransparency = 1
	vTitle.Text = "👑 " .. vCfg.Name
	vTitle.TextColor3 = Color3.fromRGB(255, 225, 80)
	vTitle.TextStrokeTransparency = 0.2
	vTitle.Font = Enum.Font.GothamBlack
	vTitle.TextSize = 14

	local vCostLbl = Instance.new("TextLabel", vBbg)
	vCostLbl.Name = "StatusLabel"
	vCostLbl.Size = UDim2.new(1, 0, 0.48, 0)
	vCostLbl.Position = UDim2.fromScale(0, 0.52)
	vCostLbl.BackgroundTransparency = 1
	vCostLbl.Text = "Costo: " .. NumberFormat.Format(vCfg.Cost) .. " Luce"
	vCostLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	vCostLbl.TextStrokeTransparency = 0.25
	vCostLbl.Font = Enum.Font.GothamBold
	vCostLbl.TextSize = 12

	-- 6. Bracieri Rituali di Regno 1 per la Zona
	local ritualFolder = Instance.new("Folder", plotModel)
	ritualFolder.Name = "Regno1Ritual"
	for _, b in ipairs(GameConfig.Regno1.Braziers) do
		local bPos = origin + b.Pos
		makeCylinder(bPos, 3.0, b.PedestalHeight, Color3.fromRGB(38, 41, 56), Enum.Material.Marble, ritualFolder, "Brazier_" .. b.Index)
	end

	return {
		Index = index,
		Origin = origin,
		SpawnPos = origin + Vector3.new(0, 4.5, 16),
		Model = plotModel,
		SignBoard = signBoard,
		FlameCore = flameCore,
		EmberRing = emberRing,
		BaseFlameSize = flameCore.Size,
		BaseFlamePos = flameCore.Position,
		BrazierBowl = bowl,
		FlameHitbox = flameHitbox,
		FlameTitle = flameTitle,
		AltarsFolder = altarsFolder,
		VictoryModel = vModel,
		VictoryPad = victoryPad,
		VictoryBillboard = vBbg,
		VictoryStatusLabel = vCostLbl,
		RitualFolder = ritualFolder,
		Owner = nil,
	}
end

function WorldBuilder.Build()
	setupAtmosphere()

	local old = Workspace:FindFirstChild("LastFlameWorld")
	if old then old:Destroy() end

	local world = Instance.new("Folder", Workspace)
	world.Name = "LastFlameWorld"

	-- Isola Centrale di Ritrovo (Sobria, senza neon eccessivi)
	local hubModel = Instance.new("Model", world)
	hubModel.Name = "CentralPlaza"
	makeCylinder(Vector3.new(0, -2, 0), 34, 4, Color3.fromRGB(22, 24, 34), Enum.Material.Slate, hubModel, "HubBase")
	makeCylinder(Vector3.new(0, 0.1, 0), 34.4, 0.4, Color3.fromRGB(58, 72, 96), Enum.Material.Marble, hubModel, "HubRim")

	local spawnLoc = Instance.new("SpawnLocation", hubModel)
	spawnLoc.Name = "LobbySpawn"
	spawnLoc.Anchored = true
	spawnLoc.Size = Vector3.new(12, 1, 12)
	spawnLoc.Position = Vector3.new(0, 0.5, 0)
	spawnLoc.Transparency = 1
	spawnLoc.CanCollide = false

	-- Costruzione delle 10 Zone Individuali disposte ad anello
	local plotsFolder = Instance.new("Folder", world)
	plotsFolder.Name = "Plots"

	local maxPlots = GameConfig.MaxPlots or 10
	local ringRadius = GameConfig.PlotRingRadius or 430
	local plots = {}

	for i = 1, maxPlots do
		local angle = ((i - 1) / maxPlots) * (math.pi * 2)
		local origin = Vector3.new(
			math.floor(math.cos(angle) * ringRadius + 0.5),
			0,
			math.floor(math.sin(angle) * ringRadius + 0.5)
		)

		local bridgeLen = ringRadius - 92
		local bridgeMid = origin.Unit * (34 + bridgeLen * 0.5) - Vector3.new(0, 0.4, 0)
		local bridge = makePart({
			Name = "LightBridge_" .. i,
			Size = Vector3.new(7, 0.5, bridgeLen),
			CFrame = CFrame.lookAt(bridgeMid, origin),
			Color = Color3.fromRGB(34, 38, 52),
			Material = Enum.Material.Cobblestone,
			Parent = hubModel,
		})
		bridge:SetAttribute("PlotIndex", i)

		plots[i] = buildSinglePlot(i, origin, plotsFolder)
	end

	return {
		World = world,
		PlotsFolder = plotsFolder,
		Plots = plots,
		AltarsFolder = plots[1].AltarsFolder,
		FlameCore = plots[1].FlameCore,
		BrazierBowl = plots[1].BrazierBowl,
		FlameHitbox = plots[1].FlameHitbox,
		RitualFolder = plots[1].RitualFolder,
	}
end

return WorldBuilder