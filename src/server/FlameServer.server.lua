local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Impedisce lo spawn prima che al giocatore venga assegnato il proprio slot
Players.CharacterAutoLoads = false

-- Crea subito Remotes prima di costruire il mondo così il client non va mai in attesa
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local function makeRemote(cls, name)
	local existing = remotes:FindFirstChild(name)
	if existing then return existing end
	local r = Instance.new(cls)
	r.Name = name
	r.Parent = remotes
	return r
end

local StateSync = makeRemote("RemoteEvent", "StateSync")
local ClickFlameEvent = makeRemote("RemoteEvent", "ClickFlame")
local BuyUpgrade = makeRemote("RemoteEvent", "BuyUpgrade")
local BuyWeapon = makeRemote("RemoteEvent", "BuyWeapon")
local BuyDefense = makeRemote("RemoteEvent", "BuyDefense")
local BuyAlbaPerk = makeRemote("RemoteEvent", "BuyAlbaPerk")
local UnlockAlbaZone = makeRemote("RemoteEvent", "UnlockAlbaZone")
local SummonWisp = makeRemote("RemoteEvent", "SummonWisp")
local FuseWisp = makeRemote("RemoteEvent", "FuseWisp")
local SyncGamePass = makeRemote("RemoteEvent", "SyncGamePass")
local TeleportHome = makeRemote("RemoteEvent", "TeleportHome")
local SetLanguage = makeRemote("RemoteEvent", "SetLanguage")
local CompleteTutorial = makeRemote("RemoteEvent", "CompleteTutorial")
local RedeemCode = makeRemote("RemoteFunction", "RedeemCode")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local Regno1Service = require(script.Parent:WaitForChild("Regno1Service"))
local ShadowDefenseService = require(script.Parent:WaitForChild("ShadowDefenseService"))

local built = WorldBuilder.Build()
local world = built.World
local plots = built.Plots

-- Disabilita eventuali SpawnLocation esterne (es. Baseplate/Lobby)
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("SpawnLocation") and (not world or not obj:IsDescendantOf(world)) then
		obj.Enabled = false
	end
end

-- Crea una SpawnLocation privata dentro ogni singolo Plot
for _, plot in ipairs(plots) do
	local lookTarget = plot.Origin + Vector3.new(0, 4.5, 0)
	local spawnPos = plot.SpawnPos or (plot.Origin + Vector3.new(0, 4.5, -28))
	local sp = Instance.new("SpawnLocation")
	sp.Name = "PlotSpawn_" .. tostring(plot.Index)
	sp.Anchored = true
	sp.CanCollide = false
	sp.Transparency = 1
	sp.Duration = 0
	sp.Neutral = false
	sp.Enabled = true
	sp.Size = Vector3.new(6, 1, 6)
	sp.CFrame = CFrame.lookAt(spawnPos, lookTarget)
	sp.Parent = plot.Folder or world
	plot.SpawnPad = sp
end

local mainStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("LastFlame_V6")
end)

local PlayerData = {}
local PlayerLoadedMap = {}
local PlayerPlotMap = {}
local ClickHeat = {}
local ActiveEmbers = {}

local function getLang(data)
	return (data and data.Language) or "en"
end

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

local function applyCharacterSpeed(player, walkSpeed)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and math.abs(hum.WalkSpeed - walkSpeed) > 0.1 then
		hum.WalkSpeed = walkSpeed
	end
end

local function teleportPlayerToPlot(player, plot)
	if not player or not plot then return end
	local char = player.Character
	if not char then return end
	local lookTarget = plot.Origin + Vector3.new(0, 4.5, 0)
	local spawnPos = plot.SpawnPos or (plot.Origin + Vector3.new(0, 4.5, -28))
	local targetCFrame = CFrame.lookAt(spawnPos, lookTarget)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = targetCFrame
	else
		char:PivotTo(targetCFrame)
	end
end

local function updatePlotSign(plot, ownerName, rankName, lang)
	if not plot or not plot.SignBoard then return end
	lang = lang or "en"
	for _, guiName in ipairs({ "SignGui", "SignGuiFront" }) do
		local sg = plot.SignBoard:FindFirstChild(guiName)
		if sg then
			local t = sg:FindFirstChild("OwnerTitle")
			local s = sg:FindFirstChild("OwnerSub")
			if ownerName then
				if t then t.Text = Localization.T(lang, "PLOT_OWNER_FMT", plot.Index, ownerName) end
				if s then s.Text = Localization.T(lang, "PLOT_RANK_FMT", rankName or Localization.Pick(lang, "Spark Bearer", "Portatore di Scintilla")) end
			else
				if t then t.Text = Localization.T(lang, "PLOT_FREE_FMT", plot.Index) end
				if s then s.Text = Localization.T(lang, "PLOT_WAIT") end
			end
		end
	end
end

