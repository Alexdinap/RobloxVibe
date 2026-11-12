local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local BigNum = require(Modules:WaitForChild("BigNum"))
local GameConfig = require(Modules:WaitForChild("GameConfig"))

local world = workspace:WaitForChild("QuantumWorld")
local corePart = world:WaitForChild("QuantumCoreAssembly"):WaitForChild("CorePart")
local floorButtons = world:WaitForChild("FloorButtons")
local droneStation = world:WaitForChild("DroneStation")
local lbList = world:WaitForChild("LeaderboardWall"):WaitForChild("LeaderboardGui"):WaitForChild("List")

-- Creazione Remotes
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function newRemote(className, name)
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end

local StateSync = newRemote("RemoteEvent", "StateSync")
local BuyUpgrade = newRemote("RemoteEvent", "BuyUpgrade")
local BuyDarkUpgrade = newRemote("RemoteEvent", "BuyDarkUpgrade")
local PrestigeEvent = newRemote("RemoteEvent", "Prestige")
local CraftDroneEvent = newRemote("RemoteEvent", "CraftDrone")
local RedeemCode = newRemote("RemoteFunction", "RedeemCode")
local ClaimDaily = newRemote("RemoteFunction", "ClaimDaily")

-- DataStores protetti
local mainStore, orderedStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("QuantumCore_Full_V1")
	orderedStore = DataStoreService:GetOrderedDataStore("QuantumCore_TopWatt_Full_V1")
end)

local PlayerData = {}
local ActiveOrbs = {}
local ActiveEvents = {
	CoreOverloadUntil = 0,
	CrystalRainUntil = 0,
	GoldenSurgeUntil = 0,
}

local function defaultData()
	return {
		Watt = 15,
		TotalWatt = 15,
		Plasma = 0,
		DarkMatter = 0,
		DarkMatterEarned = 0,
		TotalClicks = 0,
		DronesCrafted = 0,
		Buttons = {},
		Upgrades = {},
		DarkUpgrades = {},
		Drones = {},
		Achievements = {},
		UsedCodes = {},
		LastDaily = 0,
		LastLogout = os.time(),
	}
end

local function getLvl(tbl, id)
	return (tbl and tbl[id]) or 0
end

local function getMaxDroneSlots(data)
	return GameConfig.BaseEquippedDrones + getLvl(data.Upgrades, "u16")
end

local function getDroneCost(data)
	if getLvl(data.DarkUpgrades, "dm2") > 0 then
		return math.floor(GameConfig.BaseDroneCost * 0.5)
	end
	return GameConfig.BaseDroneCost
end

