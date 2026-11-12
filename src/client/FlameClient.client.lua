local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSync = Remotes:WaitForChild("StateSync")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local SummonWisp = Remotes:WaitForChild("SummonWisp")
local PrestigeEvent = Remotes:WaitForChild("Prestige")
local RedeemCode = Remotes:WaitForChild("RedeemCode")

local world = workspace:WaitForChild("SantuarioDellaFiamma")
local flameCore = world:WaitForChild("PrimordialFlame"):WaitForChild("FlameCore")
local mainLight = flameCore:WaitForChild("MainFlameLight")
local altarsFolder = world:WaitForChild("LightAltars")
local zonesFolder = world:WaitForChild("WorldZones")

-- Setup Atmosfera Oscura Iniziale
for _, fx in ipairs(Lighting:GetChildren()) do
	if fx:IsA("Atmosphere") or fx:IsA("BloomEffect") then fx:Destroy() end
end
local atmo = Instance.new("Atmosphere", Lighting)
local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.7
bloom.Size = 24
bloom.Threshold = 1.0

local lightPct = 4
local flamePulse = 0

local function applyWorldIllumination(pct, upgrades)
	local t = math.clamp(pct / 100, 0, 1)

	Lighting.Brightness = 0.15 + t * 2.35
	Lighting.ClockTime = (t * 10.5) % 24
	Lighting.Ambient = Color3.fromRGB(8, 10, 18):Lerp(Color3.fromRGB(125, 115, 105), t)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 12, 22):Lerp(Color3.fromRGB(165, 150, 130), t)

	atmo.Density = 0.78 - t * 0.58
	atmo.Color = Color3.fromRGB(10, 12, 20):Lerp(Color3.fromRGB(255, 210, 150), t)
	atmo.Decay = Color3.fromRGB(5, 6, 12):Lerp(Color3.fromRGB(180, 130, 80), t)
	atmo.Haze = 2.5 - t * 1.8

	mainLight.Range = math.min(60, 22 + t * 38)
	mainLight.Brightness = 2.2 + t * 2.5

	if upgrades["u_braziers"] and upgrades["u_braziers"] > 0 then
		for _, obj in ipairs(zonesFolder.Braziers:GetChildren()) do
			if string.sub(obj.Name, 1, 6) == "Torch_" then
				obj.Color = Color3.fromRGB(255, 165, 50)
				obj.Material = Enum.Material.Neon
				local l = obj:FindFirstChildOfClass("PointLight")
				if l then l.Enabled = true; l.Brightness = 2.2 end
			end
		end
	end

	if upgrades["u_crystals"] and upgrades["u_crystals"] > 0 then
		for _, c in ipairs(zonesFolder.Crystals:GetChildren()) do
			c.Color = Color3.fromRGB(55, 245, 205)
			c.Material = Enum.Material.Neon
			local l = c:FindFirstChildOfClass("PointLight")
			if l then l.Enabled = true; l.Brightness = 2.5 end
		end
	end

	if upgrades["u_waterfall"] and upgrades["u_waterfall"] > 0 then
		local ws = zonesFolder.Waterfall.WaterStream
		local wp = zonesFolder.Waterfall.WaterPool
		ws.Color = Color3.fromRGB(95, 220, 255)
		ws.Material = Enum.Material.Neon
		wp.Color = Color3.fromRGB(95, 220, 255)
		wp.Material = Enum.Material.Neon
		local l = ws:FindFirstChildOfClass("PointLight")
		if l then l.Enabled = true; l.Brightness = 3.0 end
	end

	if upgrades["u_temple"] and upgrades["u_temple"] > 0 then
		local disc = zonesFolder.Temple.SunDisc
		disc.Color = Color3.fromRGB(255, 225, 95)
		disc.Material = Enum.Material.Neon
		local l = disc:FindFirstChildOfClass("PointLight")
		if l then l.Enabled = true; l.Brightness = 4.0 end
	end
end

local sfx = Instance.new("Sound", playerGui)
sfx.SoundId = "rbxassetid://6895079853"
sfx.Volume = 0.4

