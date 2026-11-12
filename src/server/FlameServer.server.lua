local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

---------------------------------------------------------------------
-- 1. GENERAZIONE DEL MONDO OSCURO (SANTUARIO DELLA FIAMMA)
---------------------------------------------------------------------
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

-- LA FIAMMA PRIMORDIALE AL CENTRO
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
	Size = Vector3.new(12, 12, 12),
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

-- Targhetta discreta (non AlwaysOnTop e visibile solo vicino alla Fiamma)
local flameBb = Instance.new("BillboardGui")
flameBb.Size = UDim2.fromOffset(220, 34)
flameBb.StudsOffset = Vector3.new(0, 4.8, 0)
flameBb.MaxDistance = 45
flameBb.Parent = flameCore

local flameLbl = Instance.new("TextLabel")
flameLbl.Size = UDim2.fromScale(1, 1)
flameLbl.BackgroundTransparency = 1
flameLbl.Text = "🔥 CLICCA LA FIAMMA"
flameLbl.TextColor3 = Color3.fromRGB(255, 220, 125)
flameLbl.TextStrokeTransparency = 0.35
flameLbl.Font = Enum.Font.GothamBlack
flameLbl.TextScaled = true
flameLbl.Parent = flameBb

-- Gli 8 Altari a Terra (con Billboard puliti e visibili solo da vicino)
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
	bb.MaxDistance = 36
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
	t2.Text = "Lv. 0 | " .. GameConfig.Format(cfg.BaseCost)
	t2.TextColor3 = Color3.fromRGB(235, 232, 220)
	t2.Font = Enum.Font.GothamBold
	t2.TextScaled = true
end

-- I 5 REGNI OSCURI CHE SI RISVEGLIANO
local zonesFolder = Instance.new("Folder")
zonesFolder.Name = "WorldZones"
zonesFolder.Parent = world

local braziersFolder = Instance.new("Folder", zonesFolder)
braziersFolder.Name = "Braziers"
for i = 1, 12 do
	local ang = (i / 12) * math.pi * 2
	local pos = Vector3.new(math.cos(ang) * 44, 1, math.sin(ang) * 44)
	makePart({ Name = "Post_" .. i, Size = Vector3.new(2, 5.5, 2), Position = pos + Vector3.new(0, 2.75, 0), Color = Color3.fromRGB(32, 32, 38), Material = Enum.Material.Cobblestone, Parent = braziersFolder })
	local top = makePart({ Name = "Torch_" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), Position = pos + Vector3.new(0, 6.2, 0), Color = Color3.fromRGB(25, 25, 30), Material = Enum.Material.SmoothPlastic, Parent = braziersFolder })
	local l = Instance.new("PointLight", top); l.Color = Color3.fromRGB(255, 165, 50); l.Range = 28; l.Brightness = 0; l.Enabled = false
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

---------------------------------------------------------------------
-- 2. MOTORE ECONOMICO & REMOTES
---------------------------------------------------------------------
local remotes = Instance.new("Folder", ReplicatedStorage)
remotes.Name = "Remotes"

local function makeRemote(cls, name)
	local r = Instance.new(cls, remotes)
	r.Name = name
	return r
end

local StateSync = makeRemote("RemoteEvent", "StateSync")
local ClickFlameEvent = makeRemote("RemoteEvent", "ClickFlame")
local BuyUpgrade = makeRemote("RemoteEvent", "BuyUpgrade")
local BuyStarPerk = makeRemote("RemoteEvent", "BuyStarPerk")
local SummonWisp = makeRemote("RemoteEvent", "SummonWisp")
local FuseWisp = makeRemote("RemoteEvent", "FuseWisp")
local PrestigeEvent = makeRemote("RemoteEvent", "Prestige")
local RedeemCode = makeRemote("RemoteFunction", "RedeemCode")

local mainStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("LastFlame_V4")
end)

local PlayerData = {}
local ClickHeat = {}
local ActiveEmbers = {}
local ActiveShadows = {}

local function defaultData()
	return {
		Points = 0,
		TotalPoints = 0,
		TotalClicks = 0,
		EternalStars = 0,
		Altars = {},
		Upgrades = {},
		StarPerks = {},
		Wisps = {},
		UsedCodes = {},
		LastLogout = os.time(),
	}
end

local function getLvl(tbl, id)
	return (tbl and tbl[id]) or 0
end

