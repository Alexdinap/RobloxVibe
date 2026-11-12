local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSync = Remotes:WaitForChild("StateSync")
local ClickFlameEvent = Remotes:WaitForChild("ClickFlame")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local BuyStarPerk = Remotes:WaitForChild("BuyStarPerk")
local SummonWisp = Remotes:WaitForChild("SummonWisp")
local FuseWisp = Remotes:WaitForChild("FuseWisp")
local PrestigeEvent = Remotes:WaitForChild("Prestige")
local RedeemCode = Remotes:WaitForChild("RedeemCode")

local world = workspace:WaitForChild("SantuarioDellaFiamma")
local flameModel = world:WaitForChild("PrimordialFlame")
local flameCore = flameModel:WaitForChild("FlameCore")
local mainLight = flameCore:WaitForChild("MainFlameLight")
local altarsFolder = world:WaitForChild("LightAltars")
local zonesFolder = world:WaitForChild("WorldZones")

-- Setup Atmosfera Oscura Iniziale
for _, fx in ipairs(Lighting:GetChildren()) do
	if fx:IsA("Atmosphere") or fx:IsA("BloomEffect") then fx:Destroy() end
end
local atmo = Instance.new("Atmosphere", Lighting)
local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.75
bloom.Size = 24
bloom.Threshold = 1.0

local State = {
	LightPercent = 4,
	Heat = 0,
	FlamePulse = 0,
	Muted = false,
	LanternsLit = false,
	DrawerOpen = true,
	ActiveTab = "Flame",
}

-- Effetto Visivo 3D al Click sulla Fiamma (senza pop-up sullo schermo)
local function triggerFlameClickVisual(originPos, isCrit)
	State.FlamePulse = isCrit and 1.45 or 1.0

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = isCrit and Color3.fromRGB(255, 250, 140) or Color3.fromRGB(255, 180, 65)
	ring.Transparency = 0.35
	ring.Size = Vector3.new(0.25, 4, 4)
	ring.CFrame = CFrame.new(originPos or Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace

	local maxD = isCrit and 52 or 28
	local tw = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.25, maxD, maxD),
		Transparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() ring:Destroy() end)

	for _ = 1, (isCrit and 7 or 3) do
		local sp = Instance.new("Part")
		sp.Shape = Enum.PartType.Ball
		sp.Size = Vector3.new(0.4, 0.4, 0.4)
		sp.Anchored = true
		sp.CanCollide = false
		sp.Material = Enum.Material.Neon
		sp.Color = isCrit and Color3.fromRGB(255, 255, 160) or Color3.fromRGB(255, 190, 60)
		sp.Position = flameCore.Position + Vector3.new(math.random(-14, 14) * 0.1, 0, math.random(-14, 14) * 0.1)
		sp.Parent = workspace

		local dest = sp.Position + Vector3.new(math.random(-4, 4), math.random(5, 8), math.random(-4, 4))
		local stw = TweenService:Create(sp, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = dest,
			Size = Vector3.new(0.05, 0.05, 0.05),
			Transparency = 1,
		})
		stw:Play()
		stw.Completed:Connect(function() sp:Destroy() end)
	end
end

local function applyWorldIllumination(pct, upgrades)
	local t = math.clamp(pct / 100, 0, 1)

	Lighting.Brightness = 0.15 + t * 2.4
	Lighting.ClockTime = (t * 10.5) % 24
	Lighting.Ambient = Color3.fromRGB(8, 10, 18):Lerp(Color3.fromRGB(130, 120, 110), t)
	Lighting.OutdoorAmbient = Color3.fromRGB(10, 12, 22):Lerp(Color3.fromRGB(170, 155, 135), t)

	atmo.Density = 0.78 - t * 0.58
	atmo.Color = Color3.fromRGB(10, 12, 20):Lerp(Color3.fromRGB(255, 215, 155), t)
	atmo.Decay = Color3.fromRGB(5, 6, 12):Lerp(Color3.fromRGB(185, 135, 85), t)
	atmo.Haze = 2.5 - t * 1.8

	mainLight.Range = math.min(60, 24 + t * 36 + State.Heat * 8)
	mainLight.Brightness = 2.4 + t * 2.5 + State.Heat * 1.2

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

	if upgrades["u_lanterns"] and upgrades["u_lanterns"] > 0 then
		State.LanternsLit = true
		for _, obj in ipairs(zonesFolder.Lanterns:GetChildren()) do
			if string.sub(obj.Name, 1, 11) == "SkyLantern_" then
				obj.Color = Color3.fromRGB(255, 155, 65)
				obj.Material = Enum.Material.Neon
				local l = obj:FindFirstChildOfClass("PointLight")
				if l then l.Enabled = true; l.Brightness = 2.4 end
			end
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
		if l then l.Enabled = true; l.Brightness = 4.2 end
	end