local function getEquippedDrones(data)
	local list = {}
	for _, dId in ipairs(data.Drones) do
		for _, cfg in ipairs(GameConfig.Drones) do
			if cfg.Id == dId then
				table.insert(list, cfg)
				break
			end
		end
	end
	table.sort(list, function(a, b)
		return a.WattMult > b.WattMult
	end)
	local maxSlots = getMaxDroneSlots(data)
	local equipped = {}
	for i = 1, math.min(maxSlots, #list) do
		table.insert(equipped, list[i])
	end
	return equipped
end

local function getTotalButtonLevels(data)
	local sum = 0
	for _, v in pairs(data.Buttons) do
		sum += v
	end
	return sum
end

local function calculateStats(data)
	local baseWattSec = 0
	local wattMult = 1
	local plasmaSec = 0
	local plasmaMult = 1
	local clickMult = 1
	local costDiscount = 0
	local droneSynergy = 1
	local orbBonus = 1
	local comboBonus = 0

	-- Pulsanti a terra
	for _, btn in ipairs(GameConfig.Buttons) do
		local lvl = getLvl(data.Buttons, btn.Id)
		if lvl > 0 then
			if btn.Type == "AddWatt" then
				baseWattSec += btn.Value * lvl
			elseif btn.Type == "MultWatt" then
				wattMult *= (btn.Value ^ lvl)
			end
		end
	end

	-- Upgrade Tree principale
	for _, upg in ipairs(GameConfig.Upgrades) do
		local lvl = getLvl(data.Upgrades, upg.Id)
		if lvl > 0 then
			if upg.Effect == "WattMult" then
				wattMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "PlasmaMult" then
				plasmaMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "ClickMult" then
				clickMult *= (upg.Value ^ lvl)
			elseif upg.Effect == "CostDiscount" then
				costDiscount = math.min(0.75, costDiscount + upg.Value * lvl)
			elseif upg.Effect == "UnlockPlasma" then
				plasmaSec += 1
			elseif upg.Effect == "DroneSynergy" then
				droneSynergy += upg.Value * lvl
			elseif upg.Effect == "OrbBonus" then
				orbBonus += upg.Value * lvl
			elseif upg.Effect == "ComboBonus" then
				comboBonus += upg.Value * lvl
			end
		end
	end

	-- Bonus Droni equipaggiati
	local equipped = getEquippedDrones(data)
	local droneWattBonus = 1
	local dronePlasmaBonus = 1
	for _, d in ipairs(equipped) do
		droneWattBonus += (d.WattMult - 1) * droneSynergy
		dronePlasmaBonus += (d.PlasmaMult - 1) * droneSynergy
	end
	wattMult *= droneWattBonus
	plasmaMult *= dronePlasmaBonus

	-- Bonus Obiettivi sbloccati
	for _, ach in ipairs(GameConfig.Achievements) do
		if data.Achievements[ach.Id] then
			if ach.MultType == "Watt" then
				wattMult *= ach.MultVal
			elseif ach.MultType == "Plasma" then
				plasmaMult *= ach.MultVal
			elseif ach.MultType == "Click" then
				clickMult *= ach.MultVal
			elseif ach.MultType == "All" then
				wattMult *= ach.MultVal
				plasmaMult *= ach.MultVal
				clickMult *= ach.MultVal
			end
		end
	end

	-- Bonus Materia Oscura + Dark Upgrades
	if data.DarkMatterEarned > 0 then
		wattMult *= (5 ^ data.DarkMatterEarned)
		plasmaMult *= (3 ^ data.DarkMatterEarned)
	end
	local hyperLvl = getLvl(data.DarkUpgrades, "dm4")
	if hyperLvl > 0 then
		wattMult *= (25 ^ hyperLvl)
		plasmaMult *= (25 ^ hyperLvl)
	end

	-- Boost temporanei ed Eventi
	local now = os.time()
	if data.OrbBoostUntil and now < data.OrbBoostUntil then
		wattMult *= 2
	end
	if now < ActiveEvents.CoreOverloadUntil then
		wattMult *= 5
		clickMult *= 5
	end
	if now < ActiveEvents.GoldenSurgeUntil then
		wattMult *= 3
		plasmaMult *= 3
	end

	return {
		WattPerSec = baseWattSec * wattMult,
		PlasmaPerSec = plasmaSec * plasmaMult,
		ClickPower = math.max(1, (1 + baseWattSec * 0.25) * clickMult),
		CostDiscount = costDiscount,
		DroneWattBonus = droneWattBonus,
		DronePlasmaBonus = dronePlasmaBonus,
		OrbBonus = orbBonus,
		ComboBonus = comboBonus,
		EquippedDrones = equipped,
		MaxDroneSlots = getMaxDroneSlots(data),
		DroneCost = getDroneCost(data),
	}
end

local function checkAchievements(data)
	local unlockedNew = nil
	local statValues = {
		TotalClicks = data.TotalClicks or 0,
		TotalWatt = data.TotalWatt or 0,
		TotalButtonLevels = getTotalButtonLevels(data),
		DronesCrafted = data.DronesCrafted or 0,
		DarkMatterEarned = data.DarkMatterEarned or 0,
	}
	for _, ach in ipairs(GameConfig.Achievements) do
		if not data.Achievements[ach.Id] then
			local cur = statValues[ach.Stat] or 0
			if cur >= ach.Target then
				data.Achievements[ach.Id] = true
				unlockedNew = ach.Name .. " (" .. ach.BonusText .. ")"
			end
		end
	end
	return unlockedNew
end

local function syncPlayer(player, extraPayload)
	local data = PlayerData[player.UserId]
	if not data then return end

	local newAch = checkAchievements(data)
	local stats = calculateStats(data)

	player:SetAttribute("DarkMatter", data.DarkMatterEarned)
	local eqIds = {}
	for _, d in ipairs(stats.EquippedDrones) do
		table.insert(eqIds, d.Id)
	end
	player:SetAttribute("EquippedDrones", HttpService:JSONEncode(eqIds))

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Watt.Value = BigNum.Format(data.Watt)
		ls.Plasma.Value = BigNum.Format(data.Plasma)
	end

	-- Conta quanti droni possiede per tipo
	local droneCounts = {}
	for _, id in ipairs(data.Drones) do
		droneCounts[id] = (droneCounts[id] or 0) + 1
	end

	local now = os.time()
	local payload = {
		Watt = data.Watt,
		TotalWatt = data.TotalWatt,
		Plasma = data.Plasma,
		DarkMatter = data.DarkMatter,
		DarkMatterEarned = data.DarkMatterEarned,
		WattPerSec = stats.WattPerSec,
		PlasmaPerSec = stats.PlasmaPerSec,
		CostDiscount = stats.CostDiscount,
		DroneWattBonus = stats.DroneWattBonus,
		DronePlasmaBonus = stats.DronePlasmaBonus,
		EquippedCount = #stats.EquippedDrones,
		MaxDroneSlots = stats.MaxDroneSlots,
		DroneCost = stats.DroneCost,
		DroneCounts = droneCounts,
		Buttons = data.Buttons,
		Upgrades = data.Upgrades,
		DarkUpgrades = data.DarkUpgrades,
		Achievements = data.Achievements,
		StatProgress = {
			TotalClicks = data.TotalClicks or 0,
			TotalWatt = data.TotalWatt or 0,
			TotalButtonLevels = getTotalButtonLevels(data),
			DronesCrafted = data.DronesCrafted or 0,
			DarkMatterEarned = data.DarkMatterEarned or 0,
		},
		OrbBoostLeft = math.max(0, (data.OrbBoostUntil or 0) - now),
		CoreOverloadLeft = math.max(0, ActiveEvents.CoreOverloadUntil - now),
		CrystalRainLeft = math.max(0, ActiveEvents.CrystalRainUntil - now),
		GoldenSurgeLeft = math.max(0, ActiveEvents.GoldenSurgeUntil - now),
	}

	if newAch then
		payload.AchievementUnlocked = newAch
	end
	if extraPayload then
		for k, v in pairs(extraPayload) do
			payload[k] = v
		end
	end
	StateSync:FireClient(player, payload)
end

-- Acquisto continuo sui 9 pulsanti a terra
local function getButtonCost(btnCfg, level, discount)
	local raw = btnCfg.BaseCost * (btnCfg.CostMult ^ level)
	return math.max(1, math.floor(raw * (1 - discount)))
end

local function tryBuyButton(player, btnCfg)
	local data = PlayerData[player.UserId]
	if not data then return false end
	local stats = calculateStats(data)
	local lvl = getLvl(data.Buttons, btnCfg.Id)
	local cost = getButtonCost(btnCfg, lvl, stats.CostDiscount)
	if data.Watt >= cost then
		data.Watt -= cost
		data.Buttons[btnCfg.Id] = lvl + 1
		syncPlayer(player, { SoundCue = "Buy" })
		return true
	end
	return false
end

local TouchingMap = {}
for _, btnCfg in ipairs(GameConfig.Buttons) do
	local pad = floorButtons:FindFirstChild(btnCfg.Id)
	if pad then
		TouchingMap[btnCfg.Id] = {}
		pad.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then
				TouchingMap[btnCfg.Id][plr.UserId] = plr
			end
		end)
		pad.TouchEnded:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if plr then
				TouchingMap[btnCfg.Id][plr.UserId] = nil
			end
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(0.12)
		for _, btnCfg in ipairs(GameConfig.Buttons) do
			for _, plr in pairs(TouchingMap[btnCfg.Id]) do
				if plr and plr.Parent then
					tryBuyButton(plr, btnCfg)
				end
			end
		end
	end
