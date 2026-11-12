local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local BigNum = require(Modules:WaitForChild("BigNum"))
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSync = Remotes:WaitForChild("StateSync")
local BuyUpgrade = Remotes:WaitForChild("BuyUpgrade")
local BuyDarkUpgrade = Remotes:WaitForChild("BuyDarkUpgrade")
local PrestigeEvent = Remotes:WaitForChild("Prestige")
local CraftDroneEvent = Remotes:WaitForChild("CraftDrone")
local RedeemCode = Remotes:WaitForChild("RedeemCode")
local ClaimDaily = Remotes:WaitForChild("ClaimDaily")

local world = workspace:WaitForChild("QuantumWorld")
local upgradeWall = world:WaitForChild("UpgradeWall")
local prestigeWall = world:WaitForChild("PrestigeWall")
local floorButtons = world:WaitForChild("FloorButtons")
local droneStation = world:WaitForChild("DroneStation")

-- Audio Juice
local sfx = Instance.new("Sound")
sfx.SoundId = "rbxassetid://6895079853"
sfx.Volume = 0.45
sfx.Parent = playerGui

local comboPitch = 1.0
local lastSoundTime = 0
local function playJuiceSound(cue)
	if ClientState.Muted then return end
	local now = os.clock()
	if now - lastSoundTime < 0.6 then
		comboPitch = math.min(1.65, comboPitch + 0.05)
	else
		comboPitch = 1.0
	end
	lastSoundTime = now
	sfx.PlaybackSpeed = cue == "Prestige" and 0.7 or comboPitch
	sfx:Play()
end

-- HUD Principale
local hud = Instance.new("ScreenGui")
hud.Name = "QuantumHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(0.72, 0, 0, 56)
topBar.Position = UDim2.new(0.14, 0, 0, 12)
topBar.BackgroundColor3 = Color3.fromRGB(14, 17, 28)
topBar.BackgroundTransparency = 0.14
topBar.Parent = hud
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", topBar)
stroke.Color = Color3.fromRGB(0, 215, 255)
stroke.Thickness = 2

local function makeStatLabel(xScale, color)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.24, 0, 0.85, 0)
	lbl.Position = UDim2.new(xScale, 0, 0.075, 0)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = color
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.Parent = topBar
	return lbl
end

local wattLbl = makeStatLabel(0.01, Color3.fromRGB(0, 230, 255))
local wpsLbl = makeStatLabel(0.26, Color3.fromRGB(120, 255, 170))
local plasmaLbl = makeStatLabel(0.51, Color3.fromRGB(220, 100, 255))
local dmLbl = makeStatLabel(0.76, Color3.fromRGB(255, 200, 50))

-- Banner Eventi
local eventBanner = Instance.new("TextLabel")
eventBanner.Size = UDim2.new(0.50, 0, 0, 34)
eventBanner.Position = UDim2.new(0.25, 0, 0, 74)
eventBanner.BackgroundColor3 = Color3.fromRGB(28, 14, 44)
eventBanner.BackgroundTransparency = 0.18
eventBanner.TextColor3 = Color3.fromRGB(255, 235, 95)
eventBanner.Font = Enum.Font.GothamBold
eventBanner.TextScaled = true
eventBanner.Visible = false
eventBanner.Parent = hud
Instance.new("UICorner", eventBanner).CornerRadius = UDim.new(0, 8)

-- Popup Fluttuante
local function showPopup(text, color)
	local pop = Instance.new("TextLabel")
	pop.Size = UDim2.fromOffset(420, 38)
	pop.Position = UDim2.new(0.5, -210, 0.62, 0)
	pop.BackgroundTransparency = 1
	pop.Text = text
	pop.TextColor3 = color or Color3.fromRGB(255, 240, 110)
	pop.TextStrokeTransparency = 0.2
	pop.Font = Enum.Font.GothamBlack
	pop.TextScaled = true
	pop.Parent = hud

	local tw = TweenService:Create(pop, TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -210, 0.47, 0),
		TextTransparency = 1,
	})
	tw:Play()
	tw.Completed:Connect(function()
		pop:Destroy()
	end)
