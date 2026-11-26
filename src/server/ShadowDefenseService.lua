local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local ShadowDefenseService = {}

local WorldRef = nil
local PlotsRef = {}
local PlayerDataRef = {}
local PlayerPlotMapRef = {}
local SyncPlayerFn = nil
local CalculateStatsFn = nil
local DefenseFxEvent = nil

local ActiveShadows = {}
local PlotDefensesState = {}
local RaidAnnounceCooldown = {}
local PlotGraceUntil = {}
local PlotGraceInitial = {}

local SHADOW_TYPES = {
	{
		Id = "wisp",
		Name_en = "Void Wisp",
		Name_it = "Ombra Errante",
		MaxHP = 18,
		Speed = 5.6,
		Size = 3.4,
		DrainPct = 0.08,
		MinDrain = 55,
		RewardMult = 18,
		Color = Color3.fromRGB(32, 14, 58),
		LightColor = Color3.fromRGB(165, 65, 255),
	},
	{
		Id = "stalker",
		Name_en = "Dusk Stalker",
		Name_it = "Ombra Predatrice",
		MaxHP = 10,
		Speed = 9.0,
		Size = 3.6,
		DrainPct = 0.06,
		MinDrain = 35,
		RewardMult = 15,
		Color = Color3.fromRGB(55, 12, 42),
		LightColor = Color3.fromRGB(235, 55, 140),
	},
	{
		Id = "brute",
		Name_en = "Abyssal Brute",
		Name_it = "Colosso d'Ombra",
		MaxHP = 95,
		Speed = 2.8,
		Size = 5.8,
		DrainPct = 0.15,
		MinDrain = 220,
		RewardMult = 75,
		Color = Color3.fromRGB(20, 8, 32),
		LightColor = Color3.fromRGB(255, 110, 40),
	},
	{
		Id = "siphon",
		Name_en = "Void Siphon",
		Name_it = "Sifone d'Ombra",
		MaxHP = 34,
		Speed = 4.4,
		Size = 4.0,
		StopRange = 22,
		DrainInterval = 1.6,
		DrainPct = 0.045,
		MinDrain = 40,
		RewardMult = 42,
		Color = Color3.fromRGB(14, 28, 46),
		LightColor = Color3.fromRGB(0, 215, 255),
	},
}

local TURRET_SLOTS = {
	Vector3.new(15, 0, 15),
	Vector3.new(-15, 0, 15),
	Vector3.new(15, 0, -15),
	Vector3.new(-15, 0, -15),
}

local PRISM_SLOTS = {
	Vector3.new(21, 0, 0),
	Vector3.new(-21, 0, 0),
	Vector3.new(0, 0, 21),
	Vector3.new(0, 0, -21),
	Vector3.new(0, 0, -26),
}

local function getLang(data)
	return (data and data.Language) or "en"
end

local function isBrazierComplete(data)
	if not data then return false end
	return EconomyEngine.GetUpgradeCompletion(data) == true
end

function ShadowDefenseService.StartGracePeriod(plotIndex, duration, isInitial)
	if not plotIndex then return end
	PlotGraceUntil[plotIndex] = os.clock() + (duration or GameConfig.RebirthShadowGraceSeconds or 120)
	PlotGraceInitial[plotIndex] = (isInitial == true)
	ShadowDefenseService.ClearShadowsForPlot(plotIndex)
end

function ShadowDefenseService.GetGraceRemaining(plotIndex)
	if not plotIndex then return 0 end
	local untilTime = PlotGraceUntil[plotIndex]
	if not untilTime then return 0 end
	local rem = math.ceil(untilTime - os.clock())
	if rem <= 0 then
		PlotGraceUntil[plotIndex] = nil
		PlotGraceInitial[plotIndex] = nil
		return 0
	end
	return rem
end

function ShadowDefenseService.IsInitialGrace(plotIndex)
	if not plotIndex then return false end
	return ShadowDefenseService.GetGraceRemaining(plotIndex) > 0 and (PlotGraceInitial[plotIndex] == true)
end

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function weldAttachmentPart(handle, props, offsetCFrame)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	for k, v in pairs(props) do
		p[k] = v
	end
	p.CFrame = handle.CFrame * offsetCFrame
	p.Parent = handle.Parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	return p
end