end)

-- Clicker con Combo sul Nucleo Centrale
local ClickCombos = {}
corePart.CoreClick.MouseClick:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	local stats = calculateStats(data)

	local now = os.clock()
	local combo = ClickCombos[player.UserId] or { Count = 0, Last = 0 }
	if now - combo.Last <= 2.5 then
		combo.Count += 1
	else
		combo.Count = 1
	end
	combo.Last = now
	ClickCombos[player.UserId] = combo

	local maxCombo = 5.0 + stats.ComboBonus
	local comboMult = math.min(maxCombo, 1 + (combo.Count - 1) * 0.15)
	local gain = stats.ClickPower * comboMult

	data.Watt += gain
	data.TotalWatt += gain
	data.TotalClicks = (data.TotalClicks or 0) + 1

	syncPlayer(player, {
		SoundCue = "Click",
		CorePulse = true,
		PopupText = "+" .. BigNum.Format(gain) .. " W (x" .. string.format("%.1f", comboMult) .. ")",
	})
end)

-- Acquisto Upgrade Tree principale
BuyUpgrade.OnServerEvent:Connect(function(player, upgId)
	local data = PlayerData[player.UserId]
	if not data then return end

	local target
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Id == upgId then
			target = u
			break
		end
	end
	if not target then return end
	if target.Prereq and getLvl(data.Upgrades, target.Prereq) <= 0 then return end

	local curLvl = getLvl(data.Upgrades, target.Id)
	if curLvl >= target.MaxLevel then return end

	local cost = math.floor(target.Cost * (target.CostMult ^ curLvl))
	if target.Currency == "Watt" and data.Watt >= cost then
		data.Watt -= cost
		data.Upgrades[target.Id] = curLvl + 1
		syncPlayer(player, { SoundCue = "Upgrade" })
	elseif target.Currency == "Plasma" and data.Plasma >= cost then
		data.Plasma -= cost
		data.Upgrades[target.Id] = curLvl + 1
		syncPlayer(player, { SoundCue = "Upgrade" })
	end
end)

