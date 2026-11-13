local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage:WaitForChild("NumberFormat"))

local PopupManager = {}
PopupManager.__index = PopupManager

function PopupManager.new(parentGui)
	local self = setmetatable({}, PopupManager)
	self.Container = Instance.new("Frame")
	self.Container.Name = "PopupLayer"
	self.Container.Size = UDim2.fromScale(1, 1)
	self.Container.BackgroundTransparency = 1
	self.Container.ZIndex = 20
	self.Container.Parent = parentGui
	self.ClickCycle = 0
	return self
end

-- Pop-up dei punti accumulati ad ogni click sulla Fiamma!
function PopupManager:ShowClickPoints(amount, isCrit)
	self.ClickCycle = (self.ClickCycle + 1) % 7
	local angleOffset = (self.ClickCycle - 3) * 32

	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint = Vector2.new(0.5, 0.5)
	lbl.Position = UDim2.new(0.42, angleOffset + math.random(-12, 12), 0.56, math.random(-14, 14))
	lbl.Size = isCrit and UDim2.fromOffset(310, 48) or UDim2.fromOffset(230, 38)
	lbl.BackgroundTransparency = 1
	lbl.ZIndex = 22
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true

	if isCrit then
		lbl.Text = "💥 CRITICO! +" .. NumberFormat.Format(amount) .. " Punti!"
		lbl.TextColor3 = Color3.fromRGB(255, 250, 120)
		lbl.Rotation = math.random(-6, 6)
	else
		lbl.Text = "+" .. NumberFormat.Format(amount) .. " Punti"
		lbl.TextColor3 = Color3.fromRGB(255, 200, 70)
	end

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = isCrit and 2.5 or 1.8
	stroke.Color = Color3.fromRGB(20, 14, 10)
	stroke.Parent = lbl

	local scale = Instance.new("UIScale")
	scale.Scale = 0.55
	scale.Parent = lbl

	lbl.Parent = self.Container

	-- Rimbalzo iniziale + salita verso l'alto
	TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = isCrit and 1.18 or 1.0,
	}):Play()

	local moveTween = TweenService:Create(lbl, TweenInfo.new(0.95, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = lbl.Position - UDim2.fromOffset(angleOffset * 0.35, isCrit and 125 or 95),
		TextTransparency = 1,
	})
	TweenService:Create(stroke, TweenInfo.new(0.95), { Transparency = 1 }):Play()

	moveTween:Play()
	moveTween.Completed:Connect(function()
		lbl:Destroy()
	end)
end

-- Pop-up per eventi (Nuovi bottoni sbloccati, Regni risvegliati, Spiriti, Codici)
function PopupManager:ShowEvent(text, accentColor)
	if not text or text == "" then return end

	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.new(0.42, 0, 0.22, 0)
	banner.Size = UDim2.fromOffset(420, 42)
	banner.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	banner.BackgroundTransparency = 0.12
	banner.ZIndex = 25
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", banner)
	stroke.Color = accentColor or Color3.fromRGB(255, 195, 75)
	stroke.Thickness = 2

	local lbl = Instance.new("TextLabel", banner)
	lbl.Size = UDim2.new(1, -20, 1, -6)
	lbl.Position = UDim2.fromOffset(10, 3)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = accentColor or Color3.fromRGB(255, 225, 115)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.ZIndex = 26

	local scale = Instance.new("UIScale", banner)
	scale.Scale = 0.7

	banner.Parent = self.Container

	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0,
	}):Play()

	task.delay(1.35, function()
		local out = TweenService:Create(banner, TweenInfo.new(0.45), {
			Position = banner.Position - UDim2.fromOffset(0, 32),
			BackgroundTransparency = 1,
		})
		TweenService:Create(lbl, TweenInfo.new(0.45), { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.45), { Transparency = 1 }):Play()
		out:Play()
		out.Completed:Connect(function()
			banner:Destroy()
		end)
	end)
end

return PopupManager
