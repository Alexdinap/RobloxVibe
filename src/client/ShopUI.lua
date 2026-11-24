local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))
local EconomyEngine = require(ReplicatedStorage:WaitForChild("EconomyEngine"))
local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

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

local function createCloseImageButton(parent, zIndex)
	local btn = Instance.new("TextButton", parent)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -12, 0.5, 0)
	btn.Size = UDim2.fromOffset(30, 30)
	btn.BackgroundColor3 = Color3.fromRGB(48, 24, 32)
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.ZIndex = zIndex
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(255, 105, 120)
	stroke.Thickness = 1.2

	local icon = Instance.new("ImageLabel", btn)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(16, 16)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxasset://textures/ui/InspectMenu/x.png"
	icon.ImageColor3 = Color3.fromRGB(255, 120, 130)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = zIndex + 1

	return btn
end

function ShopUI.Build(parentGui, remotes)
	local latestState = nil
	local activeTab = "Character"
	local renderedTab = nil
	local renderedLang = nil
	local isOpen = false
	local lastActionClock = 0

	local charCardRefs = {}
	local defenseRefs = nil
	local wispRowRefs = {}
	local wispHeaderRefs = nil
	local wispLockRef = nil
	local albaRefs = nil

	local function getLang()
		return (latestState and latestState.Language) or "en"
	end

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
	homeBtn.Text = Localization.T("en", "MY_ZONE_BTN")
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
	toggleLabel.Text = Localization.T("en", "CHAR_BTN_TITLE")
	toggleLabel.TextColor3 = THEME.TextMain
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.Font = Enum.Font.GothamBlack
	toggleLabel.TextSize = 13
	toggleLabel.ZIndex = 16

	local toggleSub = Instance.new("TextLabel", toggleBtn)
	toggleSub.Size = UDim2.new(1, -54, 0, 16)
	toggleSub.Position = UDim2.fromOffset(50, 28)
	toggleSub.BackgroundTransparency = 1
	toggleSub.Text = Localization.T("en", "CHAR_BTN_SUB")
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
	dockBoostBtn.Text = Localization.T("en", "ROBUX_X2_BTN")
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

	local modal = Instance.new("Frame", parentGui)
	modal.Name = "CharacterMenuModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.48)
	modal.Size = UDim2.fromOffset(620, 420)
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
	headerTitle.Text = Localization.T("en", "MODAL_TITLE")
	headerTitle.TextColor3 = THEME.Gold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 16
	headerTitle.ZIndex = 21

	local closeBtn = createCloseImageButton(header, 22)

	local tabsBar = Instance.new("Frame", modal)
	tabsBar.Position = UDim2.fromOffset(14, 44)
	tabsBar.Size = UDim2.new(1, -28, 0, 32)
	tabsBar.BackgroundTransparency = 1
	tabsBar.ZIndex = 21

	local tabDefs = {
		{ Id = "Character", Key = "TAB_CHAR" },
		{ Id = "Defense",   Key = "TAB_DEFENSE" },
		{ Id = "Wisps",     Key = "TAB_WISPS" },
		{ Id = "Alba",      Key = "TAB_DAWN" },
		{ Id = "Codes",     Key = "TAB_CODES" },
	}
	local tabButtons = {}

	for idx, td in ipairs(tabDefs) do
		local b = Instance.new("TextButton", tabsBar)
		b.Position = UDim2.new((idx - 1) * 0.2, 2, 0, 0)
		b.Size = UDim2.new(0.2, -4, 1, 0)
		b.BackgroundColor3 = THEME.Card
		b.Text = Localization.T("en", td.Key)
		b.TextColor3 = THEME.TextMain
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
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
		defenseRefs = nil
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

	local function refreshExistingWidgets()
		if not latestState then return end
		local st = latestState
		local lang = getLang()
		local lightUnit = Localization.T(lang, "LIGHT_UNIT")
		local points = st.Points or 0
		local albaPts = st.AlbaPoints or 0
		local albaCount = st.AlbaCount or 0

		if renderedTab == "Character" then
			for _, ref in ipairs(charCardRefs) do
				local u = ref.Config
				local lvl = EconomyEngine.GetLevel(st.Upgrades, u.Id)
				local unlocked = EconomyEngine.IsUpgradeUnlocked({ Upgrades = st.Upgrades or {} }, u)
				local maxed = lvl >= u.MaxLevel
				local cost = math.floor(u.BaseCost * (u.CostMult ^ lvl))
				local canBuy = unlocked and (not maxed) and points >= cost

				local uName = Localization.Pick(lang, u.Name, u.Name_it)
				local uTag = Localization.Pick(lang, u.Tag, u.Tag_it)
				local uDesc = Localization.Pick(lang, u.Desc, u.Desc_it)

				ref.Card.BackgroundColor3 = unlocked and THEME.Card or THEME.CardLocked
				ref.Title.Text = string.format("%s %s  [Lv.%d/%d]", u.Icon, uName, lvl, u.MaxLevel)
				ref.Title.TextColor3 = unlocked and THEME.TextMain or THEME.TextSub
				ref.Desc.Text = unlocked and (uTag .. " — " .. uDesc) or Localization.T(lang, "LOCKED_REQ")

				ref.BuyBtn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				ref.BuyBtn.Text = maxed and Localization.T(lang, "BTN_MAXED") or (unlocked and (NumberFormat.Format(cost) .. " " .. lightUnit) or Localization.T(lang, "BTN_LOCKED"))
				ref.BuyBtn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end

		elseif renderedTab == "Defense" and defenseRefs then
			local ownedWeapons = st.OwnedWeapons or {}
			for _, wRef in ipairs(defenseRefs.Weapons) do
				local w = wRef.Config
				local owned = ownedWeapons[w.Id] == true
				local reqAlba = w.ReqAlba or 0
				local albaLocked = (not owned) and (albaCount < reqAlba)
				local canBuy = (not owned) and (not albaLocked) and points >= w.Cost
				local wName = Localization.Pick(lang, w.Name, w.Name_it)
				local wTag = Localization.Pick(lang, w.Tag, w.Tag_it)
				local wDesc = Localization.Pick(lang, w.Desc, w.Desc_it)

				if albaLocked then
					wRef.Card.BackgroundColor3 = THEME.CardLocked
					wRef.Title.Text = string.format("🔒 %s (%s)", wName, wTag)
					wRef.Desc.Text = wDesc
					wRef.Btn.BackgroundColor3 = Color3.fromRGB(36, 40, 56)
					wRef.Btn.Text = (lang == "it") and ("🔒 " .. reqAlba .. " Rinascita") or ("🔒 " .. reqAlba .. " Rebirth")
					wRef.Btn.TextColor3 = THEME.TextSub
				else
					wRef.Card.BackgroundColor3 = owned and Color3.fromRGB(24, 42, 36) or THEME.Card
					wRef.Title.Text = string.format("%s %s (%s)", w.Icon, wName, wTag)
					wRef.Desc.Text = wDesc
					wRef.Btn.BackgroundColor3 = owned and Color3.fromRGB(35, 65, 52) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
					wRef.Btn.Text = owned and Localization.T(lang, "BTN_EQUIPPED") or (NumberFormat.Format(w.Cost) .. " " .. lightUnit)
					wRef.Btn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				end
			end

			for _, dRef in ipairs(defenseRefs.Structures) do
				local d = dRef.Config

				-- Nasconde i potenziamenti delle torrette finché non viene comprata la 1ª torretta
				if d.ReqDefenseId then
					local reqLvl = EconomyEngine.GetLevel(st.Defenses, d.ReqDefenseId)
					dRef.Card.Visible = reqLvl >= (d.ReqDefenseLvl or 1)
				else
					dRef.Card.Visible = true
				end

				local lvl = EconomyEngine.GetLevel(st.Defenses, d.Id)
				local maxed = lvl >= d.MaxLevel
				local costInfo = GameConfig.GetDefenseCost(d, lvl)
				local needPts = costInfo.Points or 0
				local needAlba = costInfo.Alba or 0
				local canBuy = (not maxed) and (points >= needPts) and (albaPts >= needAlba)

				local dName = Localization.Pick(lang, d.Name, d.Name_it)
				local dTag = Localization.Pick(lang, d.Tag, d.Tag_it)
				local dDesc = Localization.Pick(lang, d.Desc, d.Desc_it)

				dRef.Title.Text = string.format("%s %s  [Lv.%d/%d]", d.Icon, dName, lvl, d.MaxLevel)
				dRef.Desc.Text = dTag .. " — " .. dDesc
				dRef.Btn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Cyan or Color3.fromRGB(36, 40, 56))
				if maxed then
					dRef.Btn.Text = Localization.T(lang, "BTN_MAXED")
				elseif needAlba > 0 then
					dRef.Btn.Text = string.format("%s %s\n+ %d 🌅", NumberFormat.Format(needPts), lightUnit, needAlba)
				else
					dRef.Btn.Text = NumberFormat.Format(needPts) .. " " .. lightUnit
				end
				dRef.Btn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end

		elseif renderedTab == "Wisps" then
			if wispLockRef then
				wispLockRef.Visible = not st.WispsUnlocked
				wispLockRef.Text = Localization.T(lang, "WISPS_LOCKED")
			end
			if wispHeaderRefs then
				wispHeaderRefs.Card.Visible = st.WispsUnlocked == true
				wispHeaderRefs.Info.Text = Localization.T(lang, "WISPS_HEADER_FMT", st.EquippedCount or 0, st.MaxWispSlots or 3)
				wispHeaderRefs.Btn1.Text = Localization.T(lang, "SUMMON_1_FMT", NumberFormat.Format(GameConfig.BaseWispCost))
				wispHeaderRefs.Btn1.BackgroundColor3 = (points >= GameConfig.BaseWispCost) and THEME.Cyan or Color3.fromRGB(36, 40, 56)
				wispHeaderRefs.Btn1.TextColor3 = (points >= GameConfig.BaseWispCost) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				local cost5 = GameConfig.BaseWispCost * 5
				wispHeaderRefs.Btn5.Text = Localization.T(lang, "SUMMON_5_FMT", NumberFormat.Format(cost5))
				wispHeaderRefs.Btn5.BackgroundColor3 = (points >= cost5) and THEME.Gold or Color3.fromRGB(36, 40, 56)
				wispHeaderRefs.Btn5.TextColor3 = (points >= cost5) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end
			local counts = st.WispCounts or {}
			for _, ref in ipairs(wispRowRefs) do
				ref.Row.Visible = st.WispsUnlocked == true
				local w = ref.Config
				local wName = Localization.Pick(lang, w.Name, w.Name_it)
				local normCnt = counts[w.Id] or 0
				local radCnt = counts[w.Id .. "_rad"] or 0
				ref.Label.Text = Localization.T(lang, "WISP_ROW_FMT", wName, w.ClickMult, w.Chance, normCnt, radCnt)
				ref.FuseBtn.BackgroundColor3 = (normCnt >= 3) and THEME.Purple or Color3.fromRGB(36, 40, 56)
				ref.FuseBtn.Text = (normCnt >= 3) and Localization.T(lang, "FORGE_READY") or Localization.T(lang, "FORGE_NEED_FMT", normCnt)
			end

		elseif renderedTab == "Alba" and albaRefs then
			local rewardPerRebirth = st.AlbaRewardPerRebirth or 1
			local dawnUnit = Localization.T(lang, "DAWN_PT_UNIT")
			local statusTxt = st.AllUpgradesCompleted
				and Localization.T(lang, "DAWN_STATUS_READY", rewardPerRebirth)
				or Localization.T(lang, "DAWN_STATUS_PROG", st.CompletedUpgradesCount or 0, st.TotalUpgradesCount or 20, rewardPerRebirth)

			albaRefs.HeaderInfo.Text = Localization.T(lang, "DAWN_HEADER_FMT", albaPts, albaCount, statusTxt)

			for _, apRef in ipairs(albaRefs.Perks) do
				local ap = apRef.Config
				local lvl = EconomyEngine.GetLevel(st.AlbaPerks, ap.Id)
				local maxed = lvl >= ap.MaxLevel
				local cost = math.floor(ap.Cost * (ap.CostMult ^ lvl))
				local canBuy = (not maxed) and albaPts >= cost

				apRef.Title.Text = string.format("🌅 %s  [Lv.%d/%d]", Localization.Pick(lang, ap.Name, ap.Name_it), lvl, ap.MaxLevel)
				apRef.Desc.Text = Localization.Pick(lang, ap.Desc, ap.Desc_it)
				apRef.Btn.BackgroundColor3 = maxed and Color3.fromRGB(35, 55, 45) or (canBuy and THEME.Gold or Color3.fromRGB(36, 40, 56))
				apRef.Btn.Text = maxed and Localization.T(lang, "BTN_MAXED") or (cost .. " " .. dawnUnit)
				apRef.Btn.TextColor3 = canBuy and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end

			local unlockedZones = st.UnlockedAlbaZones or {}
			for _, zRef in ipairs(albaRefs.Zones) do
				local z = zRef.Config
				local isUnlocked = unlockedZones[z.Id] == true
				local canUnlock = (not isUnlocked) and albaPts >= z.Cost

				zRef.Card.BackgroundColor3 = isUnlocked and Color3.fromRGB(24, 42, 36) or THEME.Card
				zRef.Title.Text = string.format("%s %s", z.Icon, Localization.Pick(lang, z.Name, z.Name_it))
				zRef.Desc.Text = Localization.Pick(lang, z.Desc, z.Desc_it)
				zRef.Btn.BackgroundColor3 = isUnlocked and Color3.fromRGB(35, 65, 52) or (canUnlock and THEME.Cyan or Color3.fromRGB(36, 40, 56))
				zRef.Btn.Text = isUnlocked and Localization.T(lang, "BTN_UNLOCKED") or (z.Cost .. " " .. dawnUnit)
				zRef.Btn.TextColor3 = canUnlock and Color3.fromRGB(16, 18, 24) or THEME.TextMain
			end
		end
	end

	local function buildTabStructure()
		clearScroll()
		local lang = getLang()
		renderedTab = activeTab
		renderedLang = lang

		for _, td in ipairs(tabDefs) do
			local btn = tabButtons[td.Id]
			if btn then
				btn.Text = Localization.T(lang, td.Key)
				btn.BackgroundColor3 = (td.Id == activeTab) and Color3.fromRGB(58, 46, 22) or THEME.Card
				btn.TextColor3 = (td.Id == activeTab) and THEME.Gold or THEME.TextSub
			end
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

		elseif activeTab == "Defense" then
			local tipCard = Instance.new("Frame", scroll)
			tipCard.LayoutOrder = 1
			tipCard.Size = UDim2.new(1, -6, 0, 44)
			tipCard.BackgroundColor3 = Color3.fromRGB(30, 22, 42)
			tipCard.ZIndex = 22
			Instance.new("UICorner", tipCard).CornerRadius = UDim.new(0, 10)
			Instance.new("UIStroke", tipCard).Color = THEME.Purple

			local tipLbl = Instance.new("TextLabel", tipCard)
			tipLbl.Position = UDim2.fromOffset(12, 4)
			tipLbl.Size = UDim2.new(1, -24, 1, -8)
			tipLbl.BackgroundTransparency = 1
			tipLbl.Text = Localization.T(lang, "DEF_TIP")
			tipLbl.TextColor3 = THEME.TextMain
			tipLbl.TextXAlignment = Enum.TextXAlignment.Left
			tipLbl.TextWrapped = true
			tipLbl.Font = Enum.Font.GothamBold
			tipLbl.TextSize = 11
			tipLbl.ZIndex = 23

			local sec1 = Instance.new("TextLabel", scroll)
			sec1.LayoutOrder = 2
			sec1.Size = UDim2.new(1, -6, 0, 22)
			sec1.BackgroundTransparency = 1
			sec1.Text = Localization.T(lang, "SEC_WEAPONS")
			sec1.TextColor3 = THEME.Gold
			sec1.TextXAlignment = Enum.TextXAlignment.Left
			sec1.Font = Enum.Font.GothamBlack
			sec1.TextSize = 12
			sec1.ZIndex = 22

			local wepList = {}
			for idx, w in ipairs(GameConfig.Weapons) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 10 + idx
				row.Size = UDim2.new(1, -6, 0, 56)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(12, 6)
				tLbl.Size = UDim2.new(1, -150, 0, 18)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = w.Color
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBold
				tLbl.TextSize = 13
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(12, 24)
				dLbl.Size = UDim2.new(1, -150, 0, 26)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 11
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -10, 0.5, 0)
				b.Size = UDim2.fromOffset(126, 36)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 11
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				b.MouseButton1Click:Connect(function()
					remotes.BuyWeapon:FireServer(w.Id)
				end)

				table.insert(wepList, { Config = w, Card = row, Title = tLbl, Desc = dLbl, Btn = b })
			end

			local sec2 = Instance.new("TextLabel", scroll)
			sec2.LayoutOrder = 30
			sec2.Size = UDim2.new(1, -6, 0, 22)
			sec2.BackgroundTransparency = 1
			sec2.Text = Localization.T(lang, "SEC_STRUCTURES")
			sec2.TextColor3 = THEME.Cyan
			sec2.TextXAlignment = Enum.TextXAlignment.Left
			sec2.Font = Enum.Font.GothamBlack
			sec2.TextSize = 12
			sec2.ZIndex = 22

			local defList = {}
			for idx, d in ipairs(GameConfig.Defenses) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 40 + idx
				row.Size = UDim2.new(1, -6, 0, 56)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(12, 6)
				tLbl.Size = UDim2.new(1, -150, 0, 18)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.Cyan
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBold
				tLbl.TextSize = 13
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(12, 24)
				dLbl.Size = UDim2.new(1, -150, 0, 26)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 11
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -10, 0.5, 0)
				b.Size = UDim2.fromOffset(126, 36)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 11
				b.TextWrapped = true
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				b.MouseButton1Click:Connect(function()
					remotes.BuyDefense:FireServer(d.Id)
				end)

				table.insert(defList, { Config = d, Card = row, Title = tLbl, Desc = dLbl, Btn = b })
			end

			defenseRefs = { Weapons = wepList, Structures = defList }

		elseif activeTab == "Wisps" then
			local lockLbl = Instance.new("TextLabel", scroll)
			lockLbl.LayoutOrder = 0
			lockLbl.Size = UDim2.new(1, -6, 0, 72)
			lockLbl.BackgroundColor3 = THEME.Card
			lockLbl.Text = Localization.T(lang, "WISPS_LOCKED")
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
			btn1.Font = Enum.Font.GothamBold
			btn1.TextSize = 11
			btn1.ZIndex = 23
			Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 8)
			btn1.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(1)
			end)

			local btn5 = Instance.new("TextButton", sumCard)
			btn5.Position = UDim2.new(0.76, 0, 0.5, -19)
			btn5.Size = UDim2.new(0.22, 0, 0, 38)
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
			local hCard = Instance.new("Frame", scroll)
			hCard.LayoutOrder = 1
			hCard.Size = UDim2.new(1, -6, 0, 64)
			hCard.BackgroundColor3 = Color3.fromRGB(34, 28, 22)
			hCard.ZIndex = 22
			Instance.new("UICorner", hCard).CornerRadius = UDim.new(0, 10)
			Instance.new("UIStroke", hCard).Color = THEME.Gold

			local hInfo = Instance.new("TextLabel", hCard)
			hInfo.Position = UDim2.fromOffset(12, 6)
			hInfo.Size = UDim2.new(1, -24, 0, 52)
			hInfo.BackgroundTransparency = 1
			hInfo.TextColor3 = THEME.Gold
			hInfo.TextXAlignment = Enum.TextXAlignment.Left
			hInfo.TextWrapped = true
			hInfo.Font = Enum.Font.GothamBold
			hInfo.TextSize = 12
			hInfo.ZIndex = 23

			local sec1 = Instance.new("TextLabel", scroll)
			sec1.LayoutOrder = 2
			sec1.Size = UDim2.new(1, -6, 0, 22)
			sec1.BackgroundTransparency = 1
			sec1.Text = Localization.T(lang, "SEC_DAWN_PERKS")
			sec1.TextColor3 = THEME.Gold
			sec1.TextXAlignment = Enum.TextXAlignment.Left
			sec1.Font = Enum.Font.GothamBlack
			sec1.TextSize = 12
			sec1.ZIndex = 22

			local perksList = {}
			for idx, ap in ipairs(GameConfig.AlbaPerks) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 10 + idx
				row.Size = UDim2.new(1, -6, 0, 56)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(12, 6)
				tLbl.Size = UDim2.new(1, -150, 0, 18)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.TextMain
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBold
				tLbl.TextSize = 13
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(12, 24)
				dLbl.Size = UDim2.new(1, -150, 0, 26)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 11
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -10, 0.5, 0)
				b.Size = UDim2.fromOffset(126, 36)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 12
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				b.MouseButton1Click:Connect(function()
					remotes.BuyAlbaPerk:FireServer(ap.Id)
				end)

				table.insert(perksList, { Config = ap, Title = tLbl, Desc = dLbl, Btn = b })
			end

			local sec2 = Instance.new("TextLabel", scroll)
			sec2.LayoutOrder = 30
			sec2.Size = UDim2.new(1, -6, 0, 22)
			sec2.BackgroundTransparency = 1
			sec2.Text = Localization.T(lang, "SEC_DAWN_ZONES")
			sec2.TextColor3 = THEME.Cyan
			sec2.TextXAlignment = Enum.TextXAlignment.Left
			sec2.Font = Enum.Font.GothamBlack
			sec2.TextSize = 12
			sec2.ZIndex = 22

			local zonesList = {}
			for idx, z in ipairs(GameConfig.AlbaZones) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 40 + idx
				row.Size = UDim2.new(1, -6, 0, 56)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(12, 6)
				tLbl.Size = UDim2.new(1, -150, 0, 18)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.Cyan
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBold
				tLbl.TextSize = 13
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(12, 24)
				dLbl.Size = UDim2.new(1, -150, 0, 26)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 11
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -10, 0.5, 0)
				b.Size = UDim2.fromOffset(126, 36)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 12
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				b.MouseButton1Click:Connect(function()
					remotes.UnlockAlbaZone:FireServer(z.Id)
				end)

				table.insert(zonesList, { Config = z, Card = row, Title = tLbl, Desc = dLbl, Btn = b })
			end

			albaRefs = { HeaderInfo = hInfo, Perks = perksList, Zones = zonesList }

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
			box.PlaceholderText = Localization.T(lang, "CODE_PLACEHOLDER")
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
			statusLbl.Text = Localization.T(lang, "CODE_HINT")
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
			redeemBtn.Text = Localization.T(lang, "CODE_REDEEM")
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
			if renderedTab ~= activeTab or renderedLang ~= getLang() then
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

	local victoryModal = Instance.new("Frame", parentGui)
	victoryModal.Name = "VictoryCelebrationModal"
	victoryModal.AnchorPoint = Vector2.new(0.5, 0.5)
	victoryModal.Position = UDim2.fromScale(0.5, 0.5)
	victoryModal.Size = UDim2.fromOffset(450, 240)
	victoryModal.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
	victoryModal.Visible = false
	victoryModal.ZIndex = 40
	Instance.new("UICorner", victoryModal).CornerRadius = UDim.new(0, 18)

	local vStroke = Instance.new("UIStroke", victoryModal)
	vStroke.Color = THEME.Gold
	vStroke.Thickness = 2.4

	local vHeader = Instance.new("Frame", victoryModal)
	vHeader.Size = UDim2.new(1, 0, 0, 44)
	vHeader.BackgroundTransparency = 1
	vHeader.ZIndex = 41

	local vHead = Instance.new("TextLabel", vHeader)
	vHead.Position = UDim2.fromOffset(18, 10)
	vHead.Size = UDim2.new(1, -64, 0, 28)
	vHead.BackgroundTransparency = 1
	vHead.Text = Localization.T("en", "VICTORY_TITLE")
	vHead.TextColor3 = THEME.Gold
	vHead.TextXAlignment = Enum.TextXAlignment.Left
	vHead.Font = Enum.Font.GothamBlack
	vHead.TextSize = 18
	vHead.ZIndex = 41

	local vTopClose = createCloseImageButton(vHeader, 42)
	vTopClose.MouseButton1Click:Connect(function()
		victoryModal.Visible = false
	end)

	local vBody = Instance.new("TextLabel", victoryModal)
	vBody.Position = UDim2.fromOffset(20, 56)
	vBody.Size = UDim2.new(1, -40, 0, 110)
	vBody.BackgroundTransparency = 1
	vBody.Text = ""
	vBody.TextColor3 = THEME.TextMain
	vBody.TextWrapped = true
	vBody.Font = Enum.Font.Gotham
	vBody.TextSize = 13
	vBody.ZIndex = 41

	local vOpenAlba = Instance.new("TextButton", victoryModal)
	vOpenAlba.AnchorPoint = Vector2.new(0.5, 1)
	vOpenAlba.Position = UDim2.new(0.5, 0, 1, -18)
	vOpenAlba.Size = UDim2.fromOffset(210, 38)
	vOpenAlba.BackgroundColor3 = THEME.Gold
	vOpenAlba.Text = Localization.T("en", "VICTORY_OPEN_DAWN")
	vOpenAlba.TextColor3 = Color3.fromRGB(16, 18, 24)
	vOpenAlba.Font = Enum.Font.GothamBlack
	vOpenAlba.TextSize = 12
	vOpenAlba.ZIndex = 41
	Instance.new("UICorner", vOpenAlba).CornerRadius = UDim.new(0, 10)
	vOpenAlba.MouseButton1Click:Connect(function()
		victoryModal.Visible = false
		activeTab = "Alba"
		setOpen(true)
	end)

	return {
		Update = function(st)
			latestState = st
			local lang = getLang()

			homeBtn.Text = Localization.T(lang, "MY_ZONE_BTN")
			toggleLabel.Text = Localization.T(lang, "CHAR_BTN_TITLE")
			toggleSub.Text = Localization.T(lang, "CHAR_BTN_SUB")
			headerTitle.Text = Localization.T(lang, "MODAL_TITLE")
			vHead.Text = Localization.T(lang, "VICTORY_TITLE")
			vOpenAlba.Text = Localization.T(lang, "VICTORY_OPEN_DAWN")

			if st.HasDoubleLight then
				dockBoostBtn.Text = Localization.T(lang, "ROBUX_X2_ACTIVE")
				dockBoostBtn.TextColor3 = THEME.Green
				dockBoostStroke.Color = THEME.Green
			else
				dockBoostBtn.Text = Localization.T(lang, "ROBUX_X2_BTN")
				dockBoostBtn.TextColor3 = THEME.Gold
				dockBoostStroke.Color = THEME.Gold
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
				if renderedTab ~= activeTab or renderedLang ~= lang then
					buildTabStructure()
				else
					refreshExistingWidgets()
				end
			end
		end,
		ShowVictory = function(st)
			local lang = getLang()
			local gained = (st and st.AlbaGained) or 1
			local totAlba = (st and st.AlbaPoints) or gained
			vBody.Text = Localization.T(lang, "VICTORY_BODY_FMT", gained, totAlba)
			victoryModal.Visible = true
		end,
	}
end

return ShopUI