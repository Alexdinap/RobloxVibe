local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local ShopUI = {}

local THEME = {
	PanelBg = Color3.fromRGB(14, 15, 22),
	TileLocked = Color3.fromRGB(25, 27, 38),
	TileReady = Color3.fromRGB(36, 28, 18),
	TileMax = Color3.fromRGB(18, 38, 30),
	Gold = Color3.fromRGB(255, 185, 60),
	Cyan = Color3.fromRGB(80, 225, 255),
	Green = Color3.fromRGB(55, 205, 130),
	Purple = Color3.fromRGB(165, 80, 235),
	TextMain = Color3.fromRGB(248, 248, 252),
	TextSub = Color3.fromRGB(175, 182, 202),
}

function ShopUI.Build(parentGui, remotes, popupManager, onMuteToggle)
	local localPlayer = Players.LocalPlayer
	local activeTab = "Flame"
	local unlockedSet = {} -- traccia quali bottoni sono già comparsi per animarli all'ingresso
	local isOpen = false   -- parte chiuso/retratto così non occupa il centro dello schermo

	local passCfg = GameConfig.RobuxPasses and GameConfig.RobuxPasses.DoubleLight or {
		GamePassId = 0,
		Name = "Luce x2 Permanente",
		Tag = "x2 PUNTI LUCE",
		Desc = "Raddoppia per sempre tutti i Punti Luce prodotti!",
		PriceLabel = "Robux",
		Multiplier = 2.0,
	}
	local hasDoubleLight = false
	local autoPromptShown = false

	local POS_PANEL_OPEN = UDim2.new(1, -12, 0.54, 0)
	local POS_PANEL_CLOSED = UDim2.new(1, 20, 0.54, 0)
	local POS_TOGGLE_SHOWN = UDim2.new(1, -12, 0.54, 0)
	local POS_TOGGLE_HIDDEN = UDim2.new(1, 220, 0.54, 0)

	-- Contenitore retratto sul bordo destro (Pulsante Negozio + Pillola x2 Robux)
	local dockedDock = Instance.new("Frame", parentGui)
	dockedDock.Name = "ShopDockedContainer"
	dockedDock.AnchorPoint = Vector2.new(1, 0.5)
	dockedDock.Position = POS_TOGGLE_SHOWN
	dockedDock.Size = UDim2.fromOffset(172, 92)
	dockedDock.BackgroundTransparency = 1
	dockedDock.ZIndex = 15

	-- Linguetta / Pulsante retratto per aprire il menù potenziamenti
	local toggleBtn = Instance.new("TextButton", dockedDock)
	toggleBtn.Name = "ShopToggleButton"
	toggleBtn.AnchorPoint = Vector2.new(1, 0)
	toggleBtn.Position = UDim2.new(1, 0, 0, 0)
	toggleBtn.Size = UDim2.fromOffset(172, 46)
	toggleBtn.BackgroundColor3 = THEME.PanelBg
	toggleBtn.BackgroundTransparency = 0.08
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = false
	toggleBtn.ZIndex = 15
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = THEME.Gold
	toggleStroke.Transparency = 0.45
	toggleStroke.Thickness = 1.6

	local toggleIcon = Instance.new("TextLabel", toggleBtn)
	toggleIcon.Size = UDim2.fromOffset(30, 30)
	toggleIcon.Position = UDim2.fromOffset(8, 8)
	toggleIcon.BackgroundColor3 = Color3.fromRGB(32, 34, 48)
	toggleIcon.Text = "⚡"
	toggleIcon.TextScaled = true
	toggleIcon.ZIndex = 16
	Instance.new("UICorner", toggleIcon).CornerRadius = UDim.new(0, 9)

	local toggleLabel = Instance.new("TextLabel", toggleBtn)
	toggleLabel.Size = UDim2.new(1, -46, 0, 20)
	toggleLabel.Position = UDim2.fromOffset(42, 6)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = "POTENZIAMENTI"
	toggleLabel.TextColor3 = THEME.TextMain
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Font = Enum.Font.GothamBlack
	toggleLabel.TextScaled = true
	toggleLabel.ZIndex = 16

	local toggleSub = Instance.new("TextLabel", toggleBtn)
	toggleSub.Size = UDim2.new(1, -46, 0, 14)
	toggleSub.Position = UDim2.fromOffset(42, 26)
	toggleSub.BackgroundTransparency = 1
	toggleSub.Text = "Apri Negozio [B]"
	toggleSub.TextColor3 = THEME.TextSub
	toggleSub.TextXAlignment = Enum.TextXAlignment.Left
	toggleSub.Font = Enum.Font.GothamBold
	toggleSub.TextScaled = true
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
	readyBadge.TextScaled = true
	readyBadge.Visible = false
	readyBadge.ZIndex = 17
	Instance.new("UICorner", readyBadge).CornerRadius = UDim.new(1, 0)

	-- Pulsante compatto sul bordo destro per aprire il Pop-up x2 Robux
	local dockBoostBtn = Instance.new("TextButton", dockedDock)
	dockBoostBtn.Name = "DoubleLightDockButton"
	dockBoostBtn.AnchorPoint = Vector2.new(1, 0)
	dockBoostBtn.Position = UDim2.new(1, 0, 0, 52)
	dockBoostBtn.Size = UDim2.fromOffset(172, 36)
	dockBoostBtn.BackgroundColor3 = Color3.fromRGB(36, 28, 16)
	dockBoostBtn.BackgroundTransparency = 0.06
	dockBoostBtn.Text = "⚡ LUCE x2 (ROBUX)"
	dockBoostBtn.TextColor3 = THEME.Gold
	dockBoostBtn.Font = Enum.Font.GothamBlack
	dockBoostBtn.TextScaled = true
	dockBoostBtn.ZIndex = 15
	Instance.new("UICorner", dockBoostBtn).CornerRadius = UDim.new(0, 12)

	local dockBoostStroke = Instance.new("UIStroke", dockBoostBtn)
	dockBoostStroke.Color = THEME.Gold
	dockBoostStroke.Transparency = 0.3
	dockBoostStroke.Thickness = 1.5

	-- =========================================================================
	-- POP-UP ACQUISTO x2 ROBUX (Modale centrata e chiudibile)
	-- =========================================================================
	local popupOverlay = Instance.new("TextButton", parentGui)
	popupOverlay.Name = "DoubleLightPopupOverlay"
	popupOverlay.Size = UDim2.fromScale(1, 1)
	popupOverlay.BackgroundColor3 = Color3.fromRGB(6, 7, 12)
	popupOverlay.BackgroundTransparency = 0.42
	popupOverlay.Text = ""
	popupOverlay.AutoButtonColor = false
	popupOverlay.Visible = false
	popupOverlay.ZIndex = 40

	local popupCard = Instance.new("Frame", popupOverlay)
	popupCard.Name = "DoubleLightCard"
	popupCard.AnchorPoint = Vector2.new(0.5, 0.5)
	popupCard.Position = UDim2.fromScale(0.5, 0.5)
	popupCard.Size = UDim2.fromOffset(350, 268)
	popupCard.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
	popupCard.ZIndex = 41
	Instance.new("UICorner", popupCard).CornerRadius = UDim.new(0, 20)

	local cardStroke = Instance.new("UIStroke", popupCard)
	cardStroke.Color = THEME.Gold
	cardStroke.Thickness = 2.2

	local cardScale = Instance.new("UIScale", popupCard)
	cardScale.Scale = 1.0

	local popupCloseBtn = Instance.new("TextButton", popupCard)
	popupCloseBtn.AnchorPoint = Vector2.new(1, 0)
	popupCloseBtn.Position = UDim2.new(1, -12, 0, 12)
	popupCloseBtn.Size = UDim2.fromOffset(30, 30)
	popupCloseBtn.BackgroundColor3 = Color3.fromRGB(34, 36, 52)
	popupCloseBtn.Text = "✕"
	popupCloseBtn.TextColor3 = THEME.TextMain
	popupCloseBtn.Font = Enum.Font.GothamBlack
	popupCloseBtn.TextScaled = true
	popupCloseBtn.ZIndex = 43
	Instance.new("UICorner", popupCloseBtn).CornerRadius = UDim.new(0, 9)

	local popupIconBg = Instance.new("TextLabel", popupCard)
	popupIconBg.AnchorPoint = Vector2.new(0.5, 0)
	popupIconBg.Position = UDim2.new(0.5, 0, 0, 16)
	popupIconBg.Size = UDim2.fromOffset(58, 58)
	popupIconBg.BackgroundColor3 = Color3.fromRGB(42, 32, 16)
	popupIconBg.Text = "⚡🔥"
	popupIconBg.TextScaled = true
	popupIconBg.ZIndex = 42
	Instance.new("UICorner", popupIconBg).CornerRadius = UDim.new(0, 16)

	local popupIconStroke = Instance.new("UIStroke", popupIconBg)
	popupIconStroke.Color = THEME.Gold
	popupIconStroke.Thickness = 1.6

	local popupTitle = Instance.new("TextLabel", popupCard)
	popupTitle.Size = UDim2.new(1, -32, 0, 28)
	popupTitle.Position = UDim2.fromOffset(16, 82)
	popupTitle.BackgroundTransparency = 1
	popupTitle.Text = string.upper(passCfg.Name)
	popupTitle.TextColor3 = THEME.Gold
	popupTitle.Font = Enum.Font.GothamBlack
	popupTitle.TextScaled = true
	popupTitle.ZIndex = 42

	local popupDesc = Instance.new("TextLabel", popupCard)
	popupDesc.Size = UDim2.new(1, -36, 0, 56)
	popupDesc.Position = UDim2.fromOffset(18, 114)
	popupDesc.BackgroundTransparency = 1
	popupDesc.Text = passCfg.Desc
	popupDesc.TextColor3 = THEME.TextSub
	popupDesc.Font = Enum.Font.GothamMedium
	popupDesc.TextSize = 14
	popupDesc.TextWrapped = true
	popupDesc.TextYAlignment = Enum.TextYAlignment.Top
	popupDesc.ZIndex = 42

	local popupBuyBtn = Instance.new("TextButton", popupCard)
	popupBuyBtn.Name = "BuyDoubleLightRobuxBtn"
	popupBuyBtn.Size = UDim2.new(1, -36, 0, 44)
	popupBuyBtn.Position = UDim2.fromOffset(18, 176)
	popupBuyBtn.BackgroundColor3 = THEME.Green
	popupBuyBtn.Text = "💎 COMPRA x2 (" .. (passCfg.PriceLabel or "Robux") .. ")"
	popupBuyBtn.TextColor3 = Color3.fromRGB(14, 22, 18)
	popupBuyBtn.Font = Enum.Font.GothamBlack
	popupBuyBtn.TextScaled = true
	popupBuyBtn.ZIndex = 42
	Instance.new("UICorner", popupBuyBtn).CornerRadius = UDim.new(0, 12)

	local popupLaterBtn = Instance.new("TextButton", popupCard)
	popupLaterBtn.Size = UDim2.new(1, -36, 0, 26)
	popupLaterBtn.Position = UDim2.fromOffset(18, 226)
	popupLaterBtn.BackgroundTransparency = 1
	popupLaterBtn.Text = "Non ora"
	popupLaterBtn.TextColor3 = THEME.TextSub
	popupLaterBtn.Font = Enum.Font.GothamBold
	popupLaterBtn.TextSize = 13
	popupLaterBtn.ZIndex = 42

	local headerBoostBtn -- dichiarato qui per aggiornarlo insieme agli altri

	local function refreshDoubleLightVisuals()
		if hasDoubleLight then
			dockBoostBtn.BackgroundColor3 = THEME.TileMax
			dockBoostBtn.Text = "✓ LUCE x2 ATTIVA"
			dockBoostBtn.TextColor3 = THEME.Green
			dockBoostStroke.Color = THEME.Green

			if headerBoostBtn then
				headerBoostBtn.BackgroundColor3 = THEME.TileMax
				headerBoostBtn.Text = "✓ x2"
				headerBoostBtn.TextColor3 = THEME.Green
			end

			popupBuyBtn.BackgroundColor3 = THEME.TileMax
			popupBuyBtn.Text = "✓ POTENZIAMENTO x2 GIÀ ATTIVO"
			popupBuyBtn.TextColor3 = THEME.Green
		else
			dockBoostBtn.BackgroundColor3 = Color3.fromRGB(36, 28, 16)
			dockBoostBtn.Text = "⚡ LUCE x2 (ROBUX)"
			dockBoostBtn.TextColor3 = THEME.Gold
			dockBoostStroke.Color = THEME.Gold

			if headerBoostBtn then
				headerBoostBtn.BackgroundColor3 = Color3.fromRGB(48, 36, 16)
				headerBoostBtn.Text = "⚡ x2"
				headerBoostBtn.TextColor3 = THEME.Gold
			end

			popupBuyBtn.BackgroundColor3 = THEME.Green
			popupBuyBtn.Text = "💎 COMPRA x2 (" .. (passCfg.PriceLabel or "Robux") .. ")"
			popupBuyBtn.TextColor3 = Color3.fromRGB(14, 22, 18)
		end
	end

	local function openDoubleLightPopup()
		refreshDoubleLightVisuals()
		popupOverlay.Visible = true
		cardScale.Scale = 0.82
		TweenService:Create(cardScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.0,
		}):Play()
	end

	local function closeDoubleLightPopup()
		popupOverlay.Visible = false
	end

	dockBoostBtn.MouseButton1Click:Connect(openDoubleLightPopup)
	popupCloseBtn.MouseButton1Click:Connect(closeDoubleLightPopup)
	popupLaterBtn.MouseButton1Click:Connect(closeDoubleLightPopup)
	popupOverlay.MouseButton1Click:Connect(closeDoubleLightPopup)

	popupBuyBtn.MouseButton1Click:Connect(function()
		if hasDoubleLight then
			closeDoubleLightPopup()
			return
		end
		local passId = passCfg.GamePassId or 0
		if passId <= 0 then
			if popupManager then
				popupManager:ShowEvent("Imposta GamePassId in GameConfig.lua!", THEME.Gold)
			end
			return
		end
		local ok, err = pcall(function()
			MarketplaceService:PromptGamePassPurchase(localPlayer, passId)
		end)
		if not ok and popupManager then
			popupManager:ShowEvent("Acquisto non disponibile: " .. tostring(err), THEME.Gold)
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if player == localPlayer and gamePassId == (passCfg.GamePassId or 0) and wasPurchased then
			hasDoubleLight = true
			refreshDoubleLightVisuals()
			closeDoubleLightPopup()
			if popupManager then
				popupManager:ShowEvent("⚡ LUCE x2 PERMANENTE ATTIVATA!", THEME.Gold)
			end
			if remotes and remotes.SyncGamePass then
				remotes.SyncGamePass:FireServer(gamePassId)
			end
		end
	end)

	-- Controllo iniziale se il giocatore possiede già il GamePass
	task.spawn(function()
		local passId = passCfg.GamePassId or 0
		if passId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, passId)
			end)
			if ok and owns then
				hasDoubleLight = true
				refreshDoubleLightVisuals()
			end
		end
	end)

	-- =========================================================================
	-- PANNELLO LATERALE COMPASSATO E RETRAIBILE
	-- =========================================================================
	local panel = Instance.new("Frame", parentGui)
	panel.Name = "ProgressiveShopPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = POS_PANEL_CLOSED
	panel.Size = UDim2.new(0, 355, 0.74, 0)
	panel.BackgroundColor3 = THEME.PanelBg
	panel.BackgroundTransparency = 0.08
	panel.Visible = false
	panel.ZIndex = 12
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

	local pStroke = Instance.new("UIStroke", panel)
	pStroke.Color = THEME.Gold
	pStroke.Transparency = 0.55
	pStroke.Thickness = 1.5

	local animToken = 0
	local function setShopOpen(openState)
		if isOpen == openState then
			return
		end
		isOpen = openState
		animToken += 1
		local currentToken = animToken

		local tweenInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		if isOpen then
			panel.Visible = true
			TweenService:Create(panel, tweenInfo, { Position = POS_PANEL_OPEN }):Play()
			TweenService:Create(dockedDock, tweenInfo, { Position = POS_TOGGLE_HIDDEN }):Play()
			task.delay(0.25, function()
				if animToken == currentToken and isOpen then
					dockedDock.Visible = false
				end
			end)
		else
			dockedDock.Visible = true
			TweenService:Create(panel, tweenInfo, { Position = POS_PANEL_CLOSED }):Play()
			TweenService:Create(dockedDock, tweenInfo, { Position = POS_TOGGLE_SHOWN }):Play()
			task.delay(0.25, function()
				if animToken == currentToken and not isOpen then
					panel.Visible = false
				end
			end)
		end
	end

	toggleBtn.MouseButton1Click:Connect(function()
		setShopOpen(true)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			setShopOpen(not isOpen)
		end
	end)

	-- Intestazione con contatore bottoni scoperti, bottone x2 Robux e pulsante chiudi/retrai
	local header = Instance.new("Frame", panel)
	header.Size = UDim2.new(1, -24, 0, 32)
	header.Position = UDim2.fromOffset(12, 10)
	header.BackgroundTransparency = 1

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Size = UDim2.new(0.42, 0, 1, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "⚡ POTENZIAMENTI"
	headerTitle.TextColor3 = THEME.TextMain
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextScaled = true

	local discoveryBadge = Instance.new("TextLabel", header)
	discoveryBadge.Size = UDim2.new(0.29, 0, 0.78, 0)
	discoveryBadge.Position = UDim2.new(0.43, 0, 0.11, 0)
	discoveryBadge.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
	discoveryBadge.Text = "1/" .. #GameConfig.Upgrades
	discoveryBadge.TextColor3 = THEME.Gold
	discoveryBadge.Font = Enum.Font.GothamBold
	discoveryBadge.TextScaled = true
	Instance.new("UICorner", discoveryBadge).CornerRadius = UDim.new(1, 0)

	headerBoostBtn = Instance.new("TextButton", header)
	headerBoostBtn.Name = "HeaderDoubleLightBtn"
	headerBoostBtn.AnchorPoint = Vector2.new(1, 0.5)
	headerBoostBtn.Position = UDim2.new(1, -36, 0.5, 0)
	headerBoostBtn.Size = UDim2.fromOffset(48, 28)
	headerBoostBtn.BackgroundColor3 = Color3.fromRGB(48, 36, 16)
	headerBoostBtn.Text = "⚡ x2"
	headerBoostBtn.TextColor3 = THEME.Gold
	headerBoostBtn.Font = Enum.Font.GothamBlack
	headerBoostBtn.TextScaled = true
	Instance.new("UICorner", headerBoostBtn).CornerRadius = UDim.new(0, 8)
	headerBoostBtn.MouseButton1Click:Connect(openDoubleLightPopup)

	local closeBtn = Instance.new("TextButton", header)
	closeBtn.Name = "CollapseShopButton"
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(30, 30)
	closeBtn.BackgroundColor3 = Color3.fromRGB(34, 36, 52)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = THEME.TextMain
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextScaled = true
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 9)
	closeBtn.MouseButton1Click:Connect(function()
		setShopOpen(false)
	end)

	-- Barra delle Schede (anch'esse compaiono man mano che le sblocchi!)
	local tabStrip = Instance.new("Frame", panel)
	tabStrip.Size = UDim2.new(1, -24, 0, 34)
	tabStrip.Position = UDim2.fromOffset(12, 46)
	tabStrip.BackgroundTransparency = 1

	local tabLayout = Instance.new("UIListLayout", tabStrip)
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 6)
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

	local tabDefs = {
		{ Id = "Flame", Label = "🔥 Fiamma", Color = THEME.Gold },
		{ Id = "World", Label = "🌍 Regni", Color = THEME.Green },
		{ Id = "Wisps", Label = "✨ Spiriti", Color = THEME.Cyan },
		{ Id = "Alba", Label = "🌅 Alba", Color = THEME.Purple },
	}

	local tabButtons = {}
	local pages = {}

	local function selectTab(id)
		activeTab = id
		for tId, btn in pairs(tabButtons) do
			local on = (tId == id)
			btn.BackgroundColor3 = on and btn:GetAttribute("AccentColor") or Color3.fromRGB(26, 28, 40)
			btn.TextColor3 = on and Color3.fromRGB(16, 16, 22) or THEME.TextSub
		end
		for pId, pg in pairs(pages) do
			pg.Visible = (pId == id)
		end
	end

	for _, td in ipairs(tabDefs) do
		local tb = Instance.new("TextButton", tabStrip)
		tb.Size = UDim2.new(0.235, 0, 1, 0)
		tb.BackgroundColor3 = Color3.fromRGB(26, 28, 40)
		tb.Text = td.Label
		tb.TextColor3 = THEME.TextSub
		tb.Font = Enum.Font.GothamBlack
		tb.TextScaled = true
		tb.Visible = (td.Id == "Flame") -- All'inizio è visibile solo la scheda Fiamma!
		tb:SetAttribute("AccentColor", td.Color)
		Instance.new("UICorner", tb).CornerRadius = UDim.new(1, 0)
		tb.MouseButton1Click:Connect(function() selectTab(td.Id) end)
		tabButtons[td.Id] = tb

		local pg = Instance.new("Frame", panel)
		pg.Size = UDim2.new(1, -24, 1, -94)
		pg.Position = UDim2.fromOffset(12, 86)
		pg.BackgroundTransparency = 1
		pg.Visible = false
		pages[td.Id] = pg
	end

	-- Griglia a 2 Colonne per i Bottoni a Comparsa Progressiva ("Flame" e "World") con Descrizioni
	local tileMap = {}
	local function createTileGrid(parentPage, category)
		local scroll = Instance.new("ScrollingFrame", parentPage)
		scroll.Size = UDim2.fromScale(1, 1)
		scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = THEME.Gold
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.CanvasSize = UDim2.fromOffset(0, 0)

		local grid = Instance.new("UIGridLayout", scroll)
		grid.CellSize = UDim2.new(0.482, 0, 0, 140)
		grid.CellPadding = UDim2.new(0.036, 0, 0, 10)
		grid.SortOrder = Enum.SortOrder.LayoutOrder

		for _, u in ipairs(GameConfig.Upgrades) do
			if u.Category == category then
				local tile = Instance.new("TextButton", scroll)
				tile.Name = u.Id
				tile.LayoutOrder = u.Order
				tile.BackgroundColor3 = THEME.TileLocked
				tile.Text = ""
				tile.AutoButtonColor = false
				tile.Visible = (u.ReqId == nil)
				Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 14)

				local stroke = Instance.new("UIStroke", tile)
				stroke.Color = Color3.fromRGB(52, 56, 76)
				stroke.Thickness = 1.6

				local scale = Instance.new("UIScale", tile)
				scale.Scale = 1.0

				-- Badge Icona in alto a sinistra
				local iconBadge = Instance.new("TextLabel", tile)
				iconBadge.Size = UDim2.fromOffset(28, 28)
				iconBadge.Position = UDim2.fromOffset(8, 8)
				iconBadge.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
				iconBadge.Text = u.Icon
				iconBadge.TextScaled = true
				Instance.new("UICorner", iconBadge).CornerRadius = UDim.new(0, 8)

				-- Pillola Livello in alto a destra
				local lvlPill = Instance.new("TextLabel", tile)
				lvlPill.AnchorPoint = Vector2.new(1, 0)
				lvlPill.Position = UDim2.new(1, -8, 0, 10)
				lvlPill.Size = UDim2.fromOffset(62, 20)
				lvlPill.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
				lvlPill.Text = "Lv. 0/" .. u.MaxLevel
				lvlPill.TextColor3 = THEME.TextSub
				lvlPill.Font = Enum.Font.GothamBold
				lvlPill.TextScaled = true
				Instance.new("UICorner", lvlPill).CornerRadius = UDim.new(1, 0)

				-- Nome Potenziamento
				local titleLbl = Instance.new("TextLabel", tile)
				titleLbl.Size = UDim2.new(1, -16, 0, 18)
				titleLbl.Position = UDim2.fromOffset(8, 40)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = u.Name
				titleLbl.TextColor3 = THEME.TextMain
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.Font = Enum.Font.GothamBlack
				titleLbl.TextScaled = true

				-- Effetto numerico sintetico
				local tagLbl = Instance.new("TextLabel", tile)
				tagLbl.Size = UDim2.new(1, -16, 0, 14)
				tagLbl.Position = UDim2.fromOffset(8, 58)
				tagLbl.BackgroundTransparency = 1
				tagLbl.Text = u.Tag
				tagLbl.TextColor3 = THEME.Cyan
				tagLbl.TextXAlignment = Enum.TextXAlignment.Left
				tagLbl.Font = Enum.Font.GothamBold
				tagLbl.TextScaled = true

				-- Descrizione dettagliata del potenziamento
				local descLbl = Instance.new("TextLabel", tile)
				descLbl.Size = UDim2.new(1, -16, 0, 32)
				descLbl.Position = UDim2.fromOffset(8, 74)
				descLbl.BackgroundTransparency = 1
				descLbl.Text = u.Desc or ""
				descLbl.TextColor3 = THEME.TextSub
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextYAlignment = Enum.TextYAlignment.Top
				descLbl.Font = Enum.Font.GothamMedium
				descLbl.TextSize = 11
				descLbl.TextWrapped = true

				-- Pillola Costo in basso (tutta larghezza)
				local costPill = Instance.new("Frame", tile)
				costPill.Size = UDim2.new(1, -16, 0, 22)
				costPill.Position = UDim2.new(0, 8, 1, -28)
				costPill.BackgroundColor3 = Color3.fromRGB(34, 37, 52)
				costPill.ClipsDescendants = true
				Instance.new("UICorner", costPill).CornerRadius = UDim.new(0, 8)

				local progFill = Instance.new("Frame", costPill)
				progFill.Size = UDim2.fromScale(0, 1)
				progFill.BackgroundColor3 = THEME.Gold
				progFill.BackgroundTransparency = 0.72
				progFill.BorderSizePixel = 0

				local costTxt = Instance.new("TextLabel", costPill)
				costTxt.Size = UDim2.fromScale(1, 1)
				costTxt.BackgroundTransparency = 1
				costTxt.Text = "🔥 " .. NumberFormat.Format(u.BaseCost)
				costTxt.TextColor3 = THEME.TextMain
				costTxt.Font = Enum.Font.GothamBlack
				costTxt.TextScaled = true

				tile.MouseButton1Click:Connect(function()
					TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.93 }):Play()
					task.delay(0.08, function()
						TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.0 }):Play()
					end)
					remotes.BuyUpgrade:FireServer(u.Id)
				end)

				if u.ReqId == nil then
					unlockedSet[u.Id] = true
				end

				tileMap[u.Id] = {
					Cfg = u,
					Tile = tile,
					Stroke = stroke,
					Scale = scale,
					LvlPill = lvlPill,
					CostPill = costPill,
					ProgFill = progFill,
					CostTxt = costTxt,
				}
			end
		end
	end

	createTileGrid(pages["Flame"], "Flame")
	createTileGrid(pages["World"], "World")

	-- Pagina Spiriti di Luce
	local pWisps = pages["Wisps"]
	local wispHeader = Instance.new("TextLabel", pWisps)
	wispHeader.Size = UDim2.new(1, 0, 0, 22)
	wispHeader.BackgroundTransparency = 1
	wispHeader.Text = "Spiriti Attivi: 0/3 (Moltiplicano i Punti Click)"
	wispHeader.TextColor3 = THEME.Cyan
	wispHeader.Font = Enum.Font.GothamBold
	wispHeader.TextScaled = true

	local wispRows = {}
	for i, w in ipairs(GameConfig.Wisps) do
		local row = Instance.new("Frame", pWisps)
		row.Size = UDim2.new(1, 0, 0, 46)
		row.Position = UDim2.fromOffset(0, 26 + (i - 1) * 51)
		row.BackgroundColor3 = THEME.TileLocked
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

		local nameLbl = Instance.new("TextLabel", row)
		nameLbl.Size = UDim2.new(0.65, 0, 0.52, 0)
		nameLbl.Position = UDim2.fromOffset(10, 3)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = w.Name .. " (" .. w.Chance .. ")"
		nameLbl.TextColor3 = w.Color
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.Font = Enum.Font.GothamBlack
		nameLbl.TextScaled = true

		local countLbl = Instance.new("TextLabel", row)
		countLbl.Size = UDim2.new(0.65, 0, 0.42, 0)
		countLbl.Position = UDim2.fromOffset(10, 24)
		countLbl.BackgroundTransparency = 1
		countLbl.Text = "Base: 0 • Radiosi: 0"
		countLbl.TextColor3 = THEME.TextSub
		countLbl.TextXAlignment = Enum.TextXAlignment.Left
		countLbl.Font = Enum.Font.GothamMedium
		countLbl.TextScaled = true

		local fuseBtn = Instance.new("TextButton", row)
		fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
		fuseBtn.Position = UDim2.new(1, -8, 0.5, 0)
		fuseBtn.Size = UDim2.fromOffset(88, 32)
		fuseBtn.BackgroundColor3 = Color3.fromRGB(36, 40, 56)
		fuseBtn.Text = "FORGIA 3→1"
		fuseBtn.TextColor3 = THEME.TextMain
		fuseBtn.Font = Enum.Font.GothamBlack
		fuseBtn.TextScaled = true
		Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 8)
		fuseBtn.MouseButton1Click:Connect(function() remotes.FuseWisp:FireServer(w.Id) end)

		wispRows[w.Id] = { Count = countLbl, Fuse = fuseBtn }
	end

	local summon1Btn = Instance.new("TextButton", pWisps)
	summon1Btn.Size = UDim2.new(0.485, 0, 0, 42)
	summon1Btn.Position = UDim2.new(0, 0, 1, -44)
	summon1Btn.BackgroundColor3 = Color3.fromRGB(40, 155, 205)
	summon1Btn.Text = "✨ Evoca x1 (" .. NumberFormat.Format(GameConfig.BaseWispCost) .. ")"
	summon1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	summon1Btn.Font = Enum.Font.GothamBlack
	summon1Btn.TextScaled = true
	Instance.new("UICorner", summon1Btn).CornerRadius = UDim.new(0, 10)
	summon1Btn.MouseButton1Click:Connect(function() remotes.SummonWisp:FireServer(1) end)

	local summon5Btn = Instance.new("TextButton", pWisps)
	summon5Btn.Size = UDim2.new(0.485, 0, 0, 42)
	summon5Btn.Position = UDim2.new(0.515, 0, 1, -44)
	summon5Btn.BackgroundColor3 = THEME.Purple
	summon5Btn.Text = "✨ Evoca x5 (" .. NumberFormat.Format(GameConfig.BaseWispCost * 5) .. ")"
	summon5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	summon5Btn.Font = Enum.Font.GothamBlack
	summon5Btn.TextScaled = true
	Instance.new("UICorner", summon5Btn).CornerRadius = UDim.new(0, 10)
	summon5Btn.MouseButton1Click:Connect(function() remotes.SummonWisp:FireServer(5) end)

	-- Pagina Grande Alba, Codici & Suoni
	local pAlba = pages["Alba"]
	local prestigeBtn = Instance.new("TextButton", pAlba)
	prestigeBtn.Size = UDim2.new(1, 0, 0, 52)
	prestigeBtn.Position = UDim2.fromOffset(0, 0)
	prestigeBtn.BackgroundColor3 = THEME.Purple
	prestigeBtn.Text = "🌅 GRANDE ALBA (50M Punti)\nStelle Eterne: 0"
	prestigeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	prestigeBtn.Font = Enum.Font.GothamBlack
	prestigeBtn.TextScaled = true
	Instance.new("UICorner", prestigeBtn).CornerRadius = UDim.new(0, 12)
	prestigeBtn.MouseButton1Click:Connect(function() remotes.Prestige:FireServer() end)

	local starButtons = {}
	for i, sp in ipairs(GameConfig.StarPerks) do
		local b = Instance.new("TextButton", pAlba)
		b.Size = UDim2.new(1, 0, 0, 40)
		b.Position = UDim2.fromOffset(0, 58 + (i - 1) * 45)
		b.BackgroundColor3 = THEME.TileLocked
		b.TextColor3 = THEME.TextMain
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
		b.MouseButton1Click:Connect(function() remotes.BuyStarPerk:FireServer(sp.Id) end)
		starButtons[sp.Id] = { Btn = b, Cfg = sp }
	end

	local codeBox = Instance.new("TextBox", pAlba)
	codeBox.Size = UDim2.new(0.66, 0, 0, 34)
	codeBox.Position = UDim2.new(0, 0, 1, -80)
	codeBox.PlaceholderText = "Codice (LUCE100, FIAMMA)"
	codeBox.Text = ""
	codeBox.BackgroundColor3 = THEME.TileLocked
	codeBox.TextColor3 = THEME.TextMain
	codeBox.Font = Enum.Font.GothamBold
	codeBox.TextScaled = true
	Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

	local codeBtn = Instance.new("TextButton", pAlba)
	codeBtn.Size = UDim2.new(0.32, 0, 0, 34)
	codeBtn.Position = UDim2.new(0.68, 0, 1, -80)
	codeBtn.BackgroundColor3 = THEME.Green
	codeBtn.Text = "RISCATTA"
	codeBtn.TextColor3 = Color3.fromRGB(16, 22, 18)
	codeBtn.Font = Enum.Font.GothamBlack
	codeBtn.TextScaled = true
	Instance.new("UICorner", codeBtn).CornerRadius = UDim.new(0, 8)
	codeBtn.MouseButton1Click:Connect(function()
		local _, msg = remotes.RedeemCode:InvokeServer(codeBox.Text)
		popupManager:ShowEvent(msg, THEME.Green)
	end)

	local muted = false
	local muteBtn = Instance.new("TextButton", pAlba)
	muteBtn.Size = UDim2.new(1, 0, 0, 34)
	muteBtn.Position = UDim2.new(0, 0, 1, -38)
	muteBtn.BackgroundColor3 = Color3.fromRGB(36, 40, 56)
	muteBtn.Text = "🔊 Suoni: Attivi"
	muteBtn.TextColor3 = THEME.TextMain
	muteBtn.Font = Enum.Font.GothamBold
	muteBtn.TextScaled = true
	Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 8)
	muteBtn.MouseButton1Click:Connect(function()
		muted = not muted
		muteBtn.Text = muted and "🔇 Suoni: Disattivati" or "🔊 Suoni: Attivi"
		if onMuteToggle then onMuteToggle(muted) end
	end)

	selectTab("Flame")
	refreshDoubleLightVisuals()

	-- Aggiornamento dinamico dei bottoni progressivi
	local uiController = {
		SetOpen = setShopOpen,
		IsOpen = function()
			return isOpen
		end,
		OpenDoubleLightPopup = openDoubleLightPopup,
		CloseDoubleLightPopup = closeDoubleLightPopup,
	}

	function uiController.Update(st)
		local upgrades = st.Upgrades or {}
		local points = st.Points or 0
		local discoveredCount = 0
		local affordableCount = 0
		local hasWorldButtons = false

		if st.HasDoubleLight == true and not hasDoubleLight then
			hasDoubleLight = true
			refreshDoubleLightVisuals()
		end

		-- Mostra automaticamente il pop-up x2 una sola volta quando il giocatore raggiunge 100 Punti Luce
		if not hasDoubleLight and not autoPromptShown and (st.TotalPoints or points) >= 100 then
			autoPromptShown = true
			openDoubleLightPopup()
		end

		for id, entry in pairs(tileMap) do
			local u = entry.Cfg
			local isUnlocked = (u.ReqId == nil) or ((upgrades[u.ReqId] or 0) >= (u.ReqLvl or 1))

			if isUnlocked then
				discoveredCount += 1
				if u.Category == "World" then
					hasWorldButtons = true
				end

				if not unlockedSet[id] then
					unlockedSet[id] = true
					entry.Tile.Visible = true
					entry.Scale.Scale = 0.25
					TweenService:Create(entry.Scale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Scale = 1.0,
					}):Play()
				else
					entry.Tile.Visible = true
				end

				local lvl = upgrades[id] or 0
				local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
				entry.LvlPill.Text = string.format("Lv. %d/%d", lvl, u.MaxLevel)
				entry.ProgFill.Size = UDim2.fromScale(math.clamp(lvl / u.MaxLevel, 0, 1), 1)

				if lvl >= u.MaxLevel then
					entry.Tile.BackgroundColor3 = THEME.TileMax
					entry.Stroke.Color = THEME.Green
					entry.CostPill.BackgroundColor3 = THEME.Green
					entry.CostTxt.TextColor3 = Color3.fromRGB(16, 24, 20)
					entry.CostTxt.Text = "✓ COMPLETATO"
				elseif points >= cost then
					affordableCount += 1
					entry.Tile.BackgroundColor3 = THEME.TileReady
					entry.Stroke.Color = THEME.Gold
					entry.CostPill.BackgroundColor3 = THEME.Gold
					entry.CostTxt.TextColor3 = Color3.fromRGB(18, 16, 22)
					entry.CostTxt.Text = "🔥 " .. NumberFormat.Format(cost)
				else
					entry.Tile.BackgroundColor3 = THEME.TileLocked
					entry.Stroke.Color = Color3.fromRGB(52, 56, 76)
					entry.CostPill.BackgroundColor3 = Color3.fromRGB(34, 37, 52)
					entry.CostTxt.TextColor3 = THEME.TextSub
					entry.CostTxt.Text = "🔥 " .. NumberFormat.Format(cost)
				end
			else
				entry.Tile.Visible = false
			end
		end

		discoveryBadge.Text = string.format("%d/%d", discoveredCount, #GameConfig.Upgrades)

		-- Aggiorna il badge sul pulsante retratto
		if affordableCount > 0 then
			readyBadge.Visible = true
			readyBadge.Text = tostring(affordableCount)
			toggleStroke.Color = THEME.Gold
			toggleStroke.Transparency = 0.15
			toggleSub.Text = affordableCount == 1 and "1 disponibile! [B]" or (affordableCount .. " disponibili! [B]")
			toggleSub.TextColor3 = THEME.Gold
		else
			readyBadge.Visible = false
			toggleStroke.Color = THEME.Gold
			toggleStroke.Transparency = 0.55
			toggleSub.Text = "Apri Negozio [B]"
			toggleSub.TextColor3 = THEME.TextSub
		end

		-- Sblocca progressivamente anche le schede superiori!
		tabButtons["World"].Visible = hasWorldButtons
		tabButtons["Wisps"].Visible = st.WispsUnlocked == true
		tabButtons["Alba"].Visible = st.AlbaUnlocked == true

		-- Spiriti
		wispHeader.Text = string.format("Spiriti Attivi: %d/%d (Moltiplicano i Click)", st.EquippedCount or 0, st.MaxWispSlots or 3)
		for id, entry in pairs(wispRows) do
			local baseCnt = (st.WispCounts and st.WispCounts[id]) or 0
			local radCnt = (st.WispCounts and st.WispCounts[id .. "_rad"]) or 0
			entry.Count.Text = string.format("Base: %d • Radiosi (x2.5): %d", baseCnt, radCnt)
			local canFuse = baseCnt >= 3
			entry.Fuse.BackgroundColor3 = canFuse and THEME.Gold or Color3.fromRGB(36, 40, 56)
			entry.Fuse.TextColor3 = canFuse and Color3.fromRGB(18, 16, 22) or THEME.TextSub
		end

		-- Prestige
		if points >= GameConfig.PrestigeCost then
			local gain = math.max(1, math.floor(math.log10(points / 5e6)))
			prestigeBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 165)
			prestigeBtn.Text = "🌅 COMPI GRANDE ALBA (+" .. gain .. " Stelle)\nStelle attuali: " .. (st.EternalStars or 0)
		else
			prestigeBtn.BackgroundColor3 = THEME.Purple
			prestigeBtn.Text = "🌅 GRANDE ALBA (50M Punti)\nStelle Eterne: " .. (st.EternalStars or 0)
		end

		for id, entry in pairs(starButtons) do
			local sp = entry.Cfg
			local lvl = (st.StarPerks and st.StarPerks[id]) or 0
			local cost = math.floor(sp.Cost * (sp.CostMult ^ lvl))
			if lvl >= sp.MaxLevel then
				entry.Btn.BackgroundColor3 = THEME.Green
				entry.Btn.TextColor3 = Color3.fromRGB(16, 22, 18)
				entry.Btn.Text = sp.Name .. " [MAX]"
			else
				local ok = (st.EternalStars or 0) >= cost
				entry.Btn.BackgroundColor3 = ok and Color3.fromRGB(150, 65, 210) or THEME.TileLocked
				entry.Btn.TextColor3 = THEME.TextMain
				entry.Btn.Text = string.format("%s (%d/%d) — %d⭐", sp.Name, lvl, sp.MaxLevel, cost)
			end
		end
	end

	return uiController
end

return ShopUI