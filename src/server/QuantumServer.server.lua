local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

---------------------------------------------------------------------
-- PARTE 1: GENERAZIONE PROCEDURALE DELLA CITTADELLA QUANTICA (240x240)
---------------------------------------------------------------------
Lighting.Brightness = 2.0
Lighting.Ambient = Color3.fromRGB(28, 36, 58)
Lighting.OutdoorAmbient = Color3.fromRGB(40, 52, 82)
Lighting.ClockTime = 21.5

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

local function makeWorldLabel(parent, titleTxt, subTxt, color, offset, sizeOffset)
	local bb = Instance.new("BillboardGui")
	bb.Name = "InfoGui"
	bb.Size = sizeOffset or UDim2.fromOffset(230, 82)
	bb.StudsOffset = offset or Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = false
	bb.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	bg.BackgroundTransparency = 0.16
	bg.Parent = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke", bg)
	st.Color = color
	st.Thickness = 2

	local t1 = Instance.new("TextLabel")
	t1.Name = "TitleLabel"
	t1.Size = UDim2.new(1, -10, 0.50, 0)
	t1.Position = UDim2.fromOffset(5, 3)
	t1.BackgroundTransparency = 1
	t1.Text = titleTxt
	t1.TextColor3 = color
	t1.Font = Enum.Font.GothamBlack
	t1.TextScaled = true
	t1.Parent = bg

	local t2 = Instance.new("TextLabel")
	t2.Name = "SubLabel"
	t2.Size = UDim2.new(1, -10, 0.44, 0)
	t2.Position = UDim2.new(0, 5, 0.53, 0)
	t2.BackgroundTransparency = 1
	t2.Text = subTxt
	t2.TextColor3 = Color3.fromRGB(235, 242, 255)
	t2.Font = Enum.Font.GothamBold
	t2.TextScaled = true
	t2.Parent = bg

	return bb, t1, t2
end

-- Piattaforma principale 240x240
makePart({ Name = "MainPlatform", Size = Vector3.new(240, 2, 240), Position = Vector3.new(0, 0, 0), Color = Color3.fromRGB(15, 18, 28), Material = Enum.Material.SmoothPlastic, Parent = world })
makePart({ Name = "SubDeck", Size = Vector3.new(210, 5, 210), Position = Vector3.new(0, -3.5, 0), Color = Color3.fromRGB(22, 26, 40), Material = Enum.Material.Metal, Parent = world })

-- Bordi Neon
local borders = {
	{ Vector3.new(242, 2.5, 2), Vector3.new(0, 0.25, 120.5) },
	{ Vector3.new(242, 2.5, 2), Vector3.new(0, 0.25, -120.5) },
	{ Vector3.new(2, 2.5, 242), Vector3.new(120.5, 0.25, 0) },
	{ Vector3.new(2, 2.5, 242), Vector3.new(-120.5, 0.25, 0) },
}
for _, b in ipairs(borders) do
	makePart({ Name = "NeonBorder", Size = b[1], Position = b[2], Color = Color3.fromRGB(0, 220, 255), Material = Enum.Material.Neon, Parent = world })
end