---------------------------------------------------------------------
-- INTERFACCIA SEMPLICE E PULITA (HUD + 3 SCHEDE)
---------------------------------------------------------------------
local hud = Instance.new("ScreenGui", playerGui)
hud.Name = "LastFlameHUD"
hud.ResetOnSpawn = false

local topBar = Instance.new("Frame", hud)
topBar.Size = UDim2.new(0.68, 0, 0, 68)
topBar.Position = UDim2.new(0.16, 0, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(16, 15, 22)
topBar.BackgroundTransparency = 0.15
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", topBar)
stroke.Color = Color3.fromRGB(255, 175, 60)
stroke.Thickness = 2

local sparkLbl = Instance.new("TextLabel", topBar)
sparkLbl.Size = UDim2.new(0.32, 0, 0.48, 0)
sparkLbl.Position = UDim2.new(0.02, 0, 0.05, 0)
sparkLbl.BackgroundTransparency = 1
sparkLbl.TextColor3 = Color3.fromRGB(255, 195, 75)
sparkLbl.Font = Enum.Font.GothamBlack
sparkLbl.TextScaled = true

local sunLbl = Instance.new("TextLabel", topBar)
sunLbl.Size = UDim2.new(0.32, 0, 0.48, 0)
sunLbl.Position = UDim2.new(0.35, 0, 0.05, 0)
sunLbl.BackgroundTransparency = 1
sunLbl.TextColor3 = Color3.fromRGB(100, 235, 255)
sunLbl.Font = Enum.Font.GothamBlack
sunLbl.TextScaled = true

local starLbl = Instance.new("TextLabel", topBar)
starLbl.Size = UDim2.new(0.30, 0, 0.48, 0)
starLbl.Position = UDim2.new(0.68, 0, 0.05, 0)
starLbl.BackgroundTransparency = 1
starLbl.TextColor3 = Color3.fromRGB(255, 240, 150)
starLbl.Font = Enum.Font.GothamBlack
starLbl.TextScaled = true

local barBg = Instance.new("Frame", topBar)
barBg.Size = UDim2.new(0.96, 0, 0.32, 0)
barBg.Position = UDim2.new(0.02, 0, 0.58, 0)
barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 6)

local barFill = Instance.new("Frame", barBg)
barFill.Size = UDim2.fromScale(0.04, 1)
barFill.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 6)

local barText = Instance.new("TextLabel", barBg)
barText.Size = UDim2.fromScale(1, 1)
barText.BackgroundTransparency = 1
barText.Text = "☀️ Luce nel Mondo: 4%"
barText.TextColor3 = Color3.fromRGB(255, 255, 255)
barText.TextStrokeTransparency = 0.3
barText.Font = Enum.Font.GothamBold
barText.TextScaled = true

local function showPopup(txt)
	local p = Instance.new("TextLabel", hud)
	p.Size = UDim2.fromOffset(380, 34)
	p.Position = UDim2.new(0.5, -190, 0.64, 0)
	p.BackgroundTransparency = 1
	p.Text = txt
	p.TextColor3 = Color3.fromRGB(255, 220, 100)
	p.TextStrokeTransparency = 0.2
	p.Font = Enum.Font.GothamBlack
	p.TextScaled = true
	local tw = TweenService:Create(p, TweenInfo.new(1.1), { Position = UDim2.new(0.5, -190, 0.50, 0), TextTransparency = 1 })
	tw:Play()
	tw.Completed:Connect(function() p:Destroy() end)
end

local dock = Instance.new("Frame", hud)
dock.Size = UDim2.fromOffset(480, 46)
dock.Position = UDim2.new(0.5, -240, 1, -58)
dock.BackgroundColor3 = Color3.fromRGB(16, 15, 22)
dock.BackgroundTransparency = 0.15
Instance.new("UICorner", dock).CornerRadius = UDim.new(0, 12)

