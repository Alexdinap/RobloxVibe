local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSync = Remotes:WaitForChild("StateSync")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local BuyDarkUpgrade = Remotes:WaitForChild("BuyDarkUpgrade")
local BuyAfkUpgrade = Remotes:WaitForChild("BuyAfkUpgrade")
local PrestigeEvent = Remotes:WaitForChild("Prestige")
local CraftDroneEvent = Remotes:WaitForChild("CraftDrone")
local FuseDroneEvent = Remotes:WaitForChild("FuseDrone")
local StartChallengeEvent = Remotes:WaitForChild("StartChallenge")
local AbandonChallengeEvent = Remotes:WaitForChild("AbandonChallenge")
local DonateBatteryEvent = Remotes:WaitForChild("DonateBattery")
local RedeemCode = Remotes:WaitForChild("RedeemCode")
local ClaimDaily = Remotes:WaitForChild("ClaimDaily")

local world = workspace:WaitForChild("QuantumWorld")
local upgradeWall = world:WaitForChild("UpgradeWall")
local prestigeWall = world:WaitForChild("PrestigeWall")
local floorButtons = world:WaitForChild("FloorButtons")
local coreAssembly = world:WaitForChild("QuantumCoreAssembly")
local corePart = coreAssembly:WaitForChild("CorePart")
local ring1 = coreAssembly:WaitForChild("Ring1")
local ring2 = coreAssembly:WaitForChild("Ring2")
local critOrb = coreAssembly:WaitForChild("CritOrb")
local droneHolo = world:WaitForChild("DroneHolo")

-- Stato Client Locale
local State = {
	TotalWatt = 0,
	IsOverload = false,
	PulseScale = 0,
	Muted = false,
}

-- Audio Dinamico
local sfx = Instance.new("Sound")
sfx.SoundId = "rbxassetid://6895079853"
sfx.Volume = 0.45
sfx.Parent = playerGui

local comboPitch, lastSfx = 1.0, 0
local function playSound(cue)
	if State.Muted then return end
	local now = os.clock()
	comboPitch = (now - lastSfx < 0.6) and math.min(1.65, comboPitch + 0.05) or 1.0
	lastSfx = now
	sfx.PlaybackSpeed = cue == "Prestige" and 0.7 or comboPitch
	sfx:Play()
end

---------------------------------------------------------------------
-- 1. INTERFACCIA GRAFICA PULITA E NON CONFUSIONARIA (HUD + DOCK + 1 FINESTRA)
---------------------------------------------------------------------
local hud = Instance.new("ScreenGui")
hud.Name = "QuantumHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

-- Barra Superiore Risorse (Compatta)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0.76, 0, 0, 52)
topBar.Position = UDim2.new(0.12, 0, 0, 10)
topBar.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
topBar.BackgroundTransparency = 0.12
topBar.Parent = hud
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
local topStroke = Instance.new("UIStroke", topBar)
topStroke.Color = Color3.fromRGB(0, 215, 255)
topStroke.Thickness = 2

local function makeTopStat(idx, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.19, 0, 0.85, 0)
	lbl.Position = UDim2.new(0.01 + (idx - 1) * 0.198, 0, 0.075, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = topBar
	return lbl
end

local wattLbl = makeTopStat(1, Color3.fromRGB(0, 230, 255))
local wpsLbl = makeTopStat(2, Color3.fromRGB(120, 255, 170))
local plasmaLbl = makeTopStat(3, Color3.fromRGB(220, 100, 255))
local fragLbl = makeTopStat(4, Color3.fromRGB(80, 255, 200))
local dmLbl = makeTopStat(5, Color3.fromRGB(255, 195, 50))

-- Pillola Grado Attuale (sotto la barra superiore a sinistra)
local rankPill = Instance.new("TextLabel")
rankPill.Size = UDim2.new(0, 230, 0, 28)
rankPill.Position = UDim2.new(0.12, 0, 0, 68)
rankPill.BackgroundColor3 = Color3.fromRGB(16, 20, 34)
rankPill.BackgroundTransparency = 0.15
rankPill.Text = "🎖️ Grado: Apprendista"
rankPill.TextColor3 = Color3.fromRGB(0, 225, 255)
rankPill.Font = Enum.Font.GothamBold
rankPill.TextScaled = true
rankPill.Parent = hud
Instance.new("UICorner", rankPill).CornerRadius = UDim.new(0, 8)

-- Banner Eventi & Sfida Attiva (compare solo quando serve)
local eventBanner = Instance.new("TextLabel")
eventBanner.Size = UDim2.new(0.52, 0, 0, 32)
eventBanner.Position = UDim2.new(0.36, 0, 0, 68)
eventBanner.BackgroundColor3 = Color3.fromRGB(35, 16, 48)
eventBanner.BackgroundTransparency = 0.15
eventBanner.TextColor3 = Color3.fromRGB(255, 235, 95)
eventBanner.Font = Enum.Font.GothamBold
eventBanner.TextScaled = true
eventBanner.Visible = false
eventBanner.Parent = hud
Instance.new("UICorner", eventBanner).CornerRadius = UDim.new(0, 8)

-- Popup Fluttuante
local function showPopup(text, color)
	local pop = Instance.new("TextLabel")
	pop.Size = UDim2.fromOffset(440, 36)
	pop.Position = UDim2.new(0.5, -220, 0.64, 0)
	pop.BackgroundTransparency = 1
	pop.Text = text
	pop.TextColor3 = color or Color3.fromRGB(255, 240, 110)
	pop.TextStrokeTransparency = 0.2
	pop.Font = Enum.Font.GothamBlack
	pop.TextScaled = true
	pop.Parent = hud

	local tw = TweenService:Create(pop, TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -220, 0.49, 0),
		TextTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function() pop:Destroy() end)