end

-- Audio Dinamico
local sfx = Instance.new("Sound", playerGui)
sfx.SoundId = "rbxassetid://6895079853"
sfx.Volume = 0.38
local lastSfx, pitch = 0, 1.0
local function playSound(cue)
	if State.Muted then return end
	local now = os.clock()
	pitch = (now - lastSfx < 0.5) and math.min(1.75, pitch + 0.05) or 1.0
	lastSfx = now
	sfx.PlaybackSpeed = cue == "Crit" and 1.85 or (cue == "Prestige" and 0.72 or pitch)
	sfx:Play()
end

---------------------------------------------------------------------
-- DESIGN GUI PULITO, ELEGANTE E SENZA POP-UP INVADENTI
---------------------------------------------------------------------
local PALETTE = {
	GlassBg = Color3.fromRGB(15, 16, 23),
	CardBg = Color3.fromRGB(23, 25, 35),
	CardHover = Color3.fromRGB(30, 33, 46),
	AccentGold = Color3.fromRGB(255, 185, 65),
	AccentCyan = Color3.fromRGB(85, 225, 255),
	AccentGreen = Color3.fromRGB(52, 195, 125),
	AccentPurple = Color3.fromRGB(165, 85, 235),
	TextMain = Color3.fromRGB(245, 245, 250),
	TextSub = Color3.fromRGB(165, 172, 192),
	MutedBtn = Color3.fromRGB(40, 43, 58),
}

local hud = Instance.new("ScreenGui", playerGui)
hud.Name = "LastFlameCleanHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- 1. BARRA SUPERIORE MINIMAL & COMPATTA (Top HUD)
local topHud = Instance.new("Frame", hud)
topHud.Name = "TopHUD"
topHud.AnchorPoint = Vector2.new(0.5, 0)
topHud.Position = UDim2.new(0.5, 0, 0, 12)
topHud.Size = UDim2.new(0, 680, 0, 66)
topHud.BackgroundColor3 = PALETTE.GlassBg
topHud.BackgroundTransparency = 0.14
Instance.new("UICorner", topHud).CornerRadius = UDim.new(0, 14)

local topStroke = Instance.new("UIStroke", topHud)
topStroke.Color = PALETTE.AccentGold
topStroke.Transparency = 0.45
topStroke.Thickness = 1.5

local topGrad = Instance.new("UIGradient", topHud)
topGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 24, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 15, 22)),
})
topGrad.Rotation = 90

-- Colonna Sinistra TopHUD: Punti Luce + Calore Fiamma
local pointsFrame = Instance.new("Frame", topHud)
pointsFrame.Size = UDim2.new(0.34, 0, 1, 0)
pointsFrame.Position = UDim2.fromOffset(14, 0)
pointsFrame.BackgroundTransparency = 1

local pointsValue = Instance.new("TextLabel", pointsFrame)
pointsValue.Size = UDim2.new(1, 0, 0.56, 0)
pointsValue.Position = UDim2.fromOffset(0, 4)
pointsValue.BackgroundTransparency = 1
pointsValue.Text = "🔥 0"
pointsValue.TextColor3 = PALETTE.AccentGold
pointsValue.TextXAlignment = Enum.TextXAlignment.Left
pointsValue.Font = Enum.Font.GothamBlack
pointsValue.TextScaled = true

local heatRow = Instance.new("Frame", pointsFrame)
heatRow.Size = UDim2.new(0.92, 0, 0.28, 0)
heatRow.Position = UDim2.new(0, 0, 0.62, 0)
heatRow.BackgroundTransparency = 1

local heatLabel = Instance.new("TextLabel", heatRow)
heatLabel.Size = UDim2.new(0.46, 0, 1, 0)
heatLabel.BackgroundTransparency = 1
heatLabel.Text = "Calore x1.0"
heatLabel.TextColor3 = PALETTE.TextSub
heatLabel.TextXAlignment = Enum.TextXAlignment.Left
heatLabel.Font = Enum.Font.GothamBold
heatLabel.TextScaled = true

local heatBarBg = Instance.new("Frame", heatRow)
heatBarBg.Size = UDim2.new(0.52, 0, 0.55, 0)
heatBarBg.Position = UDim2.new(0.48, 0, 0.22, 0)
heatBarBg.BackgroundColor3 = Color3.fromRGB(34, 32, 44)
Instance.new("UICorner", heatBarBg).CornerRadius = UDim.new(1, 0)

local heatBarFill = Instance.new("Frame", heatBarBg)
heatBarFill.Size = UDim2.fromScale(0, 1)
heatBarFill.BackgroundColor3 = Color3.fromRGB(255, 130, 50)
Instance.new("UICorner", heatBarFill).CornerRadius = UDim.new(1, 0)