local function updatePlotBrazierVisuals(plot, stats)
	if not plot or not plot.FlameCore then return end
	local rLvl = (stats and stats.RadiusLevel) or 1
	local col = (stats and stats.BrazierColor) or Color3.fromRGB(255, 145, 45)
	local scaleFactor = math.clamp(1.0 + (rLvl - 1) * 0.045, 1.0, 2.3)

	local corePos = plot.BaseFlamePos or plot.FlameCore.Position
	if plot.BaseFlameSize and plot.BaseFlamePos then
		plot.FlameCore.Size = plot.BaseFlameSize * scaleFactor
		corePos = plot.BaseFlamePos + Vector3.new(0, (scaleFactor - 1.0) * plot.BaseFlameSize.Y * 0.42, 0)
		plot.FlameCore.Position = corePos
	end
	plot.FlameCore.Color = col

	if plot.InnerFlameCore and plot.InnerFlameCore.Parent then
		plot.InnerFlameCore.Size = Vector3.new(2.7, 3.8, 2.7) * scaleFactor
		plot.InnerFlameCore.Position = corePos + Vector3.new(0, -0.35 * scaleFactor, 0)
		plot.InnerFlameCore.Color = col:Lerp(Color3.fromRGB(255, 250, 225), 0.65)
	end

	if plot.FlameTongues then
		for _, tInfo in ipairs(plot.FlameTongues) do
			if tInfo.Part and tInfo.Part.Parent then
				tInfo.Part.Color = col
				tInfo.Part.Size = tInfo.BaseSize * scaleFactor
				tInfo.Part.CFrame = CFrame.new(corePos + Vector3.new(math.cos(tInfo.Angle) * 1.15 * scaleFactor, 0.65 * scaleFactor, math.sin(tInfo.Angle) * 1.15 * scaleFactor))
					* CFrame.Angles(0, tInfo.Angle, math.rad(14))
			end
		end
	end

	if plot.RuneCrystals then
		for _, crys in ipairs(plot.RuneCrystals) do
			if crys and crys.Parent then
				crys.Color = col
			end
		end
	end

	if plot.FireEmitter and plot.FireEmitter.Parent then
		plot.FireEmitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, col:Lerp(Color3.fromRGB(255, 250, 220), 0.7)),
			ColorSequenceKeypoint.new(0.5, col),
			ColorSequenceKeypoint.new(1, col:Lerp(Color3.fromRGB(80, 20, 10), 0.35)),
		})
	end
	if plot.SparkEmitter and plot.SparkEmitter.Parent then
		plot.SparkEmitter.Color = ColorSequence.new(col:Lerp(Color3.fromRGB(255, 250, 220), 0.6), col)
	end

	for _, desc in ipairs(plot.FlameCore:GetChildren()) do
		if desc:IsA("PointLight") then
			desc.Color = col
			desc.Range = 60
			desc.Brightness = math.min(8.5, 3.6 + rLvl * 0.28)
		end
	end

	local skyAtt = plot.FlameCore:FindFirstChild("BrazierWideLightAtt")
	if not skyAtt then
		skyAtt = Instance.new("Attachment")
		skyAtt.Name = "BrazierWideLightAtt"
		skyAtt.Position = Vector3.new(0, 12, 0)
		skyAtt.Parent = plot.FlameCore
	end
	local skyLight = skyAtt:FindFirstChildOfClass("PointLight")
	if not skyLight then
		skyLight = Instance.new("PointLight")
		skyLight.Parent = skyAtt
	end
	skyLight.Color = col
	skyLight.Range = 60
	skyLight.Brightness = math.min(6.0, 2.8 + rLvl * 0.2)

	if plot.EmberRing then
		plot.EmberRing.Color = col
		local ringLight = plot.EmberRing:FindFirstChildOfClass("PointLight")
		if not ringLight then
			ringLight = Instance.new("PointLight")
			ringLight.Parent = plot.EmberRing
		end
		ringLight.Color = col
		ringLight.Range = 60
		ringLight.Brightness = math.min(5.0, 2.2 + rLvl * 0.15)
	end
end

local function updatePlotGroundButtons(plot, data)
	if not plot then return end
	local albaCount = (data and data.AlbaCount) or 0
	local discountLvl = EconomyEngine.GetLevel(data and data.AlbaPerks, "ap_discount")
	local lang = getLang(data)
	local lightUnit = Localization.T(lang, "LIGHT_UNIT")
	local ownedWeapons = (data and data.OwnedWeapons) or {}
	local upgrades = (data and data.Upgrades) or {}

	if plot.WeaponPadRefs then
		for _, wep in ipairs(GameConfig.Weapons) do
			local ref = plot.WeaponPadRefs[wep.Id]
			if ref then
				local owned = ownedWeapons[wep.Id] == true
				local reqAlba = wep.ReqAlba or 0
				local locked = (not owned) and (albaCount < reqAlba)
				local cost = GameConfig.GetWeaponCost(wep, albaCount, discountLvl)
				local wName = Localization.Pick(lang, wep.Name, wep.Name_it)
				local wTag = Localization.Pick(lang, wep.Tag, wep.Tag_it)

				if ref.TitleLabel then
					ref.TitleLabel.Text = (locked and "🔒 " or (wep.Icon .. " ")) .. wName
				end
				if ref.DescLabel then
					ref.DescLabel.Text = wTag
				end
				if ref.CostLabel then
					if owned then
						ref.CostLabel.Text = Localization.T(lang, "PAD_WEP_EQUIPPED")
					elseif locked then
						ref.CostLabel.Text = Localization.T(lang, "PAD_WEP_LOCKED_FMT", reqAlba)
					else
						ref.CostLabel.Text = wep.AlbaCost
							and string.format("%d 🌅", wep.AlbaCost)
							or (NumberFormat.Format(cost) .. " " .. lightUnit)
					end
				end
			end
		end
	end

	if plot.WispStationRefs then
		local ws = plot.WispStationRefs
		local wispsUnlocked = EconomyEngine.GetUpgradeLevel(data or {}, "u_unlock_wisps") > 0
		local unitCost = GameConfig.GetWispCost(albaCount, discountLvl)
		if ws.ShrineTitle then
			ws.ShrineTitle.Text = Localization.T(lang, "PAD_WISP_SHRINE_TITLE")
		end
		if ws.Pad1 then
			if ws.Pad1.TitleLabel then
				ws.Pad1.TitleLabel.Text = Localization.T(lang, "PAD_WISP_1_TITLE")
			end
			if ws.Pad1.DescLabel then
				ws.Pad1.DescLabel.Text = wispsUnlocked and Localization.T(lang, "PAD_WISP_READY_DESC") or Localization.T(lang, "PAD_WISP_LOCKED_DESC")
			end
			if ws.Pad1.CostLabel then
				ws.Pad1.CostLabel.Text = wispsUnlocked and (NumberFormat.Format(unitCost) .. " " .. lightUnit) or Localization.T(lang, "BTN_LOCKED")
			end
		end
		if ws.Pad5 then
			if ws.Pad5.TitleLabel then
				ws.Pad5.TitleLabel.Text = Localization.T(lang, "PAD_WISP_5_TITLE")
			end
			if ws.Pad5.DescLabel then
				ws.Pad5.DescLabel.Text = wispsUnlocked and Localization.T(lang, "PAD_WISP_READY_DESC") or Localization.T(lang, "PAD_WISP_LOCKED_DESC")
			end
			if ws.Pad5.CostLabel then
				ws.Pad5.CostLabel.Text = wispsUnlocked and (NumberFormat.Format(unitCost * 5) .. " " .. lightUnit) or Localization.T(lang, "BTN_LOCKED")
			end
		end
	end

	if plot.VictoryTitleLabel then
		plot.VictoryTitleLabel.Text = "🌅 " .. Localization.Pick(lang, GameConfig.VictoryButton.Name, GameConfig.VictoryButton.Name_it)
	end
	if plot.VictoryDescLabel then
		local reward = EconomyEngine.GetAlbaRewardPerRebirth(data)
		plot.VictoryDescLabel.Text = (lang == "it")
			and string.format("Prestigio (+%d Punti Alba)", reward)
			or string.format("Prestige (+%d Dawn Pts)", reward)
	end
	if plot.VictoryStatusLabel then
		local vCost = GameConfig.GetVictoryCost(albaCount, discountLvl)
		plot.VictoryStatusLabel.Text = NumberFormat.Format(vCost) .. " " .. lightUnit
	end
	local _ = upgrades
