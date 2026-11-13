local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Regno1Visuals = {}

local PITCH_SCALE = { 1.0, 1.15, 1.30, 1.48, 1.72 }

function Regno1Visuals.Init(world, playerGui)
	local localPlayer = Players.LocalPlayer
	local zonesFolder = world:WaitForChild("WorldZones")
	local braziersFolder = zonesFolder:WaitForChild("Braziers")
	local ritualFolder = braziersFolder:WaitForChild("RitualBraziers")

	local state = {
		Unlocked = false,
		Completed = false,
		Active = false,
		Step = 0,
		Muted = false,
	}

	-- Audio dedicato con scala musicale ascendente per i 5 bracieri
	local chimeSfx = Instance.new("Sound")
	chimeSfx.Name = "Regno1Chime"
	chimeSfx.SoundId = "rbxassetid://6895079853"
	chimeSfx.Volume = 0.55
	chimeSfx.Parent = playerGui

	-- Fascio guida 3D dal giocatore verso il prossimo braciere
	local guideFolder = Instance.new("Folder", workspace)
	guideFolder.Name = "Regno1GuideVisuals"

	local playerAttachPart = Instance.new("Part", guideFolder)
	playerAttachPart.Name = "PlayerGuideAnchor"
	playerAttachPart.Size = Vector3.new(0.2, 0.2, 0.2)
	playerAttachPart.Transparency = 1
	playerAttachPart.Anchored = true
	playerAttachPart.CanCollide = false
	local att0 = Instance.new("Attachment", playerAttachPart)

	local targetAttachPart = Instance.new("Part", guideFolder)
	targetAttachPart.Name = "TargetGuideAnchor"
	targetAttachPart.Size = Vector3.new(0.2, 0.2, 0.2)
	targetAttachPart.Transparency = 1
	targetAttachPart.Anchored = true
	targetAttachPart.CanCollide = false
	local att1 = Instance.new("Attachment", targetAttachPart)

	local guideBeam = Instance.new("Beam", guideFolder)
	guideBeam.Attachment0 = att0
	guideBeam.Attachment1 = att1
	guideBeam.Enabled = false
	guideBeam.Width0 = 0.45
	guideBeam.Width1 = 1.15
	guideBeam.FaceCamera = true
	guideBeam.LightEmission = 1
	guideBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	guideBeam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 75), Color3.fromRGB(255, 115, 35))

	-- Sfera "Scintilla Viva" trasportata dal giocatore durante il rituale
	local sparkOrb = Instance.new("Part", guideFolder)
	sparkOrb.Name = "LivingSparkOrb"
	sparkOrb.Shape = Enum.PartType.Ball
	sparkOrb.Size = Vector3.new(1.1, 1.1, 1.1)
	sparkOrb.Material = Enum.Material.Neon
	sparkOrb.Color = Color3.fromRGB(255, 225, 95)
	sparkOrb.Anchored = true
	sparkOrb.CanCollide = false
	sparkOrb.Transparency = 1

	local sparkLight = Instance.new("PointLight", sparkOrb)
	sparkLight.Color = Color3.fromRGB(255, 195, 70)
	sparkLight.Range = 18
	sparkLight.Brightness = 0

	local function playBrazierBurst(index)
		local bModel = ritualFolder:FindFirstChild("RitualBrazier_" .. index)
		local core = bModel and bModel:FindFirstChild("FlameOrb")
		if not core then return end

		if not state.Muted then
			chimeSfx.PlaybackSpeed = PITCH_SCALE[index] or 1.0
			chimeSfx:Play()
		end

		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = index == 5 and Color3.fromRGB(255, 245, 140) or Color3.fromRGB(255, 175, 55)
		ring.Transparency = 0.25
		ring.Size = Vector3.new(0.25, 3, 3)
		ring.CFrame = CFrame.new(core.Position - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace

		local tw = TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.25, index == 5 and 34 or 20, index == 5 and 34 or 20),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() ring:Destroy() end)
	end

	local function refreshBraziersAppearance()
		local nextTargetIdx = nil
		if state.Active then
			nextTargetIdx = state.Step + 1
		elseif state.Unlocked then
			nextTargetIdx = 1
		end

		for i = 1, #GameConfig.Regno1.Braziers do
			local bModel = ritualFolder:FindFirstChild("RitualBrazier_" .. i)
			if bModel then
				local core = bModel:FindFirstChild("FlameOrb")
				local runePad = bModel:FindFirstChild("RunePad")
				local light = core and core:FindFirstChild("BrazierLight")
				local gui = core and core:FindFirstChild("BrazierGui")
				local subLbl = gui and gui.Frame:FindFirstChild("Sub")
				local stroke = gui and gui.Frame:FindFirstChild("Stroke")

				local isLitInRun = state.Active and (i <= state.Step)
				local isNext = (i == nextTargetIdx)
				local isMasteredIdle = (not state.Active) and state.Completed

				if core then
					if isLitInRun then
						core.Material = Enum.Material.Neon
						core.Color = Color3.fromRGB(255, 195, 65)
						if light then light.Enabled = true; light.Brightness = 3.2 end
					elseif isNext then
						core.Material = Enum.Material.Neon
						core.Color = Color3.fromRGB(255, 245, 140)
						if light then light.Enabled = true; light.Brightness = 2.6 end
					elseif isMasteredIdle then
						core.Material = Enum.Material.Neon
						core.Color = Color3.fromRGB(255, 180, 65)
						if light then light.Enabled = true; light.Brightness = 2.0 end
					elseif state.Unlocked then
						core.Material = Enum.Material.SmoothPlastic
						core.Color = Color3.fromRGB(65, 52, 42)
						if light then light.Enabled = false end
					else
						core.Material = Enum.Material.SmoothPlastic
						core.Color = Color3.fromRGB(28, 28, 34)
						if light then light.Enabled = false end
					end
				end

				if runePad then
					if isNext then
						runePad.Color = Color3.fromRGB(255, 225, 85)
						runePad.Transparency = 0.12
					elseif isLitInRun or isMasteredIdle then
						runePad.Color = Color3.fromRGB(255, 155, 45)
						runePad.Transparency = 0.25
					else
						runePad.Color = Color3.fromRGB(45, 42, 52)
						runePad.Transparency = 0.55
					end
				end

				if subLbl and stroke then
					if not state.Unlocked then
						subLbl.Text = "🔒 Sblocca Regno 1"
						stroke.Color = Color3.fromRGB(90, 90, 110)
					elseif isLitInRun then
						subLbl.Text = "✓ ACCESO"
						stroke.Color = Color3.fromRGB(80, 235, 145)
					elseif isNext then
						subLbl.Text = state.Active and "⚡ CORRI QUI!" or "🔥 INIZIA CATENA"
						stroke.Color = Color3.fromRGB(255, 235, 100)
					else
						subLbl.Text = "Tappa " .. i .. " / 5"
						stroke.Color = Color3.fromRGB(255, 175, 60)
					end
				end
			end
		end
	end

	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		local targetIdx = state.Active and (state.Step + 1) or (state.Unlocked and 1 or nil)
		local targetModel = targetIdx and ritualFolder:FindFirstChild("RitualBrazier_" .. targetIdx)
		local targetCore = targetModel and targetModel:FindFirstChild("FlameOrb")

		if hrp and targetCore and (state.Active or (state.Unlocked and not state.Completed)) then
			playerAttachPart.Position = hrp.Position + Vector3.new(0, 1.2, 0)
			targetAttachPart.Position = targetCore.Position
			guideBeam.Enabled = true
		else
			guideBeam.Enabled = false
		end

		if hrp and state.Active then
			sparkOrb.Transparency = 0
			sparkLight.Brightness = 2.6 + math.sin(t * 10) * 0.6
			sparkOrb.Size = Vector3.new(1, 1, 1) * (0.9 + state.Step * 0.14 + math.sin(t * 12) * 0.08)
			sparkOrb.Position = hrp.Position + Vector3.new(math.cos(t * 5) * 1.8, 3.2 + math.sin(t * 6) * 0.35, math.sin(t * 5) * 1.8)
		else
			sparkOrb.Transparency = 1
			sparkLight.Brightness = 0
		end

		-- Pulsazione del prossimo braciere bersaglio
		if targetCore then
			local pulse = 1 + math.sin(t * 6) * 0.12
			targetCore.Size = Vector3.new(2.6, 3.0, 2.6) * pulse
		end
	end)

	local controller = {}

	function controller.SetMuted(isMuted)
		state.Muted = isMuted
	end

	function controller.OnRegno1Event(payload)
		state.Unlocked = payload.Unlocked == true
		state.Completed = payload.Completed == true
		state.Active = payload.Active == true
		state.Step = payload.Step or 0

		refreshBraziersAppearance()

		if payload.LitIndex and (payload.Type == "Start" or payload.Type == "Ignite" or payload.Type == "Complete") then
			playBrazierBurst(payload.LitIndex)
		end
	end

	refreshBraziersAppearance()
	return controller
end

return Regno1Visuals
