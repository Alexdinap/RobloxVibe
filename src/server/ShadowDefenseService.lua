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
local BuiltWallNodes = {}
local BuiltTurrets = {}
local RaidAnnounceCooldown = {}

local SHADOW_TYPES = {
	{
		Id = "wisp",
		Name_en = "Void Wisp",
		Name_it = "Ombra Errante",
		MaxHP = 2,
		Speed = 5.2,
		Size = 3.2,
		DrainPct = 0.02,
		MinDrain = 5,
		RewardMult = 12,
		Color = Color3.fromRGB(32, 14, 58),
		LightColor = Color3.fromRGB(165, 65, 255),
	},
	{
		Id = "stalker",
		Name_en = "Dusk Stalker",
		Name_it = "Ombra Predatrice",
		MaxHP = 6,
		Speed = 3.8,
		Size = 4.2,
		DrainPct = 0.04,
		MinDrain = 25,
		RewardMult = 26,
		Color = Color3.fromRGB(55, 12, 42),
		LightColor = Color3.fromRGB(235, 55, 140),
	},
	{
		Id = "brute",
		Name_en = "Abyssal Brute",
		Name_it = "Colosso d'Ombra",
		MaxHP = 15,
		Speed = 2.5,
		Size = 5.6,
		DrainPct = 0.07,
		MinDrain = 80,
		RewardMult = 65,
		Color = Color3.fromRGB(20, 8, 32),
		LightColor = Color3.fromRGB(190, 40, 255),
	},
}