end

local function updatePlotAlbaZones(plot, data)
	if not plot or not plot.AlbaZoneRefs then return end
	local unlockedZones = (data and data.UnlockedAlbaZones) or {}
	local lang = getLang(data)

	for _, z in ipairs(GameConfig.AlbaZones) do
		local zRef = plot.AlbaZoneRefs[z.Id]
		if zRef then
			local isUnlocked = unlockedZones[z.Id] == true
			local zName = Localization.Pick(lang, z.Name, z.Name_it)

			zRef.Bridge.Transparency = isUnlocked and 0 or 0.65
			zRef.Bridge.CanCollide = isUnlocked
			zRef.BridgeTrim.Transparency = isUnlocked and 0.15 or 0.80

			zRef.GateBarrier.Transparency = isUnlocked and 1 or 0.35
			zRef.GateBarrier.CanCollide = not isUnlocked
			zRef.GatePad.Transparency = isUnlocked and 0.78 or 0.20
			if zRef.GatePadRim then
				zRef.GatePadRim.Transparency = isUnlocked and 0.85 or 0.06
			end

			if zRef.GateLabel then
				if isUnlocked then
					zRef.GateLabel.Text = Localization.T(lang, "ZONE_GATE_UNLOCKED_FMT", zName, z.LightMult or 1.0)
				else
					zRef.GateLabel.Text = Localization.T(lang, "ZONE_GATE_LOCKED_FMT", zName, z.Cost)
				end
			end

			zRef.IslandBase.Transparency = isUnlocked and 0 or 0.55
			zRef.IslandBase.CanCollide = isUnlocked
			zRef.IslandRim.Transparency = isUnlocked and 0.10 or 0.70
			zRef.IslandRim.CanCollide = false
			zRef.IslandInner.Transparency = isUnlocked and 0 or 0.55
			zRef.IslandInner.CanCollide = isUnlocked

			for _, pil in ipairs(zRef.Pillars) do
				pil.Transparency = isUnlocked and 0 or 0.55
				pil.CanCollide = isUnlocked
			end

			zRef.MonumentPedestal.Transparency = isUnlocked and 0 or 0.55
			zRef.MonumentPedestal.CanCollide = isUnlocked

			if zRef.MonumentParts then
				for _, mPart in ipairs(zRef.MonumentParts) do
					if mPart and mPart.Parent then
						if mPart.Name ~= "MonumentAuraCore" then
							mPart.Transparency = isUnlocked and 0.04 or 0.72
						end
						mPart.CanCollide = isUnlocked
					end
				end
			end

			if zRef.MonumentLights then
				for _, mLight in ipairs(zRef.MonumentLights) do
					if mLight and mLight.Parent then
						mLight.Enabled = isUnlocked
					end
				end
			end

			if zRef.ZoneTitle then
				if isUnlocked then
					zRef.ZoneTitle.Text = string.format("%s %s (x%.2f)", z.Icon, zName, z.LightMult or 1.0)
				else
					zRef.ZoneTitle.Text = string.format("🔒 %s (x%.2f)", zName, z.LightMult or 1.0)
				end
			end
		end
	end
end

local function assignPlotToPlayer(player, lang)
	for _, plot in ipairs(plots) do
		if plot.Owner == nil then
			plot.Owner = player
			PlayerPlotMap[player.UserId] = plot
			if plot.SpawnPad then
				player.RespawnLocation = plot.SpawnPad
			end
			if plot.Folder then
				plot.Folder:SetAttribute("OwnerUserId", player.UserId)
			end
			player:SetAttribute("PlotIndex", plot.Index)
			player:SetAttribute("PlotOrigin", plot.Origin)
			if plot.FlameTitle then
				plot.FlameTitle.Text = Localization.T(lang, "BRAZIER_OWNER_FMT", player.Name)
			end
			updatePlotSign(plot, player.Name, nil, lang)
			return plot
		end
	end
	return nil
end

local function releasePlotFromPlayer(player)
	local plot = PlayerPlotMap[player.UserId]
	if not plot then return end
	pcall(function()
		ShadowDefenseService.ClearPlot(plot.Index)
	end)
	if plot.DefensesFolder then
		plot.DefensesFolder:ClearAllChildren()
	end
	if plot.Folder then
		plot.Folder:SetAttribute("OwnerUserId", nil)
	end
	plot.Owner = nil
	PlayerPlotMap[player.UserId] = nil
	if plot.FlameTitle then
		plot.FlameTitle.Text = Localization.T("en", "BRAZIER_DEFAULT_FMT", plot.Index)
	end
	updatePlotSign(plot, nil, nil, "en")
	updatePlotBrazierVisuals(plot, nil)
	updatePlotGroundButtons(plot, nil)
	updatePlotAlbaZones(plot, nil)
end