local function getRank(lightPct)
	local best = GameConfig.Ranks[1]
	for _, r in ipairs(GameConfig.Ranks) do
		if lightPct >= r.MinLight then best = r end
	end
	return best
end

local function getMaxWispSlots(data)
	return GameConfig.BaseEquippedWisps + getLvl(data.Upgrades, "u_wisp_slot")
end

local function parseWispId(rawId)
	local isRadiant = string.sub(rawId, -4) == "_rad"
	local baseId = isRadiant and string.sub(rawId, 1, -5) or rawId
	for _, cfg in ipairs(GameConfig.Wisps) do
		if cfg.Id == baseId then return cfg, isRadiant end
	end
	return nil, false
end

local function getEquippedWisps(data)
	local list = {}
	for _, rawId in ipairs(data.Wisps) do
		local cfg, rad = parseWispId(rawId)
		if cfg then
			local mult = rad and 2.5 or 1.0
			table.insert(list, {
				RawId = rawId,
				Id = cfg.Id,
				Radiant = rad,
				ClickMult = cfg.ClickMult * mult,
			})
		end
	end
	table.sort(list, function(a, b) return a.ClickMult > b.ClickMult end)
	local eq = {}
	for i = 1, math.min(getMaxWispSlots(data), #list) do
		table.insert(eq, list[i])
	end
	return eq
end

local function calculateStats(data, userId)
	local baseClick = 1
	local clickMult = 1
	local pointsPerSec = 0
	local critChance = 0
	local critMult = 12 * (2 ^ getLvl(data.StarPerks, "sp_crit"))
	local autoClicksPerSec = 0
	local maxHeatBonus = 2.0
	local lightPercent = 4

	for _, alt in ipairs(GameConfig.Altars) do
		local lvl = getLvl(data.Altars, alt.Id)
		if lvl > 0 then
			pointsPerSec += alt.Pps * lvl
			baseClick += alt.ClickBonus * lvl
		end
	end

	for _, upg in ipairs(GameConfig.Upgrades) do
		local lvl = getLvl(data.Upgrades, upg.Id)
		if lvl > 0 then
			lightPercent += upg.LightPct * lvl
			if upg.Effect == "ClickAdd" then
				baseClick += upg.Value * lvl
			elseif upg.Effect == "ClickMult" then
				clickMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "CritChance" then
				critChance = math.min(0.75, critChance + upg.Value * lvl)
			elseif upg.Effect == "AutoClick" then
				autoClicksPerSec += upg.Value * lvl
			elseif upg.Effect == "HeatMax" then
				maxHeatBonus += upg.Value * lvl
			end
		end
	end

	local equipped = getEquippedWisps(data)
	local wispBonus = 1
	for _, w in ipairs(equipped) do
		wispBonus += (w.ClickMult - 1)
	end
	clickMult *= wispBonus

	if data.EternalStars > 0 then
		clickMult *= (4 ^ data.EternalStars)
	end
	local starPowerLvl = getLvl(data.StarPerks, "sp_power")
	if starPowerLvl > 0 then
		clickMult *= (5 ^ starPowerLvl)
	end

	local heat = 0
	if userId and ClickHeat[userId] then
		local elapsed = os.clock() - ClickHeat[userId].LastClick
		heat = math.max(0, ClickHeat[userId].Heat - elapsed * 0.22)
		ClickHeat[userId].Heat = heat
	end
	local heatMult = 1 + (heat * maxHeatBonus)

	local finalClickPower = baseClick * clickMult * heatMult
	local finalPps = (pointsPerSec * clickMult * 0.25) + (autoClicksPerSec * finalClickPower)

	return {
		ClickPower = finalClickPower,
		PointsPerSec = finalPps,
		CritChance = critChance,
		CritMult = critMult,
		Heat = heat,
		HeatMult = heatMult,
		LightPercent = math.min(100, math.floor(lightPercent)),
		RadiusLevel = getLvl(data.Upgrades, "u_radius"),
		EquippedWisps = equipped,
		MaxWispSlots = getMaxWispSlots(data),
	}
end

local function syncPlayer(player, extra)
	local data = PlayerData[player.UserId]
	if not data then return end
	local stats = calculateStats(data, player.UserId)
	local rank = getRank(stats.LightPercent)

	local eqIds = {}
	for _, w in ipairs(stats.EquippedWisps) do
		table.insert(eqIds, w.RawId)
	end
	player:SetAttribute("EquippedWisps", HttpService:JSONEncode(eqIds))
	player:SetAttribute("RadiusLevel", stats.RadiusLevel)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Punti.Value = GameConfig.Format(data.Points)
		ls.Luce.Value = tostring(stats.LightPercent) .. "%"
	end

	local wispCounts = {}
	for _, rawId in ipairs(data.Wisps) do
		wispCounts[rawId] = (wispCounts[rawId] or 0) + 1
	end

	local payload = {
		Points = data.Points,
		EternalStars = data.EternalStars,
		ClickPower = stats.ClickPower,
		PointsPerSec = stats.PointsPerSec,
		Heat = stats.Heat,
		HeatMult = stats.HeatMult,
		LightPercent = stats.LightPercent,
		RankName = rank.Name,
		Altars = data.Altars,
		Upgrades = data.Upgrades,
		StarPerks = data.StarPerks,
		WispCounts = wispCounts,
		EquippedCount = #stats.EquippedWisps,
		MaxWispSlots = stats.MaxWispSlots,
	}
	if extra then
		for k, v in pairs(extra) do payload[k] = v end
	end
	StateSync:FireClient(player, payload)
end

-- Click sulla Fiamma
local LastClickTime = {}
local function handleFlameClick(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local now = os.clock()
	if LastClickTime[player.UserId] and (now - LastClickTime[player.UserId] < 0.045) then
		return
	end
	LastClickTime[player.UserId] = now

	local h = ClickHeat[player.UserId] or { Heat = 0, LastClick = now }
	local decay = math.max(0, (now - h.LastClick) * 0.22)
	h.Heat = math.min(1.0, math.max(0, h.Heat - decay) + 0.08)
	h.LastClick = now
	ClickHeat[player.UserId] = h

	local stats = calculateStats(data, player.UserId)
	local isCrit = math.random() < stats.CritChance
	local gained = stats.ClickPower * (isCrit and stats.CritMult or 1)

	data.Points += gained
	data.TotalPoints += gained
	data.TotalClicks += 1

	syncPlayer(player, {
		FlameClicked = true,
		IsCrit = isCrit,
		SoundCue = isCrit and "Crit" or "Click",
	})
end

for _, part in ipairs({ flameCore, brazierBowl, flameHitbox }) do
	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 75
	cd.Parent = part
	cd.MouseClick:Connect(handleFlameClick)
end
ClickFlameEvent.OnServerEvent:Connect(handleFlameClick)

-- Altari a Terra
local TouchingMap = {}
for _, alt in ipairs(GameConfig.Altars) do
	local pad = altarsFolder:FindFirstChild(alt.Id)
	if pad then
		TouchingMap[alt.Id] = {}
		pad.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then TouchingMap[alt.Id][plr.UserId] = plr end
		end)
		pad.TouchEnded:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then TouchingMap[alt.Id][plr.UserId] = nil end
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(0.14)
		for _, alt in ipairs(GameConfig.Altars) do
			for _, plr in pairs(TouchingMap[alt.Id]) do
				local data = plr and plr.Parent and PlayerData[plr.UserId]
				if data then
					local lvl = getLvl(data.Altars, alt.Id)
					local cost = math.floor(alt.BaseCost * (alt.CostMult ^ lvl))
					if data.Points >= cost then
						data.Points -= cost
						data.Altars[alt.Id] = lvl + 1
						syncPlayer(plr, { SoundCue = "Buy" })
					end
				end
			end
		end
	end
end)

