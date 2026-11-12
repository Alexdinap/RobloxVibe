--!nonstrict
--[[
	BigNum - gestione e formattazione dei numeri enormi.

	Il gioco usa numeri Lua (double), che arrivano fino a ~1.8e308: questo modulo
	non cambia il tipo dei numeri, ma fornisce una formattazione leggibile con
	suffissi (K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc) e passa automaticamente
	alla notazione scientifica oltre il ultimo suffisso (1e36).
]]

local BigNum = {}

-- Soglie e sigle, dalla piu' piccola alla piu' grande.
local SUFFISSI = {
	{ valore = 1e3, sigla = "K" }, -- migliaia
	{ valore = 1e6, sigla = "M" }, -- milioni
	{ valore = 1e9, sigla = "B" }, -- miliardi
	{ valore = 1e12, sigla = "T" }, -- trilioni
	{ valore = 1e15, sigla = "Qa" }, -- quadrilioni
	{ valore = 1e18, sigla = "Qi" }, -- quintilioni
	{ valore = 1e21, sigla = "Sx" }, -- sestilioni
	{ valore = 1e24, sigla = "Sp" }, -- settilioni
	{ valore = 1e27, sigla = "Oc" }, -- ottilioni
	{ valore = 1e30, sigla = "No" }, -- nonilioni
	{ valore = 1e33, sigla = "Dc" }, -- decilioni
}

-- Toglie gli zeri inutili in coda: "1.250" -> "1.25", "12.0" -> "12".
local function trimZeri(testo: string): string
	if string.find(testo, "%.") then
		testo = string.gsub(testo, "0+$", "")
		testo = string.gsub(testo, "%.$", "")
	end
	return testo
end

--[[
	Formatta un numero in modo compatto.
	BigNum.format(1234)      -> "1.23K"
	BigNum.format(45.678)    -> "45.7"
	BigNum.format(1.5e40)    -> "1.50e40"
]]
function BigNum.format(valore: number, decimali: number?): string
	-- Valori non finiti o non numerici (difesa contro NaN nel salvataggio).
	if valore ~= valore then
		return "0"
	end
	if valore == math.huge then
		return "inf"
	end
	if valore == -math.huge then
		return "-inf"
	end

	local segno = ""
	local assoluto = valore
	if valore < 0 then
		segno = "-"
		assoluto = -valore
	end

	-- Sotto le migliaia niente suffisso.
	if assoluto < 1000 then
		local dec = decimali
		if dec == nil then
			if assoluto < 10 then
				dec = 2
			elseif assoluto < 100 then
				dec = 1
			else
				dec = 0
			end
		end
		return segno .. trimZeri(string.format("%." .. dec .. "f", assoluto))
	end

	local ultimo = SUFFISSI[#SUFFISSI]
	if assoluto >= ultimo.valore * 1000 then
		-- Oltre 1e36: notazione scientifica.
		local esponente = math.floor(math.log10(assoluto))
		local mantissa = assoluto / (10 ^ esponente)
		return string.format("%s%.2fe%d", segno, mantissa, esponente)
	end

	local indiceSuffisso = nil
	for indice = #SUFFISSI, 1, -1 do
		if assoluto >= SUFFISSI[indice].valore then
			indiceSuffisso = indice
			break
		end
	end

	if indiceSuffisso then
		local function formattaConSuffisso(indice)
			local scala = assoluto / SUFFISSI[indice].valore
			local dec = decimali
			if dec == nil then
				dec = scala < 10 and 2 or (scala < 100 and 1 or 0)
			end
			local arrotondata = string.format("%." .. dec .. "f", scala)
			-- Es. 999999 non deve diventare "1000K" ma "1M".
			if tonumber(arrotondata) >= 1000 and indice < #SUFFISSI then
				return formattaConSuffisso(indice + 1)
			end
			return segno .. trimZeri(arrotondata) .. SUFFISSI[indice].sigla
		end

		return formattaConSuffisso(indiceSuffisso)
	end

	-- Non raggiungibile, ma tenuto come rete di sicurezza.
	return segno .. tostring(math.floor(assoluto))
end

-- Formatta una velocita', es. "1.23K/s".
function BigNum.formatRate(valore: number): string
	return BigNum.format(valore) .. "/s"
end

-- Formatta secondi in mm:ss (per timer di boost, popup, ecc.).
function BigNum.formatTime(secondi: number): string
	local totale = math.max(0, math.floor(secondi))
	local minuti = math.floor(totale / 60)
	local secondiRimanenti = totale % 60
	return string.format("%d:%02d", minuti, secondiRimanenti)
end

-- Limita un numero nell'intervallo sicuro dei double (evita inf da overflow).
function BigNum.clamp(valore: number, massimo: number?): number
	local tetto = massimo or 1e308
	if valore ~= valore then
		return 0
	end
	if valore > tetto then
		return tetto
	end
	if valore < -tetto then
		return -tetto
	end
	return valore
end

-- Restituisce la sigla usata per un certo valore (utile per tooltip/debug).
function BigNum.sigla(valore: number): string
	local assoluto = math.abs(valore)
	for indice = #SUFFISSI, 1, -1 do
		if assoluto >= SUFFISSI[indice].valore then
			return SUFFISSI[indice].sigla
		end
	end
	return ""
end

return BigNum
