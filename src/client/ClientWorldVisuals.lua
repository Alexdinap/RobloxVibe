local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local ClientWorldVisuals = {}

local ritualOrbCache = {}

function ClientWorldVisuals.GetMyPlotModel()
	local world = Workspace:FindFirstChild("LastFlameWorld")
	if not world then return nil end

	local plotIndex = Players.LocalPlayer:GetAttribute("PlotIndex")
	if not plotIndex then
		for i = 1, (GameConfig.PlotCount or 10) do
			local candidate = world:FindFirstChild("Plot_" .. tostring(i))
			if candidate and candidate:GetAttribute("OwnerUserId") == Players.LocalPlayer.UserId then
				plotIndex = i
				break
			end
		end
	end
	if not plotIndex then return nil end

	local plotsFolder = world:FindFirstChild("Plots")
	if plotsFolder then
		return plotsFolder:FindFirstChild("Plot_" .. tostring(plotIndex))
	end
	return world:FindFirstChild("Plot_" .. tostring(plotIndex))
end

function ClientWorldVisuals.GetMyFlameCore()
	local plotModel = ClientWorldVisuals.GetMyPlotModel()
	local brazier = plotModel and plotModel:FindFirstChild("Brazier")
	return brazier and brazier:FindFirstChild("FlameCore")
end

function ClientWorldVisuals.PlayShockwave(color)
	local core = ClientWorldVisuals.GetMyFlameCore()
	if not core then return end

	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = color or core.Color
	ring.Transparency = 0.25
	ring.Size = Vector3.new(0.4, 6, 6)
	ring.CFrame = CFrame.new(core.Position.X, 0.8, core.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace

	local tween = TweenService:Create(ring, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 54, 54),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		ring:Destroy()
	end)
end

function ClientWorldVisuals.PlayDefenseFx(fx)
	if not fx then return end
	if fx.Kind == "Beam" and fx.From and fx.To then
		local dist = (fx.To - fx.From).Magnitude
		if dist < 0.5 then return end
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = fx.Color or Color3.fromRGB(255, 220, 80)
		beam.Size = Vector3.new(0.32, 0.32, dist)
		beam.CFrame = CFrame.lookAt((fx.From + fx.To) * 0.5, fx.To)
		beam.Parent = Workspace

		local tw = TweenService:Create(beam, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = Vector3.new(0.05, 0.05, dist),
		})
		tw:Play()
		tw.Completed:Connect(function()
			beam:Destroy()
		end)
	elseif fx.Kind == "Pulse" and fx.Pos then
		local r = (fx.Radius or 18) * 2
		local ring = Instance.new("Part")
		ring.Anchored = true
		ring.CanCollide = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = fx.Color or Color3.fromRGB(255, 195, 70)
		ring.Transparency = 0.3
		ring.Size = Vector3.new(0.3, 4, 4)
		ring.CFrame = CFrame.new(fx.Pos.X, 1.2, fx.Pos.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = Workspace

		local tw = TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.15, r, r),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function()
			ring:Destroy()
		end)
	end
end

