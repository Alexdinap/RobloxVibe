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
local BuiltTurrets = {}
local RaidAnnounceCooldown = {}

local SHADOW_TYPES = {
	{
		Id = "wisp",
		Name_en = "Void Wisp",
		Name_it = "Ombra Errante",
		MaxHP = 6,          -- Potenziata: più vita
		Speed = 5.4,
		Size = 3.4,
		DrainPct = 0.045,   -- Potenziata: fa più danni (drena più Punti Luce)
		MinDrain = 24,
		RewardMult = 18,
		Color = Color3.fromRGB(32, 14, 58),
		LightColor = Color3.fromRGB(165, 65, 255),
	},
	{
		Id = "stalker",
		Name_en = "Dusk Stalker",
		Name_it = "Ombra Predatrice",
		MaxHP = 2,          -- Meno vita, ma spawna molto più spesso
		Speed = 8.8,
		Size = 3.6,
		DrainPct = 0.03,
		MinDrain = 14,
		RewardMult = 15,
		Color = Color3.fromRGB(55, 12, 42),
		LightColor = Color3.fromRGB(235, 55, 140),
	},
	{
		Id = "brute",
		Name_en = "Abyssal Brute",
		Name_it = "Colosso d'Ombra",
		MaxHP = 24,         -- Arriva dalla 2ª rinascita
		Speed = 2.6,
		Size = 5.8,
		DrainPct = 0.08,
		MinDrain = 95,
		RewardMult = 75,
		Color = Color3.fromRGB(20, 8, 32),
		LightColor = Color3.fromRGB(255, 110, 40),
	},
	{
		Id = "siphon",
		Name_en = "Void Siphon",
		Name_it = "Sifone d'Ombra",
		MaxHP = 9,          -- Arriva dalla 1ª rinascita
		Speed = 4.2,
		Size = 4.0,
		StopRange = 22,
		DrainInterval = 2.1,
		DrainPct = 0.02,
		MinDrain = 16,
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

local function getLang(data)
	return (data and data.Language) or "en"
end

-- Quando il braciere è completo, tutto il mondo è illuminato e le ombre non spawnano più
local function isBrazierComplete(data)
	if not data then return false end
	return EconomyEngine.GetUpgradeCompletion(data) == true
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

-- Calcola statistiche torrette: partono molto scarse (0.55 dmg ogni 2.8s) e scalano con i potenziamenti
function ShadowDefenseService.GetTurretStats(data)
	local defenses = (data and data.Defenses) or {}
	local dmgLvl = EconomyEngine.GetLevel(defenses, "def_turret_dmg")
	local spdLvl = EconomyEngine.GetLevel(defenses, "def_turret_spd")

	local damage = 0.55 + (dmgLvl * 0.85)
	local cooldown = math.max(0.45, 2.8 * (0.85 ^ spdLvl))
	local range = 28 + (spdLvl * 1.5)

	return damage, cooldown, range, dmgLvl, spdLvl
end

function ShadowDefenseService.RebuildPlotDefenses(plot, data)
	if not plot or not plot.DefensesFolder then return end
	plot.DefensesFolder:ClearAllChildren()
	BuiltTurrets[plot.Index] = {}

	if not data or type(data.Defenses) ~= "table" then return end

	local turretCount = EconomyEngine.GetLevel(data.Defenses, "def_turrets")
	local dmg, cooldown, range, dmgLvl, spdLvl = ShadowDefenseService.GetTurretStats(data)

	for i = 1, math.min(turretCount, #TURRET_SLOTS) do
		local basePos = plot.Origin + TURRET_SLOTS[i]
		local ped = makePart({
			Name = "TurretPedestal_" .. i,
			Size = Vector3.new(2.6, 3.6, 2.6),
			Position = basePos + Vector3.new(0, 1.8, 0),
			Color = Color3.fromRGB(36, 40, 54),
			Material = Enum.Material.Marble,
			Parent = plot.DefensesFolder,
		})
		ped.CanCollide = false

		local scaleBonus = 1 + math.min(0.45, dmgLvl * 0.05)
		local crystalColor = spdLvl > 0 and Color3.fromRGB(255, 235, 110) or Color3.fromRGB(255, 195, 65)

		local crystal = makePart({
			Name = "TurretCrystal_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.5, 2.0, 1.5) * scaleBonus,
			Position = basePos + Vector3.new(0, 4.5, 0),
			Color = crystalColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = plot.DefensesFolder,
		})

		table.insert(BuiltTurrets[plot.Index], {
			Crystal = crystal,
			Pos = crystal.Position,
			Cooldown = (i - 1) * 0.35,
			Damage = dmg,
			AttackInterval = cooldown,
			Range = range,
		})
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

function ShadowDefenseService.DamageShadow(sh, dmg, attackerPlayer, knockbackDir, knockbackForce, slowDuration)
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
		destroyShadowEntry(sh)

		if owner and PlayerDataRef[owner.UserId] then
			local data = PlayerDataRef[owner.UserId]
			local stats = CalculateStatsFn(owner, data)
			local reward = math.max(15, math.floor(stats.ClickPower * rewardMult))
			data.Points += reward
			data.TotalPoints += reward
			if SyncPlayerFn then
				SyncPlayerFn(owner, {
					SoundCue = "Upgrade",
					PopupText = Localization.T(getLang(data), "POP_SHADOW_KILL", NumberFormat.Format(reward)),
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
	light.Range = 14
	light.Brightness = 1.6

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

	elseif wepCfg.Id == "wep_lantern" then
		handle.Size = Vector3.new(0.35, 0.9, 0.35)
		handle.Color = Color3.fromRGB(45, 42, 52)
		handle.Material = Enum.Material.Metal

		weldAttachmentPart(handle, {
			Name = "LanternCap",
			Size = Vector3.new(1.25, 0.25, 1.25),
			Color = Color3.fromRGB(210, 175, 80),
			Material = Enum.Material.Metal,
		}, CFrame.new(0, -0.55, -0.35))

		local core = weldAttachmentPart(handle, {
			Name = "LanternCore",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.95, 1.25, 0.95),
			Color = wepCfg.Color,
			Material = Enum.Material.Neon,
		}, CFrame.new(0, -1.15, -0.35))
		light.Parent = core

	else
		handle.Size = Vector3.new(0.35, 1.3, 0.35)
		handle.Color = Color3.fromRGB(40, 35, 48)
		handle.Material = Enum.Material.SmoothPlastic

		weldAttachmentPart(handle, {
			Name = "CrossGuard",
			Size = Vector3.new(1.35, 0.22, 0.45),
			Color = Color3.fromRGB(235, 190, 75),
			Material = Enum.Material.Metal,
		}, CFrame.new(0, 0.72, 0))

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

		if wepCfg.Id == "wep_lantern" then
			local candidates = {}
			for _, sh in ipairs(ActiveShadows) do
				if sh and sh.PlotIndex == plot.Index and sh.Part and sh.Part.Parent then
					local d = (sh.Part.Position - hrp.Position).Magnitude
					if d <= wepCfg.Range then
						table.insert(candidates, { Shadow = sh, Dist = d })
					end
				end
			end
			table.sort(candidates, function(a, b) return a.Dist < b.Dist end)

			local prevPos = hrp.Position + Vector3.new(0, 1.2, 0)
			local hits = math.min(3, #candidates)
			for idx = 1, hits do
				local targetSh = candidates[idx].Shadow
				local targetPos = targetSh.Part.Position
				local dmgMult = (idx == 1) and 1.0 or 0.65
				ShadowDefenseService.DamageShadow(targetSh, wepCfg.Damage * dmgMult, plr, nil, 0, 2.5)

				if DefenseFxEvent then
					DefenseFxEvent:FireClient(plr, {
						Kind = "Beam",
						From = prevPos,
						To = targetPos,
						Color = wepCfg.Color,
					})
				end
				prevPos = targetPos
			end

			if hits == 0 and DefenseFxEvent then
				DefenseFxEvent:FireClient(plr, {
					Kind = "Pulse",
					Pos = hrp.Position,
					Radius = math.min(12, wepCfg.Range * 0.5),
					Color = wepCfg.Color,
				})
			end
		else
			local isSword = (wepCfg.Id ~= "wep_torch")
			local minDot = isSword and -0.25 or 0.15
			local kbForce = isSword and 5.5 or 3.5

			for i = #ActiveShadows, 1, -1 do
				local sh = ActiveShadows[i]
				if sh and sh.PlotIndex == plot.Index and sh.Part and sh.Part.Parent then
					local offset = sh.Part.Position - hrp.Position
					local d = offset.Magnitude
					if d <= wepCfg.Range then
						local dir = d > 0.01 and offset.Unit or lookDir
						if dir:Dot(lookDir) >= minDot or d <= 5.5 then
							ShadowDefenseService.DamageShadow(sh, wepCfg.Damage, plr, dir, kbForce, 0)
						end
					end
				end
			end

			if DefenseFxEvent then
				DefenseFxEvent:FireClient(plr, {
					Kind = "Pulse",
					Pos = hrp.Position + lookDir * (wepCfg.Range * 0.35),
					Radius = wepCfg.Range,
					Color = wepCfg.Color,
				})
			end
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

-- Selezione archetipo in base alle rinascite (AlbaCount):
-- Alba 0: Predatrice (molto frequente) + Errante
-- Alba 1+: si aggiunge il Sifone d'Ombra
-- Alba 2+: si aggiunge il Colosso d'Ombra
local function pickShadowType(data)
	local alba = (data and data.AlbaCount) or 0
	local roll = math.random(1, 100)

	if alba >= 2 then
		if roll <= 15 then
			return SHADOW_TYPES[3] -- Colosso d'Ombra (15%)
		elseif roll <= 35 then
			return SHADOW_TYPES[4] -- Sifone d'Ombra (20%)
		elseif roll <= 80 then
			return SHADOW_TYPES[2] -- Ombra Predatrice (45%)
		end
		return SHADOW_TYPES[1]     -- Ombra Errante (20%)
	elseif alba >= 1 then
		if roll <= 22 then
			return SHADOW_TYPES[4] -- Sifone d'Ombra (22%)
		elseif roll <= 76 then
			return SHADOW_TYPES[2] -- Ombra Predatrice (54%)
		end
		return SHADOW_TYPES[1]     -- Ombra Errante (24%)
	else
		if roll <= 68 then
			return SHADOW_TYPES[2] -- Ombra Predatrice (68% - spawna molto di più)
		end
		return SHADOW_TYPES[1]     -- Ombra Errante (32%)
	end
end

function ShadowDefenseService.SpawnShadowForPlot(plot, data)
	if not plot or not plot.Owner or not WorldRef then return end

	-- Se il braciere è completo, il mondo è tutto illuminato e le ombre non spawnano più
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
	if countOnPlot >= 5 then return end

	local sType = pickShadowType(data)
	local alba = math.max(0, (data and data.AlbaCount) or 0)

	-- Dopo ogni rinascita tutte le ombre diventano più potenti
	local hpMult = 1 + (alba * 0.75)
	local drainMult = 1 + (alba * 0.50)
	local speedMult = 1 + math.min(0.45, alba * 0.08)
	local rewardScale = 1 + (alba * 0.55)

	local scaledMaxHP = math.max(1, math.round(sType.MaxHP * hpMult))
	local scaledSpeed = sType.Speed * speedMult
	local scaledDrainPct = math.min(0.35, sType.DrainPct * drainMult)
	local scaledMinDrain = math.max(1, math.round(sType.MinDrain * drainMult))
	local scaledRewardMult = sType.RewardMult * rewardScale

	local ang = math.random() * math.pi * 2
	local spawnPos = plot.Origin + Vector3.new(math.cos(ang) * 54, sType.Size * 0.5 + 0.8, math.sin(ang) * 54)

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
			ShadowDefenseService.DamageShadow(entry, 1, plr)
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
			task.wait(14)
			for _, plot in ipairs(PlotsRef) do
				if plot.Owner then
					local data = PlayerDataRef[plot.Owner.UserId]
					if data and not isBrazierComplete(data) then
						ShadowDefenseService.SpawnShadowForPlot(plot, data)
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

		-- Se il braciere viene completato, dissolve subito le ombre rimaste
		if not sh or not sh.Part or not sh.Part.Parent or not plot or not owner or isBrazierComplete(data) then
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
				if sh.SiphonTimer >= (sh.Type.DrainInterval or 2.1) then
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
						clickHeatTable[owner.UserId].Heat = math.max(0, (clickHeatTable[owner.UserId].Heat or 0) - 0.25)
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

	for plotIndex, turrets in pairs(BuiltTurrets) do
		local plot = PlotsRef[plotIndex]
		local owner = plot and plot.Owner
		if owner and #turrets > 0 then
			for _, t in ipairs(turrets) do
				t.Cooldown -= dt
				if t.Cooldown <= 0 then
					local targetSh = nil
					local bestDist = t.Range or 28
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
						t.Cooldown = t.AttackInterval or 2.8
						local hitPos = targetSh.Part.Position
						ShadowDefenseService.DamageShadow(targetSh, t.Damage or 0.55, owner)
						if DefenseFxEvent then
							DefenseFxEvent:FireClient(owner, {
								Kind = "Beam",
								From = t.Pos,
								To = hitPos,
								Color = Color3.fromRGB(255, 220, 75),
							})
						end
					else
						t.Cooldown = 0.35
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
	ShadowDefenseService.ClearShadowsForPlot(plotIndex)
	BuiltTurrets[plotIndex] = nil
end

return ShadowDefenseService