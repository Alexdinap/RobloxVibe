local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local WorldVisuals = {}

function WorldVisuals.Init(world)
	local flameModel = world:WaitForChild("PrimordialFlame")
	local flameCore = flameModel:WaitForChild("FlameCore")
	local mainLight = flameCore:WaitForChild("MainFlameLight")
	local zonesFolder = world:WaitForChild("WorldZones")

	for _, fx in ipairs(Lighting:GetChildren()) do
		if fx:IsA("Atmosphere") or fx:IsA("BloomEffect") then fx:Destroy() end
	end
	local atmo = Instance.new("Atmosphere", Lighting)
	local bloom = Instance.new("BloomEffect", Lighting)
	bloom.Intensity = 0.75
	bloom.Size = 24
	bloom.Threshold = 1.0

	local state = {
		LightPercent = 4,
		Heat = 0,
		FlamePulse = 0,
		LanternsLit = false,
	}

	local visualFolder = Instance.new("Folder", workspace)
	visualFolder.Name = "LightWispsVisuals"

	local wispColors = {}
	for _, w in ipairs(GameConfig.Wisps) do
		wispColors[w.Id] = w.Color
	end

	local controller = {}

	function controller.TriggerClickPulse(isCrit)
		state.FlamePulse = isCrit and 1.45 or 1.0

		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = isCrit and Color3.fromRGB(255, 250, 140) or Color3.fromRGB(255, 180, 65)
		ring.Transparency = 0.35
		ring.Size = Vector3.new(0.25, 4, 4)
		ring.CFrame = CFrame.new(0, 1.3, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace

		local maxD = isCrit and 52 or 28
		local tw = TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.25, maxD, maxD),
			Transparency = 1,
		})
		tw:Play()
		tw.Completed:Connect(function() ring:Destroy() end)

		for _ = 1, (isCrit and 7 or 3) do
			local sp = Instance.new("Part")
			sp.Shape = Enum.PartType.Ball
			sp.Size = Vector3.new(0.4, 0.4, 0.4)
			sp.Anchored = true
			sp.CanCollide = false
			sp.Material = Enum.Material.Neon
			sp.Color = isCrit and Color3.fromRGB(255, 255, 160) or Color3.fromRGB(255, 190, 60)
			sp.Position = flameCore.Position + Vector3.new(math.random(-14, 14) * 0.1, 0, math.random(-14, 14) * 0.1)
			sp.Parent = workspace

			local dest = sp.Position + Vector3.new(math.random(-4, 4), math.random(5, 8), math.random(-4, 4))
			local stw = TweenService:Create(sp, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = dest,
				Size = Vector3.new(0.05, 0.05, 0.05),
				Transparency = 1,
			})
			stw:Play()
			stw.Completed:Connect(function() sp:Destroy() end)
		end
	end

	function controller.ApplyIllumination(pct, heat, upgrades)
		state.LightPercent = pct
		state.Heat = heat
		local t = math.clamp(pct / 100, 0, 1)

		Lighting.Brightness = 0.15 + t * 2.4
		Lighting.ClockTime = (t * 10.5) % 24
		Lighting.Ambient = Color3.fromRGB(8, 10, 18):Lerp(Color3.fromRGB(130, 120, 110), t)
		Lighting.OutdoorAmbient = Color3.fromRGB(10, 12, 22):Lerp(Color3.fromRGB(170, 155, 135), t)

		atmo.Density = 0.78 - t * 0.58
		atmo.Color = Color3.fromRGB(10, 12, 20):Lerp(Color3.fromRGB(255, 215, 155), t)
		atmo.Decay = Color3.fromRGB(5, 6, 12):Lerp(Color3.fromRGB(185, 135, 85), t)
		atmo.Haze = 2.5 - t * 1.8

		mainLight.Range = math.min(60, 24 + t * 36 + heat * 8)
		mainLight.Brightness = 2.4 + t * 2.5 + heat * 1.2

		if upgrades["u_braziers"] and upgrades["u_braziers"] > 0 then
			for _, obj in ipairs(zonesFolder.Braziers:GetChildren()) do
				if string.sub(obj.Name, 1, 6) == "Torch_" then
					obj.Color = Color3.fromRGB(255, 165, 50)
					obj.Material = Enum.Material.Neon
					local l = obj:FindFirstChildOfClass("PointLight")
					if l then l.Enabled = true; l.Brightness = 2.2 end
				end
			end
		end

		if upgrades["u_crystals"] and upgrades["u_crystals"] > 0 then
			for _, c in ipairs(zonesFolder.Crystals:GetChildren()) do
				c.Color = Color3.fromRGB(55, 245, 205)
				c.Material = Enum.Material.Neon
				local l = c:FindFirstChildOfClass("PointLight")
				if l then l.Enabled = true; l.Brightness = 2.5 end
			end
		end

		if upgrades["u_lanterns"] and upgrades["u_lanterns"] > 0 then
			state.LanternsLit = true
			for _, obj in ipairs(zonesFolder.Lanterns:GetChildren()) do
				if string.sub(obj.Name, 1, 11) == "SkyLantern_" then
					obj.Color = Color3.fromRGB(255, 155, 65)
					obj.Material = Enum.Material.Neon
					local l = obj:FindFirstChildOfClass("PointLight")
					if l then l.Enabled = true; l.Brightness = 2.4 end
				end
			end
		end

		if upgrades["u_waterfall"] and upgrades["u_waterfall"] > 0 then
			local ws = zonesFolder.Waterfall.WaterStream
			local wp = zonesFolder.Waterfall.WaterPool
			ws.Color = Color3.fromRGB(95, 220, 255)
			ws.Material = Enum.Material.Neon
			wp.Color = Color3.fromRGB(95, 220, 255)
			wp.Material = Enum.Material.Neon
			local l = ws:FindFirstChildOfClass("PointLight")
			if l then l.Enabled = true; l.Brightness = 3.0 end
		end

		if upgrades["u_temple"] and upgrades["u_temple"] > 0 then
			local disc = zonesFolder.Temple.SunDisc
			disc.Color = Color3.fromRGB(255, 225, 95)
			disc.Material = Enum.Material.Neon
			local l = disc:FindFirstChildOfClass("PointLight")
			if l then l.Enabled = true; l.Brightness = 4.2 end
		end
	end

	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		state.FlamePulse = math.max(0, state.FlamePulse - dt * 4.0)
		local scale = (1 + (state.LightPercent / 100) * 1.3 + state.Heat * 0.35) * (1 + math.sin(t * 5) * 0.06 + state.FlamePulse * 0.28)
		flameCore.Size = Vector3.new(3.8, 4.8, 3.8) * scale

		if state.LanternsLit then
			for i, obj in ipairs(zonesFolder.Lanterns:GetChildren()) do
				if string.sub(obj.Name, 1, 11) == "SkyLantern_" then
					obj.Position += Vector3.new(0, math.sin(t * 1.6 + i) * 0.015, 0)
				end
			end
		end

		for _, plr in ipairs(Players:GetPlayers()) do
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local pFolder = visualFolder:FindFirstChild(plr.Name)

			if hrp then
				if not pFolder then
					pFolder = Instance.new("Folder", visualFolder)
					pFolder.Name = plr.Name
				end

				local rLvl = plr:GetAttribute("RadiusLevel") or 0
				local personalLight = hrp:FindFirstChild("PersonalLantern")
				if not personalLight then
					personalLight = Instance.new("PointLight", hrp)
					personalLight.Name = "PersonalLantern"
					personalLight.Color = Color3.fromRGB(255, 195, 110)
				end
				personalLight.Range = 20 + rLvl * 5
				personalLight.Brightness = 1.4 + rLvl * 0.25

				local ok, ids = pcall(function() return HttpService:JSONDecode(plr:GetAttribute("EquippedWisps") or "[]") end)
				ids = (ok and type(ids) == "table") and ids or {}

				for i = 1, 5 do
					local wPart = pFolder:FindFirstChild("Wisp_" .. i)
					if ids[i] then
						local isRad = string.sub(ids[i], -4) == "_rad"
						local baseId = isRad and string.sub(ids[i], 1, -5) or ids[i]
						if not wPart then
							wPart = Instance.new("Part", pFolder)
							wPart.Name = "Wisp_" .. i
							wPart.Shape = Enum.PartType.Ball
							wPart.Anchored = true
							wPart.CanCollide = false
							wPart.Material = Enum.Material.Neon
							Instance.new("PointLight", wPart)
						end
						wPart.Size = isRad and Vector3.new(1.35, 1.35, 1.35) or Vector3.new(0.95, 0.95, 0.95)
						local col = isRad and Color3.fromRGB(255, 230, 95) or (wispColors[baseId] or Color3.fromRGB(255, 200, 80))
						wPart.Color = col
						local wl = wPart:FindFirstChildOfClass("PointLight")
						wl.Color = col
						wl.Range = isRad and 24 or 16
						wl.Brightness = isRad and 2.5 or 1.8

						local a = t * 2.0 + (i * (math.pi * 2 / #ids))
						wPart.Position = hrp.Position + Vector3.new(math.cos(a) * 4.0, 1.5 + math.sin(t * 3.5 + i) * 0.5, math.sin(a) * 4.0)
					elseif wPart then
						wPart:Destroy()
					end
				end
			elseif pFolder then
				pFolder:Destroy()
			end
		end
	end)

	return controller
end

return WorldVisuals