-- Acquisto Dark Matter Upgrades (Santuario Materia Oscura)
BuyDarkUpgrade.OnServerEvent:Connect(function(player, dmId)
	local data = PlayerData[player.UserId]
	if not data then return end

	local target
	for _, d in ipairs(GameConfig.DarkUpgrades) do
		if d.Id == dmId then
			target = d
			break
		end
	end
	if not target then return end

	local curLvl = getLvl(data.DarkUpgrades, target.Id)
	if curLvl >= target.MaxLevel then return end

	local cost = math.floor(target.Cost * (target.CostMult ^ curLvl))
	if data.DarkMatter >= cost then
		data.DarkMatter -= cost
		data.DarkUpgrades[target.Id] = curLvl + 1
		syncPlayer(player, { SoundCue = "Upgrade", PopupText = "🌌 Potenziamento Oscuro sbloccato!" })
	end
end)

-- Collasso Quantistico (Prestige Endgame)
PrestigeEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data or data.Watt < GameConfig.PrestigeCost then return end

	local gained = math.max(1, math.floor(math.log10(data.Watt / 1e11)))
	data.DarkMatter += gained
	data.DarkMatterEarned += gained

	local startLvl = getLvl(data.DarkUpgrades, "dm1")
	data.Watt = startLvl > 0 and (25000 * startLvl) or 25
	data.Plasma = startLvl > 0 and (50 * startLvl) or 0
	data.Buttons = {}

	local savedAutos = {}
	if getLvl(data.DarkUpgrades, "dm5") > 0 then
		if getLvl(data.Upgrades, "u6") > 0 then savedAutos["u6"] = 1 end
		if getLvl(data.Upgrades, "u10") > 0 then savedAutos["u10"] = 1 end
		if getLvl(data.Upgrades, "u13") > 0 then savedAutos["u13"] = 1 end
	end
	data.Upgrades = savedAutos

	syncPlayer(player, {
		SoundCue = "Prestige",
		PopupText = "🌌 COLLASSO QUANTISTICO! +" .. gained .. " Materia Oscura!",
	})
end)