end

-- Menu Laterale Sinistro (4 Pulsanti Modali)
local function makeSideBtn(idx, text, bg)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 168, 0, 40)
	b.Position = UDim2.new(0, 14, 0.34, (idx - 1) * 48)
	b.BackgroundColor3 = bg
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.Parent = hud
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

local dronesMenuBtn = makeSideBtn(1, "🛸 DRONI (0/3)", Color3.fromRGB(165, 55, 235))
local achMenuBtn = makeSideBtn(2, "🏆 OBIETTIVI", Color3.fromRGB(220, 155, 20))
local codeMenuBtn = makeSideBtn(3, "🎁 CODICI & GIORNO", Color3.fromRGB(0, 155, 220))
local tpMenuBtn = makeSideBtn(4, "⚡ TELETRASPORTO", Color3.fromRGB(45, 65, 95))

-- Helper per creare finestre modali pulite
local modals = {}
local function createModal(titleText, w, h)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(w, h)
	frame.Position = UDim2.new(0.5, -w / 2, 0.5, -h / 2)
	frame.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	frame.Visible = false
	frame.ZIndex = 10
	frame.Parent = hud
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
	local st = Instance.new("UIStroke", frame)
	st.Color = Color3.fromRGB(0, 200, 255)
	st.Thickness = 2

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -50, 0, 42)
	header.Position = UDim2.fromOffset(14, 6)
	header.BackgroundTransparency = 1
	header.Text = titleText
	header.TextColor3 = Color3.fromRGB(255, 255, 255)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Font = Enum.Font.GothamBlack
	header.TextScaled = true
	header.ZIndex = 11
	header.Parent = frame

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(34, 34)
	close.Position = UDim2.new(1, -42, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(200, 55, 70)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.Font = Enum.Font.GothamBlack
	close.ZIndex = 11
	close.Parent = frame
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	table.insert(modals, frame)
	return frame
end

local function toggleModal(target)
	local nextState = not target.Visible
	for _, m in ipairs(modals) do
		m.Visible = false
	end
	target.Visible = nextState
end

-- MODALE 1: Inventario & Fabbrica Droni
local droneModal = createModal("🛸 FLOTTA DRONI & PROBABILITÀ", 440, 390)
local droneRows = {}
for i, d in ipairs(GameConfig.Drones) do
	local row = Instance.new("TextLabel")
	row.Size = UDim2.new(1, -28, 0, 34)
	row.Position = UDim2.fromOffset(14, 52 + (i - 1) * 38)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
	row.TextColor3 = d.Color
	row.Font = Enum.Font.GothamBold
	row.TextScaled = true
	row.ZIndex = 11
	row.Parent = droneModal
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
	droneRows[d.Id] = { Label = row, Cfg = d }
end

local craft1Btn = Instance.new("TextButton")
craft1Btn.Size = UDim2.new(0.45, 0, 0, 42)
craft1Btn.Position = UDim2.new(0.04, 0, 1, -54)
craft1Btn.BackgroundColor3 = Color3.fromRGB(165, 55, 235)
craft1Btn.Text = "CREA x1 (50 Plasma)"
craft1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
craft1Btn.Font = Enum.Font.GothamBlack
craft1Btn.TextScaled = true
craft1Btn.ZIndex = 11
craft1Btn.Parent = droneModal
Instance.new("UICorner", craft1Btn).CornerRadius = UDim.new(0, 8)
craft1Btn.MouseButton1Click:Connect(function()
	CraftDroneEvent:FireServer(1)
end)

local craft5Btn = Instance.new("TextButton")
craft5Btn.Size = UDim2.new(0.45, 0, 0, 42)
craft5Btn.Position = UDim2.new(0.51, 0, 1, -54)
craft5Btn.BackgroundColor3 = Color3.fromRGB(220, 65, 160)
craft5Btn.Text = "CREA x5 (250 Plasma)"
craft5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
craft5Btn.Font = Enum.Font.GothamBlack
craft5Btn.TextScaled = true
craft5Btn.ZIndex = 11
craft5Btn.Parent = droneModal
Instance.new("UICorner", craft5Btn).CornerRadius = UDim.new(0, 8)
craft5Btn.MouseButton1Click:Connect(function()
	CraftDroneEvent:FireServer(5)
end)

dronesMenuBtn.MouseButton1Click:Connect(function() toggleModal(droneModal) end)

-- MODALE 2: Obiettivi (Achievements)
local achModal = createModal("🏆 OBIETTIVI PERMANENTI", 460, 430)
local achScroll = Instance.new("ScrollingFrame")
achScroll.Size = UDim2.new(1, -24, 1, -60)
achScroll.Position = UDim2.fromOffset(12, 52)
achScroll.CanvasSize = UDim2.fromOffset(0, #GameConfig.Achievements * 46)
achScroll.BackgroundTransparency = 1
achScroll.ScrollBarThickness = 6
achScroll.ZIndex = 11
achScroll.Parent = achModal

local achRows = {}
for i, ach in ipairs(GameConfig.Achievements) do
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 0, 40)
	lbl.Position = UDim2.fromOffset(4, (i - 1) * 44)
	lbl.BackgroundColor3 = Color3.fromRGB(26, 32, 50)
	lbl.TextColor3 = Color3.fromRGB(220, 225, 240)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.ZIndex = 12
	lbl.Parent = achScroll
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
	achRows[ach.Id] = { Label = lbl, Cfg = ach }
end

achMenuBtn.MouseButton1Click:Connect(function() toggleModal(achModal) end)

-- MODALE 3: Codici Promo & Premio Giornaliero
local codeModal = createModal("🎁 CODICI & RICOMPENSE", 360, 240)
local codeBox = Instance.new("TextBox")
codeBox.Size = UDim2.new(0.88, 0, 0, 40)
codeBox.Position = UDim2.new(0.06, 0, 0.24, 0)
codeBox.PlaceholderText = "Inserisci codice (es. QUANTUM100)"
codeBox.Text = ""
codeBox.BackgroundColor3 = Color3.fromRGB(28, 34, 54)
codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
codeBox.Font = Enum.Font.GothamBold
codeBox.TextScaled = true
codeBox.ZIndex = 11
codeBox.Parent = codeModal
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

local codeStatus = Instance.new("TextLabel")
codeStatus.Size = UDim2.new(0.88, 0, 0, 26)
codeStatus.Position = UDim2.new(0.06, 0, 0.44, 0)
codeStatus.BackgroundTransparency = 1
codeStatus.Text = "Prova: QUANTUM100, NEON2026, DRONEFREE"
codeStatus.TextColor3 = Color3.fromRGB(160, 220, 255)
codeStatus.Font = Enum.Font.Gotham
codeStatus.TextScaled = true
codeStatus.ZIndex = 11
codeStatus.Parent = codeModal

local redeemBtn = Instance.new("TextButton")
redeemBtn.Size = UDim2.new(0.88, 0, 0, 38)
redeemBtn.Position = UDim2.new(0.06, 0, 0.58, 0)
redeemBtn.BackgroundColor3 = Color3.fromRGB(0, 195, 115)
redeemBtn.Text = "RISCATTA CODICE"
redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
redeemBtn.Font = Enum.Font.GothamBlack
redeemBtn.TextScaled = true
redeemBtn.ZIndex = 11
redeemBtn.Parent = codeModal
Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 8)
redeemBtn.MouseButton1Click:Connect(function()
	local _, msg = RedeemCode:InvokeServer(codeBox.Text)
	codeStatus.Text = msg or ""
end)