BuyUpgrade.OnServerEvent:Connect(function(player, upgId)
	local data = PlayerData[player.UserId]
	if not data then return end
	local target
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Id == upgId then target = u; break end
	end
	if not target then return end
	local cur = getLvl(data.Upgrades, target.Id)
	if cur >= target.MaxLevel then return end

	local cost = math.floor(target.BaseCost * (target.CostMult ^ cur))
	if data.Points >= cost then
		data.Points -= cost
		data.Upgrades[target.Id] = cur + 1
		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = target.Zone ~= nil,
			StatusBanner = target.Zone and ("✨ Regno risvegliato: " .. target.Name) or nil,
		})
	end
end)

BuyStarPerk.OnServerEvent:Connect(function(player, perkId)
	local data = PlayerData[player.UserId]
	if not data then return end
	local target
	for _, p in ipairs(GameConfig.StarPerks) do
		if p.Id == perkId then target = p; break end
	end
	if not target then return end
	local cur = getLvl(data.StarPerks, target.Id)
	if cur >= target.MaxLevel then return end
	local cost = math.floor(target.Cost * (target.CostMult ^ cur))
	if data.EternalStars >= cost then
		data.EternalStars -= cost
		data.StarPerks[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Prestige", StatusBanner = "⭐ Costellazione sbloccata: " .. target.Name })
	end
end)

SummonWisp.OnServerEvent:Connect(function(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local totalCost = GameConfig.BaseWispCost * amount
	if data.Points < totalCost then
		syncPlayer(player, { StatusBanner = "Servono " .. GameConfig.Format(totalCost) .. " Punti Luce" })
		return
	end
	data.Points -= totalCost
	local best = nil
	for _ = 1, amount do
		local roll, acc, chosen = math.random(1, 1000), 0, GameConfig.Wisps[1]
		for _, w in ipairs(GameConfig.Wisps) do
			acc += w.Weight
			if roll <= acc then chosen = w; break end
		end
		table.insert(data.Wisps, chosen.Id)
		if not best or chosen.ClickMult > best.ClickMult then best = chosen end
	end
	syncPlayer(player, {
		SoundCue = "Upgrade",
		StatusBanner = amount == 1 and ("✨ Evocato: " .. best.Name) or ("✨ Evocati " .. amount .. " Spiriti (" .. best.Name .. ")"),
	})
end)

FuseWisp.OnServerEvent:Connect(function(player, baseWispId)
	local data = PlayerData[player.UserId]
	if not data or type(baseWispId) ~= "string" then return end

	local idxs = {}
	for i, rawId in ipairs(data.Wisps) do
		if rawId == baseWispId then
			table.insert(idxs, i)
			if #idxs == 3 then break end
		end
	end
	if #idxs < 3 then return end

	for i = 3, 1, -1 do
		table.remove(data.Wisps, idxs[i])
	end
	table.insert(data.Wisps, baseWispId .. "_rad")

	local cfg = parseWispId(baseWispId)
	syncPlayer(player, {
		SoundCue = "Prestige",
		Shockwave = true,
		StatusBanner = "🌟 Forgiato: " .. (cfg and cfg.Name or "Spirito") .. " Radioso (x2.5)",
	})
end)

PrestigeEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data or data.Points < GameConfig.PrestigeCost then return end

	local gained = math.max(1, math.floor(math.log10(data.Points / 1e7)))
	data.EternalStars += gained

	local startLvl = getLvl(data.StarPerks, "sp_start")
	data.Points = startLvl > 0 and (5000 * startLvl) or 0
	data.Altars = {}
	data.Upgrades = startLvl > 0 and { u_click_add = 5 * startLvl } or {}

	syncPlayer(player, {
		SoundCue = "Prestige",
		Shockwave = true,
		StatusBanner = "🌅 Grande Alba compiuta! +" .. gained .. " Stelle Eterne",
	})
end)

RedeemCode.OnServerInvoke = function(player, raw)
	local data = PlayerData[player.UserId]
	if not data or type(raw) ~= "string" then return false, "Errore" end
	local code = string.upper(string.gsub(raw, "%s+", ""))
	if data.UsedCodes[code] then return false, "Codice già usato" end
	local rew = GameConfig.PromoCodes[code]
	if not rew then return false, "Codice non valido" end
	data.UsedCodes[code] = true
	data.Points += rew.Points
	data.TotalPoints += rew.Points
	syncPlayer(player, { SoundCue = "Upgrade", StatusBanner = rew.Msg })
	return true, rew.Msg
end

-- Sfere Vaganti & Ombre
local function spawnWanderingEmber()
	local ember = makePart({
		Name = "WanderingEmber",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.4, 2.4, 2.4),
		Position = Vector3.new(math.random(-60, 60), 2.5, math.random(-60, 60)),
		Color = Color3.fromRGB(255, 200, 75),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	local l = Instance.new("PointLight", ember)
	l.Color = Color3.fromRGB(255, 190, 60)
	l.Range = 14
	l.Brightness = 2

	ActiveEmbers[ember] = true
	local taken = false
	ember.Touched:Connect(function(hit)
		if taken then return end
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		local data = plr and PlayerData[plr.UserId]
		if data then
			taken = true
			ActiveEmbers[ember] = nil
			local stats = calculateStats(data, plr.UserId)
			local gain = math.max(10, stats.ClickPower * 8)
			data.Points += gain
			data.TotalPoints += gain
			syncPlayer(plr, { SoundCue = "Click", StatusBanner = "✨ Sfera raccolta: +" .. GameConfig.Format(gain) .. " Punti" })
			ember:Destroy()
		end
	end)
	task.delay(22, function()
		ActiveEmbers[ember] = nil
		if ember and ember.Parent then ember:Destroy() end
	end)
end

local function banishShadow(shadowObj, player)
	local idx = table.find(ActiveShadows, shadowObj)
	if not idx then return end
	table.remove(ActiveShadows, idx)
	if shadowObj and shadowObj.Parent then shadowObj:Destroy() end

	if player and PlayerData[player.UserId] then
		local data = PlayerData[player.UserId]
		local stats = calculateStats(data, player.UserId)
		local reward = math.max(25, stats.ClickPower * 15)
		data.Points += reward
		data.TotalPoints += reward
		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = true,
			StatusBanner = "🛡️ Ombra dissipata: +" .. GameConfig.Format(reward) .. " Punti",
		})
	end