local function syncPlayer(player, extra)
	local data = PlayerData[player.UserId]
	if not data then return end
	local lang = getLang(data)
	local buffMult, buffRem = Regno1Service.GetActiveBuff(player.UserId)
	local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(player.UserId), buffMult, data.HasDoubleLight)
	local rank = EconomyEngine.GetRank(stats.LightPercent)
	local localizedRank = Localization.Pick(lang, rank.Name, rank.Name_it)

	applyCharacterSpeed(player, stats.WalkSpeed)

	local plot = PlayerPlotMap[player.UserId]
	if plot then
		updatePlotSign(plot, player.Name, localizedRank, lang)
		if plot.FlameTitle then
			plot.FlameTitle.Text = Localization.T(lang, "BRAZIER_OWNER_FMT", player.Name)
		end
	end

	local eqIds = {}
	for _, w in ipairs(stats.EquippedWisps) do
		table.insert(eqIds, w.RawId)
	end
	player:SetAttribute("EquippedWisps", HttpService:JSONEncode(eqIds))
	player:SetAttribute("RadiusLevel", stats.RadiusLevel)

	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Points.Value = NumberFormat.Format(math.floor(data.Points))
		ls.Light.Value = tostring(stats.LightPercent) .. "%"
	end

	local wispCounts = {}
	for _, rawId in ipairs(data.Wisps) do
		wispCounts[rawId] = (wispCounts[rawId] or 0) + 1
	end

	local payload = {
		Language = lang,
		DataLoaded = (PlayerLoadedMap[player.UserId] == true),
		TutorialCompleted = (data.TutorialCompleted == true),
		PlotIndex = plot and plot.Index or 1,
		PlotOrigin = plot and plot.Origin or Vector3.zero,
		ShadowGraceRemaining = plot and ShadowDefenseService.GetGraceRemaining(plot.Index) or 0,
		ShadowGraceIsInitial = plot and ShadowDefenseService.IsInitialGrace(plot.Index) or false,
		Points = math.floor(data.Points),
		TotalPoints = math.floor(data.TotalPoints),
		TotalClicks = data.TotalClicks,
		AlbaPoints = data.AlbaPoints or 0,
		AlbaCount = data.AlbaCount or 0,
		AlbaRewardPerRebirth = stats.AlbaRewardPerRebirth,
		UnlockedZonesCount = stats.UnlockedZonesCount,
		UnlockedAlbaZones = data.UnlockedAlbaZones or {},
		AlbaPerks = data.AlbaPerks or {},
		OwnedWeapons = data.OwnedWeapons or {},
		Defenses = data.Defenses or {},
		HasDoubleLight = stats.HasDoubleLight,
		AllUpgradesCompleted = stats.AllUpgradesCompleted,
		CompletedUpgradesCount = stats.CompletedUpgradesCount,
		TotalUpgradesCount = stats.TotalUpgradesCount,
		ClickPower = stats.ClickPower,
		ClickCooldown = stats.ClickCooldown,
		PointsPerSec = stats.PointsPerSec,
		WalkSpeed = stats.WalkSpeed,
		Heat = stats.Heat,
		HeatMult = stats.HeatMult,
		LightPercent = stats.LightPercent,
		RankName = localizedRank,
		RadiusLevel = stats.RadiusLevel,
		BrazierColor = stats.BrazierColor,
		Altars = data.Altars,
		Upgrades = data.Upgrades,
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

Regno1Service.Init(remotes, plots, PlayerData, syncPlayer)
ShadowDefenseService.Init(world, remotes, plots, PlayerData, PlayerPlotMap, syncPlayer, function(plr, data)
	local buffMult = Regno1Service.GetActiveBuff(plr.UserId)
	return EconomyEngine.CalculateStats(data, getCurrentHeat(plr.UserId), buffMult, data.HasDoubleLight)
end)

SetLanguage.OnServerEvent:Connect(function(player, lang)
	local data = PlayerData[player.UserId]
	if not data then return end
	if lang ~= "en" and lang ~= "it" then return end
	data.Language = lang

	local plot = PlayerPlotMap[player.UserId]
	if plot then
		updatePlotGroundButtons(plot, data)
		updatePlotAlbaZones(plot, data)
	end
	pcall(function() ShadowDefenseService.SyncPlayerTools(player, data) end)
	pcall(function() Regno1Service.SyncPlayer(player) end)
	syncPlayer(player)
end)

CompleteTutorial.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	local wasCompleted = (data.TutorialCompleted == true)
	data.TutorialCompleted = true

	if not wasCompleted then
		local plot = PlayerPlotMap[player.UserId]
		if plot then
			ShadowDefenseService.StartGracePeriod(plot.Index, GameConfig.InitialShadowGraceSeconds or 180, true)
		end
		syncPlayer(player, {
			PopupText = Localization.T(getLang(data), "POP_TUTORIAL_DONE"),
		})
	else
		syncPlayer(player)
	end
end)

