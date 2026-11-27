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
	TextMain = Color3.fromRGB(248, 250, 255),
	TextSub = Color3.fromRGB(212, 222, 244),
}

local function styleTreeCard(card, accent)
	card.BackgroundColor3 = accent:Lerp(THEME.Bg, 0.88)
	card.BorderSizePixel = 0
	local stroke = Instance.new("UIStroke", card)
	stroke.Color = accent
	stroke.Thickness = 1.5
	stroke.Transparency = 0.18
	return stroke
end

local function styleTreeButton(button, accent)
	local stroke = Instance.new("UIStroke", button)
	stroke.Color = accent
	stroke.Thickness = 1.2
	stroke.Transparency = 0.2
	return stroke
end

local function createCloseImageButton(parent, zIndex)
	local btn = Instance.new("TextButton", parent)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -12, 0.5, 0)
	btn.Size = UDim2.fromOffset(36, 36)
	btn.BackgroundColor3 = Color3.fromRGB(48, 24, 32)
	btn.Text = ""
	btn.AutoButtonColor = true
	btn.ZIndex = zIndex
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local stroke = Instance.new("UIStroke", btn)
	stroke.Color = Color3.fromRGB(255, 105, 120)
	stroke.Thickness = 1.4

	local icon = Instance.new("ImageLabel", btn)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromOffset(18, 18)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxasset://textures/ui/InspectMenu/x.png"
	icon.ImageColor3 = Color3.fromRGB(255, 120, 130)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = zIndex + 1

	return btn
end

