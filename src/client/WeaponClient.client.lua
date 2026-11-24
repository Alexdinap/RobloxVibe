local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local ShadowCombatConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShadowCombatConfig"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local remotes = ReplicatedStorage:WaitForChild("ShadowCombatRemotes")
local attackRemote = remotes:WaitForChild("AttackRequest")
local vfxRemote = remotes:WaitForChild("PlayVFX")

local lastLocalAttack = {}

local function hookTool(tool)
	if not tool:IsA("Tool") then
		return
	end
	local weaponId = tool:GetAttribute("WeaponId")
	local cfg = weaponId and ShadowCombatConfig.Weapons[weaponId]
	if not cfg then
		return
	end

	tool.Activated:Connect(function()
		local now = os.clock()
		if now - (lastLocalAttack[weaponId] or 0) < cfg.Cooldown then
			return
		end
		lastLocalAttack[weaponId] = now

		local hitPos = mouse.Hit and mouse.Hit.Position or (player.Character.HumanoidRootPart.Position + player.Character.HumanoidRootPart.CFrame.LookVector * 10)
		attackRemote:FireServer(weaponId, hitPos)
	end)
end

local function onCharacterAdded(char)
	for _, child in ipairs(char:GetChildren()) do
		hookTool(child)
	end
	char.ChildAdded:Connect(hookTool)
end

if player.Character then
	onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- Effetti visivi dei colpi
vfxRemote.OnClientEvent:Connect(function(weaponId, origin, targetOrDir)
	local cfg = ShadowCombatConfig.Weapons[weaponId]
	if not cfg then
		return
	end

	if weaponId == "LamaDellaFiamma" then
		local slash = Instance.new("Part")
		slash.Anchored = true
		slash.CanCollide = false
		slash.CanQuery = false
		slash.Material = Enum.Material.Neon
		slash.Color = cfg.Color
		slash.Size = Vector3.new(cfg.Range * 1.1, 0.25, 2.2)
		slash.CFrame = CFrame.lookAt(origin, origin + targetOrDir) * CFrame.new(0, 0, -cfg.Range * 0.45)
		slash.Parent = workspace

		TweenService:Create(slash, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = slash.Size + Vector3.new(2, 0, 1.5),
			CFrame = slash.CFrame * CFrame.new(0, 0, -2.5),
		}):Play()
		Debris:AddItem(slash, 0.25)

	elseif weaponId == "ScettroSolare" then
		local dist = (targetOrDir - origin).Magnitude
		local travelTime = math.clamp(dist / 140, 0.06, 0.35)

		local orb = Instance.new("Part")
		orb.Shape = Enum.PartType.Ball
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.Material = Enum.Material.Neon
		orb.Color = cfg.Color
		orb.Size = Vector3.new(1.1, 1.1, 1.1)
		orb.Position = origin + Vector3.new(0, 1, 0)
		orb.Parent = workspace

		local tween = TweenService:Create(orb, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
			Position = targetOrDir,
		})
		tween:Play()
		tween.Completed:Connect(function()
			orb.Size = Vector3.new(cfg.SplashRadius * 1.6, cfg.SplashRadius * 1.6, cfg.SplashRadius * 1.6)
			TweenService:Create(orb, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			Debris:AddItem(orb, 0.22)
		end)

	elseif weaponId == "LanternaEsplosiva" then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Material = Enum.Material.Neon
		ring.Color = cfg.Color
		ring.Transparency = 0.25
		ring.Size = Vector3.new(0.4, 2, 2)
		ring.CFrame = CFrame.new(origin - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace

		local maxDiameter = cfg.Radius * 2
		TweenService:Create(ring, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.2, maxDiameter, maxDiameter),
			Transparency = 1,
		}):Play()
		Debris:AddItem(ring, 0.4)
	end
end)