end

-- Dock Inferiore (4 Pulsanti Compatti -> Apri/Chiudi un'unica finestra pulita)
local dock = Instance.new("Frame")
dock.Size = UDim2.new(0, 640, 0, 48)
dock.Position = UDim2.new(0.5, -320, 1, -60)
dock.BackgroundColor3 = Color3.fromRGB(13, 16, 26)
dock.BackgroundTransparency = 0.12
dock.Parent = hud
Instance.new("UICorner", dock).CornerRadius = UDim.new(0, 12)
local dockStroke = Instance.new("UIStroke", dock)
dockStroke.Color = Color3.fromRGB(0, 195, 255)
dockStroke.Thickness = 1.5

local function makeDockTab(idx, text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.235, 0, 0.78, 0)
	b.Position = UDim2.new(0.015 + (idx - 1) * 0.245, 0, 0.11, 0)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = dock
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local tabDronesBtn = makeDockTab(1, "🛸 DRONI & FORGIA", Color3.fromRGB(155, 50, 225))
local tabChallengeBtn = makeDockTab(2, "🔥 SFIDE & AFK", Color3.fromRGB(225, 115, 20))
local tabAchBtn = makeDockTab(3, "🏆 OBIETTIVI", Color3.fromRGB(20, 155, 115))
local tabExtraBtn = makeDockTab(4, "⚡ EXTRA & TP", Color3.fromRGB(0, 140, 215))

-- Unica Finestra Centrale con 4 Schede (Zero finestre sovrapposte!)
local mainModal = Instance.new("Frame")
mainModal.Size = UDim2.fromOffset(540, 410)
mainModal.Position = UDim2.new(0.5, -270, 0.5, -215)
mainModal.BackgroundColor3 = Color3.fromRGB(15, 19, 30)
mainModal.Visible = false
mainModal.ZIndex = 10
mainModal.Parent = hud
Instance.new("UICorner", mainModal).CornerRadius = UDim.new(0, 14)
local modalStroke = Instance.new("UIStroke", mainModal)
modalStroke.Color = Color3.fromRGB(0, 215, 255)
modalStroke.Thickness = 2

local modalTitle = Instance.new("TextLabel")
modalTitle.Size = UDim2.new(1, -55, 0, 40)
modalTitle.Position = UDim2.fromOffset(16, 6)
modalTitle.BackgroundTransparency = 1
modalTitle.Text = "PANNELLO"
modalTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
modalTitle.TextXAlignment = Enum.TextXAlignment.Left
modalTitle.Font = Enum.Font.GothamBlack
modalTitle.TextScaled = true
modalTitle.ZIndex = 11
modalTitle.Parent = mainModal

local closeModalBtn = Instance.new("TextButton")
closeModalBtn.Size = UDim2.fromOffset(34, 34)
closeModalBtn.Position = UDim2.new(1, -42, 0, 8)
closeModalBtn.BackgroundColor3 = Color3.fromRGB(205, 55, 70)
closeModalBtn.Text = "X"
closeModalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeModalBtn.Font = Enum.Font.GothamBlack
closeModalBtn.ZIndex = 11
closeModalBtn.Parent = mainModal
Instance.new("UICorner", closeModalBtn).CornerRadius = UDim.new(0, 8)

local pages = {}
local currentPage = nil
local function openPage(pageName, titleText)
	if mainModal.Visible and currentPage == pageName then
		mainModal.Visible = false
		return
	end
	currentPage = pageName
	modalTitle.Text = titleText
	for k, p in pairs(pages) do
		p.Visible = (k == pageName)
	end
	mainModal.Visible = true
end

closeModalBtn.MouseButton1Click:Connect(function() mainModal.Visible = false end)

local function makePage(name)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -24, 1, -54)
	f.Position = UDim2.fromOffset(12, 48)
	f.BackgroundTransparency = 1
	f.Visible = false
	f.ZIndex = 11
	f.Parent = mainModal
	pages[name] = f
	return f
end

