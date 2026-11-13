local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local EconomyEngine = {}

function EconomyEngine.DefaultData()
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
		Regno1 = {
			Completed = false,
			Completions = 0,
			BestTime = nil,
		},
		LastLogout = os.time(),
	}
end

function EconomyEngine.GetLevel(tbl, id)
	return (tbl and tbl[id]) or 0
end

-- Controlla se un potenziamento è già sbloccato nella catena progressiva
function EconomyEngine.IsUpgradeUnlocked(data, upg)
	if not upg.ReqId then
		return true
	end
	local reqCurrent = EconomyEngine.GetLevel(data.Upgrades, upg.ReqId)
	return reqCurrent >= (upg.ReqLvl or 1)
end

function EconomyEngine.GetRank(lightPct)
	local best = GameConfig.Ranks[1]
	for _, r in ipairs(GameConfig.Ranks) do
		if lightPct >= r.MinLight then
			best = r
		end
	end
	return best
end

function EconomyEngine.GetMaxWispSlots(data)
	return GameConfig.BaseEquippedWisps + EconomyEngine.GetLevel(data.Upgrades, "u_wisp_slot")
end

function EconomyEngine.ParseWispId(rawId)
	local isRadiant = string.sub(rawId, -4) == "_rad"
	local baseId = isRadiant and string.sub(rawId, 1, -5) or rawId
	for _, cfg in ipairs(GameConfig.Wisps) do
		if cfg.Id == baseId then
			return cfg, isRadiant
		end
	end
	return nil, false
end

function EconomyEngine.GetEquippedWisps(data)
	local list = {}
	for _, rawId in ipairs(data.Wisps) do
		local cfg, rad = EconomyEngine.ParseWispId(rawId)
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
	for i = 1, math.min(EconomyEngine.GetMaxWispSlots(data), #list) do
		table.insert(eq, list[i])
	end
	return eq
end

function EconomyEngine.CalculateStats(data, heatValue, regno1BuffMult)
	local baseClick = 1
	local clickMult = 1
	local pointsPerSec = 0
	local critChance = 0
	local critMult = 12 * (2 ^ EconomyEngine.GetLevel(data.StarPerks, "sp_crit"))
	local autoClicksPerSec = 0
	local maxHeatBonus = 2.0
	local lightPercent = 4

	for _, alt in ipairs(GameConfig.Altars) do
		local lvl = EconomyEngine.GetLevel(data.Altars, alt.Id)
		if lvl > 0 then
			pointsPerSec += alt.Pps * lvl
			baseClick += alt.ClickBonus * lvl
		end
	end

	for _, upg in ipairs(GameConfig.Upgrades) do
		local lvl = EconomyEngine.GetLevel(data.Upgrades, upg.Id)
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

	-- Benedizione permanente di Regno 1 (+35% produzione dopo il 1° completamento del Rituale)
	local regno1Blessed = (data.Regno1 and data.Regno1.Completed == true)
	if regno1Blessed then
		clickMult *= GameConfig.Regno1.PermanentBlessingMult
	end

	-- Buff temporaneo "Fiamma Ruggente" vinto completando la Catena del Fuoco di Regno 1
	local activeBuff = math.max(1.0, regno1BuffMult or 1.0)
	clickMult *= activeBuff

	local equipped = EconomyEngine.GetEquippedWisps(data)
	local wispBonus = 1
	for _, w in ipairs(equipped) do
		wispBonus += (w.ClickMult - 1)
	end
	clickMult *= wispBonus

	if data.EternalStars > 0 then
		clickMult *= (4 ^ data.EternalStars)
	end
	local starPowerLvl = EconomyEngine.GetLevel(data.StarPerks, "sp_power")
	if starPowerLvl > 0 then
		clickMult *= (5 ^ starPowerLvl)
	end

	local heat = math.clamp(heatValue or 0, 0, 1)
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
		RadiusLevel = EconomyEngine.GetLevel(data.Upgrades, "u_radius"),
		EquippedWisps = equipped,
		MaxWispSlots = EconomyEngine.GetMaxWispSlots(data),
		WispsUnlocked = EconomyEngine.GetLevel(data.Upgrades, "u_unlock_wisps") > 0 or #data.Wisps > 0,
		AlbaUnlocked = EconomyEngine.GetLevel(data.Upgrades, "u_unlock_alba") > 0 or data.EternalStars > 0,
		Regno1Unlocked = EconomyEngine.GetLevel(data.Upgrades, GameConfig.Regno1.UnlockUpgradeId) > 0,
		Regno1Blessed = regno1Blessed,
		Regno1BuffMult = activeBuff,
	}
end

return EconomyEngine
