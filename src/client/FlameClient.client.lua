local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))
local ClientWorldVisuals = require(script.Parent:WaitForChild("ClientWorldVisuals"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local TutorialUI = require(script.Parent:WaitForChild("TutorialUI"))
local ShadowModelBuilder = require(script.Parent:WaitForChild("ShadowModelBuilder"))
ShadowModelBuilder.Start()

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {
	StateSync = remotesFolder:WaitForChild("StateSync"),
	ClickFlame = remotesFolder:WaitForChild("ClickFlame"),
	BuyUpgrade = remotesFolder:WaitForChild("BuyUpgrade"),
	BuyWeapon = remotesFolder:WaitForChild("BuyWeapon"),
	BuyDefense = remotesFolder:WaitForChild("BuyDefense"),
	BuyAlbaPerk = remotesFolder:WaitForChild("BuyAlbaPerk"),
	UnlockAlbaZone = remotesFolder:WaitForChild("UnlockAlbaZone"),
	SummonWisp = remotesFolder:WaitForChild("SummonWisp"),
	FuseWisp = remotesFolder:WaitForChild("FuseWisp"),
	SyncGamePass = remotesFolder:WaitForChild("SyncGamePass"),
	TeleportHome = remotesFolder:WaitForChild("TeleportHome"),
	SetLanguage = remotesFolder:WaitForChild("SetLanguage"),
	CompleteTutorial = remotesFolder:WaitForChild("CompleteTutorial"),
	RedeemCode = remotesFolder:WaitForChild("RedeemCode"),
	Regno1Sync = remotesFolder:WaitForChild("Regno1Sync"),
	DefenseFx = remotesFolder:WaitForChild("DefenseFx"),
}

ClientWorldVisuals.StartWispRenderer()

local currentLang = "en"
local currentClickCooldown = 0.50
local canHoldClickCore = false

local gui = Instance.new("ScreenGui")
gui.Name = "LastFlameHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local topHud = Instance.new("Frame", gui)
topHud.Name = "TopStatsBar"
topHud.AnchorPoint = Vector2.new(0.5, 0)
topHud.Position = UDim2.new(0.5, 0, 0, 10)
topHud.Size = UDim2.new(0.94, 0, 0, 68)
topHud.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
topHud.BackgroundTransparency = 0.08
topHud.ZIndex = 10
Instance.new("UICorner", topHud).CornerRadius = UDim.new(0, 14)

local topConstraint = Instance.new("UISizeConstraint", topHud)
topConstraint.MaxSize = Vector2.new(700, 68)
topConstraint.MinSize = Vector2.new(320, 62)

local topStroke = Instance.new("UIStroke", topHud)
topStroke.Color = Color3.fromRGB(255, 195, 65)
topStroke.Thickness = 1.6

local pointsLbl = Instance.new("TextLabel", topHud)
pointsLbl.Position = UDim2.fromOffset(14, 7)
pointsLbl.Size = UDim2.fromOffset(290, 28)
pointsLbl.BackgroundTransparency = 1
pointsLbl.Text = "🔥 0 Light Points"
pointsLbl.TextColor3 = Color3.fromRGB(255, 220, 90)
pointsLbl.TextXAlignment = Enum.TextXAlignment.Left
pointsLbl.Font = Enum.Font.GothamBlack
pointsLbl.TextSize = 18
pointsLbl.ZIndex = 11

local rateLbl = Instance.new("TextLabel", topHud)
rateLbl.Position = UDim2.fromOffset(14, 38)
rateLbl.Size = UDim2.fromOffset(310, 20)
rateLbl.BackgroundTransparency = 1
rateLbl.Text = "+1 / click (0.50s)  •  +0 / sec"
rateLbl.TextColor3 = Color3.fromRGB(210, 222, 245)
rateLbl.TextXAlignment = Enum.TextXAlignment.Left
rateLbl.Font = Enum.Font.GothamBold
rateLbl.TextSize = 13
rateLbl.ZIndex = 11

local zoneBadge = Instance.new("TextLabel", topHud)
zoneBadge.AnchorPoint = Vector2.new(1, 0)
zoneBadge.Position = UDim2.new(1, -96, 0, 9)
zoneBadge.Size = UDim2.fromOffset(280, 22)
zoneBadge.BackgroundTransparency = 1
zoneBadge.Text = "ZONES 1/5 • Spark Bearer (4%)"
zoneBadge.TextColor3 = Color3.fromRGB(95, 230, 255)
zoneBadge.TextXAlignment = Enum.TextXAlignment.Right
zoneBadge.Font = Enum.Font.GothamBold
zoneBadge.TextSize = 13
zoneBadge.ZIndex = 11

local heatAndAlbaLbl = Instance.new("TextLabel", topHud)
heatAndAlbaLbl.AnchorPoint = Vector2.new(1, 0)
heatAndAlbaLbl.Position = UDim2.new(1, -96, 0, 38)
heatAndAlbaLbl.Size = UDim2.fromOffset(290, 20)
heatAndAlbaLbl.BackgroundTransparency = 1
heatAndAlbaLbl.Text = "Heat x1.00 • 🌅Dawn: 0 • Upg. 0/22"
heatAndAlbaLbl.TextColor3 = Color3.fromRGB(255, 195, 115)
heatAndAlbaLbl.TextXAlignment = Enum.TextXAlignment.Right
heatAndAlbaLbl.Font = Enum.Font.GothamBold
heatAndAlbaLbl.TextSize = 12
heatAndAlbaLbl.ZIndex = 11

local langBtn = Instance.new("TextButton", topHud)
langBtn.Name = "LanguageToggleBtn"
langBtn.AnchorPoint = Vector2.new(1, 0.5)
langBtn.Position = UDim2.new(1, -10, 0.5, 0)
langBtn.Size = UDim2.fromOffset(76, 48)
langBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
langBtn.Text = "🌐 EN"
langBtn.TextColor3 = Color3.fromRGB(255, 220, 95)
langBtn.Font = Enum.Font.GothamBlack
langBtn.TextSize = 15
langBtn.ZIndex = 12
Instance.new("UICorner", langBtn).CornerRadius = UDim.new(0, 10)
local langStroke = Instance.new("UIStroke", langBtn)
langStroke.Color = Color3.fromRGB(90, 225, 255)
langStroke.Thickness = 1.5

langBtn.MouseButton1Click:Connect(function()
	currentLang = (currentLang == "en") and "it" or "en"
	langBtn.Text = (currentLang == "en") and "🌐 EN" or "🌐 IT"
	remotes.SetLanguage:FireServer(currentLang)
end)

local trialBanner = Instance.new("TextLabel", gui)
trialBanner.Name = "Regno1Banner"
trialBanner.AnchorPoint = Vector2.new(0.5, 0)
trialBanner.Position = UDim2.new(0.5, 0, 0, 126)
trialBanner.Size = UDim2.fromOffset(420, 30)
trialBanner.BackgroundColor3 = Color3.fromRGB(38, 24, 14)
trialBanner.Text = ""
trialBanner.TextColor3 = Color3.fromRGB(255, 225, 95)
trialBanner.Font = Enum.Font.GothamBold
trialBanner.TextSize = 13
trialBanner.Visible = false
trialBanner.ZIndex = 12
Instance.new("UICorner", trialBanner).CornerRadius = UDim.new(0, 10)

local toastLbl = Instance.new("TextLabel", gui)
toastLbl.Name = "PopupToast"
toastLbl.AnchorPoint = Vector2.new(0.5, 0)
toastLbl.Position = UDim2.new(0.5, 0, 0, 162)
toastLbl.Size = UDim2.fromOffset(470, 32)
toastLbl.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
toastLbl.Text = ""
toastLbl.TextColor3 = Color3.fromRGB(255, 235, 130)
toastLbl.Font = Enum.Font.GothamBold
toastLbl.TextSize = 13
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

local function spawnFloatingGain(amount, isCrit)
	local plotModel = ClientWorldVisuals.GetMyPlotModel()
	local brazier = plotModel and plotModel:FindFirstChild("Brazier")
	local bowl = brazier and brazier:FindFirstChild("BrazierBowl")
	local core = brazier and brazier:FindFirstChild("FlameCore")
	if not bowl and not core then return end

	local anchorPos = bowl and bowl.Position or Vector3.new(core.Position.X, 2.5, core.Position.Z)

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.Position = anchorPos + Vector3.new((math.random() - 0.5) * 8.0, 1.8, (math.random() - 0.5) * 8.0)
	p.Parent = Workspace

	local bbg = Instance.new("BillboardGui", p)
	bbg.Size = UDim2.fromOffset(260, 56)
	bbg.AlwaysOnTop = true

	local lbl = Instance.new("TextLabel", bbg)
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = (isCrit and "💥 CRIT +" or "+") .. NumberFormat.Format(math.floor(amount))
	lbl.TextColor3 = isCrit and Color3.fromRGB(255, 95, 80) or Color3.fromRGB(255, 225, 75)
	lbl.TextStrokeColor3 = Color3.fromRGB(16, 12, 8)
	lbl.TextStrokeTransparency = 0.08
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = isCrit and 36 or 27

	local targetSize = isCrit and 32 or 24
	TweenService:Create(lbl, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = targetSize,
	}):Play()

	local tw = TweenService:Create(p, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = p.Position + Vector3.new(0, 4.4, 0),
	})
	tw:Play()
	tw.Completed:Connect(function()
		p:Destroy()
	end)
