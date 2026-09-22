local NumberFormat = {}

-- Standart K, M, B, T ve sonrasında çift harfler (aa, bb, ... zz), ardından üçlü harfler
local SUFFIXES = {
	"", "K", "M", "B", "T"
}

-- aa'dan zz'ye kadar çift harfleri ekle
local alphabet = "abcdefghijklmnopqrstuvwxyz"
for i = 1, #alphabet do
	local char = alphabet:sub(i, i)
	table.insert(SUFFIXES, char .. char)
end

-- İhtiyaç halinde aaa, bbb... üçlü harfler
for i = 1, #alphabet do
	local char = alphabet:sub(i, i)
	table.insert(SUFFIXES, char .. char .. char)
end

-- Sayıyı kısaltılmış biçime dönüştürür (örn: 1250 -> 1.25K, 4500000 -> 4.50M, 1e15 -> 1.00aa)
function NumberFormat.FormatCompact(value: number): string
	if not value or value ~= value then return "0" end
	if value < 0 then
		return "-" .. NumberFormat.FormatCompact(-value)
	end
	if value < 1000 then
		if value == math.floor(value) then
			return tostring(math.floor(value))
		else
			return string.format("%.2f", value)
		end
	end

	local tier = math.floor(math.log10(value) / 3)
	if tier < 1 then
		return string.format("%.0f", value)
	end

	if tier >= #SUFFIXES then
		tier = #SUFFIXES - 1
	end

	local scale = 10 ^ (tier * 3)
	local scaled = value / scale
	local suffix = SUFFIXES[tier + 1] or ""

	if scaled >= 100 then
		return string.format("%.1f%s", scaled, suffix)
	else
		return string.format("%.2f%s", scaled, suffix)
	end
end

-- İnşaat Puanı (İP) sembolüyle birlikte formatlama
function NumberFormat.FormatCash(value: number): string
	return NumberFormat.FormatCompact(value) .. " İP"
end

-- Kristal formatlama
function NumberFormat.FormatCrystals(value: number): string
	return NumberFormat.FormatCompact(value) .. " 💎"
end

-- Mühendis formatlama (küçük kesirleri destekler, örn: 0.45 👷 veya 12.50K 👷)
function NumberFormat.FormatEngineers(value: number): string
	if value < 10 and value > 0 and value ~= math.floor(value) then
		return string.format("%.2f 👷", value)
	end
	return NumberFormat.FormatCompact(value) .. " 👷"
end

return NumberFormat
