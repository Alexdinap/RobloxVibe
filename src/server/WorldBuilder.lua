local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
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



	elseif mType == "Phoenix" then
		addPart("PhoenixPlinth", Vector3.new(4.2, 2.2, 4.2), CFrame.new(0, 1.1, 0), marble, Enum.Material.Marble, 0)
		addPart("PhoenixCore", Vector3.new(2.2, 5.8, 2.2), CFrame.new(0, 5.2, 0), gold, Enum.Material.Neon, 0.05)
		addPart("PhoenixWingL1", Vector3.new(6.8, 1.6, 0.7), CFrame.new(-3.8, 5.6, 0.4) * CFrame.Angles(0, math.rad(-18), math.rad(28)), accent, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingL2", Vector3.new(5.4, 1.2, 0.6), CFrame.new(-4.8, 7.2, 0.6) * CFrame.Angles(0, math.rad(-22), math.rad(42)), gold, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingR1", Vector3.new(6.8, 1.6, 0.7), CFrame.new(3.8, 5.6, 0.4) * CFrame.Angles(0, math.rad(18), math.rad(-28)), accent, Enum.Material.Neon, 0.08)
		addPart("PhoenixWingR2", Vector3.new(5.4, 1.2, 0.6), CFrame.new(4.8, 7.2, 0.6) * CFrame.Angles(0, math.rad(22), math.rad(-42)), gold, Enum.Material.Neon, 0.08)
		local crown = addPart("PhoenixCrown", Vector3.new(2.8, 2.8, 2.8), CFrame.new(0, 9.4, 0), Color3.fromRGB(255, 250, 210), Enum.Material.Neon, 0.02, Enum.PartType.Ball)



	else
		addPart("ObeliskBase", Vector3.new(4.8, 1.8, 4.8), CFrame.new(0, 0.9, 0), marble, Enum.Material.Marble, 0)
		addPart("ObeliskShaftLower", Vector3.new(3.2, 5.5, 3.2), CFrame.new(0, 4.5, 0), marble, Enum.Material.Marble, 0)
		addPart("ObeliskGoldBand", Vector3.new(3.5, 0.7, 3.5), CFrame.new(0, 7.5, 0), gold, Enum.Material.Neon, 0.05)
		addPart("ObeliskShaftUpper", Vector3.new(2.2, 4.2, 2.2), CFrame.new(0, 9.8, 0), marble, Enum.Material.Marble, 0)
		local apex = addPart("ObeliskApex", Vector3.new(2.4, 2.4, 2.4), CFrame.new(0, 12.8, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), accent, Enum.Material.Neon, 0.04)


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
			elseif desc:IsA("PointLight") or desc:IsA("SpotLight") or desc:IsA("SurfaceLight") then
				desc:Destroy()
			elseif desc:IsA("ParticleEmitter") then
				table.insert(lights, desc)
			end
		end

		return parts, lights
	end

	return buildFallbackMonument(islandFolder, zCfg, pedestalTopPos, dir)
end

local function createPadBillboard(pad, titleText, descText, costText, accentColor)
	local bbg = Instance.new("BillboardGui")
	bbg.Name = "PadGui"
	bbg.Adornee = pad
	bbg.Size = UDim2.fromOffset(184, 62)
	bbg.StudsOffset = Vector3.new(0, 3.0, 0)
	bbg.MaxDistance = 48
	bbg.AlwaysOnTop = false
	bbg.Parent = pad

	local bg = Instance.new("Frame", bbg)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 15, 24)
	bg.BackgroundTransparency = 0.14
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = accentColor or Color3.fromRGB(255, 200, 75)
	stroke.Thickness = 1.5

	local titleLbl = Instance.new("TextLabel", bg)
	titleLbl.Name = "TitleLabel"
	titleLbl.Position = UDim2.fromOffset(7, 3)
	titleLbl.Size = UDim2.new(1, -14, 0, 19)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText
	titleLbl.TextColor3 = Color3.fromRGB(255, 250, 235)
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 13
	titleLbl.TextScaled = false
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local descLbl = Instance.new("TextLabel", bg)
	descLbl.Name = "DescLabel"
	descLbl.Position = UDim2.fromOffset(7, 22)
	descLbl.Size = UDim2.new(1, -14, 0, 18)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = descText or ""
	descLbl.TextColor3 = Color3.fromRGB(214, 226, 248)
	descLbl.Font = Enum.Font.GothamBold
	descLbl.TextSize = 12
	descLbl.TextWrapped = false
	descLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local costLbl = Instance.new("TextLabel", bg)
	costLbl.Name = "CostLabel"
	costLbl.Position = UDim2.fromOffset(7, 40)
	costLbl.Size = UDim2.new(1, -14, 0, 18)
	costLbl.BackgroundTransparency = 1
	costLbl.Text = costText
	costLbl.TextColor3 = accentColor or Color3.fromRGB(255, 215, 80)
	costLbl.Font = Enum.Font.GothamBlack
	costLbl.TextSize = 12
	costLbl.TextTruncate = Enum.TextTruncate.AtEnd

	return titleLbl, descLbl, costLbl
