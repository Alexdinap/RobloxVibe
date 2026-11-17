local Players = game:GetService("Players")
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
	local renderedTab = nil
	local isOpen = false
	local lastActionClock = 0

	-- Riferimenti persistenti alle card della scheda attiva (per evitare Destroy() durante i click)
	local charCardRefs = {}
	local wispRowRefs = {}
	local wispHeaderRefs = nil
	local wispLockRef = nil
	local albaRefs = nil

	-- =========================================================================
	-- BARRA INFERIORE COMPATTA
	-- =========================================================================
	local bottomBar = Instance.new("Frame", parentGui)
	bottomBar.Name = "BigMenuLaunchBar"
	bottomBar.AnchorPoint = Vector2.new(0.5, 1)
	bottomBar.Position = UDim2.new(0.5, 0, 1, -14)
	bottomBar.Size = UDim2.fromOffset(520, 52)
	bottomBar.BackgroundTransparency = 1
	bottomBar.ZIndex = 15

	local homeBtn = Instance.new("TextButton", bottomBar)
	homeBtn.Name = "TeleportHomeButton"
	homeBtn.Position = UDim2.fromOffset(0, 0)
	homeBtn.Size = UDim2.fromOffset(130, 52)
	homeBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 48)
	homeBtn.Text = "🏠 LA MIA ZONA"
	homeBtn.TextColor3 = THEME.Cyan
	homeBtn.Font = Enum.Font.GothamBold
	homeBtn.TextSize = 12
	homeBtn.ZIndex = 15
	Instance.new("UICorner", homeBtn).CornerRadius = UDim.new(0, 14)

	local homeStroke = Instance.new("UIStroke", homeBtn)
	homeStroke.Color = THEME.Cyan
	homeStroke.Thickness = 1.6

	homeBtn.MouseButton1Click:Connect(function()
		if remotes and remotes.TeleportHome then
			remotes.TeleportHome:FireServer()
		end
	end)

	local toggleBtn = Instance.new("TextButton", bottomBar)
	toggleBtn.Name = "BigOpenMenuButton"
	toggleBtn.Position = UDim2.fromOffset(140, 0)
	toggleBtn.Size = UDim2.fromOffset(230, 52)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = true
	toggleBtn.ZIndex = 15
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = THEME.Gold
	toggleStroke.Thickness = 1.8

	local toggleIconBg = Instance.new("TextLabel", toggleBtn)
	toggleIconBg.Size = UDim2.fromOffset(34, 34)
	toggleIconBg.Position = UDim2.fromOffset(9, 9)
	toggleIconBg.BackgroundColor3 = Color3.fromRGB(44, 34, 18)
	toggleIconBg.Text = "🧙"
	toggleIconBg.TextSize = 18
	toggleIconBg.ZIndex = 16
	Instance.new("UICorner", toggleIconBg).CornerRadius = UDim.new(0, 10)

	local toggleLabel = Instance.new("TextLabel", toggleBtn)
	toggleLabel.Size = UDim2.new(1, -54, 0, 20)
	toggleLabel.Position = UDim2.fromOffset(50, 7)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = "PERSONAGGIO"
	toggleLabel.TextColor3 = THEME.TextMain
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Font = Enum.Font.GothamBlack
	toggleLabel.TextSize = 13
	toggleLabel.ZIndex = 16

	local toggleSub = Instance.new("TextLabel", toggleBtn)
	toggleSub.Size = UDim2.new(1, -54, 0, 16)
	toggleSub.Position = UDim2.fromOffset(50, 28)
	toggleSub.BackgroundTransparency = 1
	toggleSub.Text = "Potenziamenti [B]"
	toggleSub.TextColor3 = THEME.TextSub
	toggleSub.TextXAlignment = Enum.TextXAlignment.Left
	toggleSub.Font = Enum.Font.Gotham
	toggleSub.TextSize = 11
	toggleSub.ZIndex = 16

	local readyBadge = Instance.new("TextLabel", toggleBtn)
	readyBadge.Name = "ReadyBadge"
	readyBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	readyBadge.Position = UDim2.fromOffset(4, 4)
	readyBadge.Size = UDim2.fromOffset(22, 22)
	readyBadge.BackgroundColor3 = THEME.Gold
	readyBadge.Text = "0"
	readyBadge.TextColor3 = Color3.fromRGB(16, 16, 22)
	readyBadge.Font = Enum.Font.GothamBlack
	readyBadge.TextSize = 11
	readyBadge.Visible = false
	readyBadge.ZIndex = 18
	Instance.new("UICorner", readyBadge).CornerRadius = UDim.new(1, 0)

	local dockBoostBtn = Instance.new("TextButton", bottomBar)
	dockBoostBtn.Name = "BigDoubleLightButton"
	dockBoostBtn.Position = UDim2.fromOffset(380, 0)
	dockBoostBtn.Size = UDim2.fromOffset(140, 52)
	dockBoostBtn.BackgroundColor3 = Color3.fromRGB(42, 32, 16)
	dockBoostBtn.Text = "⚡ LUCE x2 (ROBUX)"
	dockBoostBtn.TextColor3 = THEME.Gold
	dockBoostBtn.Font = Enum.Font.GothamBold
	dockBoostBtn.TextSize = 12
	dockBoostBtn.ZIndex = 15
	Instance.new("UICorner", dockBoostBtn).CornerRadius = UDim.new(0, 14)

	local dockBoostStroke = Instance.new("UIStroke", dockBoostBtn)
	dockBoostStroke.Color = THEME.Gold
	dockBoostStroke.Thickness = 1.6

	dockBoostBtn.MouseButton1Click:Connect(function()
		local passId = GameConfig.RobuxPasses and GameConfig.RobuxPasses.DoubleLight and GameConfig.RobuxPasses.DoubleLight.GamePassId or 0
		if passId > 0 then
			pcall(function()
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, passId)
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
	modal.Size = UDim2.fromOffset(580, 400)
	modal.BackgroundColor3 = THEME.Bg
	modal.Visible = false
	modal.ZIndex = 20
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)

	local modalStroke = Instance.new("UIStroke", modal)
	modalStroke.Color = THEME.Gold
	modalStroke.Thickness = 1.6

	local header = Instance.new("Frame", modal)
	header.Size = UDim2.new(1, 0, 0, 42)
	header.BackgroundTransparency = 1
	header.ZIndex = 21

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Position = UDim2.fromOffset(16, 8)
	headerTitle.Size = UDim2.new(1, -70, 0, 26)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "🧙 SANTUARIO DEL CUSTODE"
	headerTitle.TextColor3 = THEME.Gold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 16
	headerTitle.ZIndex = 21

	local closeBtn = Instance.new("TextButton", header)
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -12, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 32)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 110, 120)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.ZIndex = 22
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

	local tabsBar = Instance.new("Frame", modal)
	tabsBar.Position = UDim2.fromOffset(14, 44)
	tabsBar.Size = UDim2.new(1, -28, 0, 32)
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
		b.TextSize = 12
		b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		tabButtons[td.Id] = b
	end

	local scroll = Instance.new("ScrollingFrame", modal)
	scroll.Position = UDim2.fromOffset(14, 84)
	scroll.Size = UDim2.new(1, -28, 1, -98)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 21

	local listLayout = Instance.new("UIListLayout", scroll)
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function clearScroll()
		charCardRefs = {}
		wispRowRefs = {}
		wispHeaderRefs = nil
		wispLockRef = nil
		albaRefs = nil
		for _, child in ipairs(scroll:GetChildren()) do
			if not child:IsA("UIListLayout") then
				child:Destroy()
			end
		end
	end

	-- Aggiorna i valori sulle card ESISTENTI senza mai distruggerle
	local function refreshExistingWidgets()
		if not latestState then return end
		local st = latestState
		local points = st.Points or 0

		if renderedTab == "Character" then
			for _, ref in ipairs(charCardRefs) do
				local u = ref.Config
				local lvl = EconomyEngine.GetLevel(st.Upgrades, u.Id)
				local unlocked = EconomyEngine.IsUpgradeUnlocked({ Upgrades = st.Upgrades or {} }, u)
				local maxed = lvl >= u.MaxLevel
				local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
				local canBuy = unlocked and (not maxed) and points >= cost

				ref.Card.BackgroundColor3 = unlocked and THEME.Card or THEME.CardLocked
				ref.Title.Text = string.format("%s %s  [Lv.%d/%d]", u.Icon, u.Name, lvl, u.MaxLevel)
				ref.Title.TextColor3 = unlocked and THEME.TextMain or THEME.TextSub
				ref.Desc.Text = unlocked and (u.Tag .. " — " .. u.Desc) or "🔒 Richiede potenziamento precedente"

				ref.BuyBtn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				ref.BuyBtn.Text = maxed and "MASSIMO" or (unlocked and (NumberFormat.Format(cost) .. " Luce") or "BLOCCATO")
				ref.BuyBtn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end

		elseif renderedTab == "Wisps" then
			if wispLockRef then
				wispLockRef.Visible = not st.WispsUnlocked
			end
			if wispHeaderRefs then
				wispHeaderRefs.Card.Visible = st.WispsUnlocked == true
				wispHeaderRefs.Info.Text = string.format("✨ Spiriti Attivi: %d / %d  (I migliori si equipaggiano in automatico)", st.EquippedCount or 0, st.MaxWispSlots or 3)
				wispHeaderRefs.Btn1.BackgroundColor3 = (points >= GameConfig.BaseWispCost) and THEME.Cyan or Color3.fromRGB(36, 40, 56)
				wispHeaderRefs.Btn1.TextColor3 = (points >= GameConfig.BaseWispCost) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				local cost5 = GameConfig.BaseWispCost * 5
				wispHeaderRefs.Btn5.BackgroundColor3 = (points >= cost5) and THEME.Gold or Color3.fromRGB(36, 40, 56)
				wispHeaderRefs.Btn5.TextColor3 = (points >= cost5) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end
			local counts = st.WispCounts or {}
			for _, ref in ipairs(wispRowRefs) do
				ref.Row.Visible = st.WispsUnlocked == true
				local w = ref.Config
				local normCnt = counts[w.Id] or 0
				local radCnt = counts[w.Id .. "_rad"] or 0
				ref.Label.Text = string.format("● %s (x%.1f | %s) — Norm: %d | Rad: %d", w.Name, w.ClickMult, w.Chance, normCnt, radCnt)
				ref.FuseBtn.BackgroundColor3 = (normCnt >= 3) and THEME.Purple or Color3.fromRGB(36, 40, 56)
				ref.FuseBtn.Text = (normCnt >= 3) and "🌟 FORGIA (3→1)" or ("Servono 3 (" .. normCnt .. "/3)")
			end

		elseif renderedTab == "Alba" and albaRefs then
			local canPrestige = points >= GameConfig.PrestigeCost
			local gained = canPrestige and math.max(1, math.floor(math.log10(points / 5e6))) or 0
			albaRefs.Info.Text = string.format("🌅 GRANDE ALBA (Stelle: %d)\nRichiede %s Luce • Ottieni +%d Stelle Eterne", st.EternalStars or 0, NumberFormat.Format(GameConfig.PrestigeCost), gained)
			albaRefs.PrestigeBtn.BackgroundColor3 = canPrestige and THEME.Gold or Color3.fromRGB(36, 40, 56)
			albaRefs.PrestigeBtn.Text = canPrestige and ("RINASCI (+" .. gained .. " ⭐)") or "INSUFFICIENTE"
			albaRefs.PrestigeBtn.TextColor3 = canPrestige and Color3.fromRGB(16, 18, 24) or THEME.TextMain

			for _, spRef in ipairs(albaRefs.Perks) do
				local sp = spRef.Config
				local lvl = EconomyEngine.GetLevel(st.StarPerks, sp.Id)
				local maxed = lvl >= sp.MaxLevel
				local cost = math.floor(sp.Cost * (sp.CostMult ^ lvl))
				local canBuy = (not maxed) and (st.EternalStars or 0) >= cost

				spRef.Label.Text = string.format("⭐ %s [%d/%d] — %s", sp.Name, lvl, sp.MaxLevel, sp.Desc)
				spRef.Btn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				spRef.Btn.Text = maxed and "MASSIMO" or (cost .. " ⭐")
				spRef.Btn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end
		end
	end

	-- Costruisce la struttura della scheda UNA SOLA VOLTA quando si apre o cambia tab
	local function buildTabStructure()
		clearScroll()
		renderedTab = activeTab

		for id, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = (id == activeTab) and Color3.fromRGB(58, 46, 22) or THEME.Card
			btn.TextColor3 = (id == activeTab) and THEME.Gold or THEME.TextSub
		end

		if activeTab == "Character" then
			local sorted = {}
			for _, u in ipairs(GameConfig.Upgrades) do table.insert(sorted, u) end
			table.sort(sorted, function(a, b) return (a.Order or 0) < (b.Order or 0) end)

			for idx, u in ipairs(sorted) do
				local card = Instance.new("Frame", scroll)
				card.LayoutOrder = idx
				card.Size = UDim2.new(1, -6, 0, 58)
				card.BackgroundColor3 = THEME.Card
				card.ZIndex = 22
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

				local title = Instance.new("TextLabel", card)
				title.Position = UDim2.fromOffset(12, 6)
				title.Size = UDim2.new(1, -150, 0, 18)
				title.BackgroundTransparency = 1
				title.TextColor3 = THEME.TextMain
				title.TextXAlignment = Enum.TextXAlignment.Left
				title.Font = Enum.Font.GothamBold
				title.TextSize = 13
				title.ZIndex = 23

				local desc = Instance.new("TextLabel", card)
				desc.Position = UDim2.fromOffset(12, 25)
				desc.Size = UDim2.new(1, -150, 0, 28)
				desc.BackgroundTransparency = 1
				desc.TextColor3 = THEME.TextSub
				desc.TextXAlignment = Enum.TextXAlignment.Left
				desc.TextWrapped = true
				desc.Font = Enum.Font.Gotham
				desc.TextSize = 11
				desc.ZIndex = 23

				local buyBtn = Instance.new("TextButton", card)
				buyBtn.AnchorPoint = Vector2.new(1, 0.5)
				buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
				buyBtn.Size = UDim2.fromOffset(126, 38)
				buyBtn.BackgroundColor3 = Color3.fromRGB(36, 40, 56)
				buyBtn.TextColor3 = THEME.TextMain
				buyBtn.Font = Enum.Font.GothamBlack
				buyBtn.TextSize = 12
				buyBtn.AutoButtonColor = true
				buyBtn.ZIndex = 23
				Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)

				-- Collegato UNA SOLA VOLTA: mai interrotto dai refresh di rete
				buyBtn.MouseButton1Click:Connect(function()
					local now = os.clock()
					if now - lastActionClock < 0.08 then return end
					lastActionClock = now
					remotes.BuyUpgrade:FireServer(u.Id)
				end)

				table.insert(charCardRefs, {
					Config = u,
					Card = card,
					Title = title,
					Desc = desc,
					BuyBtn = buyBtn,
				})
			end

		elseif activeTab == "Wisps" then
			local lockLbl = Instance.new("TextLabel", scroll)
			lockLbl.LayoutOrder = 0
			lockLbl.Size = UDim2.new(1, -6, 0, 72)
			lockLbl.BackgroundColor3 = THEME.Card
			lockLbl.Text = "🔒 Sblocca 'Evocazione Spiriti' nella scheda Personaggio!"
			lockLbl.TextColor3 = THEME.Gold
			lockLbl.Font = Enum.Font.GothamBold
			lockLbl.TextWrapped = true
			lockLbl.TextSize = 13
			lockLbl.Visible = false
			lockLbl.ZIndex = 22
			Instance.new("UICorner", lockLbl).CornerRadius = UDim.new(0, 10)
			wispLockRef = lockLbl

			local sumCard = Instance.new("Frame", scroll)
			sumCard.LayoutOrder = 1
			sumCard.Size = UDim2.new(1, -6, 0, 62)
			sumCard.BackgroundColor3 = THEME.Card
			sumCard.ZIndex = 22
			Instance.new("UICorner", sumCard).CornerRadius = UDim.new(0, 10)

			local sumInfo = Instance.new("TextLabel", sumCard)
			sumInfo.Position = UDim2.fromOffset(12, 8)
			sumInfo.Size = UDim2.new(0.48, 0, 0, 46)
			sumInfo.BackgroundTransparency = 1
			sumInfo.TextColor3 = THEME.TextMain
			sumInfo.TextXAlignment = Enum.TextXAlignment.Left
			sumInfo.TextWrapped = true
			sumInfo.Font = Enum.Font.GothamBold
			sumInfo.TextSize = 11
			sumInfo.ZIndex = 23

			local btn1 = Instance.new("TextButton", sumCard)
			btn1.Position = UDim2.new(0.52, 0, 0.5, -19)
			btn1.Size = UDim2.new(0.22, 0, 0, 38)
			btn1.Text = "Evoca x1 (" .. NumberFormat.Format(GameConfig.BaseWispCost) .. ")"
			btn1.Font = Enum.Font.GothamBold
			btn1.TextSize = 11
			btn1.ZIndex = 23
			Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 8)
			btn1.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(1)
			end)

			local cost5 = GameConfig.BaseWispCost * 5
			local btn5 = Instance.new("TextButton", sumCard)
			btn5.Position = UDim2.new(0.76, 0, 0.5, -19)
			btn5.Size = UDim2.new(0.22, 0, 0, 38)
			btn5.Text = "Evoca x5 (" .. NumberFormat.Format(cost5) .. ")"
			btn5.Font = Enum.Font.GothamBold
			btn5.TextSize = 11
			btn5.ZIndex = 23
			Instance.new("UICorner", btn5).CornerRadius = UDim.new(0, 8)
			btn5.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(5)
			end)

			wispHeaderRefs = { Card = sumCard, Info = sumInfo, Btn1 = btn1, Btn5 = btn5 }

			for idx, w in ipairs(GameConfig.Wisps) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = idx + 1
				row.Size = UDim2.new(1, -6, 0, 50)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local lbl = Instance.new("TextLabel", row)
				lbl.Position = UDim2.fromOffset(12, 6)
				lbl.Size = UDim2.new(1, -150, 0, 38)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = w.Color
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 12
				lbl.ZIndex = 23

				local fuseBtn = Instance.new("TextButton", row)
				fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
				fuseBtn.Position = UDim2.new(1, -10, 0.5, 0)
				fuseBtn.Size = UDim2.fromOffset(126, 34)
				fuseBtn.TextColor3 = THEME.TextMain
				fuseBtn.Font = Enum.Font.GothamBold
				fuseBtn.TextSize = 11
				fuseBtn.ZIndex = 23
				Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 8)
				fuseBtn.MouseButton1Click:Connect(function()
					remotes.FuseWisp:FireServer(w.Id)
				end)

				table.insert(wispRowRefs, { Config = w, Row = row, Label = lbl, FuseBtn = fuseBtn })
			end

		elseif activeTab == "Alba" then
			local pCard = Instance.new("Frame", scroll)
			pCard.LayoutOrder = 1
			pCard.Size = UDim2.new(1, -6, 0, 68)
			pCard.BackgroundColor3 = THEME.Card
			pCard.ZIndex = 22
			Instance.new("UICorner", pCard).CornerRadius = UDim.new(0, 10)

			local pInfo = Instance.new("TextLabel", pCard)
			pInfo.Position = UDim2.fromOffset(12, 8)
			pInfo.Size = UDim2.new(1, -165, 0, 52)
			pInfo.BackgroundTransparency = 1
			pInfo.TextColor3 = THEME.Gold
			pInfo.TextXAlignment = Enum.TextXAlignment.Left
			pInfo.TextWrapped = true
			pInfo.Font = Enum.Font.GothamBold
			pInfo.TextSize = 12
			pInfo.ZIndex = 23

			local pBtn = Instance.new("TextButton", pCard)
			pBtn.AnchorPoint = Vector2.new(1, 0.5)
			pBtn.Position = UDim2.new(1, -10, 0.5, 0)
			pBtn.Size = UDim2.fromOffset(140, 42)
			pBtn.Font = Enum.Font.GothamBlack
			pBtn.TextSize = 12
			pBtn.ZIndex = 23
			Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 8)
			pBtn.MouseButton1Click:Connect(function()
				remotes.Prestige:FireServer()
			end)

			local perksList = {}
			for idx, sp in ipairs(GameConfig.StarPerks) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = idx + 1
				row.Size = UDim2.new(1, -6, 0, 54)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local lbl = Instance.new("TextLabel", row)
				lbl.Position = UDim2.fromOffset(12, 6)
				lbl.Size = UDim2.new(1, -150, 0, 42)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = THEME.TextMain
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 11
				lbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -10, 0.5, 0)
				b.Size = UDim2.fromOffset(126, 36)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 12
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				b.MouseButton1Click:Connect(function()
					remotes.BuyStarPerk:FireServer(sp.Id)
				end)

				table.insert(perksList, { Config = sp, Label = lbl, Btn = b })
			end

			albaRefs = { Info = pInfo, PrestigeBtn = pBtn, Perks = perksList }

		elseif activeTab == "Codes" then
			local cCard = Instance.new("Frame", scroll)
			cCard.Size = UDim2.new(1, -6, 0, 108)
			cCard.BackgroundColor3 = THEME.Card
			cCard.ZIndex = 22
			Instance.new("UICorner", cCard).CornerRadius = UDim.new(0, 10)

			local box = Instance.new("TextBox", cCard)
			box.Position = UDim2.fromOffset(14, 14)
			box.Size = UDim2.new(1, -160, 0, 38)
			box.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
			box.PlaceholderText = "Codice (es. LUCE100)"
			box.Text = ""
			box.TextColor3 = THEME.TextMain
			box.Font = Enum.Font.GothamBold
			box.TextSize = 13
			box.ZIndex = 23
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

			local statusLbl = Instance.new("TextLabel", cCard)
			statusLbl.Position = UDim2.fromOffset(14, 62)
			statusLbl.Size = UDim2.new(1, -28, 0, 32)
			statusLbl.BackgroundTransparency = 1
			statusLbl.Text = "Codici attivi: LUCE100, FIAMMA, ALBA2026"
			statusLbl.TextColor3 = THEME.TextSub
			statusLbl.TextXAlignment = Enum.TextXAlignment.Left
			statusLbl.Font = Enum.Font.Gotham
			statusLbl.TextSize = 12
			statusLbl.ZIndex = 23

			local redeemBtn = Instance.new("TextButton", cCard)
			redeemBtn.AnchorPoint = Vector2.new(1, 0)
			redeemBtn.Position = UDim2.new(1, -14, 0, 14)
			redeemBtn.Size = UDim2.fromOffset(126, 38)
			redeemBtn.BackgroundColor3 = THEME.Green
			redeemBtn.Text = "RISCATTA"
			redeemBtn.TextColor3 = Color3.fromRGB(16, 18, 24)
			redeemBtn.Font = Enum.Font.GothamBlack
			redeemBtn.TextSize = 12
			redeemBtn.ZIndex = 23
			Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 8)

			redeemBtn.MouseButton1Click:Connect(function()
				local ok, msg = remotes.RedeemCode:InvokeServer(box.Text)
				statusLbl.Text = tostring(msg)
				statusLbl.TextColor3 = ok and THEME.Green or Color3.fromRGB(255, 110, 120)
				if ok then box.Text = "" end
			end)
		end

		refreshExistingWidgets()
	end

	for id, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			activeTab = id
			buildTabStructure()
		end)
	end

	local function setOpen(val)
		isOpen = val
		modal.Visible = isOpen
		if isOpen then
			if renderedTab ~= activeTab then
				buildTabStructure()
			else
				refreshExistingWidgets()
			end
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
	victoryModal.Size = UDim2.fromOffset(440, 230)
	victoryModal.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
	victoryModal.Visible = false
	victoryModal.ZIndex = 40
	Instance.new("UICorner", victoryModal).CornerRadius = UDim.new(0, 18)

	local vStroke = Instance.new("UIStroke", victoryModal)
	vStroke.Color = THEME.Gold
	vStroke.Thickness = 2.4

	local vHead = Instance.new("TextLabel", victoryModal)
	vHead.Position = UDim2.fromOffset(16, 18)
	vHead.Size = UDim2.new(1, -32, 0, 34)
	vHead.BackgroundTransparency = 1
	vHead.Text = "👑 VITTORIA SUPREMA!"
	vHead.TextColor3 = THEME.Gold
	vHead.Font = Enum.Font.GothamBlack
	vHead.TextSize = 20
	vHead.ZIndex = 41

	local vBody = Instance.new("TextLabel", victoryModal)
	vBody.Position = UDim2.fromOffset(20, 62)
	vBody.Size = UDim2.new(1, -40, 0, 96)
	vBody.BackgroundTransparency = 1
	vBody.Text = "Hai completato tutti i potenziamenti e acceso la Fiamma Suprema!\nPuoi continuare ad esplorare quando vuoi."
	vBody.TextColor3 = THEME.TextMain
	vBody.TextWrapped = true
	vBody.Font = Enum.Font.Gotham
	vBody.TextSize = 13
	vBody.ZIndex = 41

	local vClose = Instance.new("TextButton", victoryModal)
	vClose.AnchorPoint = Vector2.new(0.5, 1)
	vClose.Position = UDim2.new(0.5, 0, 1, -18)
	vClose.Size = UDim2.fromOffset(190, 38)
	vClose.BackgroundColor3 = THEME.Gold
	vClose.Text = "CONTINUA A GIOCARE"
	vClose.TextColor3 = Color3.fromRGB(16, 18, 24)
	vClose.Font = Enum.Font.GothamBlack
	vClose.TextSize = 12
	vClose.ZIndex = 41
	Instance.new("UICorner", vClose).CornerRadius = UDim.new(0, 10)
	vClose.MouseButton1Click:Connect(function()
		victoryModal.Visible = false
	end)

	return {
		Update = function(st)
			latestState = st
			if st.HasDoubleLight then
				dockBoostBtn.Text = "✅ LUCE x2 ATTIVA"
				dockBoostBtn.TextColor3 = THEME.Green
				dockBoostStroke.Color = THEME.Green
			end

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
				if renderedTab ~= activeTab then
					buildTabStructure()
				else
					refreshExistingWidgets()
				end
			end
		end,
		ShowVictory = function()
			victoryModal.Visible = true
		end,
	}
end

return ShopUI