-- Colonna Centrale TopHUD: Progresso Luce nel Mondo
local lightFrame = Instance.new("Frame", topHud)
lightFrame.Size = UDim2.new(0.34, 0, 1, 0)
lightFrame.Position = UDim2.new(0.35, 0, 0, 0)
lightFrame.BackgroundTransparency = 1

local rankText = Instance.new("TextLabel", lightFrame)
rankText.Size = UDim2.new(1, 0, 0.42, 0)
rankText.Position = UDim2.fromOffset(0, 6)
rankText.BackgroundTransparency = 1
rankText.Text = "☀️ Luce 4% • Portatore di Scintilla"
rankText.TextColor3 = PALETTE.TextMain
rankText.Font = Enum.Font.GothamBold
rankText.TextScaled = true

local lightBarBg = Instance.new("Frame", lightFrame)
lightBarBg.Size = UDim2.new(1, 0, 0.24, 0)
lightBarBg.Position = UDim2.new(0, 0, 0.56, 0)
lightBarBg.BackgroundColor3 = Color3.fromRGB(32, 34, 46)
Instance.new("UICorner", lightBarBg).CornerRadius = UDim.new(1, 0)

local lightBarFill = Instance.new("Frame", lightBarBg)
lightBarFill.Size = UDim2.fromScale(0.04, 1)
lightBarFill.BackgroundColor3 = PALETTE.AccentGold
Instance.new("UICorner", lightBarFill).CornerRadius = UDim.new(1, 0)

-- Colonna Destra TopHUD: Statistiche Click & Passivo
local statsFrame = Instance.new("Frame", topHud)
statsFrame.Size = UDim2.new(0.27, 0, 1, 0)
statsFrame.Position = UDim2.new(0.71, 0, 0, 0)
statsFrame.BackgroundTransparency = 1

local clickStat = Instance.new("TextLabel", statsFrame)
clickStat.Size = UDim2.new(1, 0, 0.44, 0)
clickStat.Position = UDim2.fromOffset(0, 6)
clickStat.BackgroundTransparency = 1
clickStat.Text = "👆 +1 / click"
clickStat.TextColor3 = PALETTE.AccentCyan
clickStat.TextXAlignment = Enum.TextXAlignment.Right
clickStat.Font = Enum.Font.GothamBlack
clickStat.TextScaled = true

local ppsStat = Instance.new("TextLabel", statsFrame)
ppsStat.Size = UDim2.new(1, 0, 0.38, 0)
ppsStat.Position = UDim2.new(0, 0, 0.52, 0)
ppsStat.BackgroundTransparency = 1
ppsStat.Text = "⚡ +0 / sec"
ppsStat.TextColor3 = PALETTE.AccentGreen
ppsStat.TextXAlignment = Enum.TextXAlignment.Right
ppsStat.Font = Enum.Font.GothamBold
ppsStat.TextScaled = true

-- Unica striscia di stato discreta sotto la TopHUD (sostituisce tutti i pop-up invasivi!)
local statusPill = Instance.new("TextLabel", hud)
statusPill.AnchorPoint = Vector2.new(0.5, 0)
statusPill.Position = UDim2.new(0.5, 0, 0, 84)
statusPill.Size = UDim2.new(0, 420, 0, 24)
statusPill.BackgroundColor3 = PALETTE.GlassBg
statusPill.BackgroundTransparency = 1
statusPill.Text = ""
statusPill.TextColor3 = PALETTE.AccentGold
statusPill.TextTransparency = 1
statusPill.Font = Enum.Font.GothamBold
statusPill.TextScaled = true
Instance.new("UICorner", statusPill).CornerRadius = UDim.new(1, 0)

local statusToken = 0
local function setSubtleStatus(msg)
	if not msg or msg == "" then return end
	statusToken += 1
	local myToken = statusToken
	statusPill.Text = msg
	statusPill.BackgroundTransparency = 0.25
	statusPill.TextTransparency = 0
	task.delay(2.6, function()
		if statusToken == myToken then
			TweenService:Create(statusPill, TweenInfo.new(0.5), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}):Play()
		end
	end)
end

-- Micro-animazione pulita sul contatore punti al click (zero pop-up flottanti)
local function pulsePointsCounter(isCrit)
	pointsValue.TextColor3 = isCrit and Color3.fromRGB(255, 255, 160) or Color3.fromRGB(255, 225, 125)
	clickStat.TextColor3 = isCrit and Color3.fromRGB(255, 240, 110) or PALETTE.AccentCyan
	task.delay(0.14, function()
		pointsValue.TextColor3 = PALETTE.AccentGold
		clickStat.TextColor3 = PALETTE.AccentCyan
	end)
end

mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target and target:IsDescendantOf(flameModel) then
		triggerFlameClickVisual(Vector3.new(0, 1.3, 0), false)
		pulsePointsCounter(false)
		ClickFlameEvent:FireServer()
	end
end)