function ClientWorldVisuals.Update(st)
	if not st then return end
	local plotModel = ClientWorldVisuals.GetMyPlotModel()
	if not plotModel then return end

	local lang = st.Language or "en"
	local lightUnit = Localization.T(lang, "LIGHT_UNIT")
	local points = st.Points or 0
	local albaCount = st.AlbaCount or 0
	local ownedWeapons = st.OwnedWeapons or {}

	-- 1. Postazioni Armi a terra
	local weaponsFolder = plotModel:FindFirstChild("Weapons")
	if weaponsFolder then
		for _, wep in ipairs(GameConfig.Weapons) do
			local pad = weaponsFolder:FindFirstChild(wep.Id)
			if pad and pad:IsA("BasePart") then
				local rim = pad:FindFirstChild(wep.Id .. "_Rim")
				local owned = ownedWeapons[wep.Id] == true
				local reqAlba = wep.ReqAlba or 0
				local locked = (not owned) and (albaCount < reqAlba)
				local cost = GameConfig.GetWeaponCost(wep, albaCount)
				local canAfford = (not owned) and (not locked) and (points >= cost)
				local wName = Localization.Pick(lang, wep.Name, wep.Name_it)
				local wTag = Localization.Pick(lang, wep.Tag, wep.Tag_it)

				local padCol, padMat
				if owned then
					padCol = Color3.fromRGB(50, 185, 115)
					padMat = Enum.Material.SmoothPlastic
				elseif locked then
					padCol = Color3.fromRGB(36, 40, 54)
					padMat = Enum.Material.SmoothPlastic
				elseif canAfford then
					padCol = wep.Color
					padMat = Enum.Material.Neon
				else
					padCol = wep.Color:Lerp(Color3.fromRGB(22, 24, 34), 0.58)
					padMat = Enum.Material.SmoothPlastic
				end
				pad.Color = padCol
				pad.Material = padMat
				if rim and rim:IsA("BasePart") then
					rim.Color = owned and Color3.fromRGB(70, 245, 145) or (locked and Color3.fromRGB(65, 72, 95) or wep.Color)
				end

				local bbg = pad:FindFirstChildOfClass("BillboardGui")
				local container = bbg and (bbg:FindFirstChildOfClass("Frame") or bbg)
				if container then
					local t1 = container:FindFirstChild("TitleLabel")
					local td = container:FindFirstChild("DescLabel")
					local t2 = container:FindFirstChild("CostLabel")
					if t1 then
						t1.Text = (locked and "🔒 " or (wep.Icon .. " ")) .. wName
					end
					if td then
						td.Text = wTag
					end
					if t2 then
						if owned then
							t2.Text = Localization.T(lang, "PAD_WEP_EQUIPPED")
							t2.TextColor3 = Color3.fromRGB(95, 245, 155)
						elseif locked then
							t2.Text = Localization.T(lang, "PAD_WEP_LOCKED_FMT", reqAlba)
							t2.TextColor3 = Color3.fromRGB(190, 200, 222)
						else
							t2.Text = (canAfford and "✅ " or "") .. NumberFormat.Format(cost) .. " " .. lightUnit
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(235, 240, 252)
						end
					end
				end
			end
		end
	end

	-- 2. Postazione Spiriti a terra
	local wispFolder = plotModel:FindFirstChild("WispStation")
	if wispFolder then
		local wispsUnlocked = (st.WispsUnlocked == true)
		local unitCost = GameConfig.GetWispCost(albaCount)
		local padConfigs = {
			{ Name = "WispPad_1", Mult = 1, TitleKey = "PAD_WISP_1_TITLE", BaseColor = Color3.fromRGB(80, 225, 255) },
			{ Name = "WispPad_5", Mult = 5, TitleKey = "PAD_WISP_5_TITLE", BaseColor = Color3.fromRGB(205, 115, 255) },
		}
		for _, pc in ipairs(padConfigs) do
			local pad = wispFolder:FindFirstChild(pc.Name)
			if pad and pad:IsA("BasePart") then
				local rim = pad:FindFirstChild(pc.Name .. "_Rim")
				local totalCost = unitCost * pc.Mult
				local canAfford = wispsUnlocked and (points >= totalCost)

				if not wispsUnlocked then
					pad.Color = Color3.fromRGB(36, 40, 56)
					pad.Material = Enum.Material.SmoothPlastic
				elseif canAfford then
					pad.Color = pc.BaseColor
					pad.Material = Enum.Material.Neon
				else
					pad.Color = pc.BaseColor:Lerp(Color3.fromRGB(22, 24, 34), 0.56)
					pad.Material = Enum.Material.SmoothPlastic
				end
				if rim and rim:IsA("BasePart") then
					rim.Color = wispsUnlocked and pc.BaseColor or Color3.fromRGB(68, 76, 102)
				end

				local bbg = pad:FindFirstChildOfClass("BillboardGui")
				local container = bbg and (bbg:FindFirstChildOfClass("Frame") or bbg)
				if container then
					local t1 = container:FindFirstChild("TitleLabel")
					local td = container:FindFirstChild("DescLabel")
					local t2 = container:FindFirstChild("CostLabel")
					if t1 then
						t1.Text = Localization.T(lang, pc.TitleKey)
					end
					if td then
						td.Text = wispsUnlocked and Localization.T(lang, "PAD_WISP_READY_DESC") or Localization.T(lang, "PAD_WISP_LOCKED_DESC")
					end
					if t2 then
						if not wispsUnlocked then
							t2.Text = "🔒 " .. Localization.T(lang, "BTN_LOCKED")
							t2.TextColor3 = Color3.fromRGB(190, 200, 222)
						else
							t2.Text = (canAfford and "✅ " or "") .. NumberFormat.Format(totalCost) .. " " .. lightUnit
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(235, 240, 252)
						end
					end
				end
			end
		end
	end

	-- 3. Pedana Rebirth
	local vPad = plotModel:FindFirstChild("VictoryPad")
	if vPad and vPad:IsA("BasePart") then
		local showVictory = (st.AllUpgradesCompleted == true)
		local vCost = GameConfig.GetVictoryCost(albaCount)
		vPad.Transparency = showVictory and 0.16 or 1
		local vRim = vPad:FindFirstChild("VictoryPad_Rim")
		if vRim and vRim:IsA("BasePart") then
			vRim.Transparency = showVictory and 0.05 or 1
		end

		local bbg = vPad:FindFirstChildOfClass("BillboardGui")
		if bbg then
			bbg.Enabled = showVictory
		end
		if showVictory then
			local vCol = (points >= vCost) and Color3.fromRGB(70, 245, 145) or Color3.fromRGB(255, 215, 75)
			vPad.Color = vCol
			if vRim and vRim:IsA("BasePart") then
				vRim.Color = vCol
			end
		end
	end
