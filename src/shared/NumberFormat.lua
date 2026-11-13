local NumberFormat = {}

local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd"
}

function NumberFormat.Format(n)
	if n == nil or n ~= n then return "0" end
	if n == math.huge then return "Infinito" end
	if n < 0 then return "-" .. NumberFormat.Format(-n) end
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

return NumberFormat
