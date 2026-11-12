local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

---------------------------------------------------------------------
-- 1. GENERAZIONE DEL MONDO OSCURO (SANTUARIO DELLA FIAMMA)
---------------------------------------------------------------------
Lighting.Brightness = 0.2
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

makePart({ Name = "SanctuaryGround", Size = Vector3.new(220, 2, 220), Position = Vector3.new(0, 0, 0), Color = Color3.fromRGB(22, 24, 30), Material = Enum.Material.Slate, Parent = world })

local spawn = Instance.new("SpawnLocation")
spawn.Name = "SanctuarySpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(10, 0.5, 10)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 42), Vector3.new(0, 1.25, 0))
spawn.Color = Color3.fromRGB(60, 50, 40)
spawn.Material = Enum.Material.Cobblestone
spawn.Parent = world

-- LA FIAMMA PRIMORDIALE AL CENTRO (0, 0, 0)
local flameModel = Instance.new("Model")
flameModel.Name = "PrimordialFlame"
flameModel.Parent = world

makePart({ Name = "BrazierStone", Size = Vector3.new(10, 1.5, 10), Position = Vector3.new(0, 1.75, 0), Color = Color3.fromRGB(35, 36, 42), Material = Enum.Material.Cobblestone, Parent = flameModel })
makePart({ Name = "BrazierBowl", Size = Vector3.new(7, 1.2, 7), Position = Vector3.new(0, 3.0, 0), Color = Color3.fromRGB(48, 35, 25), Material = Enum.Material.Metal, Parent = flameModel })

local flameCore = makePart({
	Name = "FlameCore",
	Shape = Enum.PartType.Ball,
	Size = Vector3.new(3.5, 4.5, 3.5),
	Position = Vector3.new(0, 5.5, 0),
	Color = Color3.fromRGB(255, 155, 40),
	Material = Enum.Material.Neon,
	CanCollide = false,
	Parent = flameModel,
})

local fireFx = Instance.new("Fire")
fireFx.Size = 8
fireFx.Heat = 12
fireFx.Color = Color3.fromRGB(255, 175, 50)
fireFx.SecondaryColor = Color3.fromRGB(255, 80, 20)
fireFx.Parent = flameCore

local flameLight = Instance.new("PointLight")
flameLight.Name = "MainFlameLight"
flameLight.Color = Color3.fromRGB(255, 185, 85)
flameLight.Range = 28
flameLight.Brightness = 2.5
flameLight.Parent = flameCore

local flameClick = Instance.new("ClickDetector")
flameClick.Name = "StokeClick"
flameClick.MaxActivationDistance = 45
flameClick.Parent = flameCore

local flameBb = Instance.new("BillboardGui")
flameBb.Size = UDim2.fromOffset(230, 52)
flameBb.StudsOffset = Vector3.new(0, 4.8, 0)
flameBb.AlwaysOnTop = true
flameBb.Parent = flameCore

local flameLbl = Instance.new("TextLabel")
flameLbl.Size = UDim2.fromScale(1, 1)
flameLbl.BackgroundTransparency = 1
flameLbl.Text = "🔥 ALIMENTA LA FIAMMA 🔥"
flameLbl.TextColor3 = Color3.fromRGB(255, 215, 110)
flameLbl.TextStrokeTransparency = 0.2
flameLbl.Font = Enum.Font.GothamBlack
flameLbl.TextScaled = true
flameLbl.Parent = flameBb

-- Gli 8 Altari a terra
local altarsFolder = Instance.new("Folder")
altarsFolder.Name = "LightAltars"
altarsFolder.Parent = world