TeleportHome.OnServerEvent:Connect(function(player)
	local plot = PlayerPlotMap[player.UserId]
	if plot then
		teleportPlayerToPlot(player, plot)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	local passId = getDoubleLightPassId()
	if wasPurchased and passId > 0 and gamePassId == passId then
		local data = PlayerData[player.UserId]
		if data and not data.HasDoubleLight then
			data.HasDoubleLight = true
			syncPlayer(player, {
				SoundCue = "Prestige",
				Shockwave = true,
				PopupText = Localization.T(getLang(data), "POP_PASS_ACTIVE"),
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

local LastClickTime = {}
local function handleFlameClick(player)
	local data = PlayerData[player.UserId]
	if not data then return end

	local plot = PlayerPlotMap[player.UserId]
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if plot and hrp and (hrp.Position - plot.FlameCore.Position).Magnitude > 85 then
		return
	end

	local curHeat = getCurrentHeat(player.UserId)
	local buffMult = Regno1Service.GetActiveBuff(player.UserId)
	local preStats = EconomyEngine.CalculateStats(data, curHeat, buffMult, data.HasDoubleLight)

	local now = os.clock()
	local requiredCooldown = math.max(0.045, (preStats.ClickCooldown or 0.50) - 0.015)
	if LastClickTime[player.UserId] and (now - LastClickTime[player.UserId] < requiredCooldown) then
		return
	end
	LastClickTime[player.UserId] = now

	local newHeat = math.min(1.0, curHeat + 0.08)
	ClickHeat[player.UserId] = { Heat = newHeat, LastClick = now }

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

ClickFlameEvent.OnServerEvent:Connect(handleFlameClick)

local WeaponPadCooldown = {}
local WispPadCooldown = {}
local VictoryCooldown = {}
local ZonePadCooldown = {}

local function handleWeaponPurchaseOrEquip(player, wepId, equipIfOwned)
	local data = PlayerData[player.UserId]
	if not data or type(wepId) ~= "string" then return end

	local target
	for _, w in ipairs(GameConfig.Weapons) do
		if w.Id == wepId then target = w; break end
	end
	if not target then return end

	local lang = getLang(data)
	local wName = Localization.Pick(lang, target.Name, target.Name_it)

	if data.OwnedWeapons[target.Id] == true then
		if equipIfOwned then
			pcall(function() ShadowDefenseService.EquipWeaponTool(player, target.Id) end)
			syncPlayer(player, {
				SoundCue = "Click",
				PopupText = Localization.T(lang, "POP_WEAPON_EQUIPPED", wName),
			})
		end
		return
	end

	local albaCount = data.AlbaCount or 0
	if target.ReqAlba and albaCount < target.ReqAlba then
		local reqMsg = lang == "it"
			and string.format("Serve almeno Rinascita %d dell'Alba!", target.ReqAlba)
			or string.format("Requires at least Dawn Rebirth %d!", target.ReqAlba)
		syncPlayer(player, { PopupText = reqMsg })
		return
	end

	local albaCost = target.AlbaCost or 0
	if (data.AlbaPoints or 0) < albaCost then
		local albaMsg = lang == "it"
			and string.format("Servono %d Punti Alba!", albaCost)
			or string.format("Requires %d Dawn Points!", albaCost)
		syncPlayer(player, { PopupText = albaMsg })
		return
	end

	local discountLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_discount")
	local cost = GameConfig.GetWeaponCost(target, albaCount, discountLvl)
	if data.Points >= cost then
		data.Points -= cost
		data.AlbaPoints = (data.AlbaPoints or 0) - albaCost
		data.OwnedWeapons[target.Id] = true
		pcall(function() ShadowDefenseService.SyncPlayerTools(player, data) end)
		pcall(function() ShadowDefenseService.EquipWeaponTool(player, target.Id) end)

		local plot = PlayerPlotMap[player.UserId]
		if plot then
			updatePlotGroundButtons(plot, data)
		end

		syncPlayer(player, {
			SoundCue = "Upgrade",
			PopupText = Localization.T(lang, "POP_WEAPON_BOUGHT", wName),
		})
	else
		syncPlayer(player, {
			PopupText = Localization.T(lang, "POP_NEED_LIGHT", NumberFormat.Format(cost)),
		})
	end
end

local function handleSummonWisp(player, amount)
	local data = PlayerData[player.UserId]
	if not data then return end
	local lang = getLang(data)

	if EconomyEngine.GetUpgradeLevel(data, "u_unlock_wisps") <= 0 then
		syncPlayer(player, { PopupText = Localization.T(lang, "POP_WISPS_LOCKED") })
		return
	end

	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local discountLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_discount")
	local unitCost = GameConfig.GetWispCost(data.AlbaCount or 0, discountLvl)
	local totalCost = unitCost * amount
	if data.Points < totalCost then
		syncPlayer(player, { PopupText = Localization.T(lang, "POP_NEED_LIGHT", NumberFormat.Format(totalCost)) })
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
	local bestName = Localization.Pick(lang, best.Name, best.Name_it)
	syncPlayer(player, {
		SoundCue = "Upgrade",
		PopupText = amount == 1 and Localization.T(lang, "POP_WISP_1", bestName) or Localization.T(lang, "POP_WISP_5", amount, bestName),
	})
end

for _, plot in ipairs(plots) do
	if plot.FlameHitbox then
		local cd = plot.FlameHitbox:FindFirstChildOfClass("ClickDetector") or Instance.new("ClickDetector")
		cd.MaxActivationDistance = 75
		cd.Parent = plot.FlameHitbox
		cd.MouseClick:Connect(function(plr)
			if plot.Owner == plr then
				handleFlameClick(plr)
			end
		end)
	end

	if plot.WeaponPadRefs then
		for _, wep in ipairs(GameConfig.Weapons) do
			local ref = plot.WeaponPadRefs[wep.Id]
			if ref and ref.Pad then
				ref.Pad.Touched:Connect(function(hit)
					local plr = Players:GetPlayerFromCharacter(hit.Parent)
					if not plr or plot.Owner ~= plr then return end
					local now = os.clock()
					local key = plr.UserId .. "_" .. wep.Id
					if WeaponPadCooldown[key] and (now - WeaponPadCooldown[key] < 1.0) then
						return
					end
					WeaponPadCooldown[key] = now
					handleWeaponPurchaseOrEquip(plr, wep.Id, true)
				end)
			end
		end
	end

	if plot.WispStationRefs then
		local function bindWispPad(padObj, amount)
			if not padObj or not padObj.Pad then return end
			padObj.Pad.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if not plr or plot.Owner ~= plr then return end
				local now = os.clock()
				local key = plr.UserId .. "_wisp_" .. tostring(amount)
				if WispPadCooldown[key] and (now - WispPadCooldown[key] < 0.9) then
					return
				end
				WispPadCooldown[key] = now
				handleSummonWisp(plr, amount)
			end)
		end
		bindWispPad(plot.WispStationRefs.Pad1, 1)
		bindWispPad(plot.WispStationRefs.Pad5, 5)
	end

	for _, z in ipairs(GameConfig.AlbaZones) do
		local zRef = plot.AlbaZoneRefs and plot.AlbaZoneRefs[z.Id]
		if zRef and zRef.GatePad then
			zRef.GatePad.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if not plr or plot.Owner ~= plr then return end
				local data = PlayerData[plr.UserId]
				if not data or data.UnlockedAlbaZones[z.Id] == true then return end

				local now = os.clock()
				local key = plr.UserId .. "_" .. z.Id
				if ZonePadCooldown[key] and (now - ZonePadCooldown[key] < 1.5) then
					return
				end
				ZonePadCooldown[key] = now

				local lang = getLang(data)
				if (data.AlbaPoints or 0) >= z.Cost then
					data.AlbaPoints -= z.Cost
					data.UnlockedAlbaZones[z.Id] = true
					updatePlotAlbaZones(plot, data)
					syncPlayer(plr, {
						SoundCue = "Prestige",
						Shockwave = true,
						PopupText = Localization.T(lang, "POP_ZONE_UNLOCK", Localization.Pick(lang, z.Name, z.Name_it)),
					})
				else
					syncPlayer(plr, {
						PopupText = Localization.T(lang, "POP_NEED_DAWN_PTS", z.Cost),
					})
				end
			end)
		end
	end

	if plot.VictoryPad then
		plot.VictoryPad.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if not plr or plot.Owner ~= plr then return end

			local data = PlayerData[plr.UserId]
			if not data then return end

			local allDone = EconomyEngine.GetUpgradeCompletion(data)
			if not allDone then
				return
			end

			local now = os.clock()
			if VictoryCooldown[plr.UserId] and (now - VictoryCooldown[plr.UserId] < 2.2) then
				return
			end
			VictoryCooldown[plr.UserId] = now

			local lang = getLang(data)
			local discountLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_discount")
			local vCost = GameConfig.GetVictoryCost(data.AlbaCount or 0, discountLvl)
			if data.Points < vCost then
				syncPlayer(plr, {
					PopupText = Localization.T(lang, "POP_NEED_FINAL", NumberFormat.Format(vCost)),
				})
				return
			end

			local albaGained = EconomyEngine.GetAlbaRewardPerRebirth(data)
			data.AlbaPoints = (data.AlbaPoints or 0) + albaGained
			data.AlbaCount = (data.AlbaCount or 0) + 1

			local startLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_start")
			data.Points = startLvl > 0 and (10000 * startLvl) or 0
			data.Altars = {}
			data.Upgrades = startLvl > 0 and { alt_click = 5 * startLvl } or {}

			data.OwnedWeapons = {}
			data.Defenses = {}

			ShadowDefenseService.StartGracePeriod(plot.Index, GameConfig.RebirthShadowGraceSeconds or 120, false)

			local freshStats = EconomyEngine.CalculateStats(data, 0, 1, data.HasDoubleLight)
			updatePlotBrazierVisuals(plot, freshStats)
			updatePlotGroundButtons(plot, data)
			updatePlotAlbaZones(plot, data)
			pcall(function() ShadowDefenseService.RebuildPlotDefenses(plot, data) end)
			pcall(function() ShadowDefenseService.SyncPlayerTools(plr, data) end)
			pcall(function() Regno1Service.SyncPlayer(plr) end)

			syncPlayer(plr, {
				VictoryTriggered = true,
				AlbaGained = albaGained,
				SoundCue = "Prestige",
				Shockwave = true,
				PopupText = Localization.T(lang, "POP_DAWN_DONE", albaGained),
			})
		end)
	end
