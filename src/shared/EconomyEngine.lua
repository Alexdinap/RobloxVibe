local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local EconomyEngine = {}

local WISP_BY_ID = {}
for _, w in ipairs(GameConfig.Wisps) do
	WISP_BY_ID[w.Id] = w
end

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
		Regno1 = { Completed = false, Completions = 0, BestTime = nil },
		HasDoubleLight = false,
		HasWon = false,
		LastLogout = os.time(),
	}
end

function EconomyEngine.GetLevel(tbl, id)
	if type(tbl) ~= "table" then return 0 end
	return tbl[id] or 0
end

function EconomyEngine.IsUpgradeUnlocked(data, target)
	if not target or not target.ReqId then return true end
	return EconomyEngine.GetLevel(data.Upgrades, target.ReqId) >= (target.ReqLvl or 1)
end

function EconomyEngine.ParseWispId(rawId)
	if type(rawId) ~= "string" then return nil, false end
	local isRadiant = string.sub(rawId, -4) == "_rad"
	local baseId = isRadiant and string.sub(rawId, 1, -5) or rawId
	return WISP_BY_ID[baseId], isRadiant
end

function EconomyEngine.GetRank(lightPercent)
	local best = GameConfig.Ranks[1]
	for _, r in ipairs(GameConfig.Ranks) do
		if lightPercent >= r.MinLight then
			best = r
		end
	end
	return best
end

