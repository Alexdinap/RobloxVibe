local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(script.Parent:WaitForChild("EconomyEngine"))

local Regno1Service = {}

local PlayerDataRef = nil
local SyncPlayerFn = nil
local Regno1Event = nil
local RitualFolder = nil

-- Stato runtime per ogni giocatore:
-- ActiveRuns[userId] = { Step = 1..4, TimeLeft = 18.0, MaxTime = 18.0, StartClock = os.clock() }
-- Cooldowns[userId] = os.clock() + X
-- ActiveBuffs[userId] = { Mult = 1.8, ExpiresAt = os.clock() + 30 }
local ActiveRuns = {}
local Cooldowns = {}
local ActiveBuffs = {}

local function sendClientState(player, eventType, extra)
	if not Regno1Event then return end
	local data = PlayerDataRef and PlayerDataRef[player.UserId]
	local regData = (data and data.Regno1) or {}
	local run = ActiveRuns[player.UserId]
	local buff = ActiveBuffs[player.UserId]
	local now = os.clock()

	local buffMult = 1.0
	local buffRem = 0
	if buff and buff.ExpiresAt > now then
		buffMult = buff.Mult
		buffRem = buff.ExpiresAt - now
	end

	local payload = {
		Type = eventType,
		Unlocked = data and (EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) > 0) or false,
		Completed = regData.Completed == true,
		Completions = regData.Completions or 0,
		BestTime = regData.BestTime,
		Active = run ~= nil,
		Step = run and run.Step or 0,
		TotalBraziers = #GameConfig.Regno1.Braziers,
		TimeLeft = run and math.max(0, run.TimeLeft) or 0,
		MaxTime = run and run.MaxTime or GameConfig.Regno1.BaseTime,
		BuffMult = buffMult,
		BuffRemaining = buffRem,
		BuffDuration = GameConfig.Regno1.BuffDuration,
	}
	if extra then
		for k, v in pairs(extra) do
			payload[k] = v
		end
	end
	Regno1Event:FireClient(player, payload)
end

function Regno1Service.GetActiveBuff(userId)
	local buff = ActiveBuffs[userId]
	if not buff then return 1.0, 0 end
	local rem = buff.ExpiresAt - os.clock()
	if rem <= 0 then
		ActiveBuffs[userId] = nil
		return 1.0, 0
	end
	return buff.Mult, rem
end

function Regno1Service.SyncPlayer(player)
	sendClientState(player, "Sync")
end

local function startTrial(player)
	local userId = player.UserId
	local data = PlayerDataRef and PlayerDataRef[userId]
	if not data then return end

	if EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) <= 0 then
		if SyncPlayerFn then
			SyncPlayerFn(player, {
				PopupText = "🔒 Acquista prima 'Regno 1' nella scheda Regni!",
			})
		end
		return
	end

	if ActiveRuns[userId] then
		return
	end

	local now = os.clock()
	if Cooldowns[userId] and now < Cooldowns[userId] then
		local waitSec = math.ceil(Cooldowns[userId] - now)
		if SyncPlayerFn then
			SyncPlayerFn(player, {
				PopupText = "⏳ Attendi " .. waitSec .. "s prima di riaccendere la Catena!",
			})
		end
		return
	end

	ActiveRuns[userId] = {
		Step = 1,
		TimeLeft = GameConfig.Regno1.BaseTime,
		MaxTime = GameConfig.Regno1.BaseTime,
		StartClock = now,
	}

	sendClientState(player, "Start", {
		LitIndex = 1,
	})
end

local function completeTrial(player, run)
	local userId = player.UserId
	local data = PlayerDataRef and PlayerDataRef[userId]
	if not data then return end

	ActiveRuns[userId] = nil
	Cooldowns[userId] = os.clock() + GameConfig.Regno1.RetryCooldown

	data.Regno1 = data.Regno1 or { Completed = false, Completions = 0, BestTime = nil }
	local firstTime = not data.Regno1.Completed
	data.Regno1.Completed = true
	data.Regno1.Completions = (data.Regno1.Completions or 0) + 1

	local elapsed = math.max(0.1, math.floor((os.clock() - run.StartClock) * 100) / 100)
	local isNewRecord = false
	if not data.Regno1.BestTime or elapsed < data.Regno1.BestTime then
		data.Regno1.BestTime = elapsed
		isNewRecord = true
	end

	-- Calcola moltiplicatore buff temporaneo in base al tempo rimasto
	local timeRatio = math.clamp(run.TimeLeft / 12.0, 0, 1)
	local mult = GameConfig.Regno1.BuffMinMult + (GameConfig.Regno1.BuffMaxMult - GameConfig.Regno1.BuffMinMult) * timeRatio
	mult = math.floor(mult * 100) / 100

	ActiveBuffs[userId] = {
		Mult = mult,
		ExpiresAt = os.clock() + GameConfig.Regno1.BuffDuration,
	}

	-- Calcola premio istantaneo in Punti Luce
	local stats = EconomyEngine.CalculateStats(data, 0.5, mult)
	local instantReward = math.max(300, (stats.PointsPerSec * 25) + (stats.ClickPower * 45))
	instantReward *= (1 + run.TimeLeft * 0.06)
	data.Points += instantReward
	data.TotalPoints += instantReward

	local bannerMsg
	if firstTime then
		bannerMsg = string.format(
			"🏆 REGNO 1 PURIFICATO! Benedizione +35%% Permanente & Fiamma x%.2f!",
			mult
		)
	elseif isNewRecord then
		bannerMsg = string.format(
			"⚡ NUOVO RECORD REGNO 1 (%.2fs)! +%s Punti & Fiamma x%.2f!",
			elapsed,
			NumberFormat.Format(instantReward),
			mult
		)
	else
		bannerMsg = string.format(
			"🔥 CATENA COMPLETATA (%.2fs)! +%s Punti & Fiamma x%.2f!",
			elapsed,
			NumberFormat.Format(instantReward),
			mult
		)
	end

	sendClientState(player, "Complete", {
		LitIndex = #GameConfig.Regno1.Braziers,
		Elapsed = elapsed,
		IsNewRecord = isNewRecord,
		FirstTime = firstTime,
		Reward = instantReward,
	})

	if SyncPlayerFn then
		SyncPlayerFn(player, {
			SoundCue = "Prestige",
			Shockwave = true,
			PopupText = bannerMsg,
		})
	end
