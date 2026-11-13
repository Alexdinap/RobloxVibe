local TweenService = game:GetService("TweenService")
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
	local activeTab = "Flame"
	local unlockedSet = {} -- traccia quali bottoni sono già comparsi per animarli all'ingresso

	local panel = Instance.new("Frame", parentGui)
	panel.Name = "ProgressiveShopPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -16, 0.52, 0)
	panel.Size = UDim2.new(0, 390, 0.80, 0)
	panel.BackgroundColor3 = THEME.PanelBg
	panel.BackgroundTransparency = 0.10
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)

	local pStroke = Instance.new("UIStroke", panel)
	pStroke.Color = THEME.Gold
	pStroke.Transparency = 0.55
	pStroke.Thickness = 1.5

	-- Intestazione con contatore bottoni scoperti
	local header = Instance.new("Frame", panel)
	header.Size = UDim2.new(1, -24, 0, 32)
	header.Position = UDim2.fromOffset(12, 10)
	header.BackgroundTransparency = 1

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Size = UDim2.new(0.62, 0, 1, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "⚡ POTENZIAMENTI"
	headerTitle.TextColor3 = THEME.TextMain
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextScaled = true

	local discoveryBadge = Instance.new("TextLabel", header)
	discoveryBadge.Size = UDim2.new(0.36, 0, 0.82, 0)
	discoveryBadge.Position = UDim2.new(0.64, 0, 0.09, 0)
	discoveryBadge.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
	discoveryBadge.Text = "Scoperti: 1/" .. #GameConfig.Upgrades
	discoveryBadge.TextColor3 = THEME.Gold
	discoveryBadge.Font = Enum.Font.GothamBold
	discoveryBadge.TextScaled = true
	Instance.new("UICorner", discoveryBadge).CornerRadius = UDim.new(1, 0)

	-- Barra delle Schede (anch'esse compaiono man mano che le sblocchi!)
	local tabStrip = Instance.new("Frame", panel)
	tabStrip.Size = UDim2.new(1, -24, 0, 36)
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
		pg.Size = UDim2.new(1, -24, 1, -96)
		pg.Position = UDim2.fromOffset(12, 88)
		pg.BackgroundTransparency = 1
		pg.Visible = false
		pages[td.Id] = pg
	end

	-- Griglia a 2 Colonne per i Bottoni a Comparsa Progressiva ("Flame" e "World")
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
		grid.CellSize = UDim2.new(0.482, 0, 0, 114)
		grid.CellPadding = UDim2.new(0.036, 0, 0, 10)
		grid.SortOrder = Enum.SortOrder.LayoutOrder

		for _, u in ipairs(GameConfig.Upgrades) do
			if u.Category == category then
				-- Il bottone intero è una Tile cliccabile!
				local tile = Instance.new("TextButton", scroll)
				tile.Name = u.Id
				tile.LayoutOrder = u.Order
				tile.BackgroundColor3 = THEME.TileLocked
				tile.Text = ""
				tile.AutoButtonColor = false
				tile.Visible = (u.ReqId == nil) -- Nascosto finché non compri il prerequisito!
				Instance.new("UICorner", tile).CornerRadius = UDim.new(0, 14)

				local stroke = Instance.new("UIStroke", tile)
				stroke.Color = Color3.fromRGB(52, 56, 76)
				stroke.Thickness = 1.6

				local scale = Instance.new("UIScale", tile)
				scale.Scale = 1.0

				-- Badge Icona in alto a sinistra
				local iconBadge = Instance.new("TextLabel", tile)
				iconBadge.Size = UDim2.fromOffset(32, 32)
				iconBadge.Position = UDim2.fromOffset(8, 8)
				iconBadge.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
				iconBadge.Text = u.Icon
				iconBadge.TextScaled = true
				Instance.new("UICorner", iconBadge).CornerRadius = UDim.new(0, 9)

				-- Pillola Livello in alto a destra
				local lvlPill = Instance.new("TextLabel", tile)
				lvlPill.AnchorPoint = Vector2.new(1, 0)
				lvlPill.Position = UDim2.new(1, -8, 0, 10)
				lvlPill.Size = UDim2.fromOffset(64, 22)
				lvlPill.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
				lvlPill.Text = "Lv. 0/" .. u.MaxLevel
				lvlPill.TextColor3 = THEME.TextSub
				lvlPill.Font = Enum.Font.GothamBold
				lvlPill.TextScaled = true
				Instance.new("UICorner", lvlPill).CornerRadius = UDim.new(1, 0)

				-- Nome Potenziamento
				local titleLbl = Instance.new("TextLabel", tile)
				titleLbl.Size = UDim2.new(1, -16, 0, 20)
				titleLbl.Position = UDim2.fromOffset(8, 44)
				titleLbl.BackgroundTransparency = 1
				titleLbl.Text = u.Name
				titleLbl.TextColor3 = THEME.TextMain
				titleLbl.TextXAlignment = Enum.TextXAlignment.Left
				titleLbl.Font = Enum.Font.GothamBlack
				titleLbl.TextScaled = true

				-- Effetto sintetico
				local tagLbl = Instance.new("TextLabel", tile)
				tagLbl.Size = UDim2.new(1, -16, 0, 16)
				tagLbl.Position = UDim2.fromOffset(8, 64)
				tagLbl.BackgroundTransparency = 1
				tagLbl.Text = u.Tag
				tagLbl.TextColor3 = THEME.Cyan
				tagLbl.TextXAlignment = Enum.TextXAlignment.Left
				tagLbl.Font = Enum.Font.GothamBold
				tagLbl.TextScaled = true

				-- Pillola Costo in basso (tutta larghezza)
				local costPill = Instance.new("Frame", tile)
				costPill.Size = UDim2.new(1, -16, 0, 24)
				costPill.Position = UDim2.new(0, 8, 1, -30)
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
		row.Size = UDim2.new(1, 0, 0, 48)
		row.Position = UDim2.fromOffset(0, 28 + (i - 1) * 54)
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
		countLbl.Position = UDim2.fromOffset(10, 25)
		countLbl.BackgroundTransparency = 1
		countLbl.Text = "Base: 0 • Radiosi: 0"
		countLbl.TextColor3 = THEME.TextSub
		countLbl.TextXAlignment = Enum.TextXAlignment.Left
		countLbl.Font = Enum.Font.GothamMedium
		countLbl.TextScaled = true

		local fuseBtn = Instance.new("TextButton", row)
		fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
		fuseBtn.Position = UDim2.new(1, -8, 0.5, 0)
		fuseBtn.Size = UDim2.fromOffset(96, 34)
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
	summon1Btn.Size = UDim2.new(0.485, 0, 0, 44)
	summon1Btn.Position = UDim2.new(0, 0, 1, -46)
	summon1Btn.BackgroundColor3 = Color3.fromRGB(40, 155, 205)
	summon1Btn.Text = "✨ Evoca x1 (500)"
	summon1Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	summon1Btn.Font = Enum.Font.GothamBlack
	summon1Btn.TextScaled = true
	Instance.new("UICorner", summon1Btn).CornerRadius = UDim.new(0, 10)
	summon1Btn.MouseButton1Click:Connect(function() remotes.SummonWisp:FireServer(1) end)

	local summon5Btn = Instance.new("TextButton", pWisps)
	summon5Btn.Size = UDim2.new(0.485, 0, 0, 44)
	summon5Btn.Position = UDim2.new(0.515, 0, 1, -46)
	summon5Btn.BackgroundColor3 = THEME.Purple
	summon5Btn.Text = "✨ Evoca x5 (2.5K)"
	summon5Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	summon5Btn.Font = Enum.Font.GothamBlack
	summon5Btn.TextScaled = true
	Instance.new("UICorner", summon5Btn).CornerRadius = UDim.new(0, 10)
	summon5Btn.MouseButton1Click:Connect(function() remotes.SummonWisp:FireServer(5) end)

	-- Pagina Grande Alba, Codici & Suoni
	local pAlba = pages["Alba"]
	local prestigeBtn = Instance.new("TextButton", pAlba)
	prestigeBtn.Size = UDim2.new(1, 0, 0, 54)
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
		b.Size = UDim2.new(1, 0, 0, 42)
		b.Position = UDim2.fromOffset(0, 60 + (i - 1) * 47)
		b.BackgroundColor3 = THEME.TileLocked
		b.TextColor3 = THEME.TextMain
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
		b.MouseButton1Click:Connect(function() remotes.BuyStarPerk:FireServer(sp.Id) end)
		starButtons[sp.Id] = { Btn = b, Cfg = sp }
	end

	local codeBox = Instance.new("TextBox", pAlba)
	codeBox.Size = UDim2.new(0.66, 0, 0, 36)
	codeBox.Position = UDim2.new(0, 0, 1, -84)
	codeBox.PlaceholderText = "Codice (LUCE100, FIAMMA)"
	codeBox.Text = ""
	codeBox.BackgroundColor3 = THEME.TileLocked
	codeBox.TextColor3 = THEME.TextMain
	codeBox.Font = Enum.Font.GothamBold
	codeBox.TextScaled = true
	Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 8)

	local codeBtn = Instance.new("TextButton", pAlba)
	codeBtn.Size = UDim2.new(0.32, 0, 0, 36)
	codeBtn.Position = UDim2.new(0.68, 0, 1, -84)
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
	muteBtn.Size = UDim2.new(1, 0, 0, 36)
	muteBtn.Position = UDim2.new(0, 0, 1, -40)
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

	-- Aggiornamento dinamico dei bottoni progressivi
	local uiController = {}
	function uiController.Update(st)
		local upgrades = st.Upgrades or {}
		local points = st.Points or 0
		local discoveredCount = 0
		local hasWorldButtons = false

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

		discoveryBadge.Text = string.format("Scoperti: %d/%d", discoveredCount, #GameConfig.Upgrades)

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