---------------------------------------------------------------------
-- 2. PANNELLO LATERALE DESTRO (Lascia la Fiamma al centro sempre libera!)
---------------------------------------------------------------------
local toggleDrawerBtn = Instance.new("TextButton", hud)
toggleDrawerBtn.AnchorPoint = Vector2.new(1, 0)
toggleDrawerBtn.Position = UDim2.new(1, -16, 0, 14)
toggleDrawerBtn.Size = UDim2.fromOffset(118, 36)
toggleDrawerBtn.BackgroundColor3 = PALETTE.GlassBg
toggleDrawerBtn.BackgroundTransparency = 0.12
toggleDrawerBtn.Text = "⚡ POTENZIA ▾"
toggleDrawerBtn.TextColor3 = PALETTE.AccentGold
toggleDrawerBtn.Font = Enum.Font.GothamBlack
toggleDrawerBtn.TextScaled = true
Instance.new("UICorner", toggleDrawerBtn).CornerRadius = UDim.new(0, 10)
local tStroke = Instance.new("UIStroke", toggleDrawerBtn)
tStroke.Color = PALETTE.AccentGold
tStroke.Transparency = 0.4

local sidePanel = Instance.new("Frame", hud)
sidePanel.Name = "UpgradeDrawer"
sidePanel.AnchorPoint = Vector2.new(1, 0)
sidePanel.Position = UDim2.new(1, -16, 0, 58)
sidePanel.Size = UDim2.new(0, 380, 1, -76)
sidePanel.BackgroundColor3 = PALETTE.GlassBg
sidePanel.BackgroundTransparency = 0.12
sidePanel.ClipsDescendants = true
Instance.new("UICorner", sidePanel).CornerRadius = UDim.new(0, 16)
local pStroke = Instance.new("UIStroke", sidePanel)
pStroke.Color = Color3.fromRGB(65, 70, 95)
pStroke.Thickness = 1.5

toggleDrawerBtn.MouseButton1Click:Connect(function()
	State.DrawerOpen = not State.DrawerOpen
	sidePanel.Visible = State.DrawerOpen
	toggleDrawerBtn.Text = State.DrawerOpen and "⚡ POTENZIA ▾" or "⚡ POTENZIA ▸"
end)

-- Barra Tab Segmented dentro il Pannello Destro
local tabBar = Instance.new("Frame", sidePanel)
tabBar.Size = UDim2.new(1, -20, 0, 38)
tabBar.Position = UDim2.fromOffset(10, 10)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 23, 33)
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local tabList = {
	{ Id = "Flame", Label = "🔥 Fiamma" },
	{ Id = "World", Label = "🌍 Regni" },
	{ Id = "Wisps", Label = "✨ Spiriti" },
	{ Id = "Alba", Label = "🌅 Alba" },
}

local tabBtns = {}
local pages = {}

local function selectTab(tabId)
	State.ActiveTab = tabId
	for id, btn in pairs(tabBtns) do
		local active = (id == tabId)
		btn.BackgroundColor3 = active and PALETTE.AccentGold or Color3.fromRGB(22, 23, 33)
		btn.TextColor3 = active and Color3.fromRGB(18, 16, 22) or PALETTE.TextSub
	end
	for id, pg in pairs(pages) do
		pg.Visible = (id == tabId)
	end
end

for i, info in ipairs(tabList) do
	local b = Instance.new("TextButton", tabBar)
	b.Size = UDim2.new(0.24, 0, 0.82, 0)
	b.Position = UDim2.new(0.01 + (i - 1) * 0.247, 0, 0.09, 0)
	b.BackgroundColor3 = Color3.fromRGB(22, 23, 33)
	b.Text = info.Label
	b.TextColor3 = PALETTE.TextSub
	b.Font = Enum.Font.GothamBlack
	b.TextScaled = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() selectTab(info.Id) end)
	tabBtns[info.Id] = b

	local page = Instance.new("Frame", sidePanel)
	page.Size = UDim2.new(1, -20, 1, -58)
	page.Position = UDim2.fromOffset(10, 54)
	page.BackgroundTransparency = 1
	page.Visible = false
	pages[info.Id] = page
end