-- SCHEDA 1: DRONI & FORGIA SOVRACCARICO
local pDrones = makePage("Drones")
local droneRows = {}
for i, d in ipairs(GameConfig.Drones) do
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 38)
	row.Position = UDim2.fromOffset(0, (i - 1) * 42)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
	row.ZIndex = 12
	row.Parent = pDrones
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(0.72, 0, 1, 0)
	info.Position = UDim2.fromOffset(8, 0)
	info.BackgroundTransparency = 1
	info.TextColor3 = d.Color
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.Font = Enum.Font.GothamBold
	info.TextScaled = true
	info.ZIndex = 13
	info.Parent = row

	local fuseBtn = Instance.new("TextButton")
	fuseBtn.Size = UDim2.new(0.25, 0, 0.78, 0)
	fuseBtn.Position = UDim2.new(0.735, 0, 0.11, 0)
	fuseBtn.BackgroundColor3 = Color3.fromRGB(230, 135, 20)
	fuseBtn.Text = "FORGIA (3->1)"
	fuseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	fuseBtn.Font = Enum.Font.GothamBlack
	fuseBtn.TextScaled = true
	fuseBtn.ZIndex = 13
	fuseBtn.Parent = row
	Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 6)
	fuseBtn.MouseButton1Click:Connect(function() FuseDroneEvent:FireServer(d.Id) end)

	droneRows[d.Id] = { Info = info, Fuse = fuseBtn, Cfg = d }
end

local craft1Btn = Instance.new("TextButton")
craft1Btn.Size = UDim2.new(0.48, 0, 0, 42)
craft1Btn.Position = UDim2.new(0, 0, 1, -44)
craft1Btn.BackgroundColor3 = Color3.fromRGB(165, 55, 235)
craft1Btn.Text = "CREA x1 (50 Plasma)"
craft1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
craft1Btn.Font = Enum.Font.GothamBlack
craft1Btn.TextScaled = true
craft1Btn.ZIndex = 12
craft1Btn.Parent = pDrones
Instance.new("UICorner", craft1Btn).CornerRadius = UDim.new(0, 8)
craft1Btn.MouseButton1Click:Connect(function() CraftDroneEvent:FireServer(1) end)

local craft5Btn = Instance.new("TextButton")
craft5Btn.Size = UDim2.new(0.48, 0, 0, 42)
craft5Btn.Position = UDim2.new(0.52, 0, 1, -44)
craft5Btn.BackgroundColor3 = Color3.fromRGB(220, 65, 160)
craft5Btn.Text = "CREA x5 (250 Plasma)"
craft5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
craft5Btn.Font = Enum.Font.GothamBlack
craft5Btn.TextScaled = true
craft5Btn.ZIndex = 12
craft5Btn.Parent = pDrones
Instance.new("UICorner", craft5Btn).CornerRadius = UDim.new(0, 8)
craft5Btn.MouseButton1Click:Connect(function() CraftDroneEvent:FireServer(5) end)

tabDronesBtn.MouseButton1Click:Connect(function() openPage("Drones", "🛸 FLOTTA DRONI & FORGIA") end)

-- SCHEDA 2: SFIDE QUANTICHE & NEGOZIO TEMPORALE AFK
local pChal = makePage("Challenges")
local chTitle = Instance.new("TextLabel")
chTitle.Size = UDim2.new(1, 0, 0, 24)
chTitle.BackgroundTransparency = 1
chTitle.Text = "🔥 SFIDE QUANTICHE (Moltiplicatori Permanenti)"
chTitle.TextColor3 = Color3.fromRGB(255, 190, 60)
chTitle.TextXAlignment = Enum.TextXAlignment.Left
chTitle.Font = Enum.Font.GothamBlack
chTitle.TextScaled = true
chTitle.ZIndex = 12
chTitle.Parent = pChal

local chButtons = {}
for i, c in ipairs(GameConfig.Challenges) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 46)
	b.Position = UDim2.fromOffset(0, 26 + (i - 1) * 50)
	b.BackgroundColor3 = Color3.fromRGB(32, 26, 46)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.ZIndex = 12
	b.Parent = pChal
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() StartChallengeEvent:FireServer(c.Id) end)
	chButtons[c.Id] = { Btn = b, Cfg = c }
end

local abandonBtn = Instance.new("TextButton")
abandonBtn.Size = UDim2.new(1, 0, 0, 28)
abandonBtn.Position = UDim2.fromOffset(0, 178)
abandonBtn.BackgroundColor3 = Color3.fromRGB(160, 45, 55)
abandonBtn.Text = "ABBANDONA SFIDA IN CORSO"
abandonBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
abandonBtn.Font = Enum.Font.GothamBold
abandonBtn.TextScaled = true
abandonBtn.Visible = false
abandonBtn.ZIndex = 12
abandonBtn.Parent = pChal
Instance.new("UICorner", abandonBtn).CornerRadius = UDim.new(0, 6)
abandonBtn.MouseButton1Click:Connect(function() AbandonChallengeEvent:FireServer() end)

local afkHeader = Instance.new("TextLabel")
afkHeader.Size = UDim2.new(1, 0, 0, 24)
afkHeader.Position = UDim2.fromOffset(0, 212)
afkHeader.BackgroundTransparency = 1
afkHeader.Text = "⏳ POTENZIAMENTI TEMPORALI (Spendi Frammenti AFK)"
afkHeader.TextColor3 = Color3.fromRGB(80, 255, 190)
afkHeader.TextXAlignment = Enum.TextXAlignment.Left
afkHeader.Font = Enum.Font.GothamBlack
afkHeader.TextScaled = true
afkHeader.ZIndex = 12
afkHeader.Parent = pChal