local WALL_SLOTS = {
	{ Dir = Vector3.new(0, 0, 1),  RotY = 0 },
	{ Dir = Vector3.new(0, 0, -1), RotY = 0 },
	{ Dir = Vector3.new(1, 0, 0),  RotY = 90 },
	{ Dir = Vector3.new(-1, 0, 0), RotY = 90 },
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

function ShadowDefenseService.RebuildPlotDefenses(plot, data)
	if not plot or not plot.DefensesFolder then return end
	plot.DefensesFolder:ClearAllChildren()
	BuiltWallNodes[plot.Index] = {}
	BuiltTurrets[plot.Index] = {}

	if not data or type(data.Defenses) ~= "table" then return end

	local wallLvl = EconomyEngine.GetLevel(data.Defenses, "def_walls")
	local turretLvl = EconomyEngine.GetLevel(data.Defenses, "def_turrets")

	for i = 1, math.min(wallLvl, #WALL_SLOTS) do
		local slot = WALL_SLOTS[i]
		local center = plot.Origin + slot.Dir * 26 + Vector3.new(0, 2.2, 0)
		local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(slot.RotY), 0)

		local leftPillar = makePart({
			Name = "WallPillarL_" .. i,
			Size = Vector3.new(1.4, 4.6, 1.4),
			CFrame = cf * CFrame.new(-6.5, 0, 0),
			Color = Color3.fromRGB(48, 44, 38),
			Material = Enum.Material.Marble,
			Parent = plot.DefensesFolder,
		})
		local rightPillar = makePart({
			Name = "WallPillarR_" .. i,
			Size = Vector3.new(1.4, 4.6, 1.4),
			CFrame = cf * CFrame.new(6.5, 0, 0),
			Color = Color3.fromRGB(48, 44, 38),
			Material = Enum.Material.Marble,
			Parent = plot.DefensesFolder,
		})
		leftPillar.CanCollide = false
		rightPillar.CanCollide = false

		local barrier = makePart({
			Name = "LightBarrier_" .. i,
			Size = Vector3.new(11.6, 3.8, 0.5),
			CFrame = cf,
			Color = Color3.fromRGB(255, 205, 75),
			Material = Enum.Material.Neon,
			Transparency = 0.58,
			CanCollide = false,
			Parent = plot.DefensesFolder,
		})

		table.insert(BuiltWallNodes[plot.Index], {
			Part = barrier,
			Center = center,
			Level = wallLvl,
		})
	end

	for i = 1, math.min(turretLvl, #TURRET_SLOTS) do
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

		local crystal = makePart({
			Name = "TurretCrystal_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 2.4, 1.8),
			Position = basePos + Vector3.new(0, 4.6, 0),
			Color = Color3.fromRGB(255, 215, 75),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = plot.DefensesFolder,
		})

		table.insert(BuiltTurrets[plot.Index], {
			Crystal = crystal,
			Pos = crystal.Position,
			Cooldown = (i - 1) * 0.25,
			Level = turretLvl,
		})
	end
end

local function updateShadowHealthBar(sh)
	if not sh or not sh.HpFill or not sh.HpBg then return end
	local pct = math.clamp(sh.HP / math.max(1, sh.MaxHP), 0, 1)
	sh.HpBg.Visible = (sh.HP < sh.MaxHP)
	sh.HpFill.Size = UDim2.new(pct, 0, 1, 0)
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

function ShadowDefenseService.DamageShadow(sh, dmg, attackerPlayer)
	if not sh or not sh.Part or not sh.Part.Parent then return false end
	sh.HP -= dmg
	if sh.HP <= 0 then
		local plot = PlotsRef[sh.PlotIndex]
		local owner = attackerPlayer or (plot and plot.Owner)
		destroyShadowEntry(sh)

		if owner and PlayerDataRef[owner.UserId] then
			local data = PlayerDataRef[owner.UserId]
			local stats = CalculateStatsFn(owner, data)
			local reward = math.max(15, math.floor(stats.ClickPower * sh.Type.RewardMult))
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

	if wepCfg.Id == "wep_torch" then
		handle.Size = Vector3.new(0.6, 3.2, 0.6)
		handle.Color = Color3.fromRGB(92, 58, 32)
		handle.Material = Enum.Material.Wood
		local tip = Instance.new("Part", tool)
		tip.Name = "FlameTip"
		tip.Shape = Enum.PartType.Ball
		tip.Size = Vector3.new(1.1, 1.3, 1.1)
		tip.Color = wepCfg.Color
		tip.Material = Enum.Material.Neon
		tip.CanCollide = false
		tip.Massless = true
		local weld = Instance.new("WeldConstraint", handle)
		weld.Part0 = handle
		weld.Part1 = tip
		tip.CFrame = handle.CFrame * CFrame.new(0, 1.8, 0)
	elseif wepCfg.Id == "wep_lantern" then
		handle.Size = Vector3.new(1.1, 1.6, 1.1)
		handle.Color = wepCfg.Color
		handle.Material = Enum.Material.Neon
	else
		handle.Size = Vector3.new(0.45, 4.6, 0.9)
		handle.Color = wepCfg.Color
		handle.Material = Enum.Material.Neon
	end

	handle.Parent = tool

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

		local hitAny = false
		local nearestShadow = nil
		local nearestDist = wepCfg.Range

		for i = #ActiveShadows, 1, -1 do
			local sh = ActiveShadows[i]
			if sh and sh.PlotIndex == plot.Index and sh.Part and sh.Part.Parent then
				local d = (sh.Part.Position - hrp.Position).Magnitude
				if d <= wepCfg.Range then
					if wepCfg.Id == "wep_lantern" then
						if d < nearestDist then
							nearestDist = d
							nearestShadow = sh
						end
					else
						hitAny = true
						ShadowDefenseService.DamageShadow(sh, wepCfg.Damage, plr)
					end
				end
			end
		end

		if wepCfg.Id == "wep_lantern" and nearestShadow then
			hitAny = true
			local targetPos = nearestShadow.Part.Position
			ShadowDefenseService.DamageShadow(nearestShadow, wepCfg.Damage, plr)
			if DefenseFxEvent then
				DefenseFxEvent:FireClient(plr, {
					Kind = "Beam",
					From = hrp.Position + Vector3.new(0, 1.2, 0),
					To = targetPos,
					Color = wepCfg.Color,
				})
			end
		elseif DefenseFxEvent then
			DefenseFxEvent:FireClient(plr, {
				Kind = "Pulse",
				Pos = hrp.Position,
				Radius = wepCfg.Range,
				Color = wepCfg.Color,
			})
		end

		if not hitAny and DefenseFxEvent then
			DefenseFxEvent:FireClient(plr, {
				Kind = "Pulse",
				Pos = hrp.Position,
				Radius = math.min(14, wepCfg.Range * 0.65),
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
	if alba >= 1 and roll <= 20 then
		return SHADOW_TYPES[3]
	elseif roll <= 42 then
		return SHADOW_TYPES[2]
	end
	return SHADOW_TYPES[1]
end

function ShadowDefenseService.SpawnShadowForPlot(plot, data)
	if not plot or not plot.Owner or not WorldRef then return end

	local countOnPlot = 0
	for _, sh in ipairs(ActiveShadows) do
		if sh.PlotIndex == plot.Index then
			countOnPlot += 1
		end
	end
	if countOnPlot >= 4 then return end

	local sType = pickShadowType(data)
	local ang = math.random() * math.pi * 2
	local spawnPos = plot.Origin + Vector3.new(math.cos(ang) * 54, sType.Size * 0.5 + 0.6, math.sin(ang) * 54)

	local part = makePart({
		Name = "InvadingShadow",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(sType.Size, sType.Size, sType.Size),
		Position = spawnPos,
		Color = sType.Color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = WorldRef,
	})

	local pLight = Instance.new("PointLight", part)
	pLight.Color = sType.LightColor
	pLight.Range = 9
	pLight.Brightness = 1.3

	local bbg = Instance.new("BillboardGui", part)
	bbg.Size = UDim2.fromOffset(72, 10)
	bbg.StudsOffset = Vector3.new(0, sType.Size * 0.7 + 1.0, 0)
	bbg.AlwaysOnTop = false

	local hpBg = Instance.new("Frame", bbg)
	hpBg.Size = UDim2.fromScale(1, 1)
	hpBg.BackgroundColor3 = Color3.fromRGB(24, 16, 32)
	hpBg.BorderSizePixel = 0
	hpBg.Visible = false
	Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 4)

	local hpFill = Instance.new("Frame", hpBg)
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(235, 70, 120)
	hpFill.BorderSizePixel = 0
	Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 4)

	local entry = {
		PlotIndex = plot.Index,
		Type = sType,
		HP = sType.MaxHP,
		MaxHP = sType.MaxHP,
		Part = part,
		HpBg = hpBg,
		HpFill = hpFill,
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
			task.wait(19)
			for _, plot in ipairs(PlotsRef) do
				if plot.Owner then
					local data = PlayerDataRef[plot.Owner.UserId]
					if data then
						ShadowDefenseService.SpawnShadowForPlot(plot, data)
					end
				end
			end
		end
	end)
end

function ShadowDefenseService.Tick(dt, clickHeatTable)
	for i = #ActiveShadows, 1, -1 do
		local sh = ActiveShadows[i]
		local plot = sh and PlotsRef[sh.PlotIndex]
		if not sh or not sh.Part or not sh.Part.Parent or not plot or not plot.Owner then
			if sh then destroyShadowEntry(sh) end
		else
			local targetPos = Vector3.new(plot.Origin.X, sh.Part.Position.Y, plot.Origin.Z)
			local toCenter = targetPos - sh.Part.Position
			local dist = toCenter.Magnitude

			local speedMult = 1.0
			local wallBurnDmg = 0
			for _, wall in ipairs(BuiltWallNodes[plot.Index] or {}) do
				if (sh.Part.Position - wall.Center).Magnitude <= 6.8 then
					speedMult = 0.35
					wallBurnDmg = math.max(wallBurnDmg, 1.5 * wall.Level)
				end
			end

			if wallBurnDmg > 0 then
				if ShadowDefenseService.DamageShadow(sh, wallBurnDmg * dt, plot.Owner) then
					continue
				end
			end

			if dist <= 7.2 then
				local owner = plot.Owner
				local data = owner and PlayerDataRef[owner.UserId]
				destroyShadowEntry(sh)

				if owner and data then
					local currentPts = math.floor(data.Points or 0)
					local drain = 0
					if currentPts > 0 then
						drain = math.min(currentPts, math.max(sh.Type.MinDrain, math.floor(currentPts * sh.Type.DrainPct)))
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
				sh.Part.Position += toCenter.Unit * (sh.Type.Speed * speedMult * dt)
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
					local bestDist = 42
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
						t.Cooldown = 1.15
						local hitPos = targetSh.Part.Position
						local dmg = 2 * t.Level
						ShadowDefenseService.DamageShadow(targetSh, dmg, owner)
						if DefenseFxEvent then
							DefenseFxEvent:FireClient(owner, {
								Kind = "Beam",
								From = t.Pos,
								To = hitPos,
								Color = Color3.fromRGB(255, 220, 75),
							})
						end
					else
						t.Cooldown = 0.3
					end
				end
			end
		end
	end
end

function ShadowDefenseService.ClearPlot(plotIndex)
	for i = #ActiveShadows, 1, -1 do
		if ActiveShadows[i].PlotIndex == plotIndex then
			destroyShadowEntry(ActiveShadows[i])
		end
	end
	BuiltWallNodes[plotIndex] = nil
	BuiltTurrets[plotIndex] = nil
end

return ShadowDefenseService