for _, cfg in ipairs(GameConfig.Altars) do
	local pad = makePart({
		Name = cfg.Id,
		Size = Vector3.new(8, 1.0, 8),
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
	bb.Size = UDim2.fromOffset(200, 75)
	bb.StudsOffset = Vector3.new(0, 3.6, 0)
	bb.Parent = pad

	local bg = Instance.new("Frame", bb)
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(16, 15, 22)
	bg.BackgroundTransparency = 0.2
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

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
	t2.TextColor3 = Color3.fromRGB(240, 235, 220)
	t2.Font = Enum.Font.GothamBold
	t2.TextScaled = true
end

-- ZONE DEL MONDO CHE SI ILLUMINANO PROGRESSIVAMENTE
local zonesFolder = Instance.new("Folder")
zonesFolder.Name = "WorldZones"
zonesFolder.Parent = world

-- Zona 1: Sentiero dei Bracieri
local braziersFolder = Instance.new("Folder", zonesFolder)
braziersFolder.Name = "Braziers"
local brazierCoords = {
	Vector3.new(-8, 1, 26), Vector3.new(8, 1, 26),
	Vector3.new(-8, 1, -26), Vector3.new(8, 1, -26),
	Vector3.new(-32, 1, 8), Vector3.new(-32, 1, -8),
	Vector3.new(32, 1, 8), Vector3.new(32, 1, -8),
}
for i, pos in ipairs(brazierCoords) do
	makePart({ Name = "Post_" .. i, Size = Vector3.new(2, 5, 2), Position = pos + Vector3.new(0, 2.5, 0), Color = Color3.fromRGB(32, 32, 38), Material = Enum.Material.Cobblestone, Parent = braziersFolder })
	local top = makePart({ Name = "Torch_" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2), Position = pos + Vector3.new(0, 5.8, 0), Color = Color3.fromRGB(25, 25, 30), Material = Enum.Material.SmoothPlastic, Parent = braziersFolder })
	local l = Instance.new("PointLight", top); l.Color = Color3.fromRGB(255, 165, 50); l.Range = 26; l.Brightness = 0; l.Enabled = false
end

-- Zona 2: Foresta di Cristallo (Est, X = +65)
local crystalsFolder = Instance.new("Folder", zonesFolder)
crystalsFolder.Name = "Crystals"
for i = 1, 10 do
	local ang = (i / 10) * math.pi * 2
	local rad = 8 + (i % 3) * 6
	local pos = Vector3.new(65 + math.cos(ang) * rad, 1, math.sin(ang) * rad)
	local h = 10 + (i % 4) * 5
	local c = makePart({
		Name = "Crystal_" .. i,
		Size = Vector3.new(3.5, h, 3.5),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(math.rad((i % 3 - 1) * 12), ang, math.rad((i % 2) * 10)),
		Color = Color3.fromRGB(20, 24, 32),
		Material = Enum.Material.SmoothPlastic,
		Parent = crystalsFolder,
	})
	if i % 3 == 0 then
		local l = Instance.new("PointLight", c); l.Color = Color3.fromRGB(60, 255, 210); l.Range = 36; l.Brightness = 0; l.Enabled = false
	end
end

-- Zona 3: Cascata Eterea (Ovest, X = -72)
local waterfallFolder = Instance.new("Folder", zonesFolder)
waterfallFolder.Name = "Waterfall"
makePart({ Name = "CliffBack", Size = Vector3.new(12, 34, 28), Position = Vector3.new(-76, 17, 0), Color = Color3.fromRGB(28, 30, 36), Material = Enum.Material.Rock, Parent = waterfallFolder })
local waterStream = makePart({ Name = "WaterStream", Size = Vector3.new(2, 30, 16), Position = Vector3.new(-69.5, 16, 0), Color = Color3.fromRGB(22, 26, 35), Material = Enum.Material.SmoothPlastic, Parent = waterfallFolder })
local waterPool = makePart({ Name = "WaterPool", Size = Vector3.new(16, 0.8, 22), Position = Vector3.new(-62, 1.3, 0), Color = Color3.fromRGB(22, 26, 35), Material = Enum.Material.SmoothPlastic, Parent = waterfallFolder })
local wfLight = Instance.new("PointLight", waterStream); wfLight.Color = Color3.fromRGB(110, 220, 255); wfLight.Range = 45; wfLight.Brightness = 0; wfLight.Enabled = false

-- Zona 4: Tempio dell'Alba (Nord, Z = -74)
local templeFolder = Instance.new("Folder", zonesFolder)
templeFolder.Name = "Temple"
makePart({ Name = "TempleFloor", Size = Vector3.new(44, 2, 26), Position = Vector3.new(0, 1.5, -74), Color = Color3.fromRGB(34, 34, 40), Material = Enum.Material.Marble, Parent = templeFolder })
for _, px in ipairs({ -16, -6, 6, 16 }) do
	makePart({ Name = "Pillar", Size = Vector3.new(3.5, 26, 3.5), Position = Vector3.new(px, 15, -74), Color = Color3.fromRGB(36, 36, 44), Material = Enum.Material.Marble, Parent = templeFolder })
end
local sunDisc = makePart({ Name = "SunDisc", Shape = Enum.PartType.Ball, Size = Vector3.new(12, 12, 12), Position = Vector3.new(0, 22, -78), Color = Color3.fromRGB(30, 30, 36), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = templeFolder })
local sunLight = Instance.new("PointLight", sunDisc); sunLight.Color = Color3.fromRGB(255, 225, 110); sunLight.Range = 60; sunLight.Brightness = 0; sunLight.Enabled = false

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
local BuyUpgrade = makeRemote("RemoteEvent", "BuyUpgrade")
local SummonWisp = makeRemote("RemoteEvent", "SummonWisp")
local PrestigeEvent = makeRemote("RemoteEvent", "Prestige")
local RedeemCode = makeRemote("RemoteFunction", "RedeemCode")

local mainStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("LastFlame_V1")
end)