end

BuyUpgrade.OnServerEvent:Connect(function(player, upgId)
	local data = PlayerData[player.UserId]
	if not data or type(upgId) ~= "string" then return end
	local target
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Id == upgId then target = u; break end
	end
	if not target then return end
	if not EconomyEngine.IsUpgradeUnlocked(data, target) then return end

	local cur = EconomyEngine.GetLevel(data.Upgrades, target.Id)
	if cur >= target.MaxLevel then return end

	local lang = getLang(data)
	local discountLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_discount")
	local cost = GameConfig.GetUpgradeCost(target, cur, data.AlbaCount or 0, discountLvl)
	if data.Points >= cost then
		local wasAllDone = EconomyEngine.GetUpgradeCompletion(data)
		data.Points -= cost
		local nextLvl = cur + 1
		data.Upgrades[target.Id] = nextLvl

		local newlyUnlocked = {}
		if nextLvl == 1 then
			for _, other in ipairs(GameConfig.Upgrades) do
				if other.ReqId == target.Id and (other.ReqLvl or 1) == 1 then
					table.insert(newlyUnlocked, Localization.Pick(lang, other.Name, other.Name_it))
				end
			end
		end

		local plot = PlayerPlotMap[player.UserId]
		if plot then
			if target.RadiusBonus ~= nil or target.BrazierColor ~= nil then
				local buffMult = Regno1Service.GetActiveBuff(player.UserId)
				local freshStats = EconomyEngine.CalculateStats(data, getCurrentHeat(player.UserId), buffMult, data.HasDoubleLight)
				updatePlotBrazierVisuals(plot, freshStats)
			end
			if target.Id == "u_unlock_wisps" then
				updatePlotGroundButtons(plot, data)
			end
		end

		local nowAllDone = EconomyEngine.GetUpgradeCompletion(data)
		local popup = nil
		local soundCue = "Upgrade"
		if (not wasAllDone) and nowAllDone then
			popup = Localization.T(lang, "POP_ALL_MAXED")
			if plot then
				ShadowDefenseService.ClearShadowsForPlot(plot.Index)
			end
		elseif target.IsColorButton then
			soundCue = "Prestige"
			popup = Localization.T(
				lang,
				"POP_COLOR_UNLOCKED",
				Localization.Pick(lang, target.Name, target.Name_it),
				Localization.Pick(lang, target.Tag, target.Tag_it) or ""
			)
		elseif target.Id == "u_braziers" then
			popup = Localization.T(lang, "POP_R1_UNLOCKED")
			pcall(function() Regno1Service.SyncPlayer(player) end)
		elseif #newlyUnlocked > 0 then
			popup = Localization.T(lang, "POP_NEW_UNLOCK", table.concat(newlyUnlocked, " & "))
		end

		local doShockwave = (not wasAllDone and nowAllDone)
			or (#newlyUnlocked > 0)
			or (target.IsColorButton == true)
			or (target.RadiusBonus ~= nil)

		syncPlayer(player, {
			SoundCue = soundCue,
			Shockwave = doShockwave,
			PopupText = popup,
		})
	end
end)

BuyWeapon.OnServerEvent:Connect(function(player, wepId)
	handleWeaponPurchaseOrEquip(player, wepId, false)
end)

BuyDefense.OnServerEvent:Connect(function(player, defId)
	local data = PlayerData[player.UserId]
	if not data or type(defId) ~= "string" then return end

	local target
	for _, d in ipairs(GameConfig.Defenses) do
		if d.Id == defId then target = d; break end
	end
	if not target then return end

	if target.ReqDefenseId then
		local reqLvl = EconomyEngine.GetLevel(data.Defenses, target.ReqDefenseId)
		if reqLvl < (target.ReqDefenseLvl or 1) then
			return
		end
	end

	local cur = EconomyEngine.GetLevel(data.Defenses, target.Id)
	if cur >= target.MaxLevel then return end

	local lang = getLang(data)
	local discountLvl = EconomyEngine.GetLevel(data.AlbaPerks, "ap_discount")
	local costInfo = GameConfig.GetDefenseCost(target, cur, data.AlbaCount or 0, discountLvl)
	local needPoints = costInfo.Points or 0
	local needAlba = costInfo.Alba or 0

	if (data.AlbaPoints or 0) < needAlba then
		local albaMsg = lang == "it"
			and string.format("Servono %d Punti Alba!", needAlba)
			or string.format("Requires %d Dawn Points!", needAlba)
		syncPlayer(player, { PopupText = albaMsg })
		return
	end

	if data.Points >= needPoints then
		data.Points -= needPoints
		if needAlba > 0 then
			data.AlbaPoints = (data.AlbaPoints or 0) - needAlba
		end
		local nextLvl = cur + 1
		data.Defenses[target.Id] = nextLvl

		local plot = PlayerPlotMap[player.UserId]
		if plot then
			pcall(function() ShadowDefenseService.RebuildPlotDefenses(plot, data) end)
		end

		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = true,
			PopupText = Localization.T(lang, "POP_DEFENSE_BUILT", Localization.Pick(lang, target.Name, target.Name_it), nextLvl),
		})
	else
		syncPlayer(player, {
			PopupText = Localization.T(lang, "POP_NEED_LIGHT", NumberFormat.Format(needPoints)),
		})
	end