-- Fabbricazione Droni (sia da Stazione 3D che da UI)
local function craftDrones(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local unitCost = getDroneCost(data)
	local totalCost = unitCost * amount

	if data.Plasma < totalCost then
		syncPlayer(player, { PopupText = "Servono " .. totalCost .. " Plasma!" })
		return
	end

	data.Plasma -= totalCost
	local luckMult = 1 + getLvl(data.DarkUpgrades, "dm3")
	local bestChosen = nil

	for _ = 1, amount do
		local weights = {}
		local totalWeight = 0
		for i, d in ipairs(GameConfig.Drones) do
			local w = d.Weight
			if i >= 3 then
				w = w * luckMult
			end
			weights[i] = w
			totalWeight += w
		end

		local roll = math.random() * totalWeight
		local acc = 0
		local chosen = GameConfig.Drones[1]
		for i, d in ipairs(GameConfig.Drones) do
			acc += weights[i]
			if roll <= acc then
				chosen = d
				break
			end
		end

		table.insert(data.Drones, chosen.Id)
		data.DronesCrafted = (data.DronesCrafted or 0) + 1
		if not bestChosen or chosen.WattMult > bestChosen.WattMult then
			bestChosen = chosen
		end
	end

	local msg = amount == 1
		and ("🛸 Creato: " .. bestChosen.Name .. " (x" .. bestChosen.WattMult .. " W)!")
		or ("🛸 Creati " .. amount .. " Droni! Migliore: " .. bestChosen.Name)

	syncPlayer(player, {
		SoundCue = "Upgrade",
		PopupText = msg,
	})
end

droneStation.HatchClick.MouseClick:Connect(function(player)
	craftDrones(player, 1)
end)
CraftDroneEvent.OnServerEvent:Connect(function(player, amount)
	craftDrones(player, amount)
end)

-- Codici Promo
RedeemCode.OnServerInvoke = function(player, rawCode)
	local data = PlayerData[player.UserId]
	if not data or type(rawCode) ~= "string" then return false, "Errore" end
	local code = string.upper(string.gsub(rawCode, "%s+", ""))
	if data.UsedCodes[code] then return false, "Codice già usato!" end
	local reward = GameConfig.PromoCodes[code]
	if not reward then return false, "Codice non valido!" end

	data.UsedCodes[code] = true
	data.Watt += reward.Watt
	data.TotalWatt += reward.Watt
	data.Plasma += reward.Plasma
	syncPlayer(player, { SoundCue = "Upgrade" })
	return true, reward.Msg
end

-- Premio Giornaliero
ClaimDaily.OnServerInvoke = function(player)
	local data = PlayerData[player.UserId]
	if not data then return false, "Errore" end
	local now = os.time()
	local diff = now - (data.LastDaily or 0)
	if diff < 86400 then
		return false, "Torna tra " .. BigNum.FormatTime(86400 - diff)
	end

	data.LastDaily = now
	local stats = calculateStats(data)
	local bonusWatt = math.max(500, stats.WattPerSec * 180)
	data.Watt += bonusWatt
	data.TotalWatt += bonusWatt
	data.Plasma += 40
	syncPlayer(player, { SoundCue = "Upgrade" })
	return true, "+" .. BigNum.Format(bonusWatt) .. " W e +40 Plasma!"
end

-- Spawner Sfere di Sovraccarico
local function spawnBonusOrb(isCrystalEvent)
	local orb = Instance.new("Part")
	orb.Shape = Enum.PartType.Ball
	orb.Size = isCrystalEvent and Vector3.new(2.6, 2.6, 2.6) or Vector3.new(3.6, 3.6, 3.6)
	orb.Position = Vector3.new(math.random(-46, 46), 3.2, math.random(-34, 42))
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = isCrystalEvent and Color3.fromRGB(220, 80, 255) or Color3.fromRGB(255, 230, 50)
	orb.Parent = world

	ActiveOrbs[orb] = true
	local claimed = false

	orb.Touched:Connect(function(hit)
		if claimed then return end
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if plr and PlayerData[plr.UserId] then
			claimed = true
			ActiveOrbs[orb] = nil
			local data = PlayerData[plr.UserId]
			local stats = calculateStats(data)
			if isCrystalEvent then
				local gain = math.max(50, stats.WattPerSec * 15 * stats.OrbBonus)
				data.Watt += gain
				data.TotalWatt += gain
				data.Plasma += 3
				syncPlayer(plr, { SoundCue = "Click", PopupText = "💎 +" .. BigNum.Format(gain) .. " W & +3 Plasma!" })
			else
				data.OrbBoostUntil = os.time() + math.floor(30 * stats.OrbBonus)
				syncPlayer(plr, { SoundCue = "Upgrade", PopupText = "⚡ BOOST x2 ATTIVO!" })
			end
			orb:Destroy()
		end
	end)

	task.delay(20, function()
		ActiveOrbs[orb] = nil
		if orb and orb.Parent then
			orb:Destroy()
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(16)
		spawnBonusOrb(false)
	end
end)

-- Eventi Dinamici ogni 75 secondi
task.spawn(function()
	while true do
		task.wait(75)
		local roll = math.random(1, 3)
		if roll == 1 then
			ActiveEvents.CoreOverloadUntil = os.time() + 25
		elseif roll == 2 then
			ActiveEvents.CrystalRainUntil = os.time() + 25
			for i = 1, 14 do
				task.delay(i * 0.35, function()
					spawnBonusOrb(true)
				end)
			end
		else
			ActiveEvents.GoldenSurgeUntil = os.time() + 25
		end
	end
end)

-- Loop Economia (0.1s), Attrazione Magnetica Sfere e Auto-Buyer (1.0s)
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
				data.Watt += stats.WattPerSec * 0.1
				data.TotalWatt += stats.WattPerSec * 0.1
				data.Plasma += stats.PlasmaPerSec * 0.1

				-- Attrazione sfere se u9 è sbloccato
				if getLvl(data.Upgrades, "u9") > 0 and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local hrpPos = plr.Character.HumanoidRootPart.Position
					for orb in pairs(ActiveOrbs) do
						if orb and orb.Parent then
							local diff = hrpPos - orb.Position
							if diff.Magnitude < 32 then
								orb.Position += diff.Unit * 2.4
							end
						end
					end
				end

				if runAuto then
					if getLvl(data.Upgrades, "u6") > 0 then
						for i = 1, 3 do
							local id = GameConfig.Buttons[i].Id
							data.Buttons[id] = getLvl(data.Buttons, id) + 1
						end
					end
					if getLvl(data.Upgrades, "u10") > 0 then
						for i = 4, 6 do
							local id = GameConfig.Buttons[i].Id
							data.Buttons[id] = getLvl(data.Buttons, id) + 1
						end
					end
					if getLvl(data.Upgrades, "u13") > 0 then
						for i = 7, 9 do
							local id = GameConfig.Buttons[i].Id
							data.Buttons[id] = getLvl(data.Buttons, id) + 1
						end
					end
				end

				syncPlayer(plr)
			end
		end
	end
end)

