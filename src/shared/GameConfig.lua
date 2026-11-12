local GameConfig = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
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

-- 8 Altari a Terra attorno alla Fiamma Centrale
GameConfig.Altars = {
	{ Id = "alt1", Name = "Pietra Focaia", Desc = "+1 Scintilla/s", BaseCost = 10, CostMult = 1.15, Type = "AddSpark", Value = 1, Color = Color3.fromRGB(255, 160, 50), Pos = Vector3.new(-16, 1.4, 14) },
	{ Id = "alt2", Name = "Lanterna Antica", Desc = "+7 Scintille/s", BaseCost = 85, CostMult = 1.17, Type = "AddSpark", Value = 7, Color = Color3.fromRGB(255, 210, 80), Pos = Vector3.new(16, 1.4, 14) },
	{ Id = "alt3", Name = "Braciere Runico", Desc = "x1.25 Scintille/s", BaseCost = 450, CostMult = 1.35, Type = "MultSpark", Value = 1.25, Color = Color3.fromRGB(255, 110, 40), Pos = Vector3.new(-22, 1.4, 0) },
	{ Id = "alt4", Name = "Faro del Crepuscolo", Desc = "+55 Scintille/s", BaseCost = 2200, CostMult = 1.19, Type = "AddSpark", Value = 55, Color = Color3.fromRGB(110, 220, 255), Pos = Vector3.new(22, 1.4, 0) },
	{ Id = "alt5", Name = "Specchio Solare", Desc = "x1.45 Scintille/s", BaseCost = 12000, CostMult = 1.45, Type = "MultSpark", Value = 1.45, Color = Color3.fromRGB(255, 240, 120), Pos = Vector3.new(-16, 1.4, -14) },
	{ Id = "alt6", Name = "Fucina Stellare", Desc = "+750 Scintille/s", BaseCost = 85000, CostMult = 1.21, Type = "AddSpark", Value = 750, Color = Color3.fromRGB(190, 130, 255), Pos = Vector3.new(16, 1.4, -14) },
	{ Id = "alt7", Name = "Obelisco dell'Alba", Desc = "+12K Scintille/s", BaseCost = 1.2e6, CostMult = 1.23, Type = "AddSpark", Value = 12000, Color = Color3.fromRGB(80, 255, 180), Pos = Vector3.new(-12, 1.4, -26) },
	{ Id = "alt8", Name = "Cuore del Sole", Desc = "x2.00 Scintille/s", BaseCost = 2e7, CostMult = 1.60, Type = "MultSpark", Value = 2.00, Color = Color3.fromRGB(255, 80, 130), Pos = Vector3.new(12, 1.4, -26) },
}

