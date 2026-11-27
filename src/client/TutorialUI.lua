local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Localization = require(ReplicatedStorage:WaitForChild("Localization"))

local TutorialUI = {}

local SLIDES = {
	{
		Icon = "🔥",
		Illustration = "👆   🔥   ✨",
		Accent = Color3.fromRGB(255, 195, 65),
		TitleKey = "TUT_1_TITLE",
		BodyKey = "TUT_1_BODY",
		TipKey = "TUT_1_TIP",
	},
	{
		Icon = "🟠",
		Illustration = "🌱   🌳   ⬆️",
		Accent = Color3.fromRGB(255, 145, 55),
		TitleKey = "TUT_2_TITLE",
		BodyKey = "TUT_2_BODY",
		TipKey = "TUT_2_TIP",
	},
	{
		Icon = "🛡️",
		Illustration = "🛡️   🗼   👾",
		Accent = Color3.fromRGB(80, 225, 255),
		TitleKey = "TUT_3_TITLE",
		BodyKey = "TUT_3_BODY",
		TipKey = "TUT_3_TIP",
	},
	{
		Icon = "✨",
		Illustration = "✨   🌀   🌟",
		Accent = Color3.fromRGB(195, 110, 255),
		TitleKey = "TUT_4_TITLE",
		BodyKey = "TUT_4_BODY",
		TipKey = "TUT_4_TIP",
	},
	{
		Icon = "🌅",
		Illustration = "🌅   🔄   🏝️",
		Accent = Color3.fromRGB(255, 220, 90),
		TitleKey = "TUT_5_TITLE",
		BodyKey = "TUT_5_BODY",
		TipKey = "TUT_5_TIP",
	},
}

local function createCloseButton(parent, zIndex)
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

