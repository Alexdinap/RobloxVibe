local GameConfig = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"
}

function GameConfig.Format(n)
	if n == nil or n ~= n then return "0" end
	if n == math.huge then return "Infinito" end
	if n < 0 then return "-" .. GameConfig.Format(-n) end
	if n < 1000 then
		if n < 10 and n % 1 ~= 0 then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n))
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier < #SUFFIXES then
		return string.format("%.2f%s", n / (10 ^ (tier * 3)), SUFFIXES[tier + 1])
	else
		local exp = math.floor(math.log10(n))
		return string.format("%.2fe%d", n / (10 ^ exp), exp)
	end
end

function GameConfig.FormatTime(sec)
	sec = math.max(0, math.floor(sec))
	if sec < 60 then return tostring(sec) .. "s" end
	if sec < 3600 then return string.format("%dm %02ds", math.floor(sec / 60), sec % 60) end
	return string.format("%dh %02dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60))
end

-- 12 Pulsanti a Terra (Griglia 4x3 lungo il Viale Centrale)
GameConfig.Buttons = {
	-- Fila 1 (Base)
	{ Id = "btn1", Name = "Generatore Base", Desc = "+1 Watt/s", BaseCost = 10, CostMult = 1.15, Type = "AddWatt", Value = 1, Color = Color3.fromRGB(0, 225, 255), Pos = Vector3.new(-22, 1.5, 16) },
	{ Id = "btn2", Name = "Amplificatore", Desc = "+8 Watt/s", BaseCost = 100, CostMult = 1.17, Type = "AddWatt", Value = 8, Color = Color3.fromRGB(0, 255, 165), Pos = Vector3.new(0, 1.5, 16) },
	{ Id = "btn3", Name = "Condensatore", Desc = "x1.25 Watt/s", BaseCost = 500, CostMult = 1.35, Type = "MultWatt", Value = 1.25, Color = Color3.fromRGB(255, 205, 0), Pos = Vector3.new(22, 1.5, 16) },
	-- Fila 2 (Avanzata)
	{ Id = "btn4", Name = "Turbina Quantica", Desc = "+65 Watt/s", BaseCost = 2500, CostMult = 1.19, Type = "AddWatt", Value = 65, Color = Color3.fromRGB(130, 105, 255), Pos = Vector3.new(-22, 1.5, 0) },
	{ Id = "btn5", Name = "Sovralimentatore", Desc = "x1.50 Watt/s", BaseCost = 15000, CostMult = 1.45, Type = "MultWatt", Value = 1.50, Color = Color3.fromRGB(255, 80, 160), Pos = Vector3.new(0, 1.5, 0) },
	{ Id = "btn6", Name = "Sintetizzatore", Desc = "+850 Watt/s", BaseCost = 100000, CostMult = 1.21, Type = "AddWatt", Value = 850, Color = Color3.fromRGB(255, 115, 45), Pos = Vector3.new(22, 1.5, 0) },
	-- Fila 3 (Quantica)
	{ Id = "btn7", Name = "Reattore ad Arco", Desc = "+12K Watt/s", BaseCost = 1.5e6, CostMult = 1.23, Type = "AddWatt", Value = 12000, Color = Color3.fromRGB(60, 175, 255), Pos = Vector3.new(-22, 1.5, -16) },
	{ Id = "btn8", Name = "Matrice Fotonica", Desc = "x2.00 Watt/s", BaseCost = 2.5e7, CostMult = 1.60, Type = "MultWatt", Value = 2.00, Color = Color3.fromRGB(210, 70, 255), Pos = Vector3.new(0, 1.5, -16) },
	{ Id = "btn9", Name = "Motore Singolarità", Desc = "+250K Watt/s", BaseCost = 5e8, CostMult = 1.25, Type = "AddWatt", Value = 250000, Color = Color3.fromRGB(255, 50, 85), Pos = Vector3.new(22, 1.5, -16) },
	-- Fila 4 (Cosmica)
	{ Id = "btn10", Name = "Fenditura Stellare", Desc = "+6M Watt/s", BaseCost = 1e10, CostMult = 1.26, Type = "AddWatt", Value = 6e6, Color = Color3.fromRGB(0, 255, 220), Pos = Vector3.new(-22, 1.5, -32) },
	{ Id = "btn11", Name = "Nucleo di Antimateria", Desc = "x3.00 Watt/s", BaseCost = 2.5e11, CostMult = 1.75, Type = "MultWatt", Value = 3.00, Color = Color3.fromRGB(255, 230, 90), Pos = Vector3.new(0, 1.5, -32) },
	{ Id = "btn12", Name = "Orizzonte degli Eventi", Desc = "+180M Watt/s", BaseCost = 5e12, CostMult = 1.28, Type = "AddWatt", Value = 1.8e8, Color = Color3.fromRGB(255, 70, 190), Pos = Vector3.new(22, 1.5, -32) },
}

-- 18 Nodi sull'Upgrade Tree Principale (Muro Nord)
GameConfig.Upgrades = {
	{ Id = "u1", Name = "Raffreddamento", Desc = "Watt/s x1.5", Cost = 25, CostMult = 2.5, Currency = "Watt", MaxLevel = 5, Prereq = nil, GridX = 0.50, GridY = 0.10, Effect = "WattMult", Value = 1.5 },
	{ Id = "u2", Name = "Superconduttori", Desc = "Costi -7%", Cost = 150, CostMult = 3.0, Currency = "Watt", MaxLevel = 6, Prereq = "u1", GridX = 0.20, GridY = 0.26, Effect = "CostDiscount", Value = 0.07 },
	{ Id = "u3", Name = "Risonanza Nucleo", Desc = "Click x2.5", Cost = 200, CostMult = 2.8, Currency = "Watt", MaxLevel = 6, Prereq = "u1", GridX = 0.50, GridY = 0.26, Effect = "ClickMult", Value = 2.5 },
	{ Id = "u4", Name = "Magnetismo Sfere", Desc = "Sfere +50%", Cost = 350, CostMult = 3.2, Currency = "Watt", MaxLevel = 5, Prereq = "u1", GridX = 0.80, GridY = 0.26, Effect = "OrbBonus", Value = 0.5 },

	{ Id = "u5", Name = "Sovraccarico Rete", Desc = "Watt/s x2.0", Cost = 1800, CostMult = 3.5, Currency = "Watt", MaxLevel = 6, Prereq = "u2", GridX = 0.12, GridY = 0.43, Effect = "WattMult", Value = 2.0 },
	{ Id = "u6", Name = "Auto-Buyer Fila 1", Desc = "Pulsanti 1-3", Cost = 2500, CostMult = 1, Currency = "Watt", MaxLevel = 1, Prereq = "u2", GridX = 0.30, GridY = 0.43, Effect = "AutoRow1", Value = 1 },
	{ Id = "u7", Name = "INIETTORE PLASMA", Desc = "Sblocca Plasma/s!", Cost = 5000, CostMult = 1, Currency = "Watt", MaxLevel = 1, Prereq = "u3", GridX = 0.50, GridY = 0.43, Effect = "UnlockPlasma", Value = 1 },
	{ Id = "u8", Name = "Maestria Critica", Desc = "Critico Nucleo x2", Cost = 4000, CostMult = 3.4, Currency = "Watt", MaxLevel = 5, Prereq = "u3", GridX = 0.70, GridY = 0.43, Effect = "CritMult", Value = 2.0 },
	{ Id = "u9", Name = "Attrazione Sfere", Desc = "Calamita Sfere", Cost = 4500, CostMult = 1, Currency = "Watt", MaxLevel = 1, Prereq = "u4", GridX = 0.88, GridY = 0.43, Effect = "MagnetPull", Value = 1 },

	{ Id = "u10", Name = "Auto-Buyer Fila 2", Desc = "Pulsanti 4-6", Cost = 20, CostMult = 1, Currency = "Plasma", MaxLevel = 1, Prereq = "u6", GridX = 0.15, GridY = 0.60, Effect = "AutoRow2", Value = 1 },
	{ Id = "u11", Name = "Sintesi Plasma", Desc = "Plasma/s x2.2", Cost = 30, CostMult = 2.7, Currency = "Plasma", MaxLevel = 6, Prereq = "u7", GridX = 0.38, GridY = 0.60, Effect = "PlasmaMult", Value = 2.2 },
	{ Id = "u12", Name = "Sinergia Droni", Desc = "Droni +60%", Cost = 45, CostMult = 2.9, Currency = "Plasma", MaxLevel = 5, Prereq = "u7", GridX = 0.62, GridY = 0.60, Effect = "DroneSynergy", Value = 0.6 },
	{ Id = "u13", Name = "Auto-Buyer Fila 3", Desc = "Pulsanti 7-9", Cost = 150, CostMult = 1, Currency = "Plasma", MaxLevel = 1, Prereq = "u8", GridX = 0.85, GridY = 0.60, Effect = "AutoRow3", Value = 1 },

	{ Id = "u14", Name = "Motore a Fusione", Desc = "Watt/s x3.5", Cost = 220, CostMult = 3.2, Currency = "Plasma", MaxLevel = 6, Prereq = "u10", GridX = 0.12, GridY = 0.77, Effect = "WattMult", Value = 3.5 },
	{ Id = "u15", Name = "Reattore Quantico", Desc = "Plasma/s x3.5", Cost = 350, CostMult = 3.4, Currency = "Plasma", MaxLevel = 6, Prereq = "u11", GridX = 0.31, GridY = 0.77, Effect = "PlasmaMult", Value = 3.5 },
	{ Id = "u16", Name = "Slot Drone Extra", Desc = "+1 Drone attivo", Cost = 500, CostMult = 4.0, Currency = "Plasma", MaxLevel = 2, Prereq = "u12", GridX = 0.50, GridY = 0.77, Effect = "ExtraDroneSlot", Value = 1 },
	{ Id = "u17", Name = "Auto-Buyer Fila 4", Desc = "Pulsanti 10-12", Cost = 1200, CostMult = 1, Currency = "Plasma", MaxLevel = 1, Prereq = "u13", GridX = 0.69, GridY = 0.77, Effect = "AutoRow4", Value = 1 },
	{ Id = "u18", Name = "Singolarità Stabile", Desc = "Watt/s x6.0", Cost = 2500, CostMult = 4.0, Currency = "Plasma", MaxLevel = 6, Prereq = "u13", GridX = 0.88, GridY = 0.77, Effect = "WattMult", Value = 6.0 },
}

-- Santuario Materia Oscura (Prestige)
GameConfig.PrestigeCost = 1e12
GameConfig.DarkUpgrades = {
	{ Id = "dm1", Name = "Nucleo Primordiale", Desc = "Parti con 50K W e 60 Plasma", Cost = 1, CostMult = 2, MaxLevel = 3 },
	{ Id = "dm2", Name = "Fabbrica Economica", Desc = "Costo Droni -50% (25 Plasma)", Cost = 1, CostMult = 1, MaxLevel = 1 },
	{ Id = "dm3", Name = "Fortuna Astrale", Desc = "2x Probabilità Droni Rari", Cost = 2, CostMult = 3, MaxLevel = 2 },
	{ Id = "dm4", Name = "Iper-Produzione", Desc = "Watt/s e Plasma/s x25!", Cost = 2, CostMult = 3, MaxLevel = 5 },
	{ Id = "dm5", Name = "Memoria Quantica", Desc = "Mantieni gli Auto-Buyer al reset", Cost = 3, CostMult = 1, MaxLevel = 1 },
	{ Id = "dm6", Name = "Eternità Offline", Desc = "Guadagno offline 100% (24h)", Cost = 4, CostMult = 1, MaxLevel = 1 },
}

-- Potenziamenti Camera AFK (Frammenti Temporali)
GameConfig.AfkUpgrades = {
	{ Id = "afk_speed", Name = "Propulsori Ionici", Desc = "+4 Velocità Corsa per liv.", BaseCost = 15, CostMult = 1.8, MaxLevel = 8 },
	{ Id = "afk_jump", Name = "Stivali Antigravità", Desc = "+12 Salto per liv.", BaseCost = 20, CostMult = 1.9, MaxLevel = 6 },
	{ Id = "afk_watt", Name = "Dilatazione Temporale", Desc = "+35% Watt/s e Plasma/s", BaseCost = 30, CostMult = 2.2, MaxLevel = 10 },
	{ Id = "afk_frag", Name = "Condensatore Crono", Desc = "+1 Frammento/s in Camera AFK", BaseCost = 40, CostMult = 2.5, MaxLevel = 5 },
}

-- 3 Sfide Quantiche Opzionali (Nessuna perdita dei progressi reali)
GameConfig.Challenges = {
	{
		Id = "ch1",
		Name = "Sovraccarico Manuale",
		Desc = "I pulsanti costano x10, ma i Click valgono x50! Raggiungi 50K Watt in 120s.",
		Duration = 120,
		GoalWatt = 50000,
		RewardText = "Permanente: Click Nucleo x4.0",
	},
	{
		Id = "ch2",
		Name = "Crisi Energetica",
		Desc = "Parti da 0 senza droni né upgrade. Raggiungi 250K Watt in 150s.",
		Duration = 150,
		GoalWatt = 250000,
		RewardText = "Permanente: Watt/s x2.5",
	},
	{
		Id = "ch3",
		Name = "Singolarità Lampo",
		Desc = "Costo pulsanti x25, ma guadagni x5! Raggiungi 5M Watt in 180s.",
		Duration = 180,
		GoalWatt = 5000000,
		RewardText = "Permanente: Plasma/s x3.0 e Watt/s x2.0",
	},
}

-- Fabbrica & Forgia Droni (3 Droni uguali -> 1 Sovraccarico x2.5)
GameConfig.BaseDroneCost = 50
GameConfig.BaseEquippedDrones = 3
GameConfig.Drones = {
	{ Id = "d_base", Name = "Drone Base", Chance = "50.0%", Weight = 500, WattMult = 1.5, PlasmaMult = 1.0, Color = Color3.fromRGB(0, 230, 255) },
	{ Id = "d_ioni", Name = "Drone Ioni", Chance = "26.0%", Weight = 260, WattMult = 2.4, PlasmaMult = 1.3, Color = Color3.fromRGB(80, 255, 110) },
	{ Id = "d_plasma", Name = "Drone Plasma", Chance = "13.0%", Weight = 130, WattMult = 4.0, PlasmaMult = 2.0, Color = Color3.fromRGB(210, 75, 255) },
	{ Id = "d_quantico", Name = "Drone Quantico", Chance = "6.5%", Weight = 65, WattMult = 7.5, PlasmaMult = 3.5, Color = Color3.fromRGB(255, 210, 40) },
	{ Id = "d_stellare", Name = "Drone Stellare", Chance = "3.0%", Weight = 30, WattMult = 15.0, PlasmaMult = 6.0, Color = Color3.fromRGB(255, 110, 30) },
	{ Id = "d_singolarita", Name = "Singolarità", Chance = "1.2%", Weight = 12, WattMult = 35.0, PlasmaMult = 12.0, Color = Color3.fromRGB(255, 45, 95) },
	{ Id = "d_divino", Name = "Divinità Quantica", Chance = "0.3%", Weight = 3, WattMult = 100.0, PlasmaMult = 30.0, Color = Color3.fromRGB(255, 255, 255) },
}

-- 8 Gradi Visibili e Scie Luminose
GameConfig.Ranks = {
	{ MinWatt = 0, Name = "Apprendista", Color = Color3.fromRGB(170, 190, 210) },
	{ MinWatt = 5e3, Name = "Tecnico", Color = Color3.fromRGB(0, 225, 255) },
	{ MinWatt = 2.5e5, Name = "Ingegnere", Color = Color3.fromRGB(0, 255, 155) },
	{ MinWatt = 1e7, Name = "Fisico Quantico", Color = Color3.fromRGB(140, 110, 255) },
	{ MinWatt = 5e8, Name = "Architetto Plasma", Color = Color3.fromRGB(220, 75, 255) },
	{ MinWatt = 2.5e10, Name = "Signore Stellare", Color = Color3.fromRGB(255, 200, 40) },
	{ MinWatt = 1e12, Name = "Singolarità", Color = Color3.fromRGB(255, 55, 100) },
	{ MinWatt = 1e15, Name = "Entità Cosmica", Color = Color3.fromRGB(255, 255, 255) },
}

-- 10 Obiettivi Permanenti
GameConfig.Achievements = {
	{ Id = "ach_click1", Name = "Primo Impulso", Desc = "Clicca il Nucleo 25 volte", Stat = "TotalClicks", Target = 25, BonusText = "+25% Click", MultType = "Click", MultVal = 1.25 },
	{ Id = "ach_crit1", Name = "Riflessi Quantici", Desc = "Colpisci 5 Punti Critici", Stat = "CritHits", Target = 5, BonusText = "+50% Critici", MultType = "Crit", MultVal = 1.50 },
	{ Id = "ach_watt1", Name = "Centrale Elettrica", Desc = "Accumula 10K Watt totali", Stat = "TotalWatt", Target = 1e4, BonusText = "+25% Watt/s", MultType = "Watt", MultVal = 1.25 },
	{ Id = "ach_watt2", Name = "Megawatt", Desc = "Accumula 10M Watt totali", Stat = "TotalWatt", Target = 1e7, BonusText = "+50% Watt/s", MultType = "Watt", MultVal = 1.50 },
	{ Id = "ach_watt3", Name = "Signore dell'Energia", Desc = "Accumula 10B Watt totali", Stat = "TotalWatt", Target = 1e10, BonusText = "x2.0 Watt/s", MultType = "Watt", MultVal = 2.00 },
	{ Id = "ach_btn1", Name = "Costruttore", Desc = "Compra 50 livelli pulsanti", Stat = "TotalButtonLevels", Target = 50, BonusText = "+25% Watt/s", MultType = "Watt", MultVal = 1.25 },
	{ Id = "ach_drone1", Name = "Primo Satellite", Desc = "Fabbrica 1 Drone", Stat = "DronesCrafted", Target = 1, BonusText = "+25% Plasma/s", MultType = "Plasma", MultVal = 1.25 },
	{ Id = "ach_fuse1", Name = "Mastro Forgiatore", Desc = "Fondi 1 Drone Sovraccarico", Stat = "FusionsDone", Target = 1, BonusText = "+50% Droni", MultType = "Drone", MultVal = 1.50 },
	{ Id = "ach_afk1", Name = "Viaggiatore del Tempo", Desc = "Raccogli 100 Frammenti AFK", Stat = "TotalFragments", Target = 100, BonusText = "+30% Watt/s", MultType = "Watt", MultVal = 1.30 },
	{ Id = "ach_dm1", Name = "Oltre l'Orizzonte", Desc = "Completa 1 Collasso Quantistico", Stat = "DarkMatterEarned", Target = 1, BonusText = "x3.0 Tutto", MultType = "All", MultVal = 3.00 },
}

-- Codici Promo
GameConfig.PromoCodes = {
	["QUANTUM100"] = { Watt = 300, Plasma = 0, Frags = 0, Msg = "+300 Watt riscattati!" },
	["NEON2026"] = { Watt = 0, Plasma = 60, Frags = 0, Msg = "+60 Plasma riscattati!" },
	["CHRONO50"] = { Watt = 0, Plasma = 0, Frags = 50, Msg = "+50 Frammenti Temporali!" },
	["CITADEL"] = { Watt = 2000, Plasma = 50, Frags = 25, Msg = "Pacchetto Cittadella riscattato!" },
}

-- Stadi Evolutivi del Nucleo
GameConfig.CoreStages = {
	{ MinWatt = 0, Size = 6.2, Color = Color3.fromRGB(0, 225, 255), Spin = 1.0 },
	{ MinWatt = 1e4, Size = 7.2, Color = Color3.fromRGB(0, 255, 155), Spin = 1.5 },
	{ MinWatt = 1e7, Size = 8.4, Color = Color3.fromRGB(195, 75, 255), Spin = 2.1 },
	{ MinWatt = 1e10, Size = 9.8, Color = Color3.fromRGB(255, 195, 0), Spin = 2.8 },
	{ MinWatt = 1e13, Size = 11.4, Color = Color3.fromRGB(255, 45, 95), Spin = 3.6 },
}

GameConfig.ServerBatteryMax = 500
GameConfig.ServerDonationStep = 25

return GameConfig
