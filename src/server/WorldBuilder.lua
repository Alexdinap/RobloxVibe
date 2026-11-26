local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local WorldBuilder = {}

local catalogTemplateCache = {}

local function getCatalogMonumentTemplate(assetId)
	if not assetId or assetId <= 0 then
		return nil
	end
	if catalogTemplateCache[assetId] ~= nil then
		return catalogTemplateCache[assetId] or nil
	end

	local ok, container = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)

	if ok and container then
		local model = Instance.new("Model")
		model.Name = "CatalogMonument_" .. tostring(assetId)

		for _, desc in ipairs(container:GetDescendants()) do
			if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("ModuleScript") or desc:IsA("JointInstance") then
				desc:Destroy()
			end
		end

		for _, child in ipairs(container:GetChildren()) do
			child.Parent = model
		end
		container:Destroy()

		local partCount = 0
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Anchored = true
				desc.CanCollide = false
				partCount += 1
			end
		end

		if partCount > 0 then
			catalogTemplateCache[assetId] = model
			return model
		else
			model:Destroy()
		end
	end

	catalogTemplateCache[assetId] = false
	return nil
end

local function makePart(parent, name, size, cframe, color, material, transparency, canCollide, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.CanCollide = (canCollide ~= false)
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function makeUprightCylinder(parent, name, height, diameter, pos, color, material, transparency, canCollide)
	local cf = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	return makePart(parent, name, Vector3.new(height, diameter, diameter), cf, color, material, transparency, canCollide, Enum.PartType.Cylinder)
end

local function buildFallbackMonument(parent, zCfg, pedestalTopPos, dir)
	local parts = {}
	local lights = {}
	local accent = zCfg.Color or Color3.fromRGB(255, 205, 85)
	local marble = Color3.fromRGB(232, 234, 242)
	local gold = Color3.fromRGB(245, 195, 75)
	local baseCF = CFrame.lookAt(pedestalTopPos, pedestalTopPos + dir)
	local mType = zCfg.MonumentType or "Obelisk"

	local function addPart(name, size, relCF, col, mat, transp, shape)
		local p = makePart(parent, name, size, baseCF * relCF, col, mat, transp or 0, false, shape)
		table.insert(parts, p)
		return p
	end

	if mType == "Fountain" then
		local b1 = makeUprightCylinder(parent, "FountainBasin1", 1.4, 11.5, pedestalTopPos + Vector3.new(0, 0.7, 0), marble, Enum.Material.Marble, 0, false)
		local w1 = makeUprightCylinder(parent, "FountainWater1", 1.5, 9.8, pedestalTopPos + Vector3.new(0, 0.75, 0), accent, Enum.Material.Neon, 0.15, false)
		local col1 = makeUprightCylinder(parent, "FountainStem", 4.2, 2.2, pedestalTopPos + Vector3.new(0, 2.1, 0), marble, Enum.Material.Marble, 0, false)
		local b2 = makeUprightCylinder(parent, "FountainBasin2", 1.1, 6.4, pedestalTopPos + Vector3.new(0, 4.3, 0), marble, Enum.Material.Marble, 0, false)
		local w2 = makeUprightCylinder(parent, "FountainWater2", 1.2, 5.2, pedestalTopPos + Vector3.new(0, 4.35, 0), accent, Enum.Material.Neon, 0.12, false)
		local apex = addPart("FountainSpire", Vector3.new(1.5, 3.2, 1.5), CFrame.new(0, 6.2, 0), gold, Enum.Material.Neon, 0.05, Enum.PartType.Ball)
		table.insert(parts, b1); table.insert(parts, w1); table.insert(parts, col1)
		table.insert(parts, b2); table.insert(parts, w2)

		local pl = Instance.new("PointLight", apex)
		pl.Color = accent
		pl.Range = 26
		pl.Brightness = 2.4
		table.insert(lights, pl)

	elseif mType == "Temple" then
		local floor = makeUprightCylinder(parent, "TempleDais", 0.8, 12.0, pedestalTopPos + Vector3.new(0, 0.4, 0), marble, Enum.Material.Marble, 0, false)
		table.insert(parts, floor)

		for i = 0, 5 do
			local ang = math.rad(i * 60 + 30)
			local cPos = pedestalTopPos + Vector3.new(math.cos(ang) * 4.5, 4.4, math.sin(ang) * 4.5)
			local col = makeUprightCylinder(parent, "TempleCol_" .. i, 7.6, 1.1, cPos, marble, Enum.Material.Marble, 0, false)
			table.insert(parts, col)
		end

		local roofRing = makeUprightCylinder(parent, "TempleCornice", 1.1, 12.4, pedestalTopPos + Vector3.new(0, 8.6, 0), gold, Enum.Material.SmoothPlastic, 0, false)
		local dome = addPart("TempleDome", Vector3.new(9.2, 5.2, 9.2), CFrame.new(0, 9.6, 0), marble, Enum.Material.Marble, 0, Enum.PartType.Ball)
		local statueBody = addPart("GuardianStatue", Vector3.new(2.2, 5.0, 1.6), CFrame.new(0, 3.3, 0), gold, Enum.Material.Glass, 0.08)
		local statueOrb = addPart("GuardianHalo", Vector3.new(2.6, 2.6, 0.4), CFrame.new(0, 6.2, 0), accent, Enum.Material.Neon, 0.05, Enum.PartType.Cylinder)
		table.insert(parts, roofRing)

		local pl = Instance.new("PointLight", statueBody)
		pl.Color = accent
		pl.Range = 28
		pl.Brightness = 2.6
		table.insert(lights, pl)

	elseif mType == "Phoenix" then
		addPart("PhoenixPlinth", Vector3.new(4.2, 2.2, 4.2), CFrame.new(0, 1.1, 0), marble, Enum.Material.Marble, 0)
		addPart("PhoenixCore", Vector3.new(2.2, 5.8, 2.2), CFrame.new(0, 5.2, 0), gold, Enum.Material.Neon, 0.05)
		addPart("PhoenixWingL1", Vector3.new(6.8, 1.6, 0.7), CFrame.new(-3.8, 5.6, 0.4) * CFrame.Angles(0, math.rad(-18), math.rad(28)), accent, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingL2", Vector3.new(5.4, 1.2, 0.6), CFrame.new(-4.8, 7.2, 0.6) * CFrame.Angles(0, math.rad(-22), math.rad(42)), gold, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingR1", Vector3.new(6.8, 1.6, 0.7), CFrame.new(3.8, 5.6, 0.4) * CFrame.Angles(0, math.rad(18), math.rad(-28)), accent, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingR2", Vector3.new(5.4, 1.2, 0.6), CFrame.new(4.8, 7.2, 0.6) * CFrame.Angles(0, math.rad(22), math.rad(-42)), gold, Enum.Material.Neon, 0.08)
		local crown = addPart("PhoenixCrown", Vector3.new(2.8, 2.8, 2.8), CFrame.new(0, 9.4, 0), Color3.fromRGB(255, 250, 210), Enum.Material.Neon, 0.02, Enum.PartType.Ball)

		local pl = Instance.new("PointLight", crown)
		pl.Color = accent
		pl.Range = 32
		pl.Brightness = 3.0
		table.insert(lights, pl)

	else
		addPart("ObeliskBase", Vector3.new(4.8, 1.8, 4.8), CFrame.new(0, 0.9, 0), marble, Enum.Material.Marble, 0)
		addPart("ObeliskShaftLower", Vector3.new(3.2, 5.5, 3.2), CFrame.new(0, 4.5, 0), marble, Enum.Material.Marble, 0)
		addPart("ObeliskGoldBand", Vector3.new(3.5, 0.7, 3.5), CFrame.new(0, 7.5, 0), gold, Enum.Material.Neon, 0.05)
		addPart("ObeliskShaftUpper", Vector3.new(2.2, 4.2, 2.2), CFrame.new(0, 9.8, 0), marble, Enum.Material.Marble, 0)
		local apex = addPart("ObeliskApex", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, 12.8, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), accent, Enum.Material.Neon, 0.04)

		local pl = Instance.new("PointLight", apex)
		pl.Color = accent
		pl.Range = 28
		pl.Brightness = 2.6
		table.insert(lights, pl)
	end

	return parts, lights
end

local function placeMonumentOnIsland(islandFolder, zCfg, pedestalTopPos, dir)
	local parts = {}
	local lights = {}
	local accent = zCfg.Color or Color3.fromRGB(255, 205, 85)

	local template = getCatalogMonumentTemplate(zCfg.CatalogAssetId)
	if template then
		local clone = template:Clone()
		clone.Name = "Monument_" .. zCfg.Id
		clone.Parent = islandFolder

		local cf, size = clone:GetBoundingBox()
		local maxDim = math.max(size.X, size.Y, size.Z, 0.1)
		local targetSize = 11.5
		local scale = math.clamp(targetSize / maxDim, 0.15, 6.0)

		local bottomCenter = cf.Position - Vector3.new(0, size.Y * 0.5, 0)
		local targetRot = CFrame.lookAt(Vector3.zero, Vector3.new(dir.X, 0, dir.Z))

		for _, desc in ipairs(clone:GetDescendants()) do
			if desc:IsA("BasePart") then
				local rel = desc.CFrame.Position - bottomCenter
				local rotOnly = desc.CFrame - desc.CFrame.Position
				desc.Size = desc.Size * scale
				desc.CFrame = CFrame.new(pedestalTopPos) * targetRot * CFrame.new(rel * scale) * rotOnly
				desc.Anchored = true
				desc.CanCollide = false
				table.insert(parts, desc)
			elseif desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("ParticleEmitter") then
				table.insert(lights, desc)
			end
		end

		local glowAnchor = makePart(
			clone,
			"MonumentAuraCore",
			Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(pedestalTopPos + Vector3.new(0, 5.5, 0)),
			accent,
			Enum.Material.Neon,
			1,
			false
		)
		local pl = Instance.new("PointLight", glowAnchor)
		pl.Color = accent
		pl.Range = 28
		pl.Brightness = 2.5
		table.insert(lights, pl)

		return parts, lights
	end

	return buildFallbackMonument(islandFolder, zCfg, pedestalTopPos, dir)
end

local function createPadBillboard(pad, titleText, descText, costText, accentColor)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "PadGui"
	bbg.Size = UDim2.fromOffset(156, 44)
	bbg.StudsOffset = Vector3.new(0, 2.75, 0)
	bbg.MaxDistance = 38
	bbg.AlwaysOnTop = false
	bbg.Parent = pad

	local bg = Instance.new("Frame", bbg)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(13, 15, 24)
	bg.BackgroundTransparency = 0.24
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = accentColor or Color3.fromRGB(255, 200, 75)
	stroke.Thickness = 1.1

	local titleLbl = Instance.new("TextLabel", bg)
	titleLbl.Name = "TitleLabel"
	titleLbl.Position = UDim2.fromOffset(6, 2)
	titleLbl.Size = UDim2.new(1, -12, 0, 14)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText
	titleLbl.TextColor3 = Color3.fromRGB(255, 248, 225)
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 10
	titleLbl.TextScaled = false
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local descLbl = Instance.new("TextLabel", bg)
	descLbl.Name = "DescLabel"
	descLbl.Position = UDim2.fromOffset(6, 16)
	descLbl.Size = UDim2.new(1, -12, 0, 12)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = descText or ""
	descLbl.TextColor3 = Color3.fromRGB(170, 188, 216)
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextSize = 8
	descLbl.TextWrapped = false
	descLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local costLbl = Instance.new("TextLabel", bg)
	costLbl.Name = "CostLabel"
	costLbl.Position = UDim2.fromOffset(6, 28)
	costLbl.Size = UDim2.new(1, -12, 0, 14)
	costLbl.BackgroundTransparency = 1
	costLbl.Text = costText
	costLbl.TextColor3 = accentColor or Color3.fromRGB(255, 215, 80)
	costLbl.Font = Enum.Font.GothamBold
	costLbl.TextSize = 10
	costLbl.TextTruncate = Enum.TextTruncate.AtEnd

	return titleLbl, descLbl, costLbl
end

local function buildRitualBrazier(plotModel, plotIndex, origin, outwardDir)
	local brazierModel = Instance.new("Model")
	brazierModel.Name = "Brazier"
	brazierModel.Parent = plotModel

	local accentGold = Color3.fromRGB(235, 185, 70)
	local stoneDark = Color3.fromRGB(30, 34, 48)
	local stoneMid = Color3.fromRGB(44, 50, 68)
	local ironDark = Color3.fromRGB(36, 40, 52)
	local baseFlameCol = Color3.fromRGB(255, 145, 45)
	local baseCF = CFrame.lookAt(origin, origin + outwardDir)

	-- 1. Gradini ottagonali / circolari dell'altare senza sovrapposizioni coplanari
	makeUprightCylinder(brazierModel, "BrazierBaseLower", 0.8, 16.0, origin + Vector3.new(0, 0.4, 0), stoneDark, Enum.Material.Basalt, 0, true)
	makeUprightCylinder(brazierModel, "BrazierBaseTrim", 0.36, 16.4, origin + Vector3.new(0, 0.18, 0), accentGold, Enum.Material.SmoothPlastic, 0, false)
	makeUprightCylinder(brazierModel, "BrazierPedestal", 1.1, 12.8, origin + Vector3.new(0, 1.35, 0), stoneMid, Enum.Material.Slate, 0, true)
	makeUprightCylinder(brazierModel, "BrazierMidTrim", 0.24, 13.1, origin + Vector3.new(0, 1.92, 0), accentGold, Enum.Material.SmoothPlastic, 0, false)

	-- 2. 4 Pilastri runici cardinali con cristalli luminosi sincronizzati al colore della fiamma
	local runeCrystals = {}
	for i = 0, 3 do
		local ang = math.rad(i * 90 + 45)
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local pPos = origin + dir * 6.5
		makePart(
			brazierModel,
			"BrazierRunePillar_" .. (i + 1),
			Vector3.new(1.3, 3.1, 1.3),
			CFrame.lookAt(pPos + Vector3.new(0, 1.95, 0), pPos + dir + Vector3.new(0, 1.95, 0)),
			stoneDark,
			Enum.Material.Basalt,
			0,
			true
		)
		local crystal = makePart(
			brazierModel,
			"BrazierRuneCrystal_" .. (i + 1),
			Vector3.new(0.85, 0.85, 0.85),
			CFrame.new(pPos + Vector3.new(0, 3.95, 0)) * CFrame.Angles(math.rad(45), math.rad(45), 0),
			baseFlameCol,
			Enum.Material.Neon,
			0.1,
			false
		)
		table.insert(runeCrystals, crystal)
	end

	-- 3. Coppa / Calderone forgiato in ferro e oro con punte a corona
	makeUprightCylinder(brazierModel, "BrazierStem", 1.1, 5.6, origin + Vector3.new(0, 2.45, 0), ironDark, Enum.Material.Metal, 0, true)
	local bowl = makeUprightCylinder(brazierModel, "BrazierBowl", 1.7, 10.8, origin + Vector3.new(0, 3.55, 0), ironDark, Enum.Material.DiamondPlate, 0, true)
	makeUprightCylinder(brazierModel, "BrazierGoldCollar", 0.34, 11.2, origin + Vector3.new(0, 3.85, 0), accentGold, Enum.Material.SmoothPlastic, 0, false)

	for i = 0, 7 do
		local ang = math.rad(i * 45)
		local prongCF = baseCF
			* CFrame.Angles(0, ang, 0)
			* CFrame.new(0, 4.15, -5.35)
			* CFrame.Angles(math.rad(-26), 0, 0)
		makePart(
			brazierModel,
			"BrazierCrownProng_" .. (i + 1),
			Vector3.new(0.65, 2.35, 0.55),
			prongCF,
			(i % 2 == 0) and ironDark or accentGold,
			Enum.Material.Metal,
			0,
			false
		)
	end

	-- 4. Letto di braci vulcaniche e anello incandescente
	makeUprightCylinder(brazierModel, "BrazierCoalBed", 0.45, 9.4, origin + Vector3.new(0, 4.35, 0), Color3.fromRGB(22, 18, 22), Enum.Material.Basalt, 0, false)
	local emberRing = makeUprightCylinder(brazierModel, "EmberRing", 0.32, 9.9, origin + Vector3.new(0, 4.5, 0), baseFlameCol, Enum.Material.Neon, 0.08, false)

	for i = 0, 5 do
		local ang = math.rad(i * 60 + 15)
		local r = 2.6 + (i % 2) * 1.1
		local coalPos = origin + Vector3.new(math.cos(ang) * r, 4.62, math.sin(ang) * r)
		local coal = makePart(
			brazierModel,
			"EmberChunk_" .. (i + 1),
			Vector3.new(1.1, 0.65, 0.95),
			CFrame.new(coalPos) * CFrame.Angles(math.rad(18), ang, math.rad(12)),
			baseFlameCol,
			Enum.Material.Neon,
			0.15,
			false
		)
		table.insert(runeCrystals, coal)
	end

	-- 5. Fiamma multistrato + Particelle fuoco e scintille
	local baseFlameSize = Vector3.new(4.8, 6.2, 4.8)
	local baseFlamePos = origin + Vector3.new(0, 6.8, 0)
	local flameCore = makePart(
		brazierModel,
		"FlameCore",
		baseFlameSize,
		CFrame.new(baseFlamePos),
		baseFlameCol,
		Enum.Material.Neon,
		0.26,
		false,
		Enum.PartType.Ball
	)

	local innerCore = makePart(
		flameCore,
		"InnerFlameCore",
		Vector3.new(2.7, 3.8, 2.7),
		CFrame.new(baseFlamePos + Vector3.new(0, -0.35, 0)),
		Color3.fromRGB(255, 245, 195),
		Enum.Material.Neon,
		0.04,
		false,
		Enum.PartType.Ball
	)

	local flameTongues = {}
	for i = 1, 3 do
		local ang = math.rad((i - 1) * 120)
		local tongueCF = CFrame.new(baseFlamePos + Vector3.new(math.cos(ang) * 1.15, 0.65, math.sin(ang) * 1.15))
			* CFrame.Angles(0, ang, math.rad(14))
		local tongue = makePart(
			flameCore,
			"FlameTongue_" .. i,
			Vector3.new(2.1, 4.4, 2.1),
			tongueCF,
			baseFlameCol,
			Enum.Material.Neon,
			0.22,
			false,
			Enum.PartType.Ball
		)
		table.insert(flameTongues, {
			Part = tongue,
			Angle = ang,
			BaseSize = Vector3.new(2.1, 4.4, 2.1),
		})
	end

	local fireEmitter = Instance.new("ParticleEmitter")
	fireEmitter.Name = "FirePlumeEmitter"
	fireEmitter.Texture = "rbxasset://textures/particles/fire_main.dds"
	fireEmitter.LightEmission = 1
	fireEmitter.LightInfluence = 0
	fireEmitter.Rate = 32
	fireEmitter.Lifetime = NumberRange.new(0.75, 1.3)
	fireEmitter.Speed = NumberRange.new(3.2, 6.2)
	fireEmitter.SpreadAngle = Vector2.new(16, 16)
	fireEmitter.RotSpeed = NumberRange.new(-40, 40)
	fireEmitter.Rotation = NumberRange.new(0, 360)
	fireEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 245, 190)),
		ColorSequenceKeypoint.new(0.45, baseFlameCol),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 25)),
	})
	fireEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2.2),
		NumberSequenceKeypoint.new(0.5, 1.6),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	fireEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	fireEmitter.Parent = flameCore

	local sparkEmitter = Instance.new("ParticleEmitter")
	sparkEmitter.Name = "EmberSparksEmitter"
	sparkEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkEmitter.LightEmission = 1
	sparkEmitter.LightInfluence = 0
	sparkEmitter.Rate = 20
	sparkEmitter.Lifetime = NumberRange.new(1.1, 2.2)
	sparkEmitter.Speed = NumberRange.new(4.0, 8.5)
	sparkEmitter.SpreadAngle = Vector2.new(30, 30)
	sparkEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 235, 150), baseFlameCol)
	sparkEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.42),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkEmitter.Parent = flameCore

	local flameLight = Instance.new("PointLight", flameCore)
	flameLight.Color = Color3.fromRGB(255, 155, 55)
	flameLight.Range = 55
	flameLight.Brightness = 3.8

	local flameHitbox = makePart(
		brazierModel,
		"FlameHitbox",
		Vector3.new(12, 12, 12),
		CFrame.new(origin + Vector3.new(0, 6.2, 0)),
		Color3.fromRGB(255, 200, 80),
		Enum.Material.SmoothPlastic,
		1,
		false
	)

	local titleBbg = Instance.new("BillboardGui", flameCore)
	titleBbg.Name = "BrazierTitleGui"
	titleBbg.Size = UDim2.fromOffset(200, 28)
	titleBbg.StudsOffset = Vector3.new(0, 6.0, 0)
	titleBbg.MaxDistance = 80

	local flameTitle = Instance.new("TextLabel", titleBbg)
	flameTitle.Size = UDim2.fromScale(1, 1)
	flameTitle.BackgroundTransparency = 1
	flameTitle.Text = Localization.T("en", "BRAZIER_DEFAULT_FMT", plotIndex)
	flameTitle.TextColor3 = Color3.fromRGB(255, 225, 110)
	flameTitle.TextStrokeTransparency = 0.2
	flameTitle.Font = Enum.Font.GothamBlack
	flameTitle.TextSize = 14

	return {
		Bowl = bowl,
		FlameCore = flameCore,
		InnerFlameCore = innerCore,
		FlameTongues = flameTongues,
		FireEmitter = fireEmitter,
		SparkEmitter = sparkEmitter,
		RuneCrystals = runeCrystals,
		BaseFlameSize = baseFlameSize,
		BaseFlamePos = baseFlamePos,
		FlameHitbox = flameHitbox,
		FlameTitle = flameTitle,
		EmberRing = emberRing,
	}
