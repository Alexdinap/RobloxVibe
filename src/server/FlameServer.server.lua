local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

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

local mainStore
pcall(function()
	mainStore = DataStoreService:GetDataStore("LastFlame_V6")
end)

local PlayerData = {}
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
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local lookTarget = plot.Origin + Vector3.new(0, 4.5, 0)
		hrp.CFrame = CFrame.lookAt(plot.SpawnPos, lookTarget)
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

	plot.FlameCore.Size = plot.BaseFlameSize * scaleFactor
	plot.FlameCore.Position = plot.BaseFlamePos + Vector3.new(0, (scaleFactor - 1.0) * plot.BaseFlameSize.Y * 0.42, 0)
	plot.FlameCore.Color = col

	for _, desc in ipairs(plot.FlameCore:GetChildren()) do
		if desc:IsA("PointLight") then
			desc.Color = col
			desc.Range = 60
			desc.Brightness = math.min(8.5, 3.6 + rLvl * 0.28)
		elseif desc:IsA("ParticleEmitter") then
			desc.Color = ColorSequence.new(col)
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
	if not plot or not plot.AltarsFolder then return end
	local altars = (data and data.Altars) or {}
	local albaCount = (data and data.AlbaCount) or 0
	local lang = getLang(data)
	local lightUnit = Localization.T(lang, "LIGHT_UNIT")

	for _, alt in ipairs(GameConfig.Altars) do
		local pad = plot.AltarsFolder:FindFirstChild(alt.Id)
		if pad then
			local maxLvl = alt.MaxLevel or 1
			local lvl = EconomyEngine.GetLevel(altars, alt.Id)
			local maxed = lvl >= maxLvl
			local cost = GameConfig.GetAltarCost(alt, lvl, albaCount)
			local altName = Localization.Pick(lang, alt.Name, alt.Name_it)
			local altDesc = Localization.Pick(lang, alt.Desc, alt.Desc_it)
			local benefit = Localization.Pick(lang, alt.BenefitTag, alt.BenefitTag_it)

			local bbg = pad:FindFirstChildOfClass("BillboardGui")
			local container = bbg and (bbg:FindFirstChildOfClass("Frame") or bbg)
			if container then
				local t1 = container:FindFirstChild("TitleLabel")
				local td = container:FindFirstChild("DescLabel")
				local t2 = container:FindFirstChild("CostLabel")

				if td then
					td.Text = altDesc
				end

				if alt.IsColorButton then
					if t1 then
						t1.Text = maxed and ("✅ " .. altName) or ("🎨 " .. altName)
					end
					if t2 then
						t2.Text = maxed and (Localization.T(lang, "ACTIVE_GROUND_PAD") .. " (" .. (benefit or "") .. ")") or (NumberFormat.Format(cost) .. " " .. lightUnit .. " • " .. (benefit or ""))
					end
				else
					if t1 then
						t1.Text = string.format("%s [%d/%d]", altName, lvl, maxLvl)
					end
					if t2 then
						t2.Text = maxed and Localization.T(lang, "MAX_GROUND_PAD") or (NumberFormat.Format(cost) .. " " .. lightUnit)
					end
				end
			end
		end
	end

	if plot.VictoryTitleLabel then
		plot.VictoryTitleLabel.Text = "🌅 " .. Localization.Pick(lang, GameConfig.VictoryButton.Name, GameConfig.VictoryButton.Name_it)
	end
	if plot.VictoryDescLabel then
		plot.VictoryDescLabel.Text = Localization.Pick(lang, GameConfig.VictoryButton.Desc, GameConfig.VictoryButton.Desc_it)
	end
	if plot.VictoryStatusLabel then
		local vCost = GameConfig.GetVictoryCost(albaCount)
		local reward = EconomyEngine.GetAlbaRewardPerRebirth(data)
		plot.VictoryStatusLabel.Text = Localization.T(lang, "FINAL_BTN_COST_FMT", NumberFormat.Format(vCost), reward)
	end
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
	ShadowDefenseService.ClearPlot(plot.Index)
	if plot.DefensesFolder then
		plot.DefensesFolder:ClearAllChildren()
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
	ShadowDefenseService.SyncPlayerTools(player, data)
	Regno1Service.SyncPlayer(player)
	syncPlayer(player)
end)

