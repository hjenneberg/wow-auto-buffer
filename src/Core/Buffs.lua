local addonName, addon = ...

-- The currently selected buff
local Buffs = {}
addon.Buffs = Buffs

local current = {
	name = nil,
	icon = nil,
	names = {}, -- all buff names that count as "already has it"
}

function Buffs:GetCurrent()
	return current
end

function Buffs:Set(spell, covers, silent)
	if InCombatLockdown() then
		addon.Print("Can't change the buff while in combat.")

		return false
	end

	local name, icon = addon.Api.GetSpellInfo(spell)

	if not name then
		addon.Print("Spell not found: " .. tostring(spell))

		return false
	end

	current.name = name
	current.icon = icon
	current.names = { [name] = true }

	for _, id in ipairs(covers or {}) do
		local coverName = addon.Api.GetSpellInfo(id)

		if coverName then
			current.names[coverName] = true
		end
	end

	addon.db.spell = spell
	addon.db.covers = covers or {}

	addon.Button:SetSpell(name, icon)

	if not silent then
		addon.Print("Selected: " .. addon.Highlight(name))
	end

	return true
end

-- Switches to the next available preset of the player's class
function Buffs:Cycle()
	local list = addon.Presets:GetAvailable()

	if #list == 0 then
		return
	end

	local index = 0

	for i, preset in ipairs(list) do
		if addon.Api.GetSpellInfo(preset.cast) == current.name then
			index = i
		end
	end

	local preset = list[index % #list + 1]

	self:Set(preset.cast, preset.covers)
end

-- Restores the saved buff, or picks the first available preset
function Buffs:PickDefault()
	if current.name then
		return
	end

	if addon.db.spell and self:Set(addon.db.spell, addon.db.covers, true) then
		return
	end

	local preset = addon.Presets:GetAvailable()[1]

	if preset then
		self:Set(preset.cast, preset.covers, true)
	end
end