end

local lastLocalClick = 0
local function tryClickMyFlame()
	local now = os.clock()
	if now - lastLocalClick < currentClickCooldown then return end
	lastLocalClick = now
	remotes.ClickFlame:FireServer()
end

local flameHoldSource = nil
local flameHoldGeneration = 0
local function startFlameHold(source)
	if not canHoldClickCore or flameHoldSource then return end
	flameHoldGeneration += 1
	local generation = flameHoldGeneration
	flameHoldSource = source
	task.spawn(function()
		while flameHoldGeneration == generation and flameHoldSource and canHoldClickCore do
			tryClickMyFlame()
			task.wait(math.clamp(currentClickCooldown, 0.05, 0.10))
		end
		if flameHoldGeneration == generation then
			flameHoldSource = nil
		end
	end)
end

local function stopFlameHold(source)
	if flameHoldSource == source then
		flameHoldGeneration += 1
		flameHoldSource = nil
	end
end

UserInputService.InputBegan:Connect(function(inp, gp)
	if gp then return end
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		local target = mouse.Target
		local myPlot = ClientWorldVisuals.GetMyPlotModel()
		local brazier = myPlot and myPlot:FindFirstChild("Brazier")
		if target and brazier and target:IsDescendantOf(brazier) then
			tryClickMyFlame()
			startFlameHold("pointer")
		end
	elseif inp.KeyCode == Enum.KeyCode.E or inp.KeyCode == Enum.KeyCode.F then
		local core = ClientWorldVisuals.GetMyFlameCore()
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if core and hrp and (core.Position - hrp.Position).Magnitude <= 32 then
			tryClickMyFlame()
			startFlameHold("key")
		end
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		stopFlameHold("pointer")
	elseif inp.KeyCode == Enum.KeyCode.E or inp.KeyCode == Enum.KeyCode.F then
		stopFlameHold("key")
	end
end)

