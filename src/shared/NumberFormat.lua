local NumberFormat = {}

local SUFFIXES = {
	"", "K", "M", "B", "T",
	"Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg"
}

function NumberFormat.Format(n)
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	if n < 0 then
		return "-" .. NumberFormat.Format(-n)
	end
	if n < 1000 then
		if n < 10 and math.abs(n - math.floor(n)) >= 0.05 then
			return string.format("%.1f", n)
		end
		return tostring(math.floor(n + 0.5))
	end

	local tier = math.floor(math.log10(n) / 3)
	if tier >= #SUFFIXES then
		tier = #SUFFIXES - 1
	end

	local scale = 10 ^ (tier * 3)
	local scaled = n / scale

	if scaled >= 100 then
		return string.format("%.1f%s", scaled, SUFFIXES[tier + 1])
	else
		return string.format("%.2f%s", scaled, SUFFIXES[tier + 1])
	end
end

function NumberFormat.FormatTime(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%02d:%02d", m, s)
end

return NumberFormat