function ShadowDefenseService.RebuildPlotDefenses(plot, data)
	if not plot or not plot.DefensesFolder then return end
	plot.DefensesFolder:ClearAllChildren()
	PlotDefensesState[plot.Index] = {
		Turrets = {},
		Ward = nil,
		Prisms = {},
	}

	if not data or type(data.Defenses) ~= "table" then return end

	local state = PlotDefensesState[plot.Index]

	-- 1. Sunfire Turrets (def_pylon_1, MaxLevel = 8)
	local pylonLvl = EconomyEngine.GetLevel(data.Defenses, "def_pylon_1")
	if pylonLvl > 0 then
		local activeCount = math.min(#TURRET_SLOTS, pylonLvl)
		local dmg = 14 * (1 + (pylonLvl - 1) * 0.45)
		local interval = math.max(0.38, 1.1 * (0.90 ^ (pylonLvl - 1)))
		local range = 36 + (pylonLvl * 1.5)

		for i = 1, activeCount do
			local basePos = plot.Origin + TURRET_SLOTS[i]
			makePart({
				Name = "SunfirePedestal_" .. i,
				Size = Vector3.new(2.6, 3.8, 2.6),
				Position = basePos + Vector3.new(0, 1.9, 0),
				Color = Color3.fromRGB(36, 40, 54),
				Material = Enum.Material.Marble,
				CanCollide = false,
				Parent = plot.DefensesFolder,
			})

			local scaleBonus = 1 + math.min(0.45, pylonLvl * 0.05)
			local crystal = makePart({
				Name = "SunfireCrystal_" .. i,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(1.5, 2.0, 1.5) * scaleBonus,
				Position = basePos + Vector3.new(0, 4.7, 0),
				Color = Color3.fromRGB(255, 200, 65),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = plot.DefensesFolder,
			})

			table.insert(state.Turrets, {
				Pos = crystal.Position,
				Cooldown = (i - 1) * 0.25,
				Damage = dmg,
				AttackInterval = interval,
				Range = range,
				Color = Color3.fromRGB(255, 215, 75),
			})
		end
	end

	-- 2. Radiant Ward (def_ward_ring, MaxLevel = 6)
	local wardLvl = EconomyEngine.GetLevel(data.Defenses, "def_ward_ring")
	if wardLvl > 0 then
		local radius = 26 + (wardLvl - 1) * 2.0
		local wardRing = makePart({
			Name = "RadiantWardRing",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.18, radius * 2, radius * 2),
			CFrame = CFrame.new(plot.Origin + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(80, 225, 255),
			Material = Enum.Material.Neon,
			Transparency = 0.72,
			CanCollide = false,
			CanQuery = false,
			Parent = plot.DefensesFolder,
		})
		wardRing.CanTouch = false

		state.Ward = {
			Radius = radius,
			Damage = 10 * (1 + (wardLvl - 1) * 0.55),
			TickInterval = 0.8,
			Timer = 0,
			SlowDuration = 1.4 + wardLvl * 0.2,
		}
	end

	-- 3. Zenith Prism Tower (def_obelisk_beam, MaxLevel = 5)
	local prismLvl = EconomyEngine.GetLevel(data.Defenses, "def_obelisk_beam")
	if prismLvl > 0 then
		local prismCount = math.min(#PRISM_SLOTS, prismLvl)
		local dmg = 65 * (1 + (prismLvl - 1) * 0.65)
		local interval = math.max(0.65, 1.4 * (0.92 ^ (prismLvl - 1)))
		local range = 46 + (prismLvl * 2)

		for i = 1, prismCount do
			local basePos = plot.Origin + PRISM_SLOTS[i]
			makePart({
				Name = "PrismObelisk_" .. i,
				Size = Vector3.new(2.2, 6.4, 2.2),
				Position = basePos + Vector3.new(0, 3.2, 0),
				Color = Color3.fromRGB(26, 32, 48),
				Material = Enum.Material.Marble,
				CanCollide = false,
				Parent = plot.DefensesFolder,
			})

			local orb = makePart({
				Name = "PrismCore_" .. i,
				Shape = Enum.PartType.Ball,
				Size = Vector3.new(2.1, 2.1, 2.1),
				Position = basePos + Vector3.new(0, 7.6, 0),
				Color = Color3.fromRGB(205, 125, 255),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = plot.DefensesFolder,
			})

			table.insert(state.Prisms, {
				Pos = orb.Position,
				Cooldown = (i - 1) * 0.35,
				Damage = dmg,
				AttackInterval = interval,
				Range = range,
				BonusDawnChance = 0.12 * prismLvl,
				Color = Color3.fromRGB(210, 125, 255),
			})
		end
	end
end

local function updateShadowHealthBar(sh)
	if not sh or not sh.HpFill or not sh.HpBg then return end
	local pct = math.clamp(sh.HP / math.max(1, sh.MaxHP), 0, 1)
	sh.HpBg.Visible = (sh.HP < sh.MaxHP)
	sh.HpFill.Size = UDim2.new(pct, 0, 1, 0)
	if sh.Part then
		sh.Part:SetAttribute("HP", sh.HP)
	end
end

local function destroyShadowEntry(sh)
	local idx = table.find(ActiveShadows, sh)
	if idx then
		table.remove(ActiveShadows, idx)
	end
	if sh.Part and sh.Part.Parent then
		sh.Part:Destroy()
	end
end

function ShadowDefenseService.DamageShadow(sh, dmg, attackerPlayer, knockbackDir, knockbackForce, slowDuration, bonusDawnChance)
	if not sh or not sh.Part or not sh.Part.Parent then return false end

	if slowDuration and slowDuration > 0 then
		sh.SlowUntil = math.max(sh.SlowUntil or 0, os.clock() + slowDuration)
		sh.Part:SetAttribute("IsSlowed", true)
	end

	if knockbackDir and knockbackForce and knockbackForce > 0 then
		local flatDir = Vector3.new(knockbackDir.X, 0, knockbackDir.Z)
		if flatDir.Magnitude > 0.01 then
			local plot = PlotsRef[sh.PlotIndex]
			local nextPos = sh.Part.Position + flatDir.Unit * knockbackForce
			if plot then
				local fromOrigin = Vector3.new(nextPos.X - plot.Origin.X, 0, nextPos.Z - plot.Origin.Z)
				if fromOrigin.Magnitude <= 56 then
					sh.Part.Position = nextPos
				end
			else
				sh.Part.Position = nextPos
			end
		end
	end

	sh.HP -= dmg
	if sh.HP <= 0 then
		local plot = PlotsRef[sh.PlotIndex]
		local owner = attackerPlayer or (plot and plot.Owner)
		local rewardMult = sh.RewardMult
		local isBrute = (sh.Type and sh.Type.Id == "brute")
		destroyShadowEntry(sh)

		if owner and PlayerDataRef[owner.UserId] then
			local data = PlayerDataRef[owner.UserId]
			local stats = CalculateStatsFn(owner, data)
			local reward = math.max(15, math.floor(stats.ClickPower * rewardMult))
			data.Points += reward
			data.TotalPoints += reward

			local extraDawn = 0
			if isBrute and bonusDawnChance and bonusDawnChance > 0 and math.random() < bonusDawnChance then
				extraDawn = 1
				data.AlbaPoints = (data.AlbaPoints or 0) + 1
			end

			if SyncPlayerFn then
				local pop = Localization.T(getLang(data), "POP_SHADOW_KILL", NumberFormat.Format(reward))
				if extraDawn > 0 then
					pop = pop .. " (+1 🌅)"
				end
				SyncPlayerFn(owner, {
					SoundCue = "Upgrade",
					PopupText = pop,
				})
			end
		end
		return true
	else
		updateShadowHealthBar(sh)
		return false
	end
end

local function createWeaponTool(wepCfg, lang)
	local tool = Instance.new("Tool")
	tool.Name = Localization.Pick(lang, wepCfg.Name, wepCfg.Name_it)
	tool:SetAttribute("WeaponId", wepCfg.Id)
	tool.RequiresHandle = true
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local light = Instance.new("PointLight")
	light.Color = wepCfg.Color
	light.Range = 16
	light.Brightness = 1.8

	if wepCfg.Id == "wep_torch" then
		handle.Size = Vector3.new(0.45, 3.0, 0.45)
		handle.Color = Color3.fromRGB(92, 58, 32)
		handle.Material = Enum.Material.Wood

		weldAttachmentPart(handle, {
			Name = "TorchCup",
			Size = Vector3.new(0.85, 0.35, 0.85),
			Color = Color3.fromRGB(50, 48, 55),
			Material = Enum.Material.Metal,
		}, CFrame.new(0, 1.45, 0))

		local tip = weldAttachmentPart(handle, {
			Name = "FlameTip",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.05, 1.35, 1.05),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, 1.95, 0))
		light.Parent = tip

	elseif wepCfg.Id == "wep_aether_spear" then
		handle.Size = Vector3.new(0.30, 4.6, 0.30)
		handle.Color = Color3.fromRGB(70, 45, 28)
		handle.Material = Enum.Material.Wood

		local spearHead = weldAttachmentPart(handle, {
			Name = "SpearHead",
			Size = Vector3.new(0.24, 1.9, 0.72),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, 2.85, 0))
		light.Parent = spearHead

	elseif wepCfg.Id == "wep_sunblade" then
		handle.Size = Vector3.new(0.42, 1.6, 0.42)
		handle.Color = Color3.fromRGB(42, 35, 48)
		handle.Material = Enum.Material.SmoothPlastic

		weldAttachmentPart(handle, {
			Name = "HeavyGuard",
			Size = Vector3.new(1.85, 0.28, 0.55),
			Color = Color3.fromRGB(255, 195, 65),
			Material = Enum.Material.Metal,
		}, CFrame.new(0, 0.9, 0))

		local heavyBlade = weldAttachmentPart(handle, {
			Name = "SolarBlade",
			Size = Vector3.new(0.24, 4.4, 0.85),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, 3.15, 0))
		light.Parent = heavyBlade

	elseif wepCfg.Id == "wep_zenith_scythe" then
		handle.Size = Vector3.new(0.34, 4.8, 0.34)
		handle.Color = Color3.fromRGB(245, 235, 200)
		handle.Material = Enum.Material.Neon

		local scytheArc = weldAttachmentPart(handle, {
			Name = "ZenithBlade",
			Size = Vector3.new(0.22, 0.85, 3.3),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, 2.3, -1.2))
		light.Parent = scytheArc

	else
		handle.Size = Vector3.new(0.35, 1.3, 0.35)
		handle.Color = Color3.fromRGB(40, 35, 48)
		handle.Material = Enum.Material.SmoothPlastic

		local blade = weldAttachmentPart(handle, {
			Name = "LightBlade",
			Size = Vector3.new(0.18, 3.6, 0.55),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, 2.55, 0))
		light.Parent = blade
	end

	local lastUse = 0
	tool.Activated:Connect(function()
		local char = tool.Parent
		local plr = char and Players:GetPlayerFromCharacter(char)
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not plr or not hrp then return end

		local now = os.clock()
		if now - lastUse < (wepCfg.Cooldown or 0.45) then return end
		lastUse = now

		local plot = PlayerPlotMapRef[plr.UserId]
		if not plot then return end

		local lookDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
		if lookDir.Magnitude > 0.01 then
			lookDir = lookDir.Unit
		else
			lookDir = Vector3.new(0, 0, -1)
		end

		local isCosmicArc = (wepCfg.Id == "wep_zenith_scythe")
		local isCleave = (wepCfg.Id == "wep_sunblade")
		local minDot = isCosmicArc and -1.0 or (isCleave and -0.35 or 0.1)
		local kbForce = isCosmicArc and 11.0 or (isCleave and 7.0 or 4.5)

		for i = #ActiveShadows, 1, -1 do
			local sh = ActiveShadows[i]
			if sh and sh.PlotIndex == plot.Index and sh.Part and sh.Part.Parent then
				local offset = sh.Part.Position - hrp.Position
				local d = offset.Magnitude
				if d <= wepCfg.Range then
					local dir = d > 0.01 and offset.Unit or lookDir
					if dir:Dot(lookDir) >= minDot or d <= 6.5 then
						ShadowDefenseService.DamageShadow(sh, wepCfg.Damage, plr, dir, kbForce, 0)
					end
				end
			end
		end

		if DefenseFxEvent then
			local fxPos = isCosmicArc and hrp.Position or (hrp.Position + lookDir * (wepCfg.Range * 0.35))
			DefenseFxEvent:FireClient(plr, {
				Kind = "Pulse",
				Pos = fxPos,
				Radius = wepCfg.Range,
				Color = wepCfg.Color,
			})
		end
	end)

	return tool
end

function ShadowDefenseService.SyncPlayerTools(player, data)
	if not player or not data then return end
	local owned = data.OwnedWeapons or {}
	local lang = getLang(data)

	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character

	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("WeaponId") then
				item:Destroy()
			end
		end
	end
	if char then
		for _, item in ipairs(char:GetChildren()) do
			if item:IsA("Tool") and item:GetAttribute("WeaponId") then
				item:Destroy()
			end
		end
	end

	if not backpack then return end
	for _, wep in ipairs(GameConfig.Weapons) do
		if owned[wep.Id] == true then
			local tool = createWeaponTool(wep, lang)
			tool.Parent = backpack
		end
	end
end

local function pickShadowType(data)
	local alba = (data and data.AlbaCount) or 0
	local roll = math.random(1, 100)

	if alba >= 2 then
		if roll <= 16 then
			return SHADOW_TYPES[3]
		elseif roll <= 36 then
			return SHADOW_TYPES[4]
		elseif roll <= 80 then
			return SHADOW_TYPES[2]
		end
		return SHADOW_TYPES[1]
	elseif alba >= 1 then
		if roll <= 24 then
			return SHADOW_TYPES[4]
		elseif roll <= 76 then
			return SHADOW_TYPES[2]
		end
		return SHADOW_TYPES[1]
	else
		if roll <= 68 then
			return SHADOW_TYPES[2]
		end
		return SHADOW_TYPES[1]
	end
end

function ShadowDefenseService.SpawnShadowForPlot(plot, data)
	if not plot or not plot.Owner or not WorldRef then return end

	if ShadowDefenseService.GetGraceRemaining(plot.Index) > 0 then
		return
	end

	if isBrazierComplete(data) then
		ShadowDefenseService.ClearShadowsForPlot(plot.Index)
		return
	end

	local countOnPlot = 0
	for _, sh in ipairs(ActiveShadows) do
		if sh.PlotIndex == plot.Index then
			countOnPlot += 1
		end
	end
	if countOnPlot >= 8 then return end

	local sType = pickShadowType(data)
	local alba = math.max(0, (data and data.AlbaCount) or 0)

	local hpMult = 1 + (alba * 0.75)
	local drainMult = 1 + (alba * 0.65)
	local speedMult = 1 + math.min(0.50, alba * 0.09)
	local rewardScale = 1 + (alba * 0.55)

	local scaledMaxHP = math.max(1, math.round(sType.MaxHP * hpMult))
	local scaledSpeed = sType.Speed * speedMult
	local scaledDrainPct = math.min(0.45, sType.DrainPct * drainMult)
	local scaledMinDrain = math.max(1, math.round(sType.MinDrain * drainMult))
	local scaledRewardMult = sType.RewardMult * rewardScale

	local ang = math.random() * math.pi * 2
	local spawnPos = plot.Origin + Vector3.new(math.cos(ang) * 40, sType.Size * 0.5 + 0.8, math.sin(ang) * 40)

	local part = makePart({
		Name = "InvadingShadow",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(sType.Size, sType.Size, sType.Size),
		Position = spawnPos,
		Color = sType.Color,
		Transparency = 1,
		CanCollide = false,
		Parent = WorldRef,
	})
	part:SetAttribute("ShadowTypeId", sType.Id)
	part:SetAttribute("PlotIndex", plot.Index)
	part:SetAttribute("HP", scaledMaxHP)
	part:SetAttribute("MaxHP", scaledMaxHP)

	local bbg = Instance.new("BillboardGui", part)
	bbg.Size = UDim2.fromOffset(78, 12)
	bbg.StudsOffset = Vector3.new(0, sType.Size * 0.7 + 1.4, 0)
	bbg.AlwaysOnTop = false

	local hpBg = Instance.new("Frame", bbg)
	hpBg.Size = UDim2.fromScale(1, 1)
	hpBg.BackgroundColor3 = Color3.fromRGB(24, 16, 32)
	hpBg.BorderSizePixel = 0
	hpBg.Visible = false
	Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

	local hpFill = Instance.new("Frame", hpBg)
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = sType.LightColor
	hpFill.BorderSizePixel = 0
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

	local entry = {
		PlotIndex = plot.Index,
		Type = sType,
		HP = scaledMaxHP,
		MaxHP = scaledMaxHP,
		Speed = scaledSpeed,
		DrainPct = scaledDrainPct,
		MinDrain = scaledMinDrain,
		RewardMult = scaledRewardMult,
		Part = part,
		HpBg = hpBg,
		HpFill = hpFill,
		SlowUntil = 0,
		SiphonTimer = 0,
	}

	local cd = Instance.new("ClickDetector", part)
	cd.MaxActivationDistance = 55
	cd.MouseClick:Connect(function(plr)
		if plot.Owner == plr then
			ShadowDefenseService.DamageShadow(entry, 5, plr)
		end
	end)

	table.insert(ActiveShadows, entry)

	local owner = plot.Owner
	local now = os.clock()
	if owner and (not RaidAnnounceCooldown[owner.UserId] or now - RaidAnnounceCooldown[owner.UserId] > 35) then
		RaidAnnounceCooldown[owner.UserId] = now
		if SyncPlayerFn then
			SyncPlayerFn(owner, {
				PopupText = Localization.T(getLang(data), "POP_SHADOW_RAID"),
			})
		end
	end
end

function ShadowDefenseService.Init(world, remotesFolder, plots, playerData, playerPlotMap, syncPlayerFn, calcStatsFn)
	WorldRef = world
	PlotsRef = plots
	PlayerDataRef = playerData
	PlayerPlotMapRef = playerPlotMap
	SyncPlayerFn = syncPlayerFn
	CalculateStatsFn = calcStatsFn

	DefenseFxEvent = Instance.new("RemoteEvent", remotesFolder)
	DefenseFxEvent.Name = "DefenseFx"

	task.spawn(function()
		while true do
			task.wait(7.5)
			for _, plot in ipairs(PlotsRef) do
				if plot.Owner and ShadowDefenseService.GetGraceRemaining(plot.Index) <= 0 then
					local data = PlayerDataRef[plot.Owner.UserId]
					if data and not isBrazierComplete(data) then
						ShadowDefenseService.SpawnShadowForPlot(plot, data)
						local extraChance = ((data.AlbaCount or 0) >= 1) and 0.45 or 0.25
						if math.random() < extraChance then
							ShadowDefenseService.SpawnShadowForPlot(plot, data)
						end
					end
				end
			end
		end
	end)
end

function ShadowDefenseService.Tick(dt, clickHeatTable)
	local now = os.clock()

	for i = #ActiveShadows, 1, -1 do
		local sh = ActiveShadows[i]
		local plot = sh and PlotsRef[sh.PlotIndex]
		local owner = plot and plot.Owner
		local data = owner and PlayerDataRef[owner.UserId]

		if not sh or not sh.Part or not sh.Part.Parent or not plot or not owner or isBrazierComplete(data) or ShadowDefenseService.GetGraceRemaining(sh.PlotIndex) > 0 then
			if sh then destroyShadowEntry(sh) end
		else
			local targetPos = Vector3.new(plot.Origin.X, sh.Part.Position.Y, plot.Origin.Z)
			local toCenter = targetPos - sh.Part.Position
			local dist = toCenter.Magnitude

			local speedMult = 1.0
			if now < (sh.SlowUntil or 0) then
				speedMult = 0.45
			elseif sh.Part:GetAttribute("IsSlowed") then
				sh.Part:SetAttribute("IsSlowed", false)
			end

			if sh.Type.StopRange and dist <= sh.Type.StopRange then
				sh.SiphonTimer = (sh.SiphonTimer or 0) + dt
				if sh.SiphonTimer >= (sh.Type.DrainInterval or 1.6) then
					sh.SiphonTimer = 0
					if data then
						local currentPts = math.floor(data.Points or 0)
						if currentPts > 0 then
							local drain = math.min(currentPts, math.max(sh.MinDrain, math.floor(currentPts * sh.DrainPct)))
							data.Points = math.max(0, currentPts - drain)
							if SyncPlayerFn then
								SyncPlayerFn(owner, {
									PopupText = Localization.T(getLang(data), "POP_SHADOW_HIT", NumberFormat.Format(drain)),
								})
							end
						end
						if DefenseFxEvent then
							DefenseFxEvent:FireClient(owner, {
								Kind = "Beam",
								From = sh.Part.Position,
								To = plot.Origin + Vector3.new(0, 4.5, 0),
								Color = sh.Type.LightColor,
							})
						end
					end
				end
			elseif dist <= 7.2 then
				destroyShadowEntry(sh)

				if data then
					local currentPts = math.floor(data.Points or 0)
					local drain = 0
					if currentPts > 0 then
						drain = math.min(currentPts, math.max(sh.MinDrain, math.floor(currentPts * sh.DrainPct)))
						data.Points = math.max(0, currentPts - drain)
					end
					if clickHeatTable and clickHeatTable[owner.UserId] then
						clickHeatTable[owner.UserId].Heat = math.max(0, (clickHeatTable[owner.UserId].Heat or 0) - 0.35)
					end
					if SyncPlayerFn then
						SyncPlayerFn(owner, {
							Shockwave = true,
							PopupText = Localization.T(getLang(data), "POP_SHADOW_HIT", NumberFormat.Format(drain)),
						})
					end
				end
			else
				sh.Part.CFrame = CFrame.lookAt(sh.Part.Position, targetPos) + toCenter.Unit * (sh.Speed * speedMult * dt)
			end
		end
	end

	for plotIndex, defState in pairs(PlotDefensesState) do
		local plot = PlotsRef[plotIndex]
		local owner = plot and plot.Owner
		if owner and defState then
			-- 1. Sunfire Turrets
			for _, t in ipairs(defState.Turrets) do
				t.Cooldown -= dt
				if t.Cooldown <= 0 then
					local targetSh = nil
					local bestDist = t.Range
					for _, sh in ipairs(ActiveShadows) do
						if sh.PlotIndex == plotIndex and sh.Part and sh.Part.Parent then
							local d = (sh.Part.Position - t.Pos).Magnitude
							if d <= bestDist then
								bestDist = d
								targetSh = sh
							end
						end
					end

					if targetSh then
						t.Cooldown = t.AttackInterval
						local hitPos = targetSh.Part.Position
						ShadowDefenseService.DamageShadow(targetSh, t.Damage, owner)
						if DefenseFxEvent then
							DefenseFxEvent:FireClient(owner, {
								Kind = "Beam",
								From = t.Pos,
								To = hitPos,
								Color = t.Color,
							})
						end
					else
						t.Cooldown = 0.25
					end
				end
			end

			-- 2. Radiant Ward (rallenta e brucia nel perimetro)
			if defState.Ward then
				local w = defState.Ward
				w.Timer += dt
				if w.Timer >= w.TickInterval then
					w.Timer = 0
					for i = #ActiveShadows, 1, -1 do
						local sh = ActiveShadows[i]
						if sh and sh.PlotIndex == plotIndex and sh.Part and sh.Part.Parent then
							local d = (Vector3.new(sh.Part.Position.X, plot.Origin.Y, sh.Part.Position.Z) - plot.Origin).Magnitude
							if d <= w.Radius then
								ShadowDefenseService.DamageShadow(sh, w.Damage, owner, nil, 0, w.SlowDuration)
							end
						end
					end
				end
			end

			-- 3. Zenith Prism Towers (priorità ai Colossi d'Ombra + Punti Alba bonus)
			for _, p in ipairs(defState.Prisms) do
				p.Cooldown -= dt
				if p.Cooldown <= 0 then
					local targetSh = nil
					local bestScore = -1
					for _, sh in ipairs(ActiveShadows) do
						if sh.PlotIndex == plotIndex and sh.Part and sh.Part.Parent then
							local d = (sh.Part.Position - p.Pos).Magnitude
							if d <= p.Range then
								local score = (sh.Type.Id == "brute" and 1000 or 0) + (p.Range - d)
								if score > bestScore then
									bestScore = score
									targetSh = sh
								end
							end
						end
					end

					if targetSh then
						p.Cooldown = p.AttackInterval
						local hitPos = targetSh.Part.Position
						ShadowDefenseService.DamageShadow(targetSh, p.Damage, owner, nil, 0, 0, p.BonusDawnChance)
						if DefenseFxEvent then
							DefenseFxEvent:FireClient(owner, {
								Kind = "Beam",
								From = p.Pos,
								To = hitPos,
								Color = p.Color,
							})
						end
					else
						p.Cooldown = 0.3
					end
				end
			end
		end
	end
end

function ShadowDefenseService.ClearShadowsForPlot(plotIndex)
	for i = #ActiveShadows, 1, -1 do
		if ActiveShadows[i].PlotIndex == plotIndex then
			destroyShadowEntry(ActiveShadows[i])
		end
	end
end

function ShadowDefenseService.ClearPlot(plotIndex)
	PlotGraceUntil[plotIndex] = nil
	PlotGraceInitial[plotIndex] = nil
	ShadowDefenseService.ClearShadowsForPlot(plotIndex)
	PlotDefensesState[plotIndex] = nil
end

return ShadowDefenseService