local tutorialController = TutorialUI.Build(gui, remotes)
local shopController = ShopUI.Build(gui, remotes, function()
	tutorialController.Open()
end)

remotes.StateSync.OnClientEvent:Connect(function(st)
	if not st then return end
	if st.Language == "en" or st.Language == "it" then
		currentLang = st.Language
		langBtn.Text = (currentLang == "en") and "🌐 EN" or "🌐 IT"
	end

	if type(st.ClickCooldown) == "number" then
		currentClickCooldown = math.max(0.05, st.ClickCooldown)
	end
	local autoClickLevel = (st.AlbaPerks and st.AlbaPerks.ap_auto_click) or 0
	canHoldClickCore = type(autoClickLevel) == "number" and autoClickLevel > 0

	pointsLbl.Text = "🔥 " .. NumberFormat.Format(math.floor(st.Points or 0)) .. " " .. Localization.T(currentLang, "POINTS_SUFFIX")
	rateLbl.Text = Localization.T(
		currentLang,
		"RATE_FMT",
		NumberFormat.Format(st.ClickPower or 1),
		currentClickCooldown,
		NumberFormat.Format(st.PointsPerSec or 0)
	)
	zoneBadge.Text = Localization.T(currentLang, "ZONE_BADGE_FMT", st.UnlockedZonesCount or 1, st.RankName or "Keeper", st.LightPercent or 4)

	local buffSuffix = ""
	if (st.Regno1BuffRemaining or 0) > 0 then
		buffSuffix = string.format(" • ⚡x%.2f(%ds)", st.Regno1BuffMult or 1, math.ceil(st.Regno1BuffRemaining))
	end
	heatAndAlbaLbl.Text = Localization.T(
		currentLang,
		"HEAT_ALBA_FMT",
		st.HeatMult or 1,
		st.AlbaPoints or 0,
		st.CompletedUpgradesCount or 0,
		st.TotalUpgradesCount or 22,
		buffSuffix
	)

	ClientWorldVisuals.Update(st)
	shopController.Update(st)
	tutorialController.Update(st)

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
		trialBanner.Text = Localization.T(currentLang, "R1_BANNER_ACTIVE", r1.CurrentStep or 1, r1.TotalSteps or 5, r1.TimeLeft or 0)
	elseif (r1.BuffRemaining or 0) > 0 then
		trialBanner.Visible = true
		trialBanner.Text = Localization.T(currentLang, "R1_BANNER_BUFF", r1.BuffMult or 1.5, math.ceil(r1.BuffRemaining))
	else
		trialBanner.Visible = false
	end
end)

remotes.DefenseFx.OnClientEvent:Connect(function(fx)
	ClientWorldVisuals.PlayDefenseFx(fx)
end)

remotes.SyncGamePass:FireServer()