end

function WorldBuilder.Build()
	local existing = Workspace:FindFirstChild("LastFlameWorld")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "LastFlameWorld"
	world.Parent = Workspace

	local plotCount = GameConfig.PlotCount or 10
	local ringRadius = GameConfig.PlotRingRadius or 245
	local halfSize = GameConfig.PlotHalfSize or 42

	-- === PIAZZA CENTRALE (ZERO SOVRAPPOSIZIONI E ZERO Z-FIGHTING) ===
	local hubFolder = Instance.new("Folder")
	hubFolder.Name = "CentralHub"
	hubFolder.Parent = world

	local hubRadius = 52.0
	local hubDiameter = hubRadius * 2 -- 104 studs, superficie superiore esattamente a Y = 0.00
	makeUprightCylinder(hubFolder, "CentralHubFloor", 2.4, hubDiameter, Vector3.new(0, -1.2, 0), Color3.fromRGB(26, 30, 44), Enum.Material.Slate, 0, true)
	-- Bordo esterno ribassato sotto Y = 0 così non compenetra mai né col pavimento né coi ponti
	makeUprightCylinder(hubFolder, "CentralHubTrim", 2.0, hubDiameter + 2.4, Vector3.new(0, -1.22, 0), Color3.fromRGB(255, 195, 70), Enum.Material.Neon, 0.22, false)

	-- Anelli decorativi a gradini netti (altezze Y distinte, zero facce coplanari)
	makeUprightCylinder(hubFolder, "HubOuterSlateRing", 0.08, 78, Vector3.new(0, 0.04, 0), Color3.fromRGB(34, 40, 58), Enum.Material.Marble, 0, false)
	makeUprightCylinder(hubFolder, "HubGoldInlayRing", 0.04, 58, Vector3.new(0, 0.10, 0), Color3.fromRGB(245, 188, 68), Enum.Material.Neon, 0.25, false)
	makeUprightCylinder(hubFolder, "HubInnerMarbleDisc", 0.06, 54, Vector3.new(0, 0.15, 0), Color3.fromRGB(24, 34, 52), Enum.Material.Marble, 0, false)
	makeUprightCylinder(hubFolder, "HubCenterSunDisc", 0.06, 20, Vector3.new(0, 0.21, 0), Color3.fromRGB(52, 42, 34), Enum.Material.SmoothPlastic, 0, false)

	-- Punto luce centrale sospeso (non blocca il passaggio al centro della piazza)
	local hubLightAnchor = makePart(hubFolder, "HubLightAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 15, 0), Color3.fromRGB(255, 200, 80), Enum.Material.SmoothPlastic, 1, false)
	hubLightAnchor.CanQuery = false
	hubLightAnchor.CanTouch = false
	local hubLight = Instance.new("PointLight", hubLightAnchor)
	hubLight.Color = Color3.fromRGB(255, 200, 80)
	hubLight.Range = 65
	hubLight.Brightness = 2.8

	local plots = {}
	local walkwayWidth = 8.4

	for i = 1, plotCount do
		local theta = ((i - 1) / plotCount) * math.pi * 2
		local outwardDir = Vector3.new(math.cos(theta), 0, math.sin(theta)).Unit
		local rightDir = outwardDir:Cross(Vector3.yAxis).Unit
		local inwardDir = -outwardDir
		local origin = outwardDir * ringRadius

		local plotModel = Instance.new("Model")
		plotModel.Name = "Plot_" .. tostring(i)
		plotModel.Parent = world

		local plotLook = CFrame.lookAt(origin, origin + outwardDir)

		-- Pavimento Plot con superficie superiore esattamente a Y = 0.00
		makePart(plotModel, "PlotFloor", Vector3.new(halfSize * 2, 2.4, halfSize * 2), plotLook * CFrame.new(0, -1.2, 0), Color3.fromRGB(24, 28, 42), Enum.Material.Slate, 0, true)

		-- Cornice perimetrale esterna senza sovrapposizioni col pavimento e con varco pulito per la passerella
		local borderThick = 1.1
		local borderHeight = 1.8
		local borderY = -1.02 -- top a Y = -0.12, zero Z-fighting con Y = 0.00
		local sideSpan = halfSize * 2 + borderThick * 2
		local sideOffset = halfSize + borderThick * 0.5
		local frontSegmentLen = (halfSize * 2 - walkwayWidth) * 0.5

		-- Lato posteriore (esterno)
		makePart(plotModel, "PlotBorderBack", Vector3.new(sideSpan, borderHeight, borderThick), plotLook * CFrame.new(0, borderY, -sideOffset), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.35, false)
		-- Lati destro e sinistro
		makePart(plotModel, "PlotBorderRight", Vector3.new(borderThick, borderHeight, halfSize * 2), plotLook * CFrame.new(sideOffset, borderY, 0), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.35, false)
		makePart(plotModel, "PlotBorderLeft", Vector3.new(borderThick, borderHeight, halfSize * 2), plotLook * CFrame.new(-sideOffset, borderY, 0), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.35, false)
		-- Lato anteriore diviso in 2 ali ai lati della passerella (nessuna compenetrazione!)
		if frontSegmentLen > 1 then
			local wingX = walkwayWidth * 0.5 + frontSegmentLen * 0.5
			makePart(plotModel, "PlotBorderFrontL", Vector3.new(frontSegmentLen, borderHeight, borderThick), plotLook * CFrame.new(-wingX, borderY, sideOffset), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.35, false)
			makePart(plotModel, "PlotBorderFrontR", Vector3.new(frontSegmentLen, borderHeight, borderThick), plotLook * CFrame.new(wingX, borderY, sideOffset), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.35, false)
		end

		-- === PASSERELLA DI COLLEGAMENTO A FILO (DA R = 52.00 A R = ringRadius - halfSize) ===
		local bridgeStart = hubRadius
		local bridgeEnd = ringRadius - halfSize
		local hubBridgeLen = bridgeEnd - bridgeStart
		if hubBridgeLen > 4 then
			local bridgeMid = outwardDir * (bridgeStart + hubBridgeLen * 0.5)
			local bridgeCF = CFrame.lookAt(bridgeMid, bridgeMid + outwardDir)

			-- Piano principale a livello Y = 0.00 esatto, senza alcuna compenetrazione
			makePart(plotModel, "HubBridge", Vector3.new(walkwayWidth, 1.8, hubBridgeLen), bridgeCF * CFrame.new(0, -0.9, 0), Color3.fromRGB(30, 35, 52), Enum.Material.Slate, 0, true)
			-- Cordoli laterali rialzati
			local curbOffset = walkwayWidth * 0.5 + 0.25
			makePart(plotModel, "HubBridgeCurbL", Vector3.new(0.5, 0.36, hubBridgeLen), bridgeCF * CFrame.new(-curbOffset, 0.06, 0), Color3.fromRGB(48, 56, 80), Enum.Material.SmoothPlastic, 0, true)
			makePart(plotModel, "HubBridgeCurbR", Vector3.new(0.5, 0.36, hubBridgeLen), bridgeCF * CFrame.new(curbOffset, 0.06, 0), Color3.fromRGB(48, 56, 80), Enum.Material.SmoothPlastic, 0, true)
			-- Striscia luminosa centrale leggermente sopra Y = 0.00 (Y = 0.02, zero Z-fighting)
			makePart(plotModel, "HubBridgeGuideline", Vector3.new(0.36, 0.04, hubBridgeLen - 2.0), bridgeCF * CFrame.new(0, 0.02, 0), Color3.fromRGB(255, 195, 75), Enum.Material.Neon, 0.35, false)
		end

		-- Cartello identificativo Plot
		local signPos = origin + inwardDir * (halfSize - 3) + Vector3.new(0, 5.5, 0)
		local signBoard = makePart(plotModel, "SignBoard", Vector3.new(12, 5.2, 0.8), CFrame.lookAt(signPos, signPos + inwardDir), Color3.fromRGB(18, 22, 34), Enum.Material.SmoothPlastic, 0, true)

		for _, faceInfo in ipairs({ { "SignGui", Enum.NormalId.Front }, { "SignGuiFront", Enum.NormalId.Back } }) do
			local sg = Instance.new("SurfaceGui", signBoard)
			sg.Name = faceInfo[1]
			sg.Face = faceInfo[2]
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 35

			local ot = Instance.new("TextLabel", sg)
			ot.Name = "OwnerTitle"
			ot.Position = UDim2.fromScale(0.05, 0.12)
			ot.Size = UDim2.fromScale(0.9, 0.42)
			ot.BackgroundTransparency = 1
			ot.Text = Localization.T("en", "PLOT_FREE_FMT", i)
			ot.TextColor3 = Color3.fromRGB(255, 215, 85)
			ot.Font = Enum.Font.GothamBlack
			ot.TextScaled = true

			local os = Instance.new("TextLabel", sg)
			os.Name = "OwnerSub"
			os.Position = UDim2.fromScale(0.05, 0.56)
			os.Size = UDim2.fromScale(0.9, 0.32)
			os.BackgroundTransparency = 1
			os.Text = Localization.T("en", "PLOT_WAIT")
			os.TextColor3 = Color3.fromRGB(185, 200, 225)
			os.Font = Enum.Font.GothamBold
			os.TextScaled = true
		end

		-- === MODELLO BRACIERE MONUMENTALE ===
		local brazierRefs = buildRitualBrazier(plotModel, i, origin, outwardDir)

		-- === PEDANE POTENZIAMENTO A TERRA (CON ETICHETTE COMPATTE E PULITE) ===
		local altarsFolder = Instance.new("Folder")
		altarsFolder.Name = "Altars"
		altarsFolder.Parent = plotModel

		local coreAltars = {}
		local colorAltars = {}
		for _, alt in ipairs(GameConfig.Altars) do
			if alt.IsColorButton then
				table.insert(colorAltars, alt)
			else
				table.insert(coreAltars, alt)
			end
		end

		local arcAngles = { -68, -34, 0, 34, 68 }
		for idx, alt in ipairs(coreAltars) do
			local deg = arcAngles[idx] or ((idx - 3) * 34)
			local dirPad = (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(deg)) * inwardDir).Unit
			local padPos = origin + dirPad * 16.5 + Vector3.new(0, 0.3, 0)
			local pad = makePart(
				altarsFolder,
				alt.Id,
				Vector3.new(5.4, 0.6, 5.4),
				CFrame.lookAt(padPos, padPos + inwardDir),
				alt.Color or Color3.fromRGB(255, 175, 55),
				Enum.Material.Neon,
				0.18,
				false
			)
			createPadBillboard(
				pad,
				string.format("%s [0/%d]", alt.Name, alt.MaxLevel or 1),
				alt.BenefitTag or alt.Desc or "",
				tostring(alt.BaseCost) .. " Light",
				alt.Color
			)
		end

		local colorOffsets = {
			rightDir * -23 + inwardDir * 7,
			rightDir * -23 + outwardDir * 7,
			rightDir * 23 + inwardDir * 7,
			rightDir * 23 + outwardDir * 7,
		}
		for idx, alt in ipairs(colorAltars) do
			local off = colorOffsets[idx] or (rightDir * (20 + idx * 4))
			local padPos = origin + off + Vector3.new(0, 0.3, 0)
			local pad = makePart(
				altarsFolder,
				alt.Id,
				Vector3.new(5.2, 0.6, 5.2),
				CFrame.lookAt(padPos, padPos + inwardDir),
				alt.Color or Color3.fromRGB(255, 200, 80),
				Enum.Material.Neon,
				0.18,
				false
			)
			createPadBillboard(
				pad,
				"🎨 " .. alt.Name,
				alt.BenefitTag or alt.Desc or "",
				tostring(alt.BaseCost) .. " Light",
				alt.Color
			)
		end

		local victoryPos = origin + outwardDir * 21.5 + Vector3.new(0, 0.35, 0)
		local victoryPad = makePart(
			plotModel,
			"VictoryPad",
			Vector3.new(8.2, 0.7, 6.0),
			CFrame.lookAt(victoryPos, victoryPos + inwardDir),
			Color3.fromRGB(255, 215, 75),
			Enum.Material.Neon,
			0.14,
			false
		)
		local vTitleLbl, vDescLbl, vStatusLbl = createPadBillboard(
			victoryPad,
			"🌅 " .. GameConfig.VictoryButton.Name,
			"+1 Dawn Pt (Prestige)",
			"25B Light",
			Color3.fromRGB(255, 220, 90)
		)

		-- === 4 ISOLE DELL'ALBA ===
		local albaZonesFolder = Instance.new("Folder")
		albaZonesFolder.Name = "AlbaZones"
		albaZonesFolder.Parent = plotModel

		local albaZoneRefs = {}
		for _, z in ipairs(GameConfig.AlbaZones) do
			local zFolder = Instance.new("Folder")
			zFolder.Name = z.Id
			zFolder.Parent = albaZonesFolder

			local fanRad = math.rad(z.FanAngle or 0)
			local zDir = (CFrame.fromAxisAngle(Vector3.yAxis, fanRad) * outwardDir).Unit
			local zDist = z.Distance or 90
			local islandCenter = origin + zDir * zDist

			local edgeDist = halfSize / math.max(math.abs(math.cos(fanRad)), math.abs(math.sin(fanRad)))
			local bridgeStartDist = edgeDist + 0.1
			local bridgeEndDist = zDist - 13.8
			local bridgeLen = math.max(10, bridgeEndDist - bridgeStartDist)
			local bridgeMid = origin + zDir * (bridgeStartDist + bridgeLen * 0.5)
			local bridgeCF = CFrame.lookAt(bridgeMid, bridgeMid + zDir)

			local bridge = makePart(zFolder, "Bridge", Vector3.new(5.6, 1.0, bridgeLen), bridgeCF * CFrame.new(0, -0.5, 0), Color3.fromRGB(36, 42, 60), Enum.Material.Marble, 0.65, false)
			local bridgeTrim = makePart(zFolder, "BridgeTrim", Vector3.new(6.2, 0.6, bridgeLen), bridgeCF * CFrame.new(0, -0.75, 0), z.Color, Enum.Material.Neon, 0.80, false)

			local gatePos = origin + zDir * (edgeDist - 1.8)
			local gateCF = CFrame.lookAt(gatePos, gatePos + zDir)
			local gatePad = makePart(zFolder, "GatePad", Vector3.new(5.8, 0.45, 4.2), gateCF * CFrame.new(0, 0.25, 0), z.Color, Enum.Material.Neon, 0.20, false)
			local gateBarrier = makePart(zFolder, "GateBarrier", Vector3.new(6.4, 7.2, 0.9), gateCF * CFrame.new(0, 3.6, 0), z.Color, Enum.Material.ForceField, 0.35, true)

			local gateBbg = Instance.new("BillboardGui", gateBarrier)
			gateBbg.Size = UDim2.fromOffset(186, 32)
			gateBbg.StudsOffset = Vector3.new(0, 4.0, 0)
			gateBbg.MaxDistance = 60

			local gateLabel = Instance.new("TextLabel", gateBbg)
			gateLabel.Size = UDim2.fromScale(1, 1)
			gateLabel.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
			gateLabel.BackgroundTransparency = 0.2
			gateLabel.Text = Localization.T("en", "ZONE_GATE_LOCKED_FMT", z.Name, z.Cost)
			gateLabel.TextColor3 = z.Color
			gateLabel.Font = Enum.Font.GothamBlack
			gateLabel.TextSize = 11
			Instance.new("UICorner", gateLabel).CornerRadius = UDim.new(0, 8)

			local islandBase = makeUprightCylinder(zFolder, "IslandBase", 2.4, 28, islandCenter + Vector3.new(0, -1.2, 0), Color3.fromRGB(32, 36, 52), Enum.Material.Slate, 0.55, false)
			local islandRim = makeUprightCylinder(zFolder, "IslandRim", 2.0, 29.4, islandCenter + Vector3.new(0, -1.45, 0), z.Color, Enum.Material.Neon, 0.70, false)
			local islandInner = makeUprightCylinder(zFolder, "IslandInner", 0.6, 21.5, islandCenter + Vector3.new(0, 0.3, 0), Color3.fromRGB(220, 224, 236), Enum.Material.Marble, 0.55, false)

			local pillars = {}
			for _, pDeg in ipairs({ -125, -45, 45, 125 }) do
				local pDir = (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(pDeg)) * zDir).Unit
				local pPos = islandCenter + pDir * 11.8 + Vector3.new(0, 4.2, 0)
				local pil = makeUprightCylinder(zFolder, "IslandPillar", 7.8, 1.4, pPos, Color3.fromRGB(225, 228, 240), Enum.Material.Marble, 0.55, false)
				table.insert(pillars, pil)
			end

			local pedestal = makeUprightCylinder(zFolder, "MonumentPedestal", 1.8, 8.2, islandCenter + Vector3.new(0, 1.5, 0), Color3.fromRGB(46, 52, 72), Enum.Material.Marble, 0.55, false)
			local pedestalTopPos = islandCenter + Vector3.new(0, 2.4, 0)
			local monumentParts, monumentLights = placeMonumentOnIsland(zFolder, z, pedestalTopPos, zDir)

			local zTitleAnchor = makePart(zFolder, "ZoneTitleAnchor", Vector3.new(1, 1, 1), CFrame.new(islandCenter + Vector3.new(0, 15.5, 0)), z.Color, Enum.Material.SmoothPlastic, 1, false)
			local zBbg = Instance.new("BillboardGui", zTitleAnchor)
			zBbg.Size = UDim2.fromOffset(220, 32)
			zBbg.MaxDistance = 110

			local zoneTitle = Instance.new("TextLabel", zBbg)
			zoneTitle.Size = UDim2.fromScale(1, 1)
			zoneTitle.BackgroundTransparency = 1
			zoneTitle.Text = string.format("🔒 %s (x%.2f)", z.Name, z.LightMult or 1.0)
			zoneTitle.TextColor3 = z.Color
			zoneTitle.TextStrokeTransparency = 0.2
			zoneTitle.Font = Enum.Font.GothamBlack
			zoneTitle.TextSize = 13

			albaZoneRefs[z.Id] = {
				Bridge = bridge,
				BridgeTrim = bridgeTrim,
				GateBarrier = gateBarrier,
				GatePad = gatePad,
				GateLabel = gateLabel,
				IslandBase = islandBase,
				IslandRim = islandRim,
				IslandInner = islandInner,
				Pillars = pillars,
				MonumentPedestal = pedestal,
				MonumentParts = monumentParts,
				MonumentLights = monumentLights,
				ZoneTitle = zoneTitle,
			}
		end

		local defensesFolder = Instance.new("Folder")
		defensesFolder.Name = "Defenses"
		defensesFolder.Parent = plotModel

		local spawnPos = origin + inwardDir * 29 + Vector3.new(0, 4.2, 0)

		table.insert(plots, {
			Index = i,
			Origin = origin,
			OutwardDir = outwardDir,
			RightDir = rightDir,
			SpawnPos = spawnPos,
			Owner = nil,
			SignBoard = signBoard,
			FlameCore = brazierRefs.FlameCore,
			InnerFlameCore = brazierRefs.InnerFlameCore,
			FlameTongues = brazierRefs.FlameTongues,
			FireEmitter = brazierRefs.FireEmitter,
			SparkEmitter = brazierRefs.SparkEmitter,
			RuneCrystals = brazierRefs.RuneCrystals,
			BaseFlameSize = brazierRefs.BaseFlameSize,
			BaseFlamePos = brazierRefs.BaseFlamePos,
			FlameHitbox = brazierRefs.FlameHitbox,
			FlameTitle = brazierRefs.FlameTitle,
			EmberRing = brazierRefs.EmberRing,
			AltarsFolder = altarsFolder,
			VictoryPad = victoryPad,
			VictoryTitleLabel = vTitleLbl,
			VictoryDescLabel = vDescLbl,
			VictoryStatusLabel = vStatusLbl,
			AlbaZoneRefs = albaZoneRefs,
			DefensesFolder = defensesFolder,
		})
	end

	return {
		World = world,
		Plots = plots,
	}
end

return WorldBuilder