local afkButtons = {}
for i, a in ipairs(GameConfig.AfkUpgrades) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.49, 0, 0, 52)
	b.Position = UDim2.new(col * 0.51, 0, 0, 240 + row * 56)
	b.BackgroundColor3 = Color3.fromRGB(20, 44, 48)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.ZIndex = 12
	b.Parent = pChal
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function() BuyAfkUpgrade:FireServer(a.Id) end)
	afkButtons[a.Id] = { Btn = b, Cfg = a }
end

tabChallengeBtn.MouseButton1Click:Connect(function() openPage("Challenges", "🔥 SFIDE QUANTICHE & CAMERA AFK") end)

-- SCHEDA 3: OBIETTIVI PERMANENTI
local pAch = makePage("Achievements")
local achScroll = Instance.new("ScrollingFrame")
achScroll.Size = UDim2.fromScale(1, 1)
achScroll.CanvasSize = UDim2.fromOffset(0, #GameConfig.Achievements * 44)
achScroll.BackgroundTransparency = 1
achScroll.ScrollBarThickness = 6
achScroll.ZIndex = 12
achScroll.Parent = pAch

local achRows = {}
for i, ach in ipairs(GameConfig.Achievements) do
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -10, 0, 38)
	lbl.Position = UDim2.fromOffset(0, (i - 1) * 42)
	lbl.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
	lbl.TextColor3 = Color3.fromRGB(220, 230, 245)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.ZIndex = 13
	lbl.Parent = achScroll
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
	achRows[ach.Id] = { Label = lbl, Cfg = ach }
end

tabAchBtn.MouseButton1Click:Connect(function() openPage("Achievements", "🏆 OBIETTIVI & BONUS PERMANENTI") end)

-- SCHEDA 4: CODICI PROMO, PREMIO GIORNO, BATTERIA SERVER & TELETRASPORTO
local pExtra = makePage("Extra")
local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(0.66, 0, 0, 38)
codeBox.Position = UDim2.fromOffset(0, 4)
codeBox.PlaceholderText = "Codice (es. QUANTUM100, CITADEL)"
codeBox.Text = ""
codeBox.BackgroundColor3 = Color3.fromRGB(28, 34, 54)
codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
codeBox.Font = Enum.Font.GothamBold
codeBox.TextScaled = true
codeBox.ZIndex = 12
codeBox.Parent = pExtra
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

local redeemBtn = Instance.new("TextButton")
redeemBtn.Size = UDim2.new(0.32, 0, 0, 38)
redeemBtn.Position = UDim2.new(0.68, 0, 0, 4)
redeemBtn.BackgroundColor3 = Color3.fromRGB(0, 195, 115)
redeemBtn.Text = "RISCATTA"
redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
redeemBtn.Font = Enum.Font.GothamBlack
redeemBtn.TextScaled = true
redeemBtn.ZIndex = 12
redeemBtn.Parent = pExtra
Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 8)
redeemBtn.MouseButton1Click:Connect(function()
	local _, msg = RedeemCode:InvokeServer(codeBox.Text)
	showPopup(msg or "")
end)

local dailyBtn = Instance.new("TextButton")
dailyBtn.Size = UDim2.new(0.49, 0, 0, 42)
dailyBtn.Position = UDim2.fromOffset(0, 50)
dailyBtn.BackgroundColor3 = Color3.fromRGB(165, 55, 235)
dailyBtn.Text = "📅 PREMIO GIORNALIERO (24H)"
dailyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyBtn.Font = Enum.Font.GothamBold
dailyBtn.TextScaled = true
dailyBtn.ZIndex = 12
dailyBtn.Parent = pExtra
Instance.new("UICorner", dailyBtn).CornerRadius = UDim.new(0, 8)
dailyBtn.MouseButton1Click:Connect(function()
	local _, msg = ClaimDaily:InvokeServer()
	showPopup(msg or "")
end)

local donateBtn = Instance.new("TextButton")
donateBtn.Size = UDim2.new(0.49, 0, 0, 42)
donateBtn.Position = UDim2.new(0.51, 0, 0, 50)
donateBtn.BackgroundColor3 = Color3.fromRGB(225, 165, 20)
donateBtn.Text = "⚡ DONA 25 PLASMA AL SERVER"
donateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
donateBtn.Font = Enum.Font.GothamBold
donateBtn.TextScaled = true
donateBtn.ZIndex = 12
donateBtn.Parent = pExtra
Instance.new("UICorner", donateBtn).CornerRadius = UDim.new(0, 8)
donateBtn.MouseButton1Click:Connect(function() DonateBatteryEvent:FireServer() end)