end

function ClientWorldVisuals.UpdateRegno1(r1State)
	if not r1State then return end
	local plotModel = ClientWorldVisuals.GetMyPlotModel()
	local ritualFolder = plotModel and plotModel:FindFirstChild("Regno1Ritual")
	if not ritualFolder then return end

	for _, b in ipairs(GameConfig.Regno1.Braziers) do
		local ped = ritualFolder:FindFirstChild("Brazier_" .. b.Index)
		if ped then
			local entry = ritualOrbCache[b.Index]
			if not entry or not entry.Orb or not entry.Orb.Parent then
				local orb = Instance.new("Part")
				orb.Name = "ClientRitualFlame_" .. b.Index
				orb.Anchored = true
				orb.CanCollide = false
				orb.Shape = Enum.PartType.Ball
				orb.Material = Enum.Material.Neon
				orb.Size = Vector3.new(2.4, 3.0, 2.4)
				orb.Position = ped.Position + Vector3.new(0, b.PedestalHeight * 0.5 + 2.0, 0)
				orb.Parent = ritualFolder

				local light = Instance.new("PointLight", orb)
				light.Range = 12
				light.Brightness = 1.2

				local bbg = Instance.new("BillboardGui", orb)
				bbg.Size = UDim2.fromOffset(80, 24)
				bbg.StudsOffset = Vector3.new(0, 2.6, 0)
				local lbl = Instance.new("TextLabel", bbg)
				lbl.Size = UDim2.fromScale(1, 1)
				lbl.BackgroundTransparency = 1
				lbl.Text = b.Numeral
				lbl.TextColor3 = Color3.fromRGB(255, 215, 85)
				lbl.TextStrokeTransparency = 0.25
				lbl.Font = Enum.Font.GothamBlack
				lbl.TextSize = 13

				entry = { Orb = orb, Light = light, Billboard = bbg }
				ritualOrbCache[b.Index] = entry
			end

			if not r1State.Unlocked then
				entry.Orb.Transparency = 1
				entry.Light.Enabled = false
				entry.Billboard.Enabled = false
			elseif r1State.Active then
				entry.Billboard.Enabled = true
				if b.Index < r1State.CurrentStep then
					entry.Orb.Transparency = 0
					entry.Orb.Color = Color3.fromRGB(70, 255, 155)
					entry.Orb.Size = Vector3.new(2.8, 3.4, 2.8)
					entry.Light.Color = Color3.fromRGB(70, 255, 155)
					entry.Light.Enabled = true
				elseif b.Index == r1State.CurrentStep then
					entry.Orb.Transparency = 0
					entry.Orb.Color = Color3.fromRGB(255, 230, 75)
					entry.Orb.Size = Vector3.new(3.4, 4.0, 3.4)
					entry.Light.Color = Color3.fromRGB(255, 230, 75)
					entry.Light.Enabled = true
				else
					entry.Orb.Transparency = 0.55
					entry.Orb.Color = Color3.fromRGB(110, 125, 160)
					entry.Orb.Size = Vector3.new(2.0, 2.4, 2.0)
					entry.Light.Enabled = false
				end
			else
				entry.Billboard.Enabled = true
				if b.Index == 1 then
					entry.Orb.Transparency = 0
					entry.Orb.Color = Color3.fromRGB(255, 165, 50)
					entry.Orb.Size = Vector3.new(3.0, 3.6, 3.0)
					entry.Light.Color = Color3.fromRGB(255, 165, 50)
					entry.Light.Enabled = true
				else
					entry.Orb.Transparency = 0.65
					entry.Orb.Color = Color3.fromRGB(95, 110, 145)
					entry.Orb.Size = Vector3.new(1.8, 2.2, 1.8)
					entry.Light.Enabled = false
				end
			end
		end
	end
