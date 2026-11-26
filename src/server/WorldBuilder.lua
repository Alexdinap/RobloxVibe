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
	bbg.Size = UDim2.fromOffset(230, 76)
	bbg.StudsOffset = Vector3.new(0, 4.4, 0)
	bbg.MaxDistance = 65
	bbg.AlwaysOnTop = false
	bbg.Parent = pad

	local bg = Instance.new("Frame", bbg)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
	bg.BackgroundTransparency = 0.22
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", bg)
	stroke.Color = accentColor or Color3.fromRGB(255, 200, 75)
	stroke.Thickness = 1.4

	local titleLbl = Instance.new("TextLabel", bg)
	titleLbl.Name = "TitleLabel"
	titleLbl.Position = UDim2.fromOffset(6, 3)
	titleLbl.Size = UDim2.new(1, -12, 0, 20)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = titleText
	titleLbl.TextColor3 = Color3.fromRGB(255, 248, 225)
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 13
	titleLbl.TextScaled = false
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd

	local descLbl = Instance.new("TextLabel", bg)
	descLbl.Name = "DescLabel"
	descLbl.Position = UDim2.fromOffset(8, 23)
	descLbl.Size = UDim2.new(1, -16, 0, 30)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = descText or ""
	descLbl.TextColor3 = Color3.fromRGB(195, 210, 235)
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextSize = 10
	descLbl.TextWrapped = true

	local costLbl = Instance.new("TextLabel", bg)
	costLbl.Name = "CostLabel"
	costLbl.Position = UDim2.fromOffset(6, 54)
	costLbl.Size = UDim2.new(1, -12, 0, 19)
	costLbl.BackgroundTransparency = 1
	costLbl.Text = costText
	costLbl.TextColor3 = accentColor or Color3.fromRGB(255, 215, 80)
	costLbl.Font = Enum.Font.GothamBold
	costLbl.TextSize = 12

	return titleLbl, descLbl, costLbl
end