-- Griglia pavimento
for i = -100, 100, 25 do
	makePart({ Name = "GridX", Size = Vector3.new(230, 0.05, 0.22), Position = Vector3.new(0, 1.02, i), Color = Color3.fromRGB(22, 52, 82), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
	makePart({ Name = "GridZ", Size = Vector3.new(0.22, 0.05, 230), Position = Vector3.new(i, 1.02, 0), Color = Color3.fromRGB(22, 52, 82), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
end

-- 4 Piloni Energetici agli angoli
local cornerCoords = { Vector3.new(-110, 1, -110), Vector3.new(110, 1, -110), Vector3.new(-110, 1, 110), Vector3.new(110, 1, 110) }
for i, pos in ipairs(cornerCoords) do
	makePart({ Name = "PylonBase_" .. i, Size = Vector3.new(12, 3, 12), Position = pos + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(26, 30, 46), Material = Enum.Material.Metal, Parent = world })
	makePart({ Name = "PylonShaft_" .. i, Size = Vector3.new(5, 34, 5), Position = pos + Vector3.new(0, 20, 0), Color = Color3.fromRGB(18, 22, 34), Material = Enum.Material.SmoothPlastic, Parent = world })
	makePart({ Name = "PylonCrystal_" .. i, Size = Vector3.new(5, 5, 5), Position = pos + Vector3.new(0, 42, 0), Color = Color3.fromRGB(0, 235, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
end

-- Piazza di Spawn (Sud)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "QuantumSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(14, 0.5, 14)
spawn.CFrame = CFrame.lookAt(Vector3.new(0, 1.25, 96), Vector3.new(0, 1.25, 0))
spawn.Color = Color3.fromRGB(0, 195, 255)
spawn.Material = Enum.Material.Neon
spawn.Transparency = 0.5
spawn.Parent = world

-- Sentieri Luminosi di orientamento (Zero confusione!)
makePart({ Name = "ConduitNorth", Size = Vector3.new(2.6, 0.08, 130), Position = Vector3.new(0, 1.04, 26), Color = Color3.fromRGB(0, 215, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
makePart({ Name = "ConduitEast", Size = Vector3.new(75, 0.08, 2.2), Position = Vector3.new(38, 1.04, 44), Color = Color3.fromRGB(190, 70, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = world })
makePart({ Name = "ConduitWest", Size = Vector3.new(75, 0.08, 2.2), Position = Vector3.new(-38, 1.04, 44), Color = Color3.fromRGB(0, 255, 165), Material = Enum.Material.Neon, CanCollide = false, Parent = world })

-- Batteria Cooperativa del Server (Piazza Sud, Z = 72)
local batteryPad = makePart({ Name = "ServerBatteryPad", Size = Vector3.new(12, 1.4, 12), Position = Vector3.new(0, 1.5, 72), Color = Color3.fromRGB(255, 190, 0), Material = Enum.Material.Neon, Parent = world })
local batteryColumn = makePart({ Name = "ServerBatteryCore", Size = Vector3.new(4, 10, 4), Position = Vector3.new(0, 7, 72), Color = Color3.fromRGB(255, 220, 60), Material = Enum.Material.ForceField, CanCollide = false, Parent = world })
local batteryClick = Instance.new("ClickDetector")
batteryClick.Name = "DonateClick"
batteryClick.MaxActivationDistance = 35
batteryClick.Parent = batteryPad
local _, _, batterySubLbl = makeWorldLabel(batteryPad, "⚡ BATTERIA DEL SERVER (x2)", "0 / 500 Plasma (Clicca: dona 25)", Color3.fromRGB(255, 210, 40), Vector3.new(0, 11.5, 0), UDim2.fromOffset(270, 85))

-- Quantum Core Centrale (Z = 44) + Bersaglio Critico Orbitante
local coreCenter = Vector3.new(0, 10, 44)
local coreModel = Instance.new("Model")
coreModel.Name = "QuantumCoreAssembly"
coreModel.Parent = world

makePart({ Name = "CorePedestal", Size = Vector3.new(16, 1.2, 16), Position = Vector3.new(0, 1.6, 44), Color = Color3.fromRGB(24, 28, 44), Material = Enum.Material.Metal, Parent = coreModel })
local corePart = makePart({ Name = "CorePart", Shape = Enum.PartType.Ball, Size = Vector3.new(6.2, 6.2, 6.2), Position = coreCenter, Color = Color3.fromRGB(0, 230, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = coreModel })
local ring1 = makePart({ Name = "Ring1", Size = Vector3.new(11, 0.35, 11), Position = coreCenter, Color = Color3.fromRGB(190, 245, 255), Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = coreModel })
local ring2 = makePart({ Name = "Ring2", Size = Vector3.new(13.5, 0.3, 13.5), Position = coreCenter, Color = Color3.fromRGB(0, 170, 255), Material = Enum.Material.Neon, Transparency = 0.45, CanCollide = false, Parent = coreModel })

local coreClick = Instance.new("ClickDetector")
coreClick.Name = "CoreClick"
coreClick.MaxActivationDistance = 55
coreClick.Parent = corePart
makeWorldLabel(corePart, "⚡ QUANTUM CORE ⚡", "Clicca per generare energia", Color3.fromRGB(0, 235, 255), Vector3.new(0, 7.0, 0), UDim2.fromOffset(250, 75))

-- Punto Critico Orbitante attorno al Nucleo
local critOrb = makePart({ Name = "CritOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(3.2, 3.2, 3.2), Position = coreCenter + Vector3.new(9, 0, 0), Color = Color3.fromRGB(255, 50, 120), Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, Parent = coreModel })
local critClick = Instance.new("ClickDetector")
critClick.Name = "CritClick"
critClick.MaxActivationDistance = 55
critClick.Parent = critOrb

-- I 12 Pulsanti a Terra (Viale Centrale)
local buttonsFolder = Instance.new("Folder")
buttonsFolder.Name = "FloorButtons"
buttonsFolder.Parent = world

for _, cfg in ipairs(GameConfig.Buttons) do
	makePart({ Name = cfg.Id .. "_Base", Size = Vector3.new(11.5, 0.6, 11.5), Position = cfg.Pos - Vector3.new(0, 0.2, 0), Color = Color3.fromRGB(26, 30, 44), Material = Enum.Material.Metal, Parent = buttonsFolder })
	local pad = makePart({ Name = cfg.Id, Size = Vector3.new(9.5, 1.0, 9.5), Position = cfg.Pos, Color = cfg.Color, Material = Enum.Material.Neon, Parent = buttonsFolder })
	makeWorldLabel(pad, cfg.Name, "Lv. 0 | " .. GameConfig.Format(cfg.BaseCost) .. " W", cfg.Color, Vector3.new(0, 4.0, 0), UDim2.fromOffset(215, 78))
end

-- Muro Gigante Upgrade Tree (Nord, Z = -66)
local upgradeWall = makePart({ Name = "UpgradeWall", Size = Vector3.new(100, 50, 2.5), CFrame = CFrame.lookAt(Vector3.new(0, 27, -66), Vector3.new(0, 27, 50)), Color = Color3.fromRGB(13, 16, 26), Material = Enum.Material.SmoothPlastic, Parent = world })
makePart({ Name = "UpgradeWallFrame", Size = Vector3.new(103, 53, 1.8), CFrame = CFrame.lookAt(Vector3.new(0, 27, -66.6), Vector3.new(0, 27, 50)), Color = Color3.fromRGB(0, 215, 255), Material = Enum.Material.Neon, Parent = world })

-- Ala Est: Fabbrica Droni (X = 76, Z = 44) & Santuario Materia Oscura (X = 82, Z = -18)
local droneStation = makePart({ Name = "DroneStation", Size = Vector3.new(16, 1.5, 16), Position = Vector3.new(76, 1.5, 44), Color = Color3.fromRGB(185, 55, 255), Material = Enum.Material.Neon, Parent = world })
local droneHolo = makePart({ Name = "DroneHolo", Size = Vector3.new(4.2, 4.2, 4.2), Position = Vector3.new(76, 7.2, 44), Color = Color3.fromRGB(230, 130, 255), Material = Enum.Material.ForceField, CanCollide = false, Parent = world })
local droneClick = Instance.new("ClickDetector")
droneClick.Name = "HatchClick"
droneClick.MaxActivationDistance = 35
droneClick.Parent = droneStation
local _, _, droneStationSub = makeWorldLabel(droneStation, "🛸 FABBRICA & FORGIA DRONI", "Clicca: crea (50 Plasma)", Color3.fromRGB(220, 120, 255), Vector3.new(0, 9.0, 0), UDim2.fromOffset(250, 80))

local prestigeWall = makePart({ Name = "PrestigeWall", Size = Vector3.new(38, 36, 2), CFrame = CFrame.lookAt(Vector3.new(82, 20, -18), Vector3.new(0, 20, 20)), Color = Color3.fromRGB(22, 12, 32), Material = Enum.Material.SmoothPlastic, Parent = world })
makePart({ Name = "PrestigeWallFrame", Size = Vector3.new(40.5, 38.5, 1.5), CFrame = CFrame.lookAt(Vector3.new(82.6, 20, -18.3), Vector3.new(0, 20, 20)), Color = Color3.fromRGB(255, 45, 115), Material = Enum.Material.Neon, Parent = world })

-- Ala Ovest: Camera AFK (X = -76, Z = 44), Portale Sfide (X = -82, Z = 6) & Classifica (X = -82, Z = -32)
local afkPos = Vector3.new(-76, 1.5, 44)
local afkPad = makePart({ Name = "AfkZonePad", Size = Vector3.new(18, 1.2, 18), Position = afkPos, Color = Color3.fromRGB(0, 255, 165), Material = Enum.Material.Neon, Parent = world })
makePart({ Name = "AfkRingTop", Size = Vector3.new(20, 0.6, 20), Position = afkPos + Vector3.new(0, 12, 0), Color = Color3.fromRGB(0, 255, 165), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = world })
makeWorldLabel(afkPad, "⏳ CAMERA TEMPORALE AFK", "Resta dentro per Frammenti", Color3.fromRGB(0, 255, 165), Vector3.new(0, 7.0, 0), UDim2.fromOffset(250, 80))

local challengePad = makePart({ Name = "ChallengePortal", Size = Vector3.new(14, 1.4, 14), Position = Vector3.new(-82, 1.5, 6), Color = Color3.fromRGB(255, 140, 20), Material = Enum.Material.Neon, Parent = world })
makePart({ Name = "ChallengeArch", Size = Vector3.new(2, 16, 14), Position = Vector3.new(-88, 9, 6), Color = Color3.fromRGB(255, 170, 40), Material = Enum.Material.ForceField, CanCollide = false, Parent = world })
makeWorldLabel(challengePad, "🔥 PORTALE SFIDE QUANTICHE", "Apri menu Sfide per boost permanenti", Color3.fromRGB(255, 165, 35), Vector3.new(0, 7.5, 0), UDim2.fromOffset(260, 80))

local lbWall = makePart({ Name = "LeaderboardWall", Size = Vector3.new(32, 36, 2), CFrame = CFrame.lookAt(Vector3.new(-82, 20, -32), Vector3.new(0, 20, 20)), Color = Color3.fromRGB(15, 20, 32), Material = Enum.Material.SmoothPlastic, Parent = world })
makePart({ Name = "LeaderboardFrame", Size = Vector3.new(34.5, 38.5, 1.5), CFrame = CFrame.lookAt(Vector3.new(-82.6, 20, -32.3), Vector3.new(0, 20, 20)), Color = Color3.fromRGB(0, 185, 255), Material = Enum.Material.Neon, Parent = world })

local lbGui = Instance.new("SurfaceGui")
lbGui.Name = "LeaderboardGui"
lbGui.Face = Enum.NormalId.Front
lbGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
lbGui.PixelsPerStud = 20
lbGui.Parent = lbWall

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, 0, 0.14, 0)
lbTitle.BackgroundColor3 = Color3.fromRGB(0, 145, 215)
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
Instance.new("UIListLayout", lbList).Padding = UDim.new(0, 6)

---------------------------------------------------------------------
-- PARTE 2: MOTORE ECONOMICO, SFIDE, FORGIA, BATTERIA SERVER & DATASTORE
---------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(cls, name)
	local r = Instance.new(cls)
	r.Name = name
	r.Parent = remotes
	return r
end

local StateSync = makeRemote("RemoteEvent", "StateSync")
local BuyUpgrade = makeRemote("RemoteEvent", "BuyUpgrade")
local BuyDarkUpgrade = makeRemote("RemoteEvent", "BuyDarkUpgrade")
local BuyAfkUpgrade = makeRemote("RemoteEvent", "BuyAfkUpgrade")
local PrestigeEvent = makeRemote("RemoteEvent", "Prestige")
local CraftDroneEvent = makeRemote("RemoteEvent", "CraftDrone")
local FuseDroneEvent = makeRemote("RemoteEvent", "FuseDrone")
local StartChallengeEvent = makeRemote("RemoteEvent", "StartChallenge")
local AbandonChallengeEvent = makeRemote("RemoteEvent", "AbandonChallenge")
local DonateBatteryEvent = makeRemote("RemoteEvent", "DonateBattery")
local RedeemCode = makeRemote("RemoteFunction", "RedeemCode")
local ClaimDaily = makeRemote("RemoteFunction", "ClaimDaily")

local mainStore, orderedStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("QuantumCitadel_V2")
	orderedStore = DataStoreService:GetOrderedDataStore("QuantumCitadel_Top_V2")
end)

local PlayerData = {}
local ChallengeSessions = {}
local ActiveOrbs = {}
local CritOrbActive = false

local ServerBattery = {
	Current = 0,
	Max = GameConfig.ServerBatteryMax,
	BoostUntil = 0,
}

local ActiveEvents = {
	CoreOverloadUntil = 0,
	CrystalRainUntil = 0,
}

local function defaultData()
	return {
		Watt = 15,
		TotalWatt = 15,
		Plasma = 0,
		TimeFragments = 0,
		TotalFragments = 0,
		DarkMatter = 0,
		DarkMatterEarned = 0,
		TotalClicks = 0,
		CritHits = 0,
		DronesCrafted = 0,
		FusionsDone = 0,
		Buttons = {},
		Upgrades = {},
		DarkUpgrades = {},
		AfkUpgrades = {},
		Drones = {}, -- lista di ID es. "d_base" o "d_base_ov" (Sovraccarico)
		CompletedChallenges = {},
		Achievements = {},
		UsedCodes = {},
		LastDaily = 0,
		LastLogout = os.time(),
	}
end

local function getLvl(tbl, id)
	return (tbl and tbl[id]) or 0
end

local function getRank(totalWatt)
	local rank = GameConfig.Ranks[1]
	for _, r in ipairs(GameConfig.Ranks) do
		if totalWatt >= r.MinWatt then
			rank = r
		end
	end
	return rank
end

local function getMaxDroneSlots(data)
	return GameConfig.BaseEquippedDrones + getLvl(data.Upgrades, "u16")
end

local function getDroneCost(data)
	return getLvl(data.DarkUpgrades, "dm2") > 0 and 25 or GameConfig.BaseDroneCost
end

local function parseDroneId(rawId)
	local isOvercharged = string.sub(rawId, -3) == "_ov"
	local baseId = isOvercharged and string.sub(rawId, 1, -4) or rawId
	for _, cfg in ipairs(GameConfig.Drones) do
		if cfg.Id == baseId then
			return cfg, isOvercharged
		end
	end
	return nil, false
end

local function getEquippedDrones(data, chSession)
	if chSession and chSession.Id == "ch2" then
		return {}
	end
	local list = {}
	for _, rawId in ipairs(data.Drones) do
		local cfg, ov = parseDroneId(rawId)
		if cfg then
			local mult = ov and 2.5 or 1.0
			table.insert(list, {
				RawId = rawId,
				Id = cfg.Id,
				Overcharged = ov,
				WattMult = cfg.WattMult * mult,
				PlasmaMult = cfg.PlasmaMult * mult,
			})
		end
	end
	table.sort(list, function(a, b) return a.WattMult > b.WattMult end)
	local eq = {}
	for i = 1, math.min(getMaxDroneSlots(data), #list) do
		table.insert(eq, list[i])
	end
	return eq
end

local function getTotalButtonLevels(buttons)
	local s = 0
	for _, v in pairs(buttons) do s += v end
	return s
end

local function calculateStats(data, chSession)
	local activeButtons = chSession and chSession.Buttons or data.Buttons
	local activeUpgrades = (chSession and chSession.Id == "ch2") and {} or data.Upgrades

	local baseWattSec = 0
	local wattMult = 1
	local plasmaSec = 0
	local plasmaMult = 1
	local clickMult = 1
	local critMult = 25
	local costDiscount = 0
	local droneSynergy = 1
	local orbBonus = 1

	for _, btn in ipairs(GameConfig.Buttons) do
		local lvl = getLvl(activeButtons, btn.Id)
		if lvl > 0 then
			if btn.Type == "AddWatt" then
				baseWattSec += btn.Value * lvl
			elseif btn.Type == "MultWatt" then
				wattMult *= (btn.Value ^ lvl)
			end
		end
	end

	for _, upg in ipairs(GameConfig.Upgrades) do
		local lvl = getLvl(activeUpgrades, upg.Id)
		if lvl > 0 then
			if upg.Effect == "WattMult" then wattMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "PlasmaMult" then plasmaMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "ClickMult" then clickMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "CritMult" then critMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "CostDiscount" then costDiscount = math.min(0.75, costDiscount + upg.Value * lvl)
			elseif upg.Effect == "UnlockPlasma" then plasmaSec += 1
			elseif upg.Effect == "DroneSynergy" then droneSynergy += upg.Value * lvl
			elseif upg.Effect == "OrbBonus" then orbBonus += upg.Value * lvl
			end
		end
	end

	-- Droni equipaggiati
	local equipped = getEquippedDrones(data, chSession)
	local achDroneBonus = data.Achievements["ach_fuse1"] and 1.5 or 1.0
	local droneWattBonus = 1
	local dronePlasmaBonus = 1
	for _, d in ipairs(equipped) do
		droneWattBonus += (d.WattMult - 1) * droneSynergy * achDroneBonus
		dronePlasmaBonus += (d.PlasmaMult - 1) * droneSynergy * achDroneBonus
	end
	wattMult *= droneWattBonus
	plasmaMult *= dronePlasmaBonus

	-- Bonus AFK Frammenti Temporali
	local afkWattLvl = getLvl(data.AfkUpgrades, "afk_watt")
	if afkWattLvl > 0 then
		local b = 1 + (0.35 * afkWattLvl)
		wattMult *= b
		plasmaMult *= b
	end

	-- Bonus Sfide Completate
	if data.CompletedChallenges["ch1"] then clickMult *= 4.0 end
	if data.CompletedChallenges["ch2"] then wattMult *= 2.5 end
	if data.CompletedChallenges["ch3"] then plasmaMult *= 3.0; wattMult *= 2.0 end

	-- Bonus Obiettivi
	for _, ach in ipairs(GameConfig.Achievements) do
		if data.Achievements[ach.Id] then
			if ach.MultType == "Watt" then wattMult *= ach.MultVal
			elseif ach.MultType == "Plasma" then plasmaMult *= ach.MultVal
			elseif ach.MultType == "Click" then clickMult *= ach.MultVal
			elseif ach.MultType == "Crit" then critMult *= ach.MultVal
			elseif ach.MultType == "All" then
				wattMult *= ach.MultVal
				plasmaMult *= ach.MultVal
				clickMult *= ach.MultVal
			end
		end
	end

	-- Materia Oscura
	if data.DarkMatterEarned > 0 then
		wattMult *= (5 ^ data.DarkMatterEarned)
		plasmaMult *= (3 ^ data.DarkMatterEarned)
	end
	local hyperLvl = getLvl(data.DarkUpgrades, "dm4")
	if hyperLvl > 0 then
		wattMult *= (25 ^ hyperLvl)
		plasmaMult *= (25 ^ hyperLvl)
	end

	-- Modificatori Sfida Attiva
	if chSession then
		if chSession.Id == "ch1" then
			clickMult *= 50
		elseif chSession.Id == "ch3" then
			wattMult *= 5
		end
	end

	-- Eventi & Batteria Server
	local now = os.time()
	if data.OrbBoostUntil and now < data.OrbBoostUntil then wattMult *= 2 end
	if now < ActiveEvents.CoreOverloadUntil then wattMult *= 5; clickMult *= 5 end
	if now < ServerBattery.BoostUntil then wattMult *= 2; plasmaMult *= 2; clickMult *= 2 end

	return {
		WattPerSec = baseWattSec * wattMult,
		PlasmaPerSec = plasmaSec * plasmaMult,
		ClickPower = math.max(1, (1 + baseWattSec * 0.25) * clickMult),
		CritMult = critMult,
		CostDiscount = costDiscount,
		DroneWattBonus = droneWattBonus,
		OrbBonus = orbBonus,
		EquippedDrones = equipped,
		MaxDroneSlots = getMaxDroneSlots(data),
		DroneCost = getDroneCost(data),
	}
end

local function applyAvatarStats(player, data)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.UseJumpPower = true
		hum.WalkSpeed = 16 + getLvl(data.AfkUpgrades, "afk_speed") * 4
		hum.JumpPower = 50 + getLvl(data.AfkUpgrades, "afk_jump") * 12
	end
end

local function checkAchievements(data)
	local unlockedNew = nil
	local statsMap = {
		TotalClicks = data.TotalClicks or 0,
		CritHits = data.CritHits or 0,
		TotalWatt = data.TotalWatt or 0,
		TotalButtonLevels = getTotalButtonLevels(data.Buttons),
		DronesCrafted = data.DronesCrafted or 0,
		FusionsDone = data.FusionsDone or 0,
		TotalFragments = data.TotalFragments or 0,
		DarkMatterEarned = data.DarkMatterEarned or 0,
	}
	for _, ach in ipairs(GameConfig.Achievements) do
		if not data.Achievements[ach.Id] and (statsMap[ach.Stat] or 0) >= ach.Target then
			data.Achievements[ach.Id] = true
			unlockedNew = ach.Name .. " (" .. ach.BonusText .. ")"
		end
	end
	return unlockedNew
end

local function syncPlayer(player, extra)
	local data = PlayerData[player.UserId]
	if not data then return end
	local ch = ChallengeSessions[player.UserId]
	local newAch = checkAchievements(data)
	local stats = calculateStats(data, ch)
	local rank = getRank(data.TotalWatt)

	player:SetAttribute("RankName", rank.Name)
	player:SetAttribute("RankColor", rank.Color)
	player:SetAttribute("WattPerSec", GameConfig.Format(stats.WattPerSec))
	player:SetAttribute("DarkMatter", data.DarkMatterEarned)

	local eqIds = {}
	for _, d in ipairs(stats.EquippedDrones) do
		table.insert(eqIds, d.RawId)
	end
	player:SetAttribute("EquippedDrones", HttpService:JSONEncode(eqIds))

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Watt.Value = GameConfig.Format(ch and ch.Watt or data.Watt)
		ls.Plasma.Value = GameConfig.Format(data.Plasma)
	end

	local droneCounts = {}
	for _, rawId in ipairs(data.Drones) do
		droneCounts[rawId] = (droneCounts[rawId] or 0) + 1
	end

	local now = os.time()
	local payload = {
		Watt = ch and ch.Watt or data.Watt,
		TotalWatt = data.TotalWatt,
		Plasma = data.Plasma,
		TimeFragments = data.TimeFragments,
		DarkMatter = data.DarkMatter,
		WattPerSec = stats.WattPerSec,
		PlasmaPerSec = stats.PlasmaPerSec,
		CostDiscount = stats.CostDiscount,
		DroneWattBonus = stats.DroneWattBonus,
		EquippedCount = #stats.EquippedDrones,
		MaxDroneSlots = stats.MaxDroneSlots,
		DroneCost = stats.DroneCost,
		DroneCounts = droneCounts,
		Buttons = ch and ch.Buttons or data.Buttons,
		Upgrades = data.Upgrades,
		DarkUpgrades = data.DarkUpgrades,
		AfkUpgrades = data.AfkUpgrades,
		CompletedChallenges = data.CompletedChallenges,
		Achievements = data.Achievements,
		RankName = rank.Name,
		RankColor = { rank.Color.R, rank.Color.G, rank.Color.B },
		ActiveChallenge = ch and {
			Id = ch.Id,
			Name = ch.Name,
			GoalWatt = ch.GoalWatt,
			TimeLeft = math.max(0, ch.EndsAt - now),
			CostMult = ch.CostMult,
		} or nil,
		ServerBoostLeft = math.max(0, ServerBattery.BoostUntil - now),
		ServerBatteryPct = math.floor((ServerBattery.Current / ServerBattery.Max) * 100),
		CoreOverloadLeft = math.max(0, ActiveEvents.CoreOverloadUntil - now),
		CrystalRainLeft = math.max(0, ActiveEvents.CrystalRainUntil - now),
		OrbBoostLeft = math.max(0, (data.OrbBoostUntil or 0) - now),
		CritOrbActive = CritOrbActive,
	}
	if newAch then payload.AchievementUnlocked = newAch end
	if extra then
		for k, v in pairs(extra) do payload[k] = v end
	end
	StateSync:FireClient(player, payload)
end

-- Batteria Cooperativa del Server
local function updateBatteryVisual()
	local now = os.time()
	if now < ServerBattery.BoostUntil then
		batterySubLbl.Text = "🔥 BOOST x2 ATTIVO (" .. GameConfig.FormatTime(ServerBattery.BoostUntil - now) .. ")"
		batteryColumn.Color = Color3.fromRGB(0, 255, 160)
	else
		batterySubLbl.Text = string.format("%d / %d Plasma (Clicca: dona %d)", ServerBattery.Current, ServerBattery.Max, GameConfig.ServerDonationStep)
		batteryColumn.Color = Color3.fromRGB(255, 220, 60)
	end
end

local function donateToBattery(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	if os.time() < ServerBattery.BoostUntil then
		syncPlayer(player, { PopupText = "⚡ Il Boost del Server è già attivo!" })
		return
	end
	local step = GameConfig.ServerDonationStep
	if data.Plasma < step then
		syncPlayer(player, { PopupText = "Servono almeno " .. step .. " Plasma!" })
		return
	end
	data.Plasma -= step
	ServerBattery.Current += step
	if ServerBattery.Current >= ServerBattery.Max then
		ServerBattery.Current = 0
		ServerBattery.BoostUntil = os.time() + 300
		for _, p in ipairs(Players:GetPlayers()) do
			syncPlayer(p, { SoundCue = "Prestige", PopupText = "🌟 BATTERIA CARICA! BOOST x2 PER TUTTO IL SERVER (5 MIN)!" })
		end
	else
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = "⚡ Donati " .. step .. " Plasma alla Batteria del Server!" })
	end
	updateBatteryVisual()
end

batteryClick.MouseClick:Connect(donateToBattery)
DonateBatteryEvent.OnServerEvent:Connect(donateToBattery)

-- Acquisto Pulsanti a Terra (funziona sia in partita normale che in Sfida)
local function getButtonCost(btnCfg, level, discount, chSession)
	local chMult = chSession and chSession.CostMult or 1
	local raw = btnCfg.BaseCost * (btnCfg.CostMult ^ level) * chMult
	return math.max(1, math.floor(raw * (1 - discount)))
end

local TouchingMap = {}
for _, btnCfg in ipairs(GameConfig.Buttons) do
	local pad = floorButtons:FindFirstChild(btnCfg.Id)
	if pad then
		TouchingMap[btnCfg.Id] = {}
		pad.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then TouchingMap[btnCfg.Id][plr.UserId] = plr end
		end)
		pad.TouchEnded:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then TouchingMap[btnCfg.Id][plr.UserId] = nil end
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(0.12)
		for _, btnCfg in ipairs(GameConfig.Buttons) do
			for _, plr in pairs(TouchingMap[btnCfg.Id]) do
				local data = plr and plr.Parent and PlayerData[plr.UserId]
				if data then
					local ch = ChallengeSessions[plr.UserId]
					local stats = calculateStats(data, ch)
					local targetBtns = ch and ch.Buttons or data.Buttons
					local lvl = getLvl(targetBtns, btnCfg.Id)
					local cost = getButtonCost(btnCfg, lvl, stats.CostDiscount, ch)
					local wallet = ch and ch.Watt or data.Watt
					if wallet >= cost then
						if ch then
							ch.Watt -= cost
							ch.Buttons[btnCfg.Id] = lvl + 1
						else
							data.Watt -= cost
							data.Buttons[btnCfg.Id] = lvl + 1
						end
						syncPlayer(plr, { SoundCue = "Buy" })
					end
				end
			end
		end
	end
end)

-- Clicker Nucleo + Punto Critico Orbitante
local ClickCombos = {}
coreClick.MouseClick:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	local ch = ChallengeSessions[player.UserId]
	local stats = calculateStats(data, ch)

	local now = os.clock()
	local combo = ClickCombos[player.UserId] or { Count = 0, Last = 0 }
	combo.Count = (now - combo.Last <= 2.5) and (combo.Count + 1) or 1
	combo.Last = now
	ClickCombos[player.UserId] = combo

	local comboMult = math.min(6.0, 1 + (combo.Count - 1) * 0.15)
	local gain = stats.ClickPower * comboMult

	if ch then
		ch.Watt += gain
	else
		data.Watt += gain
		data.TotalWatt += gain
	end
	data.TotalClicks = (data.TotalClicks or 0) + 1

	syncPlayer(player, {
		SoundCue = "Click",
		CorePulse = true,
		PopupText = "+" .. GameConfig.Format(gain) .. " W (x" .. string.format("%.1f", comboMult) .. ")",
	})
end)

critClick.MouseClick:Connect(function(player)
	if not CritOrbActive then return end
	CritOrbActive = false
	critOrb.Transparency = 1

	local data = PlayerData[player.UserId]
	if not data then return end
	local ch = ChallengeSessions[player.UserId]
	local stats = calculateStats(data, ch)

	local gain = stats.ClickPower * stats.CritMult
	if ch then
		ch.Watt += gain
	else
		data.Watt += gain
		data.TotalWatt += gain
	end
	data.Plasma += 3
	data.CritHits = (data.CritHits or 0) + 1

	syncPlayer(player, {
		SoundCue = "Prestige",
		CorePulse = true,
		PopupText = "💥 SCARICA CRITICA! +" .. GameConfig.Format(gain) .. " W e +3 Plasma!",
	})
end)

-- Spawner Punto Critico ogni 11 secondi
task.spawn(function()
	while true do
		task.wait(11)
		CritOrbActive = true
		critOrb.Transparency = 0
		task.delay(5.5, function()
			CritOrbActive = false
			critOrb.Transparency = 1
		end)
	end
end)

-- Upgrade Tree, Dark Upgrades e AFK Upgrades
BuyUpgrade.OnServerEvent:Connect(function(player, upgId)
	local data = PlayerData[player.UserId]
	if not data or ChallengeSessions[player.UserId] then return end
	local target
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Id == upgId then target = u; break end
	end
	if not target then return end
	if target.Prereq and getLvl(data.Upgrades, target.Prereq) <= 0 then return end
	local cur = getLvl(data.Upgrades, target.Id)
	if cur >= target.MaxLevel then return end

	local cost = math.floor(target.Cost * (target.CostMult ^ cur))
	if target.Currency == "Watt" and data.Watt >= cost then
		data.Watt -= cost
		data.Upgrades[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Upgrade" })
	elseif target.Currency == "Plasma" and data.Plasma >= cost then
		data.Plasma -= cost
		data.Upgrades[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Upgrade" })
	end
end)

BuyDarkUpgrade.OnServerEvent:Connect(function(player, dmId)
	local data = PlayerData[player.UserId]
	if not data then return end
	local target
	for _, d in ipairs(GameConfig.DarkUpgrades) do
		if d.Id == dmId then target = d; break end
	end
	if not target then return end
	local cur = getLvl(data.DarkUpgrades, target.Id)
	if cur >= target.MaxLevel then return end
	local cost = math.floor(target.Cost * (target.CostMult ^ cur))
	if data.DarkMatter >= cost then
		data.DarkMatter -= cost
		data.DarkUpgrades[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = "🌌 Potenziamento Oscuro sbloccato!" })
	end
end)

BuyAfkUpgrade.OnServerEvent:Connect(function(player, afkId)
	local data = PlayerData[player.UserId]
	if not data then return end
	local target
	for _, a in ipairs(GameConfig.AfkUpgrades) do
		if a.Id == afkId then target = a; break end
	end
	if not target then return end
	local cur = getLvl(data.AfkUpgrades, target.Id)
	if cur >= target.MaxLevel then return end
	local cost = math.floor(target.BaseCost * (target.CostMult ^ cur))
	if data.TimeFragments >= cost then
		data.TimeFragments -= cost
		data.AfkUpgrades[target.Id] = cur + 1
		applyAvatarStats(player, data)
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = "⏳ Potenziamento Temporale applicato!" })
	end
end)

-- Collasso Quantistico (Prestige)
PrestigeEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data or ChallengeSessions[player.UserId] or data.Watt < GameConfig.PrestigeCost then return end

	local gained = math.max(1, math.floor(math.log10(data.Watt / 1e11)))
	data.DarkMatter += gained
	data.DarkMatterEarned += gained

	local startLvl = getLvl(data.DarkUpgrades, "dm1")
	data.Watt = startLvl > 0 and (50000 * startLvl) or 25
	data.Plasma = startLvl > 0 and (60 * startLvl) or 0
	data.Buttons = {}

	local savedAutos = {}
	if getLvl(data.DarkUpgrades, "dm5") > 0 then
		for _, autoId in ipairs({ "u6", "u10", "u13", "u17" }) do
			if getLvl(data.Upgrades, autoId) > 0 then savedAutos[autoId] = 1 end
		end
	end
	data.Upgrades = savedAutos

	syncPlayer(player, { SoundCue = "Prestige", PopupText = "🌌 COLLASSO QUANTISTICO! +" .. gained .. " Materia Oscura!" })
end)

-- Fabbrica & Forgia Droni (Fusione 3x -> Sovraccarico)
local function craftDrones(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local totalCost = getDroneCost(data) * amount
	if data.Plasma < totalCost then
		syncPlayer(player, { PopupText = "Servono " .. totalCost .. " Plasma!" })
		return
	end
	data.Plasma -= totalCost
	local luckMult = 1 + getLvl(data.DarkUpgrades, "dm3")
	local best = nil

	for _ = 1, amount do
		local weights, totalW = {}, 0
		for i, d in ipairs(GameConfig.Drones) do
			local w = (i >= 3) and (d.Weight * luckMult) or d.Weight
			weights[i] = w
			totalW += w
		end
		local roll, acc, chosen = math.random() * totalW, 0, GameConfig.Drones[1]
		for i, d in ipairs(GameConfig.Drones) do
			acc += weights[i]
			if roll <= acc then chosen = d; break end
		end
		table.insert(data.Drones, chosen.Id)
		data.DronesCrafted = (data.DronesCrafted or 0) + 1
		if not best or chosen.WattMult > best.WattMult then best = chosen end
	end

	syncPlayer(player, {
		SoundCue = "Upgrade",
		PopupText = amount == 1 and ("🛸 Creato: " .. best.Name .. "!") or ("🛸 Creati " .. amount .. " Droni! Migliore: " .. best.Name),
	})
end

droneClick.MouseClick:Connect(function(plr) craftDrones(plr, 1) end)
CraftDroneEvent.OnServerEvent:Connect(craftDrones)

FuseDroneEvent.OnServerEvent:Connect(function(player, baseDroneId)
	local data = PlayerData[player.UserId]
	if not data or type(baseDroneId) ~= "string" then return end

	local indices = {}
	for idx, rawId in ipairs(data.Drones) do
		if rawId == baseDroneId then
			table.insert(indices, idx)
			if #indices == 3 then break end
		end
	end

	if #indices < 3 then
		syncPlayer(player, { PopupText = "Servono 3 droni base identici per la Forgia!" })
		return
	end

	-- Rimuovi i 3 droni base partendo dal fondo
	for i = 3, 1, -1 do
		table.remove(data.Drones, indices[i])
	end
	table.insert(data.Drones, baseDroneId .. "_ov")
	data.FusionsDone = (data.FusionsDone or 0) + 1

	local cfg = parseDroneId(baseDroneId)
	syncPlayer(player, {
		SoundCue = "Prestige",
		PopupText = "🔥 FORGIA RIUSCITA! " .. (cfg and cfg.Name or "Drone") .. " SOVRACCARICO (x2.5)!",
	})
end)

-- Sfide Quantiche (Isolate e Sicure)
StartChallengeEvent.OnServerEvent:Connect(function(player, chId)
	local data = PlayerData[player.UserId]
	if not data or ChallengeSessions[player.UserId] then return end
	local cfg
	for _, c in ipairs(GameConfig.Challenges) do
		if c.Id == chId then cfg = c; break end
	end
	if not cfg then return end

	ChallengeSessions[player.UserId] = {
		Id = cfg.Id,
		Name = cfg.Name,
		GoalWatt = cfg.GoalWatt,
		EndsAt = os.time() + cfg.Duration,
		CostMult = cfg.Id == "ch1" and 10 or (cfg.Id == "ch3" and 25 or 1),
		Watt = 25,
		Buttons = {},
	}
	syncPlayer(player, { SoundCue = "Prestige", PopupText = "🔥 SFIDA AVVIATA: " .. cfg.Name .. "!" })
end)

AbandonChallengeEvent.OnServerEvent:Connect(function(player)
	if ChallengeSessions[player.UserId] then
		ChallengeSessions[player.UserId] = nil
		syncPlayer(player, { PopupText = "Sfida interrotta. Progressi principali intatti!" })
	end
end)

-- Codici & Premio Giornaliero
RedeemCode.OnServerInvoke = function(player, rawCode)
	local data = PlayerData[player.UserId]
	if not data or type(rawCode) ~= "string" then return false, "Errore" end
	local code = string.upper(string.gsub(rawCode, "%s+", ""))
	if data.UsedCodes[code] then return false, "Codice già usato!" end
	local rew = GameConfig.PromoCodes[code]
	if not rew then return false, "Codice non valido!" end
	data.UsedCodes[code] = true
	data.Watt += rew.Watt
	data.TotalWatt += rew.Watt
	data.Plasma += rew.Plasma
	data.TimeFragments += rew.Frags
	data.TotalFragments += rew.Frags
	syncPlayer(player, { SoundCue = "Upgrade" })
	return true, rew.Msg
end

ClaimDaily.OnServerInvoke = function(player)
	local data = PlayerData[player.UserId]
	if not data then return false, "Errore" end
	local diff = os.time() - (data.LastDaily or 0)
	if diff < 86400 then return false, "Torna tra " .. GameConfig.FormatTime(86400 - diff) end
	data.LastDaily = os.time()
	local stats = calculateStats(data, nil)
	local bonusWatt = math.max(500, stats.WattPerSec * 180)
	data.Watt += bonusWatt
	data.TotalWatt += bonusWatt
	data.Plasma += 40
	data.TimeFragments += 20
	syncPlayer(player, { SoundCue = "Upgrade" })
	return true, "+" .. GameConfig.Format(bonusWatt) .. " W, +40 Plasma, +20 Frammenti!"
end

-- Spawner Sfere Bonus & Eventi Dinamici
local function spawnBonusOrb(isCrystal)
	local orb = makePart({
		Name = "BonusOrb",
		Shape = Enum.PartType.Ball,
		Size = isCrystal and Vector3.new(2.8, 2.8, 2.8) or Vector3.new(3.8, 3.8, 3.8),
		Position = Vector3.new(math.random(-65, 65), 3.2, math.random(-45, 65)),
		Color = isCrystal and Color3.fromRGB(220, 80, 255) or Color3.fromRGB(255, 230, 50),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = world,
	})
	ActiveOrbs[orb] = true
	local claimed = false
	orb.Touched:Connect(function(hit)
		if claimed then return end
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		local data = plr and PlayerData[plr.UserId]
		if data then
			claimed = true
			ActiveOrbs[orb] = nil
			local stats = calculateStats(data, nil)
			if isCrystal then
				local gain = math.max(50, stats.WattPerSec * 15 * stats.OrbBonus)
				data.Watt += gain
				data.TotalWatt += gain
				data.Plasma += 3
				syncPlayer(plr, { SoundCue = "Click", PopupText = "💎 +" .. GameConfig.Format(gain) .. " W e +3 Plasma!" })
			else
				data.OrbBoostUntil = os.time() + math.floor(30 * stats.OrbBonus)
				syncPlayer(plr, { SoundCue = "Upgrade", PopupText = "⚡ BOOST SFERA x2 ATTIVO!" })
			end
			orb:Destroy()
		end
	end)
	task.delay(20, function()
		ActiveOrbs[orb] = nil
		if orb and orb.Parent then orb:Destroy() end
	end)
end

task.spawn(function()
	while true do
		task.wait(16)
		spawnBonusOrb(false)
	end
end)

task.spawn(function()
	while true do
		task.wait(80)
		if math.random(1, 2) == 1 then
			ActiveEvents.CoreOverloadUntil = os.time() + 25
		else
			ActiveEvents.CrystalRainUntil = os.time() + 25
			for i = 1, 14 do
				task.delay(i * 0.35, function() spawnBonusOrb(true) end)
			end
		end
	end
end)

-- Loop Principale (0.1s): Economia, Sfide, Camera AFK, Auto-Buyer e Calamita Sfere
local secTimer = 0
task.spawn(function()
	while true do
		task.wait(0.1)
		secTimer += 0.1
		local runSecond = secTimer >= 1.0
		if runSecond then
			secTimer = 0
			updateBatteryVisual()
		end

		local now = os.time()
		for _, plr in ipairs(Players:GetPlayers()) do
			local data = PlayerData[plr.UserId]
			if data then
				local ch = ChallengeSessions[plr.UserId]
				local stats = calculateStats(data, ch)

				if ch then
					ch.Watt += stats.WattPerSec * 0.1
					if ch.Watt >= ch.GoalWatt then
						data.CompletedChallenges[ch.Id] = true
						ChallengeSessions[plr.UserId] = nil
						syncPlayer(plr, { SoundCue = "Prestige", PopupText = "🏆 SFIDA COMPLETATA: " .. ch.Name .. "!" })
						continue
					elseif now >= ch.EndsAt then
						ChallengeSessions[plr.UserId] = nil
						syncPlayer(plr, { PopupText = "⏰ Tempo scaduto! Sei tornato alla partita principale." })
						continue
					end
				else
					data.Watt += stats.WattPerSec * 0.1
					data.TotalWatt += stats.WattPerSec * 0.1
					data.Plasma += stats.PlasmaPerSec * 0.1
				end

				-- Camera AFK & Calamita Sfere
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					if runSecond and (hrp.Position - afkPos).Magnitude <= 11 then
						local gain = 1 + getLvl(data.AfkUpgrades, "afk_frag")
						data.TimeFragments += gain
						data.TotalFragments = (data.TotalFragments or 0) + gain
					end
					if getLvl(data.Upgrades, "u9") > 0 then
						for orb in pairs(ActiveOrbs) do
							if orb and orb.Parent then
								local diff = hrp.Position - orb.Position
								if diff.Magnitude < 36 then
									orb.Position += diff.Unit * 2.5
								end
							end
						end
					end
				end

				-- Auto-Buyer (ogni 1.0s)
				if runSecond and not ch then
					local rows = {
						{ "u6", 1, 3 },
						{ "u10", 4, 6 },
						{ "u13", 7, 9 },
						{ "u17", 10, 12 },
					}
					for _, r in ipairs(rows) do
						if getLvl(data.Upgrades, r[1]) > 0 then
							for i = r[2], r[3] do
								local id = GameConfig.Buttons[i].Id
								data.Buttons[id] = getLvl(data.Buttons, id) + 1
							end
						end
					end
				end

				syncPlayer(plr)
			end
		end
	end
end)

-- Classifica & Salvataggi
local function refreshLeaderboard()
	if not orderedStore then return end
	local ok, pages = pcall(function() return orderedStore:GetSortedAsync(false, 10) end)
	if not ok or not pages then return end
	for _, c in ipairs(lbList:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for rank, entry in ipairs(pages:GetCurrentPage()) do
		local name = "Giocatore"
		pcall(function() name = Players:GetNameFromUserIdAsync(tonumber(entry.key)) end)
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0.088, 0)
		row.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
		row.Text = string.format("#%d %s - %s W", rank, name, GameConfig.Format(entry.value))
		row.TextColor3 = rank == 1 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(220, 235, 255)
		row.Font = Enum.Font.GothamBold
		row.TextScaled = true
		row.Parent = lbList
	end
end

local function savePlayer(player, removeCache)
	local data = PlayerData[player.UserId]
	if not data then return end
	data.LastLogout = os.time()
	if mainStore then
		pcall(function() mainStore:SetAsync("Plr_" .. player.UserId, data) end)
	end
	if orderedStore then
		pcall(function() orderedStore:SetAsync(tostring(player.UserId), math.floor(data.TotalWatt)) end)
	end
	if removeCache then
		PlayerData[player.UserId] = nil
		ChallengeSessions[player.UserId] = nil
	end
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, p in ipairs(Players:GetPlayers()) do savePlayer(p, false) end
		refreshLeaderboard()
	end
end)

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player
	local w = Instance.new("StringValue"); w.Name = "Watt"; w.Value = "0"; w.Parent = ls
	local p = Instance.new("StringValue"); p.Name = "Plasma"; p.Value = "0"; p.Parent = ls

	local data = defaultData()
	if mainStore then
		local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do data[k] = v end
		end
	end
	PlayerData[player.UserId] = data

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		applyAvatarStats(player, data)
	end)

	local stats = calculateStats(data, nil)
	local offlineGain = 0
	if data.LastLogout and data.LastLogout > 0 and stats.WattPerSec > 0 then
		local full = getLvl(data.DarkUpgrades, "dm6") > 0
		local elapsed = math.min(full and 86400 or 28800, math.max(0, os.time() - data.LastLogout))
		if elapsed >= 30 then
			offlineGain = stats.WattPerSec * elapsed * (full and 1.0 or 0.5)
			data.Watt += offlineGain
			data.TotalWatt += offlineGain
		end
	end

	task.wait(1)
	applyAvatarStats(player, data)
	syncPlayer(player, offlineGain > 0 and { OfflineGain = offlineGain } or nil)
end)

Players.PlayerRemoving:Connect(function(plr) savePlayer(plr, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)