end)

BuyAlbaPerk.OnServerEvent:Connect(function(player, perkId)
	local data = PlayerData[player.UserId]
	if not data or type(perkId) ~= "string" then return end

	local target
	for _, p in ipairs(GameConfig.AlbaPerks) do
		if p.Id == perkId then target = p; break end
	end
	if not target then return end

	local cur = EconomyEngine.GetLevel(data.AlbaPerks, target.Id)
	if cur >= target.MaxLevel then return end

	local lang = getLang(data)
	local cost = math.floor(target.Cost * (target.CostMult ^ cur))
	if (data.AlbaPoints or 0) >= cost then
		data.AlbaPoints -= cost
		data.AlbaPerks[target.Id] = cur + 1

		local plot = PlayerPlotMap[player.UserId]
		if plot then
			updatePlotGroundButtons(plot, data)
		end

		syncPlayer(player, {
			SoundCue = "Prestige",
			PopupText = Localization.T(lang, "POP_DAWN_PERK", Localization.Pick(lang, target.Name, target.Name_it)),
		})
	end
end)

UnlockAlbaZone.OnServerEvent:Connect(function(player, zoneId)
	local data = PlayerData[player.UserId]
	if not data or type(zoneId) ~= "string" then return end

	local target
	for _, z in ipairs(GameConfig.AlbaZones) do
		if z.Id == zoneId then target = z; break end
	end
	if not target then return end

	if data.UnlockedAlbaZones[target.Id] == true then return end
	local lang = getLang(data)

	if (data.AlbaPoints or 0) >= target.Cost then
		data.AlbaPoints -= target.Cost
		data.UnlockedAlbaZones[target.Id] = true

		local plot = PlayerPlotMap[player.UserId]
		if plot then
			updatePlotAlbaZones(plot, data)
		end

		syncPlayer(player, {
			SoundCue = "Prestige",
			Shockwave = true,
			PopupText = Localization.T(lang, "POP_ZONE_UNLOCK", Localization.Pick(lang, z.Name, z.Name_it)),
		})
	else
		syncPlayer(player, {
			PopupText = Localization.T(lang, "POP_NEED_DAWN_PTS", target.Cost),
		})
	end
end)

SummonWisp.OnServerEvent:Connect(function(player, amount)
	handleSummonWisp(player, amount)
end)

FuseWisp.OnServerEvent:Connect(function(player, baseWispId)
	local data = PlayerData[player.UserId]
	if not data or type(baseWispId) ~= "string" then return end
	local lang = getLang(data)

	local idxs = {}
	for i, rawId in ipairs(data.Wisps) do
		if rawId == baseWispId then
			table.insert(idxs, i)
			if #idxs == 3 then break end
		end
	end
	if #idxs < 3 then
		syncPlayer(player, { PopupText = Localization.T(lang, "POP_NEED_3_WISPS") })
		return
	end

	for i = 3, 1, -1 do
		table.remove(data.Wisps, idxs[i])
	end
	table.insert(data.Wisps, baseWispId .. "_rad")

	local cfg = EconomyEngine.ParseWispId(baseWispId)
	local wName = cfg and Localization.Pick(lang, cfg.Name, cfg.Name_it) or "Wisp"
	syncPlayer(player, {
		SoundCue = "Prestige",
		Shockwave = true,
		PopupText = Localization.T(lang, "POP_FORGE_OK", wName),
	})
end)

RedeemCode.OnServerInvoke = function(player, raw)
	local data = PlayerData[player.UserId]
	if not data or type(raw) ~= "string" then return false, "Error" end
	local lang = getLang(data)
	local code = string.upper(string.gsub(raw, "%s+", ""))
	if data.UsedCodes[code] then return false, Localization.T(lang, "CODE_USED") end
	local rew = GameConfig.PromoCodes[code]
	if not rew then return false, Localization.T(lang, "CODE_INVALID") end
	data.UsedCodes[code] = true
	data.Points += rew.Points
	data.TotalPoints += rew.Points
	local msg = Localization.Pick(lang, rew.Msg, rew.Msg_it)
	syncPlayer(player, { SoundCue = "Upgrade", PopupText = msg })
	return true, msg
end