end

local function advanceTrial(player, brazierIndex)
	local userId = player.UserId
	local run = ActiveRuns[userId]
	if not run then
		if brazierIndex == 1 then
			startTrial(player)
		end
		return
	end

	local expected = run.Step + 1
	if brazierIndex ~= expected then
		return
	end

	-- Verifica distanza fisica lato server (anti-cheat)
	local bCfg = GameConfig.Regno1.Braziers[brazierIndex]
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not bCfg or not hrp then return end

	local dist = (hrp.Position - bCfg.Pos).Magnitude
	if dist > (GameConfig.Regno1.IgniteRadius + 4.5) then
		return
	end

	if brazierIndex >= #GameConfig.Regno1.Braziers then
		completeTrial(player, run)
	else
		run.Step = brazierIndex
		run.TimeLeft += GameConfig.Regno1.BonusTimePerBrazier
		run.MaxTime = math.max(run.MaxTime, run.TimeLeft)

		sendClientState(player, "Ignite", {
			LitIndex = brazierIndex,
			BonusAdded = GameConfig.Regno1.BonusTimePerBrazier,
		})
	end
end

function Regno1Service.Init(remotesFolder, ritualFolder, playerDataTable, syncPlayerCallback)
	RitualFolder = ritualFolder
	PlayerDataRef = playerDataTable
	SyncPlayerFn = syncPlayerCallback

	Regno1Event = Instance.new("RemoteEvent")
	Regno1Event.Name = "Regno1Event"
	Regno1Event.Parent = remotesFolder

	-- Collega ProximityPrompt e Touched su ciascuno dei 5 Bracieri di Regno 1
	for _, bCfg in ipairs(GameConfig.Regno1.Braziers) do
		local bModel = RitualFolder:FindFirstChild("RitualBrazier_" .. bCfg.Index)
		if bModel then
			local bowl = bModel:FindFirstChild("Bowl")
			local runePad = bModel:FindFirstChild("RunePad")
			local prompt = bowl and bowl:FindFirstChild("RitualPrompt")

			if prompt then
				prompt.Triggered:Connect(function(plr)
					if bCfg.Index == 1 and not ActiveRuns[plr.UserId] then
						startTrial(plr)
					else
						advanceTrial(plr, bCfg.Index)
					end
				end)
			end

			if runePad then
				runePad.Touched:Connect(function(hit)
					local plr = Players:GetPlayerFromCharacter(hit.Parent)
					if not plr then return end
					if bCfg.Index == 1 and not ActiveRuns[plr.UserId] then
						startTrial(plr)
					else
						advanceTrial(plr, bCfg.Index)
					end
				end)
			end
		end
	end

	Players.PlayerRemoving:Connect(function(plr)
		ActiveRuns[plr.UserId] = nil
		Cooldowns[plr.UserId] = nil
		ActiveBuffs[plr.UserId] = nil
	end)
end

-- Chiamato dal loop server ogni 0.1s per aggiornare timer e accensione di prossimità fluida
function Regno1Service.Tick(dt)
	for _, plr in ipairs(Players:GetPlayers()) do
		local userId = plr.UserId
		local run = ActiveRuns[userId]
		if run then
			run.TimeLeft -= dt
			if run.TimeLeft <= 0 then
				ActiveRuns[userId] = nil
				Cooldowns[userId] = os.clock() + 2.0
				sendClientState(plr, "Fail")
				if SyncPlayerFn then
					SyncPlayerFn(plr, {
						PopupText = "💨 La Scintilla si è spenta! Riprova dal Braciere I di Regno 1.",
					})
				end
			else
				-- Accensione automatica fluida quando il giocatore corre vicino al prossimo braciere
				local nextIdx = run.Step + 1
				local nextCfg = GameConfig.Regno1.Braziers[nextIdx]
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if nextCfg and hrp then
					local flatDist = (Vector3.new(hrp.Position.X, nextCfg.Pos.Y, hrp.Position.Z) - nextCfg.Pos).Magnitude
					if flatDist <= GameConfig.Regno1.IgniteRadius then
						advanceTrial(plr, nextIdx)
					end
				end
			end
		end
	end
end

return Regno1Service