end

local function createRoundGroundPad(parent, name, groundPos, diameter, color, titleText, descText, costText)
	local pad = makeUprightCylinder(
		parent,
		name,
		0.42,
		diameter,
		groundPos + Vector3.new(0, 0.21, 0),
		color or Color3.fromRGB(255, 200, 80),
		Enum.Material.Neon,
		0.18,
		false
	)
	local rim = makeUprightCylinder(
		pad,
		name .. "_Rim",
		0.22,
		diameter + 0.7,
		groundPos + Vector3.new(0, 0.11, 0),
		color or Color3.fromRGB(255, 200, 80),
		Enum.Material.Neon,
		0.05,
		false
	)
	rim.CanTouch = false
	rim.CanQuery = false

	local titleLbl, descLbl, costLbl = createPadBillboard(pad, titleText, descText, costText, color)
	return pad, rim, titleLbl, descLbl, costLbl
end

local function buildWeaponDisplayStand(parent, wep, standPos, faceDir)
	local standCF = CFrame.lookAt(standPos, standPos + faceDir)
	makeUprightCylinder(parent, wep.Id .. "_StandBase", 0.55, 4.4, standPos + Vector3.new(0, 0.275, 0), Color3.fromRGB(28, 32, 46), Enum.Material.Marble, 0, true)
	makeUprightCylinder(parent, wep.Id .. "_StandTrim", 0.22, 4.7, standPos + Vector3.new(0, 0.11, 0), wep.Color, Enum.Material.Neon, 0.12, false)
	makeUprightCylinder(parent, wep.Id .. "_StandPillar", 2.2, 2.0, standPos + Vector3.new(0, 1.65, 0), Color3.fromRGB(36, 42, 58), Enum.Material.Slate, 0, true)
	makeUprightCylinder(parent, wep.Id .. "_StandCap", 0.3, 2.7, standPos + Vector3.new(0, 2.85, 0), wep.Color, Enum.Material.Neon, 0.15, false)

	local displayPos = standPos + Vector3.new(0, 4.4, 0)
	local displayCF = CFrame.lookAt(displayPos, displayPos + faceDir) * CFrame.Angles(0, 0, math.rad(-22))
	local preview = makePart(parent, wep.Id .. "_Preview", Vector3.new(0.38, 3.2, 0.38), displayCF, Color3.fromRGB(64, 46, 36), Enum.Material.Wood, 0, false)
	local tip = makePart(parent, wep.Id .. "_PreviewGlow", Vector3.new(0.55, 1.5, 0.55), displayCF * CFrame.new(0, 1.5, 0), wep.Color, Enum.Material.Neon, 0.05, false)
	if wep.Id == "wep_torch" then
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(1.0, 1.2, 1.0)
	elseif wep.Id == "wep_zenith_scythe" then
		tip.Size = Vector3.new(0.24, 0.75, 2.6)
		tip.CFrame = displayCF * CFrame.new(0, 1.4, -0.8)
	elseif wep.Id == "wep_sunblade" then
		tip.Size = Vector3.new(0.24, 2.8, 0.75)
	end
	local pl = Instance.new("PointLight", tip)
	pl.Color = wep.Color
	pl.Range = 12
	pl.Brightness = 1.4
	local _ = standCF
	return preview
end

