local addonName, addon = ...

-- Wrappers that work with both the old and the new client API
local Api = {}
addon.Api = Api

local function Try(func, ...)
	if not func then
		return nil
	end

	local ok, result = pcall(func, ...)

	if ok then
		return result
	end
end

-- Returns name, icon and spell ID for a spell name or ID
function Api.GetSpellInfo(spell)
	if C_Spell and C_Spell.GetSpellInfo then
		local ok, info = pcall(C_Spell.GetSpellInfo, spell)

		if ok and info and info.name then
			return info.name, info.iconID, info.spellID
		end
	end

	if GetSpellInfo then
		local ok, name, _, icon, _, _, _, id = pcall(GetSpellInfo, spell)

		if ok and name then
			return name, icon, id
		end
	end
end

function Api.IsSpellKnown(id)
	return Try(C_SpellBook and C_SpellBook.IsSpellKnown, id)
		or Try(IsPlayerSpell, id)
		or Try(IsSpellKnown, id)
end

-- True if the unit has one of the buffs in names ({ [buffName] = true })
function Api.HasBuff(unit, names)
	local ok, result = pcall(function()
		for i = 1, 40 do
			local name

			if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
				local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")

				if not aura then
					return false
				end

				name = aura.name
			else
				name = UnitBuff(unit, i)

				if not name then
					return false
				end
			end

			if names[name] then
				return true
			end
		end

		return false
	end)

	-- Unreadable (e.g. restricted values)? Then treat it as buffed and skip the unit.
	if not ok then
		return true
	end

	return result
end

function Api.IsSpellInRange(spell, unit)
	if UnitIsUnit(unit, "player") then
		return true
	end

	local func = (C_Spell and C_Spell.IsSpellInRange) or IsSpellInRange

	if not func then
		return true
	end

	local ok, result = pcall(func, spell, unit)

	return ok and (result == true or result == 1)
end

function Api.IsInRaid()
	if IsInRaid then
		return IsInRaid()
	end

	return GetNumRaidMembers and GetNumRaidMembers() > 0
end

-- Yourself or a member of your group/raid
function Api.IsOwnGroup(unit)
	return UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit)
end

-- First and last name (Forever players have both; UnitName may return only
-- the first name). The longest name any API returns wins.
function Api.GetFullName(unit)
	local best = ""

	local function Consider(func, ...)
		if not func then
			return
		end

		local results = { pcall(func, ...) }

		if not results[1] then
			return
		end

		for i = 2, #results do
			local value = results[i]
			local ok, isLonger = pcall(function()
				return type(value) == "string" and #value > #best
			end)

			if ok and isLonger then
				best = value
			end
		end
	end

	Consider(UnitName, unit)
	Consider(GetUnitName, unit, true)
	Consider(UnitFullName, unit)

	if best == "" then
		return "?"
	end

	return best
end

-- Localized class name for a class token like "PRIEST"
function Api.GetClassName(class)
	local names = LOCALIZED_CLASS_NAMES_MALE

	return (names and names[class]) or class
end

-- Wraps the text in the color of the class token (white if unknown)
function Api.ColorByClass(name, class)
	local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	local color = class and colors and colors[class]

	if not color then
		return "|cFFFFFFFF" .. name .. "|r"
	end

	return string.format(
		"|cFF%02X%02X%02X%s|r",
		math.floor(color.r * 255),
		math.floor(color.g * 255),
		math.floor(color.b * 255),
		name
	)
end
