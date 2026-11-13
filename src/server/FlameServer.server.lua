local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local EconomyEngine = require(script.Parent:WaitForChild("EconomyEngine"))
local Regno1Service = require(script.Parent:WaitForChild("Regno1Service"))

local built = WorldBuilder.Build()
local world = built.World
local altarsFolder = built.AltarsFolder

-- Remotes
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
local SyncGamePass = makeRemote("RemoteEvent", "SyncGamePass")
local RedeemCode = makeRemote("RemoteFunction", "RedeemCode")

local mainStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("LastFlame_V5")
end)

local PlayerData = {}
local ClickHeat = {}
local ActiveEmbers = {}
local ActiveShadows = {}

local function getDoubleLightPassId()
	return (GameConfig.RobuxPasses and GameConfig.RobuxPasses.DoubleLight and GameConfig.RobuxPasses.DoubleLight.GamePassId) or 0
end

local function verifyDoubleLightOwnership(player, data)
	if not data then return false end
	if data.HasDoubleLight == true then
		return true
	end
	local passId = getDoubleLightPassId()
	if passId > 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
		if ok and owns then
			data.HasDoubleLight = true
			return true
		end
	end
	return false
end

local function getCurrentHeat(userId)
	local h = ClickHeat[userId]
	if not h then return 0 end
	local elapsed = os.clock() - h.LastClick
	local val = math.max(0, h.Heat - elapsed * 0.22)
	h.Heat = val
	return val
end

local function syncPlayer(player, extra)
	local data = PlayerData[player.UserId]
	if not data then return end
	local buffMult, buffRem = Regno1Service.GetActiveBuff(player.UserId)
	local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(player.UserId), buffMult, data.HasDoubleLight)
	local rank = EconomyEngine.GetRank(stats.LightPercent)

	local eqIds = {}
	for _, w in ipairs(stats.EquippedWisps) do
		table.insert(eqIds, w.RawId)
	end
	player:SetAttribute("EquippedWisps", HttpService:JSONEncode(eqIds))
	player:SetAttribute("RadiusLevel", stats.RadiusLevel)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Punti.Value = NumberFormat.Format(data.Points)
		ls.Luce.Value = tostring(stats.LightPercent) .. "%"
	end

	local wispCounts = {}
	for _, rawId in ipairs(data.Wisps) do
		wispCounts[rawId] = (wispCounts[rawId] or 0) + 1
	end

	local payload = {
		Points = data.Points,
		TotalPoints = data.TotalPoints,
		EternalStars = data.EternalStars,
		HasDoubleLight = stats.HasDoubleLight,
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
		WispsUnlocked = stats.WispsUnlocked,
		AlbaUnlocked = stats.AlbaUnlocked,
		Regno1 = data.Regno1,
		Regno1BuffMult = buffMult,
		Regno1BuffRemaining = buffRem,
	}
	if extra then
		for k, v in pairs(extra) do payload[k] = v end
	end
	StateSync:FireClient(player, payload)
end

-- Inizializza la meccanica principale di Regno 1
Regno1Service.Init(remotes, built.RitualFolder, PlayerData, syncPlayer)

-- Gestione GamePass Robux (Luce x2 Permanente)
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	local passId = getDoubleLightPassId()
	if wasPurchased and passId > 0 and gamePassId == passId then
		local data = PlayerData[player.UserId]
		if data and not data.HasDoubleLight then
			data.HasDoubleLight = true
			syncPlayer(player, {
				SoundCue = "Prestige",
				Shockwave = true,
				PopupText = "⚡ LUCE x2 PERMANENTE ATTIVATA!",
			})
		end
	end
end)

SyncGamePass.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	if verifyDoubleLightOwnership(player, data) then
		syncPlayer(player)
	end