function ShopUI.Build(parentGui, remotes, onOpenTutorial)
	local latestState = nil
	local activeTab = "Character"
	local renderedTab = nil
	local renderedLang = nil
	local renderedTreeSig = nil
	local isOpen = false
	local lastActionClock = 0

	local treeNodeRefs = {}
	local treeLineRefs = {}
	local defenseRefs = nil
	local wispRowRefs = {}
	local wispHeaderRefs = nil
	local wispLockRef = nil
	local albaRefs = nil
	local setOpen

	local function getLang()
		return (latestState and latestState.Language) or "en"
	end

	local graceBanner = Instance.new("Frame", parentGui)
	graceBanner.Name = "DawnTruceTimerBanner"
	graceBanner.AnchorPoint = Vector2.new(0.5, 0)
	graceBanner.Position = UDim2.new(0.5, 0, 0, 86)
	graceBanner.Size = UDim2.fromOffset(420, 34)
	graceBanner.BackgroundColor3 = Color3.fromRGB(20, 26, 40)
	graceBanner.Visible = false
	graceBanner.ZIndex = 16
	Instance.new("UICorner", graceBanner).CornerRadius = UDim.new(0, 10)

	local graceStroke = Instance.new("UIStroke", graceBanner)
	graceStroke.Color = THEME.Cyan
	graceStroke.Thickness = 1.5

	local graceLabel = Instance.new("TextLabel", graceBanner)
	graceLabel.Size = UDim2.fromScale(1, 1)
	graceLabel.BackgroundTransparency = 1
	graceLabel.Text = ""
	graceLabel.TextColor3 = THEME.Cyan
	graceLabel.Font = Enum.Font.GothamBlack
	graceLabel.TextSize = 14
	graceLabel.ZIndex = 17

	-- === DOCK LATERALE SINISTRA (Menù Principale + La Mia Zona) ===
	local leftDock = Instance.new("Frame", parentGui)
	leftDock.Name = "LeftSideActionBar"
	leftDock.AnchorPoint = Vector2.new(0, 0.5)
	leftDock.Position = UDim2.new(0, 14, 0.52, 0)
	leftDock.Size = UDim2.fromOffset(216, 300)
	leftDock.BackgroundTransparency = 1
	leftDock.ZIndex = 15

	local leftLayout = Instance.new("UIListLayout", leftDock)
	leftLayout.Padding = UDim.new(0, 8)
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local toggleBtn = Instance.new("TextButton", leftDock)
	toggleBtn.Name = "BigOpenMenuButton"
	toggleBtn.LayoutOrder = 1
	toggleBtn.Size = UDim2.new(1, 0, 0, 66)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
	toggleBtn.BackgroundTransparency = 0.06
	toggleBtn.Text = ""
	toggleBtn.AutoButtonColor = true
	toggleBtn.ZIndex = 15
	Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 14)

	local toggleStroke = Instance.new("UIStroke", toggleBtn)
	toggleStroke.Color = THEME.Gold
	toggleStroke.Thickness = 1.8

	local toggleIconBg = Instance.new("TextLabel", toggleBtn)
	toggleIconBg.Size = UDim2.fromOffset(42, 42)
	toggleIconBg.Position = UDim2.fromOffset(10, 12)
	toggleIconBg.BackgroundColor3 = Color3.fromRGB(44, 34, 18)
	toggleIconBg.Text = "🧙"
	toggleIconBg.TextSize = 22
	toggleIconBg.ZIndex = 16
	Instance.new("UICorner", toggleIconBg).CornerRadius = UDim.new(0, 10)

	local toggleLabel = Instance.new("TextLabel", toggleBtn)
	toggleLabel.Size = UDim2.new(1, -64, 0, 22)
	toggleLabel.Position = UDim2.fromOffset(60, 10)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = Localization.T("en", "CHAR_BTN_TITLE")
	toggleLabel.TextColor3 = THEME.TextMain
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	toggleLabel.Font = Enum.Font.GothamBlack
	toggleLabel.TextSize = 14
	toggleLabel.ZIndex = 16

	local toggleSub = Instance.new("TextLabel", toggleBtn)
	toggleSub.Size = UDim2.new(1, -64, 0, 18)
	toggleSub.Position = UDim2.fromOffset(60, 34)
	toggleSub.BackgroundTransparency = 1
	toggleSub.Text = Localization.T("en", "CHAR_BTN_SUB")
	toggleSub.TextColor3 = Color3.fromRGB(205, 218, 242)
	toggleSub.TextXAlignment = Enum.TextXAlignment.Left
	toggleSub.TextTruncate = Enum.TextTruncate.AtEnd
	toggleSub.Font = Enum.Font.GothamBold
	toggleSub.TextSize = 12
	toggleSub.ZIndex = 16

	local readyBadge = Instance.new("TextLabel", toggleBtn)
	readyBadge.Name = "ReadyBadge"
	readyBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	readyBadge.Position = UDim2.new(1, -4, 0, 4)
	readyBadge.Size = UDim2.fromOffset(24, 24)
	readyBadge.BackgroundColor3 = THEME.Gold
	readyBadge.Text = "0"
	readyBadge.TextColor3 = Color3.fromRGB(16, 16, 22)
	readyBadge.Font = Enum.Font.GothamBlack
	readyBadge.TextSize = 12
	readyBadge.Visible = false
	readyBadge.ZIndex = 18
	Instance.new("UICorner", readyBadge).CornerRadius = UDim.new(1, 0)

	local function createQuickMenuButton(name, layoutOrder, color, callback)
		local button = Instance.new("TextButton", leftDock)
		button.Name = name
		button.LayoutOrder = layoutOrder
		button.Size = UDim2.new(1, 0, 0, 48)
		button.BackgroundColor3 = Color3.fromRGB(22, 30, 44)
		button.BackgroundTransparency = 0.06
		button.TextColor3 = color
		button.Font = Enum.Font.GothamBlack
		button.TextSize = 15
		button.ZIndex = 15
		Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", button)
		stroke.Color = color
		stroke.Thickness = 1.4
		button.MouseButton1Click:Connect(callback)
		return button
	end

	local turretMenuBtn = createQuickMenuButton("OpenTurretsButton", 2, THEME.Cyan, function()
		if setOpen then
			activeTab = "Defense"
			setOpen(true)
		end
	end)
	local wispsMenuBtn = createQuickMenuButton("OpenWispsButton", 3, THEME.Purple, function()
		if setOpen then
			activeTab = "Wisps"
			setOpen(true)
		end
	end)
	local dailyRewardsBtn = createQuickMenuButton("OpenDailyRewardsButton", 4, THEME.Gold, function()
		if setOpen then
			activeTab = "Daily"
			setOpen(true)
		end
	end)

	local homeBtn = Instance.new("TextButton", leftDock)
	homeBtn.Name = "TeleportHomeButton"
	homeBtn.LayoutOrder = 5
	homeBtn.Size = UDim2.new(1, 0, 0, 54)
	homeBtn.BackgroundColor3 = Color3.fromRGB(22, 30, 44)
	homeBtn.BackgroundTransparency = 0.06
	homeBtn.Text = Localization.T("en", "MY_ZONE_BTN")
	homeBtn.TextColor3 = THEME.Cyan
	homeBtn.Font = Enum.Font.GothamBlack
	homeBtn.TextSize = 15
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

	-- === DOCK LATERALE DESTRA (Boost x2 + Tutorial) ===
	local rightDock = Instance.new("Frame", parentGui)
	rightDock.Name = "RightSideActionBar"
	rightDock.AnchorPoint = Vector2.new(1, 0.5)
	rightDock.Position = UDim2.new(1, -14, 0.52, 0)
	rightDock.Size = UDim2.fromOffset(198, 122)
	rightDock.BackgroundTransparency = 1
	rightDock.ZIndex = 15

	local rightLayout = Instance.new("UIListLayout", rightDock)
	rightLayout.Padding = UDim.new(0, 10)
	rightLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local dockBoostBtn = Instance.new("TextButton", rightDock)
	dockBoostBtn.Name = "BigDoubleLightButton"
	dockBoostBtn.LayoutOrder = 1
	dockBoostBtn.Size = UDim2.new(1, 0, 0, 56)
	dockBoostBtn.BackgroundColor3 = Color3.fromRGB(38, 28, 16)
	dockBoostBtn.BackgroundTransparency = 0.06
	dockBoostBtn.Text = Localization.T("en", "ROBUX_X2_BTN")
	dockBoostBtn.TextColor3 = THEME.Gold
	dockBoostBtn.TextWrapped = true
	dockBoostBtn.Font = Enum.Font.GothamBlack
	dockBoostBtn.TextSize = 14
	dockBoostBtn.ZIndex = 15
	Instance.new("UICorner", dockBoostBtn).CornerRadius = UDim.new(0, 14)

	local dockBoostStroke = Instance.new("UIStroke", dockBoostBtn)
	dockBoostStroke.Color = THEME.Gold
	dockBoostStroke.Thickness = 1.6

	local tutorialBtn = Instance.new("TextButton", rightDock)
	tutorialBtn.Name = "OpenTutorialButton"
	tutorialBtn.LayoutOrder = 2
	tutorialBtn.Size = UDim2.new(1, 0, 0, 54)
	tutorialBtn.BackgroundColor3 = Color3.fromRGB(26, 22, 42)
	tutorialBtn.BackgroundTransparency = 0.06
	tutorialBtn.Text = Localization.T("en", "TUTORIAL_BTN")
	tutorialBtn.TextColor3 = THEME.Purple
	tutorialBtn.Font = Enum.Font.GothamBlack
	tutorialBtn.TextSize = 15
	tutorialBtn.ZIndex = 15
	Instance.new("UICorner", tutorialBtn).CornerRadius = UDim.new(0, 14)

	local tutorialStroke = Instance.new("UIStroke", tutorialBtn)
	tutorialStroke.Color = THEME.Purple
	tutorialStroke.Thickness = 1.6

	tutorialBtn.MouseButton1Click:Connect(function()
		if onOpenTutorial then
			onOpenTutorial()
		end
	end)

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
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.Size = UDim2.new(0.92, 0, 0.84, 0)
	modal.BackgroundColor3 = THEME.Bg
	modal.Visible = false
	modal.ZIndex = 20
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 16)

	local modalConstraint = Instance.new("UISizeConstraint", modal)
	modalConstraint.MaxSize = Vector2.new(780, 520)
	modalConstraint.MinSize = Vector2.new(440, 340)

	local modalStroke = Instance.new("UIStroke", modal)
	modalStroke.Color = THEME.Gold
	modalStroke.Thickness = 1.8

	local header = Instance.new("Frame", modal)
	header.Size = UDim2.new(1, 0, 0, 46)
	header.BackgroundTransparency = 1
	header.ZIndex = 21

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Position = UDim2.fromOffset(16, 10)
	headerTitle.Size = UDim2.new(1, -76, 0, 28)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = Localization.T("en", "MODAL_TITLE")
	headerTitle.TextColor3 = THEME.Gold
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 17
	headerTitle.ZIndex = 21

	local closeBtn = createCloseImageButton(header, 22)

	local tabsBar = Instance.new("Frame", modal)
	tabsBar.Position = UDim2.fromOffset(14, 48)
	tabsBar.Size = UDim2.new(1, -28, 0, 36)
	tabsBar.BackgroundTransparency = 1
	tabsBar.ZIndex = 21

	local tabDefs = {
		{ Id = "Character", Key = "TAB_CHAR" },
		{ Id = "Alba",      Key = "TAB_DAWN" },
		{ Id = "Codes",     Key = "TAB_CODES" },
	}
	local tabButtons = {}
	local tabStrokes = {}

	for idx, td in ipairs(tabDefs) do
		local b = Instance.new("TextButton", tabsBar)
		b.Position = UDim2.new((idx - 1) / #tabDefs, 2, 0, 0)
		b.Size = UDim2.new(1 / #tabDefs, -4, 1, 0)
		b.BackgroundColor3 = THEME.Card
		b.Text = Localization.T("en", td.Key)
		b.TextColor3 = THEME.TextMain
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.ZIndex = 22
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		tabStrokes[td.Id] = styleTreeButton(b, THEME.Cyan)
		tabButtons[td.Id] = b
	end

	local scroll = Instance.new("ScrollingFrame", modal)
	scroll.Position = UDim2.fromOffset(14, 92)
	scroll.Size = UDim2.new(1, -28, 1, -106)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.ZIndex = 21

	local listLayout = Instance.new("UIListLayout", scroll)
	listLayout.Padding = UDim.new(0, 10)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- === CONTENITORE ALBERO POTENZIAMENTI (Scheda Principale) ===
	local treeContainer = Instance.new("Frame", modal)
	treeContainer.Name = "UpgradeTreeContainer"
	treeContainer.Position = UDim2.fromOffset(14, 92)
	treeContainer.Size = UDim2.new(1, -28, 1, -106)
	treeContainer.BackgroundTransparency = 1
	treeContainer.Visible = false
	treeContainer.ZIndex = 21

	local treeProgLabel = Instance.new("TextLabel", treeContainer)
	treeProgLabel.Size = UDim2.new(1, 0, 0, 30)
	treeProgLabel.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
	treeProgLabel.Text = ""
	treeProgLabel.TextColor3 = THEME.Gold
	treeProgLabel.Font = Enum.Font.GothamBold
	treeProgLabel.TextSize = 13
	treeProgLabel.ZIndex = 22
	Instance.new("UICorner", treeProgLabel).CornerRadius = UDim.new(0, 8)

	local treeScroll = Instance.new("ScrollingFrame", treeContainer)
	treeScroll.Name = "UpgradeTreeScroll"
	treeScroll.Position = UDim2.fromOffset(0, 34)
	treeScroll.Size = UDim2.new(1, 0, 1, -60)
	treeScroll.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
	treeScroll.BorderSizePixel = 0
	treeScroll.ScrollingDirection = Enum.ScrollingDirection.XY
	treeScroll.ScrollBarThickness = 7
	treeScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	treeScroll.ZIndex = 21
	Instance.new("UICorner", treeScroll).CornerRadius = UDim.new(0, 12)

	local treeHintLabel = Instance.new("TextLabel", treeContainer)
	treeHintLabel.AnchorPoint = Vector2.new(0, 1)
	treeHintLabel.Position = UDim2.new(0, 0, 1, 0)
	treeHintLabel.Size = UDim2.new(1, 0, 0, 22)
	treeHintLabel.BackgroundTransparency = 1
	treeHintLabel.Text = Localization.T("en", "TREE_HOVER_HINT")
	treeHintLabel.TextColor3 = Color3.fromRGB(190, 204, 232)
	treeHintLabel.Font = Enum.Font.GothamBold
	treeHintLabel.TextSize = 12
	treeHintLabel.ZIndex = 22

	local treeLinesLayer = Instance.new("Frame", treeScroll)
	treeLinesLayer.Name = "TreeLinesLayer"
	treeLinesLayer.Size = UDim2.fromScale(1, 1)
	treeLinesLayer.BackgroundTransparency = 1
	treeLinesLayer.ZIndex = 22

	local treeNodesLayer = Instance.new("Frame", treeScroll)
	treeNodesLayer.Name = "TreeNodesLayer"
	treeNodesLayer.Size = UDim2.fromScale(1, 1)
	treeNodesLayer.BackgroundTransparency = 1
	treeNodesLayer.ZIndex = 23

	-- === TOOLTIP FLUTTUANTE AL PASSAGGIO DEL CURSORE ===
	local hoveredNodeId = nil
	local hoverTooltip = Instance.new("Frame", modal)
	hoverTooltip.Name = "TreeHoverTooltip"
	hoverTooltip.Size = UDim2.fromOffset(276, 0)
	hoverTooltip.AutomaticSize = Enum.AutomaticSize.Y
	hoverTooltip.BackgroundColor3 = Color3.fromRGB(14, 17, 28)
	hoverTooltip.BackgroundTransparency = 0.03
	hoverTooltip.Visible = false
	hoverTooltip.ZIndex = 35
	Instance.new("UICorner", hoverTooltip).CornerRadius = UDim.new(0, 12)

	local ttStroke = Instance.new("UIStroke", hoverTooltip)
	ttStroke.Color = THEME.Gold
	ttStroke.Thickness = 1.8

	local ttPad = Instance.new("UIPadding", hoverTooltip)
	ttPad.PaddingTop = UDim.new(0, 10)
	ttPad.PaddingBottom = UDim.new(0, 10)
	ttPad.PaddingLeft = UDim.new(0, 12)
	ttPad.PaddingRight = UDim.new(0, 12)

	local ttLayout = Instance.new("UIListLayout", hoverTooltip)
	ttLayout.Padding = UDim.new(0, 5)
	ttLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local ttTitle = Instance.new("TextLabel", hoverTooltip)
	ttTitle.LayoutOrder = 1
	ttTitle.Size = UDim2.new(1, 0, 0, 0)
	ttTitle.AutomaticSize = Enum.AutomaticSize.Y
	ttTitle.BackgroundTransparency = 1
	ttTitle.TextColor3 = THEME.TextMain
	ttTitle.TextXAlignment = Enum.TextXAlignment.Left
	ttTitle.TextWrapped = true
	ttTitle.Font = Enum.Font.GothamBlack
	ttTitle.TextSize = 14
	ttTitle.ZIndex = 36

	local ttTag = Instance.new("TextLabel", hoverTooltip)
	ttTag.LayoutOrder = 2
	ttTag.Size = UDim2.new(1, 0, 0, 0)
	ttTag.AutomaticSize = Enum.AutomaticSize.Y
	ttTag.BackgroundTransparency = 1
	ttTag.TextColor3 = THEME.Cyan
	ttTag.TextXAlignment = Enum.TextXAlignment.Left
	ttTag.TextWrapped = true
	ttTag.Font = Enum.Font.GothamBold
	ttTag.TextSize = 13
	ttTag.ZIndex = 36

	local ttDesc = Instance.new("TextLabel", hoverTooltip)
	ttDesc.LayoutOrder = 3
	ttDesc.Size = UDim2.new(1, 0, 0, 0)
	ttDesc.AutomaticSize = Enum.AutomaticSize.Y
	ttDesc.BackgroundTransparency = 1
	ttDesc.TextColor3 = THEME.TextSub
	ttDesc.TextXAlignment = Enum.TextXAlignment.Left
	ttDesc.TextWrapped = true
	ttDesc.Font = Enum.Font.Gotham
	ttDesc.TextSize = 13
	ttDesc.ZIndex = 36

	local ttFooter = Instance.new("TextLabel", hoverTooltip)
	ttFooter.LayoutOrder = 4
	ttFooter.Size = UDim2.new(1, 0, 0, 0)
	ttFooter.AutomaticSize = Enum.AutomaticSize.Y
	ttFooter.BackgroundTransparency = 1
	ttFooter.TextColor3 = THEME.Gold
	ttFooter.TextXAlignment = Enum.TextXAlignment.Left
	ttFooter.TextWrapped = true
	ttFooter.Font = Enum.Font.GothamBlack
	ttFooter.TextSize = 12
	ttFooter.ZIndex = 36

	local function positionHoverTooltip(anchorBtn)
		if not anchorBtn or not anchorBtn.Parent then return end
		local modalPos = modal.AbsolutePosition
		local modalSize = modal.AbsoluteSize
		local btnPos = anchorBtn.AbsolutePosition - modalPos
		local btnSize = anchorBtn.AbsoluteSize
		local ttW = 276
		local ttH = math.max(108, hoverTooltip.AbsoluteSize.Y)

		local x = btnPos.X + btnSize.X + 10
		if x + ttW > modalSize.X - 10 then
			x = btnPos.X - ttW - 10
		end
		x = math.clamp(x, 10, math.max(10, modalSize.X - ttW - 10))

		local y = math.clamp(btnPos.Y - 6, 48, math.max(48, modalSize.Y - ttH - 10))
		hoverTooltip.Position = UDim2.fromOffset(x, y)
	end

	local function updateHoverTooltip()
		if not hoveredNodeId or not latestState or activeTab ~= "Character" or not isOpen then
			hoverTooltip.Visible = false
			return
		end
		local targetRef = nil
		for _, ref in ipairs(treeNodeRefs) do
			if ref.Config.Id == hoveredNodeId then
				targetRef = ref
				break
			end
		end
		if not targetRef then
			hoverTooltip.Visible = false
			return
		end

		local st = latestState
		local lang = getLang()
		local lightUnit = Localization.T(lang, "LIGHT_UNIT")
		local dataProxy = { Upgrades = st.Upgrades or {}, Altars = st.Altars or {} }
		local u = targetRef.Config
		local lvl = EconomyEngine.GetUpgradeLevel(dataProxy, u.Id)
		local maxLvl = u.MaxLevel or 1
		local maxed = lvl >= maxLvl
		local discountLvl = EconomyEngine.GetLevel(st.AlbaPerks, "ap_discount")
		local cost = GameConfig.GetUpgradeCost(u, lvl, st.AlbaCount or 0, discountLvl)
		local canBuy = (not maxed) and ((st.Points or 0) >= cost)

		local uName = Localization.Pick(lang, u.Name, u.Name_it)
		local uTag = Localization.Pick(lang, u.Tag, u.Tag_it)
		local uDesc = Localization.Pick(lang, u.Desc, u.Desc_it)

		ttTitle.Text = string.format("%s %s  [%d/%d]", u.Icon or "🔥", uName, lvl, maxLvl)
		ttTag.Text = uTag
		ttTag.TextColor3 = u.Color or THEME.Cyan
		ttDesc.Text = uDesc

		if maxed then
			ttFooter.Text = "✅ " .. Localization.T(lang, "BTN_MAXED")
			ttFooter.TextColor3 = THEME.Green
			ttStroke.Color = THEME.Green
		elseif canBuy then
			ttFooter.Text = string.format("💰 %s %s  •  %s", NumberFormat.Format(cost), lightUnit, Localization.T(lang, "TREE_TIP_CLICK"))
			ttFooter.TextColor3 = THEME.Gold
			ttStroke.Color = THEME.Gold
		else
			ttFooter.Text = string.format("🔒 %s %s", NumberFormat.Format(cost), lightUnit)
			ttFooter.TextColor3 = THEME.TextSub
			ttStroke.Color = u.Color or THEME.Cyan
		end

		hoverTooltip.Visible = true
		positionHoverTooltip(targetRef.Card)
	end

	local function clearScroll()
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

	local function clearTreeLayers()
		treeNodeRefs = {}
		treeLineRefs = {}
		for _, child in ipairs(treeLinesLayer:GetChildren()) do
			child:Destroy()
		end
		for _, child in ipairs(treeNodesLayer:GetChildren()) do
			child:Destroy()
		end
	end

	local function drawTreeConnector(parentPos, childPos, nodeW, nodeH, gapY, color)
		local startX = parentPos.X + nodeW * 0.5
		local startY = parentPos.Y + nodeH
		local endX = childPos.X + nodeW * 0.5
		local endY = childPos.Y
		local thick = 3

		local segs = {}
		if math.abs(startX - endX) < 2 then
			local seg = Instance.new("Frame", treeLinesLayer)
			seg.BorderSizePixel = 0
			seg.BackgroundColor3 = color
			seg.Position = UDim2.fromOffset(startX - thick * 0.5, startY)
			seg.Size = UDim2.fromOffset(thick, math.max(2, endY - startY))
			seg.ZIndex = 22
			table.insert(segs, seg)
		else
			local midY = startY + gapY * 0.5
			local v1 = Instance.new("Frame", treeLinesLayer)
			v1.BorderSizePixel = 0
			v1.BackgroundColor3 = color
			v1.Position = UDim2.fromOffset(startX - thick * 0.5, startY)
			v1.Size = UDim2.fromOffset(thick, math.max(2, midY - startY))
			v1.ZIndex = 22

			local minX = math.min(startX, endX)
			local maxX = math.max(startX, endX)
			local h1 = Instance.new("Frame", treeLinesLayer)
			h1.BorderSizePixel = 0
			h1.BackgroundColor3 = color
			h1.Position = UDim2.fromOffset(minX - thick * 0.5, midY - thick * 0.5)
			h1.Size = UDim2.fromOffset((maxX - minX) + thick, thick)
			h1.ZIndex = 22

			local v2 = Instance.new("Frame", treeLinesLayer)
			v2.BorderSizePixel = 0
			v2.BackgroundColor3 = color
			v2.Position = UDim2.fromOffset(endX - thick * 0.5, midY)
			v2.Size = UDim2.fromOffset(thick, math.max(2, endY - midY))
			v2.ZIndex = 22

			table.insert(segs, v1)
			table.insert(segs, h1)
			table.insert(segs, v2)
		end
		return segs
	end

	local function buildUpgradeTreeLayout()
		clearTreeLayers()
		if not latestState then return end
		local st = latestState
		local lang = getLang()
		local dataProxy = { Upgrades = st.Upgrades or {}, Altars = st.Altars or {} }

		local visibleNodes = {}
		local sigParts = { lang }
		for _, u in ipairs(GameConfig.Upgrades) do
			local lvl = EconomyEngine.GetUpgradeLevel(dataProxy, u.Id)
			local unlocked = EconomyEngine.IsUpgradeUnlocked(dataProxy, u)
			if lvl > 0 or unlocked then
				table.insert(visibleNodes, u)
				table.insert(sigParts, u.Id)
			end
		end
		renderedTreeSig = table.concat(sigParts, ",")

		local NODE_W = 88
		local NODE_H = 92
		local GAP_X = 16
		local GAP_Y = 28
		local STEP_X = NODE_W + GAP_X
		local STEP_Y = NODE_H + GAP_Y
		local PAD = 18

		local minCol, maxCol = 999, -999
		local minRow, maxRow = 999, -999
		for _, u in ipairs(visibleNodes) do
			local c = u.TreeCol or 0
			local r = u.TreeRow or 0
			if c < minCol then minCol = c end
			if c > maxCol then maxCol = c end
			if r < minRow then minRow = r end
			if r > maxRow then maxRow = r end
		end
		if minCol > maxCol then
			minCol, maxCol, minRow, maxRow = 0, 0, 0, 0
		end

		local rawW = (maxCol - minCol + 1) * NODE_W + (maxCol - minCol) * GAP_X + PAD * 2
		local rawH = (maxRow - minRow + 1) * NODE_H + (maxRow - minRow) * GAP_Y + PAD * 2
		local absW = treeScroll.AbsoluteSize.X
		local absH = treeScroll.AbsoluteSize.Y
		local viewW = (absW > 120) and absW or 740
		local viewH = (absH > 120) and absH or 320
		local canvasW = math.max(viewW, rawW)
		local canvasH = math.max(viewH, rawH)

		treeScroll.CanvasSize = UDim2.fromOffset(canvasW, canvasH)
		treeLinesLayer.Size = UDim2.fromOffset(canvasW, canvasH)
		treeNodesLayer.Size = UDim2.fromOffset(canvasW, canvasH)

		local originX = (canvasW > rawW) and ((canvasW - rawW) * 0.5 + PAD) or PAD
		local originY = PAD

		local posById = {}
		for _, u in ipairs(visibleNodes) do
			local x = originX + ((u.TreeCol or 0) - minCol) * STEP_X
			local y = originY + ((u.TreeRow or 0) - minRow) * STEP_Y
			posById[u.Id] = Vector2.new(x, y)
		end

		for _, u in ipairs(visibleNodes) do
			if u.ReqId and posById[u.ReqId] and posById[u.Id] then
				local segs = drawTreeConnector(posById[u.ReqId], posById[u.Id], NODE_W, NODE_H, GAP_Y, THEME.Cyan)
				table.insert(treeLineRefs, { Config = u, Segments = segs })
			end

			local p = posById[u.Id]
			local nodeBtn = Instance.new("TextButton", treeNodesLayer)
			nodeBtn.Name = "TreeNode_" .. u.Id
			nodeBtn.Position = UDim2.fromOffset(p.X, p.Y)
			nodeBtn.Size = UDim2.fromOffset(NODE_W, NODE_H)
			nodeBtn.BackgroundColor3 = THEME.Card
			nodeBtn.Text = ""
			nodeBtn.AutoButtonColor = true
			nodeBtn.ZIndex = 23
			Instance.new("UICorner", nodeBtn).CornerRadius = UDim.new(0, 14)

			local stroke = Instance.new("UIStroke", nodeBtn)
			stroke.Color = u.Color or THEME.Cyan
			stroke.Thickness = 2.0

			local iconBg = Instance.new("Frame", nodeBtn)
			iconBg.AnchorPoint = Vector2.new(0.5, 0)
			iconBg.Position = UDim2.new(0.5, 0, 0, 14)
			iconBg.Size = UDim2.fromOffset(48, 48)
			iconBg.BackgroundColor3 = (u.Color or THEME.Cyan):Lerp(Color3.fromRGB(16, 18, 28), 0.72)
			iconBg.ZIndex = 24
			Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)

			local iconLbl = Instance.new("TextLabel", iconBg)
			iconLbl.Size = UDim2.fromScale(1, 1)
			iconLbl.BackgroundTransparency = 1
			iconLbl.Text = u.Icon or "🔥"
			iconLbl.TextSize = 28
			iconLbl.ZIndex = 25

			local lvlBadge = Instance.new("TextLabel", nodeBtn)
			lvlBadge.AnchorPoint = Vector2.new(1, 0)
			lvlBadge.Position = UDim2.new(1, -4, 0, 4)
			lvlBadge.Size = UDim2.fromOffset(42, 17)
			lvlBadge.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
			lvlBadge.TextColor3 = THEME.TextMain
			lvlBadge.Font = Enum.Font.GothamBlack
			lvlBadge.TextSize = 11
			lvlBadge.ZIndex = 26
			Instance.new("UICorner", lvlBadge).CornerRadius = UDim.new(0, 6)

			local costLbl = Instance.new("TextLabel", nodeBtn)
			costLbl.AnchorPoint = Vector2.new(0.5, 1)
			costLbl.Position = UDim2.new(0.5, 0, 1, -5)
			costLbl.Size = UDim2.new(1, -10, 0, 20)
			costLbl.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
			costLbl.TextColor3 = THEME.TextMain
			costLbl.Font = Enum.Font.GothamBlack
			costLbl.TextSize = 11
			costLbl.TextTruncate = Enum.TextTruncate.AtEnd
			costLbl.ZIndex = 25
			Instance.new("UICorner", costLbl).CornerRadius = UDim.new(0, 6)

			nodeBtn.MouseEnter:Connect(function()
				hoveredNodeId = u.Id
				updateHoverTooltip()
			end)
			nodeBtn.MouseLeave:Connect(function()
				if hoveredNodeId == u.Id then
					hoveredNodeId = nil
					hoverTooltip.Visible = false
				end
			end)
			nodeBtn.MouseButton1Click:Connect(function()
				hoveredNodeId = u.Id
				updateHoverTooltip()
				local now = os.clock()
				if now - lastActionClock < 0.08 then return end
				lastActionClock = now
				remotes.BuyUpgrade:FireServer(u.Id)
			end)

			table.insert(treeNodeRefs, {
				Config = u,
				Card = nodeBtn,
				Stroke = stroke,
				IconBg = iconBg,
				LvlBadge = lvlBadge,
				CostLbl = costLbl,
			})
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
		local discountLvl = EconomyEngine.GetLevel(st.AlbaPerks, "ap_discount")

		if renderedTab == "Character" then
			local dataProxy = { Upgrades = st.Upgrades or {}, Altars = st.Altars or {} }
			local sigParts = { lang }
			local unlockedCnt, maxedCnt = 0, 0
			local totalCnt = #GameConfig.Upgrades

			for _, u in ipairs(GameConfig.Upgrades) do
				local lvl = EconomyEngine.GetUpgradeLevel(dataProxy, u.Id)
				local unlocked = EconomyEngine.IsUpgradeUnlocked(dataProxy, u)
				if lvl >= (u.MaxLevel or 1) then
					maxedCnt += 1
				end
				if lvl > 0 or unlocked then
					unlockedCnt += 1
					table.insert(sigParts, u.Id)
				end
			end

			treeProgLabel.Text = Localization.T(lang, "TREE_PROG_FMT", unlockedCnt, totalCnt, maxedCnt, totalCnt)
			treeHintLabel.Text = Localization.T(lang, "TREE_HOVER_HINT")

			local newSig = table.concat(sigParts, ",")
			if newSig ~= renderedTreeSig then
				local prevCanvas = treeScroll.CanvasPosition
				buildUpgradeTreeLayout()
				treeScroll.CanvasPosition = prevCanvas
			end

			for _, lRef in ipairs(treeLineRefs) do
				local cLvl = EconomyEngine.GetUpgradeLevel(dataProxy, lRef.Config.Id)
				local lineCol = (cLvl >= 1) and THEME.Gold or THEME.Cyan
				for _, seg in ipairs(lRef.Segments) do
					seg.BackgroundColor3 = lineCol
				end
			end

			for _, ref in ipairs(treeNodeRefs) do
				local u = ref.Config
				local lvl = EconomyEngine.GetUpgradeLevel(dataProxy, u.Id)
				local maxLvl = u.MaxLevel or 1
				local maxed = lvl >= maxLvl
				local cost = GameConfig.GetUpgradeCost(u, lvl, albaCount, discountLvl)
				local canBuy = (not maxed) and points >= cost

				if maxed then
					ref.Card.BackgroundColor3 = Color3.fromRGB(22, 44, 36)
					ref.Stroke.Color = THEME.Green
					ref.IconBg.BackgroundColor3 = THEME.Green:Lerp(Color3.fromRGB(16, 26, 22), 0.72)
					ref.CostLbl.BackgroundColor3 = Color3.fromRGB(35, 72, 54)
					ref.CostLbl.Text = Localization.T(lang, "BTN_MAXED")
					ref.CostLbl.TextColor3 = THEME.Green
				elseif canBuy then
					ref.Card.BackgroundColor3 = Color3.fromRGB(36, 36, 48)
					ref.Stroke.Color = THEME.Gold
					ref.IconBg.BackgroundColor3 = (u.Color or THEME.Gold):Lerp(Color3.fromRGB(24, 24, 32), 0.62)
					ref.CostLbl.BackgroundColor3 = THEME.Gold
					ref.CostLbl.Text = NumberFormat.Format(cost)
					ref.CostLbl.TextColor3 = Color3.fromRGB(16, 18, 24)
				elseif lvl >= 1 then
					ref.Card.BackgroundColor3 = THEME.Card
					ref.Stroke.Color = u.Color or THEME.Cyan
					ref.IconBg.BackgroundColor3 = (u.Color or THEME.Cyan):Lerp(Color3.fromRGB(16, 18, 28), 0.70)
					ref.CostLbl.BackgroundColor3 = Color3.fromRGB(28, 34, 50)
					ref.CostLbl.Text = NumberFormat.Format(cost)
					ref.CostLbl.TextColor3 = THEME.TextMain
				else
					ref.Card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
					ref.Stroke.Color = Color3.fromRGB(85, 130, 175)
					ref.IconBg.BackgroundColor3 = Color3.fromRGB(28, 34, 50)
					ref.CostLbl.BackgroundColor3 = Color3.fromRGB(28, 34, 50)
					ref.CostLbl.Text = NumberFormat.Format(cost)
					ref.CostLbl.TextColor3 = THEME.TextSub
				end

				ref.LvlBadge.Text = string.format("%d/%d", lvl, maxLvl)
				ref.LvlBadge.TextColor3 = maxed and THEME.Green or THEME.TextMain
			end

			if hoveredNodeId then
				updateHoverTooltip()
			end

		elseif renderedTab == "Defense" and defenseRefs then
			for _, dRef in ipairs(defenseRefs.Structures) do
				local d = dRef.Config

				if d.ReqDefenseId then
					local reqLvl = EconomyEngine.GetLevel(st.Defenses, d.ReqDefenseId)
					dRef.Card.Visible = reqLvl >= (d.ReqDefenseLvl or 1)
				else
					dRef.Card.Visible = true
				end

				local lvl = EconomyEngine.GetLevel(st.Defenses, d.Id)
				local maxed = lvl >= d.MaxLevel
				local costInfo = GameConfig.GetDefenseCost(d, lvl, albaCount, discountLvl)
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
				local unitWispCost = GameConfig.GetWispCost(albaCount, discountLvl)
				wispHeaderRefs.Card.Visible = st.WispsUnlocked == true
				wispHeaderRefs.Info.Text = Localization.T(lang, "WISPS_HEADER_FMT", st.EquippedCount or 0, st.MaxWispSlots or 3)
				wispHeaderRefs.Btn1.Text = Localization.T(lang, "SUMMON_1_FMT", NumberFormat.Format(unitWispCost))
				wispHeaderRefs.Btn1.BackgroundColor3 = (points >= unitWispCost) and THEME.Cyan or Color3.fromRGB(36, 40, 56)
				wispHeaderRefs.Btn1.TextColor3 = (points >= unitWispCost) and Color3.fromRGB(16, 18, 24) or THEME.TextMain
				local cost5 = unitWispCost * 5
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
				or Localization.T(lang, "DAWN_STATUS_PROG", st.CompletedUpgradesCount or 0, st.TotalUpgradesCount or 22, rewardPerRebirth)

			albaRefs.HeaderInfo.Text = Localization.T(lang, "DAWN_HEADER_FMT", albaPts, albaCount, statusTxt)

			for _, apRef in ipairs(albaRefs.Perks) do
				local ap = apRef.Config
				local lvl = EconomyEngine.GetLevel(st.AlbaPerks, ap.Id)
				local maxed = lvl >= ap.MaxLevel
				local cost = math.floor(ap.Cost * (ap.CostMult ^ lvl))
				local canBuy = (not maxed) and albaPts >= cost

				apRef.Card.BackgroundColor3 = maxed
					and Color3.fromRGB(22, 42, 36)
					or (canBuy and Color3.fromRGB(42, 36, 24) or THEME.Card)
				apRef.CardStroke.Color = maxed and THEME.Green or THEME.Gold
				apRef.CardStroke.Transparency = canBuy and 0 or 0.18
				apRef.Title.Text = string.format("%s %s  [Lv.%d/%d]", ap.Icon or "🌅", Localization.Pick(lang, ap.Name, ap.Name_it), lvl, ap.MaxLevel)
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
				zRef.CardStroke.Color = isUnlocked and THEME.Green or THEME.Cyan
				zRef.CardStroke.Transparency = canUnlock and 0 or 0.18
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
		local isQuickPage = activeTab == "Defense" or activeTab == "Wisps" or activeTab == "Daily"
		tabsBar.Visible = not isQuickPage
		local contentTop = isQuickPage and 58 or 92
		local contentBottom = isQuickPage and 72 or 106
		scroll.Position = UDim2.fromOffset(14, contentTop)
		scroll.Size = UDim2.new(1, -28, 1, -contentBottom)
		treeContainer.Position = UDim2.fromOffset(14, contentTop)
		treeContainer.Size = UDim2.new(1, -28, 1, -contentBottom)
		local titleKey = ({
			Defense = "TURRET_MODAL_TITLE",
			Wisps = "WISPS_MODAL_TITLE",
			Daily = "DAILY_MODAL_TITLE",
		})[activeTab] or "MODAL_TITLE"
		headerTitle.Text = Localization.T(lang, titleKey)

		for _, td in ipairs(tabDefs) do
			local btn = tabButtons[td.Id]
			if btn then
				btn.Text = Localization.T(lang, td.Key)
				btn.BackgroundColor3 = (td.Id == activeTab) and Color3.fromRGB(58, 46, 22) or THEME.Card
				btn.TextColor3 = (td.Id == activeTab) and THEME.Gold or THEME.TextSub
				tabStrokes[td.Id].Color = (td.Id == activeTab) and THEME.Gold or THEME.Cyan
				tabStrokes[td.Id].Transparency = (td.Id == activeTab) and 0 or 0.3
			end
		end

		local isTreeTab = (activeTab == "Character")
		treeContainer.Visible = isTreeTab
		scroll.Visible = not isTreeTab

		if activeTab == "Character" then
			buildUpgradeTreeLayout()

		elseif activeTab == "Defense" then
			local tipCard = Instance.new("Frame", scroll)
			tipCard.LayoutOrder = 1
			tipCard.Size = UDim2.new(1, -6, 0, 56)
			tipCard.BackgroundColor3 = Color3.fromRGB(30, 22, 42)
			tipCard.ZIndex = 22
			Instance.new("UICorner", tipCard).CornerRadius = UDim.new(0, 10)
			styleTreeCard(tipCard, THEME.Purple)

			local tipLbl = Instance.new("TextLabel", tipCard)
			tipLbl.Position = UDim2.fromOffset(14, 6)
			tipLbl.Size = UDim2.new(1, -28, 1, -12)
			tipLbl.BackgroundTransparency = 1
			tipLbl.Text = Localization.T(lang, "DEF_TIP")
			tipLbl.TextColor3 = THEME.TextMain
			tipLbl.TextXAlignment = Enum.TextXAlignment.Left
			tipLbl.TextWrapped = true
			tipLbl.Font = Enum.Font.GothamBold
			tipLbl.TextSize = 15
			tipLbl.ZIndex = 23

			local sec2 = Instance.new("TextLabel", scroll)
			sec2.LayoutOrder = 2
			sec2.Size = UDim2.new(1, -6, 0, 26)
			sec2.BackgroundTransparency = 1
			sec2.Text = Localization.T(lang, "SEC_STRUCTURES")
			sec2.TextColor3 = THEME.Cyan
			sec2.TextXAlignment = Enum.TextXAlignment.Left
			sec2.Font = Enum.Font.GothamBlack
			sec2.TextSize = 14
			sec2.ZIndex = 22
			sec2.Position = UDim2.fromOffset(4, 0)
			sec2.Size = UDim2.new(1, -10, 0, 28)
			sec2.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
			Instance.new("UICorner", sec2).CornerRadius = UDim.new(0, 8)

			local defList = {}
			for idx, d in ipairs(GameConfig.Defenses) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 10 + idx
				row.Size = UDim2.new(1, -6, 0, 78)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				styleTreeCard(row, THEME.Cyan)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(14, 8)
				tLbl.Size = UDim2.new(1, -166, 0, 26)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.Cyan
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBlack
				tLbl.TextSize = 16
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(14, 36)
				dLbl.Size = UDim2.new(1, -166, 0, 36)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextYAlignment = Enum.TextYAlignment.Top
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 14
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -12, 0.5, 0)
				b.Size = UDim2.fromOffset(138, 50)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 14
				b.TextWrapped = true
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				styleTreeButton(b, THEME.Cyan)
				b.MouseButton1Click:Connect(function()
					remotes.BuyDefense:FireServer(d.Id)
				end)

				table.insert(defList, { Config = d, Card = row, Title = tLbl, Desc = dLbl, Btn = b })
			end

			defenseRefs = { Structures = defList }

		elseif activeTab == "Wisps" then
			local lockLbl = Instance.new("TextLabel", scroll)
			lockLbl.LayoutOrder = 0
			lockLbl.Size = UDim2.new(1, -6, 0, 84)
			lockLbl.BackgroundColor3 = THEME.Card
			lockLbl.Text = Localization.T(lang, "WISPS_LOCKED")
			lockLbl.TextColor3 = THEME.Gold
			lockLbl.Font = Enum.Font.GothamBold
			lockLbl.TextWrapped = true
			lockLbl.TextSize = 15
			lockLbl.Visible = false
			lockLbl.ZIndex = 22
			Instance.new("UICorner", lockLbl).CornerRadius = UDim.new(0, 10)
			styleTreeCard(lockLbl, THEME.Gold)
			wispLockRef = lockLbl

			local sumCard = Instance.new("Frame", scroll)
			sumCard.LayoutOrder = 1
			sumCard.Size = UDim2.new(1, -6, 0, 76)
			sumCard.BackgroundColor3 = THEME.Card
			sumCard.ZIndex = 22
			Instance.new("UICorner", sumCard).CornerRadius = UDim.new(0, 10)
			styleTreeCard(sumCard, THEME.Purple)

			local sumInfo = Instance.new("TextLabel", sumCard)
			sumInfo.Position = UDim2.fromOffset(14, 10)
			sumInfo.Size = UDim2.new(0.48, 0, 0, 56)
			sumInfo.BackgroundTransparency = 1
			sumInfo.TextColor3 = THEME.TextMain
			sumInfo.TextXAlignment = Enum.TextXAlignment.Left
			sumInfo.TextWrapped = true
			sumInfo.Font = Enum.Font.GothamBold
			sumInfo.TextSize = 15
			sumInfo.ZIndex = 23

			local btn1 = Instance.new("TextButton", sumCard)
			btn1.Position = UDim2.new(0.52, 0, 0.5, -24)
			btn1.Size = UDim2.new(0.22, 0, 0, 48)
			btn1.Font = Enum.Font.GothamBlack
			btn1.TextSize = 13
			btn1.ZIndex = 23
			Instance.new("UICorner", btn1).CornerRadius = UDim.new(0, 8)
			styleTreeButton(btn1, THEME.Cyan)
			btn1.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(1)
			end)

			local btn5 = Instance.new("TextButton", sumCard)
			btn5.Position = UDim2.new(0.76, 0, 0.5, -24)
			btn5.Size = UDim2.new(0.22, 0, 0, 48)
			btn5.Font = Enum.Font.GothamBlack
			btn5.TextSize = 13
			btn5.ZIndex = 23
			Instance.new("UICorner", btn5).CornerRadius = UDim.new(0, 8)
			styleTreeButton(btn5, THEME.Gold)
			btn5.MouseButton1Click:Connect(function()
				remotes.SummonWisp:FireServer(5)
			end)

			wispHeaderRefs = { Card = sumCard, Info = sumInfo, Btn1 = btn1, Btn5 = btn5 }

			for idx, w in ipairs(GameConfig.Wisps) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = idx + 1
				row.Size = UDim2.new(1, -6, 0, 64)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				styleTreeCard(row, w.Color)

				local lbl = Instance.new("TextLabel", row)
				lbl.Position = UDim2.fromOffset(14, 8)
				lbl.Size = UDim2.new(1, -172, 0, 48)
				lbl.BackgroundTransparency = 1
				lbl.TextColor3 = w.Color
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextWrapped = true
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 15
				lbl.ZIndex = 23

				local fuseBtn = Instance.new("TextButton", row)
				fuseBtn.AnchorPoint = Vector2.new(1, 0.5)
				fuseBtn.Position = UDim2.new(1, -12, 0.5, 0)
				fuseBtn.Size = UDim2.fromOffset(144, 42)
				fuseBtn.TextColor3 = THEME.TextMain
				fuseBtn.Font = Enum.Font.GothamBold
				fuseBtn.TextSize = 12
				fuseBtn.ZIndex = 23
				Instance.new("UICorner", fuseBtn).CornerRadius = UDim.new(0, 8)
				styleTreeButton(fuseBtn, THEME.Purple)
				fuseBtn.MouseButton1Click:Connect(function()
					remotes.FuseWisp:FireServer(w.Id)
				end)

				table.insert(wispRowRefs, { Config = w, Row = row, Label = lbl, FuseBtn = fuseBtn })
			end

		elseif activeTab == "Daily" then
			local intro = Instance.new("TextLabel", scroll)
			intro.LayoutOrder = 1
			intro.Size = UDim2.new(1, -6, 0, 68)
			intro.BackgroundColor3 = THEME.Card
			intro.Text = Localization.T(lang, "DAILY_COMING_SOON")
			intro.TextColor3 = THEME.Gold
			intro.Font = Enum.Font.GothamBold
			intro.TextWrapped = true
			intro.TextSize = 15
			intro.ZIndex = 22
			Instance.new("UICorner", intro).CornerRadius = UDim.new(0, 10)
			styleTreeCard(intro, THEME.Gold)
			intro.TextSize = 17

			local calendar = Instance.new("Frame", scroll)
			calendar.Name = "DailyRewardCalendar"
			calendar.LayoutOrder = 2
			calendar.Size = UDim2.new(1, -6, 0, 262)
			calendar.BackgroundTransparency = 1
			calendar.ZIndex = 22

			local grid = Instance.new("UIGridLayout", calendar)
			grid.CellSize = UDim2.new(1 / 3, -8, 0, 80)
			grid.CellPadding = UDim2.fromOffset(8, 8)
			grid.FillDirectionMaxCells = 3
			grid.SortOrder = Enum.SortOrder.LayoutOrder

			for day = 1, 7 do
				local card = Instance.new("Frame", calendar)
				card.Name = "Day" .. day
				card.LayoutOrder = day
				card.BackgroundColor3 = THEME.Card
				card.ZIndex = 23
				Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
				styleTreeCard(card, day == 7 and THEME.Gold or THEME.Cyan)

				local dayLabel = Instance.new("TextLabel", card)
				dayLabel.Size = UDim2.new(1, -8, 0, 28)
				dayLabel.Position = UDim2.fromOffset(4, 7)
				dayLabel.BackgroundTransparency = 1
				dayLabel.Text = Localization.T(lang, "DAILY_DAY") .. " " .. day
				dayLabel.TextColor3 = THEME.Gold
				dayLabel.Font = Enum.Font.GothamBlack
				dayLabel.TextSize = 15
				dayLabel.ZIndex = 24

				local rewardLabel = Instance.new("TextLabel", card)
				rewardLabel.Position = UDim2.fromOffset(5, 36)
				rewardLabel.Size = UDim2.new(1, -10, 0, 36)
				rewardLabel.BackgroundTransparency = 1
				rewardLabel.Text = Localization.T(lang, "DAILY_REWARD_SOON")
				rewardLabel.TextColor3 = THEME.TextSub
				rewardLabel.Font = Enum.Font.Gotham
				rewardLabel.TextWrapped = true
				rewardLabel.TextSize = 13
				rewardLabel.ZIndex = 24
			end

		elseif activeTab == "Alba" then
			local hCard = Instance.new("Frame", scroll)
			hCard.LayoutOrder = 1
			hCard.Size = UDim2.new(1, -6, 0, 78)
			hCard.BackgroundColor3 = Color3.fromRGB(34, 28, 22)
			hCard.ZIndex = 22
			Instance.new("UICorner", hCard).CornerRadius = UDim.new(0, 10)
			styleTreeCard(hCard, THEME.Gold)

			local hInfo = Instance.new("TextLabel", hCard)
			hInfo.Position = UDim2.fromOffset(14, 8)
			hInfo.Size = UDim2.new(1, -28, 0, 62)
			hInfo.BackgroundTransparency = 1
			hInfo.TextColor3 = THEME.Gold
			hInfo.TextXAlignment = Enum.TextXAlignment.Left
			hInfo.TextWrapped = true
			hInfo.Font = Enum.Font.GothamBold
			hInfo.TextSize = 15
			hInfo.ZIndex = 23

			local sec1 = Instance.new("TextLabel", scroll)
			sec1.LayoutOrder = 2
			sec1.Size = UDim2.new(1, -6, 0, 26)
			sec1.BackgroundTransparency = 1
			sec1.Text = Localization.T(lang, "SEC_DAWN_PERKS")
			sec1.TextColor3 = THEME.Gold
			sec1.TextXAlignment = Enum.TextXAlignment.Left
			sec1.Font = Enum.Font.GothamBlack
			sec1.TextSize = 14
			sec1.ZIndex = 22
			sec1.Position = UDim2.fromOffset(4, 0)
			sec1.Size = UDim2.new(1, -10, 0, 28)
			sec1.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
			sec1.BackgroundTransparency = 0
			Instance.new("UICorner", sec1).CornerRadius = UDim.new(0, 8)

			local perksList = {}
			for idx, ap in ipairs(GameConfig.AlbaPerks) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 10 + idx
				row.Size = UDim2.new(1, -6, 0, 82)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				local cardStroke = styleTreeCard(row, THEME.Gold)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(14, 8)
				tLbl.Size = UDim2.new(1, -166, 0, 26)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.TextMain
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBlack
				tLbl.TextSize = 16
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(14, 36)
				dLbl.Size = UDim2.new(1, -166, 0, 40)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextYAlignment = Enum.TextYAlignment.Top
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 14
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -12, 0.5, 0)
				b.Size = UDim2.fromOffset(138, 50)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 13
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				styleTreeButton(b, THEME.Gold)
				b.MouseButton1Click:Connect(function()
					remotes.BuyAlbaPerk:FireServer(ap.Id)
				end)

				table.insert(perksList, { Config = ap, Card = row, CardStroke = cardStroke, Title = tLbl, Desc = dLbl, Btn = b })
			end

			local sec2 = Instance.new("TextLabel", scroll)
			sec2.LayoutOrder = 30
			sec2.Size = UDim2.new(1, -6, 0, 26)
			sec2.BackgroundTransparency = 1
			sec2.Text = Localization.T(lang, "SEC_DAWN_ZONES")
			sec2.TextColor3 = THEME.Cyan
			sec2.TextXAlignment = Enum.TextXAlignment.Left
			sec2.Font = Enum.Font.GothamBlack
			sec2.TextSize = 14
			sec2.ZIndex = 22
			sec2.Position = UDim2.fromOffset(4, 0)
			sec2.Size = UDim2.new(1, -10, 0, 28)
			sec2.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
			sec2.BackgroundTransparency = 0
			Instance.new("UICorner", sec2).CornerRadius = UDim.new(0, 8)

			local zonesList = {}
			for idx, z in ipairs(GameConfig.AlbaZones) do
				local row = Instance.new("Frame", scroll)
				row.LayoutOrder = 40 + idx
				row.Size = UDim2.new(1, -6, 0, 82)
				row.BackgroundColor3 = THEME.Card
				row.ZIndex = 22
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
				local cardStroke = styleTreeCard(row, THEME.Cyan)

				local tLbl = Instance.new("TextLabel", row)
				tLbl.Position = UDim2.fromOffset(14, 8)
				tLbl.Size = UDim2.new(1, -166, 0, 22)
				tLbl.BackgroundTransparency = 1
				tLbl.TextColor3 = THEME.Cyan
				tLbl.TextXAlignment = Enum.TextXAlignment.Left
				tLbl.Font = Enum.Font.GothamBlack
				tLbl.TextSize = 16
				tLbl.ZIndex = 23

				local dLbl = Instance.new("TextLabel", row)
				dLbl.Position = UDim2.fromOffset(14, 30)
				dLbl.Size = UDim2.new(1, -166, 0, 34)
				dLbl.BackgroundTransparency = 1
				dLbl.TextColor3 = THEME.TextSub
				dLbl.TextXAlignment = Enum.TextXAlignment.Left
				dLbl.TextYAlignment = Enum.TextYAlignment.Top
				dLbl.TextWrapped = true
				dLbl.Font = Enum.Font.Gotham
				dLbl.TextSize = 14
				dLbl.ZIndex = 23

				local b = Instance.new("TextButton", row)
				b.AnchorPoint = Vector2.new(1, 0.5)
				b.Position = UDim2.new(1, -12, 0.5, 0)
				b.Size = UDim2.fromOffset(138, 50)
				b.Font = Enum.Font.GothamBlack
				b.TextSize = 13
				b.ZIndex = 23
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
				styleTreeButton(b, THEME.Cyan)
				b.MouseButton1Click:Connect(function()
					remotes.UnlockAlbaZone:FireServer(z.Id)
				end)

				table.insert(zonesList, { Config = z, Card = row, CardStroke = cardStroke, Title = tLbl, Desc = dLbl, Btn = b })
			end

			albaRefs = { HeaderInfo = hInfo, Perks = perksList, Zones = zonesList }

		elseif activeTab == "Codes" then
			local cCard = Instance.new("Frame", scroll)
			cCard.LayoutOrder = 1
			cCard.Size = UDim2.new(1, -6, 0, 144)
			cCard.BackgroundColor3 = THEME.Card
			cCard.ZIndex = 22
			Instance.new("UICorner", cCard).CornerRadius = UDim.new(0, 10)
			styleTreeCard(cCard, THEME.Purple)

			local box = Instance.new("TextBox", cCard)
			box.Position = UDim2.fromOffset(14, 14)
			box.Size = UDim2.new(1, -172, 0, 50)
			box.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
			box.PlaceholderText = Localization.T(lang, "CODE_PLACEHOLDER")
			box.Text = ""
			box.TextColor3 = THEME.TextMain
			box.Font = Enum.Font.GothamBold
			box.TextSize = 16
			box.ZIndex = 23
			Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

			local statusLbl = Instance.new("TextLabel", cCard)
			statusLbl.Position = UDim2.fromOffset(14, 76)
			statusLbl.Size = UDim2.new(1, -28, 0, 48)
			statusLbl.BackgroundTransparency = 1
			statusLbl.Text = Localization.T(lang, "CODE_HINT")
			statusLbl.TextColor3 = THEME.TextSub
			statusLbl.TextXAlignment = Enum.TextXAlignment.Left
			statusLbl.Font = Enum.Font.Gotham
			statusLbl.TextSize = 15
			statusLbl.ZIndex = 23

			local redeemBtn = Instance.new("TextButton", cCard)
			redeemBtn.AnchorPoint = Vector2.new(1, 0)
			redeemBtn.Position = UDim2.new(1, -14, 0, 14)
			redeemBtn.Size = UDim2.fromOffset(138, 50)
			redeemBtn.BackgroundColor3 = THEME.Green
			redeemBtn.Text = Localization.T(lang, "CODE_REDEEM")
			redeemBtn.TextColor3 = Color3.fromRGB(16, 18, 24)
			redeemBtn.Font = Enum.Font.GothamBlack
			redeemBtn.TextSize = 15
			redeemBtn.ZIndex = 23
			Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 8)
			styleTreeButton(redeemBtn, THEME.Green)

			redeemBtn.MouseButton1Click:Connect(function()
				local ok, msg = remotes.RedeemCode:InvokeServer(box.Text)
				statusLbl.Text = tostring(msg)
				statusLbl.TextColor3 = ok and THEME.Green or Color3.fromRGB(255, 110, 120)
				if ok then box.Text = "" end
			end)
		end

		refreshExistingWidgets()
	end

	treeScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if isOpen and activeTab == "Character" and latestState then
			buildUpgradeTreeLayout()
			refreshExistingWidgets()
		end
	end)

	for id, btn in pairs(tabButtons) do
		btn.MouseButton1Click:Connect(function()
			activeTab = id
			if activeTab ~= "Character" then
				hoveredNodeId = nil
				hoverTooltip.Visible = false
			end
			buildTabStructure()
		end)
	end

	setOpen = function(val)
		isOpen = val
		modal.Visible = isOpen
		if not isOpen then
			hoveredNodeId = nil
			hoverTooltip.Visible = false
		else
			if renderedTab ~= activeTab or renderedLang ~= getLang() then
				buildTabStructure()
			else
				refreshExistingWidgets()
			end
		end
	end

	local function toggleCharacterMenu()
		local wasCharacterOpen = isOpen and activeTab == "Character"
		activeTab = "Character"
		setOpen(not wasCharacterOpen)
	end

	toggleBtn.MouseButton1Click:Connect(toggleCharacterMenu)
	closeBtn.MouseButton1Click:Connect(function()
		setOpen(false)
	end)
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == Enum.KeyCode.B then
			toggleCharacterMenu()
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

			local graceRem = math.max(0, math.floor(st.ShadowGraceRemaining or 0))
			if graceRem > 0 and st.TutorialCompleted == true and not st.AllUpgradesCompleted then
				graceBanner.Visible = true
				local mins = math.floor(graceRem / 60)
				local secs = graceRem % 60
				local fmtKey = st.ShadowGraceIsInitial and "TRUCE_INITIAL_FMT" or "TRUCE_DAWN_FMT"
				graceLabel.Text = Localization.T(lang, fmtKey, mins, secs)
			else
				graceBanner.Visible = false
			end

			homeBtn.Text = Localization.T(lang, "MY_ZONE_BTN")
			toggleLabel.Text = Localization.T(lang, "CHAR_BTN_TITLE")
			toggleSub.Text = Localization.T(lang, "CHAR_BTN_SUB")
			turretMenuBtn.Text = Localization.T(lang, "HUD_TURRETS")
			wispsMenuBtn.Text = Localization.T(lang, "HUD_WISPS")
			dailyRewardsBtn.Text = Localization.T(lang, "HUD_DAILY")
			tutorialBtn.Text = Localization.T(lang, "TUTORIAL_BTN")
			local pageTitleKey = ({
				Defense = "TURRET_MODAL_TITLE",
				Wisps = "WISPS_MODAL_TITLE",
				Daily = "DAILY_MODAL_TITLE",
			})[activeTab] or "MODAL_TITLE"
			headerTitle.Text = Localization.T(lang, pageTitleKey)
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
			local albaCount = st.AlbaCount or 0
			local discountLvl = EconomyEngine.GetLevel(st.AlbaPerks, "ap_discount")
			local dataProxy = { Upgrades = st.Upgrades or {}, Altars = st.Altars or {} }
			for _, u in ipairs(GameConfig.Upgrades) do
				local lvl = EconomyEngine.GetUpgradeLevel(dataProxy, u.Id)
				if lvl < (u.MaxLevel or 1) and EconomyEngine.IsUpgradeUnlocked(dataProxy, u) then
					local cost = GameConfig.GetUpgradeCost(u, lvl, albaCount, discountLvl)
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
