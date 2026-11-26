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
		TutorialCompleted = false,
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
		local minVal = r.MinPercent or r.MinLight or 0
		if lightPercent >= minVal then
			best = r
		end
	end
	return best
end

function EconomyEngine.GetAlbaRewardPerRebirth(data)
	local albaPerks = (data and data.AlbaPerks) or {}
	local bonusLvl = EconomyEngine.GetLevel(albaPerks, "ap_alba_gain")
	return 1 + bonusLvl
end

function EconomyEngine.GetCostDiscountMult(data)
	local albaPerks = (data and data.AlbaPerks) or {}
	local discLvl = EconomyEngine.GetLevel(albaPerks, "ap_discount")
	return math.max(0.30, 1.0 - (discLvl * 0.08))
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

	-- 1. Character Upgrades
	local baseClick = 1.0
	local charClickMult = 1.0
	local charPassiveAdd = 0.0
	local charPassiveMult = 1.0
	local charAllMult = 1.0
	local critChance = 0.05
	local critMult = 5.0
	local walkSpeed = 16.0
	local extraWispSlots = 0
	local lightPct = 4.0
	local baseClickCooldown = 0.50
	local minClickCooldown = 0.08
	local cooldownReduction = 0.0

	for _, u in ipairs(GameConfig.Upgrades) do
		local lvl = EconomyEngine.GetLevel(upgrades, u.Id)
		if lvl > 0 then
			lightPct += (u.LightPct or 2.0) * lvl
			if u.CooldownReduce then
				cooldownReduction += u.CooldownReduce * lvl
			end
			if u.PassiveAdd then
				charPassiveAdd += u.PassiveAdd * lvl
			end
			if u.WalkSpeedAdd then
				walkSpeed += u.WalkSpeedAdd * lvl
			end
			if u.CritChanceAdd then
				critChance += u.CritChanceAdd * lvl
			end
			if u.CritMultAdd then
				critMult += u.CritMultAdd * lvl
			end
			if u.ClickMult then
				charClickMult *= (u.ClickMult ^ lvl)
			end
			if u.PassiveMult then
				charPassiveMult *= (u.PassiveMult ^ lvl)
			end
			if u.AllMult then
				charAllMult *= (u.AllMult ^ lvl)
			end
			if u.WispSlotAdd then
				extraWispSlots += u.WispSlotAdd * lvl
			end
		end
	end

	local clickCooldown = math.max(minClickCooldown, baseClickCooldown - cooldownReduction)

	-- 2. Ground Pads & Brazier Stats
	local brazierPps = 0.0
	local brazierAllMult = 1.0
	local colorLightBonus = 0.0
	local radiusLevel = 1
	local heatBonusMax = 0.0
	local brazierColor = Color3.fromRGB(255, 145, 45)
	local highestColorTier = 0
	local totalBrazierLevels = 0

	for idx, alt in ipairs(GameConfig.Altars) do
		local lvl = EconomyEngine.GetLevel(altars, alt.Id)
		if lvl > 0 then
			totalBrazierLevels += lvl
			if alt.ClickBonus then
				baseClick += alt.ClickBonus * lvl
			end
			if alt.PassiveBonus then
				brazierPps += alt.PassiveBonus * lvl
			end
			if alt.MultBonus then
				brazierAllMult *= ((1 + alt.MultBonus) ^ lvl)
			end
			if alt.RadiusBonus then
				radiusLevel += alt.RadiusBonus * lvl
			end
			if alt.HeatCapBonus then
				heatBonusMax += alt.HeatCapBonus * lvl
			end
			if alt.AllLightBonus then
				colorLightBonus += alt.AllLightBonus * lvl
			end
			if alt.BrazierColor and idx >= highestColorTier then
				highestColorTier = idx
				brazierColor = alt.BrazierColor
			end
		end
	end

	local colorMult = 1.0 + colorLightBonus
	lightPct += math.min(55, totalBrazierLevels * 0.45)

	-- 3. Equipped Light Wisps
	local baseWispSlots = GameConfig.BaseEquippedWisps or 3
	local maxWispSlots = baseWispSlots + extraWispSlots
	local allWisps = {}
	for _, rawId in ipairs(data.Wisps or {}) do
		local cfg, isRad = EconomyEngine.ParseWispId(rawId)
		if cfg then
			local cMult = cfg.ClickMult * (isRad and 2.5 or 1.0)
			local pMult = (cfg.PassiveMult or cfg.ClickMult) * (isRad and 2.5 or 1.0)
			table.insert(allWisps, { RawId = rawId, Config = cfg, ClickMult = cMult, PassiveMult = pMult })
		end
	end
	table.sort(allWisps, function(a, b) return a.ClickMult > b.ClickMult end)

	local equippedWisps = {}
	local wispClickMult = 1.0
	local wispPassiveMult = 1.0
	for i = 1, math.min(#allWisps, maxWispSlots) do
		table.insert(equippedWisps, allWisps[i])
		wispClickMult *= allWisps[i].ClickMult
		wispPassiveMult *= allWisps[i].PassiveMult
	end

	-- 4. Dawn Perks & Unlocked Monument Zones
	local albaMultLvl = EconomyEngine.GetLevel(albaPerks, "ap_mult")
	local albaMult = 1.0 + (albaMultLvl * 0.50)

	local zonesMult = 1.0
	local unlockedZonesCount = 1
	for _, z in ipairs(GameConfig.AlbaZones) do
		if unlockedZones[z.Id] == true then
			zonesMult *= (z.LightMult or 1.0)
			unlockedZonesCount += 1
		end
	end

	local r1Cfg = GameConfig.Regno1 or {}
	local regno1PermMult = (data.Regno1 and data.Regno1.Completed) and (r1Cfg.PermanentBlessingMult or 1.35) or 1.0
	local activeBuff = regno1BuffMult or 1.0
	local passMult = (hasDoubleLight or data.HasDoubleLight) and 2.0 or 1.0

	local clampedHeat = math.clamp(heat or 0, 0, 1)
	local heatMult = 1.0 + clampedHeat * (0.5 + heatBonusMax)

	local globalMult = charAllMult * brazierAllMult * colorMult * albaMult * zonesMult * regno1PermMult * activeBuff * passMult * heatMult
	local clickPower = baseClick * charClickMult * wispClickMult * globalMult
	local pointsPerSec = (brazierPps + charPassiveAdd) * charPassiveMult * wispPassiveMult * globalMult

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
		AlbaUnlocked = (allCompleted == true) or ((data.AlbaCount or 0) > 0) or ((data.AlbaPoints or 0) > 0),
		HasDoubleLight = (hasDoubleLight == true or data.HasDoubleLight == true),
		AllUpgradesCompleted = allCompleted,
		CompletedUpgradesCount = completedCount,
		TotalUpgradesCount = totalCount,
		AlbaRewardPerRebirth = EconomyEngine.GetAlbaRewardPerRebirth(data),
		UnlockedZonesCount = unlockedZonesCount,
	}
end

return EconomyEngine