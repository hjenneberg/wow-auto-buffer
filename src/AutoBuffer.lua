local addonName, addon = ...

addon.name = addonName

addon.ColorPrefix = "|cFF66CCFF"
addon.ColorText = "|cFFA0A0A0"
addon.ColorHighlight = "|cFFFFFF00"
addon.ColorCommand = "|cFFFF9900"
addon.ColorError = "|cFFFF6060"
addon.ColorEnd = "|r"

-- Normal chat text is gray, so white (priests, unknown class) stands out.
-- "|r" resets to the chat default, so gray is re-applied after each colored part.
function addon.Gray(text)
	local grayed = text:gsub("|r", "|r" .. addon.ColorText)

	return addon.ColorText .. grayed .. addon.ColorEnd
end

function addon.Highlight(text)
	return addon.ColorHighlight .. text .. addon.ColorEnd
end

-- 1234567 -> "1,234,567"
function addon.FormatNumber(number)
	local reversed = tostring(math.floor(number)):reverse():gsub("(%d%d%d)", "%1,")
	local formatted = reversed:reverse():gsub("^,", "")

	return formatted
end

function addon.Print(text)
	print(addon.ColorPrefix .. addonName .. ":" .. addon.ColorEnd .. " " .. addon.Gray(text))
end

function addon.PrintLine(text)
	print(addon.Gray(text))
end