-- Costruttore di Card Pulite per i Potenziamenti
local upgCards = {}
local function buildUpgradeList(parentPage, categoryFilter)
	local scroll = Instance.new("ScrollingFrame", parentPage)
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = PALETTE.AccentGold
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.fromOffset(0, 0)

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder

	local order = 0
	for _, u in ipairs(GameConfig.Upgrades) do
		if u.Category == categoryFilter then
			order += 1
			local card = Instance.new("Frame", scroll)
			card.LayoutOrder = order
			card.Size = UDim2.new(1, -6, 0, 66)
			card.BackgroundColor3 = PALETTE.CardBg
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
			local cStroke = Instance.new("UIStroke", card)
			cStroke.Color = Color3.fromRGB(48, 52, 70)
			cStroke.Thickness = 1

			local iconLbl = Instance.new("TextLabel", card)
			iconLbl.Size = UDim2.fromOffset(36, 36)
			iconLbl.Position = UDim2.fromOffset(10, 11)
			iconLbl.BackgroundColor3 = Color3.fromRGB(32, 34, 48)
			iconLbl.Text = u.Icon or "🔥"
			iconLbl.TextScaled = true
			Instance.new("UICorner", iconLbl).CornerRadius = UDim.new(0, 8)

			local titleLbl = Instance.new("TextLabel", card)
			titleLbl.Size = UDim2.new(1, -162, 0, 22)
			titleLbl.Position = UDim2.fromOffset(54, 8)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Text = u.Name
			titleLbl.TextColor3 = PALETTE.TextMain
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.Font = Enum.Font.GothamBlack
			titleLbl.TextScaled = true

			local descLbl = Instance.new("TextLabel", card)
			descLbl.Size = UDim2.new(1, -162, 0, 18)
			descLbl.Position = UDim2.fromOffset(54, 30)
			descLbl.BackgroundTransparency = 1
			descLbl.Text = u.Desc
			descLbl.TextColor3 = PALETTE.TextSub
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.Font = Enum.Font.GothamMedium
			descLbl.TextScaled = true

			local buyBtn = Instance.new("TextButton", card)
			buyBtn.AnchorPoint = Vector2.new(1, 0.5)
			buyBtn.Position = UDim2.new(1, -10, 0.5, -2)
			buyBtn.Size = UDim2.fromOffset(96, 38)
			buyBtn.BackgroundColor3 = PALETTE.MutedBtn
			buyBtn.Text = GameConfig.Format(u.BaseCost)
			buyBtn.TextColor3 = PALETTE.TextMain
			buyBtn.Font = Enum.Font.GothamBlack
			buyBtn.TextScaled = true
			Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
			buyBtn.MouseButton1Click:Connect(function() BuyUpgrade:FireServer(u.Id) end)

			-- Barra livello sottile in basso nella card
			local lvlTrack = Instance.new("Frame", card)
			lvlTrack.Size = UDim2.new(1, -20, 0, 4)
			lvlTrack.Position = UDim2.new(0, 10, 1, -8)
			lvlTrack.BackgroundColor3 = Color3.fromRGB(34, 36, 48)
			Instance.new("UICorner", lvlTrack).CornerRadius = UDim.new(1, 0)

			local lvlFill = Instance.new("Frame", lvlTrack)
			lvlFill.Size = UDim2.fromScale(0, 1)
			lvlFill.BackgroundColor3 = PALETTE.AccentGold
			Instance.new("UICorner", lvlFill).CornerRadius = UDim.new(1, 0)

			upgCards[u.Id] = {
				Cfg = u,
				Title = titleLbl,
				Btn = buyBtn,
				Fill = lvlFill,
				Stroke = cStroke,
			}
		end
	end
end

buildUpgradeList(pages["Flame"], "Flame")
buildUpgradeList(pages["World"], "World")

-- Pagina Spiriti di Luce (Ordinata e compatta)
local pWisps = pages["Wisps"]
local wispHeader = Instance.new("TextLabel", pWisps)
wispHeader.Size = UDim2.new(1, 0, 0, 22)
wispHeader.BackgroundTransparency = 1
wispHeader.Text = "Spiriti Attivi: 0/3 (Moltiplicano i Punti Click)"
wispHeader.TextColor3 = PALETTE.AccentCyan
wispHeader.Font = Enum.Font.GothamBold
wispHeader.TextScaled = true

local wispRows = {}
for i, w in ipairs(GameConfig.Wisps) do
	local row = Instance.new("Frame", pWisps)
	row.Size = UDim2.new(1, 0, 0, 46)
	row.Position = UDim2.fromOffset(0, 28 + (i - 1) * 52)
	row.BackgroundColor3 = PALETTE.CardBg
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 9)

	local nameLbl = Instance.new("TextLabel", row)
	nameLbl.Size = UDim2.new(0.66, 0, 0.52, 0)
	nameLbl.Position = UDim2.fromOffset(10, 3)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = w.Name .. " (" .. w.Chance .. ")"
	nameLbl.TextColor3 = w.Color
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Font = Enum.Font.GothamBlack
	nameLbl.TextScaled = true

	local countLbl = Instance.new("TextLabel", row)
	countLbl.Size = UDim2.new(0.66, 0, 0.42, 0)
	countLbl.Position = UDim2.fromOffset(10, 24)
	countLbl.BackgroundTransparency = 1
	countLbl.Text = "Base: 0 • Radiosi: 0"
	countLbl.TextColor3 = PALETTE.TextSub
	countLbl.TextXAlignment = Enum.TextXAlignment.Left
	countLbl.Font = Enum.Font.GothamMedium
	countLbl.TextScaled = true

	local fuseBtn = Instance.new("TextButton", row)
	fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
	fuseBtn.Position = UDim2.new(1, -8, 0.5, 0)
	fuseBtn.Size = UDim2.fromOffset(92, 32)
	fuseBtn.BackgroundColor3 = PALETTE.MutedBtn
	fuseBtn.Text = "FORGIA 3→1"
	fuseBtn.TextColor3 = PALETTE.TextMain
	fuseBtn.Font = Enum.Font.GothamBlack
	fuseBtn.TextScaled = true
	Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 7)
	fuseBtn.MouseButton1Click:Connect(function() FuseWisp:FireServer(w.Id) end)

	wispRows[w.Id] = { Count = countLbl, Fuse = fuseBtn, Cfg = w }
