local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))

local ClientWorldVisuals = {}

local ritualOrbCache = {}

function ClientWorldVisuals.GetMyPlotModel()
	local world = Workspace:FindFirstChild("LastFlameWorld")
	local plotsFolder = world and world:FindFirstChild("Plots")
	if not plotsFolder then return nil end

	local plotIndex = Players.LocalPlayer:GetAttribute("PlotIndex") or 1
	return plotsFolder:FindFirstChild("Plot_" .. tostring(plotIndex))
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

function ClientWorldVisuals.Update(st)
	if not st then return end
	local plotModel = ClientWorldVisuals.GetMyPlotModel()
	if not plotModel then return end

	local points = st.Points or 0
	local altars = st.Altars or {}
	local altarsFolder = plotModel:FindFirstChild("Altars")

	if altarsFolder then
		for _, alt in ipairs(GameConfig.Altars) do
			local pad = altarsFolder:FindFirstChild(alt.Id)
			if pad and pad:IsA("BasePart") then
				local maxLvl = alt.MaxLevel or 1
				local lvl = altars[alt.Id] or 0
				local maxed = lvl >= maxLvl
				local cost = math.floor(alt.BaseCost * (alt.CostMult ^ lvl))
				local canAfford = (not maxed) and (points >= cost)

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
				if bbg then
					local t2 = bbg:FindFirstChild("CostLabel")
					if t2 then
						if maxed then
							t2.Text = alt.IsColorButton and ("✅ ATTIVO (" .. (alt.BenefitTag or "") .. ")") or "✅ MASSIMO"
							t2.TextColor3 = Color3.fromRGB(95, 245, 155)
						elseif alt.IsColorButton then
							t2.Text = NumberFormat.Format(cost) .. " Luce • " .. (alt.BenefitTag or "")
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(225, 230, 242)
						else
							t2.Text = (canAfford and "✅ " or "") .. NumberFormat.Format(cost) .. " Luce"
							t2.TextColor3 = canAfford and Color3.fromRGB(95, 255, 155) or Color3.fromRGB(225, 230, 242)
						end
					end
				end
			end
		end
	end

	-- Pulsante della Vittoria: VISIBILE SOLO DOPO AVER COMPLETATO TUTTI I POTENZIAMENTI
	local vModel = plotModel:FindFirstChild("VictoryButtonPedestal")
	if vModel then
		local showVictory = (st.AllUpgradesCompleted == true)
		local vCost = (GameConfig.VictoryButton and GameConfig.VictoryButton.Cost) or 5e8

		for _, child in ipairs(vModel:GetChildren()) do
			if child:IsA("BasePart") then
				child.Transparency = showVictory and 0 or 1
			end
		end

		local vPad = vModel:FindFirstChild("VictoryPad")
		if vPad then
			local bbg = vPad:FindFirstChild("VictoryBillboard")
			if bbg then
				bbg.Enabled = showVictory
			end
			if showVictory then
				if st.HasWon then
					vPad.Color = Color3.fromRGB(80, 235, 255)
				elseif points >= vCost then
					vPad.Color = Color3.fromRGB(70, 245, 145)
				else
					vPad.Color = Color3.fromRGB(255, 215, 75)
				end
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