local function makeTabBtn(idx, txt, col)
	local b = Instance.new("TextButton", dock)
	b.Size = UDim2.new(0.31, 0, 0.78, 0)
	b.Position = UDim2.new(0.02 + (idx - 1) * 0.325, 0, 0.11, 0)
	b.BackgroundColor3 = col
	b.Text = txt
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local btnUpgrades = makeTabBtn(1, "🔥 POTENZIA LUCE", Color3.fromRGB(215, 115, 25))
local btnWisps = makeTabBtn(2, "✨ SPIRITI (0/4)", Color3.fromRGB(45, 155, 195))
local btnAlba = makeTabBtn(3, "🌅 GRANDE ALBA", Color3.fromRGB(165, 65, 185))

local modal = Instance.new("Frame", hud)
modal.Size = UDim2.fromOffset(500, 380)
modal.Position = UDim2.new(0.5, -250, 0.5, -190)
modal.BackgroundColor3 = Color3.fromRGB(18, 17, 25)
modal.Visible = false
Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 14)
Instance.new("UIStroke", modal).Color = Color3.fromRGB(255, 175, 60)

local modalHeader = Instance.new("TextLabel", modal)
modalHeader.Size = UDim2.new(1, -50, 0, 38)
modalHeader.Position = UDim2.fromOffset(14, 6)
modalHeader.BackgroundTransparency = 1
modalHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
modalHeader.TextXAlignment = Enum.TextXAlignment.Left
modalHeader.Font = Enum.Font.GothamBlack
modalHeader.TextScaled = true

local closeBtn = Instance.new("TextButton", modal)
closeBtn.Size = UDim2.fromOffset(32, 32)
closeBtn.Position = UDim2.new(1, -40, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 50, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBlack
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function() modal.Visible = false end)

local pages = {}
local activeTab = nil
local function toggleTab(name, title)
	if modal.Visible and activeTab == name then
		modal.Visible = false
		return
	end
	activeTab = name
	modalHeader.Text = title
	for k, f in pairs(pages) do f.Visible = (k == name) end
	modal.Visible = true
end

local function makePage(name)
	local f = Instance.new("Frame", modal)
	f.Size = UDim2.new(1, -24, 1, -52)
	f.Position = UDim2.fromOffset(12, 46)
	f.BackgroundTransparency = 1
	f.Visible = false
	pages[name] = f
	return f
end

-- Scheda 1: Potenziamenti della Luce
local pUpg = makePage("Upg")
local upgScroll = Instance.new("ScrollingFrame", pUpg)
upgScroll.Size = UDim2.fromScale(1, 1)
upgScroll.CanvasSize = UDim2.fromOffset(0, #GameConfig.Upgrades * 52)
upgScroll.BackgroundTransparency = 1
upgScroll.ScrollBarThickness = 6

local upgButtons = {}
for i, u in ipairs(GameConfig.Upgrades) do
	local b = Instance.new("TextButton", upgScroll)
	b.Size = UDim2.new(1, -10, 0, 46)
	b.Position = UDim2.fromOffset(0, (i - 1) * 50)
	b.BackgroundColor3 = Color3.fromRGB(32, 30, 44)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() BuyUpgrade:FireServer(u.Id) end)
	upgButtons[u.Id] = { Btn = b, Cfg = u }
end
btnUpgrades.MouseButton1Click:Connect(function() toggleTab("Upg", "🔥 POTENZIAMENTI DELLA FIAMMA") end)

-- Scheda 2: Spiriti di Luce
local pWisps = makePage("Wisps")
local wispRows = {}
for i, w in ipairs(GameConfig.Wisps) do
	local lbl = Instance.new("TextLabel", pWisps)
	lbl.Size = UDim2.new(1, 0, 0, 40)
	lbl.Position = UDim2.fromOffset(0, (i - 1) * 44)
	lbl.BackgroundColor3 = Color3.fromRGB(26, 28, 40)
	lbl.TextColor3 = w.Color
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
	wispRows[w.Id] = { Lbl = lbl, Cfg = w }
end