local function buildWispSanctuaryStation(parent, shrinePos, faceDir)
	local shrineModel = Instance.new("Model")
	shrineModel.Name = "WispSanctuaryShrine"
	shrineModel.Parent = parent

	local accentCyan = Color3.fromRGB(80, 225, 255)
	local accentViolet = Color3.fromRGB(195, 110, 255)
	local marble = Color3.fromRGB(32, 38, 56)

	makeUprightCylinder(shrineModel, "ShrineBase", 0.7, 9.6, shrinePos + Vector3.new(0, 0.35, 0), marble, Enum.Material.Marble, 0, true)
	makeUprightCylinder(shrineModel, "ShrineBaseRing", 0.32, 10.2, shrinePos + Vector3.new(0, 0.16, 0), accentCyan, Enum.Material.Neon, 0.1, false)
	makeUprightCylinder(shrineModel, "ShrineDais", 0.9, 6.2, shrinePos + Vector3.new(0, 1.15, 0), Color3.fromRGB(44, 50, 74), Enum.Material.Marble, 0, true)
	makeUprightCylinder(shrineModel, "ShrineRuneRing", 0.2, 6.6, shrinePos + Vector3.new(0, 1.62, 0), accentViolet, Enum.Material.Neon, 0.08, false)

	for i = 0, 2 do
		local ang = math.rad(i * 120 + 30)
		local pPos = shrinePos + Vector3.new(math.cos(ang) * 3.6, 2.8, math.sin(ang) * 3.6)
		makeUprightCylinder(shrineModel, "ShrinePillar_" .. (i + 1), 3.6, 0.9, pPos, marble, Enum.Material.Marble, 0, true)
		makePart(
			shrineModel,
			"ShrineCrystal_" .. (i + 1),
			Vector3.new(0.75, 1.1, 0.75),
			CFrame.new(pPos + Vector3.new(0, 2.5, 0)) * CFrame.Angles(math.rad(45), ang, 0),
			(i % 2 == 0) and accentCyan or accentViolet,
			Enum.Material.Neon,
			0.05,
			false
		)
	end

	local orbPos = shrinePos + Vector3.new(0, 4.6, 0)
	local orb = makePart(shrineModel, "ShrineCoreOrb", Vector3.new(2.2, 2.2, 2.2), CFrame.new(orbPos), accentCyan, Enum.Material.Neon, 0.05, false, Enum.PartType.Ball)
	makePart(shrineModel, "ShrineAuraShell", Vector3.new(3.2, 3.2, 3.2), CFrame.new(orbPos), accentViolet, Enum.Material.ForceField, 0.25, false, Enum.PartType.Ball)
	makePart(shrineModel, "ShrineHaloRing", Vector3.new(0.18, 4.2, 4.2), CFrame.new(orbPos) * CFrame.Angles(math.rad(25), 0, math.rad(72)), Color3.fromRGB(255, 225, 115), Enum.Material.Neon, 0.08, false, Enum.PartType.Cylinder)

	local shrineLight = Instance.new("PointLight", orb)
	shrineLight.Color = accentCyan
	shrineLight.Range = 22
	shrineLight.Brightness = 2.6

	local sparkles = Instance.new("ParticleEmitter", orb)
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.LightEmission = 1
	sparkles.Rate = 18
	sparkles.Lifetime = NumberRange.new(0.9, 1.6)
	sparkles.Speed = NumberRange.new(1.5, 3.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Color = ColorSequence.new(accentCyan, accentViolet)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })

	local shrineBbg = Instance.new("BillboardGui", orb)
	shrineBbg.Name = "ShrineTitleGui"
	shrineBbg.Size = UDim2.fromOffset(230, 38)
	shrineBbg.StudsOffset = Vector3.new(0, 3.2, 0)
	shrineBbg.MaxDistance = 65

	local shrineTitle = Instance.new("TextLabel", shrineBbg)
	shrineTitle.Name = "ShrineTitleLabel"
	shrineTitle.Size = UDim2.fromScale(1, 1)
	shrineTitle.BackgroundColor3 = Color3.fromRGB(14, 16, 28)
	shrineTitle.BackgroundTransparency = 0.2
	shrineTitle.Text = Localization.T("en", "PAD_WISP_SHRINE_TITLE")
	shrineTitle.TextColor3 = accentCyan
	shrineTitle.Font = Enum.Font.GothamBlack
	shrineTitle.TextSize = 15
	Instance.new("UICorner", shrineTitle).CornerRadius = UDim.new(0, 8)
	local sStroke = Instance.new("UIStroke", shrineTitle)
	sStroke.Color = accentViolet
	sStroke.Thickness = 1.4

	local _ = faceDir
	return shrineModel, shrineTitle
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
	flameLight.Name = "BrazierMainLight"
	flameLight.Color = Color3.fromRGB(255, 155, 55)
	flameLight.Range = 60
	flameLight.Brightness = 4.4
	flameLight.Shadows = true

	local emberLight = Instance.new("PointLight", emberRing)
	emberLight.Name = "BrazierEmberLight"
	emberLight.Color = Color3.fromRGB(255, 130, 40)
	emberLight.Range = 46
	emberLight.Brightness = 2.2

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
	titleBbg.Size = UDim2.fromOffset(240, 38)
	titleBbg.StudsOffset = Vector3.new(0, 6.4, 0)
	titleBbg.MaxDistance = 85

	local flameTitle = Instance.new("TextLabel", titleBbg)
	flameTitle.Size = UDim2.fromScale(1, 1)
	flameTitle.BackgroundTransparency = 1
	flameTitle.Text = Localization.T("en", "BRAZIER_DEFAULT_FMT", plotIndex)
	flameTitle.TextColor3 = Color3.fromRGB(255, 225, 110)
	flameTitle.TextStrokeTransparency = 0.15
	flameTitle.Font = Enum.Font.GothamBlack
	flameTitle.TextSize = 16

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

