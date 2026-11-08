local addonName, addon = ...

local Presets = {}
addon.Presets = Presets

-- cast   = spell to cast (rank 1 ID; casting by name always uses the highest rank)
-- covers = other buffs that count as "already has it" (e.g. the group version)
local PRESETS_BY_CLASS = {
	PRIEST = {
		{ cast = 1243, covers = { 21562 } }, -- Power Word: Fortitude / Prayer of Fortitude
		{ cast = 14752, covers = { 27681 } }, -- Divine Spirit / Prayer of Spirit
		{ cast = 976, covers = { 27683 } }, -- Shadow Protection / Prayer of Shadow Protection
	},
	MAGE = {
		{ cast = 1459, covers = { 23028 } }, -- Arcane Intellect / Arcane Brilliance
		{ cast = 1008, covers = {} }, -- Amplify Magic
		{ cast = 604, covers = {} }, -- Dampen Magic
	},
	DRUID = {
		{ cast = 1126, covers = { 21849 } }, -- Mark of the Wild / Gift of the Wild
		{ cast = 467, covers = {} }, -- Thorns
	},
	PALADIN = {
		{ cast = 19740, covers = { 25782 } }, -- Blessing of Might
		{ cast = 19742, covers = { 25894 } }, -- Blessing of Wisdom
		{ cast = 20217, covers = { 25898 } }, -- Blessing of Kings
		{ cast = 1038, covers = { 25895 } }, -- Blessing of Salvation
		{ cast = 19977, covers = { 25890 } }, -- Blessing of Light
		{ cast = 20911, covers = { 25899 } }, -- Blessing of Sanctuary
	},
	WARLOCK = {
		{ cast = 5697, covers = {} }, -- Unending Breath
	},
	SHAMAN = {
		{ cast = 131, covers = {} }, -- Water Breathing
	},
}

-- Presets of the player's class that the character already knows
function Presets:GetAvailable()
	local _, class = UnitClass("player")
	local list = {}

	for _, preset in ipairs(PRESETS_BY_CLASS[class] or {}) do
		if addon.Api.IsSpellKnown(preset.cast) and addon.Api.GetSpellInfo(preset.cast) then
			list[#list + 1] = preset
		end
	end

	return list
end
