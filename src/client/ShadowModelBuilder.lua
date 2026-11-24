local RunService = game:GetService("RunService")

local ShadowModelBuilder = {}
local activeVisuals = {}

local VISUAL_STYLES = {
	wisp = {
		Scale = 1.0,
		Primary = Color3.fromRGB(24, 12, 44),
		Accent = Color3.fromRGB(165, 65, 255),
	},
	stalker = {
		Scale = 1.15,
		Primary = Color3.fromRGB(40, 10, 32),
		Accent = Color3.fromRGB(235, 55, 140),
	},
	brute = {
		Scale = 1.75,
		Primary = Color3.fromRGB(16, 8, 24),
		Accent = Color3.fromRGB(255, 110, 40),
	},
	siphon = {
		Scale = 1.25,
		Primary = Color3.fromRGB(12, 24, 40),
		Accent = Color3.fromRGB(0, 215, 255),
	},
}

local function makeVisPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function attachShadowModel(hitbox)
	if activeVisuals[hitbox] or not hitbox:IsA("BasePart") or hitbox.Name ~= "InvadingShadow" then
		return
	end

	local typeId = hitbox:GetAttribute("ShadowTypeId") or "wisp"
	local style = VISUAL_STYLES[typeId] or VISUAL_STYLES.wisp
	local s = style.Scale

	local model = Instance.new("Model")
	model.Name = "ShadowVisual_" .. typeId

	local core = makeVisPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.5, 2.1, 1.5) * s,
		Material = Enum.Material.Neon,
		Color = style.Accent,
		Parent = model,
	})

	local shell = makeVisPart({
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.3, 3.1, 2.3) * s,
		Material = Enum.Material.ForceField,
		Color = style.Primary,
		Transparency = 0.15,
		Parent = model,
	})

	local leftEye = makeVisPart({
		Size = Vector3.new(0.28, 0.15, 0.15) * s,
		Material = Enum.Material.Neon,
		Color = Color3.new(1, 1, 1),
		Parent = model,
	})
	local rightEye = leftEye:Clone()
	rightEye.Parent = model

	local hl = Instance.new("Highlight")
	hl.FillColor = style.Primary
	hl.OutlineColor = style.Accent
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0.2
	hl.Parent = model

	local light = Instance.new("PointLight")
	light.Color = style.Accent
	light.Range = 10 * s
	light.Brightness = 1.4
	light.Parent = core

	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(style.Primary, style.Accent)
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55 * s), NumberSequenceKeypoint.new(1, 0) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(0.5, 1.0)
	smoke.Rate = 12
	smoke.Speed = NumberRange.new(1.5, 3.0)
	smoke.Parent = core

	local orbiters = {}
	if typeId == "wisp" then
		for i = 1, 3 do
			local shard = makeVisPart({
				Size = Vector3.new(0.32, 0.85, 0.32) * s,
				Material = Enum.Material.Neon,
				Color = style.Accent,
				Parent = model,
			})
			table.insert(orbiters, { Part = shard, Angle = (math.pi * 2 / 3) * i, Radius = 1.85 * s })
		end
	elseif typeId == "stalker" then
		shell.Size = Vector3.new(1.7, 2.7, 3.1) * s
		local a0 = Instance.new("Attachment", shell)
		a0.Position = Vector3.new(0, 1.0 * s, 0)
		local a1 = Instance.new("Attachment", shell)
		a1.Position = Vector3.new(0, -1.0 * s, 0)
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(style.Accent, style.Primary)
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.Lifetime = 0.45
		trail.Parent = shell
	elseif typeId == "brute" then
		for _, side in ipairs({ -1, 1 }) do
			local shoulder = makeVisPart({
				Size = Vector3.new(1.1, 1.5, 1.4) * s,
				Material = Enum.Material.SmoothPlastic,
				Color = style.Primary,
				Parent = model,
			})
			table.insert(orbiters, { Part = shoulder, Offset = Vector3.new(side * 1.65 * s, 0.65 * s, 0), Tilt = math.rad(side * -18) })
		end
	elseif typeId == "siphon" then
		local ring = makeVisPart({
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.15, 2.5, 2.5) * s,
			Material = Enum.Material.Neon,
			Color = style.Accent,
			Parent = model,
		})
		table.insert(orbiters, { Part = ring, Offset = Vector3.new(0, 2.0 * s, 0), SpinHalo = true })
	end

	model.Parent = workspace

	local lastHP = hitbox:GetAttribute("HP") or 1
	hitbox:GetAttributeChangedSignal("HP"):Connect(function()
		local hp = hitbox:GetAttribute("HP") or 0
		if hp < lastHP and hl.Parent then
			hl.FillColor = Color3.new(1, 1, 1)
			hl.FillTransparency = 0.1
			task.delay(0.08, function()
				if hl and hl.Parent then
					hl.FillColor = hitbox:GetAttribute("IsSlowed") and Color3.fromRGB(90, 210, 255) or style.Primary
					hl.FillTransparency = 0.4
				end
			end)
		end
		lastHP = hp
	end)

	hitbox:GetAttributeChangedSignal("IsSlowed"):Connect(function()
		if hl and hl.Parent then
			hl.OutlineColor = hitbox:GetAttribute("IsSlowed") and Color3.fromRGB(110, 240, 255) or style.Accent
		end
	end)

	activeVisuals[hitbox] = {
		Model = model,
		Core = core,
		Shell = shell,
		LeftEye = leftEye,
		RightEye = rightEye,
		Orbiters = orbiters,
		Scale = s,
		TypeId = typeId,
		Seed = math.random() * 10,
	}
end

function ShadowModelBuilder.Start()
	for _, desc in ipairs(workspace:GetDescendants()) do
		attachShadowModel(desc)
	end

	workspace.DescendantAdded:Connect(attachShadowModel)
	workspace.DescendantRemoving:Connect(function(desc)
		local vis = activeVisuals[desc]
		if vis then
			vis.Model:Destroy()
			activeVisuals[desc] = nil
		end
	end)

	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		for hitbox, v in pairs(activeVisuals) do
			if not hitbox.Parent then
				v.Model:Destroy()
				activeVisuals[hitbox] = nil
				continue
			end

			local s = v.Scale
			local bob = math.sin(t * 3.5 + v.Seed) * 0.35 * s
			local cf = hitbox.CFrame * CFrame.new(0, bob, 0)
			if v.TypeId == "stalker" then
				cf = cf * CFrame.Angles(math.rad(-20), 0, 0)
			end

			v.Core.CFrame = cf * CFrame.Angles(0, t * 2, 0)
			v.Shell.CFrame = cf
			v.LeftEye.CFrame = cf * CFrame.new(-0.36 * s, 0.35 * s, -1.02 * s)
			v.RightEye.CFrame = cf * CFrame.new(0.36 * s, 0.35 * s, -1.02 * s)

			for _, orb in ipairs(v.Orbiters) do
				if orb.Angle then
					local a = t * 2.8 + orb.Angle
					orb.Part.CFrame = cf * CFrame.new(math.cos(a) * orb.Radius, math.sin(a * 2) * 0.25, math.sin(a) * orb.Radius) * CFrame.Angles(a, a, 0)
				elseif orb.SpinHalo then
					orb.Part.CFrame = cf * CFrame.new(orb.Offset) * CFrame.Angles(0, t * 3, math.rad(90))
				elseif orb.Offset then
					orb.Part.CFrame = cf * CFrame.new(orb.Offset) * CFrame.Angles(0, 0, orb.Tilt or 0)
				end
			end
		end
	end)
end

return ShadowModelBuilder