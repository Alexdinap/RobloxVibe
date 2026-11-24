local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShadowCombatConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShadowCombatConfig"))

local ShadowCombatServer = {}
local playerCooldowns = {} -- [userId][weaponId] = timestamp
local activeShadowsFolder = nil
local onShadowKilledCallback = nil

-- Crea i RemoteEvent se non esistono già
local remotesFolder = ReplicatedStorage:FindFirstChild("ShadowCombatRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "ShadowCombatRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local attackRemote = remotesFolder:FindFirstChild("AttackRequest") or Instance.new("RemoteEvent")
attackRemote.Name = "AttackRequest"
attackRemote.Parent = remotesFolder

local vfxRemote = remotesFolder:FindFirstChild("PlayVFX") or Instance.new("RemoteEvent")
vfxRemote.Name = "PlayVFX"
vfxRemote.Parent = remotesFolder

-- Costruisce il Tool 3D procedurale per ciascuna arma
local function buildWeaponTool(weaponId)
	local cfg = ShadowCombatConfig.Weapons[weaponId]
	if not cfg then
		return nil
	end

	local tool = Instance.new("Tool")
	tool.Name = cfg.DisplayName
	tool:SetAttribute("WeaponId", weaponId)
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 1.4, 0.35)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Color = Color3.fromRGB(35, 30, 40)
	handle.CanCollide = false
	handle.Parent = tool

	local function weldPart(part, offsetCFrame)
		part.CanCollide = false
		part.Massless = true
		part.CFrame = handle.CFrame * offsetCFrame
		part.Parent = tool

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = part
	end

	local light = Instance.new("PointLight")
	light.Color = cfg.Color
	light.Range = 12
	light.Brightness = 1.6

	if weaponId == "LamaDellaFiamma" then
		tool.Grip = CFrame.new(0, -0.45, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		local guard = Instance.new("Part")
		guard.Size = Vector3.new(1.1, 0.18, 0.35)
		guard.Material = Enum.Material.Metal
		guard.Color = Color3.fromRGB(215, 175, 75)
		weldPart(guard, CFrame.new(0, 0.72, 0))

		local blade = Instance.new("Part")
		blade.Size = Vector3.new(0.14, 3.2, 0.42)
		blade.Material = Enum.Material.Neon
		blade.Color = cfg.Color
		weldPart(blade, CFrame.new(0, 2.35, 0))
		light.Parent = blade
	elseif weaponId == "ScettroSolare" then
		tool.Grip = CFrame.new(0, -0.6, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		handle.Size = Vector3.new(0.28, 3.4, 0.28)
		local orb = Instance.new("Part")
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(0.95, 0.95, 0.95)
		orb.Material = Enum.Material.Neon
		orb.Color = cfg.Color
		weldPart(orb, CFrame.new(0, 2.0, 0))
		light.Parent = orb
	elseif weaponId == "LanternaEsplosiva" then
		tool.Grip = CFrame.new(0, -0.2, 0)
		local core = Instance.new("Part")
		core.Shape = Enum.PartType.Ball
		core.Size = Vector3.new(1.0, 1.2, 1.0)
		core.Material = Enum.Material.Neon
		core.Color = cfg.Color
		weldPart(core, CFrame.new(0, -0.9, -0.35))
		light.Parent = core
	end

	return tool
end

function ShadowCombatServer.GiveWeapon(player, weaponId)
	local cfg = ShadowCombatConfig.Weapons[weaponId]
	if not cfg then
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local char = player.Character
	if (backpack and backpack:FindFirstChild(cfg.DisplayName)) or (char and char:FindFirstChild(cfg.DisplayName)) then
		return
	end

	local tool = buildWeaponTool(weaponId)
	if tool and backpack then
		tool.Parent = backpack
	end
end

function ShadowCombatServer.SpawnShadow(archetypeId, spawnCFrame, folder)
	local cfg = ShadowCombatConfig.Archetypes[archetypeId] or ShadowCombatConfig.Archetypes.OmbraErrante
	local targetFolder = folder or activeShadowsFolder
	if not targetFolder then
		return nil
	end

	local hitbox = Instance.new("Part")
	hitbox.Name = archetypeId
	hitbox.Size = Vector3.new(2.5, 3.4, 2.5) * cfg.Scale
	hitbox.CFrame = spawnCFrame
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = 1

	hitbox:SetAttribute("Archetype", archetypeId)
	hitbox:SetAttribute("HP", cfg.MaxHP)
	hitbox:SetAttribute("MaxHP", cfg.MaxHP)
	hitbox:SetAttribute("BaseSpeed", cfg.Speed)
	hitbox:SetAttribute("CurrentSpeed", cfg.Speed)
	hitbox:SetAttribute("Damage", cfg.Damage)
	hitbox:SetAttribute("Reward", cfg.Reward)
	hitbox:SetAttribute("StopRange", cfg.StopRange or 3)

	hitbox.Parent = targetFolder
	return hitbox
end

function ShadowCombatServer.DamageShadow(hitbox, amount, knockbackDir, knockbackForce, slowPercent, slowDuration, attacker)
	if not hitbox or not hitbox.Parent then
		return
	end

	local currentHP = hitbox:GetAttribute("HP") or 0
	if currentHP <= 0 then
		return
	end

	local newHP = math.max(0, currentHP - amount)
	hitbox:SetAttribute("HP", newHP)

	-- Applica rallentamento temporaneo
	if slowPercent and slowPercent > 0 and slowDuration and slowDuration > 0 then
		local baseSpeed = hitbox:GetAttribute("BaseSpeed") or 10
		hitbox:SetAttribute("CurrentSpeed", baseSpeed * (1 - slowPercent))
		local token = os.clock()
		hitbox:SetAttribute("SlowToken", token)
		task.delay(slowDuration, function()
			if hitbox and hitbox.Parent and hitbox:GetAttribute("SlowToken") == token then
				hitbox:SetAttribute("CurrentSpeed", baseSpeed)
			end
		end)
	end

	-- Applica spinta (knockback)
	if knockbackDir and knockbackForce and knockbackForce > 0 and knockbackDir.Magnitude > 0.01 then
		local flatDir = Vector3.new(knockbackDir.X, 0, knockbackDir.Z).Unit
		hitbox.CFrame = hitbox.CFrame + (flatDir * (knockbackForce * 0.12))
	end

	if newHP <= 0 then
		local reward = hitbox:GetAttribute("Reward") or 10
		local deathPos = hitbox.Position
		hitbox:Destroy()
		if onShadowKilledCallback then
			onShadowKilledCallback(attacker, reward, deathPos)
		end
	end
end

local function distancePointToSegment(point, segA, segB)
	local ab = segB - segA
	local lenSq = ab:Dot(ab)
	if lenSq == 0 then
		return (point - segA).Magnitude
	end
	local t = math.clamp((point - segA):Dot(ab) / lenSq, 0, 1)
	local proj = segA + ab * t
	return (point - proj).Magnitude
end

function ShadowCombatServer.Init(shadowsFolder, onShadowKilled)
	activeShadowsFolder = shadowsFolder
	onShadowKilledCallback = onShadowKilled

	Players.PlayerRemoving:Connect(function(player)
		playerCooldowns[player.UserId] = nil
	end)

	attackRemote.OnServerEvent:Connect(function(player, weaponId, targetPos)
		if typeof(weaponId) ~= "string" or typeof(targetPos) ~= "Vector3" then
			return
		end

		local cfg = ShadowCombatConfig.Weapons[weaponId]
		if not cfg then
			return
		end

		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local equippedTool = char and char:FindFirstChildOfClass("Tool")
		if not root or not equippedTool or equippedTool:GetAttribute("WeaponId") ~= weaponId then
			return
		end

		-- Controllo cooldown server-side
		local now = os.clock()
		playerCooldowns[player.UserId] = playerCooldowns[player.UserId] or {}
		local lastUsed = playerCooldowns[player.UserId][weaponId] or 0
		if now - lastUsed < (cfg.Cooldown * 0.85) then
			return
		end
		playerCooldowns[player.UserId][weaponId] = now

		local origin = root.Position
		local flatAim = Vector3.new(targetPos.X - origin.X, 0, targetPos.Z - origin.Z)
		local aimDir = flatAim.Magnitude > 0.01 and flatAim.Unit or root.CFrame.LookVector

		if cfg.Type == "Melee" then
			local cosHalfArc = math.cos(math.rad(cfg.ArcAngle * 0.5))
			for _, shadow in ipairs(activeShadowsFolder:GetChildren()) do
				if shadow:IsA("BasePart") then
					local offset = shadow.Position - origin
					local dist = offset.Magnitude
					if dist <= cfg.Range then
						local dir = dist > 0.01 and offset.Unit or aimDir
						if dir:Dot(aimDir) >= cosHalfArc then
							ShadowCombatServer.DamageShadow(shadow, cfg.Damage, dir, cfg.Knockback, cfg.SlowPercent, cfg.SlowDuration, player)
						end
					end
				end
			end
			vfxRemote:FireAllClients(weaponId, origin, aimDir)

		elseif cfg.Type == "Ranged" then
			local endPos = origin + (aimDir * cfg.Range)
			local closestShadow = nil
			local closestDist = math.huge

			for _, shadow in ipairs(activeShadowsFolder:GetChildren()) do
				if shadow:IsA("BasePart") then
					local perpDist = distancePointToSegment(shadow.Position, origin, endPos)
					if perpDist <= cfg.HitRadius then
						local alongDist = (shadow.Position - origin):Dot(aimDir)
						if alongDist >= 0 and alongDist < closestDist then
							closestDist = alongDist
							closestShadow = shadow
						end
					end
				end
			end

			local impactPos = endPos
			if closestShadow then
				impactPos = closestShadow.Position
				ShadowCombatServer.DamageShadow(closestShadow, cfg.Damage, aimDir, cfg.Knockback, cfg.SlowPercent, cfg.SlowDuration, player)

				-- Danno ad area ridotto attorno al punto di impatto
				for _, shadow in ipairs(activeShadowsFolder:GetChildren()) do
					if shadow:IsA("BasePart") and shadow ~= closestShadow then
						if (shadow.Position - impactPos).Magnitude <= cfg.SplashRadius then
							ShadowCombatServer.DamageShadow(shadow, cfg.Damage * 0.45, shadow.Position - impactPos, cfg.Knockback * 0.5, 0, 0, player)
						end
					end
				end
			end
			vfxRemote:FireAllClients(weaponId, origin, impactPos)

		elseif cfg.Type == "AoE" then
			for _, shadow in ipairs(activeShadowsFolder:GetChildren()) do
				if shadow:IsA("BasePart") then
					local offset = shadow.Position - origin
					if offset.Magnitude <= cfg.Radius then
						ShadowCombatServer.DamageShadow(shadow, cfg.Damage, offset, cfg.Knockback, cfg.SlowPercent, cfg.SlowDuration, player)
					end
				end
			end
			vfxRemote:FireAllClients(weaponId, origin, origin)
		end
	end)
end

return ShadowCombatServer