function WorldBuilder.Build()
	local existing = Workspace:FindFirstChild("LastFlameWorld")
	if existing then
		existing:Destroy()
	end

	local world = Instance.new("Folder")
	world.Name = "LastFlameWorld"
	world.Parent = Workspace

	local hubFloor = makeUprightCylinder(world, "CentralHubFloor", 2, 110, Vector3.new(0, -1, 0), Color3.fromRGB(26, 30, 44), Enum.Material.Slate, 0, true)
	local hubRing = makeUprightCylinder(world, "CentralHubTrim", 2.2, 114, Vector3.new(0, -1.05, 0), Color3.fromRGB(255, 195, 70), Enum.Material.Neon, 0.25, false)
	local hubBeacon = makeUprightCylinder(world, "CentralBeacon", 16, 6, Vector3.new(0, 8, 0), Color3.fromRGB(255, 210, 95), Enum.Material.Neon, 0.15, true)
	local hubLight = Instance.new("PointLight", hubBeacon)
	hubLight.Color = Color3.fromRGB(255, 200, 80)
	hubLight.Range = 60
	hubLight.Brightness = 3.0

	local plots = {}
	local plotCount = GameConfig.PlotCount or 10
	local ringRadius = GameConfig.PlotRingRadius or 245
	local halfSize = GameConfig.PlotHalfSize or 42

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

		makePart(plotModel, "PlotFloor", Vector3.new(halfSize * 2, 2, halfSize * 2), plotLook * CFrame.new(0, -1, 0), Color3.fromRGB(24, 28, 42), Enum.Material.Slate, 0, true)
		makePart(plotModel, "PlotBorder", Vector3.new(halfSize * 2 + 2.4, 1.6, halfSize * 2 + 2.4), plotLook * CFrame.new(0, -1.1, 0), Color3.fromRGB(70, 145, 210), Enum.Material.Neon, 0.45, false)

		local hubBridgeLen = ringRadius - 54 - halfSize
		if hubBridgeLen > 10 then
			local bridgeMid = outwardDir * (54 + hubBridgeLen * 0.5)
			makePart(plotModel, "HubBridge", Vector3.new(8, 1.2, hubBridgeLen), CFrame.lookAt(bridgeMid, bridgeMid + outwardDir) * CFrame.new(0, -0.8, 0), Color3.fromRGB(30, 35, 52), Enum.Material.SmoothPlastic, 0, true)
		end

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

		local brazierModel = Instance.new("Model")
		brazierModel.Name = "Brazier"
		brazierModel.Parent = plotModel

		makeUprightCylinder(brazierModel, "BrazierPedestal", 2.2, 13.5, origin + Vector3.new(0, 1.1, 0), Color3.fromRGB(36, 40, 56), Enum.Material.Basalt, 0, true)
		local bowl = makeUprightCylinder(brazierModel, "BrazierBowl", 1.8, 10.5, origin + Vector3.new(0, 2.8, 0), Color3.fromRGB(48, 52, 70), Enum.Material.Metal, 0, true)
		local emberRing = makeUprightCylinder(brazierModel, "EmberRing", 0.5, 11.4, origin + Vector3.new(0, 3.6, 0), Color3.fromRGB(255, 150, 45), Enum.Material.Neon, 0.1, false)

		local baseFlameSize = Vector3.new(5.2, 6.2, 5.2)
		local baseFlamePos = origin + Vector3.new(0, 6.4, 0)
		local flameCore = makePart(brazierModel, "FlameCore", baseFlameSize, CFrame.new(baseFlamePos), Color3.fromRGB(255, 145, 45), Enum.Material.Neon, 0.12, false, Enum.PartType.Ball)

		local flameLight = Instance.new("PointLight", flameCore)
		flameLight.Color = Color3.fromRGB(255, 155, 55)
		flameLight.Range = 55
		flameLight.Brightness = 3.8

		local flameHitbox = makePart(brazierModel, "FlameHitbox", Vector3.new(11, 11, 11), CFrame.new(origin + Vector3.new(0, 6.0, 0)), Color3.fromRGB(255, 200, 80), Enum.Material.SmoothPlastic, 1, false)

		local titleBbg = Instance.new("BillboardGui", flameCore)
		titleBbg.Name = "BrazierTitleGui"
		titleBbg.Size = UDim2.fromOffset(220, 34)
		titleBbg.StudsOffset = Vector3.new(0, 6.2, 0)
		titleBbg.MaxDistance = 85

		local flameTitle = Instance.new("TextLabel", titleBbg)
		flameTitle.Size = UDim2.fromScale(1, 1)
		flameTitle.BackgroundTransparency = 1
		flameTitle.Text = Localization.T("en", "BRAZIER_DEFAULT_FMT", i)
		flameTitle.TextColor3 = Color3.fromRGB(255, 225, 110)
		flameTitle.TextStrokeTransparency = 0.2
		flameTitle.Font = Enum.Font.GothamBlack
		flameTitle.TextSize = 16

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
			local padPos = origin + dirPad * 16.5 + Vector3.new(0, 0.35, 0)
			local pad = makePart(
				altarsFolder,
				alt.Id,
				Vector3.new(5.6, 0.6, 5.6),
				CFrame.lookAt(padPos, padPos + inwardDir),
				alt.Color or Color3.fromRGB(255, 175, 55),
				Enum.Material.Neon,
				0.18,
				false
			)
			createPadBillboard(
				pad,
				string.format("%s [0/%d]", alt.Name, alt.MaxLevel or 1),
				alt.Desc or "",
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
			local padPos = origin + off + Vector3.new(0, 0.35, 0)
			local pad = makePart(
				altarsFolder,
				alt.Id,
				Vector3.new(5.4, 0.6, 5.4),
				CFrame.lookAt(padPos, padPos + inwardDir),
				alt.Color or Color3.fromRGB(255, 200, 80),
				Enum.Material.Neon,
				0.18,
				false
			)
			createPadBillboard(
				pad,
				"🎨 " .. alt.Name,
				alt.Desc or "",
				tostring(alt.BaseCost) .. " Light",
				alt.Color
			)
		end

		local victoryPos = origin + outwardDir * 21.5 + Vector3.new(0, 0.4, 0)
		local victoryPad = makePart(
			plotModel,
			"VictoryPad",
			Vector3.new(8.6, 0.7, 6.4),
			CFrame.lookAt(victoryPos, victoryPos + inwardDir),
			Color3.fromRGB(255, 215, 75),
			Enum.Material.Neon,
			0.14,
			false
		)
		local vTitleLbl, vDescLbl, vStatusLbl = createPadBillboard(
			victoryPad,
			"🌅 " .. GameConfig.VictoryButton.Name,
			GameConfig.VictoryButton.Desc or "",
			"Cost: 25B Light • +1 Dawn Pts",
			Color3.fromRGB(255, 220, 90)
		)

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
			local bridgeStartDist = edgeDist - 0.5
			local bridgeEndDist = zDist - 12.5
			local bridgeLen = math.max(10, bridgeEndDist - bridgeStartDist)
			local bridgeMid = origin + zDir * (bridgeStartDist + bridgeLen * 0.5)
			local bridgeCF = CFrame.lookAt(bridgeMid, bridgeMid + zDir)

			local bridge = makePart(zFolder, "Bridge", Vector3.new(5.6, 1.0, bridgeLen), bridgeCF * CFrame.new(0, -0.5, 0), Color3.fromRGB(36, 42, 60), Enum.Material.Marble, 0.65, false)
			local bridgeTrim = makePart(zFolder, "BridgeTrim", Vector3.new(6.2, 0.6, bridgeLen), bridgeCF * CFrame.new(0, -0.65, 0), z.Color, Enum.Material.Neon, 0.80, false)

			local gatePos = origin + zDir * (edgeDist - 1.8)
			local gateCF = CFrame.lookAt(gatePos, gatePos + zDir)
			local gatePad = makePart(zFolder, "GatePad", Vector3.new(5.8, 0.45, 4.2), gateCF * CFrame.new(0, 0.25, 0), z.Color, Enum.Material.Neon, 0.20, false)
			local gateBarrier = makePart(zFolder, "GateBarrier", Vector3.new(6.4, 7.2, 0.9), gateCF * CFrame.new(0, 3.6, 0), z.Color, Enum.Material.ForceField, 0.35, true)

			local gateBbg = Instance.new("BillboardGui", gateBarrier)
			gateBbg.Size = UDim2.fromOffset(220, 42)
			gateBbg.StudsOffset = Vector3.new(0, 4.2, 0)
			gateBbg.MaxDistance = 70

			local gateLabel = Instance.new("TextLabel", gateBbg)
			gateLabel.Size = UDim2.fromScale(1, 1)
			gateLabel.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
			gateLabel.BackgroundTransparency = 0.2
			gateLabel.Text = Localization.T("en", "ZONE_GATE_LOCKED_FMT", z.Name, z.Cost)
			gateLabel.TextColor3 = z.Color
			gateLabel.Font = Enum.Font.GothamBlack
			gateLabel.TextSize = 12
			Instance.new("UICorner", gateLabel).CornerRadius = UDim.new(0, 8)

			local islandBase = makeUprightCylinder(zFolder, "IslandBase", 2.4, 28, islandCenter + Vector3.new(0, -1.2, 0), Color3.fromRGB(32, 36, 52), Enum.Material.Slate, 0.55, false)
			local islandRim = makeUprightCylinder(zFolder, "IslandRim", 2.0, 29.4, islandCenter + Vector3.new(0, -1.35, 0), z.Color, Enum.Material.Neon, 0.70, false)
			local islandInner = makeUprightCylinder(zFolder, "IslandInner", 0.6, 21.5, islandCenter + Vector3.new(0, 0.2, 0), Color3.fromRGB(220, 224, 236), Enum.Material.Marble, 0.55, false)

			local pillars = {}
			for _, pDeg in ipairs({ -125, -45, 45, 125 }) do
				local pDir = (CFrame.fromAxisAngle(Vector3.yAxis, math.rad(pDeg)) * zDir).Unit
				local pPos = islandCenter + pDir * 11.8 + Vector3.new(0, 4.2, 0)
				local pil = makeUprightCylinder(zFolder, "IslandPillar", 7.8, 1.4, pPos, Color3.fromRGB(225, 228, 240), Enum.Material.Marble, 0.55, false)
				table.insert(pillars, pil)
			end

			local pedestal = makeUprightCylinder(zFolder, "MonumentPedestal", 1.8, 8.2, islandCenter + Vector3.new(0, 1.2, 0), Color3.fromRGB(46, 52, 72), Enum.Material.Marble, 0.55, false)
			local pedestalTopPos = islandCenter + Vector3.new(0, 2.1, 0)
			local monumentParts, monumentLights = placeMonumentOnIsland(zFolder, z, pedestalTopPos, zDir)

			local zTitleAnchor = makePart(zFolder, "ZoneTitleAnchor", Vector3.new(1, 1, 1), CFrame.new(islandCenter + Vector3.new(0, 15.5, 0)), z.Color, Enum.Material.SmoothPlastic, 1, false)
			local zBbg = Instance.new("BillboardGui", zTitleAnchor)
			zBbg.Size = UDim2.fromOffset(250, 38)
			zBbg.MaxDistance = 120

			local zoneTitle = Instance.new("TextLabel", zBbg)
			zoneTitle.Size = UDim2.fromScale(1, 1)
			zoneTitle.BackgroundTransparency = 1
			zoneTitle.Text = string.format("🔒 %s (x%.2f)", z.Name, z.LightMult or 1.0)
			zoneTitle.TextColor3 = z.Color
			zoneTitle.TextStrokeTransparency = 0.2
			zoneTitle.Font = Enum.Font.GothamBlack
			zoneTitle.TextSize = 14

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
			FlameCore = flameCore,
			BaseFlameSize = baseFlameSize,
			BaseFlamePos = baseFlamePos,
			FlameHitbox = flameHitbox,
			FlameTitle = flameTitle,
			EmberRing = emberRing,
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