CompleteTutorial.OnServerEvent:Connect(function(player)
	local data = PlayerData[player.UserId]
	if not data then return end
	if data.TutorialCompleted then return end

	data.TutorialCompleted = true
	local plot = PlayerPlotMap[player.UserId]
	if plot then
		ShadowDefenseService.StartGracePeriod(plot.Index, GameConfig.InitialShadowGraceSeconds or 180, true)
	end

	syncPlayer(player, {
		PopupText = Localization.T(getLang(data), "POP_TUTORIAL_DONE"),
	})
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

local TouchingByPlot = {}
local ColorNotifyCooldown = {}
local VictoryCooldown = {}
local ZonePadCooldown = {}

for _, plot in ipairs(plots) do
	if plot.FlameHitbox then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 75
		cd.Parent = plot.FlameHitbox
	end

	TouchingByPlot[plot.Index] = {}
	for _, alt in ipairs(GameConfig.Altars) do
		local pad = plot.AltarsFolder:FindFirstChild(alt.Id)
		if pad then
			TouchingByPlot[plot.Index][alt.Id] = false
			pad.Touched:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if not plr or plot.Owner ~= plr then return end
				TouchingByPlot[plot.Index][alt.Id] = true

				if alt.IsColorButton then
					local data = PlayerData[plr.UserId]
					if data and EconomyEngine.GetLevel(data.Altars, alt.Id) >= 1 then
						local now = os.clock()
						local key = plr.UserId .. "_" .. alt.Id
						if not ColorNotifyCooldown[key] or (now - ColorNotifyCooldown[key] > 2.5) then
							ColorNotifyCooldown[key] = now
							local lang = getLang(data)
							syncPlayer(plr, {
								PopupText = Localization.T(
									lang,
									"POP_COLOR_ALREADY",
									Localization.Pick(lang, alt.Name, alt.Name_it),
									Localization.Pick(lang, alt.BenefitTag, alt.BenefitTag_it) or ""
								),
							})
						end
					end
				end
			end)
			pad.TouchEnded:Connect(function(hit)
				local plr = Players:GetPlayerFromCharacter(hit.Parent)
				if plr and plot.Owner == plr then
					TouchingByPlot[plot.Index][alt.Id] = false
				end
			end)
		end
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
			local vCost = GameConfig.GetVictoryCost(data.AlbaCount or 0)
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
			data.Altars = startLvl > 0 and { alt_click = 5 * startLvl } or {}
			data.Upgrades = { u_unlock_alba = 1 }

			data.OwnedWeapons = {}
			data.Defenses = {}

			ShadowDefenseService.StartGracePeriod(plot.Index, GameConfig.RebirthShadowGraceSeconds or 120, false)

			for _, alt in ipairs(GameConfig.Altars) do
				TouchingByPlot[plot.Index][alt.Id] = false
			end

			local freshStats = EconomyEngine.CalculateStats(data, 0, 1, data.HasDoubleLight)
			updatePlotBrazierVisuals(plot, freshStats)
			updatePlotGroundButtons(plot, data)
			updatePlotAlbaZones(plot, data)
			ShadowDefenseService.RebuildPlotDefenses(plot, data)
			ShadowDefenseService.SyncPlayerTools(plr, data)
			Regno1Service.SyncPlayer(plr)

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

task.spawn(function()
	while true do
		task.wait(0.14)
		for _, plot in ipairs(plots) do
			local owner = plot.Owner
			local data = owner and owner.Parent and PlayerData[owner.UserId]
			if data then
				local lang = getLang(data)
				local albaCount = data.AlbaCount or 0
				local wasAllDone = EconomyEngine.GetUpgradeCompletion(data)
				local boughtSomething = false
				local triggerShockwave = false
				local customPopup = nil
				local soundCue = "Buy"

				for _, alt in ipairs(GameConfig.Altars) do
					if TouchingByPlot[plot.Index][alt.Id] then
						local maxLvl = alt.MaxLevel or 1
						local lvl = EconomyEngine.GetLevel(data.Altars, alt.Id)
						if lvl < maxLvl then
							local cost = GameConfig.GetAltarCost(alt, lvl, albaCount)
							if data.Points >= cost then
								data.Points -= cost
								data.Altars[alt.Id] = lvl + 1
								boughtSomething = true
								if alt.IsColorButton then
									TouchingByPlot[plot.Index][alt.Id] = false
									triggerShockwave = true
									soundCue = "Prestige"
									customPopup = Localization.T(
										lang,
										"POP_COLOR_UNLOCKED",
										Localization.Pick(lang, alt.Name, alt.Name_it),
										Localization.Pick(lang, alt.BenefitTag, alt.BenefitTag_it) or ""
									)
								elseif alt.RadiusBonus ~= nil then
									triggerShockwave = true
								end
							end
						end
					end
				end

				if boughtSomething then
					local buffMult = Regno1Service.GetActiveBuff(owner.UserId)
					local stats = EconomyEngine.CalculateStats(data, getCurrentHeat(owner.UserId), buffMult, data.HasDoubleLight)
					updatePlotBrazierVisuals(plot, stats)
					updatePlotGroundButtons(plot, data)

					if (not wasAllDone) and stats.AllUpgradesCompleted then
						triggerShockwave = true
						customPopup = Localization.T(lang, "POP_ALL_MAXED")
						ShadowDefenseService.ClearShadowsForPlot(plot.Index)
					end

					syncPlayer(owner, {
						SoundCue = soundCue,
						Shockwave = triggerShockwave,
						PopupText = customPopup,
					})
				end
			end
		end
	end
end)

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
	local cost = GameConfig.GetUpgradeCost(target, cur, data.AlbaCount or 0)
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

		local nowAllDone = EconomyEngine.GetUpgradeCompletion(data)
		local popup = nil
		if (not wasAllDone) and nowAllDone then
			popup = Localization.T(lang, "POP_ALL_MAXED")
			local plot = PlayerPlotMap[player.UserId]
			if plot then
				ShadowDefenseService.ClearShadowsForPlot(plot.Index)
			end
		elseif target.Id == "u_braziers" then
			popup = Localization.T(lang, "POP_R1_UNLOCKED")
			Regno1Service.SyncPlayer(player)
		elseif #newlyUnlocked > 0 then
			popup = Localization.T(lang, "POP_NEW_UNLOCK", table.concat(newlyUnlocked, " & "))
		end

		syncPlayer(player, {
			SoundCue = "Upgrade",
			Shockwave = (not wasAllDone and nowAllDone) or (#newlyUnlocked > 0),
			PopupText = popup,
		})
	end
end)

