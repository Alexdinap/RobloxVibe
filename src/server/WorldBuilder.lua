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

function WorldBuilder.Build()
	Lighting.Brightness = 0.15
	Lighting.ClockTime = 0
	Lighting.Ambient = Color3.fromRGB(8, 10, 18)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 12, 22)

	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == "Baseplate" or obj.Name == "SantuarioDellaFiamma" or obj:IsA("SpawnLocation") then
			obj:Destroy()
		end
	end

	local world = Instance.new("Folder")
	world.Name = "SantuarioDellaFiamma"
	world.Parent = workspace

	makePart({ Name = "SanctuaryGround", Size = Vector3.new(300, 2, 300), Position = Vector3.new(0, 0, 0), Color = Color3.fromRGB(20, 22, 28), Material = Enum.Material.Slate, Parent = world })
	makePart({ Name = "InnerStoneRing", Size = Vector3.new(54, 0.15, 54), Position = Vector3.new(0, 1.05, 0), Color = Color3.fromRGB(30, 32, 40), Material = Enum.Material.Cobblestone, Parent = world })
	makePart({ Name = "OuterStoneRing", Size = Vector3.new(86, 0.1, 86), Position = Vector3.new(0, 1.02, 0), Color = Color3.fromRGB(25, 27, 34), Material = Enum.Material.Cobblestone, Parent = world })

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SanctuarySpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 0.5, 10)
	spawn.CFrame = CFrame.lookAt(Vector3.new(-8, 1.25, 34), Vector3.new(0, 1.25, 0))
	spawn.Color = Color3.fromRGB(55, 45, 35)
	spawn.Material = Enum.Material.Cobblestone
	spawn.Parent = world

	-- Fiamma Primordiale
	local flameModel = Instance.new("Model")
	flameModel.Name = "PrimordialFlame"
	flameModel.Parent = world

	makePart({ Name = "BrazierStone", Size = Vector3.new(11, 1.5, 11), Position = Vector3.new(0, 1.75, 0), Color = Color3.fromRGB(35, 36, 42), Material = Enum.Material.Cobblestone, Parent = flameModel })
	local brazierBowl = makePart({ Name = "BrazierBowl", Size = Vector3.new(7.5, 1.2, 7.5), Position = Vector3.new(0, 3.0, 0), Color = Color3.fromRGB(52, 38, 26), Material = Enum.Material.Metal, Parent = flameModel })

	local flameCore = makePart({
		Name = "FlameCore",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(3.8, 4.8, 3.8),
		Position = Vector3.new(0, 5.6, 0),
		Color = Color3.fromRGB(255, 165, 45),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = flameModel,
	})

	local flameHitbox = makePart({
		Name = "FlameHitbox",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(13, 13, 13),
		Position = Vector3.new(0, 5.5, 0),
		Transparency = 1,
		CanCollide = false,
		Parent = flameModel,
	})

	local fireFx = Instance.new("Fire")
	fireFx.Name = "FlameFire"
	fireFx.Size = 10
	fireFx.Heat = 15
	fireFx.Color = Color3.fromRGB(255, 180, 55)
	fireFx.SecondaryColor = Color3.fromRGB(255, 75, 20)
	fireFx.Parent = flameCore

	local flameLight = Instance.new("PointLight")
	flameLight.Name = "MainFlameLight"
	flameLight.Color = Color3.fromRGB(255, 185, 85)
	flameLight.Range = 28
	flameLight.Brightness = 2.6
	flameLight.Parent = flameCore

	local flameBb = Instance.new("BillboardGui")
	flameBb.Size = UDim2.fromOffset(230, 38)
	flameBb.StudsOffset = Vector3.new(0, 5.0, 0)
	flameBb.MaxDistance = 55
	flameBb.Parent = flameCore

	local flameLbl = Instance.new("TextLabel")
	flameLbl.Size = UDim2.fromScale(1, 1)
	flameLbl.BackgroundTransparency = 1
	flameLbl.Text = "🔥 CLICCA LA FIAMMA 🔥"
	flameLbl.TextColor3 = Color3.fromRGB(255, 220, 125)
	flameLbl.TextStrokeTransparency = 0.25
	flameLbl.Font = Enum.Font.GothamBlack
	flameLbl.TextScaled = true
	flameLbl.Parent = flameBb

	-- Gli 8 Altari a Terra
	local altarsFolder = Instance.new("Folder")
	altarsFolder.Name = "LightAltars"
	altarsFolder.Parent = world

	for _, cfg in ipairs(GameConfig.Altars) do
		local pad = makePart({
			Name = cfg.Id,
			Size = Vector3.new(7.5, 0.9, 7.5),
			Position = cfg.Pos,
			Color = cfg.Color,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
			Parent = altarsFolder,
		})
		local pLight = Instance.new("PointLight", pad)
		pLight.Color = cfg.Color
		pLight.Range = 12
		pLight.Brightness = 1.2

		local bb = Instance.new("BillboardGui")
		bb.Name = "InfoGui"
		bb.Size = UDim2.fromOffset(175, 56)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.MaxDistance = 38
		bb.Parent = pad

		local bg = Instance.new("Frame", bb)
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
		bg.BackgroundTransparency = 0.25
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
		local st = Instance.new("UIStroke", bg)
		st.Color = cfg.Color
		st.Transparency = 0.45

		local t1 = Instance.new("TextLabel", bg)
		t1.Name = "TitleLabel"
		t1.Size = UDim2.new(1, -8, 0.5, 0)
		t1.Position = UDim2.fromOffset(4, 2)
		t1.BackgroundTransparency = 1
		t1.Text = cfg.Name
		t1.TextColor3 = cfg.Color
		t1.Font = Enum.Font.GothamBlack
		t1.TextScaled = true

		local t2 = Instance.new("TextLabel", bg)
		t2.Name = "SubLabel"
		t2.Size = UDim2.new(1, -8, 0.45, 0)
		t2.Position = UDim2.new(0, 4, 0.52, 0)
		t2.BackgroundTransparency = 1
		t2.Text = "Lv. 0 • " .. NumberFormat.Format(cfg.BaseCost)
		t2.TextColor3 = Color3.fromRGB(235, 232, 220)
		t2.Font = Enum.Font.GothamBold
		t2.TextScaled = true
	end

	-- I 5 Regni
	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "WorldZones"
	zonesFolder.Parent = world

	-- REGNO 1: Anello dei Bracieri + I 5 Bracieri Rituali della Catena del Fuoco
	local braziersFolder = Instance.new("Folder", zonesFolder)
	braziersFolder.Name = "Braziers"
	for i = 1, 12 do
		local ang = (i / 12) * math.pi * 2
		local pos = Vector3.new(math.cos(ang) * 44, 1, math.sin(ang) * 44)
		makePart({ Name = "Post_" .. i, Size = Vector3.new(2, 5.5, 2), Position = pos + Vector3.new(0, 2.75, 0), Color = Color3.fromRGB(32, 32, 38), Material = Enum.Material.Cobblestone, Parent = braziersFolder })
		local top = makePart({ Name = "Torch_" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), Position = pos + Vector3.new(0, 6.2, 0), Color = Color3.fromRGB(25, 25, 30), Material = Enum.Material.SmoothPlastic, Parent = braziersFolder })
		local l = Instance.new("PointLight", top); l.Color = Color3.fromRGB(255, 165, 50); l.Range = 28; l.Brightness = 0; l.Enabled = false
	end

	-- 5 Bracieri Antichi Interattivi di Regno 1
	local ritualFolder = Instance.new("Folder", braziersFolder)
	ritualFolder.Name = "RitualBraziers"

	for _, bCfg in ipairs(GameConfig.Regno1.Braziers) do
		local bModel = Instance.new("Model", ritualFolder)
		bModel.Name = "RitualBrazier_" .. bCfg.Index

		local h = bCfg.PedestalHeight
		local basePos = bCfg.Pos

		-- Pedana di pietra con scalino dolce (facile da saltare/raggiungere)
		makePart({
			Name = "Pedestal",
			Size = Vector3.new(7.5, h, 7.5),
			Position = basePos + Vector3.new(0, h * 0.5, 0),
			Color = Color3.fromRGB(42, 40, 48),
			Material = Enum.Material.Cobblestone,
			Parent = bModel,
		})

		-- Anello runico luminoso a terra intorno al braciere
		local runePad = makePart({
			Name = "RunePad",
			Size = Vector3.new(9.2, 0.2, 9.2),
			Position = basePos + Vector3.new(0, 0.12, 0),
			Color = Color3.fromRGB(45, 42, 52),
			Material = Enum.Material.Neon,
			Transparency = 0.45,
			CanCollide = false,
			Parent = bModel,
		})

		-- Coppa del Braciere
		local bowl = makePart({
			Name = "Bowl",
			Size = Vector3.new(3.8, 1.4, 3.8),
			Position = basePos + Vector3.new(0, h + 0.7, 0),
			Color = Color3.fromRGB(58, 42, 28),
			Material = Enum.Material.Metal,
			Parent = bModel,
		})

		-- Sfera Fiamma del Braciere Rituale
		local core = makePart({
			Name = "FlameOrb",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.6, 3.0, 2.6),
			Position = basePos + Vector3.new(0, h + 2.6, 0),
			Color = Color3.fromRGB(32, 32, 38),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = bModel,
		})

		local bLight = Instance.new("PointLight", core)
		bLight.Name = "BrazierLight"
		bLight.Color = Color3.fromRGB(255, 175, 55)
		bLight.Range = 26
		bLight.Brightness = 0
		bLight.Enabled = false

		-- Cartello identificativo sopra il braciere
		local bb = Instance.new("BillboardGui", core)
		bb.Name = "BrazierGui"
		bb.Size = UDim2.fromOffset(180, 48)
		bb.StudsOffset = Vector3.new(0, 3.2, 0)
		bb.MaxDistance = 75

		local bg = Instance.new("Frame", bb)
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(16, 15, 22)
		bg.BackgroundTransparency = 0.25
		Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
		local st = Instance.new("UIStroke", bg)
		st.Name = "Stroke"
		st.Color = Color3.fromRGB(255, 175, 60)
		st.Transparency = 0.4

		local title = Instance.new("TextLabel", bg)
		title.Name = "Title"
		title.Size = UDim2.new(1, -8, 0.52, 0)
		title.Position = UDim2.fromOffset(4, 2)
		title.BackgroundTransparency = 1
		title.Text = "🔥 BRACIERE " .. bCfg.Numeral
		title.TextColor3 = Color3.fromRGB(255, 210, 95)
		title.Font = Enum.Font.GothamBlack
		title.TextScaled = true

		local sub = Instance.new("TextLabel", bg)
		sub.Name = "Sub"
		sub.Size = UDim2.new(1, -8, 0.44, 0)
		sub.Position = UDim2.new(0, 4, 0.54, 0)
		sub.BackgroundTransparency = 1
		sub.Text = bCfg.Index == 1 and "Inizia Catena del Fuoco" or ("Tappa " .. bCfg.Index .. " / 5")
		sub.TextColor3 = Color3.fromRGB(215, 215, 225)
		sub.Font = Enum.Font.GothamBold
		sub.TextScaled = true

		-- ProximityPrompt (istantaneo sul Braciere I, utile anche per interazione manuale)
		local prompt = Instance.new("ProximityPrompt", bowl)
		prompt.Name = "RitualPrompt"
		prompt.ObjectText = "Regno 1 • Braciere " .. bCfg.Numeral
		prompt.ActionText = bCfg.Index == 1 and "Avvia Catena del Fuoco" or "Accendi Braciere"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
	end

	local crystalsFolder = Instance.new("Folder", zonesFolder)
	crystalsFolder.Name = "Crystals"
	for i = 1, 12 do
		local ang = (i / 12) * math.pi * 2
		local rad = 8 + (i % 3) * 7
		local pos = Vector3.new(78 + math.cos(ang) * rad, 1, math.sin(ang) * rad)
		local h = 11 + (i % 4) * 5
		local c = makePart({
			Name = "Crystal_" .. i,
			Size = Vector3.new(3.6, h, 3.6),
			CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(math.rad((i % 3 - 1) * 12), ang, math.rad((i % 2) * 10)),
			Color = Color3.fromRGB(20, 24, 32),
			Material = Enum.Material.SmoothPlastic,
			Parent = crystalsFolder,
		})
		if i % 3 == 0 then
			local l = Instance.new("PointLight", c); l.Color = Color3.fromRGB(60, 255, 210); l.Range = 38; l.Brightness = 0; l.Enabled = false
		end
	end

	local lanternsFolder = Instance.new("Folder", zonesFolder)
	lanternsFolder.Name = "Lanterns"
	makePart({ Name = "LanternGazebo", Size = Vector3.new(22, 1.5, 22), Position = Vector3.new(-64, 1.5, 58), Color = Color3.fromRGB(34, 28, 30), Material = Enum.Material.WoodPlanks, Parent = lanternsFolder })
	for i = 1, 10 do
		local ang = (i / 10) * math.pi * 2
		local pos = Vector3.new(-64 + math.cos(ang) * 9, 8 + (i % 4) * 4, 58 + math.sin(ang) * 9)
		local lan = makePart({ Name = "SkyLantern_" .. i, Size = Vector3.new(2.4, 3.2, 2.4), Position = pos, Color = Color3.fromRGB(30, 25, 25), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = lanternsFolder })
		if i % 2 == 0 then
			local l = Instance.new("PointLight", lan); l.Color = Color3.fromRGB(255, 140, 60); l.Range = 30; l.Brightness = 0; l.Enabled = false
		end
	end

	local waterfallFolder = Instance.new("Folder", zonesFolder)
	waterfallFolder.Name = "Waterfall"
	makePart({ Name = "CliffBack", Size = Vector3.new(12, 36, 30), Position = Vector3.new(-88, 18, 0), Color = Color3.fromRGB(28, 30, 36), Material = Enum.Material.Rock, Parent = waterfallFolder })
	local waterStream = makePart({ Name = "WaterStream", Size = Vector3.new(2, 32, 18), Position = Vector3.new(-81.5, 17, 0), Color = Color3.fromRGB(22, 26, 35), Material = Enum.Material.SmoothPlastic, Parent = waterfallFolder })
	local waterPool = makePart({ Name = "WaterPool", Size = Vector3.new(18, 0.8, 24), Position = Vector3.new(-73, 1.3, 0), Color = Color3.fromRGB(22, 26, 35), Material = Enum.Material.SmoothPlastic, Parent = waterfallFolder })
	local wfLight = Instance.new("PointLight", waterStream); wfLight.Color = Color3.fromRGB(110, 220, 255); wfLight.Range = 48; wfLight.Brightness = 0; wfLight.Enabled = false

	local templeFolder = Instance.new("Folder", zonesFolder)
	templeFolder.Name = "Temple"
	makePart({ Name = "TempleFloor", Size = Vector3.new(48, 2, 28), Position = Vector3.new(0, 1.5, -86), Color = Color3.fromRGB(34, 34, 40), Material = Enum.Material.Marble, Parent = templeFolder })
	for _, px in ipairs({ -18, -6, 6, 18 }) do
		makePart({ Name = "Pillar", Size = Vector3.new(3.8, 28, 3.8), Position = Vector3.new(px, 16, -86), Color = Color3.fromRGB(36, 36, 44), Material = Enum.Material.Marble, Parent = templeFolder })
	end
	local sunDisc = makePart({ Name = "SunDisc", Shape = Enum.PartType.Ball, Size = Vector3.new(13, 13, 13), Position = Vector3.new(0, 24, -90), Color = Color3.fromRGB(30, 30, 36), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = templeFolder })
	local sunLight = Instance.new("PointLight", sunDisc); sunLight.Color = Color3.fromRGB(255, 225, 110); sunLight.Range = 65; sunLight.Brightness = 0; sunLight.Enabled = false

	return {
		World = world,
		FlameCore = flameCore,
		BrazierBowl = brazierBowl,
		FlameHitbox = flameHitbox,
		AltarsFolder = altarsFolder,
		RitualFolder = ritualFolder,
	}
end

return WorldBuilder