-- Classifica Globale (ogni 60s)
local function refreshLeaderboard()
	if not orderedStore then return end
	local ok, pages = pcall(function()
		return orderedStore:GetSortedAsync(false, 10)
	end)
	if not ok or not pages then return end

	for _, child in ipairs(lbList:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end

	for rank, entry in ipairs(pages:GetCurrentPage()) do
		local name = "Giocatore"
		pcall(function()
			name = Players:GetNameFromUserIdAsync(tonumber(entry.key))
		end)
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0.088, 0)
		row.BackgroundColor3 = Color3.fromRGB(22, 28, 46)
		row.Text = string.format("#%d %s - %s W", rank, name, BigNum.Format(entry.value))
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
		pcall(function()
			mainStore:SetAsync("Player_" .. player.UserId, data)
		end)
	end
	if orderedStore then
		pcall(function()
			orderedStore:SetAsync(tostring(player.UserId), math.floor(data.TotalWatt))
		end)
	end
	if removeCache then
		PlayerData[player.UserId] = nil
	end
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do
			savePlayer(plr, false)
		end
		refreshLeaderboard()
	end
end)

-- Join / Leave
Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local wVal = Instance.new("StringValue")
	wVal.Name = "Watt"
	wVal.Value = "0"
	wVal.Parent = ls

	local pVal = Instance.new("StringValue")
	pVal.Name = "Plasma"
	pVal.Value = "0"
	pVal.Parent = ls

	local data = defaultData()
	if mainStore then
		local ok, saved = pcall(function()
			return mainStore:GetAsync("Player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do
				data[k] = v
			end
		end
	end

	PlayerData[player.UserId] = data
	local stats = calculateStats(data)

	local offlineGain = 0
	if data.LastLogout and data.LastLogout > 0 and stats.WattPerSec > 0 then
		local fullOffline = getLvl(data.DarkUpgrades, "dm6") > 0
		local maxSec = fullOffline and 86400 or 28800
		local mult = fullOffline and 1.0 or 0.5
		local elapsed = math.min(maxSec, math.max(0, os.time() - data.LastLogout))
		if elapsed >= 30 then
			offlineGain = stats.WattPerSec * elapsed * mult
			data.Watt += offlineGain
			data.TotalWatt += offlineGain
		end
	end

	task.wait(1)
	syncPlayer(player, offlineGain > 0 and { OfflineGain = offlineGain } or nil)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player, true)
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		savePlayer(plr, false)
	end
end)