function TutorialUI.Build(parentGui, remotes)
	local currentLang = "en"
	local currentIndex = 1
	local isOpen = false
	local hasAutoOpened = false
	local tutorialCompleted = false

	local overlay = Instance.new("Frame", parentGui)
	overlay.Name = "TutorialSlideOverlay"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	overlay.BackgroundTransparency = 0.42
	overlay.Visible = false
	overlay.ZIndex = 50

	local modal = Instance.new("Frame", overlay)
	modal.Name = "TutorialModal"
	modal.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.Position = UDim2.fromScale(0.5, 0.5)
	modal.Size = UDim2.new(0.92, 0, 0.88, 0)
	modal.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
	modal.ZIndex = 51
	Instance.new("UICorner", modal).CornerRadius = UDim.new(0, 18)

	local modalConstraint = Instance.new("UISizeConstraint", modal)
	modalConstraint.MaxSize = Vector2.new(760, 600)
	modalConstraint.MinSize = Vector2.new(320, 340)

	local modalStroke = Instance.new("UIStroke", modal)
	modalStroke.Color = Color3.fromRGB(255, 200, 65)
	modalStroke.Thickness = 2.0

	local header = Instance.new("Frame", modal)
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 52

	local headerTitle = Instance.new("TextLabel", header)
	headerTitle.Position = UDim2.fromOffset(18, 12)
	headerTitle.Size = UDim2.new(1, -190, 0, 30)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = Localization.T("en", "TUTORIAL_HEADER")
	headerTitle.TextColor3 = Color3.fromRGB(255, 215, 85)
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
	headerTitle.Font = Enum.Font.GothamBlack
	headerTitle.TextSize = 19
	headerTitle.ZIndex = 52

	local stepBadge = Instance.new("TextLabel", header)
	stepBadge.AnchorPoint = Vector2.new(1, 0.5)
	stepBadge.Position = UDim2.new(1, -56, 0.5, 0)
	stepBadge.Size = UDim2.fromOffset(122, 32)
	stepBadge.BackgroundColor3 = Color3.fromRGB(28, 33, 48)
	stepBadge.Text = "Slide 1 / 5"
	stepBadge.TextColor3 = Color3.fromRGB(220, 232, 250)
	stepBadge.Font = Enum.Font.GothamBold
	stepBadge.TextSize = 15
	stepBadge.ZIndex = 52
	Instance.new("UICorner", stepBadge).CornerRadius = UDim.new(0, 8)

	local closeBtn = createCloseButton(header, 53)

	local contentCard = Instance.new("Frame", modal)
	contentCard.Position = UDim2.fromOffset(14, 56)
	contentCard.Size = UDim2.new(1, -28, 1, -148)
	contentCard.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
	contentCard.ZIndex = 52
	Instance.new("UICorner", contentCard).CornerRadius = UDim.new(0, 14)

	local cardStroke = Instance.new("UIStroke", contentCard)
	cardStroke.Color = Color3.fromRGB(255, 195, 65)
	cardStroke.Thickness = 1.4

	local illustrationPanel = Instance.new("Frame", contentCard)
	illustrationPanel.Position = UDim2.fromOffset(12, 12)
	illustrationPanel.Size = UDim2.new(1, -24, 0, 88)
	illustrationPanel.BackgroundColor3 = Color3.fromRGB(36, 32, 24)
	illustrationPanel.ZIndex = 53
	Instance.new("UICorner", illustrationPanel).CornerRadius = UDim.new(0, 14)

	local illustration = Instance.new("TextLabel", illustrationPanel)
	illustration.Size = UDim2.new(1, -12, 1, 0)
	illustration.Position = UDim2.fromOffset(6, 0)
	illustration.BackgroundTransparency = 1
	illustration.Text = ""
	illustration.TextSize = 36
	illustration.TextScaled = true
	illustration.Font = Enum.Font.GothamBlack
	illustration.ZIndex = 54

	local slideTitle = Instance.new("TextLabel", contentCard)
	slideTitle.Position = UDim2.fromOffset(16, 108)
	slideTitle.Size = UDim2.new(1, -32, 0, 48)
	slideTitle.BackgroundTransparency = 1
	slideTitle.Text = ""
	slideTitle.TextColor3 = Color3.fromRGB(255, 225, 105)
	slideTitle.TextXAlignment = Enum.TextXAlignment.Left
	slideTitle.TextWrapped = true
	slideTitle.Font = Enum.Font.GothamBlack
	slideTitle.TextSize = 22
	slideTitle.ZIndex = 53

	local bodyScroll = Instance.new("ScrollingFrame", contentCard)
	bodyScroll.Position = UDim2.fromOffset(16, 160)
	bodyScroll.Size = UDim2.new(1, -32, 1, -242)
	bodyScroll.BackgroundTransparency = 1
	bodyScroll.BorderSizePixel = 0
	bodyScroll.ScrollBarThickness = 8
	bodyScroll.ScrollBarImageColor3 = Color3.fromRGB(140, 155, 190)
	bodyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	bodyScroll.CanvasSize = UDim2.new()
	bodyScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	bodyScroll.ZIndex = 53

	local slideBody = Instance.new("TextLabel", bodyScroll)
	slideBody.Size = UDim2.new(1, -12, 0, 0)
	slideBody.AutomaticSize = Enum.AutomaticSize.Y
	slideBody.BackgroundTransparency = 1
	slideBody.Text = ""
	slideBody.TextColor3 = Color3.fromRGB(245, 248, 255)
	slideBody.TextXAlignment = Enum.TextXAlignment.Left
	slideBody.TextYAlignment = Enum.TextYAlignment.Top
	slideBody.TextWrapped = true
	slideBody.Font = Enum.Font.Gotham
	slideBody.TextSize = 19
	slideBody.LineHeight = 1.18
	slideBody.ZIndex = 54

	local tipBox = Instance.new("Frame", contentCard)
	tipBox.AnchorPoint = Vector2.new(0.5, 1)
	tipBox.Position = UDim2.new(0.5, 0, 1, -12)
	tipBox.Size = UDim2.new(1, -28, 0, 54)
	tipBox.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	tipBox.ZIndex = 53
	Instance.new("UICorner", tipBox).CornerRadius = UDim.new(0, 8)

	local tipLabel = Instance.new("TextLabel", tipBox)
	tipLabel.Position = UDim2.fromOffset(12, 2)
	tipLabel.Size = UDim2.new(1, -24, 1, -4)
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = ""
	tipLabel.TextColor3 = Color3.fromRGB(130, 235, 255)
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextWrapped = true
	tipLabel.Font = Enum.Font.GothamBold
	tipLabel.TextSize = 16
	tipLabel.ZIndex = 54

	local dotsHolder = Instance.new("Frame", modal)
	dotsHolder.AnchorPoint = Vector2.new(0.5, 1)
	dotsHolder.Position = UDim2.new(0.5, 0, 1, -66)
	dotsHolder.Size = UDim2.fromOffset(#SLIDES * 26, 18)
	dotsHolder.BackgroundTransparency = 1
	dotsHolder.ZIndex = 52

	local dots = {}
	for i = 1, #SLIDES do
		local dot = Instance.new("TextButton", dotsHolder)
		dot.Position = UDim2.fromOffset((i - 1) * 26 + 5, 2)
		dot.Size = UDim2.fromOffset(14, 14)
		dot.BackgroundColor3 = Color3.fromRGB(60, 68, 92)
		dot.Text = ""
		dot.ZIndex = 53
		Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
		dots[i] = dot
	end

	local prevBtn = Instance.new("TextButton", modal)
	prevBtn.AnchorPoint = Vector2.new(0, 1)
	prevBtn.Position = UDim2.new(0, 18, 1, -14)
	prevBtn.Size = UDim2.fromOffset(150, 48)
	prevBtn.BackgroundColor3 = Color3.fromRGB(34, 40, 58)
	prevBtn.Text = Localization.T("en", "TUTORIAL_PREV")
	prevBtn.TextColor3 = Color3.fromRGB(235, 242, 255)
	prevBtn.Font = Enum.Font.GothamBold
	prevBtn.TextSize = 17
	prevBtn.ZIndex = 52
	Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 10)

	local nextBtn = Instance.new("TextButton", modal)
	nextBtn.AnchorPoint = Vector2.new(1, 1)
	nextBtn.Position = UDim2.new(1, -18, 1, -14)
	nextBtn.Size = UDim2.fromOffset(205, 48)
	nextBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 65)
	nextBtn.Text = Localization.T("en", "TUTORIAL_NEXT")
	nextBtn.TextColor3 = Color3.fromRGB(16, 18, 24)
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 17
	nextBtn.ZIndex = 52
	Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

	local function updateResponsiveLayout()
		local compact = modal.AbsoluteSize.Y < 430
		local cardBottom = compact and 120 or 148
		local illustrationHeight = compact and 66 or 88

		contentCard.Size = UDim2.new(1, -28, 1, -cardBottom)
		illustrationPanel.Size = UDim2.new(1, -24, 0, illustrationHeight)
		slideTitle.Position = UDim2.fromOffset(16, compact and 84 or 108)
		slideTitle.Size = UDim2.new(1, -32, 0, compact and 42 or 48)
		slideTitle.TextSize = compact and 19 or 22
		bodyScroll.Position = UDim2.fromOffset(16, compact and 132 or 160)
		bodyScroll.Size = UDim2.new(1, -32, 1, compact and -142 or -242)
		slideBody.TextSize = compact and 17 or 19
		tipBox.Visible = not compact
		tipBox.Size = UDim2.new(1, -28, 0, compact and 46 or 54)
		tipLabel.TextSize = compact and 14 or 16
		headerTitle.TextSize = compact and 16 or 19
		stepBadge.Size = UDim2.fromOffset(compact and 102 or 122, 32)
		local navWidth = math.clamp((modal.AbsoluteSize.X - 56) / 2, 112, 205)
		prevBtn.Size = UDim2.fromOffset(navWidth, 48)
		nextBtn.Size = UDim2.fromOffset(navWidth, 48)
	end

	modal:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveLayout)
	updateResponsiveLayout()

	local function renderSlide()
		local slide = SLIDES[currentIndex] or SLIDES[1]
		headerTitle.Text = Localization.T(currentLang, "TUTORIAL_HEADER")
		stepBadge.Text = Localization.T(currentLang, "TUTORIAL_STEP_FMT", currentIndex, #SLIDES)

		illustrationPanel.BackgroundColor3 = slide.Accent:Lerp(Color3.fromRGB(16, 18, 28), 0.78)
		illustration.Text = slide.Illustration or slide.Icon
		slideTitle.Text = Localization.T(currentLang, slide.TitleKey)
		slideTitle.TextColor3 = slide.Accent
		slideBody.Text = Localization.T(currentLang, slide.BodyKey)
		tipLabel.Text = Localization.T(currentLang, slide.TipKey)
		cardStroke.Color = slide.Accent
		modalStroke.Color = slide.Accent

		for i, dot in ipairs(dots) do
			if i == currentIndex then
				dot.BackgroundColor3 = slide.Accent
				dot.Size = UDim2.fromOffset(16, 16)
				dot.Position = UDim2.fromOffset((i - 1) * 26 + 4, 1)
			else
				dot.BackgroundColor3 = Color3.fromRGB(60, 68, 92)
				dot.Size = UDim2.fromOffset(14, 14)
				dot.Position = UDim2.fromOffset((i - 1) * 26 + 5, 2)
			end
		end

		prevBtn.Visible = currentIndex > 1
		prevBtn.Text = Localization.T(currentLang, "TUTORIAL_PREV")

		if currentIndex < #SLIDES then
			nextBtn.Text = Localization.T(currentLang, "TUTORIAL_NEXT")
			nextBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 65)
		else
			local doneKey = tutorialCompleted and "TUTORIAL_CLOSE_DONE" or "TUTORIAL_START"
			nextBtn.Text = Localization.T(currentLang, doneKey)
			nextBtn.BackgroundColor3 = Color3.fromRGB(70, 240, 145)
		end
	end

	local function openTutorial(slideIdx)
		currentIndex = math.clamp(slideIdx or 1, 1, #SLIDES)
		isOpen = true
		overlay.Visible = true
		renderSlide()
	end

	local function closeTutorial()
		if not isOpen then return end
		isOpen = false
		overlay.Visible = false
		tutorialCompleted = true
		if remotes and remotes.CompleteTutorial then
			remotes.CompleteTutorial:FireServer()
		end
	end

	for i, dot in ipairs(dots) do
		dot.MouseButton1Click:Connect(function()
			currentIndex = i
			renderSlide()
		end)
	end

	prevBtn.MouseButton1Click:Connect(function()
		if currentIndex > 1 then
			currentIndex -= 1
			renderSlide()
		end
	end)

	nextBtn.MouseButton1Click:Connect(function()
		if currentIndex < #SLIDES then
			currentIndex += 1
			renderSlide()
		else
			closeTutorial()
		end
	end)

	closeBtn.MouseButton1Click:Connect(function()
		closeTutorial()
	end)

	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp or not isOpen then return end
		if inp.KeyCode == Enum.KeyCode.Right or inp.KeyCode == Enum.KeyCode.D then
			if currentIndex < #SLIDES then
				currentIndex += 1
				renderSlide()
			end
		elseif inp.KeyCode == Enum.KeyCode.Left or inp.KeyCode == Enum.KeyCode.A then
			if currentIndex > 1 then
				currentIndex -= 1
				renderSlide()
			end
		elseif inp.KeyCode == Enum.KeyCode.Escape then
			closeTutorial()
		elseif inp.KeyCode == Enum.KeyCode.Return or inp.KeyCode == Enum.KeyCode.Space then
			if currentIndex < #SLIDES then
				currentIndex += 1
				renderSlide()
			else
				closeTutorial()
			end
		end
	end)

	return {
		Open = function()
			openTutorial(1)
		end,
		Close = closeTutorial,
		Update = function(st)
			if not st then return end
			if st.Language == "en" or st.Language == "it" then
				currentLang = st.Language
			end
			tutorialCompleted = (st.TutorialCompleted == true)
			if st.DataLoaded == true and not tutorialCompleted and not hasAutoOpened then
				hasAutoOpened = true
				openTutorial(1)
				return
			end
			if isOpen then
				renderSlide()
			end
		end,
	}
end

return TutorialUI