end)

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

	local curHeat = getCurrentHeat(player.UserId)
	local newHeat = math.min(1.0, curHeat + 0.08)
	ClickHeat[player.UserId] = { Heat = newHeat, LastClick = now }

	local buffMult = Regno1Service.GetActiveBuff(player.UserId)
	local stats = EconomyEngine.CalculateStats(data, newHeat, buffMult, data.HasDoubleLight)
	local isCrit = math.random() < stats.CritChance
	local gained = stats.ClickPower * (isCrit and stats.CritMult or 1)

	data.Points += gained
	data.TotalPoints += gained
	data.TotalClicks += 1

	syncPlayer(player, {
		FlameClicked = true,
		IsCrit = isCrit,
		ClickGained = gained,
		SoundCue = isCrit and "Crit" or "Click",
	})
end

for _, part in ipairs({ built.FlameCore, built.BrazierBowl, built.FlameHitbox }) do
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
					local lvl = EconomyEngine.GetLevel(data.Altars, alt.Id)
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

-- Acquisto Potenziamenti Progressivi
BuyUpgrade.OnServerEvent:Connect(function(player, upgId)
	local data = PlayerData[player.UserId]
	if not data then return end
	local target
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Id == upgId then target = u; break end
	end
	if not target then return end
	if not EconomyEngine.IsUpgradeUnlocked(data, target) then return end

	local cur = EconomyEngine.GetLevel(data.Upgrades, target.Id)
	if cur >= target.MaxLevel then return end

	local cost = math.floor(target.BaseCost * (target.CostMult ^ cur))
	if data.Points >= cost then
		data.Points -= cost
		local nextLvl = cur + 1
		data.Upgrades[target.Id] = nextLvl

		-- Controlla quali nuovi bottoni si sono appena sbloccati
		local newlyUnlocked = {}
		if nextLvl == 1 then
			for _, other in ipairs(GameConfig.Upgrades) do
				if other.ReqId == target.Id and (other.ReqLvl or 1) == 1 then
					table.insert(newlyUnlocked, other.Name)
				end
			end
		end

		local popup = nil
		if target.Id == "u_braziers" then
			popup = "🔥 REGNO 1 RISVEGLIATO! Raggiungi il Braciere I per la Catena del Fuoco!"
			Regno1Service.SyncPlayer(player)
		elseif target.Zone then
			popup = "✨ REGNO RISVEGLIATO: " .. target.Name .. "!"
		elseif #newlyUnlocked > 0 then
			popup = "🆕 NUOVO BOTTONE: " .. table.concat(newlyUnlocked, " & ") .. "!"
		end

		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = target.Zone ~= nil or #newlyUnlocked > 0,
			PopupText = popup,
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
	local cur = EconomyEngine.GetLevel(data.StarPerks, target.Id)
	if cur >= target.MaxLevel then return end
	local cost = math.floor(target.Cost * (target.CostMult ^ cur))
	if data.EternalStars >= cost then
		data.EternalStars -= cost
		data.StarPerks[target.Id] = cur + 1
		syncPlayer(player, { SoundCue = "Prestige", PopupText = "⭐ Costellazione sbloccata: " .. target.Name })
	end
end)

SummonWisp.OnServerEvent:Connect(function(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local totalCost = GameConfig.BaseWispCost * amount
	if data.Points < totalCost then
		syncPlayer(player, { PopupText = "Servono " .. NumberFormat.Format(totalCost) .. " Punti Luce!" })
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
		PopupText = amount == 1 and ("✨ Evocato: " .. best.Name .. "!") or ("✨ Evocati " .. amount .. " Spiriti! Migliore: " .. best.Name),
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
	if #idxs < 3 then
		syncPlayer(player, { PopupText = "Servono 3 Spiriti identici!" })
		return
	end

	for i = 3, 1, -1 do
		table.remove(data.Wisps, idxs[i])
	end
	table.insert(data.Wisps, baseWispId .. "_rad")

	local cfg = EconomyEngine.ParseWispId(baseWispId)
	syncPlayer(player, {
		SoundCue = "Prestige",
		Shockwave = true,
		PopupText = "🌟 FORGIA RIUSCITA! " .. (cfg and cfg.Name or "Spirito") .. " RADIOSO (x2.5)!",
	})
end)

PrestigeEvent.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data or data.Points < GameConfig.PrestigeCost then return end

	local gained = math.max(1, math.floor(math.log10(data.Points / 5e6)))
	data.EternalStars += gained

	local startLvl = EconomyEngine.GetLevel(data.StarPerks, "sp_start")
	data.Points = startLvl > 0 and (5000 * startLvl) or 0
	data.Altars = {}
	data.Upgrades = startLvl > 0 and { u_click_add = 5 * startLvl } or {}

	Regno1Service.SyncPlayer(player)
	syncPlayer(player, {
		SoundCue = "Prestige",
		Shockwave = true,
		PopupText = "🌅 GRANDE ALBA COMPIUTA! +" .. gained .. " Stelle Eterne!",
	})
end)

