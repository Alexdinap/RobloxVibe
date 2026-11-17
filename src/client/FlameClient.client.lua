local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local ClientWorldVisuals = require(script.Parent:WaitForChild("ClientWorldVisuals"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {
	StateSync = remotesFolder:WaitForChild("StateSync"),
	ClickFlame = remotesFolder:WaitForChild("ClickFlame"),
	BuyUpgrade = remotesFolder:WaitForChild("BuyUpgrade"),
	BuyStarPerk = remotesFolder:WaitForChild("BuyStarPerk"),
	SummonWisp = remotesFolder:WaitForChild("SummonWisp"),
	FuseWisp = remotesFolder:WaitForChild("FuseWisp"),
	Prestige = remotesFolder:WaitForChild("Prestige"),
	SyncGamePass = remotesFolder:WaitForChild("SyncGamePass"),
	TeleportHome = remotesFolder:WaitForChild("TeleportHome"),
	RedeemCode = remotesFolder:WaitForChild("RedeemCode"),
	Regno1Sync = remotesFolder:WaitForChild("Regno1Sync"),
}

ClientWorldVisuals.StartWispRenderer()

-- =========================================================================
-- INTERFACCIA HUD PRINCIPALE (Scritte compatte)
-- =========================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "LastFlameHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local topHud = Instance.new("Frame", gui)
topHud.Name = "TopStatsBar"
topHud.AnchorPoint = Vector2.new(0.5, 0)
topHud.Position = UDim2.new(0.5, 0, 0, 12)
topHud.Size = UDim2.fromOffset(580, 56)
topHud.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
topHud.BackgroundTransparency = 0.08
topHud.ZIndex = 10
Instance.new("UICorner", topHud).CornerRadius = UDim.new(0, 14)

local topStroke = Instance.new("UIStroke", topHud)
topStroke.Color = Color3.fromRGB(255, 195, 65)
topStroke.Thickness = 1.6

local pointsLbl = Instance.new("TextLabel", topHud)
pointsLbl.Position = UDim2.fromOffset(14, 6)
pointsLbl.Size = UDim2.fromOffset(260, 24)
pointsLbl.BackgroundTransparency = 1
pointsLbl.Text = "🔥 0 Punti Luce"
pointsLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
pointsLbl.TextXAlignment = Enum.TextXAlignment.Left
pointsLbl.Font = Enum.Font.GothamBlack
pointsLbl.TextSize = 16
pointsLbl.ZIndex = 11

local rateLbl = Instance.new("TextLabel", topHud)
rateLbl.Position = UDim2.fromOffset(14, 32)
rateLbl.Size = UDim2.fromOffset(280, 18)
rateLbl.BackgroundTransparency = 1
rateLbl.Text = "+1.0 / click  •  +0 / sec"
rateLbl.TextColor3 = Color3.fromRGB(175, 190, 215)
rateLbl.TextXAlignment = Enum.TextXAlignment.Left
rateLbl.Font = Enum.Font.GothamBold
rateLbl.TextSize = 12
rateLbl.ZIndex = 11

local zoneBadge = Instance.new("TextLabel", topHud)
zoneBadge.AnchorPoint = Vector2.new(1, 0)
zoneBadge.Position = UDim2.new(1, -14, 0, 7)
zoneBadge.Size = UDim2.fromOffset(280, 20)
zoneBadge.BackgroundTransparency = 1
zoneBadge.Text = "ZONA 1 • Portatore di Scintilla (4%)"
zoneBadge.TextColor3 = Color3.fromRGB(90, 225, 255)
zoneBadge.TextXAlignment = Enum.TextXAlignment.Right
zoneBadge.Font = Enum.Font.GothamBold
zoneBadge.TextSize = 12
zoneBadge.ZIndex = 11

local heatAndStarsLbl = Instance.new("TextLabel", topHud)
heatAndStarsLbl.AnchorPoint = Vector2.new(1, 0)
heatAndStarsLbl.Position = UDim2.new(1, -14, 0, 31)
heatAndStarsLbl.Size = UDim2.fromOffset(290, 18)
heatAndStarsLbl.BackgroundTransparency = 1
heatAndStarsLbl.Text = "Calore x1.00  •  ⭐ 0  •  Potenz. 0/20"
heatAndStarsLbl.TextColor3 = Color3.fromRGB(255, 175, 95)
heatAndStarsLbl.TextXAlignment = Enum.TextXAlignment.Right
heatAndStarsLbl.Font = Enum.Font.Gotham
heatAndStarsLbl.TextSize = 11
heatAndStarsLbl.ZIndex = 11

-- Banner sfide Regno 1
local trialBanner = Instance.new("TextLabel", gui)
trialBanner.Name = "Regno1Banner"
trialBanner.AnchorPoint = Vector2.new(0.5, 0)
trialBanner.Position = UDim2.new(0.5, 0, 0, 76)
trialBanner.Size = UDim2.fromOffset(380, 26)
trialBanner.BackgroundColor3 = Color3.fromRGB(38, 24, 14)
trialBanner.Text = ""
trialBanner.TextColor3 = Color3.fromRGB(255, 225, 95)
trialBanner.Font = Enum.Font.GothamBold
trialBanner.TextSize = 12
trialBanner.Visible = false
trialBanner.ZIndex = 12
Instance.new("UICorner", trialBanner).CornerRadius = UDim.new(0, 10)

-- Notifica Toast
local toastLbl = Instance.new("TextLabel", gui)
toastLbl.Name = "PopupToast"
toastLbl.AnchorPoint = Vector2.new(0.5, 0)
toastLbl.Position = UDim2.new(0.5, 0, 0, 108)
toastLbl.Size = UDim2.fromOffset(440, 28)
toastLbl.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
toastLbl.Text = ""
toastLbl.TextColor3 = Color3.fromRGB(255, 235, 130)
toastLbl.Font = Enum.Font.GothamBold
toastLbl.TextSize = 12
toastLbl.Visible = false
toastLbl.ZIndex = 30
Instance.new("UICorner", toastLbl).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", toastLbl).Color = Color3.fromRGB(255, 200, 75)

local toastToken = 0
local function showToast(msg)
	if not msg or msg == "" then return end
	toastToken += 1
	local myToken = toastToken
	toastLbl.Text = msg
	toastLbl.Visible = true
	task.delay(3.0, function()
		if toastToken == myToken then
			toastLbl.Visible = false
		end
	end)
end

-- Effetti sonori
local soundFolder = Instance.new("Folder", gui)
soundFolder.Name = "ClientSounds"

local function playCue(cueName)
	local s = Instance.new("Sound", soundFolder)
	if cueName == "Crit" then
		s.SoundId = "rbxassetid://131072992"
		s.PlaybackSpeed = 1.35
		s.Volume = 0.45
	elseif cueName == "Buy" or cueName == "Upgrade" then
		s.SoundId = "rbxassetid://4612375233"
		s.PlaybackSpeed = 1.1
		s.Volume = 0.4
	elseif cueName == "Prestige" then
		s.SoundId = "rbxassetid://1843527678"
		s.PlaybackSpeed = 1.0
		s.Volume = 0.5
	else
		s.SoundId = "rbxassetid://421058925"
		s.PlaybackSpeed = 0.95 + math.random() * 0.25
		s.Volume = 0.3
	end
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

-- Testo fluttuante compatto sopra il Braciere
local function spawnFloatingGain(amount, isCrit)
	local core = ClientWorldVisuals.GetMyFlameCore()
	if not core then return end

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = core.Position + Vector3.new((math.random() - 0.5) * 6, 3.5, (math.random() - 0.5) * 6)
	p.Parent = Workspace

	local bbg = Instance.new("BillboardGui", p)
	bbg.Size = UDim2.fromOffset(130, 26)
	bbg.AlwaysOnTop = true

	local lbl = Instance.new("TextLabel", bbg)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = (isCrit and "CRIT +" or "+") .. NumberFormat.Format(amount)
	lbl.TextColor3 = isCrit and Color3.fromRGB(255, 110, 95) or Color3.fromRGB(255, 225, 95)
	lbl.TextStrokeTransparency = 0.2
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = isCrit and 16 or 13

	local tw = TweenService:Create(p, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = p.Position + Vector3.new(0, 5.0, 0),
	})
	tw:Play()
	tw.Completed:Connect(function()
		p:Destroy()
	end)
end

local lastLocalClick = 0
local function tryClickMyFlame()
	local now = os.clock()
	if now - lastLocalClick < 0.065 then return end
	lastLocalClick = now
	remotes.ClickFlame:FireServer()
end

mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if not target then return end
	local myPlot = ClientWorldVisuals.GetMyPlotModel()
	if myPlot and target:IsDescendantOf(myPlot) then
		if target.Name == "FlameHitbox" or target.Name == "FlameCore" or target.Name == "BrazierBowl" or target.Name == "EmberRing" then
			tryClickMyFlame()
		end
	end
end)

UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.KeyCode == Enum.KeyCode.E or inp.KeyCode == Enum.KeyCode.F then
		local core = ClientWorldVisuals.GetMyFlameCore()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if core and hrp and (core.Position - hrp.Position).Magnitude <= 32 then
			tryClickMyFlame()
		end
	end
end)

local shopController = ShopUI.Build(gui, remotes)

remotes.StateSync.OnClientEvent:Connect(function(st)
	if not st then return end

	pointsLbl.Text = "🔥 " .. NumberFormat.Format(st.Points or 0) .. " Punti Luce"
	rateLbl.Text = string.format("+%s / click  •  +%s / sec", NumberFormat.Format(st.ClickPower or 1), NumberFormat.Format(st.PointsPerSec or 0))
	zoneBadge.Text = string.format("ZONA %d • %s (%d%%)", st.PlotIndex or 1, st.RankName or "Custode", st.LightPercent or 4)

	local buffSuffix = ""
	if (st.Regno1BuffRemaining or 0) > 0 then
		buffSuffix = string.format(" • ⚡x%.2f(%ds)", st.Regno1BuffMult or 1, math.ceil(st.Regno1BuffRemaining))
	end
	heatAndStarsLbl.Text = string.format(
		"Calore x%.2f • ⭐%d • Potenz. %d/%d%s",
		st.HeatMult or 1,
		st.EternalStars or 0,
		st.CompletedUpgradesCount or 0,
		st.TotalUpgradesCount or 20,
		buffSuffix
	)

	ClientWorldVisuals.Update(st)
	shopController.Update(st)

	if st.FlameClicked and st.ClickGained then
		spawnFloatingGain(st.ClickGained, st.IsCrit)
	end
	if st.SoundCue then
		playCue(st.SoundCue)
	end
	if st.Shockwave then
		ClientWorldVisuals.PlayShockwave(st.BrazierColor)
	end
	if st.PopupText then
		showToast(st.PopupText)
	end
	if st.VictoryTriggered then
		shopController.ShowVictory(st)
	end
end)

remotes.Regno1Sync.OnClientEvent:Connect(function(r1)
	if not r1 then return end
	ClientWorldVisuals.UpdateRegno1(r1)

	if r1.Active then
		trialBanner.Visible = true
		trialBanner.Text = string.format("CATENA DEL FUOCO: Braciere %d/%d  •  %.1fs", r1.CurrentStep or 1, r1.TotalSteps or 5, r1.TimeLeft or 0)
	elseif (r1.BuffRemaining or 0) > 0 then
		trialBanner.Visible = true
		trialBanner.Text = string.format("BENEDIZIONE REGNO 1: x%.2f  •  %ds", r1.BuffMult or 1.5, math.ceil(r1.BuffRemaining))
	else
		trialBanner.Visible = false
	end
end)

remotes.SyncGamePass:FireServer()