local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GameConfig = require(Modules:WaitForChild("GameConfig"))
local ClientState = require(script.Parent:WaitForChild("ClientState"))

local world = workspace:WaitForChild("QuantumWorld")
local coreAssembly = world:WaitForChild("QuantumCoreAssembly")
local corePart = coreAssembly:WaitForChild("CorePart")
local ring1 = coreAssembly:WaitForChild("Ring1")
local ring2 = coreAssembly:WaitForChild("Ring2")
local droneHolo = world:WaitForChild("DroneHolo")

local visualFolder = Instance.new("Folder")
visualFolder.Name = "PlayerVisuals"
visualFolder.Parent = workspace

local droneColorMap = {}
for _, d in ipairs(GameConfig.Drones) do
	droneColorMap[d.Id] = d.Color
end

local angle = 0
RunService.RenderStepped:Connect(function(dt)
	local stage = GameConfig.CoreStages[1]
	for _, s in ipairs(GameConfig.CoreStages) do
		if ClientState.TotalWatt >= s.MinWatt then
			stage = s
		end
	end

	angle += dt * stage.Spin
	ClientState.PulseScale = math.max(0, ClientState.PulseScale - dt * 3.5)

	local breath = 1 + math.sin(angle * 3) * 0.05 + ClientState.PulseScale * 0.22
	corePart.Size = Vector3.new(stage.Size, stage.Size, stage.Size) * breath

	if ClientState.IsOverload then
		corePart.Color = Color3.fromRGB(255, 45, 45)
	elseif ClientState.IsGolden then
		corePart.Color = Color3.fromRGB(255, 215, 40)
	else
		corePart.Color = stage.Color
	end

	ring1.Size = Vector3.new(stage.Size * 1.7, 0.35, stage.Size * 1.7)
	ring2.Size = Vector3.new(stage.Size * 2.1, 0.3, stage.Size * 2.1)
	ring1.CFrame = CFrame.new(corePart.Position) * CFrame.Angles(angle, angle * 0.7, 0)
	ring2.CFrame = CFrame.new(corePart.Position) * CFrame.Angles(-angle * 0.6, 0, angle * 1.1)

	-- Ologramma rotante Fabbrica Droni
	droneHolo.CFrame = CFrame.new(48, 5.8 + math.sin(angle * 2) * 0.4, 22) * CFrame.Angles(angle * 0.8, angle * 1.2, 0)

	-- Droni e Aure orbitanti attorno ai giocatori
	local localPlr = Players.LocalPlayer
	for _, plr in ipairs(Players:GetPlayers()) do
		local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local pFolder = visualFolder:FindFirstChild(plr.Name)
		local hide = ClientState.HideOtherDrones and (plr ~= localPlr)

		if hrp and not hide then
			if not pFolder then
				pFolder = Instance.new("Folder")
				pFolder.Name = plr.Name
				pFolder.Parent = visualFolder
			end

			local rawIds = plr:GetAttribute("EquippedDrones") or "[]"
			local ok, ids = pcall(function() return HttpService:JSONDecode(rawIds) end)
			ids = (ok and type(ids) == "table") and ids or {}

			for i = 1, 5 do
				local dPart = pFolder:FindFirstChild("Drone_" .. i)
				if ids[i] then
					if not dPart then
						dPart = Instance.new("Part")
						dPart.Name = "Drone_" .. i
						dPart.Size = Vector3.new(1.15, 1.15, 1.15)
						dPart.Anchored = true
						dPart.CanCollide = false
						dPart.Material = Enum.Material.Neon
						dPart.Parent = pFolder
					end
					dPart.Color = droneColorMap[ids[i]] or Color3.fromRGB(0, 220, 255)
					local a = angle * 1.6 + (i * (math.pi * 2 / #ids))
					local radius = 4.2
					dPart.CFrame = CFrame.new(
						hrp.Position + Vector3.new(math.cos(a) * radius, 1.4 + math.sin(angle * 3 + i) * 0.45, math.sin(a) * radius)
					) * CFrame.Angles(0, -a, 0)
				elseif dPart then
					dPart:Destroy()
				end
			end

			local dm = plr:GetAttribute("DarkMatter") or 0
			local aura = pFolder:FindFirstChild("DarkAura")
			if dm > 0 then
				if not aura then
					aura = Instance.new("Part")
					aura.Name = "DarkAura"
					aura.Shape = Enum.PartType.Ball
					aura.Size = Vector3.new(1.6, 1.6, 1.6)
					aura.Anchored = true
					aura.CanCollide = false
					aura.Material = Enum.Material.Neon
					aura.Color = Color3.fromRGB(255, 50, 120)
					aura.Parent = pFolder
				end
				aura.Position = hrp.Position + Vector3.new(math.cos(-angle * 2.2) * 3.0, 3.3, math.sin(-angle * 2.2) * 3.0)
			elseif aura then
				aura:Destroy()
			end
		elseif pFolder then
			pFolder:Destroy()
		end
	end
end)