RedeemCode.OnServerInvoke = function(player, raw)
	local data = PlayerData[player.UserId]
	if not data or type(raw) ~= "string" then return false, "Errore" end
	local code = string.upper(string.gsub(raw, "%s+", ""))
	if data.UsedCodes[code] then return false, "Codice già usato!" end
	local rew = GameConfig.PromoCodes[code]
	if not rew then return false, "Codice non valido!" end
	data.UsedCodes[code] = true
	data.Points += rew.Points
	data.TotalPoints += rew.Points
	syncPlayer(player, { SoundCue = "Upgrade", PopupText = rew.Msg })
	return true, rew.Msg
end

-- Sfere Vaganti & Ombre
local function makeOrb(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.CanCollide = false
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function spawnWanderingEmber()
	local ember = makeOrb({
		Name = "WanderingEmber",
		Size = Vector3.new(2.4, 2.4, 2.4),
		Position = Vector3.new(math.random(-60, 60), 2.5, math.random(-60, 60)),
		Color = Color3.fromRGB(255, 200, 75),
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
			local buffMult = Regno1Service.GetActiveBuff(plr.UserId)
			local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(plr.UserId), buffMult, data.HasDoubleLight)
			local gain = math.max(10, stats.ClickPower * 8)
			data.Points += gain
			data.TotalPoints += gain
			syncPlayer(plr, { SoundCue = "Click", PopupText = "✨ Sfera raccolta: +" .. NumberFormat.Format(gain) .. " Punti!" })
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
		local buffMult = Regno1Service.GetActiveBuff(player.UserId)
		local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(player.UserId), buffMult, data.HasDoubleLight)
		local reward = math.max(25, stats.ClickPower * 15)
		data.Points += reward
		data.TotalPoints += reward
		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = true,
			PopupText = "🛡️ OMBRA DISSIPATA! +" .. NumberFormat.Format(reward) .. " Punti!",
		})
	end
end

local function spawnShadowWisp()
	if #ActiveShadows >= 2 then return end
	local ang = math.random() * math.pi * 2
	local shadow = makeOrb({
		Name = "VoidShadow",
		Size = Vector3.new(4.2, 4.2, 4.2),
		Position = Vector3.new(math.cos(ang) * 90, 3.8, math.sin(ang) * 90),
		Color = Color3.fromRGB(25, 10, 45),
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
		Regno1Service.Tick(0.1)

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
				local buffMult = Regno1Service.GetActiveBuff(plr.UserId)
				local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(plr.UserId), buffMult, data.HasDoubleLight)
				if stats.PointsPerSec > 0 then
					data.Points += stats.PointsPerSec * 0.1
					data.TotalPoints += stats.PointsPerSec * 0.1
				end

				if EconomyEngine.GetLevel(data.StarPerks, "sp_ward") > 0 and #ActiveShadows > 0 then
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
					if EconomyEngine.GetLevel(data.Upgrades, "u_ember_mag") > 0 then
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
	local l = Instance.new("StringValue", ls); l.Name = "Luce"; l.Value = "2%"

	local data = EconomyEngine.DefaultData()
	if mainStore then
		local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do data[k] = v end
		end
	end
	-- Migrazione sicura per salvataggi esistenti
	if type(data.Regno1) ~= "table" then
		data.Regno1 = { Completed = false, Completions = 0, BestTime = nil }
	end
	data.HasDoubleLight = (data.HasDoubleLight == true)

	verifyDoubleLightOwnership(player, data)

	PlayerData[player.UserId] = data
	task.wait(0.8)
	Regno1Service.SyncPlayer(player)
	syncPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player) savePlayer(player, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)