local dailyBtn = Instance.new("TextButton")
dailyBtn.Size = UDim2.new(0.88, 0, 0, 40)
dailyBtn.Position = UDim2.new(0.06, 0, 0.78, 0)
dailyBtn.BackgroundColor3 = Color3.fromRGB(175, 60, 235)
dailyBtn.Text = "📅 RITIRA PREMIO GIORNALIERO (24H)"
dailyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dailyBtn.Font = Enum.Font.GothamBlack
dailyBtn.TextScaled = true
dailyBtn.ZIndex = 11
dailyBtn.Parent = codeModal
Instance.new("UICorner", dailyBtn).CornerRadius = UDim.new(0, 8)
dailyBtn.MouseButton1Click:Connect(function()
	local _, msg = ClaimDaily:InvokeServer()
	codeStatus.Text = msg or ""
	showPopup(msg or "")
end)

codeMenuBtn.MouseButton1Click:Connect(function() toggleModal(codeModal) end)

-- MODALE 4: Teletrasporto & Impostazioni
local tpModal = createModal("⚡ TELETRASPORTO & OPZIONI", 340, 270)
local tpTargets = {
	{ Name = "🔵 Nucleo Centrale", Pos = Vector3.new(0, 5, 34) },
	{ Name = "🟢 Albero Potenziamenti", Pos = Vector3.new(0, 5, -34) },
	{ Name = "🟣 Fabbrica Droni", Pos = Vector3.new(38, 5, 22) },
	{ Name = "🔴 Santuario Materia Oscura", Pos = Vector3.new(40, 5, -14) },
}
for i, t in ipairs(tpTargets) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.88, 0, 0, 34)
	b.Position = UDim2.new(0.06, 0, 0.20 + (i - 1) * 0.145, 0)
	b.BackgroundColor3 = Color3.fromRGB(30, 42, 68)
	b.Text = t.Name
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextScaled = true
	b.ZIndex = 11
	b.Parent = tpModal
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	b.MouseButton1Click:Connect(function()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(t.Pos)
			tpModal.Visible = false
		end
	end)