local PlayerData = {}
local ActiveEmbers = {}

local function defaultData()
	return {
		Sparks = 15,
		TotalSparks = 15,
		SunEssence = 0,
		EternalStars = 0,
		Altars = {},
		Upgrades = {},
		Wisps = {},
		UsedCodes = {},
	}
end

local function getLvl(tbl, id)
	return (tbl and tbl[id]) or 0
end

local function getEquippedWisps(data)
	local list = {}
	for _, wId in ipairs(data.Wisps) do
		for _, cfg in ipairs(GameConfig.Wisps) do
			if cfg.Id == wId then
				table.insert(list, cfg)
				break
			end
		end
	end
	table.sort(list, function(a, b) return a.SparkMult > b.SparkMult end)
	local eq = {}
	for i = 1, math.min(GameConfig.MaxEquippedWisps, #list) do
		table.insert(eq, list[i])
	end
	return eq
end

local function calculateStats(data)
	local baseSparks = 0
	local sparkMult = 1
	local sunSec = 0
	local sunMult = 1
	local clickMult = 1
	local wispSynergy = 1
	local lightPercent = 4

	for _, alt in ipairs(GameConfig.Altars) do
		local lvl = getLvl(data.Altars, alt.Id)
		if lvl > 0 then
			if alt.Type == "AddSpark" then
				baseSparks += alt.Value * lvl
			elseif alt.Type == "MultSpark" then
				sparkMult *= (alt.Value ^ lvl)
			end
		end
	end

	for _, upg in ipairs(GameConfig.Upgrades) do
		local lvl = getLvl(data.Upgrades, upg.Id)
		if lvl > 0 then
			lightPercent += upg.LightPct * lvl
			if upg.Effect == "ClickMult" then clickMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "SparkMult" then sparkMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "SunMult" then sunMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "UnlockSun" then sunSec += 1
			elseif upg.Effect == "WispBonus" then wispSynergy += upg.Value * lvl
			elseif upg.Effect == "AllMult" then
				sparkMult *= (upg.Value ^ lvl)
				sunMult *= (upg.Value ^ lvl)
			end
		end
	end

	local equipped = getEquippedWisps(data)
	local wispSparkBonus, wispSunBonus = 1, 1
	for _, w in ipairs(equipped) do
		wispSparkBonus += (w.SparkMult - 1) * wispSynergy
		wispSunBonus += (w.SunMult - 1) * wispSynergy
	end
	sparkMult *= wispSparkBonus
	sunMult *= wispSunBonus

	if data.EternalStars > 0 then
		sparkMult *= (8 ^ data.EternalStars)
		sunMult *= (4 ^ data.EternalStars)
	end

	return {
		SparksPerSec = baseSparks * sparkMult,
		SunPerSec = sunSec * sunMult,
		ClickPower = math.max(1, (1 + baseSparks * 0.25) * clickMult),
		LightPercent = math.min(100, lightPercent),
		EquippedWisps = equipped,
	}
end

local function syncPlayer(player, extra)
	local data = PlayerData[player.UserId]
	if not data then return end
	local stats = calculateStats(data)

	local eqIds = {}
	for _, w in ipairs(stats.EquippedWisps) do
		table.insert(eqIds, w.Id)
	end
	player:SetAttribute("EquippedWisps", HttpService:JSONEncode(eqIds))

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Scintille.Value = GameConfig.Format(data.Sparks)
		ls.Luce.Value = tostring(stats.LightPercent) .. "%"
	end

	local wispCounts = {}
	for _, id in ipairs(data.Wisps) do
		wispCounts[id] = (wispCounts[id] or 0) + 1
	end

	local payload = {
		Sparks = data.Sparks,
		SunEssence = data.SunEssence,
		EternalStars = data.EternalStars,
		SparksPerSec = stats.SparksPerSec,
		SunPerSec = stats.SunPerSec,
		LightPercent = stats.LightPercent,
		Altars = data.Altars,
		Upgrades = data.Upgrades,
		WispCounts = wispCounts,
		EquippedCount = #stats.EquippedWisps,
	}
	if extra then
		for k, v in pairs(extra) do payload[k] = v end
	end
	StateSync:FireClient(player, payload)
end

-- Camminare sugli 8 Altari a terra
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
					if data.Sparks >= cost then
						data.Sparks -= cost
						data.Altars[alt.Id] = lvl + 1
						syncPlayer(plr, { SoundCue = "Buy" })
					end
				end
			end
		end
	end
end)