end

local summon1Btn = Instance.new("TextButton", pWisps)
summon1Btn.Size = UDim2.new(0.485, 0, 0, 42)
summon1Btn.Position = UDim2.new(0, 0, 1, -44)
summon1Btn.BackgroundColor3 = Color3.fromRGB(40, 155, 205)
summon1Btn.Text = "✨ Evoca x1 (500)"
summon1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
summon1Btn.Font = Enum.Font.GothamBlack
summon1Btn.TextScaled = true
Instance.new("UICorner", summon1Btn).CornerRadius = UDim.new(0, 9)
summon1Btn.MouseButton1Click:Connect(function() SummonWisp:FireServer(1) end)

local summon5Btn = Instance.new("TextButton", pWisps)
summon5Btn.Size = UDim2.new(0.485, 0, 0, 42)
summon5Btn.Position = UDim2.new(0.515, 0, 1, -44)
summon5Btn.BackgroundColor3 = PALETTE.AccentPurple
summon5Btn.Text = "✨ Evoca x5 (2.5K)"
summon5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
summon5Btn.Font = Enum.Font.GothamBlack
summon5Btn.TextScaled = true
Instance.new("UICorner", summon5Btn).CornerRadius = UDim.new(0, 9)
summon5Btn.MouseButton1Click:Connect(function() SummonWisp:FireServer(5) end)

-- Pagina Grande Alba, Codici & Audio
local pAlba = pages["Alba"]
local prestigeBtn = Instance.new("TextButton", pAlba)
prestigeBtn.Size = UDim2.new(1, 0, 0, 52)
prestigeBtn.Position = UDim2.fromOffset(0, 0)
prestigeBtn.BackgroundColor3 = PALETTE.AccentPurple
prestigeBtn.Text = "🌅 GRANDE ALBA (100M Punti)
Stelle Eterne: 0"
prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prestigeBtn.Font = Enum.Font.GothamBlack
prestigeBtn.TextScaled = true
Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 10)
prestigeBtn.MouseButton1Click:Connect(function() PrestigeEvent:FireServer() end)

local starButtons = {}
for i, sp in ipairs(GameConfig.StarPerks) do
	local b = Instance.new("TextButton", pAlba)
	b.Size = UDim2.new(1, 0, 0, 42)
	b.Position = UDim2.fromOffset(0, 58 + (i - 1) * 46)
	b.BackgroundColor3 = PALETTE.CardBg
	b.TextColor3 = PALETTE.TextMain
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() BuyStarPerk:FireServer(sp.Id) end)
	starButtons[sp.Id] = { Btn = b, Cfg = sp }
end

local codeBox = Instance.new("TextBox", pAlba)
codeBox.Size = UDim2.new(0.66, 0, 0, 36)
codeBox.Position = UDim2.new(0, 0, 1, -84)
codeBox.PlaceholderText = "Codice (LUCE100, FIAMMA)"
codeBox.Text = ""
codeBox.BackgroundColor3 = PALETTE.CardBg
codeBox.TextColor3 = PALETTE.TextMain
codeBox.Font = Enum.Font.GothamBold
codeBox.TextScaled = true
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

local codeBtn = Instance.new("TextButton", pAlba)
codeBtn.Size = UDim2.new(0.32, 0, 0, 36)
codeBtn.Position = UDim2.new(0.68, 0, 1, -84)
codeBtn.BackgroundColor3 = PALETTE.AccentGreen
codeBtn.Text = "RISCATTA"
codeBtn.TextColor3 = Color3.fromRGB(16, 22, 18)
codeBtn.Font = Enum.Font.GothamBlack
codeBtn.TextScaled = true
Instance.new("UICorner", codeBtn).CornerRadius = UDim.new(0, 8)
codeBtn.MouseButton1Click:Connect(function()
	local _, msg = RedeemCode:InvokeServer(codeBox.Text)
	setSubtleStatus(msg)
end)