BuyWeapon.OnServerEvent:Connect(function(player, wepId)
	local data = PlayerData[player.UserId]
	if not data or type(wepId) ~= "string" then return end

	local target
	for _, w in ipairs(GameConfig.Weapons) do
		if w.Id == wepId then target = w; break end
	end
	if not target then return end

	if data.OwnedWeapons[target.Id] == true then return end
	local lang = getLang(data)
	local albaCount = data.AlbaCount or 0

	if target.ReqAlba and albaCount < target.ReqAlba then
		local reqMsg = lang == "it"
			and string.format("Serve almeno Rinascita %d dell'Alba!", target.ReqAlba)
			or string.format("Requires at least Dawn Rebirth %d!", target.ReqAlba)
		syncPlayer(player, { PopupText = reqMsg })
		return
	end

	local cost = GameConfig.GetWeaponCost(target, albaCount)
	if data.Points >= cost then
		data.Points -= cost
		data.OwnedWeapons[target.Id] = true
		ShadowDefenseService.SyncPlayerTools(player, data)

		syncPlayer(player, {
			SoundCue = "Upgrade",
			PopupText = Localization.T(lang, "POP_WEAPON_BOUGHT", Localization.Pick(lang, target.Name, target.Name_it)),
		})
	else
		syncPlayer(player, {
			PopupText = Localization.T(lang, "POP_NEED_LIGHT", NumberFormat.Format(cost)),
		})
	end
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
	local costInfo = GameConfig.GetDefenseCost(target, cur, data.AlbaCount or 0)
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
			ShadowDefenseService.RebuildPlotDefenses(plot, data)
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
	local data = PlayerData[player.UserId]
	if not data then return end
	local lang = getLang(data)
	amount = math.clamp(math.floor(amount or 1), 1, 5)
	local unitCost = GameConfig.GetWispCost(data.AlbaCount or 0)
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
		Regno1Service.Tick(0.1)
		ShadowDefenseService.Tick(0.1, ClickHeat)

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

Players.PlayerAdded:Connect(function(player)
	local ls = Instance.new("Folder", player); ls.Name = "leaderstats"
	local p = Instance.new("StringValue", ls); p.Name = "Points"; p.Value = "0"
	local l = Instance.new("StringValue", ls); l.Name = "Light"; l.Value = "4%"

	local data = EconomyEngine.DefaultData()
	if mainStore then
		local ok, saved = pcall(function() return mainStore:GetAsync("Plr_" .. player.UserId) end)
		if ok and type(saved) == "table" then
			for k, v in pairs(saved) do data[k] = v end
		end
	end

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

	verifyDoubleLightOwnership(player, data)
	PlayerData[player.UserId] = data

	local assignedPlot = assignPlotToPlayer(player, getLang(data))
	if assignedPlot then
		if data.TutorialCompleted then
			ShadowDefenseService.StartGracePeriod(assignedPlot.Index, GameConfig.InitialShadowGraceSeconds or 180, true)
		else
			ShadowDefenseService.StartGracePeriod(assignedPlot.Index, 999999, true)
		end
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		local stats = EconomyEngine.CalculateStats(data, 0, 1, data.HasDoubleLight)
		applyCharacterSpeed(player, stats.WalkSpeed)
		ShadowDefenseService.SyncPlayerTools(player, data)
		if assignedPlot then
			teleportPlayerToPlot(player, assignedPlot)
		end
	end)

	task.wait(0.8)
	if assignedPlot then
		local initStats = EconomyEngine.CalculateStats(data, 0, 1, data.HasDoubleLight)
		updatePlotBrazierVisuals(assignedPlot, initStats)
		updatePlotGroundButtons(assignedPlot, data)
		updatePlotAlbaZones(assignedPlot, data)
		ShadowDefenseService.RebuildPlotDefenses(assignedPlot, data)
		ShadowDefenseService.SyncPlayerTools(player, data)
		teleportPlayerToPlot(player, assignedPlot)
	end

	Regno1Service.SyncPlayer(player)
	syncPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player) savePlayer(player, true) end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do savePlayer(plr, false) end
end)
