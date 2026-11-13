local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Regno1UI = {}

function Regno1UI.Build(parentGui)
	local state = {
		Unlocked = false,
		Completed = false,
		BestTime = nil,
		Active = false,
		Step = 0,
		TotalBraziers = #GameConfig.Regno1.Braziers,
		TimeLeft = 0,
		MaxTime = GameConfig.Regno1.BaseTime,
		BuffMult = 1.0,
		BuffRemaining = 0,
		BuffDuration = GameConfig.Regno1.BuffDuration,
	}

	-- Contenitore compatto centrato sotto la TopHUD
	local root = Instance.new("Frame", parentGui)
	root.Name = "Regno1HUD"
	root.AnchorPoint = Vector2.new(0.5, 0)
	root.Position = UDim2.new(0.42, 0, 0, 88)
	root.Size = UDim2.fromOffset(440, 84)
	root.BackgroundTransparency = 1

	-- 1. Pannello Sfida Attiva (Catena del Fuoco 1/5 -> 5/5)
	local trialCard = Instance.new("Frame", root)
	trialCard.Name = "TrialCard"
	trialCard.Size = UDim2.new(1, 0, 0, 74)
	trialCard.BackgroundColor3 = Color3.fromRGB(18, 16, 26)
	trialCard.BackgroundTransparency = 0.08
	trialCard.Visible = false
	Instance.new("UICorner", trialCard).CornerRadius = UDim.new(0, 14)

	local trialStroke = Instance.new("UIStroke", trialCard)
	trialStroke.Color = Color3.fromRGB(255, 190, 65)
	trialStroke.Thickness = 2

	local trialTitle = Instance.new("TextLabel", trialCard)
	trialTitle.Size = UDim2.new(0.62, 0, 0, 22)
	trialTitle.Position = UDim2.fromOffset(12, 6)
	trialTitle.BackgroundTransparency = 1
	trialTitle.Text = "🔥 REGNO 1 • CATENA DEL FUOCO"
	trialTitle.TextColor3 = Color3.fromRGB(255, 215, 90)
	trialTitle.TextXAlignment = Enum.TextXAlignment.Left
	trialTitle.Font = Enum.Font.GothamBlack
	trialTitle.TextScaled = true

	local timerLabel = Instance.new("TextLabel", trialCard)
	timerLabel.Size = UDim2.new(0.34, 0, 0, 22)
	timerLabel.Position = UDim2.new(0.64, 0, 0, 6)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "⏱️ 18.0s"
	timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerLabel.TextXAlignment = Enum.TextXAlignment.Right
	timerLabel.Font = Enum.Font.GothamBlack
	timerLabel.TextScaled = true

	-- Barra Timer
	local barBg = Instance.new("Frame", trialCard)
	barBg.Size = UDim2.new(1, -24, 0, 8)
	barBg.Position = UDim2.fromOffset(12, 31)
	barBg.BackgroundColor3 = Color3.fromRGB(34, 34, 48)
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

	local barFill = Instance.new("Frame", barBg)
	barFill.Size = UDim2.fromScale(1, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 185, 55)
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)

	-- 5 Pillole per i 5 Bracieri
	local stepsRow = Instance.new("Frame", trialCard)
	stepsRow.Size = UDim2.new(1, -24, 0, 24)
	stepsRow.Position = UDim2.fromOffset(12, 44)
	stepsRow.BackgroundTransparency = 1

	local stepPills = {}
	for i, bCfg in ipairs(GameConfig.Regno1.Braziers) do
		local pill = Instance.new("TextLabel", stepsRow)
		pill.Size = UDim2.new(0.184, 0, 1, 0)
		pill.Position = UDim2.new((i - 1) * 0.204, 0, 0, 0)
		pill.BackgroundColor3 = Color3.fromRGB(32, 34, 46)
		pill.Text = bCfg.Numeral
		pill.TextColor3 = Color3.fromRGB(160, 165, 185)
		pill.Font = Enum.Font.GothamBlack
		pill.TextScaled = true
		Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 7)
		stepPills[i] = pill
	end

	-- 2. Pillola Stato / Buff Fiamma Ruggente / Record (quando non sei in corsa)
	local statusPill = Instance.new("Frame", root)
	statusPill.Name = "Regno1StatusPill"
	statusPill.AnchorPoint = Vector2.new(0.5, 0)
	statusPill.Position = UDim2.new(0.5, 0, 0, 0)
	statusPill.Size = UDim2.fromOffset(390, 30)
	statusPill.BackgroundColor3 = Color3.fromRGB(18, 17, 26)
	statusPill.BackgroundTransparency = 0.14
	statusPill.Visible = false
	Instance.new("UICorner", statusPill).CornerRadius = UDim.new(1, 0)

	local statusStroke = Instance.new("UIStroke", statusPill)
	statusStroke.Color = Color3.fromRGB(255, 185, 60)
	statusStroke.Transparency = 0.35
	statusStroke.Thickness = 1.4

	local statusText = Instance.new("TextLabel", statusPill)
	statusText.Size = UDim2.new(1, -20, 1, -4)
	statusText.Position = UDim2.fromOffset(10, 2)
	statusText.BackgroundTransparency = 1
	statusText.Text = "🔥 Regno 1: Raggiungi il Braciere I"
	statusText.TextColor3 = Color3.fromRGB(255, 220, 115)
	statusText.Font = Enum.Font.GothamBlack
	statusText.TextScaled = true

	local function showBonusTimeFloat(bonusSec)
		local floatLbl = Instance.new("TextLabel", trialCard)
		floatLbl.AnchorPoint = Vector2.new(1, 0.5)
		floatLbl.Position = UDim2.new(1, -14, 0, -8)
		floatLbl.Size = UDim2.fromOffset(90, 22)
		floatLbl.BackgroundTransparency = 1
		floatLbl.Text = string.format("+%.1fs!", bonusSec)
		floatLbl.TextColor3 = Color3.fromRGB(90, 255, 160)
		floatLbl.Font = Enum.Font.GothamBlack
		floatLbl.TextScaled = true

		local tw = TweenService:Create(floatLbl, TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -14, 0, -28),
			TextTransparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() floatLbl:Destroy() end)
	end

	local function refreshVisualState()
		if state.Active then
			trialCard.Visible = true
			statusPill.Visible = false
			for i, pill in ipairs(stepPills) do
				if i <= state.Step then
					pill.BackgroundColor3 = Color3.fromRGB(255, 185, 55)
					pill.TextColor3 = Color3.fromRGB(18, 16, 22)
				elseif i == state.Step + 1 then
					pill.BackgroundColor3 = Color3.fromRGB(65, 55, 32)
					pill.TextColor3 = Color3.fromRGB(255, 240, 140)
				else
					pill.BackgroundColor3 = Color3.fromRGB(32, 34, 46)
					pill.TextColor3 = Color3.fromRGB(150, 155, 175)
				end
			end
		else
			trialCard.Visible = false
			if state.BuffRemaining > 0 and state.BuffMult > 1.0 then
				statusPill.Visible = true
				statusStroke.Color = Color3.fromRGB(255, 225, 85)
				statusText.TextColor3 = Color3.fromRGB(255, 235, 120)
				statusText.Text = string.format("⚡ FIAMMA RUGGENTE x%.2f (%ds)", state.BuffMult, math.ceil(state.BuffRemaining))
			elseif state.Unlocked then
				statusPill.Visible = true
				statusStroke.Color = Color3.fromRGB(255, 175, 60)
				statusText.TextColor3 = Color3.fromRGB(255, 215, 125)
				if state.BestTime then
					statusText.Text = string.format("🏆 Regno 1 (+35%%) • Record: %.2fs", state.BestTime)
				else
					statusText.Text = "🔥 Regno 1: Corri al Braciere I per la Catena!"
				end
			else
				statusPill.Visible = false
			end
		end
	end

	-- Aggiornamento fluido del timer client tra un tick server e l'altro
	RunService.RenderStepped:Connect(function(dt)
		if state.Active then
			state.TimeLeft = math.max(0, state.TimeLeft - dt)
			local ratio = math.clamp(state.TimeLeft / math.max(1, state.MaxTime), 0, 1)
			barFill.Size = UDim2.fromScale(ratio, 1)
			timerLabel.Text = string.format("⏱️ %.1fs", state.TimeLeft)

			if state.TimeLeft <= 4.0 then
				barFill.BackgroundColor3 = Color3.fromRGB(255, 75, 75)
				timerLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
				trialStroke.Color = Color3.fromRGB(255, 80, 80)
			else
				barFill.BackgroundColor3 = Color3.fromRGB(255, 185, 55)
				timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				trialStroke.Color = Color3.fromRGB(255, 190, 65)
			end
		elseif state.BuffRemaining > 0 then
			state.BuffRemaining = math.max(0, state.BuffRemaining - dt)
			refreshVisualState()
		end
	end)

	local controller = {}

	function controller.OnRegno1Event(payload)
		state.Unlocked = payload.Unlocked == true
		state.Completed = payload.Completed == true
		state.BestTime = payload.BestTime
		state.Active = payload.Active == true
		state.Step = payload.Step or 0
		state.TimeLeft = payload.TimeLeft or 0
		state.MaxTime = payload.MaxTime or GameConfig.Regno1.BaseTime
		state.BuffMult = payload.BuffMult or 1.0
		state.BuffRemaining = payload.BuffRemaining or 0

		if payload.Type == "Ignite" and payload.BonusAdded then
			showBonusTimeFloat(payload.BonusAdded)
		end

		refreshVisualState()
	end

	function controller.SyncFromState(st)
		if st.Upgrades then
			state.Unlocked = (st.Upgrades[GameConfig.Regno1.UnlockUpgradeId] or 0) > 0
		end
		if st.Regno1 then
			state.Completed = st.Regno1.Completed == true
			state.BestTime = st.Regno1.BestTime
		end
		if st.Regno1BuffMult then
			state.BuffMult = st.Regno1BuffMult
		end
		if st.Regno1BuffRemaining then
			state.BuffRemaining = st.Regno1BuffRemaining
		end
		refreshVisualState()
	end

	return controller
end

return Regno1UI