end

function ClientWorldVisuals.StartWispRenderer()
	local wispFolder = Instance.new("Folder", Workspace)
	wispFolder.Name = "ClientWispVisuals"

	local playerOrbs = {}

	local function clearPlayerOrbs(userId)
		local list = playerOrbs[userId]
		if list then
			for _, item in ipairs(list) do
				if item.Model then
					item.Model:Destroy()
				elseif item.Part then
					item.Part:Destroy()
				end
			end
			playerOrbs[userId] = nil
		end
	end

	Players.PlayerRemoving:Connect(function(plr)
		clearPlayerOrbs(plr.UserId)
	end)

	local function makeWispPart(parent, name, shape, size, color, material, transparency)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.Neon
		p.Transparency = transparency or 0
		p.Parent = parent
		return p
	end

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local rawAttr = plr:GetAttribute("EquippedWisps")

			if not hrp or type(rawAttr) ~= "string" then
				clearPlayerOrbs(plr.UserId)
			else
				local list = playerOrbs[plr.UserId]
				if not list or list.LastJson ~= rawAttr then
					clearPlayerOrbs(plr.UserId)
					list = { LastJson = rawAttr }
					local ok, decoded = pcall(function()
						return HttpService:JSONDecode(rawAttr)
					end)
					if ok and type(decoded) == "table" then
						for idx, rawId in ipairs(decoded) do
							local cfg, isRad = EconomyEngine.ParseWispId(rawId)
							if cfg then
								local s = isRad and 1.28 or 0.96
								local model = Instance.new("Model")
								model.Name = "WispOrb_" .. tostring(idx)

								local core = makeWispPart(
									model,
									"Core",
									Enum.PartType.Ball,
									Vector3.new(0.82, 0.82, 0.82) * s,
									cfg.Color:Lerp(Color3.new(1, 1, 1), 0.35),
									Enum.Material.Neon,
									0.02
								)

								local aura = makeWispPart(
									model,
									"AuraShell",
									Enum.PartType.Ball,
									Vector3.new(1.42, 1.42, 1.42) * s,
									cfg.Color,
									Enum.Material.ForceField,
									0.32
								)

								local ringColor = isRad and Color3.fromRGB(255, 240, 155) or cfg.Color:Lerp(Color3.new(1, 1, 1), 0.2)
								local ring = makeWispPart(
									model,
									"HaloRing",
									Enum.PartType.Cylinder,
									Vector3.new(0.09, 1.85 * s, 1.85 * s),
									ringColor,
									Enum.Material.Neon,
									0.12
								)

								local wingL = makeWispPart(
									model,
									"WingL",
									Enum.PartType.Block,
									Vector3.new(0.10, 0.42, 0.78) * s,
									cfg.Color,
									Enum.Material.Neon,
									0.18
								)
								local wingR = makeWispPart(
									model,
									"WingR",
									Enum.PartType.Block,
									Vector3.new(0.10, 0.42, 0.78) * s,
									cfg.Color,
									Enum.Material.Neon,
									0.18
								)

								-- Scia luminosa
								local attTop = Instance.new("Attachment", core)
								attTop.Position = Vector3.new(0, 0.34 * s, 0)
								local attBot = Instance.new("Attachment", core)
								attBot.Position = Vector3.new(0, -0.34 * s, 0)

								local trail = Instance.new("Trail", core)
								trail.Attachment0 = attTop
								trail.Attachment1 = attBot
								trail.Color = ColorSequence.new(cfg.Color:Lerp(Color3.new(1, 1, 1), 0.45), cfg.Color)
								trail.Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0.25),
									NumberSequenceKeypoint.new(1, 1),
								})
								trail.WidthScale = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 1.0),
									NumberSequenceKeypoint.new(1, 0.1),
								})
								trail.Lifetime = isRad and 0.55 or 0.42
								trail.LightEmission = 1

								-- Particelle scintillanti
								local sparkles = Instance.new("ParticleEmitter", core)
								sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
								sparkles.LightEmission = 1
								sparkles.LightInfluence = 0
								sparkles.Rate = isRad and 18 or 10
								sparkles.Lifetime = NumberRange.new(0.45, 0.85)
								sparkles.Speed = NumberRange.new(0.8, 2.2)
								sparkles.SpreadAngle = Vector2.new(180, 180)
								sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), cfg.Color)
								sparkles.Size = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0.32 * s),
									NumberSequenceKeypoint.new(1, 0),
								})
								sparkles.Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 0.1),
									NumberSequenceKeypoint.new(1, 1),
								})

								local light = Instance.new("PointLight", core)
								light.Color = cfg.Color
								light.Range = isRad and 8.5 or 5.5
								light.Brightness = isRad and 1.3 or 0.8

								model.Parent = wispFolder
								table.insert(list, {
									Model = model,
									Core = core,
									Aura = aura,
									Ring = ring,
									WingL = wingL,
									WingR = wingR,
									Scale = s,
									IsRadiant = isRad,
								})
							end
						end
					end
					playerOrbs[plr.UserId] = list
				end

				local count = #list
				for idx, item in ipairs(list) do
					if item.Model and item.Model.Parent and item.Core then
						local angle = t * 2.1 + ((idx - 1) * (math.pi * 2 / math.max(1, count)))
						local radius = 4.4 + (idx % 2) * 0.65
						local bob = math.sin(t * 3.4 + idx) * 0.65
						local pos = hrp.Position + Vector3.new(math.cos(angle) * radius, 1.35 + bob, math.sin(angle) * radius)

						-- Orientamento lungo la tangente dell'orbita
						local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
						local baseCF = CFrame.lookAt(pos, pos + tangent)
						local s = item.Scale
						local pulse = 1 + math.sin(t * 4.5 + idx) * 0.08
						local flap = math.sin(t * 9.0 + idx) * 0.45

						item.Core.CFrame = baseCF
						item.Aura.Size = Vector3.new(1.42, 1.42, 1.42) * s * pulse
						item.Aura.CFrame = baseCF
						item.Ring.CFrame = baseCF * CFrame.Angles(math.rad(22), t * 2.8 + idx, math.rad(75))
						item.WingL.CFrame = baseCF * CFrame.new(-0.58 * s, 0.08 * s, 0.15 * s) * CFrame.Angles(0, math.rad(28) + flap, math.rad(18))
						item.WingR.CFrame = baseCF * CFrame.new(0.58 * s, 0.08 * s, 0.15 * s) * CFrame.Angles(0, math.rad(-28) - flap, math.rad(-18))
					end
				end
			end
		end
	end)
end

return ClientWorldVisuals