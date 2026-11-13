local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local playerGui = player:WaitForChild("PlayerGui")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local Remotes = {
	StateSync = RemotesFolder:WaitForChild("StateSync"),
	ClickFlame = RemotesFolder:WaitForChild("ClickFlame"),
	BuyUpgrade = RemotesFolder:WaitForChild("BuyUpgrade"),
	BuyStarPerk = RemotesFolder:WaitForChild("BuyStarPerk"),
	SummonWisp = RemotesFolder:WaitForChild("SummonWisp"),
	FuseWisp = RemotesFolder:WaitForChild("FuseWisp"),
	Prestige = RemotesFolder:WaitForChild("Prestige"),
	RedeemCode = RemotesFolder:WaitForChild("RedeemCode"),
	Regno1Event = RemotesFolder:WaitForChild("Regno1Event"),
}

local PopupManager = require(script.Parent:WaitForChild("PopupManager"))
local WorldVisuals = require(script.Parent:WaitForChild("WorldVisuals"))
local ShopUI = require(script.Parent:WaitForChild("ShopUI"))
local Regno1Visuals = require(script.Parent:WaitForChild("Regno1Visuals"))
local Regno1UI = require(script.Parent:WaitForChild("Regno1UI"))

local world = workspace:WaitForChild("SantuarioDellaFiamma")
local flameModel = world:WaitForChild("PrimordialFlame")
local altarsFolder = world:WaitForChild("LightAltars")

local visuals = WorldVisuals.Init(world)

-- ScreenGui Principale
local hud = Instance.new("ScreenGui", playerGui)
hud.Name = "RobloxVibeHUD"
hud.ResetOnSpawn = false
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local popups = PopupManager.new(hud)
local regno1Visuals = Regno1Visuals.Init(world, playerGui)
local regno1UI = Regno1UI.Build(hud)

-- Barra Superiore (Punti Accumulati, Click Power, Punti/s e Luce nel Mondo)
local topHud = Instance.new("Frame", hud)
topHud.AnchorPoint = Vector2.new(0.5, 0)
topHud.Position = UDim2.new(0.42, 0, 0, 12)
topHud.Size = UDim2.new(0, 620, 0, 68)
topHud.BackgroundColor3 = Color3.fromRGB(15, 16, 23)
topHud.BackgroundTransparency = 0.12
Instance.new("UICorner", topHud).CornerRadius = UDim.new(0, 14)

local topStroke = Instance.new("UIStroke", topHud)
topStroke.Color = Color3.fromRGB(255, 185, 65)
topStroke.Transparency = 0.45
topStroke.Thickness = 1.5

local pointsValue = Instance.new("TextLabel", topHud)
pointsValue.Size = UDim2.new(0.38, 0, 0.56, 0)
pointsValue.Position = UDim2.fromOffset(14, 4)
pointsValue.BackgroundTransparency = 1
pointsValue.Text = "🔥 0 Punti"
pointsValue.TextColor3 = Color3.fromRGB(255, 200, 70)
pointsValue.TextXAlignment = Enum.TextXAlignment.Left
pointsValue.Font = Enum.Font.GothamBlack
pointsValue.TextScaled = true

local heatLabel = Instance.new("TextLabel", topHud)
heatLabel.Size = UDim2.new(0.36, 0, 0.30, 0)
heatLabel.Position = UDim2.new(0, 14, 0.62, 0)
heatLabel.BackgroundTransparency = 1
heatLabel.Text = "Calore Fiamma: x1.0"
heatLabel.TextColor3 = Color3.fromRGB(175, 182, 202)
heatLabel.TextXAlignment = Enum.TextXAlignment.Left
heatLabel.Font = Enum.Font.GothamBold
heatLabel.TextScaled = true

local rankText = Instance.new("TextLabel", topHud)
rankText.Size = UDim2.new(0.32, 0, 0.40, 0)
rankText.Position = UDim2.new(0.40, 0, 0.08, 0)
rankText.BackgroundTransparency = 1
rankText.Text = "☀️ Luce 4%"
rankText.TextColor3 = Color3.fromRGB(245, 245, 250)
rankText.Font = Enum.Font.GothamBold
rankText.TextScaled = true

local lightBarBg = Instance.new("Frame", topHud)
lightBarBg.Size = UDim2.new(0.32, 0, 0.24, 0)
lightBarBg.Position = UDim2.new(0.40, 0, 0.56, 0)
lightBarBg.BackgroundColor3 = Color3.fromRGB(32, 34, 46)
Instance.new("UICorner", lightBarBg).CornerRadius = UDim.new(1, 0)