local muteBtn = Instance.new("TextButton", pAlba)
muteBtn.Size = UDim2.new(1, 0, 0, 36)
muteBtn.Position = UDim2.new(0, 0, 1, -40)
muteBtn.BackgroundColor3 = PALETTE.MutedBtn
muteBtn.Text = "🔊 Suoni: Attivi"
muteBtn.TextColor3 = PALETTE.TextMain
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextScaled = true
Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 8)
muteBtn.MouseButton1Click:Connect(function()
	State.Muted = not State.Muted
	muteBtn.Text = State.Muted and "🔇 Suoni: Disattivati" or "🔊 Suoni: Attivi"
end)

selectTab("Flame")

-- Sincronizzazione dal Server
StateSync.OnClientEvent:Connect(function(st)
	State.LightPercent = st.LightPercent or 4
	State.Heat = st.Heat or 0

	pointsValue.Text = "🔥 " .. GameConfig.Format(st.Points)
	clickStat.Text = "👆 +" .. GameConfig.Format(st.ClickPower) .. " / click"
	ppsStat.Text = "⚡ +" .. GameConfig.Format(st.PointsPerSec) .. " / sec"

	heatLabel.Text = string.format("Calore x%.1f", st.HeatMult or 1.0)
	heatBarFill.Size = UDim2.fromScale(math.clamp(State.Heat, 0, 1), 1)

	lightBarFill.Size = UDim2.fromScale(math.clamp(State.LightPercent / 100, 0.02, 1), 1)
	rankText.Text = string.format("☀️ Luce %d%% • %s", State.LightPercent, st.RankName or "")

	wispHeader.Text = string.format("Spiriti Attivi: %d/%d (Moltiplicano i Punti Click)", st.EquippedCount or 0, st.MaxWispSlots or 3)

	applyWorldIllumination(State.LightPercent, st.Upgrades or {})

	if st.FlameClicked then
		triggerFlameClickVisual(Vector3.new(0, 1.3, 0), st.IsCrit)
		pulsePointsCounter(st.IsCrit)
	end
	if st.Shockwave then
		triggerFlameClickVisual(Vector3.new(0, 1.3, 0), true)
	end

	-- Altari
	for _, alt in ipairs(GameConfig.Altars) do
		local pad = altarsFolder:FindFirstChild(alt.Id)
		if pad and pad:FindFirstChild("InfoGui") then
			local lvl = (st.Altars and st.Altars[alt.Id]) or 0
			local cost = math.floor(alt.BaseCost * (alt.CostMult ^ lvl))
			pad.InfoGui.Frame.SubLabel.Text = "Lv. " .. lvl .. " • " .. GameConfig.Format(cost)
		end
	end

	-- Card Potenziamenti
	for id, entry in pairs(upgCards) do
		local u = entry.Cfg
		local lvl = (st.Upgrades and st.Upgrades[id]) or 0
		local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
		entry.Title.Text = string.format("%s  (%d/%d)", u.Name, lvl, u.MaxLevel)
		entry.Fill.Size = UDim2.fromScale(math.clamp(lvl / u.MaxLevel, 0, 1), 1)

		if lvl >= u.MaxLevel then
			entry.Btn.BackgroundColor3 = PALETTE.AccentGreen
			entry.Btn.TextColor3 = Color3.fromRGB(16, 22, 18)
			entry.Btn.Text = "MAX"
			entry.Stroke.Color = PALETTE.AccentGreen
		else
			local ok = (st.Points or 0) >= cost
			entry.Btn.BackgroundColor3 = ok and PALETTE.AccentGold or PALETTE.MutedBtn
			entry.Btn.TextColor3 = ok and Color3.fromRGB(18, 16, 22) or PALETTE.TextSub
			entry.Btn.Text = GameConfig.Format(cost)
			entry.Stroke.Color = ok and PALETTE.AccentGold or Color3.fromRGB(48, 52, 70)
		end
	end

	-- Spiriti
	for id, entry in pairs(wispRows) do
		local baseCnt = (st.WispCounts and st.WispCounts[id]) or 0
		local radCnt = (st.WispCounts and st.WispCounts[id .. "_rad"]) or 0
		entry.Count.Text = string.format("Base: %d • Radiosi (x2.5): %d", baseCnt, radCnt)
		local canFuse = baseCnt >= 3
		entry.Fuse.BackgroundColor3 = canFuse and PALETTE.AccentGold or PALETTE.MutedBtn
		entry.Fuse.TextColor3 = canFuse and Color3.fromRGB(18, 16, 22) or PALETTE.TextSub
	end

	-- Prestige
	if (st.Points or 0) >= GameConfig.PrestigeCost then
		local gain = math.max(1, math.floor(math.log10(st.Points / 1e7)))
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 165)
		prestigeBtn.Text = "🌅 COMPI GRANDE ALBA (+" .. gain .. " Stelle)