end

local function spawnShadowWisp()
	if #ActiveShadows >= 2 then return end
	local ang = math.random() * math.pi * 2
	local shadow = makePart({
		Name = "VoidShadow",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(4.2, 4.2, 4.2),
		Position = Vector3.new(math.cos(ang) * 90, 3.8, math.sin(ang) * 90),
		Color = Color3.fromRGB(25, 10, 45),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	local sLight = Instance.new("PointLight", shadow)
	sLight.Color = Color3.fromRGB(145, 40, 220)
	sLight.Range = 16
	sLight.Brightness = 2.5

	local cd = Instance.new("ClickDetector", shadow)
	cd.MaxActivationDistance = 50
	cd.MouseClick:Connect(function(plr) banishShadow(shadow, plr) end)
	table.insert(ActiveShadows, shadow)
end

task.spawn(function()
	while true do
		task.wait(11)
		spawnWanderingEmber()
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		if #Players:GetPlayers() > 0 then spawnShadowWisp() end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		for i = #ActiveShadows, 1, -1 do
			local sh = ActiveShadows[i]
			if not sh or not sh.Parent then
				table.remove(ActiveShadows, i)
			else
				local toCenter = Vector3.new(0, 3.8, 0) - sh.Position
				if toCenter.Magnitude <= 6.5 then
					table.remove(ActiveShadows, i)
					sh:Destroy()
				else
					sh.Position += toCenter.Unit * 0.35
				end
			end
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			local data = PlayerData[plr.UserId]
			if data then
				local stats = calculateStats(data, plr.UserId)
				if stats.PointsPerSec > 0 then
					data.Points += stats.PointsPerSec * 0.1
					data.TotalPoints += stats.PointsPerSec * 0.1
				end

				if getLvl(data.StarPerks, "sp_ward") > 0 and #ActiveShadows > 0 then
					banishShadow(ActiveShadows[1], plr)
				end

				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local purgeRadius = 12 + (#stats.EquippedWisps * 2.5) + (stats.RadiusLevel * 1.5)
					for i = #ActiveShadows, 1, -1 do
						local sh = ActiveShadows[i]
						if sh and sh.Parent and (hrp.Position - sh.Position).Magnitude <= purgeRadius then
							banishShadow(sh, plr)
						end
					end
					if getLvl(data.Upgrades, "u_ember_mag") > 0 then
						for emb in pairs(ActiveEmbers) do
							if emb and emb.Parent and (hrp.Position - emb.Position).Magnitude < 38 then
								emb.Position += (hrp.Position - emb.Position).Unit * 2.4
							end
						end
					end
				end

				syncPlayer(plr)
			end
		end
	end
end)

local function savePlayer(player, removeCache)
	local data = PlayerData[player.UserId]
	if data then
		data.LastLogout = os.time()
		if mainStore then
			pcall(function() mainStore:SetAsync("Plr_" .. player.UserId, data) end)
		end
	end
	if removeCache then PlayerData[player.UserId] = nil end
end

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder", player); ls.Name = "leaderstats"
	local p = Instance.new("StringValue", ls); p.Name = "Punti"; p.Value = "0"
	local l = Instance.new("StringValue", ls); l.Name = "Luce"; l.Value = "4%"

	local data = defaultData()
	if mainStore then
		local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do data[k] = v end
		end
	end
	PlayerData[player.UserId] = data
	task.wait(0.8)
	syncPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player) savePlayer(player, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)