local function spawnWanderingEmberForPlot(plot)
	if not plot or not plot.Owner then return end
	local offset = Vector3.new(math.random(-36, 36), 2.5, math.random(-36, 36))
	local ember = Instance.new("Part")
	ember.Name = "WanderingEmber"
	ember.Anchored = true
	ember.Shape = Enum.PartType.Ball
	ember.Material = Enum.Material.Neon
	ember.CanCollide = false
	ember.Size = Vector3.new(2.2, 2.2, 2.2)
	ember.Position = plot.Origin + offset
	ember.Color = Color3.fromRGB(255, 200, 75)
	ember.Parent = world

	local l = Instance.new("PointLight", ember)
	l.Color = Color3.fromRGB(255, 190, 60)
	l.Range = 8
	l.Brightness = 1.1

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
			local gain = math.max(10, math.floor(stats.ClickPower * 8))
			data.Points += gain
			data.TotalPoints += gain
			syncPlayer(plr, {
				SoundCue = "Click",
				PopupText = Localization.T(getLang(data), "POP_EMBER", NumberFormat.Format(gain)),
			})
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
		task.wait(11)
		for _, plot in ipairs(plots) do
			if plot.Owner then
				spawnWanderingEmberForPlot(plot)
			end
		end
	end
end)

local syncAccumulator = 0
task.spawn(function()
	while true do
		task.wait(0.1)
		pcall(function() Regno1Service.Tick(0.1) end)
		pcall(function() ShadowDefenseService.Tick(0.1, ClickHeat) end)

		syncAccumulator += 0.1
		local doPassiveSync = syncAccumulator >= 0.25
		if doPassiveSync then
			syncAccumulator = 0
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

				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and EconomyEngine.GetLevel(data.Upgrades, "u_ember_mag") > 0 then
					for emb in pairs(ActiveEmbers) do
						if emb and emb.Parent and (hrp.Position - emb.Position).Magnitude < 38 then
							emb.Position += (hrp.Position - emb.Position).Unit * 2.4
						end
					end
				end

				if doPassiveSync then
					syncPlayer(plr)
				end
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
	if removeCache then
		PlayerData[player.UserId] = nil
		PlayerLoadedMap[player.UserId] = nil
		releasePlotFromPlayer(player)
	end
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do
			savePlayer(plr, false)
		end
	end
end)

local function onPlayerAdded(player)
	if PlayerData[player.UserId] then return end

	local ls = Instance.new("Folder", player); ls.Name = "leaderstats"
	local p = Instance.new("StringValue", ls); p.Name = "Points"; p.Value = "0"
	local l = Instance.new("StringValue", ls); l.Name = "Light"; l.Value = "4%"

	-- 1. Assegna subito uno slot libero e imposta lo spawn
	local assignedPlot = assignPlotToPlayer(player, "en")
	local data = EconomyEngine.DefaultData()
	PlayerLoadedMap[player.UserId] = false
	PlayerData[player.UserId] = data

	if assignedPlot then
		local initStats = EconomyEngine.CalculateStats(data, 0, 1, false)
		pcall(function() updatePlotBrazierVisuals(assignedPlot, initStats) end)
		pcall(function() updatePlotGroundButtons(assignedPlot, data) end)
		pcall(function() updatePlotAlbaZones(assignedPlot, data) end)
	end

	-- 2. Gestisce lo spawn e l'eventuale respawn automatico direttamente nello slot
	player.CharacterAdded:Connect(function(char)
		task.defer(function()
			if not char or not char.Parent then return end
			local curData = PlayerData[player.UserId] or data
			local stats = EconomyEngine.CalculateStats(curData, 0, 1, curData.HasDoubleLight)
			applyCharacterSpeed(player, stats.WalkSpeed)
			pcall(function() ShadowDefenseService.SyncPlayerTools(player, curData) end)
			if assignedPlot then
				teleportPlayerToPlot(player, assignedPlot)
			end
		end)

		local hum = char:WaitForChild("Humanoid", 5)
		if hum then
			hum.Died:Connect(function()
				task.wait(2)
				if player.Parent then
					player:LoadCharacter()
				end
			end)
		end
	end)

	-- 3. Spawna subito il personaggio direttamente nello slot
	player:LoadCharacter()
	syncPlayer(player)

	-- 4. Carica eventuali salvataggi in background senza bloccare l'ingresso
	task.spawn(function()
		if mainStore then
			local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
			if ok and type(saved) == "table" and player.Parent then
				for k, v in pairs(saved) do data[k] = v end
			end
		end

		if not player.Parent then return end
		if data.Language ~= "en" and data.Language ~= "it" then data.Language = "en" end
		if type(data.AlbaPerks) ~= "table" then data.AlbaPerks = {} end
		if type(data.UnlockedAlbaZones) ~= "table" then data.UnlockedAlbaZones = {} end
		if type(data.OwnedWeapons) ~= "table" then data.OwnedWeapons = {} end
		if type(data.Defenses) ~= "table" then data.Defenses = {} end
		if type(data.Regno1) ~= "table" then
			data.Regno1 = { Completed = false, Completions = 0, BestTime = nil }
		end
		data.HasDoubleLight = (data.HasDoubleLight == true)
		data.TutorialCompleted = (data.TutorialCompleted == true)
		PlayerLoadedMap[player.UserId] = true
		EconomyEngine.MigrateData(data)

		verifyDoubleLightOwnership(player, data)

		if assignedPlot then
			if data.TutorialCompleted == true and ShadowDefenseService.GetGraceRemaining(assignedPlot.Index) <= 0 then
				pcall(function()
					ShadowDefenseService.StartGracePeriod(assignedPlot.Index, GameConfig.InitialShadowGraceSeconds or 180, true)
				end)
			end
			local loadedStats = EconomyEngine.CalculateStats(data, 0, 1, data.HasDoubleLight)
			pcall(function() updatePlotBrazierVisuals(assignedPlot, loadedStats) end)
			pcall(function() updatePlotGroundButtons(assignedPlot, data) end)
			pcall(function() updatePlotAlbaZones(assignedPlot, data) end)
			pcall(function() ShadowDefenseService.RebuildPlotDefenses(assignedPlot, data) end)
			pcall(function() ShadowDefenseService.SyncPlayerTools(player, data) end)
		end

		pcall(function() Regno1Service.SyncPlayer(player) end)
		syncPlayer(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, plr)
end

Players.PlayerRemoving:Connect(function(player) savePlayer(player, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)