Stelle attuali: " .. (st.EternalStars or 0)
	else
		prestigeBtn.BackgroundColor3 = PALETTE.AccentPurple
		prestigeBtn.Text = "🌅 GRANDE ALBA (100M Punti)
Stelle Eterne: " .. (st.EternalStars or 0)
	end
	for id, entry in pairs(starButtons) do
		local sp = entry.Cfg
		local lvl = (st.StarPerks and st.StarPerks[id]) or 0
		local cost = math.floor(sp.Cost * (sp.CostMult ^ lvl))
		if lvl >= sp.MaxLevel then
			entry.Btn.BackgroundColor3 = PALETTE.AccentGreen
			entry.Btn.TextColor3 = Color3.fromRGB(16, 22, 18)
			entry.Btn.Text = sp.Name .. " [MAX]"
		else
			local ok = (st.EternalStars or 0) >= cost
			entry.Btn.BackgroundColor3 = ok and Color3.fromRGB(150, 65, 210) or PALETTE.CardBg
			entry.Btn.TextColor3 = PALETTE.TextMain
			entry.Btn.Text = string.format("%s (%d/%d) — %d⭐", sp.Name, lvl, sp.MaxLevel, cost)
		end
	end

	if st.SoundCue then playSound(st.SoundCue) end
	if st.StatusBanner then setSubtleStatus(st.StatusBanner) end
end)

---------------------------------------------------------------------
-- ANIMAZIONE FIAMMA, LANTERNA PERSONALE & SPIRITI DI LUCE
---------------------------------------------------------------------
local visualFolder = Instance.new("Folder", workspace)
visualFolder.Name = "LightWispsVisuals"

local wispColors = {}
for _, w in ipairs(GameConfig.Wisps) do wispColors[w.Id] = w.Color end

local t = 0
RunService.RenderStepped:Connect(function(dt)
	t += dt
	State.FlamePulse = math.max(0, State.FlamePulse - dt * 4.0)
	local scale = (1 + (State.LightPercent / 100) * 1.3 + State.Heat * 0.35) * (1 + math.sin(t * 5) * 0.06 + State.FlamePulse * 0.28)
	flameCore.Size = Vector3.new(3.8, 4.8, 3.8) * scale

	if State.LanternsLit then
		for i, obj in ipairs(zonesFolder.Lanterns:GetChildren()) do
			if string.sub(obj.Name, 1, 11) == "SkyLantern_" then
				obj.Position += Vector3.new(0, math.sin(t * 1.6 + i) * 0.015, 0)
			end
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local pFolder = visualFolder:FindFirstChild(plr.Name)

		if hrp then
			if not pFolder then
				pFolder = Instance.new("Folder", visualFolder)
				pFolder.Name = plr.Name
			end

			local rLvl = plr:GetAttribute("RadiusLevel") or 0
			local personalLight = hrp:FindFirstChild("PersonalLantern")
			if not personalLight then
				personalLight = Instance.new("PointLight", hrp)
				personalLight.Name = "PersonalLantern"
				personalLight.Color = Color3.fromRGB(255, 195, 110)
			end
			personalLight.Range = 20 + rLvl * 5
			personalLight.Brightness = 1.4 + rLvl * 0.25

			local ok, ids = pcall(function() return HttpService:JSONDecode(plr:GetAttribute("EquippedWisps") or "[]") end)
			ids = (ok and type(ids) == "table") and ids or {}

			for i = 1, 5 do
				local wPart = pFolder:FindFirstChild("Wisp_" .. i)
				if ids[i] then
					local isRad = string.sub(ids[i], -4) == "_rad"
					local baseId = isRad and string.sub(ids[i], 1, -5) or ids[i]
					if not wPart then
						wPart = Instance.new("Part", pFolder)
						wPart.Name = "Wisp_" .. i
						wPart.Shape = Enum.PartType.Ball
						wPart.Anchored = true
						wPart.CanCollide = false
						wPart.Material = Enum.Material.Neon
						Instance.new("PointLight", wPart)
					end
					wPart.Size = isRad and Vector3.new(1.35, 1.35, 1.35) or Vector3.new(0.95, 0.95, 0.95)
					local col = isRad and Color3.fromRGB(255, 230, 95) or (wispColors[baseId] or Color3.fromRGB(255, 200, 80))
					wPart.Color = col
					local wl = wPart:FindFirstChildOfClass("PointLight")
					wl.Color = col
					wl.Range = isRad and 24 or 16
					wl.Brightness = isRad and 2.5 or 1.8

					local a = t * 2.0 + (i * (math.pi * 2 / #ids))
					wPart.Position = hrp.Position + Vector3.new(math.cos(a) * 4.0, 1.5 + math.sin(t * 3.5 + i) * 0.5, math.sin(a) * 4.0)
				elseif wPart then
					wPart:Destroy()
				end
			end
		elseif pFolder then
			pFolder:Destroy()
		end
	end
end)