end

local muteBtn = Instance.new("TextButton")
muteBtn.Size = UDim2.new(0.88, 0, 0, 34)
muteBtn.Position = UDim2.new(0.06, 0, 0.81, 0)
muteBtn.BackgroundColor3 = Color3.fromRGB(60, 70, 95)
muteBtn.Text = "🔊 Audio: ATTIVO"
muteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextScaled = true
muteBtn.ZIndex = 11
muteBtn.Parent = tpModal
Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 8)
muteBtn.MouseButton1Click:Connect(function()
	ClientState.Muted = not ClientState.Muted
	muteBtn.Text = ClientState.Muted and "🔇 Audio: DISATTIVATO" or "🔊 Audio: ATTIVO"
end)

tpMenuBtn.MouseButton1Click:Connect(function() toggleModal(tpModal) end)

-- SURFACE GUI 1: Albero Potenziamenti sul Muro Principale
local wallGui = Instance.new("SurfaceGui")
wallGui.Name = "WallTreeGui"
wallGui.Adornee = upgradeWall
wallGui.Face = Enum.NormalId.Front
wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
wallGui.PixelsPerStud = 25
wallGui.Parent = playerGui

local canvasW, canvasH = 92 * 25, 46 * 25
local nodeMap = {}
for _, u in ipairs(GameConfig.Upgrades) do
	nodeMap[u.Id] = u
end

for _, u in ipairs(GameConfig.Upgrades) do
	if u.Prereq and nodeMap[u.Prereq] then
		local p = nodeMap[u.Prereq]
		local x1, y1 = p.GridX * canvasW, p.GridY * canvasH
		local x2, y2 = u.GridX * canvasW, u.GridY * canvasH
		local dx, dy = x2 - x1, y2 - y1
		local dist = math.sqrt(dx * dx + dy * dy)

		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.fromOffset((x1 + x2) / 2, (y1 + y2) / 2)
		line.Size = UDim2.fromOffset(dist, 8)
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
	btn.Name = u.Id
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.fromScale(u.GridX, u.GridY)
	btn.Size = UDim2.fromOffset(235, 100)
	btn.BackgroundColor3 = Color3.fromRGB(24, 30, 48)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.ZIndex = 3
	btn.Parent = wallGui
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

	btn.MouseButton1Click:Connect(function()
		BuyUpgrade:FireServer(u.Id)
	end)
	nodeButtons[u.Id] = { Button = btn, Cfg = u }
