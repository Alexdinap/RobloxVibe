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
	Lighting.ClockTime = 0.5
	Lighting.Brightness = 1.4
	Lighting.Ambient = Color3.fromRGB(22, 24, 38)
	Lighting.OutdoorAmbient = Color3.fromRGB(30, 34, 52)
	Lighting.FogColor = Color3.fromRGB(12, 14, 24)
	Lighting.FogStart = 180
	Lighting.FogEnd = 1350

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere", Lighting)
		atm.Density = 0.24
		atm.Color = Color3.fromRGB(28, 32, 54)
		atm.Decay = Color3.fromRGB(14, 16, 28)
	end
end

local function buildSinglePlot(index, origin, plotsFolder)
	local plotModel = Instance.new("Model", plotsFolder)
	plotModel.Name = "Plot_" .. index

	-- 1. Isola Circolare in Pietra Antica (Raggio 62 studs)
	makeCylinder(origin + Vector3.new(0, -1.5, 0), 62, 3, Color3.fromRGB(28, 30, 42), Enum.Material.Slate, plotModel, "IslandBase")
	makeCylinder(origin + Vector3.new(0, 0.05, 0), 62.6, 0.5, Color3.fromRGB(255, 175, 65), Enum.Material.Neon, plotModel, "IslandRim")
	makeCylinder(origin + Vector3.new(0, 0.15, 0), 38, 0.4, Color3.fromRGB(38, 41, 56), Enum.Material.Marble, plotModel, "InnerSanctuary")

	-- Sentiero di Pietra dal Spawn al Braciere
	makePart({
		Name = "EntryPath",
		Size = Vector3.new(9, 0.45, 36),
		Position = origin + Vector3.new(0, 0.2, 20),
		Color = Color3.fromRGB(52, 56, 74),
		Material = Enum.Material.Cobblestone,
		Parent = plotModel,
	})

	-- Colonne Decorative attorno all'isola
	for p = 1, 8 do
		local ang = (p - 1) * (math.pi * 2 / 8) + math.pi / 8
		local pPos = origin + Vector3.new(math.cos(ang) * 56, 5.5, math.sin(ang) * 56)
		makePart({
			Name = "Pillar_" .. p,
			Size = Vector3.new(3.2, 11, 3.2),
			Position = pPos,
			Color = Color3.fromRGB(40, 44, 60),
			Material = Enum.Material.Marble,
			Parent = plotModel,
		})
		local cap = makePart({
			Name = "PillarCrystal_" .. p,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.2, 2.2, 2.2),
			Position = pPos + Vector3.new(0, 6.8, 0),
			Color = Color3.fromRGB(255, 190, 75),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = plotModel,
		})
		local pl = Instance.new("PointLight", cap)
		pl.Color = Color3.fromRGB(255, 190, 75)
		pl.Range = 14
		pl.Brightness = 1.2
	end

	-- 2. Cartello Proprietario della Zona
	local signBoard = makePart({
		Name = "PlotSign",
		Size = Vector3.new(16, 6, 1.2),
		Position = origin + Vector3.new(0, 5.5, 42),
		Color = Color3.fromRGB(22, 24, 34),
		Material = Enum.Material.SmoothPlastic,
		Parent = plotModel,
	})
	local signGui = Instance.new("SurfaceGui", signBoard)
	signGui.Name = "SignGui"
	signGui.Face = Enum.NormalId.Back

	local signTitle = Instance.new("TextLabel", signGui)
	signTitle.Name = "OwnerTitle"
	signTitle.Size = UDim2.new(1, -20, 0.55, 0)
	signTitle.Position = UDim2.fromOffset(10, 8)
	signTitle.BackgroundTransparency = 1
	signTitle.Text = "🏝️ ZONA " .. index .. " — LIBERA"
	signTitle.TextColor3 = Color3.fromRGB(255, 200, 75)
	signTitle.Font = Enum.Font.GothamBlack
	signTitle.TextScaled = true

	local signSub = Instance.new("TextLabel", signGui)
	signSub.Name = "OwnerSub"
	signSub.Size = UDim2.new(1, -20, 0.35, 0)
	signSub.Position = UDim2.new(0, 10, 0.6, 0)
	signSub.BackgroundTransparency = 1
	signSub.Text = "In attesa di un Custode..."
	signSub.TextColor3 = Color3.fromRGB(185, 195, 215)
	signSub.Font = Enum.Font.GothamBold
	signSub.TextScaled = true

	local signGuiFront = signGui:Clone()
	signGuiFront.Name = "SignGuiFront"
	signGuiFront.Face = Enum.NormalId.Front
	signGuiFront.Parent = signBoard

	-- 3. Il Braciere Personale del Giocatore
	local brazierFolder = Instance.new("Folder", plotModel)
	brazierFolder.Name = "Brazier"

	makeCylinder(origin + Vector3.new(0, 0.7, 0), 9.5, 1.2, Color3.fromRGB(36, 38, 52), Enum.Material.Basalt, brazierFolder, "PedestalStep1")
	makeCylinder(origin + Vector3.new(0, 1.6, 0), 7.4, 1.0, Color3.fromRGB(48, 50, 68), Enum.Material.Marble, brazierFolder, "PedestalStep2")

	local bowl = makeCylinder(origin + Vector3.new(0, 2.5, 0), 5.6, 1.4, Color3.fromRGB(26, 26, 34), Enum.Material.Slate, brazierFolder, "BrazierBowl")

	local flameCore = makePart({
		Name = "FlameCore",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(6.2, 7.8, 6.2),
		Position = origin + Vector3.new(0, 6.2, 0),
		Color = Color3.fromRGB(255, 145, 45),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = brazierFolder,
	})
	local fLight = Instance.new("PointLight", flameCore)
	fLight.Color = Color3.fromRGB(255, 165, 65)
	fLight.Range = 28
	fLight.Brightness = 2.4

	local particles = Instance.new("ParticleEmitter", flameCore)
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 180, 60))
	particles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	particles.Lifetime = NumberRange.new(1.0, 1.8)
	particles.Rate = 24
	particles.Speed = NumberRange.new(4, 8)
	particles.SpreadAngle = Vector2.new(25, 25)

	local flameHitbox = makePart({
		Name = "FlameHitbox",
		Size = Vector3.new(13, 14, 13),
		Position = origin + Vector3.new(0, 6.5, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = brazierFolder,
	})

	local flameBbg = Instance.new("BillboardGui", flameHitbox)
	flameBbg.Name = "FlameBillboard"
	flameBbg.Size = UDim2.fromOffset(260, 64)
	flameBbg.StudsOffset = Vector3.new(0, 8.5, 0)
	flameBbg.AlwaysOnTop = false

	local flameTitle = Instance.new("TextLabel", flameBbg)
	flameTitle.Name = "Title"
	flameTitle.Size = UDim2.fromScale(1, 1)
	flameTitle.BackgroundTransparency = 1
	flameTitle.Text = "🔥 FIAMMA ZONA " .. index
	flameTitle.TextColor3 = Color3.fromRGB(255, 215, 95)
	flameTitle.TextStrokeTransparency = 0.25
	flameTitle.Font = Enum.Font.GothamBlack
	flameTitle.TextScaled = true

	-- 4. Gli 8 Pulsanti a Terra del Braciere della Zona
	local altarsFolder = Instance.new("Folder", plotModel)
	altarsFolder.Name = "Altars"

	for _, alt in ipairs(GameConfig.Altars) do
		local padPos = origin + alt.Pos
		makeCylinder(padPos - Vector3.new(0, 0.25, 0), 4.6, 0.5, Color3.fromRGB(26, 28, 38), Enum.Material.Marble, altarsFolder, alt.Id .. "_Base")

		local pad = makeCylinder(padPos, 3.8, 0.65, alt.Color, Enum.Material.Neon, altarsFolder, alt.Id)
		pad.CanCollide = false

		local bbg = Instance.new("BillboardGui", pad)
		bbg.Size = UDim2.fromOffset(230, 74)
		bbg.StudsOffset = Vector3.new(0, 4.6, 0)
		bbg.AlwaysOnTop = false

		local t1 = Instance.new("TextLabel", bbg)
		t1.Size = UDim2.new(1, 0, 0.52, 0)
		t1.Position = UDim2.fromScale(0, 0)
		t1.BackgroundTransparency = 1
		t1.Text = "🔥 " .. alt.Name .. " [Lv.0]"
		t1.TextColor3 = alt.Color
		t1.TextStrokeTransparency = 0.25
		t1.Font = Enum.Font.GothamBlack
		t1.TextScaled = true

		local t2 = Instance.new("TextLabel", bbg)
		t2.Size = UDim2.new(1, 0, 0.44, 0)
		t2.Position = UDim2.fromScale(0, 0.54)
		t2.BackgroundTransparency = 1
		t2.Text = "Costo: " .. NumberFormat.Format(alt.BaseCost) .. " Luce"
		t2.TextColor3 = Color3.fromRGB(255, 255, 255)
		t2.TextStrokeTransparency = 0.3
		t2.Font = Enum.Font.GothamBold
		t2.TextScaled = true
	end

	-- 5. Pulsante della Vittoria della Zona
	local vCfg = GameConfig.VictoryButton
	local vPos = origin + vCfg.Pos
	local vModel = Instance.new("Model", plotModel)
	vModel.Name = "VictoryButtonPedestal"

	makeCylinder(vPos, 7.2, 0.7, Color3.fromRGB(32, 34, 46), Enum.Material.Marble, vModel, "Base")
	makeCylinder(vPos + Vector3.new(0, 0.1, 0), 6.3, 0.85, Color3.fromRGB(255, 190, 45), Enum.Material.Neon, vModel, "GoldRim")

	local victoryPad = makeCylinder(vPos + Vector3.new(0, 0.22, 0), 5.3, 1.0, Color3.fromRGB(255, 225, 85), Enum.Material.Neon, vModel, "VictoryPad")
	victoryPad.CanCollide = false

	local vBbg = Instance.new("BillboardGui", victoryPad)
	vBbg.Name = "VictoryBillboard"
	vBbg.Size = UDim2.fromOffset(270, 86)
	vBbg.StudsOffset = Vector3.new(0, 6.0, 0)
	vBbg.AlwaysOnTop = false

	local vTitle = Instance.new("TextLabel", vBbg)
	vTitle.Name = "TitleLabel"
	vTitle.Size = UDim2.new(1, 0, 0.52, 0)
	vTitle.BackgroundTransparency = 1
	vTitle.Text = "👑 " .. vCfg.Name .. " 👑"
	vTitle.TextColor3 = Color3.fromRGB(255, 225, 80)
	vTitle.TextStrokeTransparency = 0.2
	vTitle.Font = Enum.Font.GothamBlack
	vTitle.TextScaled = true

	local vCostLbl = Instance.new("TextLabel", vBbg)
	vCostLbl.Name = "StatusLabel"
	vCostLbl.Size = UDim2.new(1, 0, 0.44, 0)
	vCostLbl.Position = UDim2.fromScale(0, 0.54)
	vCostLbl.BackgroundTransparency = 1
	vCostLbl.Text = "🔥 Costo: " .. NumberFormat.Format(vCfg.Cost) .. " Punti Luce"
	vCostLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	vCostLbl.TextStrokeTransparency = 0.25
	vCostLbl.Font = Enum.Font.GothamBold
	vCostLbl.TextScaled = true

	-- 6. Bracieri Rituali di Regno 1 per la Zona
	local ritualFolder = Instance.new("Folder", plotModel)
	ritualFolder.Name = "Regno1Ritual"
	for _, b in ipairs(GameConfig.Regno1.Braziers) do
		local bPos = origin + b.Pos
		makeCylinder(bPos, 3.2, b.PedestalHeight, Color3.fromRGB(42, 45, 62), Enum.Material.Marble, ritualFolder, "Brazier_" .. b.Index)
	end

	return {
		Index = index,
		Origin = origin,
		SpawnPos = origin + Vector3.new(0, 4.5, 16),
		Model = plotModel,
		SignBoard = signBoard,
		FlameCore = flameCore,
		BaseFlameSize = flameCore.Size,
		BaseFlamePos = flameCore.Position,
		BrazierBowl = bowl,
		FlameHitbox = flameHitbox,
		FlameTitle = flameTitle,
		AltarsFolder = altarsFolder,
		VictoryPad = victoryPad,
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

	-- Isola Centrale di Ritrovo
	local hubModel = Instance.new("Model", world)
	hubModel.Name = "CentralPlaza"
	makeCylinder(Vector3.new(0, -2, 0), 34, 4, Color3.fromRGB(24, 26, 38), Enum.Material.Slate, hubModel, "HubBase")
	makeCylinder(Vector3.new(0, 0.1, 0), 34.5, 0.5, Color3.fromRGB(110, 210, 255), Enum.Material.Neon, hubModel, "HubRim")

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

		-- Ponte di Luce che collega l'isola centrale alla Zona
		local bridgeLen = ringRadius - 92
		local bridgeMid = origin.Unit * (34 + bridgeLen * 0.5) - Vector3.new(0, 0.4, 0)
		local bridge = makePart({
			Name = "LightBridge_" .. i,
			Size = Vector3.new(7, 0.5, bridgeLen),
			CFrame = CFrame.lookAt(bridgeMid, origin),
			Color = Color3.fromRGB(45, 65, 95),
			Material = Enum.Material.Neon,
			Transparency = 0.35,
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