-- Cliccare la Fiamma Centrale
flameClick.MouseClick:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	local stats = calculateStats(data)
	data.Sparks += stats.ClickPower
	data.TotalSparks += stats.ClickPower
	syncPlayer(player, {
		SoundCue = "Click",
		FlamePulse = true,
		PopupText = "+" .. GameConfig.Format(stats.ClickPower) .. " Scintille",
	})
end)

-- Acquisto Potenziamenti della Luce
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
	if target.Currency == "Sparks" and data.Sparks >= cost then
		data.Sparks -= cost
		data.Upgrades[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = target.Zone and ("✨ ZONA ILLUMINATA: " .. target.Name) or nil })
	elseif target.Currency == "Sun" and data.SunEssence >= cost then
		data.SunEssence -= cost
		data.Upgrades[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = target.Zone and ("✨ ZONA ILLUMINATA: " .. target.Name) or nil })
	end
end)

-- Evocazione Spiriti di Luce (Lucciole)
SummonWisp.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	if data.SunEssence < GameConfig.WispCost then
		syncPlayer(player, { PopupText = "Servono " .. GameConfig.WispCost .. " Essenza Solare!" })
		return
	end
	data.SunEssence -= GameConfig.WispCost
	local roll, acc, chosen = math.random(1, 100), 0, GameConfig.Wisps[1]
	for _, w in ipairs(GameConfig.Wisps) do
		acc += w.Weight
		if roll <= acc then chosen = w; break end
	end
	table.insert(data.Wisps, chosen.Id)
	syncPlayer(player, { SoundCue = "Upgrade", PopupText = "✨ Evocato: " .. chosen.Name .. "!" })
end)

-- Prestige: Grande Alba
PrestigeEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data or data.Sparks < GameConfig.PrestigeCost then return end
	data.EternalStars += 1
	data.Sparks = 25
	data.SunEssence = 0
	data.Altars = {}
	data.Upgrades = {}
	syncPlayer(player, { SoundCue = "Prestige", PopupText = "🌅 GRANDE ALBA COMPIUTA! +1 Stella Eterna!" })