end

local prestigeBtn = Instance.new("TextButton")
prestigeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
prestigeBtn.Position = UDim2.fromScale(0.5, 0.93)
prestigeBtn.Size = UDim2.fromOffset(620, 78)
prestigeBtn.BackgroundColor3 = Color3.fromRGB(130, 20, 60)
prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (Richiede 1.00T W)"
prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
prestigeBtn.Font = Enum.Font.GothamBlack
prestigeBtn.TextScaled = true
prestigeBtn.ZIndex = 3
prestigeBtn.Parent = wallGui
Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 14)
prestigeBtn.MouseButton1Click:Connect(function()
	PrestigeEvent:FireServer()
end)

-- SURFACE GUI 2: Santuario Materia Oscura (Muro Prestige a destra)
local dmGui = Instance.new("SurfaceGui")
dmGui.Name = "DarkMatterGui"
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
	b.MouseButton1Click:Connect(function()
		BuyDarkUpgrade:FireServer(du.Id)
	end)
	dmButtons[du.Id] = { Button = b, Cfg = du }
end

-- Aggiornamento UI da Server
StateSync.OnClientEvent:Connect(function(state)
	ClientState.TotalWatt = state.TotalWatt or 0
	ClientState.IsOverload = (state.CoreOverloadLeft or 0) > 0
	ClientState.IsGolden = (state.GoldenSurgeLeft or 0) > 0
	if state.CorePulse then
		ClientState.PulseScale = 1.0
	end

	wattLbl.Text = "⚡ " .. BigNum.Format(state.Watt) .. " W"
	wpsLbl.Text = "+" .. BigNum.Format(state.WattPerSec) .. " W/s"
	plasmaLbl.Text = "🔮 " .. BigNum.Format(state.Plasma) .. " (+" .. BigNum.Format(state.PlasmaPerSec) .. "/s)"
	dmLbl.Text = "🌌 " .. tostring(state.DarkMatter) .. " Mat. Oscura"

	dronesMenuBtn.Text = string.format("🛸 DRONI (%d/%d)", state.EquippedCount or 0, state.MaxDroneSlots or 3)
	local dCost = state.DroneCost or 50
	craft1Btn.Text = "CREA x1 (" .. dCost .. " Plasma)"
	craft5Btn.Text = "CREA x5 (" .. (dCost * 5) .. " Plasma)"

	local stLbl = droneStation:FindFirstChildOfClass("BillboardGui") and droneStation:FindFirstChildOfClass("BillboardGui"):FindFirstChild("StationLabel")
	if stLbl then
		stLbl.Text = "🛸 FABBRICA DRONI
Clicca per creare (" .. dCost .. " Plasma)"
	end

	-- Aggiorna righe Droni nel modale
	for id, entry in pairs(droneRows) do
		local d = entry.Cfg
		local owned = (state.DroneCounts and state.DroneCounts[id]) or 0
		entry.Label.Text = string.format("%s [%s] | x%.1f W, x%.1f P | Posseduti: %d", d.Name, d.Chance, d.WattMult, d.PlasmaMult, owned)
	end

	-- Aggiorna Obiettivi
	for id, entry in pairs(achRows) do
		local ach = entry.Cfg
		local done = state.Achievements and state.Achievements[id]
		local cur = (state.StatProgress and state.StatProgress[ach.Stat]) or 0
		if done then
			entry.Label.BackgroundColor3 = Color3.fromRGB(20, 115, 70)
			entry.Label.Text = string.format("✅ %s — %s [%s]", ach.Name, ach.Desc, ach.BonusText)
		else
			entry.Label.BackgroundColor3 = Color3.fromRGB(26, 32, 50)
			entry.Label.Text = string.format("⬜ %s (%s/%s) — %s", ach.Name, BigNum.Format(cur), BigNum.Format(ach.Target), ach.BonusText)
		end
	end

	-- Banner eventi
	local banners = {}
	if (state.CoreOverloadLeft or 0) > 0 then
		table.insert(banners, "🔥 SOVRACCARICO NUCLEO x5 (" .. state.CoreOverloadLeft .. "s)")
	end
	if (state.GoldenSurgeLeft or 0) > 0 then
		table.insert(banners, "🌟 ONDATA AUREA x3 (" .. state.GoldenSurgeLeft .. "s)")
	end
	if (state.CrystalRainLeft or 0) > 0 then
		table.insert(banners, "💎 PIOGGIA DI CRISTALLI (" .. state.CrystalRainLeft .. "s)")
	end
	if (state.OrbBoostLeft or 0) > 0 then
		table.insert(banners, "⚡ BOOST SFERA x2 (" .. state.OrbBoostLeft .. "s)")
	end
	eventBanner.Visible = #banners > 0
	eventBanner.Text = table.concat(banners, "  |  ")

	-- Aggiorna i 9 Pulsanti a Terra
	for _, btnCfg in ipairs(GameConfig.Buttons) do
		local pad = floorButtons:FindFirstChild(btnCfg.Id)
		if pad and pad:FindFirstChild("InfoGui") then
			local lvl = (state.Buttons and state.Buttons[btnCfg.Id]) or 0
			local cost = math.max(1, math.floor(btnCfg.BaseCost * (btnCfg.CostMult ^ lvl) * (1 - (state.CostDiscount or 0))))
			local bg = pad.InfoGui.Frame
			bg.LevelLabel.Text = "Livello: " .. lvl
			bg.CostLabel.Text = "Costo: " .. BigNum.Format(cost) .. " W"
		end
	end

	-- Aggiorna i 17 Nodi sul Muro Principale
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
Costo: %s %s", u.Name, lvl, u.MaxLevel, u.Desc, BigNum.Format(cost), unit)
		end
	end

	-- Aggiorna Pulsante Prestige
	if state.Watt >= GameConfig.PrestigeCost then
		local gain = math.max(1, math.floor(math.log10(state.Watt / 1e11)))
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(225, 40, 110)
		prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (+ " .. gain .. " Materia Oscura)"
	else
		prestigeBtn.BackgroundColor3 = Color3.fromRGB(90, 25, 50)
		prestigeBtn.Text = "🌌 COLLASSO QUANTISTICO (Richiede " .. BigNum.Format(GameConfig.PrestigeCost) .. " W)"
	end

	-- Aggiorna Santuario Materia Oscura
	for id, entry in pairs(dmButtons) do
		local du = entry.Cfg
		local lvl = (state.DarkUpgrades and state.DarkUpgrades[id]) or 0
		local cost = math.floor(du.Cost * (du.CostMult ^ lvl))
		if lvl >= du.MaxLevel then
			entry.Button.BackgroundColor3 = Color3.fromRGB(25, 120, 75)
			entry.Button.Text = string.format("%s [MAX]
%s", du.Name, du.Desc)
		else
			local canAfford = (state.DarkMatter or 0) >= cost
			entry.Button.BackgroundColor3 = canAfford and Color3.fromRGB(190, 35, 105) or Color3.fromRGB(46, 26, 64)
			entry.Button.Text = string.format("%s (%d/%d)
%s
Costo: %d Mat. Oscura", du.Name, lvl, du.MaxLevel, du.Desc, cost)
		end
	end

	if state.SoundCue then
		playJuiceSound(state.SoundCue)
	end
	if state.PopupText then
		showPopup(state.PopupText)
	end
	if state.AchievementUnlocked then
		showPopup("🏆 OBIETTIVO SBLOCCATO: " .. state.AchievementUnlocked, Color3.fromRGB(110, 255, 160))
	end
	if state.OfflineGain then
		showPopup("💤 Bentornato! Guadagno offline: +" .. BigNum.Format(state.OfflineGain) .. " W", Color3.fromRGB(130, 230, 255))
	end
end)