local summonBtn = Instance.new("TextButton", pWisps)
summonBtn.Size = UDim2.new(1, 0, 0, 46)
summonBtn.Position = UDim2.new(0, 0, 1, -48)
summonBtn.BackgroundColor3 = Color3.fromRGB(45, 165, 210)
summonBtn.Text = "✨ EVOCA SPIRITO DI LUCE (20 Essenza Solare)"
summonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
summonBtn.Font = Enum.Font.GothamBlack
summonBtn.TextScaled = true
Instance.new("UICorner", summonBtn).CornerRadius = UDim.new(0, 10)
summonBtn.MouseButton1Click:Connect(function() SummonWisp:FireServer() end)
btnWisps.MouseButton1Click:Connect(function() toggleTab("Wisps", "✨ SPIRITI DI LUCE (ILLUMINANO IL BUIO)") end)

-- Scheda 3: Grande Alba & Codici
local pAlba = makePage("Alba")
local prestigeBtn = Instance.new("TextButton", pAlba)
prestigeBtn.Size = UDim2.new(1, 0, 0, 64)
prestigeBtn.Position = UDim2.fromOffset(0, 10)
prestigeBtn.BackgroundColor3 = Color3.fromRGB(165, 65, 185)
prestigeBtn.Text = "🌅 GRANDE ALBA (Richiede 1.00B Scintille)
Ottieni +1 Stella Eterna (x8 Scintille per sempre)"
prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prestigeBtn.Font = Enum.Font.GothamBlack
prestigeBtn.TextScaled = true
Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 10)
prestigeBtn.MouseButton1Click:Connect(function() PrestigeEvent:FireServer() end)

local codeBox = Instance.new("TextBox", pAlba)
codeBox.Size = UDim2.new(0.66, 0, 0, 42)
codeBox.Position = UDim2.fromOffset(0, 100)
codeBox.PlaceholderText = "Codice (es. LUCE100, ALBA2026)"
codeBox.Text = ""
codeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
codeBox.Font = Enum.Font.GothamBold
codeBox.TextScaled = true
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

local codeBtn = Instance.new("TextButton", pAlba)
codeBtn.Size = UDim2.new(0.32, 0, 0, 42)
codeBtn.Position = UDim2.new(0.68, 0, 0, 100)
codeBtn.BackgroundColor3 = Color3.fromRGB(45, 185, 115)
codeBtn.Text = "RISCATTA"
codeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
codeBtn.Font = Enum.Font.GothamBlack
codeBtn.TextScaled = true
Instance.new("UICorner", codeBtn).CornerRadius = UDim.new(0, 8)
codeBtn.MouseButton1Click:Connect(function()
	local _, msg = RedeemCode:InvokeServer(codeBox.Text)
	showPopup(msg or "")
end)
btnAlba.MouseButton1Click:Connect(function() toggleTab("Alba", "🌅 GRANDE ALBA & CODICI") end)

