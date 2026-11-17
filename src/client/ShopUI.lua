local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))

local ShopUI = {}

local THEME = {
	Bg = Color3.fromRGB(16, 18, 28),
	Card = Color3.fromRGB(26, 30, 44),
	CardLocked = Color3.fromRGB(20, 22, 32),
	Gold = Color3.fromRGB(255, 200, 65),
	Cyan = Color3.fromRGB(75, 220, 255),
	Green = Color3.fromRGB(70, 240, 145),
	Purple = Color3.fromRGB(190, 105, 255),
	TextMain = Color3.fromRGB(245, 247, 255),
	TextSub = Color3.fromRGB(165, 175, 200),
}

function ShopUI.Build(parentGui, remotes)
	local latestState = nil
	local activeTab = "Character"
	local isOpen = false

	-- =========================================================================
	-- BARRA INFERIORE CON TASTI GRANDI: LA MIA ZONA, PERSONAGGIO E LUCE x2
	-- =========================================================================
	local bottomBar = Instance.new("Frame", parentGui)
	bottomBar.Name = "BigMenuLaunchBar"
	bottomBar.AnchorPoint = Vector2.new(0.5, 1)
	bottomBar.Position = UDim2.new(0.5, 0, 1, -16)
	bottomBar.Size = UDim2.fromOffset(636, 68)
	bottomBar.BackgroundTransparency = 1
	bottomBar.ZIndex = 15

	local homeBtn = Instance.new("TextButton", bottomBar)
	homeBtn.Name = "TeleportHomeButton"
	homeBtn.Position = UDim2.fromOffset(0, 0)
	homeBtn.Size = UDim2.fromOffset(156, 68)
	homeBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 48)
	homeBtn.Text = "🏠 LA MIA\nZONA"
	homeBtn.TextColor3 = THEME.Cyan
	homeBtn.Font = Enum.Font.GothamBlack
	homeBtn.TextScaled = true
	homeBtn.ZIndex = 15
	Instance.new("UICorner", homeBtn).CornerRadius = UDim.new(0, 18)

	local homeStroke = Instance.new("UIStroke", homeBtn)
	homeStroke.Color = THEME.Cyan
	homeStroke.Thickness = 2.2

	homeBtn.MouseButton1Click:Connect(function()
		if remotes and remotes.TeleportHome then
			remotes.TeleportHome:FireServer()
		end
	end)

	local toggleBtn = Instance.new("TextButton", bottomBar)
	toggleBtn.Name = "BigOpenMenuButton"
	toggleBtn.Position = UDim2.fromOffset(168, 0)
	toggleBtn.Size = UDim2.fromOffset(288, 68)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 15
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 18)

	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = THEME.Gold
	toggleStroke.Thickness = 2.4

	local toggleIconBg = Instance.new("TextLabel", toggleBtn)
	toggleIconBg.Size = UDim2.fromOffset(46, 46)
	toggleIconBg.Position = UDim2.fromOffset(11, 11)
	toggleIconBg.BackgroundColor3 = Color3.fromRGB(44, 34, 18)
	toggleIconBg.Text = "🧙"
	toggleIconBg.TextScaled = true
	toggleIconBg.ZIndex = 16
	Instance.new("UICorner", toggleIconBg).CornerRadius = UDim.new(0, 12)

	local toggleLabel = Instance.new("TextLabel", toggleBtn)
	toggleLabel.Size = UDim2.new(1, -68, 0, 26)
	toggleLabel.Position = UDim2.fromOffset(64, 10)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = "PERSONAGGIO"
	toggleLabel.TextColor3 = THEME.TextMain
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Font = Enum.Font.GothamBlack
	toggleLabel.TextScaled = true
	toggleLabel.ZIndex = 16

	local toggleSub = Instance.new("TextLabel", toggleBtn)
	toggleSub.Size = UDim2.new(1, -68, 0, 18)
	toggleSub.Position = UDim2.fromOffset(64, 38)
	toggleSub.BackgroundTransparency = 1
	toggleSub.Text = "Apri Menù [B]"
	toggleSub.TextColor3 = THEME.TextSub
	toggleSub.TextXAlignment = Enum.TextXAlignment.Left
	toggleSub.Font = Enum.Font.GothamBold
	toggleSub.TextScaled = true
	toggleSub.ZIndex = 16

	local readyBadge = Instance.new("TextLabel", toggleBtn)
	readyBadge.Name = "ReadyBadge"
	readyBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	readyBadge.Position = UDim2.fromOffset(6, 6)
	readyBadge.Size = UDim2.fromOffset(28, 28)
	readyBadge.BackgroundColor3 = THEME.Gold
	readyBadge.Text = "0"
	readyBadge.TextColor3 = Color3.fromRGB(16, 16, 22)
	readyBadge.Font = Enum.Font.GothamBlack
	readyBadge.TextScaled = true
	readyBadge.Visible = false
	readyBadge.ZIndex = 18
	Instance.new("UICorner", readyBadge).CornerRadius = UDim.new(1, 0)

	local dockBoostBtn = Instance.new("TextButton", bottomBar)
	dockBoostBtn.Name = "BigDoubleLightButton"
	dockBoostBtn.Position = UDim2.fromOffset(468, 0)
	dockBoostBtn.Size = UDim2.fromOffset(168, 68)
	dockBoostBtn.BackgroundColor3 = Color3.fromRGB(42, 32, 16)
	dockBoostBtn.Text = "⚡ LUCE x2\n(ROBUX)"
	dockBoostBtn.TextColor3 = THEME.Gold
	dockBoostBtn.Font = Enum.Font.GothamBlack
	dockBoostBtn.TextScaled = true
	dockBoostBtn.ZIndex = 15
	Instance.new("UICorner", dockBoostBtn).CornerRadius = UDim.new(0, 18)

	local dockBoostStroke = Instance.new("UIStroke", dockBoostBtn)
	dockBoostStroke.Color = THEME.Gold
	dockBoostStroke.Thickness = 2.2

	dockBoostBtn.MouseButton1Click:Connect(function()
		local passId = GameConfig.RobuxPasses and GameConfig.RobuxPasses.DoubleLight and GameConfig.RobuxPasses.DoubleLight.GamePassId or 0
		if passId > 0 then
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(game:GetService("Players").LocalPlayer, passId)
			end)
		end
	end)

	-- =========================================================================
	-- FINESTRA CENTRALE DEL MENÙ PERSONAGGIO
	-- =========================================================================
	local modal = Instance.new("Frame", parentGui)
	modal.Name = "CharacterMenuModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.48)
	modal.Size = UDim2.fromOffset(660, 460)
	modal.BackgroundColor3 = THEME.Bg
	modal.Visible = false
	modal.ZIndex = 20
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 20)

	local modalStroke = Instance.new("UIStroke", modal)
	modalStroke.Color = THEME.Gold
	modalStroke.Thickness = 2

	local header = Instance.new("Frame", modal)
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 21

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Position = UDim2.fromOffset(18, 10)
	headerTitle.Size = UDim2.new(1, -80, 0, 32)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "🧙 SANTUARIO DEL CUSTODE"
	headerTitle.TextColor3 = THEME.Gold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextScaled = true
	headerTitle.ZIndex = 21

	local closeBtn = Instance.new("TextButton", header)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(36, 36)
	closeBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 32)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 110, 120)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextScaled = true
	closeBtn.ZIndex = 22
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)

	-- Barra Schede
	local tabsBar = Instance.new("Frame", modal)
	tabsBar.Position = UDim2.fromOffset(16, 54)
	tabsBar.Size = UDim2.new(1, -32, 0, 40)
	tabsBar.BackgroundTransparency = 1
	tabsBar.ZIndex = 21

	local tabDefs = {
		{ Id = "Character", Label = "🔥 Personaggio" },
		{ Id = "Wisps",     Label = "✨ Spiriti" },
		{ Id = "Alba",      Label = "🌅 Alba" },
		{ Id = "Codes",     Label = "🎁 Codici" },
	}
	local tabButtons = {}

	for idx, td in ipairs(tabDefs) do
		local b = Instance.new("TextButton", tabsBar)
		b.Position = UDim2.new((idx - 1) * 0.25, 3, 0, 0)
		b.Size = UDim2.new(0.25, -6, 1, 0)
		b.BackgroundColor3 = THEME.Card
		b.Text = td.Label
		b.TextColor3 = THEME.TextMain
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		tabButtons[td.Id] = b
	end

	local scroll = Instance.new("ScrollingFrame", modal)
	scroll.Position = UDim2.fromOffset(16, 104)
	scroll.Size = UDim2.new(1, -32, 1, -120)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 21

	local listLayout = Instance.new("UIListLayout", scroll)
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function clearScroll()
		for _, child in ipairs(scroll:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	local function renderContent()
		clearScroll()
		for id, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = (id == activeTab) and Color3.fromRGB(58, 46, 22) or THEME.Card
			btn.TextColor3 = (id == activeTab) and THEME.Gold or THEME.TextSub
		end

		if not latestState then return end
		local st = latestState
		local points = st.Points or 0

		if activeTab == "Character" then
			local sorted = {}
			for _, u in ipairs(GameConfig.Upgrades) do table.insert(sorted, u) end
			table.sort(sorted, function(a, b) return (a.Order or 0) < (b.Order or 0) end)

			for idx, u in ipairs(sorted) do
				local lvl = EconomyEngine.GetLevel(st.Upgrades, u.Id)
				local unlocked = EconomyEngine.IsUpgradeUnlocked({ Upgrades = st.Upgrades or {} }, u)
				local maxed = lvl >= u.MaxLevel
				local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
				local canBuy = unlocked and (not maxed) and points >= cost

				local card = Instance.new("Frame", scroll)
				card.LayoutOrder = idx
				card.Size = UDim2.new(1, -8, 0, 74)
				card.BackgroundColor3 = unlocked and THEME.Card or THEME.CardLocked
				card.ZIndex = 22
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

				local title = Instance.new("TextLabel", card)
				title.Position = UDim2.fromOffset(14, 8)
				title.Size = UDim2.new(1, -175, 0, 24)
				title.BackgroundTransparency = 1
				title.Text = string.format("%s %s  [Lv.%d/%d]", u.Icon, u.Name, lvl, u.MaxLevel)
				title.TextColor3 = unlocked and THEME.TextMain or THEME.TextSub
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Font = Enum.Font.GothamBlack
				title.TextScaled = true
				title.ZIndex = 23

				local desc = Instance.new("TextLabel", card)
				desc.Position = UDim2.fromOffset(14, 34)
				desc.Size = UDim2.new(1, -175, 0, 32)
				desc.BackgroundTransparency = 1
				desc.Text = unlocked and (u.Tag .. " — " .. u.Desc) or ("🔒 Richiede potenziamento precedente")
				desc.TextColor3 = THEME.TextSub
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.TextWrapped = true
				desc.Font = Enum.Font.Gotham
				desc.TextScaled = true
				desc.ZIndex = 23

				local buyBtn = Instance.new("TextButton", card)
				buyBtn.AnchorPoint = Vector2.new(1, 0.5)
				buyBtn.Position = UDim2.new(1, -12, 0.5, 0)
				buyBtn.Size = UDim2.fromOffset(145, 48)
				buyBtn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				buyBtn.Text = maxed and "MASSIMO" or (unlocked and (NumberFormat.Format(cost) .. " Luce") or "BLOCCATO")
				buyBtn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				buyBtn.Font = Enum.Font.GothamBlack
				buyBtn.TextScaled = true
				buyBtn.ZIndex = 23
				Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 10)

				if canBuy then
					buyBtn.MouseButton1Click:Connect(function()
						remotes.BuyUpgrade:FireServer(u.Id)
					end)
				end
			end

		elseif activeTab == "Wisps" then
			if not st.WispsUnlocked then
				local lockLbl = Instance.new("TextLabel", scroll)
				lockLbl.Size = UDim2.new(1, -8, 0, 90)
				lockLbl.BackgroundColor3 = THEME.Card
				lockLbl.Text = "🔒 Sblocca 'Evocazione Spiriti' nella scheda Personaggio per evocare e fondere Spiriti!"
				lockLbl.TextColor3 = THEME.Gold
				lockLbl.Font = Enum.Font.GothamBold
				lockLbl.TextWrapped = true
				lockLbl.TextScaled = true
				lockLbl.ZIndex = 22
				Instance.new("UICorner", lockLbl).CornerRadius = UDim.new(0, 12)
				return
			end

			-- Pannello Evocazione 1x / 5x
			local sumCard = Instance.new("Frame", scroll)
			sumCard.LayoutOrder = 1
			sumCard.Size = UDim2.new(1, -8, 0, 76)
			sumCard.BackgroundColor3 = THEME.Card
			sumCard.ZIndex = 22
			Instance.new("UICorner", sumCard).CornerRadius = UDim.new(0, 12)

			local sumInfo = Instance.new("TextLabel", sumCard)
			sumInfo.Position = UDim2.fromOffset(14, 10)
			sumInfo.Size = UDim2.new(0.48, 0, 0, 56)
			sumInfo.BackgroundTransparency = 1
			sumInfo.Text = string.format("✨ Spiriti Attivi: %d / %d\nI migliori vengono equipaggiati in automatico!", st.EquippedCount or 0, st.MaxWispSlots or 3)
			sumInfo.TextColor3 = THEME.TextMain
			sumInfo.TextXAlignment = Enum.TextXAlignment.Left
			sumInfo.TextWrapped = true
			sumInfo.Font = Enum.Font.GothamBold
			sumInfo.TextScaled = true
			sumInfo.ZIndex = 23

			local btn1 = Instance.new("TextButton", sumCard)
			btn1.Position = UDim2.new(0.52, 0, 0.5, -24)
			btn1.Size = UDim2.new(0.22, 0, 0, 48)
			btn1.BackgroundColor3 = (points >= GameConfig.BaseWispCost) and THEME.Cyan or Color3.fromRGB(36, 40, 56)
			btn1.Text = "Evoca x1\n" .. NumberFormat.Format(GameConfig.BaseWispCost)
			btn1.TextColor3 = (points >= GameConfig.BaseWispCost) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			btn1.Font = Enum.Font.GothamBlack
			btn1.TextScaled = true
			btn1.ZIndex = 23
			Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 10)
			btn1.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(1)
			end)

			local cost5 = GameConfig.BaseWispCost * 5
			local btn5 = Instance.new("TextButton", sumCard)
			btn5.Position = UDim2.new(0.76, 0, 0.5, -24)
			btn5.Size = UDim2.new(0.22, 0, 0, 48)
			btn5.BackgroundColor3 = (points >= cost5) and THEME.Gold or Color3.fromRGB(36, 40, 56)
			btn5.Text = "Evoca x5\n" .. NumberFormat.Format(cost5)
			btn5.TextColor3 = (points >= cost5) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			btn5.Font = Enum.Font.GothamBlack
			btn5.TextScaled = true
			btn5.ZIndex = 23
			Instance.new("UICorner", btn5).CornerRadius = UDim.new(0, 10)
			btn5.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(5)
			end)

			local counts = st.WispCounts or {}
			for idx, w in ipairs(GameConfig.Wisps) do
				local normCnt = counts[w.Id] or 0
				local radCnt = counts[w.Id .. "_rad"] or 0
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = idx + 1
				row.Size = UDim2.new(1, -8, 0, 62)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

				local lbl = Instance.new("TextLabel", row)
				lbl.Position = UDim2.fromOffset(14, 8)
				lbl.Size = UDim2.new(1, -175, 0, 46)
				lbl.BackgroundTransparency = 1
				lbl.Text = string.format("● %s (x%.1f | %s)  —  Normali: %d | Radiosi: %d", w.Name, w.ClickMult, w.Chance, normCnt, radCnt)
				lbl.TextColor3 = w.Color
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.Font = Enum.Font.GothamBold
				lbl.TextScaled = true
				lbl.ZIndex = 23

				local fuseBtn = Instance.new("TextButton", row)
				fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
				fuseBtn.Position = UDim2.new(1, -12, 0.5, 0)
				fuseBtn.Size = UDim2.fromOffset(145, 42)
				fuseBtn.BackgroundColor3 = (normCnt >= 3) and THEME.Purple or Color3.fromRGB(36, 40, 56)
				fuseBtn.Text = (normCnt >= 3) and "🌟 FORGIA (3→1)" or ("Servono 3 (" .. normCnt .. "/3)")
				fuseBtn.TextColor3 = THEME.TextMain
				fuseBtn.Font = Enum.Font.GothamBlack
				fuseBtn.TextScaled = true
				fuseBtn.ZIndex = 23
				Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 10)
				if normCnt >= 3 then
					fuseBtn.MouseButton1Click:Connect(function()
						remotes.FuseWisp:FireServer(w.Id)
					end)
				end
			end

		elseif activeTab == "Alba" then
			local canPrestige = points >= GameConfig.PrestigeCost
			local gained = canPrestige and math.max(1, math.floor(math.log10(points / 5e6))) or 0

			local pCard = Instance.new("Frame", scroll)
			pCard.LayoutOrder = 1
			pCard.Size = UDim2.new(1, -8, 0, 82)
			pCard.BackgroundColor3 = THEME.Card
			pCard.ZIndex = 22
			Instance.new("UICorner", pCard).CornerRadius = UDim.new(0, 12)

			local pInfo = Instance.new("TextLabel", pCard)
			pInfo.Position = UDim2.fromOffset(14, 10)
			pInfo.Size = UDim2.new(1, -195, 0, 62)
			pInfo.BackgroundTransparency = 1
			pInfo.Text = string.format("🌅 GRANDE ALBA (Stelle Eterne: %d)\nRichiede %s Luce. Ottieni +%d Stelle Eterne!", st.EternalStars or 0, NumberFormat.Format(GameConfig.PrestigeCost), gained)
			pInfo.TextColor3 = THEME.Gold
			pInfo.TextXAlignment = Enum.TextXAlignment.Left
			pInfo.TextWrapped = true
			pInfo.Font = Enum.Font.GothamBold
			pInfo.TextScaled = true
			pInfo.ZIndex = 23

			local pBtn = Instance.new("TextButton", pCard)
			pBtn.AnchorPoint = Vector2.new(1, 0.5)
			pBtn.Position = UDim2.new(1, -12, 0.5, 0)
			pBtn.Size = UDim2.fromOffset(165, 52)
			pBtn.BackgroundColor3 = canPrestige and THEME.Gold or Color3.fromRGB(36, 40, 56)
			pBtn.Text = canPrestige and ("RINASCI (+" .. gained .. " ⭐)") or "LUCE INSUFFICIENTE"
			pBtn.TextColor3 = canPrestige and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			pBtn.Font = Enum.Font.GothamBlack
			pBtn.TextScaled = true
			pBtn.ZIndex = 23
			Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 10)
			if canPrestige then
				pBtn.MouseButton1Click:Connect(function()
					remotes.Prestige:FireServer()
				end)
			end

			for idx, sp in ipairs(GameConfig.StarPerks) do
				local lvl = EconomyEngine.GetLevel(st.StarPerks, sp.Id)
				local maxed = lvl >= sp.MaxLevel
				local cost = math.floor(sp.Cost * (sp.CostMult ^ lvl))
				local canBuy = (not maxed) and (st.EternalStars or 0) >= cost

				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = idx + 1
				row.Size = UDim2.new(1, -8, 0, 66)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

				local lbl = Instance.new("TextLabel", row)
				lbl.Position = UDim2.fromOffset(14, 8)
				lbl.Size = UDim2.new(1, -175, 0, 50)
				lbl.BackgroundTransparency = 1
				lbl.Text = string.format("⭐ %s [Lv.%d/%d] — %s", sp.Name, lvl, sp.MaxLevel, sp.Desc)
				lbl.TextColor3 = THEME.TextMain
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.Font = Enum.Font.GothamBold
				lbl.TextScaled = true
				lbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -12, 0.5, 0)
				b.Size = UDim2.fromOffset(145, 44)
				b.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				b.Text = maxed and "MASSIMO" or (cost .. " ⭐")
				b.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				b.Font = Enum.Font.GothamBlack
				b.TextScaled = true
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
				if canBuy then
					b.MouseButton1Click:Connect(function()
						remotes.BuyStarPerk:FireServer(sp.Id)
					end)
				end
			end

		elseif activeTab == "Codes" then
			local cCard = Instance.new("Frame", scroll)
			cCard.Size = UDim2.new(1, -8, 0, 130)
			cCard.BackgroundColor3 = THEME.Card
			cCard.ZIndex = 22
			Instance.new("UICorner", cCard).CornerRadius = UDim.new(0, 12)

			local box = Instance.new("TextBox", cCard)
			box.Position = UDim2.fromOffset(16, 18)
			box.Size = UDim2.new(1, -185, 0, 46)
			box.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
			box.PlaceholderText = "Inserisci codice (es. LUCE100)"
			box.Text = ""
			box.TextColor3 = THEME.TextMain
			box.Font = Enum.Font.GothamBold
			box.TextScaled = true
			box.ZIndex = 23
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)

			local statusLbl = Instance.new("TextLabel", cCard)
			statusLbl.Position = UDim2.fromOffset(16, 74)
			statusLbl.Size = UDim2.new(1, -32, 0, 38)
			statusLbl.BackgroundTransparency = 1
			statusLbl.Text = "Codici attivi: LUCE100, FIAMMA, ALBA2026"
			statusLbl.TextColor3 = THEME.TextSub
			statusLbl.TextXAlignment = Enum.TextXAlignment.Left
			statusLbl.Font = Enum.Font.GothamBold
			statusLbl.TextScaled = true
			statusLbl.ZIndex = 23

			local redeemBtn = Instance.new("TextButton", cCard)
			redeemBtn.AnchorPoint = Vector2.new(1, 0)
			redeemBtn.Position = UDim2.new(1, -16, 0, 18)
			redeemBtn.Size = UDim2.fromOffset(145, 46)
			redeemBtn.BackgroundColor3 = THEME.Green
			redeemBtn.Text = "RISCATTA"
			redeemBtn.TextColor3 = Color3.fromRGB(16, 18, 24)
			redeemBtn.Font = Enum.Font.GothamBlack
			redeemBtn.TextScaled = true
			redeemBtn.ZIndex = 23
			Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 10)

			redeemBtn.MouseButton1Click:Connect(function()
				local ok, msg = remotes.RedeemCode:InvokeServer(box.Text)
				statusLbl.Text = tostring(msg)
				statusLbl.TextColor3 = ok and THEME.Green or Color3.fromRGB(255, 110, 120)
				if ok then box.Text = "" end
			end)
		end
	end

	for id, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			activeTab = id
			renderContent()
		end)
	end

	local function setOpen(val)
		isOpen = val
		modal.Visible = isOpen
		if isOpen then
			renderContent()
		end
	end

	toggleBtn.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.B then
			setOpen(not isOpen)
		end
	end)

	-- =========================================================================
	-- SCHERMATA CELEBRATIVA "VITTORIA"
	-- =========================================================================
	local victoryModal = Instance.new("Frame", parentGui)
	victoryModal.Name = "VictoryCelebrationModal"
	victoryModal.AnchorPoint = Vector2.new(0.5, 0.5)
	victoryModal.Position = UDim2.fromScale(0.5, 0.5)
	victoryModal.Size = UDim2.fromOffset(520, 290)
	victoryModal.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
	victoryModal.Visible = false
	victoryModal.ZIndex = 40
	Instance.new("UICorner", victoryModal).CornerRadius = UDim.new(0, 22)

	local vStroke = Instance.new("UIStroke", victoryModal)
	vStroke.Color = THEME.Gold
	vStroke.Thickness = 3

	local vHead = Instance.new("TextLabel", victoryModal)
	vHead.Position = UDim2.fromOffset(20, 22)
	vHead.Size = UDim2.new(1, -40, 0, 52)
	vHead.BackgroundTransparency = 1
	vHead.Text = "👑 VITTORIA SUPREMA! 👑"
	vHead.TextColor3 = THEME.Gold
	vHead.Font = Enum.Font.GothamBlack
	vHead.TextScaled = true
	vHead.ZIndex = 41

	local vBody = Instance.new("TextLabel", victoryModal)
	vBody.Position = UDim2.fromOffset(24, 86)
	vBody.Size = UDim2.new(1, -48, 0, 110)
	vBody.BackgroundTransparency = 1
	vBody.Text = "Hai acceso la Fiamma Suprema della tua Zona con 1.00B Punti Luce!\nPuoi continuare a giocare e potenziare la tua isola quando vuoi."
	vBody.TextColor3 = THEME.TextMain
	vBody.TextWrapped = true
	vBody.Font = Enum.Font.GothamBold
	vBody.TextScaled = true
	vBody.ZIndex = 41

	local vClose = Instance.new("TextButton", victoryModal)
	vClose.AnchorPoint = Vector2.new(0.5, 1)
	vClose.Position = UDim2.new(0.5, 0, 1, -22)
	vClose.Size = UDim2.fromOffset(220, 48)
	vClose.BackgroundColor3 = THEME.Gold
	vClose.Text = "CONTINUA A GIOCARE"
	vClose.TextColor3 = Color3.fromRGB(16, 18, 24)
	vClose.Font = Enum.Font.GothamBlack
	vClose.TextScaled = true
	vClose.ZIndex = 41
	Instance.new("UICorner", vClose).CornerRadius = UDim.new(0, 14)
	vClose.MouseButton1Click:Connect(function()
		victoryModal.Visible = false
	end)

	return {
		Update = function(st)
			latestState = st
			if st.HasDoubleLight then
				dockBoostBtn.Text = "✅ LUCE x2\nATTIVA"
				dockBoostBtn.TextColor3 = THEME.Green
				dockBoostStroke.Color = THEME.Green
			end

			-- Conta potenziamenti acquistabili per il badge sul tasto
			local readyCount = 0
			local pts = st.Points or 0
			for _, u in ipairs(GameConfig.Upgrades) do
				local lvl = EconomyEngine.GetLevel(st.Upgrades, u.Id)
				if lvl < u.MaxLevel and EconomyEngine.IsUpgradeUnlocked({ Upgrades = st.Upgrades or {} }, u) then
					local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
					if pts >= cost then
						readyCount += 1
					end
				end
			end
			readyBadge.Visible = readyCount > 0
			readyBadge.Text = tostring(readyCount)

			if isOpen then
				renderContent()
			end
		end,
		ShowVictory = function()
			victoryModal.Visible = true
		end,
	}
end

return ShopUI