end)

-- Codici Promo
RedeemCode.OnServerInvoke = function(player, raw)
	local data = PlayerData[player.UserId]
	if not data or type(raw) ~= "string" then return false, "Errore" end
	local code = string.upper(string.gsub(raw, "%s+", ""))
	if data.UsedCodes[code] then return false, "Codice già usato!" end
	local rew = GameConfig.PromoCodes[code]
	if not rew then return false, "Codice non valido!" end
	data.UsedCodes[code] = true
	data.Sparks += rew.Sparks
	data.TotalSparks += rew.Sparks
	data.SunEssence += rew.Sun
	syncPlayer(player, { SoundCue = "Upgrade" })
	return true, rew.Msg
end

-- Scintille Vaganti nel buio
local function spawnWanderingEmber()
	local ember = makePart({
		Name = "WanderingEmber",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Position = Vector3.new(math.random(-55, 55), 2.5, math.random(-55, 55)),
		Color = Color3.fromRGB(255, 195, 70),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	local l = Instance.new("PointLight", ember)
	l.Color = Color3.fromRGB(255, 185, 60)
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
			local stats = calculateStats(data)
			local gain = math.max(15, stats.SparksPerSec * 12)
			data.Sparks += gain
			data.TotalSparks += gain
			syncPlayer(plr, { SoundCue = "Click", PopupText = "✨ Scintilla raccolta: +" .. GameConfig.Format(gain) })
			ember:Destroy()
		end
	end)
	task.delay(22, function()
		ActiveEmbers[ember] = nil
		if ember and ember.Parent then ember:Destroy() end
	end)
end

task.spawn(function()
	while true do
		task.wait(10)
		spawnWanderingEmber()
	end
end)

-- Loop Economia & Auto-Alimentazione
local autoTimer = 0
task.spawn(function()
	while true do
		task.wait(0.1)
		autoTimer += 0.1
		local runAuto = autoTimer >= 1.0
		if runAuto then autoTimer = 0 end

		for _, plr in ipairs(Players:GetPlayers()) do
			local data = PlayerData[plr.UserId]
			if data then
				local stats = calculateStats(data)
				data.Sparks += stats.SparksPerSec * 0.1
				data.TotalSparks += stats.SparksPerSec * 0.1
				data.SunEssence += stats.SunPerSec * 0.1

				if getLvl(data.Upgrades, "u_ember") > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local pPos = plr.Character.HumanoidRootPart.Position
					for emb in pairs(ActiveEmbers) do
						if emb and emb.Parent and (pPos - emb.Position).Magnitude < 35 then
							emb.Position += (pPos - emb.Position).Unit * 2.2
						end
					end
				end

				if runAuto then
					if getLvl(data.Upgrades, "u_auto1") > 0 then
						for i = 1, 4 do
							local id = GameConfig.Altars[i].Id
							data.Altars[id] = getLvl(data.Altars, id) + 1
						end
					end
					if getLvl(data.Upgrades, "u_auto2") > 0 then
						for i = 5, 8 do
							local id = GameConfig.Altars[i].Id
							data.Altars[id] = getLvl(data.Altars, id) + 1
						end
					end
				end

				syncPlayer(plr)
			end
		end
	end
end)

-- Join / Salvataggio
local function savePlayer(player, removeCache)
	local data = PlayerData[player.UserId]
	if data and mainStore then
		pcall(function() mainStore:SetAsync("Plr_" .. player.UserId, data) end)
	end
	if removeCache then
		PlayerData[player.UserId] = nil
	end
end

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder", player); ls.Name = "leaderstats"
	local s = Instance.new("StringValue", ls); s.Name = "Scintille"; s.Value = "0"
	local l = Instance.new("StringValue", ls); l.Name = "Luce"; l.Value = "4%"

	local data = defaultData()
	if mainStore then
		local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do data[k] = v end
		end
	end
	PlayerData[player.UserId] = data
	task.wait(1)
	syncPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player) savePlayer(player, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)