local tpTargets = {
	{ Name = "🔵 Nucleo Centrale", Pos = Vector3.new(0, 5, 58) },
	{ Name = "🟢 Albero Potenziamenti", Pos = Vector3.new(0, 5, -50) },
	{ Name = "🟣 Fabbrica Droni", Pos = Vector3.new(64, 5, 44) },
	{ Name = "🔴 Santuario Materia Oscura", Pos = Vector3.new(66, 5, -14) },
	{ Name = "⏳ Camera AFK", Pos = Vector3.new(-64, 5, 44) },
	{ Name = "🔥 Portale Sfide", Pos = Vector3.new(-68, 5, 6) },
}
for i, t in ipairs(tpTargets) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.49, 0, 0, 44)
	b.Position = UDim2.new(col * 0.51, 0, 0, 108 + row * 50)
	b.BackgroundColor3 = Color3.fromRGB(28, 38, 62)
	b.Text = t.Name
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.ZIndex = 12
	b.Parent = pExtra
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(t.Pos)
			mainModal.Visible = false
		end
	end)
end

local muteBtn = Instance.new("TextButton")
muteBtn.Size = UDim2.new(1, 0, 0, 38)
muteBtn.Position = UDim2.new(0, 0, 1, -40)
muteBtn.BackgroundColor3 = Color3.fromRGB(55, 65, 90)
muteBtn.Text = "🔊 Audio Effetti: ATTIVO"
muteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextScaled = true
muteBtn.ZIndex = 12
muteBtn.Parent = pExtra
Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 8)
muteBtn.MouseButton1Click:Connect(function()
	State.Muted = not State.Muted
	muteBtn.Text = State.Muted and "🔇 Audio Effetti: DISATTIVATO" or "🔊 Audio Effetti: ATTIVO"
end)

tabExtraBtn.MouseButton1Click:Connect(function() openPage("Extra", "⚡ CODICI, SERVER BOOST & TELETRASPORTO") end)

---------------------------------------------------------------------
-- 2. INTERFACCE SUI MURI 3D (ALBERO UPGRADE & SANTUARIO MATERIA OSCURA)
---------------------------------------------------------------------
local wallGui = Instance.new("SurfaceGui")
wallGui.Name = "WallTreeGui"
wallGui.Adornee = upgradeWall
wallGui.Face = Enum.NormalId.Front
wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
wallGui.PixelsPerStud = 25
wallGui.Parent = playerGui

local canvasW, canvasH = 100 * 25, 50 * 25
local nodeMap = {}
for _, u in ipairs(GameConfig.Upgrades) do nodeMap[u.Id] = u end

for _, u in ipairs(GameConfig.Upgrades) do
	if u.Prereq and nodeMap[u.Prereq] then
		local p = nodeMap[u.Prereq]
		local x1, y1 = p.GridX * canvasW, p.GridY * canvasH
		local x2, y2 = u.GridX * canvasW, u.GridY * canvasH
		local dx, dy = x2 - x1, y2 - y1
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
		line.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 8)
		line.Rotation = math.deg(math.atan2(dy, dx))
		line.BackgroundColor3 = Color3.fromRGB(0, 185, 245)
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = wallGui
	end
end

local nodeButtons = {}
for _, u in ipairs(GameConfig.Upgrades) do
	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.fromScale(u.GridX, u.GridY)
	btn.Size = UDim2.fromOffset(250, 105)
	btn.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.ZIndex = 3
	btn.Parent = wallGui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
	btn.MouseButton1Click:Connect(function() BuyUpgrade:FireServer(u.Id) end)
	nodeButtons[u.Id] = { Button = btn, Cfg = u }
end

local prestigeBtn = Instance.new("TextButton")
prestigeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
prestigeBtn.Position = UDim2.fromScale(0.5, 0.93)
prestigeBtn.Size = UDim2.fromOffset(660, 82)
prestigeBtn.BackgroundColor3 = Color3.fromRGB(130, 20, 60)
prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (Richiede 1.00T W)"
prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prestigeBtn.Font = Enum.Font.GothamBlack
prestigeBtn.TextScaled = true
prestigeBtn.ZIndex = 3
prestigeBtn.Parent = wallGui
Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 14)
prestigeBtn.MouseButton1Click:Connect(function() PrestigeEvent:FireServer() end)

-- Santuario Materia Oscura
local dmGui = Instance.new("SurfaceGui")
dmGui.Adornee = prestigeWall
dmGui.Face = Enum.NormalId.Front
dmGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
dmGui.PixelsPerStud = 25
dmGui.Parent = playerGui

local dmHeader = Instance.new("TextLabel")
dmHeader.Size = UDim2.new(1, 0, 0.14, 0)
dmHeader.BackgroundColor3 = Color3.fromRGB(170, 30, 85)
dmHeader.Text = "🌌 SANTUARIO MATERIA OSCURA"
dmHeader.TextColor3 = Color3.fromRGB(255, 255, 255)
dmHeader.Font = Enum.Font.GothamBlack
dmHeader.TextScaled = true
dmHeader.Parent = dmGui

local dmButtons = {}
for i, du in ipairs(GameConfig.DarkUpgrades) do
	local col = (i - 1) % 2
	local row = math.floor((i - 1) / 2)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.45, 0, 0.23, 0)
	b.Position = UDim2.new(0.035 + col * 0.48, 0, 0.18 + row * 0.26, 0)
	b.BackgroundColor3 = Color3.fromRGB(36, 20, 52)
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = dmGui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	b.MouseButton1Click:Connect(function() BuyDarkUpgrade:FireServer(du.Id) end)
	dmButtons[du.Id] = { Button = b, Cfg = du }