local function removeDefaultBaseplate(worldFolder)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (not worldFolder or not obj:IsDescendantOf(worldFolder)) then
			local isCharacterPart = obj.Parent and obj.Parent:FindFirstChildOfClass("Humanoid") ~= nil
			if not isCharacterPart then
				local lowerName = string.lower(obj.Name)
				local topY = obj.Position.Y + (obj.Size.Y * 0.5)
				local isDefaultFloor = (lowerName == "baseplate")
					or (math.abs(topY) <= 1.5 and (obj.Size.X >= 80 or obj.Size.Z >= 80))
				if isDefaultFloor then
					obj:Destroy()
				end
			end
		end
	end

	local terrain = Workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		pcall(function()
			terrain:Clear()
		end)
	end
end

local function applyBrazierOnlyDarkness()
	Lighting.ClockTime = 0
	Lighting.Brightness = 0
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
	Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
	Lighting.EnvironmentDiffuseScale = 0
	Lighting.EnvironmentSpecularScale = 0
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.ExposureCompensation = 0
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 45
	Lighting.FogEnd = 460

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("SunRaysEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end

	local voidSky = Instance.new("Sky")
	voidSky.Name = "VoidNightSky"
	voidSky.SkyboxBk = "rbxassetid://0"
	voidSky.SkyboxDn = "rbxassetid://0"
	voidSky.SkyboxFt = "rbxassetid://0"
	voidSky.SkyboxLf = "rbxassetid://0"
	voidSky.SkyboxRt = "rbxassetid://0"
	voidSky.SkyboxUp = "rbxassetid://0"
	voidSky.CelestialBodiesShown = false
	voidSky.StarCount = 0
	voidSky.Parent = Lighting

	local atm = Instance.new("Atmosphere")
	atm.Name = "VoidNightAtmosphere"
	atm.Density = 0.28
	atm.Offset = 0
	atm.Color = Color3.fromRGB(0, 0, 0)
	atm.Decay = Color3.fromRGB(0, 0, 0)
	atm.Glare = 0
	atm.Haze = 0.08
	atm.Parent = Lighting
end

function WorldBuilder.Build()
	applyBrazierOnlyDarkness()

	local existing = Workspace:FindFirstChild("LastFlameWorld")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "LastFlameWorld"
	world.Parent = Workspace

	-- Elimina il pavimento Baseplate di default di Roblox Studio così non attraversa piazza e slot
	removeDefaultBaseplate(world)

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

		-- === PASSERELLA DI COLLEGAMENTO A FILO (DA R = 51.50 A R = ringRadius - halfSize) ===
		local bridgeStart = hubRadius - 0.5
		local bridgeEnd = ringRadius - halfSize
		local hubBridgeLen = bridgeEnd - bridgeStart
		if hubBridgeLen > 4 then
			local bridgeMid = outwardDir * (bridgeStart + hubBridgeLen * 0.5)
			local bridgeCF = CFrame.lookAt(bridgeMid, bridgeMid + outwardDir)

			-- Piano principale a Y = -0.01 così si innesta sotto la piazza centrale senza Z-fighting né fessure
			makePart(plotModel, "HubBridge", Vector3.new(walkwayWidth, 1.8, hubBridgeLen), bridgeCF * CFrame.new(0, -0.91, 0), Color3.fromRGB(30, 35, 52), Enum.Material.Slate, 0, true)
			-- Cordoli laterali rialzati
			local curbOffset = walkwayWidth * 0.5 + 0.25
			makePart(plotModel, "HubBridgeCurbL", Vector3.new(0.5, 0.36, hubBridgeLen - 0.6), bridgeCF * CFrame.new(-curbOffset, 0.05, 0.3), Color3.fromRGB(48, 56, 80), Enum.Material.SmoothPlastic, 0, true)
			makePart(plotModel, "HubBridgeCurbR", Vector3.new(0.5, 0.36, hubBridgeLen - 0.6), bridgeCF * CFrame.new(curbOffset, 0.05, 0.3), Color3.fromRGB(48, 56, 80), Enum.Material.SmoothPlastic, 0, true)
			-- Striscia luminosa centrale leggermente sopra il piano (Y = 0.01, zero Z-fighting)
			makePart(plotModel, "HubBridgeGuideline", Vector3.new(0.36, 0.04, hubBridgeLen - 2.4), bridgeCF * CFrame.new(0, 0.01, 0.3), Color3.fromRGB(255, 195, 75), Enum.Material.Neon, 0.35, false)
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

		-- === POSTAZIONI ARMI DI DIFESA A TERRA (SINISTRA DEL PLOT, BOTTONI ROTONDI) ===
		local weaponsFolder = Instance.new("Folder")
		weaponsFolder.Name = "Weapons"
		weaponsFolder.Parent = plotModel

		local weaponPadRefs = {}
		local weaponOffsets = { -13.5, -4.5, 4.5, 13.5 }
		for idx, wep in ipairs(GameConfig.Weapons) do
			local offZ = weaponOffsets[idx] or ((idx - 2.5) * 9)
			local standPos = origin - rightDir * 31.0 + outwardDir * offZ
			local padPos = origin - rightDir * 25.5 + outwardDir * offZ
			buildWeaponDisplayStand(weaponsFolder, wep, standPos, rightDir)

			local pad, rim, tLbl, dLbl, cLbl = createRoundGroundPad(
				weaponsFolder,
				wep.Id,
				padPos,
				3.8,
				wep.Color or Color3.fromRGB(255, 185, 70),
				wep.Icon .. " " .. wep.Name,
				wep.Tag or wep.Desc or "",
				tostring(wep.BaseCost) .. " Light"
			)
			weaponPadRefs[wep.Id] = {
				Pad = pad,
				Rim = rim,
				TitleLabel = tLbl,
				DescLabel = dLbl,
				CostLabel = cLbl,
			}
		end

		-- === POSTAZIONE EVOCAZIONE SPIRITI (DESTRA DEL PLOT, ALTARE + BOTTONI ROTONDI) ===
		local wispFolder = Instance.new("Folder")
		wispFolder.Name = "WispStation"
		wispFolder.Parent = plotModel

		local shrinePos = origin + rightDir * 30.5
		local _, shrineTitle = buildWispSanctuaryStation(wispFolder, shrinePos, -rightDir)

		local wispPad1, wispRim1, w1Title, w1Desc, w1Cost = createRoundGroundPad(
			wispFolder,
			"WispPad_1",
			origin + rightDir * 24.0 + inwardDir * 4.5,
			4.0,
			Color3.fromRGB(80, 225, 255),
			Localization.T("en", "PAD_WISP_1_TITLE"),
			Localization.T("en", "PAD_WISP_LOCKED_DESC"),
			tostring(GameConfig.GetWispCost(0)) .. " Light"
		)

		local wispPad5, wispRim5, w5Title, w5Desc, w5Cost = createRoundGroundPad(
			wispFolder,
			"WispPad_5",
			origin + rightDir * 24.0 + outwardDir * 4.5,
			4.0,
			Color3.fromRGB(205, 115, 255),
			Localization.T("en", "PAD_WISP_5_TITLE"),
			Localization.T("en", "PAD_WISP_LOCKED_DESC"),
			tostring(GameConfig.GetWispCost(0) * 5) .. " Light"
		)

		local wispStationRefs = {
			ShrineTitle = shrineTitle,
			Pad1 = { Pad = wispPad1, Rim = wispRim1, TitleLabel = w1Title, DescLabel = w1Desc, CostLabel = w1Cost },
			Pad5 = { Pad = wispPad5, Rim = wispRim5, TitleLabel = w5Title, DescLabel = w5Desc, CostLabel = w5Cost },
		}

		-- === PEDANA RINASCITA DELL'ALBA (ROTONDA CON BORDO LUMINOSO) ===
		local victoryPos = origin + outwardDir * 21.5
		local victoryPad, victoryPadRim, vTitleLbl, vDescLbl, vStatusLbl = createRoundGroundPad(
			plotModel,
			"VictoryPad",
			victoryPos,
			5.8,
			Color3.fromRGB(255, 215, 75),
			"🌅 " .. GameConfig.VictoryButton.Name,
			"+1 Dawn Pt (Prestige)",
			"1B Light"
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

			local gatePos = origin + zDir * (edgeDist - 2.4)
			local gateCF = CFrame.lookAt(gatePos, gatePos + zDir)
			local gatePad = makeUprightCylinder(zFolder, "GatePad", 0.40, 4.2, gatePos + Vector3.new(0, 0.20, 0), z.Color, Enum.Material.Neon, 0.20, false)
			local gatePadRim = makeUprightCylinder(gatePad, "GatePad_Rim", 0.22, 4.9, gatePos + Vector3.new(0, 0.11, 0), z.Color, Enum.Material.Neon, 0.06, false)
			gatePadRim.CanTouch = false
			gatePadRim.CanQuery = false

			local gateBarrier = makePart(zFolder, "GateBarrier", Vector3.new(6.4, 7.2, 0.9), gateCF * CFrame.new(0, 3.6, 0), z.Color, Enum.Material.ForceField, 0.35, true)

			local gateBbg = Instance.new("BillboardGui", gatePad)
			gateBbg.Adornee = gatePad
			gateBbg.Size = UDim2.fromOffset(200, 38)
			gateBbg.StudsOffset = Vector3.new(0, 3.4, 0)
			gateBbg.MaxDistance = 70

			local gateLabel = Instance.new("TextLabel", gateBbg)
			gateLabel.Size = UDim2.fromScale(1, 1)
			gateLabel.BackgroundColor3 = Color3.fromRGB(14, 17, 28)
			gateLabel.BackgroundTransparency = 0.14
			gateLabel.Text = Localization.T("en", "ZONE_GATE_LOCKED_FMT", z.Name, z.Cost)
			gateLabel.TextColor3 = z.Color
			gateLabel.Font = Enum.Font.GothamBlack
			gateLabel.TextSize = 12
			gateLabel.TextWrapped = true
			Instance.new("UICorner", gateLabel).CornerRadius = UDim.new(0, 10)
			local gateStroke = Instance.new("UIStroke", gateLabel)
			gateStroke.Color = z.Color
			gateStroke.Thickness = 1.4

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
			zBbg.Size = UDim2.fromOffset(260, 40)
			zBbg.MaxDistance = 120

			local zoneTitle = Instance.new("TextLabel", zBbg)
			zoneTitle.Size = UDim2.fromScale(1, 1)
			zoneTitle.BackgroundTransparency = 1
			zoneTitle.Text = string.format("🔒 %s (x%.2f)", z.Name, z.LightMult or 1.0)
			zoneTitle.TextColor3 = z.Color
			zoneTitle.TextStrokeTransparency = 0.15
			zoneTitle.Font = Enum.Font.GothamBlack
			zoneTitle.TextSize = 15

			albaZoneRefs[z.Id] = {
				Bridge = bridge,
				BridgeTrim = bridgeTrim,
				GateBarrier = gateBarrier,
				GatePad = gatePad,
				GatePadRim = gatePadRim,
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
			Folder = plotModel,
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
			WeaponsFolder = weaponsFolder,
			WeaponPadRefs = weaponPadRefs,
			WispFolder = wispFolder,
			WispStationRefs = wispStationRefs,
			VictoryPad = victoryPad,
			VictoryPadRim = victoryPadRim,
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