function EconomyEngine.CalculateStats(data, heat, regno1BuffMult, hasDoubleLight)
	local upgrades = data.Upgrades or {}
	local altars = data.Altars or {}
	local starPerks = data.StarPerks or {}

	-- 1. Statistiche dal Menù Personaggio
	local baseClick = 1.0
	local charMult = 1.0
	local critChance = 0.05
	local critMult = 5.0
	local autoClickRate = 0.0
	local walkSpeed = 16.0
	local extraWispSlots = 0
	local lightPct = 4.0

	for _, u in ipairs(GameConfig.Upgrades) do
		local lvl = EconomyEngine.GetLevel(upgrades, u.Id)
		if lvl > 0 then
			lightPct += (u.LightPct or 0) * lvl
			if u.Effect == "ClickAdd" then
				baseClick += (u.Value or 0) * lvl
			elseif u.Effect == "ClickMult" then
				charMult *= ((u.Value or 1) ^ lvl)
			elseif u.Effect == "CritChance" then
				critChance += (u.Value or 0) * lvl
			elseif u.Effect == "AutoClick" then
				autoClickRate += (u.Value or 0) * lvl
			elseif u.Effect == "WalkSpeed" then
				walkSpeed += (u.Value or 0) * lvl
			elseif u.Effect == "ExtraWisp" then
				extraWispSlots += (u.Value or 0) * lvl
			end
		end
	end

	-- 2. Statistiche dai Pulsanti a Terra (Braciere: Potenza, Moltiplicatore, Aspetto)
	local brazierPps = 0.0
	local brazierClickBonus = 0.0
	local brazierMult = 1.0
	local radiusLevel = 1
	local heatBonusMax = 0.0
	local brazierColor = Color3.fromRGB(255, 145, 45)
	local totalBrazierLevels = 0

	for _, alt in ipairs(GameConfig.Altars) do
		local lvl = EconomyEngine.GetLevel(altars, alt.Id)
		if lvl > 0 then
			totalBrazierLevels += lvl
			brazierPps += (alt.Pps or 0) * lvl
			brazierClickBonus += (alt.ClickBonus or 0) * lvl
			if alt.BrazierMult then
				brazierMult *= (alt.BrazierMult ^ lvl)
			end
			if alt.RadiusBonus then
				radiusLevel += alt.RadiusBonus * lvl
			end
			if alt.HeatBonus then
				heatBonusMax += alt.HeatBonus * lvl
			end
			if alt.BrazierColor then
				brazierColor = alt.BrazierColor
			end
		end
	end

	lightPct += math.min(55, totalBrazierLevels * 0.45)

	-- 3. Zone sbloccate individualmente per questo giocatore
	local unlockedZones = {
		Braziers = EconomyEngine.GetLevel(upgrades, "u_braziers") > 0,
		Crystals = (EconomyEngine.GetLevel(upgrades, "u_crystals") > 0) or (EconomyEngine.GetLevel(altars, "alt2") > 0),
		Lanterns = (EconomyEngine.GetLevel(upgrades, "u_lanterns") > 0) or (EconomyEngine.GetLevel(altars, "alt4") > 0),
		Waterfall = (EconomyEngine.GetLevel(upgrades, "u_waterfall") > 0) or (EconomyEngine.GetLevel(altars, "alt6") > 0),
		Temple = (EconomyEngine.GetLevel(upgrades, "u_temple") > 0) or (EconomyEngine.GetLevel(altars, "alt8") > 0),
	}
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Zone and EconomyEngine.GetLevel(upgrades, u.Id) > 0 then
			unlockedZones[u.Zone] = true
		end
	end

	-- 4. Spiriti di Luce Equipaggiati
	local maxWispSlots = GameConfig.BaseEquippedWisps + extraWispSlots
	local allWisps = {}
	for _, rawId in ipairs(data.Wisps or {}) do
		local cfg, isRad = EconomyEngine.ParseWispId(rawId)
		if cfg then
			local mult = cfg.ClickMult * (isRad and 2.5 or 1.0)
			table.insert(allWisps, { RawId = rawId, Config = cfg, Mult = mult })
		end
	end
	table.sort(allWisps, function(a, b) return a.Mult > b.Mult end)

	local equippedWisps = {}
	local wispMult = 1.0
	for i = 1, math.min(#allWisps, maxWispSlots) do
		table.insert(equippedWisps, allWisps[i])
		wispMult *= allWisps[i].Mult
	end

	-- 5. Costellazioni (Prestige) & Benedizioni
	local starPowerLvl = EconomyEngine.GetLevel(starPerks, "sp_power")
	local starMult = (starPowerLvl > 0) and (3 ^ starPowerLvl) or 1.0

	local starCritLvl = EconomyEngine.GetLevel(starPerks, "sp_crit")
	if starCritLvl > 0 then
		critMult *= (2 ^ starCritLvl)
	end

	local regno1PermMult = (data.Regno1 and data.Regno1.Completed) and (GameConfig.Regno1.PermanentBlessingMult or 1.35) or 1.0
	local activeBuff = regno1BuffMult or 1.0
	local passMult = (hasDoubleLight or data.HasDoubleLight) and 2.0 or 1.0

	-- Calore Fiamma
	local clampedHeat = math.clamp(heat or 0, 0, 1)
	local heatMult = 1.0 + clampedHeat * (0.5 + heatBonusMax)

	-- Calcolo Finale Bilanciato
	local globalMult = charMult * brazierMult * wispMult * starMult * regno1PermMult * activeBuff * passMult * heatMult
	local clickPower = (baseClick + brazierClickBonus) * globalMult
	local pointsPerSec = (brazierPps * globalMult) + (autoClickRate * clickPower)

	return {
		ClickPower = clickPower,
		PointsPerSec = pointsPerSec,
		Heat = clampedHeat,
		HeatMult = heatMult,
		LightPercent = math.clamp(math.floor(lightPct), 4, 100),
		EquippedWisps = equippedWisps,
		RadiusLevel = radiusLevel,
		BrazierColor = brazierColor,
		UnlockedZones = unlockedZones,
		WalkSpeed = walkSpeed,
		MaxWispSlots = maxWispSlots,
		CritChance = math.min(0.75, critChance),
		CritMult = critMult,
		WispsUnlocked = EconomyEngine.GetLevel(upgrades, "u_unlock_wisps") > 0,
		AlbaUnlocked = EconomyEngine.GetLevel(upgrades, "u_unlock_alba") > 0,
		HasDoubleLight = (hasDoubleLight == true or data.HasDoubleLight == true),
	}
end

return EconomyEngine