end

---------------------------------------------------------------------
-- 3. SINCRONIZZAZIONE STATO DA SERVER
---------------------------------------------------------------------
StateSync.OnClientEvent:Connect(function(state)
	State.TotalWatt = state.TotalWatt or 0
	State.IsOverload = (state.CoreOverloadLeft or 0) > 0
	if state.CorePulse then State.PulseScale = 1.0 end

	wattLbl.Text = "⚡ " .. GameConfig.Format(state.Watt) .. " W"
	wpsLbl.Text = "+" .. GameConfig.Format(state.WattPerSec) .. " W/s"
	plasmaLbl.Text = "🔮 " .. GameConfig.Format(state.Plasma) .. " (+" .. GameConfig.Format(state.PlasmaPerSec) .. "/s)"
	fragLbl.Text = "⏳ " .. GameConfig.Format(state.TimeFragments) .. " Framm."
	dmLbl.Text = "🌌 " .. tostring(state.DarkMatter) .. " M. Oscura"

	if state.RankColor then
		rankPill.TextColor3 = Color3.new(state.RankColor[1], state.RankColor[2], state.RankColor[3])
	end
	rankPill.Text = "🎖️ Grado: " .. (state.RankName or "Apprendista")

	tabDronesBtn.Text = string.format("🛸 DRONI (%d/%d)", state.EquippedCount or 0, state.MaxDroneSlots or 3)
	local dCost = state.DroneCost or 50
	craft1Btn.Text = "CREA x1 (" .. dCost .. " Plasma)"
	craft5Btn.Text = "CREA x5 (" .. (dCost * 5) .. " Plasma)"

	-- Aggiorna lista Droni & Forgia
	for id, entry in pairs(droneRows) do
		local d = entry.Cfg
		local baseOwned = (state.DroneCounts and state.DroneCounts[id]) or 0
		local ovOwned = (state.DroneCounts and state.DroneCounts[id .. "_ov"]) or 0
		entry.Info.Text = string.format("%s [%s] | Base: %d | Sovraccarichi (x2.5): %d", d.Name, d.Chance, baseOwned, ovOwned)
		entry.Fuse.BackgroundColor3 = baseOwned >= 3 and Color3.fromRGB(235, 140, 20) or Color3.fromRGB(55, 60, 75)
	end

	-- Aggiorna Sfide & AFK
	local activeCh = state.ActiveChallenge
	abandonBtn.Visible = activeCh ~= nil
	for id, entry in pairs(chButtons) do
		local c = entry.Cfg
		local done = state.CompletedChallenges and state.CompletedChallenges[id]
		if activeCh and activeCh.Id == id then
			entry.Btn.BackgroundColor3 = Color3.fromRGB(210, 110, 20)
			entry.Btn.Text = string.format("🔥 IN CORSO: %s (%s/%s W - %ds)", c.Name, GameConfig.Format(state.Watt), GameConfig.Format(c.GoalWatt), activeCh.TimeLeft)
		elseif done then
			entry.Btn.BackgroundColor3 = Color3.fromRGB(20, 115, 70)
			entry.Btn.Text = "✅ " .. c.Name .. " — " .. c.RewardText
		else
			entry.Btn.BackgroundColor3 = Color3.fromRGB(32, 26, 48)
			entry.Btn.Text = c.Name .. ": " .. c.Desc
		end
	end

	for id, entry in pairs(afkButtons) do
		local a = entry.Cfg
		local lvl = (state.AfkUpgrades and state.AfkUpgrades[id]) or 0
		local cost = math.floor(a.BaseCost * (a.CostMult ^ lvl))
		if lvl >= a.MaxLevel then
			entry.Btn.BackgroundColor3 = Color3.fromRGB(20, 115, 70)
			entry.Btn.Text = a.Name .. " [MAX]
" .. a.Desc
		else
			entry.Btn.BackgroundColor3 = (state.TimeFragments >= cost) and Color3.fromRGB(0, 145, 140) or Color3.fromRGB(25, 45, 52)
			entry.Btn.Text = string.format("%s (%d/%d)
Costo: %d Frammenti", a.Name, lvl, a.MaxLevel, cost)
		end
	end

	-- Aggiorna Obiettivi
	for id, entry in pairs(achRows) do
		local ach = entry.Cfg
		local done = state.Achievements and state.Achievements[id]
		entry.Label.BackgroundColor3 = done and Color3.fromRGB(20, 115, 70) or Color3.fromRGB(24, 30, 48)
		entry.Label.Text = string.format("%s %s — %s [%s]", done and "✅" or "⬜", ach.Name, ach.Desc, ach.BonusText)
	end

	-- Banner Eventi
	local banners = {}
	if activeCh then
		table.insert(banners, string.format("🔥 SFIDA: %s (%s/%s W | %ds)", activeCh.Name, GameConfig.Format(state.Watt), GameConfig.Format(activeCh.GoalWatt), activeCh.TimeLeft))
	end
	if (state.ServerBoostLeft or 0) > 0 then
		table.insert(banners, "🌟 SERVER BOOST x2 (" .. GameConfig.FormatTime(state.ServerBoostLeft) .. ")")
	end
	if (state.CoreOverloadLeft or 0) > 0 then
		table.insert(banners, "⚡ SOVRACCARICO x5 (" .. state.CoreOverloadLeft .. "s)")
	end
	if (state.CritOrbActive) then
		table.insert(banners, "💥 PUNTO CRITICO SUL NUCLEO!")
	end
	eventBanner.Visible = #banners > 0
	eventBanner.Text = table.concat(banners, " | ")

	-- Aggiorna 12 Pulsanti a Terra
	local chCostMult = activeCh and activeCh.CostMult or 1
	for _, btnCfg in ipairs(GameConfig.Buttons) do
		local pad = floorButtons:FindFirstChild(btnCfg.Id)
		if pad and pad:FindFirstChild("InfoGui") then
			local lvl = (state.Buttons and state.Buttons[btnCfg.Id]) or 0
			local cost = math.max(1, math.floor(btnCfg.BaseCost * (btnCfg.CostMult ^ lvl) * chCostMult * (1 - (state.CostDiscount or 0))))
			pad.InfoGui.Frame.SubLabel.Text = "Lv. " .. lvl .. " | " .. GameConfig.Format(cost) .. " W"
		end
	end

	-- Aggiorna 18 Nodi Muro Principale
	for id, entry in pairs(nodeButtons) do
		local u = entry.Cfg
		local lvl = (state.Upgrades and state.Upgrades[id]) or 0
		local unlocked = (not u.Prereq) or (((state.Upgrades and state.Upgrades[u.Prereq]) or 0) > 0)
		local cost = math.floor(u.Cost * (u.CostMult ^ lvl))
		local unit = u.Currency == "Watt" and "W" or "Plasma"

		if lvl >= u.MaxLevel then
			entry.Button.BackgroundColor3 = Color3.fromRGB(20, 125, 78)
			entry.Button.Text = string.format("%s [MAX]
%s", u.Name, u.Desc)
		elseif not unlocked then
			entry.Button.BackgroundColor3 = Color3.fromRGB(34, 36, 46)
			entry.Button.Text = "🔒 BLOCCATO
" .. u.Name
		else
			local canAfford = (u.Currency == "Watt" and state.Watt >= cost) or (u.Currency == "Plasma" and state.Plasma >= cost)
			entry.Button.BackgroundColor3 = canAfford and Color3.fromRGB(0, 135, 215) or Color3.fromRGB(44, 50, 74)
			entry.Button.Text = string.format("%s (%d/%d)
%s
%s %s", u.Name, lvl, u.MaxLevel, u.Desc, GameConfig.Format(cost), unit)
		end
	end

	-- Aggiorna Santuario Materia Oscura & Prestige
	if state.Watt >= GameConfig.PrestigeCost then
		local gain = math.max(1, math.floor(math.log10(state.Watt / 1e11)))
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(225, 40, 110)
		prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (+" .. gain .. " Materia Oscura)"
	else
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(90, 25, 50)
		prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (Richiede 1.00T W)"
	end

	for id, entry in pairs(dmButtons) do
		local du = entry.Cfg
		local lvl = (state.DarkUpgrades and state.DarkUpgrades[id]) or 0
		local cost = math.floor(du.Cost * (du.CostMult ^ lvl))
		if lvl >= du.MaxLevel then
			entry.Button.BackgroundColor3 = Color3.fromRGB(25, 120, 75)
			entry.Button.Text = string.format("%s [MAX]
%s", du.Name, du.Desc)
		else
			local ok = (state.DarkMatter or 0) >= cost
			entry.Button.BackgroundColor3 = ok and Color3.fromRGB(190, 35, 105) or Color3.fromRGB(46, 26, 64)
			entry.Button.Text = string.format("%s (%d/%d)
%s
Costo: %d M. Oscura", du.Name, lvl, du.MaxLevel, du.Desc, cost)
		end
	end

	if state.SoundCue then playSound(state.SoundCue) end
	if state.PopupText then showPopup(state.PopupText) end
	if state.AchievementUnlocked then showPopup("🏆 OBIETTIVO: " .. state.AchievementUnlocked, Color3.fromRGB(110, 255, 160)) end
	if state.OfflineGain then showPopup("💤 Guadagno offline: +" .. GameConfig.Format(state.OfflineGain) .. " W", Color3.fromRGB(130, 230, 255)) end
end)

---------------------------------------------------------------------
-- 4. ANIMAZIONI 3D, DRONI SOVRACCARICHI, GRADI SOPRA TESTA E SCIE NEON
---------------------------------------------------------------------
local visualFolder = Instance.new("Folder")
visualFolder.Name = "PlayerVisuals"
visualFolder.Parent = workspace

local droneColors = {}
for _, d in ipairs(GameConfig.Drones) do droneColors[d.Id] = d.Color end

local angle = 0
RunService.RenderStepped:Connect(function(dt)
	local stage = GameConfig.CoreStages[1]
	for _, s in ipairs(GameConfig.CoreStages) do
		if State.TotalWatt >= s.MinWatt then stage = s end
	end

	angle += dt * stage.Spin
	State.PulseScale = math.max(0, State.PulseScale - dt * 3.5)

	local breath = 1 + math.sin(angle * 3) * 0.05 + State.PulseScale * 0.22
	corePart.Size = Vector3.new(stage.Size, stage.Size, stage.Size) * breath
	corePart.Color = State.IsOverload and Color3.fromRGB(255, 45, 45) or stage.Color

	ring1.Size = Vector3.new(stage.Size * 1.75, 0.35, stage.Size * 1.75)
	ring2.Size = Vector3.new(stage.Size * 2.15, 0.3, stage.Size * 2.15)
	ring1.CFrame = CFrame.new(corePart.Position) * CFrame.Angles(angle, angle * 0.7, 0)
	ring2.CFrame = CFrame.new(corePart.Position) * CFrame.Angles(-angle * 0.6, 0, angle * 1.1)

	-- Orbita Punto Critico
	local critR = stage.Size * 0.95 + 2.5
	critOrb.Position = corePart.Position + Vector3.new(math.cos(angle * 2.4) * critR, math.sin(angle * 3.1) * 2.2, math.sin(angle * 2.4) * critR)
	droneHolo.CFrame = CFrame.new(76, 7.2 + math.sin(angle * 2) * 0.5, 44) * CFrame.Angles(angle * 0.9, angle * 1.3, 0)

	-- Effetti sui Giocatori (Droni, Gradi e Scie Luminose)
	for _, plr in ipairs(Players:GetPlayers()) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local pFolder = visualFolder:FindFirstChild(plr.Name)

		if hrp and head then
			if not pFolder then
				pFolder = Instance.new("Folder")
				pFolder.Name = plr.Name
				pFolder.Parent = visualFolder
			end

			local rankName = plr:GetAttribute("RankName") or "Apprendista"
			local rankColor = plr:GetAttribute("RankColor") or Color3.fromRGB(0, 225, 255)
			local wpsText = plr:GetAttribute("WattPerSec") or "0"

			-- Targhetta Grado sopra la testa
			local tag = head:FindFirstChild("RankBillboard")
			if not tag then
				tag = Instance.new("BillboardGui")
				tag.Name = "RankBillboard"
				tag.Size = UDim2.fromOffset(200, 48)
				tag.StudsOffset = Vector3.new(0, 2.8, 0)
				tag.AlwaysOnTop = false
				tag.Parent = head

				local lbl = Instance.new("TextLabel")
				lbl.Name = "Txt"
				lbl.Size = UDim2.fromScale(1, 1)
				lbl.BackgroundTransparency = 1
				lbl.TextStrokeTransparency = 0.25
				lbl.Font = Enum.Font.GothamBlack
				lbl.TextScaled = true
				lbl.Parent = tag
			end
			tag.Txt.Text = string.format("[%s]
+%s W/s", rankName, wpsText)
			tag.Txt.TextColor3 = rankColor

			-- Scia Neon (Trail) sul personaggio
			local trail = hrp:FindFirstChild("QuantumTrail")
			if not trail then
				local a0 = Instance.new("Attachment", hrp); a0.Position = Vector3.new(0, 1.2, 0)
				local a1 = Instance.new("Attachment", hrp); a1.Position = Vector3.new(0, -2.4, 0)
				trail = Instance.new("Trail")
				trail.Name = "QuantumTrail"
				trail.Attachment0 = a0
				trail.Attachment1 = a1
				trail.Lifetime = 0.55
				trail.LightEmission = 0.8
				trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
				trail.Parent = hrp
			end
			trail.Color = ColorSequence.new(rankColor)

			-- Droni Orbitanti (con aura dorata se Sovraccarico _ov)
			local ok, ids = pcall(function() return HttpService:JSONDecode(plr:GetAttribute("EquippedDrones") or "[]") end)
			ids = (ok and type(ids) == "table") and ids or {}

			for i = 1, 5 do
				local dPart = pFolder:FindFirstChild("Drone_" .. i)
				if ids[i] then
					local isOv = string.sub(ids[i], -3) == "_ov"
					local baseId = isOv and string.sub(ids[i], 1, -4) or ids[i]
					if not dPart then
						dPart = Instance.new("Part")
						dPart.Name = "Drone_" .. i
						dPart.Anchored = true
						dPart.CanCollide = false
						dPart.Material = Enum.Material.Neon
						dPart.Parent = pFolder
					end
					dPart.Size = isOv and Vector3.new(1.5, 1.5, 1.5) or Vector3.new(1.1, 1.1, 1.1)
					dPart.Color = isOv and Color3.fromRGB(255, 215, 40) or (droneColors[baseId] or Color3.fromRGB(0, 225, 255))
					local a = angle * 1.6 + (i * (math.pi * 2 / #ids))
					dPart.CFrame = CFrame.new(hrp.Position + Vector3.new(math.cos(a) * 4.4, 1.4 + math.sin(angle * 3 + i) * 0.45, math.sin(a) * 4.4)) * CFrame.Angles(0, -a, 0)
				elseif dPart then
					dPart:Destroy()
				end
			end
		elseif pFolder then
			pFolder:Destroy()
		end
	end
end)
