--!strict
local BigNum = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"
}

function BigNum.Format(n: number): string
	if n == nil or n ~= n then
		return "0"
	end
	if n == math.huge then
		return "Infinito"
	end
	if n < 0 then
		return "-" .. BigNum.Format(-n)
	end
	if n < 1000 then
		if n < 10 and n % 1 ~= 0 then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n))
	end

	local tier = math.floor(math.log10(n) / 3)
	if tier < #SUFFIXES then
		local scaled = n / (10 ^ (tier * 3))
		return string.format("%.2f%s", scaled, SUFFIXES[tier + 1])
	else
		local exp = math.floor(math.log10(n))
		local mantissa = n / (10 ^ exp)
		return string.format("%.2fe%d", mantissa, exp)
	end
end

function BigNum.FormatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return tostring(seconds) .. "s"
	elseif seconds < 3600 then
		local m = math.floor(seconds / 60)
		local s = seconds % 60
		return string.format("%dm %02ds", m, s)
	else
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		return string.format("%dh %02dm", h, m)
	end
end

return BigNum