local lightBarFill = Instance.new("Frame", lightBarBg)
lightBarFill.Size = UDim2.fromScale(0.04, 1)
lightBarFill.BackgroundColor3 = Color3.fromRGB(255, 190, 60)
Instance.new("UICorner", lightBarFill).CornerRadius = UDim.new(1, 0)

local clickStat = Instance.new("TextLabel", topHud)
clickStat.Size = UDim2.new(0.24, 0, 0.44, 0)
clickStat.Position = UDim2.new(0.74, 0, 0.06, 0)
clickStat.BackgroundTransparency = 1
clickStat.Text = "👆 +1 / click"
clickStat.TextColor3 = Color3.fromRGB(85, 225, 255)
clickStat.TextXAlignment = Enum.TextXAlignment.Right
clickStat.Font = Enum.Font.GothamBlack
clickStat.TextScaled = true

local ppsStat = Instance.new("TextLabel", topHud)
ppsStat.Size = UDim2.new(0.24, 0, 0.38, 0)
ppsStat.Position = UDim2.new(0.74, 0, 0.52, 0)
ppsStat.BackgroundTransparency = 1
ppsStat.Text = "⚡ +0 / sec"
ppsStat.TextColor3 = Color3.fromRGB(55, 205, 130)
ppsStat.TextXAlignment = Enum.TextXAlignment.Right
ppsStat.Font = Enum.Font.GothamBold
ppsStat.TextScaled = true

-- Audio
local muted = false
local sfx = Instance.new("Sound", playerGui)
sfx.SoundId = "rbxassetid://6895079853"
sfx.Volume = 0.40
local lastSfx, pitch = 0, 1.0

local function playSound(cue)
	if muted then return end
	local now = os.clock()
	pitch = (now - lastSfx < 0.5) and math.min(1.75, pitch + 0.05) or 1.0
	lastSfx = now
	sfx.PlaybackSpeed = cue == "Crit" and 1.85 or (cue == "Prestige" and 0.72 or pitch)
	sfx:Play()
end

-- Pannello Bottoni a Comparsa Progressiva
local shop = ShopUI.Build(hud, Remotes, popups, function(isMuted)
	muted = isMuted
	regno1Visuals.SetMuted(isMuted)
end)

-- Eventi dedicati di Regno 1 (Catena del Fuoco)
Remotes.Regno1Event.OnClientEvent:Connect(function(payload)
	regno1Visuals.OnRegno1Event(payload)
	regno1UI.OnRegno1Event(payload)
end)

-- Click diretto sulla Fiamma
mouse.Button1Down:Connect(function()
	local target = mouse.Target
	if target and target:IsDescendantOf(flameModel) then
		visuals.TriggerClickPulse(false)
		Remotes.ClickFlame:FireServer()
	end
end)

-- Sincronizzazione dal Server
Remotes.StateSync.OnClientEvent:Connect(function(st)
	pointsValue.Text = "🔥 " .. NumberFormat.Format(st.Points) .. " Punti"
	clickStat.Text = "👆 +" .. NumberFormat.Format(st.ClickPower) .. " / click"
	ppsStat.Text = "⚡ +" .. NumberFormat.Format(st.PointsPerSec) .. " / sec"
	heatLabel.Text = string.format("Calore Fiamma: x%.1f", st.HeatMult or 1.0)

	local pct = st.LightPercent or 4
	lightBarFill.Size = UDim2.fromScale(math.clamp(pct / 100, 0.02, 1), 1)
	rankText.Text = string.format("☀️ Luce %d%% • %s", pct, st.RankName or "")

	visuals.ApplyIllumination(pct, st.Heat or 0, st.Upgrades or {})
	shop.Update(st)
	regno1UI.SyncFromState(st)

	-- Pop-up dei punti accumulati ogni volta che schiacci la fiamma!
	if st.FlameClicked then
		visuals.TriggerClickPulse(st.IsCrit)
		popups:ShowClickPoints(st.ClickGained or st.ClickPower or 1, st.IsCrit)
	end
	if st.Shockwave then
		visuals.TriggerClickPulse(true)
	end
	if st.PopupText then
		popups:ShowEvent(st.PopupText)
	end
	if st.SoundCue then
		playSound(st.SoundCue)
	end

	-- Aggiorna Altari
	for _, alt in ipairs(GameConfig.Altars) do
		local pad = altarsFolder:FindFirstChild(alt.Id)
		if pad and pad:FindFirstChild("InfoGui") then
			local lvl = (st.Altars and st.Altars[alt.Id]) or 0
			local cost = math.floor(alt.BaseCost * (alt.CostMult ^ lvl))
			pad.InfoGui.Frame.SubLabel.Text = "Lv. " .. lvl .. " • " .. NumberFormat.Format(cost)
		end
	end
end)