-- 12 Potenziamenti della Fiamma & Risveglio del Mondo
GameConfig.Upgrades = {
	{ Id = "u_breath", Name = "Soffio Vitale", Desc = "Click Fiamma x2.5", BaseCost = 20, CostMult = 2.6, Currency = "Sparks", MaxLevel = 8, LightPct = 2, Effect = "ClickMult", Value = 2.5 },
	{ Id = "u_radius", Name = "Espansione Raggio", Desc = "Allarga la luce della Fiamma (+5% Luce)", BaseCost = 50, CostMult = 2.4, Currency = "Sparks", MaxLevel = 6, LightPct = 5, Effect = "SparkMult", Value = 1.4 },
	{ Id = "u_braziers", Name = "🔥 ILLUMINA: Sentiero Bracieri", Desc = "Accende tutte le torce + Scintille x2.5", BaseCost = 300, CostMult = 1, Currency = "Sparks", MaxLevel = 1, LightPct = 15, Zone = "Braziers", Effect = "SparkMult", Value = 2.5 },
	{ Id = "u_auto1", Name = "Fiamma Autonoma I", Desc = "Potenzia da soli gli Altari 1-4", BaseCost = 1500, CostMult = 1, Currency = "Sparks", MaxLevel = 1, LightPct = 3, Effect = "Auto1", Value = 1 },
	{ Id = "u_crystals", Name = "💎 ILLUMINA: Foresta di Cristallo", Desc = "Risveglia i cristalli a Est + Sblocca Essenza Solare!", BaseCost = 4500, CostMult = 1, Currency = "Sparks", MaxLevel = 1, LightPct = 20, Zone = "Crystals", Effect = "UnlockSun", Value = 1 },
	{ Id = "u_ember", Name = "Calamita Scintille", Desc = "Attira le scintille vaganti nel buio", BaseCost = 3500, CostMult = 1, Currency = "Sparks", MaxLevel = 1, LightPct = 3, Effect = "Magnet", Value = 1 },

	-- Potenziamenti ad Essenza Solare
	{ Id = "u_wisps", Name = "Armonia degli Spiriti", Desc = "Bonus Lucciole +60% per liv.", BaseCost = 15, CostMult = 2.5, Currency = "Sun", MaxLevel = 5, LightPct = 2, Effect = "WispBonus", Value = 0.6 },
	{ Id = "u_sunflow", Name = "Condensatore Solare", Desc = "Essenza Solare/s x2.2 per liv.", BaseCost = 25, CostMult = 2.8, Currency = "Sun", MaxLevel = 5, LightPct = 2, Effect = "SunMult", Value = 2.2 },
	{ Id = "u_waterfall", Name = "🌊 ILLUMINA: Cascata Eterea", Desc = "Accende la cascata a Ovest + Scintille x4", BaseCost = 80, CostMult = 1, Currency = "Sun", MaxLevel = 1, LightPct = 18, Zone = "Waterfall", Effect = "SparkMult", Value = 4.0 },
	{ Id = "u_auto2", Name = "Fiamma Autonoma II", Desc = "Potenzia da soli gli Altari 5-8", BaseCost = 150, CostMult = 1, Currency = "Sun", MaxLevel = 1, LightPct = 4, Effect = "Auto2", Value = 1 },
	{ Id = "u_temple", Name = "🏛️ ILLUMINA: Tempio dell'Alba", Desc = "Risveglia il Tempio a Nord + Tutto x6!", BaseCost = 450, CostMult = 1, Currency = "Sun", MaxLevel = 1, LightPct = 24, Zone = "Temple", Effect = "AllMult", Value = 6.0 },
	{ Id = "u_zenith", Name = "Splendore Eterno", Desc = "Scintille/s x5.0 per liv.", BaseCost = 1200, CostMult = 3.5, Currency = "Sun", MaxLevel = 5, LightPct = 2, Effect = "SparkMult", Value = 5.0 },
}

-- 5 Spiriti di Luce (Lucciole che illuminano il giocatore nel buio)
GameConfig.WispCost = 20
GameConfig.MaxEquippedWisps = 4
GameConfig.Wisps = {
	{ Id = "w_ember", Name = "Lucciola Ambra", Weight = 50, SparkMult = 1.5, SunMult = 1.0, Color = Color3.fromRGB(255, 190, 60) },
	{ Id = "w_azure", Name = "Spirito Celeste", Weight = 28, SparkMult = 2.4, SunMult = 1.3, Color = Color3.fromRGB(70, 225, 255) },
	{ Id = "w_jade", Name = "Fata di Giada", Weight = 14, SparkMult = 4.0, SunMult = 2.0, Color = Color3.fromRGB(80, 255, 150) },
	{ Id = "w_aurora", Name = "Spirito dell'Aurora", Weight = 6, SparkMult = 8.0, SunMult = 3.5, Color = Color3.fromRGB(220, 110, 255) },
	{ Id = "w_phoenix", Name = "Fenice Primordiale", Weight = 2, SparkMult = 20.0, SunMult = 8.0, Color = Color3.fromRGB(255, 255, 255) },
}

GameConfig.PrestigeCost = 1e9

GameConfig.PromoCodes = {
	["LUCE100"] = { Sparks = 250, Sun = 0, Msg = "+250 Scintille riscattate!" },
	["ALBA2026"] = { Sparks = 0, Sun = 30, Msg = "+30 Essenza Solare riscattata!" },
}

return GameConfig
