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
	local altars = st.Altars or {}
	local altarsFolder = plotModel:FindFirstChild("Altars")

	if altarsFolder then
		for _, alt in ipairs(GameConfig.Altars) do
			local pad = altarsFolder:FindFirstChild(alt.Id)
			if pad and pad:IsA("BasePart") then
				local maxLvl = alt.MaxLevel or 1
				local lvl = altars[alt.Id] or 0
				local maxed = lvl >= maxLvl
				local cost = GameConfig.GetAltarCost(alt, lvl, albaCount)
				local canAfford = (not maxed) and (points >= cost)
				local altName = Localization.Pick(lang, alt.Name, alt.Name_it)
				local benefit = Localization.Pick(lang, alt.BenefitTag, alt.BenefitTag_it)

				if maxed then
					pad.Color = Color3.fromRGB(50, 175, 110)
					pad.Material = Enum.Material.SmoothPlastic
				elseif canAfford then
					pad.Color = alt.Color
					pad.Material = Enum.Material.Neon
				else
					pad.Color = alt.Color:Lerp(Color3.fromRGB(22, 24, 34), 0.62)
					pad.Material = Enum.Material.SmoothPlastic
				end

				local bbg = pad:FindFirstChildOfClass("BillboardGui")
				local container = bbg and (bbg:FindFirstChildOfClass("Frame") or bbg)
				if container then
					local t1 = container:FindFirstChild("TitleLabel")
					local t2 = container:FindFirstChild("CostLabel")
					if t1 then
						if alt.IsColorButton then
							t1.Text = maxed and ("✅ " .. altName) or ("🎨 " .. altName)
						else
							t1.Text = string.format("%s [%d/%d]", altName, lvl, maxLvl)
						end
					end
					if t2 then
						if maxed then
							t2.Text = alt.IsColorButton and Localization.T(lang, "ACTIVE_GROUND_PAD") or Localization.T(lang, "MAX_GROUND_PAD")
							t2.TextColor3 = Color3.fromRGB(95, 245, 155)
						elseif alt.IsColorButton then
							t2.Text = (canAfford and "✅ " or "") .. NumberFormat.Format(cost) .. " " .. lightUnit
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(225, 230, 242)
						else
							t2.Text = (canAfford and "✅ " or "") .. NumberFormat.Format(cost) .. " " .. lightUnit
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(225, 230, 242)
						end
					end
				end
			end
		end
	end

	local vPad = plotModel:FindFirstChild("VictoryPad")
	if vPad and vPad:IsA("BasePart") then
		local showVictory = (st.AllUpgradesCompleted == true)
		local vCost = GameConfig.GetVictoryCost(albaCount)
		vPad.Transparency = showVictory and 0.16 or 1

		local bbg = vPad:FindFirstChildOfClass("BillboardGui")
		if bbg then
			bbg.Enabled = showVictory
		end
		if showVictory then
			if points >= vCost then
				vPad.Color = Color3.fromRGB(70, 245, 145)
			else
				vPad.Color = Color3.fromRGB(255, 215, 75)
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
				if item.Part then item.Part:Destroy() end
			end
			playerOrbs[userId] = nil
		end
	end

	Players.PlayerRemoving:Connect(function(plr)
		clearPlayerOrbs(plr.UserId)
	end)

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
						for _, rawId in ipairs(decoded) do
							local cfg, isRad = EconomyEngine.ParseWispId(rawId)
							if cfg then
								local orb = Instance.new("Part")
								orb.Anchored = true
								orb.CanCollide = false
								orb.Shape = Enum.PartType.Ball
								orb.Material = Enum.Material.Neon
								orb.Size = isRad and Vector3.new(1.15, 1.15, 1.15) or Vector3.new(0.85, 0.85, 0.85)
								orb.Color = cfg.Color
								orb.Parent = wispFolder

								local light = Instance.new("PointLight", orb)
								light.Color = cfg.Color
								light.Range = isRad and 5 or 3.5
								light.Brightness = isRad and 0.8 or 0.5

								table.insert(list, { Part = orb, IsRadiant = isRad })
							end
						end
					end
					playerOrbs[plr.UserId] = list
				end

				local count = #list
				for idx, item in ipairs(list) do
					if item.Part and item.Part.Parent then
						local angle = t * 2.1 + ((idx - 1) * (math.pi * 2 / math.max(1, count)))
						local radius = 4.2 + (idx % 2) * 0.6
						local bob = math.sin(t * 3.4 + idx) * 0.65
						local offset = Vector3.new(math.cos(angle) * radius, 1.2 + bob, math.sin(angle) * radius)
						item.Part.Position = hrp.Position + offset
					end
				end
			end
		end
	end)
end

return ClientWorldVisuals