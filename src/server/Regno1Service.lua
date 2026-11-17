local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))

local Regno1Service = {}

local PlotsRef = {}
local PlayerDataRef = {}
local SyncPlayerCallback = nil
local Regno1SyncRemote = nil

-- Stato individuale per singolo giocatore (100% isolato in multiplayer)
local PlayerTrials = {} -- [userId] = { Active = bool, CurrentStep = 1..5, TimeLeft = float, TotalTime = float, Cooldown = float, BuffMult = 1.0, BuffRem = 0 }

local function getOrCreateState(userId)
	local st = PlayerTrials[userId]
	if not st then
		st = {
			Active = false,
			CurrentStep = 1,
			TimeLeft = 0,
			TotalTime = 0,
			Cooldown = 0,
			BuffMult = 1.0,
			BuffRem = 0,
		}
		PlayerTrials[userId] = st
	end
	return st
end

function Regno1Service.Init(remotesFolder, plotsOrRitual, playerDataMap, syncCallback)
	PlotsRef = (type(plotsOrRitual) == "table") and plotsOrRitual or {}
	PlayerDataRef = playerDataMap or {}
	SyncPlayerCallback = syncCallback

	Regno1SyncRemote = Instance.new("RemoteEvent", remotesFolder)
	Regno1SyncRemote.Name = "Regno1Sync"

	Players.PlayerRemoving:Connect(function(plr)
		PlayerTrials[plr.UserId] = nil
	end)
end

function Regno1Service.GetActiveBuff(userId)
	local st = PlayerTrials[userId]
	if st and st.BuffRem > 0 then
		return st.BuffMult, st.BuffRem
	end
	return 1.0, 0
end

function Regno1Service.SyncPlayer(player)
	if not player or not Regno1SyncRemote then return end
	local data = PlayerDataRef[player.UserId]
	local unlocked = data and (EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) > 0) or false
	local st = getOrCreateState(player.UserId)

	Regno1SyncRemote:FireClient(player, {
		Unlocked = unlocked,
		Active = st.Active,
		CurrentStep = st.CurrentStep,
		TotalSteps = #GameConfig.Regno1.Braziers,
		TimeLeft = st.TimeLeft,
		TotalTime = st.TotalTime,
		Cooldown = st.Cooldown,
		BuffMult = st.BuffRem > 0 and st.BuffMult or 1.0,
		BuffRemaining = st.BuffRem,
	})
end

function Regno1Service.Tick(dt)
	local cfg = GameConfig.Regno1
	local braziers = cfg.Braziers
	local totalBraziers = #braziers

	for _, plr in ipairs(Players:GetPlayers()) do
		local userId = plr.UserId
		local data = PlayerDataRef[userId]
		if data then
			local st = getOrCreateState(userId)
			local dirty = false

			-- Aggiorna timer benedizione attiva
			if st.BuffRem > 0 then
				st.BuffRem = math.max(0, st.BuffRem - dt)
				if st.BuffRem == 0 then
					st.BuffMult = 1.0
				end
				dirty = true
			end

			-- Aggiorna cooldown dopo fallimento
			if st.Cooldown > 0 then
				st.Cooldown = math.max(0, st.Cooldown - dt)
				dirty = true
			end

			local unlocked = EconomyEngine.GetLevel(data.Upgrades, cfg.UnlockUpgradeId) > 0
			local plotIndex = plr:GetAttribute("PlotIndex")
			local plot = plotIndex and PlotsRef[plotIndex]
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

			if unlocked and plot and hrp and st.Cooldown <= 0 then
				if st.Active then
					st.TimeLeft -= dt
					dirty = true

					if st.TimeLeft <= 0 then
						st.Active = false
						st.CurrentStep = 1
						st.TimeLeft = 0
						st.Cooldown = cfg.RetryCooldown or 3.5
						if SyncPlayerCallback then
							SyncPlayerCallback(plr, {
								PopupText = "⌛ Tempo scaduto nella Catena del Fuoco! Riprova dal Braciere I.",
							})
						end
					else
						local targetBrazier = braziers[st.CurrentStep]
						if targetBrazier then
							local worldPos = plot.Origin + targetBrazier.Pos
							local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(worldPos.X, 0, worldPos.Z)).Magnitude
							if dist <= (cfg.IgniteRadius or 11.5) then
								if st.CurrentStep < totalBraziers then
									st.CurrentStep += 1
									st.TimeLeft += (cfg.BonusTimePerBrazier or 2.5)
									st.TotalTime += (cfg.BonusTimePerBrazier or 2.5)
									if SyncPlayerCallback then
										SyncPlayerCallback(plr, {
											SoundCue = "Click",
											PopupText = string.format("🔥 Braciere %s acceso! (+%.1fs)", targetBrazier.Numeral, cfg.BonusTimePerBrazier or 2.5),
										})
									end
								else
									-- Completato Braciere V!
									local elapsed = math.max(1.0, st.TotalTime - st.TimeLeft)
									local speedRatio = math.clamp(st.TimeLeft / math.max(1, st.TotalTime), 0, 1)
									local mult = cfg.BuffMinMult + (cfg.BuffMaxMult - cfg.BuffMinMult) * speedRatio
									mult = math.floor(mult * 100 + 0.5) / 100

									st.Active = false
									st.CurrentStep = 1
									st.TimeLeft = 0
									st.BuffMult = mult
									st.BuffRem = cfg.BuffDuration or 30.0

									data.Regno1 = data.Regno1 or { Completed = false, Completions = 0, BestTime = nil }
									data.Regno1.Completed = true
									data.Regno1.Completions = (data.Regno1.Completions or 0) + 1
									if not data.Regno1.BestTime or elapsed < data.Regno1.BestTime then
										data.Regno1.BestTime = math.floor(elapsed * 10 + 0.5) / 10
									end

									if SyncPlayerCallback then
										SyncPlayerCallback(plr, {
											SoundCue = "Prestige",
											Shockwave = true,
											PopupText = string.format("🏆 CATENA DEL FUOCO COMPLETATA! Benedizione x%.2f (%ds)!", mult, math.floor(st.BuffRem)),
										})
									end
								end
							end
						end
					end
				else
					-- Controlla se il giocatore tocca il Braciere I della propria Zona per iniziare
					local firstBrazier = braziers[1]
					if firstBrazier then
						local startPos = plot.Origin + firstBrazier.Pos
						local dist = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(startPos.X, 0, startPos.Z)).Magnitude
						if dist <= (cfg.IgniteRadius or 11.5) then
							st.Active = true
							st.CurrentStep = 2
							st.TimeLeft = cfg.BaseTime or 18.0
							st.TotalTime = cfg.BaseTime or 18.0
							dirty = true
							if SyncPlayerCallback then
								SyncPlayerCallback(plr, {
									SoundCue = "Upgrade",
									PopupText = "🏃 CATENA DEL FUOCO AVVIATA! Corri al Braciere II!",
								})
							end
						end
					end
				end
			end

			if dirty then
				Regno1Service.SyncPlayer(plr)
			end
		end
	end
end

return Regno1Service
