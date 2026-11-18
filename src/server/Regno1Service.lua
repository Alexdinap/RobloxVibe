local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local Regno1Service = {}

local Regno1Sync = nil
local PlotsRef = {}
local PlayerDataRef = {}
local SyncPlayerFn = nil

local ActiveTrials = {} -- [userId] = { Step = 2, TimeLeft = 18.0 }
local ActiveBuffs = {}  -- [userId] = { Mult = 1.8, ExpiresAt = os.clock() + 30 }
local Cooldowns = {}    -- [userId] = os.clock()

local function getLang(data)
	return (data and data.Language) or "en"
end

function Regno1Service.GetActiveBuff(userId)
	local b = ActiveBuffs[userId]
	if not b then return 1.0, 0 end
	local rem = b.ExpiresAt - os.clock()
	if rem <= 0 then
		ActiveBuffs[userId] = nil
		return 1.0, 0
	end
	return b.Mult, rem
end

function Regno1Service.SyncPlayer(player)
	if not Regno1Sync or not player then return end
	local data = PlayerDataRef[player.UserId]
	local unlocked = data and (EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) > 0) or false
	local trial = ActiveTrials[player.UserId]
	local buffMult, buffRem = Regno1Service.GetActiveBuff(player.UserId)

	Regno1Sync:FireClient(player, {
		Unlocked = unlocked,
		Active = trial ~= nil,
		CurrentStep = trial and trial.Step or 1,
		TotalSteps = #GameConfig.Regno1.Braziers,
		TimeLeft = trial and trial.TimeLeft or 0,
		BuffMult = buffMult,
		BuffRemaining = buffRem,
	})
end

function Regno1Service.Init(remotesFolder, plots, playerData, syncPlayerCallback)
	PlotsRef = plots
	PlayerDataRef = playerData
	SyncPlayerFn = syncPlayerCallback

	Regno1Sync = Instance.new("RemoteEvent", remotesFolder)
	Regno1Sync.Name = "Regno1Sync"

	local braziers = GameConfig.Regno1.Braziers

	for _, plot in ipairs(plots) do
		for _, b in ipairs(braziers) do
			local ped = plot.RitualFolder and plot.RitualFolder:FindFirstChild("Brazier_" .. b.Index)
			if ped then
				ped.Touched:Connect(function(hit)
					local plr = Players:GetPlayerFromCharacter(hit.Parent)
					if not plr or plot.Owner ~= plr then return end

					local data = PlayerDataRef[plr.UserId]
					if not data then return end
					if EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) <= 0 then
						return
					end

					local lang = getLang(data)
					local now = os.clock()
					local trial = ActiveTrials[plr.UserId]

					if not trial then
						if b.Index == 1 then
							if Cooldowns[plr.UserId] and (now - Cooldowns[plr.UserId] < GameConfig.Regno1.RetryCooldown) then
								return
							end
							ActiveTrials[plr.UserId] = {
								Step = 2,
								TimeLeft = GameConfig.Regno1.BaseTime,
							}
							Regno1Service.SyncPlayer(plr)
							if SyncPlayerFn then
								SyncPlayerFn(plr, {
									SoundCue = "Upgrade",
									PopupText = Localization.T(lang, "R1_START"),
								})
							end
						end
					else
						if b.Index == trial.Step then
							if b.Index >= #braziers then
								-- Completed Chain of Fire!
								ActiveTrials[plr.UserId] = nil
								Cooldowns[plr.UserId] = now
								data.Regno1.Completed = true
								data.Regno1.Completions = (data.Regno1.Completions or 0) + 1

								local mult = GameConfig.Regno1.BuffMinMult + math.random() * (GameConfig.Regno1.BuffMaxMult - GameConfig.Regno1.BuffMinMult)
								mult = math.floor(mult * 100 + 0.5) / 100
								ActiveBuffs[plr.UserId] = {
									Mult = mult,
									ExpiresAt = now + GameConfig.Regno1.BuffDuration,
								}

								Regno1Service.SyncPlayer(plr)
								if SyncPlayerFn then
									SyncPlayerFn(plr, {
										SoundCue = "Prestige",
										Shockwave = true,
										PopupText = Localization.T(lang, "R1_WIN_FMT", mult),
									})
								end
							else
								trial.Step += 1
								trial.TimeLeft += GameConfig.Regno1.BonusTimePerBrazier
								local nextCfg = braziers[trial.Step]
								Regno1Service.SyncPlayer(plr)
								if SyncPlayerFn then
									SyncPlayerFn(plr, {
										SoundCue = "Click",
										PopupText = Localization.T(lang, "R1_STEP_FMT", b.Numeral, GameConfig.Regno1.BonusTimePerBrazier, nextCfg and nextCfg.Numeral or "V"),
									})
								end
							end
						end
					end
				end)
			end
		end
	end
end

function Regno1Service.Tick(dt)
	for userId, trial in pairs(ActiveTrials) do
		trial.TimeLeft -= dt
		local plr = Players:GetPlayerByUserId(userId)
		if not plr then
			ActiveTrials[userId] = nil
		elseif trial.TimeLeft <= 0 then
			ActiveTrials[userId] = nil
			Cooldowns[userId] = os.clock()
			local data = PlayerDataRef[userId]
			Regno1Service.SyncPlayer(plr)
			if SyncPlayerFn then
				SyncPlayerFn(plr, {
					PopupText = Localization.T(getLang(data), "R1_FAIL"),
				})
			end
		else
			Regno1Service.SyncPlayer(plr)
		end
	end
end

Players.PlayerRemoving:Connect(function(plr)
	ActiveTrials[plr.UserId] = nil
	ActiveBuffs[plr.UserId] = nil
	Cooldowns[plr.UserId] = nil
end)

return Regno1Service