StateSync.OnClientEvent:Connect(function(st)
	lightPct = st.LightPercent or 4
	if st.FlamePulse then flamePulse = 1.0 end

	sparkLbl.Text = string.format("🔥 %s (+%s/s)", GameConfig.Format(st.Sparks), GameConfig.Format(st.SparksPerSec))
	sunLbl.Text = string.format("☀️ %s (+%s/s)", GameConfig.Format(st.SunEssence), GameConfig.Format(st.SunPerSec))
	starLbl.Text = string.format("⭐ %d Stelle Eterne", st.EternalStars or 0)

	barFill.Size = UDim2.fromScale(math.clamp(lightPct / 100, 0.02, 1), 1)
	barText.Text = string.format("☀️ Luce nel Mondo: %d%%", lightPct)
	btnWisps.Text = string.format("✨ SPIRITI (%d/4)", st.EquippedCount or 0)

	applyWorldIllumination(lightPct, st.Upgrades or {})

	for _, alt in ipairs(GameConfig.Altars) do
		local pad = altarsFolder:FindFirstChild(alt.Id)
		if pad and pad:FindFirstChild("InfoGui") then
			local lvl = (st.Altars and st.Altars[alt.Id]) or 0
			local cost = math.floor(alt.BaseCost * (alt.CostMult ^ lvl))
			pad.InfoGui.Frame.SubLabel.Text = "Lv. " .. lvl .. " | " .. GameConfig.Format(cost)
		end
	end

	for id, entry in pairs(upgButtons) do
		local u = entry.Cfg
		local lvl = (st.Upgrades and st.Upgrades[id]) or 0
		local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
		local unit = u.Currency == "Sparks" and "Scintille" or "Essenza"
		if lvl >= u.MaxLevel then
			entry.Btn.BackgroundColor3 = Color3.fromRGB(30, 120, 75)
			entry.Btn.Text = u.Name .. " [MAX] — " .. u.Desc
		else
			local ok = (u.Currency == "Sparks" and st.Sparks >= cost) or (u.Currency == "Sun" and st.SunEssence >= cost)
			entry.Btn.BackgroundColor3 = ok and Color3.fromRGB(205, 110, 25) or Color3.fromRGB(34, 32, 46)
			entry.Btn.Text = string.format("%s (%d/%d) — %s
Costo: %s %s", u.Name, lvl, u.MaxLevel, u.Desc, GameConfig.Format(cost), unit)
		end
	end

	for id, entry in pairs(wispRows) do
		local w = entry.Cfg
		local count = (st.WispCounts and st.WispCounts[id]) or 0
		entry.Lbl.Text = string.format("%s (%d%%) | x%.1f Scintille | Posseduti: %d", w.Name, w.Weight, w.SparkMult, count)
	end

	if st.SoundCue then sfx:Play() end
	if st.PopupText then showPopup(st.PopupText) end
end)

---------------------------------------------------------------------
-- ANIMAZIONE FIAMMA & LUCCIOLE ORBITANTI CHE ILLUMINANO IL BUIO
---------------------------------------------------------------------
local visualFolder = Instance.new("Folder", workspace)
visualFolder.Name = "LightWispsVisuals"

local wispColors = {}
for _, w in ipairs(GameConfig.Wisps) do wispColors[w.Id] = w.Color end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	flamePulse = math.max(0, flamePulse - dt * 3.5)
	local scale = (1 + (lightPct / 100) * 1.3) * (1 + math.sin(t * 5) * 0.06 + flamePulse * 0.25)
	flameCore.Size = Vector3.new(3.5, 4.5, 3.5) * scale

	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local pFolder = visualFolder:FindFirstChild(plr.Name)
		if hrp then
			if not pFolder then
				pFolder = Instance.new("Folder", visualFolder)
				pFolder.Name = plr.Name
			end

			local personalLight = hrp:FindFirstChild("PersonalLantern")
			if not personalLight then
				personalLight = Instance.new("PointLight", hrp)
				personalLight.Name = "PersonalLantern"
				personalLight.Color = Color3.fromRGB(255, 195, 110)
				personalLight.Range = 20
				personalLight.Brightness = 1.4
			end

			local ok, ids = pcall(function() return HttpService:JSONDecode(plr:GetAttribute("EquippedWisps") or "[]") end)
			ids = (ok and type(ids) == "table") and ids or {}

			for i = 1, 4 do
				local wPart = pFolder:FindFirstChild("Wisp_" .. i)
				if ids[i] then
					if not wPart then
						wPart = Instance.new("Part", pFolder)
						wPart.Name = "Wisp_" .. i
						wPart.Shape = Enum.PartType.Ball
						wPart.Size = Vector3.new(0.9, 0.9, 0.9)
						wPart.Anchored = true
						wPart.CanCollide = false
						wPart.Material = Enum.Material.Neon
						local wl = Instance.new("PointLight", wPart)
						wl.Range = 16
						wl.Brightness = 1.8
					end
					local col = wispColors[ids[i]] or Color3.fromRGB(255, 200, 80)
					wPart.Color = col
					wPart:FindFirstChildOfClass("PointLight").Color = col
					local a = t * 2.0 + (i * (math.pi * 2 / #ids))
					wPart.Position = hrp.Position + Vector3.new(math.cos(a) * 3.8, 1.5 + math.sin(t * 3.5 + i) * 0.5, math.sin(a) * 3.8)
				elseif wPart then
					wPart:Destroy()
				end
			end
		elseif pFolder then
			pFolder:Destroy()
		end
	end
end)
