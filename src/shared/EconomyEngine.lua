local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local EconomyEngine = {}

local WISP_BY_ID = {}
for _, w in ipairs(GameConfig.Wisps) do
	WISP_BY_ID[w.Id] = w
end

function EconomyEngine.DefaultData()
	return {
		Language = "en",
		Points = 0,
		TotalPoints = 0,
		TotalClicks = 0,
		AlbaPoints = 0,
		AlbaCount = 0,
		Altars = {},
		Upgrades = {},
		AlbaPerks = {},
		UnlockedAlbaZones = {},
		OwnedWeapons = {},
		Defenses = {},
		Wisps = {},
		UsedCodes = {},
		Regno1 = { Completed = false, Completions = 0, BestTime = nil },
		HasDoubleLight = false,
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

function EconomyEngine.GetAlbaRewardPerRebirth(data)
	local albaPerks = (data and data.AlbaPerks) or {}
	local bonusLvl = EconomyEngine.GetLevel(albaPerks, "ap_alba_gain")
	local base = (GameConfig.VictoryButton and GameConfig.VictoryButton.BaseAlbaReward) or 1
	return base + bonusLvl
end

function EconomyEngine.GetUpgradeCompletion(data)
	local upgrades = (data and data.Upgrades) or {}
	local altars = (data and data.Altars) or {}
	local completed = 0
	local total = #GameConfig.Upgrades + #GameConfig.Altars

	for _, u in ipairs(GameConfig.Upgrades) do
		if EconomyEngine.GetLevel(upgrades, u.Id) >= (u.MaxLevel or 1) then
			completed += 1
		end
	end
	for _, alt in ipairs(GameConfig.Altars) do
		if EconomyEngine.GetLevel(altars, alt.Id) >= (alt.MaxLevel or 1) then
			completed += 1
		end
	end

	return (completed >= total), completed, total
end

function EconomyEngine.CalculateStats(data, heat, regno1BuffMult, hasDoubleLight)
	local upgrades = data.Upgrades or {}
	local altars = data.Altars or {}
	local albaPerks = data.AlbaPerks or {}
	local unlockedZones = data.UnlockedAlbaZones or {}

	-- 1. Character Stats
	local baseClick = 1.0
	local charClickMult = 1.0
	local critChance = 0.05
	local critMult = 5.0
	local autoClickRate = 0.0
	local walkSpeed = 16.0
	local extraWispSlots = 0
	local lightPct = 4.0
	local baseClickCooldown = GameConfig.BaseClickCooldown or 0.50
	local minClickCooldown = GameConfig.MinClickCooldown or 0.06
	local cooldownReduction = 0.0

	for _, u in ipairs(GameConfig.Upgrades) do
		local lvl = EconomyEngine.GetLevel(upgrades, u.Id)
		if lvl > 0 then
			lightPct += (u.LightPct or 0) * lvl
			if u.Effect == "ClickAdd" then
				baseClick += (u.Value or 0) * lvl
			elseif u.Effect == "ClickCooldown" then
				cooldownReduction += (u.Value or 0) * lvl
			elseif u.Effect == "ClickPowerMult" or u.Effect == "ClickMult" then
				charClickMult *= ((u.Value or 1) ^ lvl)
			elseif u.Effect == "CritChance" then
				critChance += (u.Value or 0) * lvl
			elseif u.Effect == "CritMult" then
				critMult += (u.Value or 0) * lvl
			elseif u.Effect == "AutoClick" then
				autoClickRate += (u.Value or 0) * lvl
			elseif u.Effect == "WalkSpeed" then
				walkSpeed += (u.Value or 0) * lvl
			elseif u.Effect == "ExtraWisp" then
				extraWispSlots += (u.Value or 0) * lvl
			end
		end
	end

	local clickCooldown = math.max(minClickCooldown, baseClickCooldown - cooldownReduction)

	-- 2. Ground Buttons & Brazier Stats
	local brazierPps = 0.0
	local brazierMult = 1.0
	local radiusLevel = 1
	local heatBonusMax = 0.0
	local brazierColor = Color3.fromRGB(255, 145, 45)
	local highestColorTier = 0
	local totalBrazierLevels = 0

	for _, alt in ipairs(GameConfig.Altars) do
		local lvl = EconomyEngine.GetLevel(altars, alt.Id)
		if lvl > 0 then
			totalBrazierLevels += lvl
			if alt.ClickAdd then
				baseClick += alt.ClickAdd * lvl
			end
			brazierPps += (alt.Pps or 0) * lvl
			if alt.BrazierMult then
				brazierMult *= (alt.BrazierMult ^ lvl)
			end
			if alt.RadiusBonus then
				radiusLevel += alt.RadiusBonus * lvl
			end
			if alt.HeatBonus then
				heatBonusMax += alt.HeatBonus * lvl
			end
			if alt.BrazierColor and (alt.ColorTier or 1) >= highestColorTier then
				highestColorTier = alt.ColorTier or 1
				brazierColor = alt.BrazierColor
			end
		end
	end

	lightPct += math.min(50, totalBrazierLevels * 0.45)

	-- 3. Equipped Light Wisps
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

	-- 4. Dawn Perks & Unlocked Zones
	local albaPowerLvl = EconomyEngine.GetLevel(albaPerks, "ap_power")
	local albaMult = (albaPowerLvl > 0) and (2.5 ^ albaPowerLvl) or 1.0

	local albaCritLvl = EconomyEngine.GetLevel(albaPerks, "ap_crit")
	if albaCritLvl > 0 then
		critMult *= (2 ^ albaCritLvl)
	end

	local zonesMult = 1.0
	local unlockedZonesCount = 1
	for _, z in ipairs(GameConfig.AlbaZones) do
		if unlockedZones[z.Id] == true then
			zonesMult *= (z.LightMult or 1.0)
			unlockedZonesCount += 1
		end
	end

	local regno1PermMult = (data.Regno1 and data.Regno1.Completed) and (GameConfig.Regno1.PermanentBlessingMult or 1.35) or 1.0
	local activeBuff = regno1BuffMult or 1.0
	local passMult = (hasDoubleLight or data.HasDoubleLight) and 2.0 or 1.0

	local clampedHeat = math.clamp(heat or 0, 0, 1)
	local heatMult = 1.0 + clampedHeat * (0.5 + heatBonusMax)

	local sharedMult = wispMult * albaMult * zonesMult * regno1PermMult * activeBuff * passMult * heatMult
	local clickPower = baseClick * charClickMult * sharedMult
	local pointsPerSec = (brazierPps * brazierMult * sharedMult) + (autoClickRate * clickPower)

	local allCompleted, completedCount, totalCount = EconomyEngine.GetUpgradeCompletion(data)

	return {
		ClickPower = clickPower,
		ClickCooldown = clickCooldown,
		PointsPerSec = pointsPerSec,
		Heat = clampedHeat,
		HeatMult = heatMult,
		LightPercent = math.clamp(math.floor(lightPct), 4, 100),
		EquippedWisps = equippedWisps,
		RadiusLevel = radiusLevel,
		BrazierColor = brazierColor,
		WalkSpeed = walkSpeed,
		MaxWispSlots = maxWispSlots,
		CritChance = math.min(0.75, critChance),
		CritMult = critMult,
		WispsUnlocked = EconomyEngine.GetLevel(upgrades, "u_unlock_wisps") > 0,
		AlbaUnlocked = (EconomyEngine.GetLevel(upgrades, "u_unlock_alba") > 0) or ((data.AlbaCount or 0) > 0) or ((data.AlbaPoints or 0) > 0),
		HasDoubleLight = (hasDoubleLight == true or data.HasDoubleLight == true),
		AllUpgradesCompleted = allCompleted,
		CompletedUpgradesCount = completedCount,
		TotalUpgradesCount = totalCount,
		AlbaRewardPerRebirth = EconomyEngine.GetAlbaRewardPerRebirth(data),
		UnlockedZonesCount = unlockedZonesCount,
	}
end

return EconomyEngine