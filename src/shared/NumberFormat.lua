local NumberFormat = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"
}

function NumberFormat.Format(n)
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	if n < 0 then
		return "-" .. NumberFormat.Format(-n)
	end
	if n < 1000 then
		return tostring(math.floor(n + 1e-6))
	end

	local tier = math.floor(math.log10(n) / 3)
	if tier >= #SUFFIXES then
		tier = #SUFFIXES - 1
	end

	local scale = 10 ^ (tier * 3)
	local scaled = n / scale

	if scaled >= 100 then
		return string.format("%d%s", math.floor(scaled + 1e-6), SUFFIXES[tier + 1])
	elseif scaled >= 10 then
		local v = math.floor(scaled * 10 + 1e-6) / 10
		if v % 1 == 0 then
			return string.format("%d%s", v, SUFFIXES[tier + 1])
		end
		return string.format("%.1f%s", v, SUFFIXES[tier + 1])
	else
		local v = math.floor(scaled * 100 + 1e-6) / 100
		if v % 1 == 0 then
			return string.format("%d%s", v, SUFFIXES[tier + 1])
		end
		return string.format("%.2f%s", v, SUFFIXES[tier + 1])
	end
end

return NumberFormat
