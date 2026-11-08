local addonName, addon = ...

-- Tracks casts of the selected buff on friendly players and hands the
-- results to the statistics and the chat report
local pending = {} -- castGUID -> cast info, captured when the cast is sent

local function OnSent(target, castGUID, spellID)
	local spellName = addon.Api.GetSpellInfo(spellID)

	if not spellName or not addon.Buffs:GetCurrent().names[spellName] then
		return
	end

	-- Self-casts may come without a target name
	local who = target

	if not who or who == "" then
		who = addon.Api.GetFullName("player")
	end

	local unit = addon.Scanner:FindUnitByName(who, addon.Button:GetLastUnit())

	-- Only friendly players; NPCs and unidentified targets are not tracked
	if not unit or not UnitIsPlayer(unit) or not UnitCanAssist("player", unit) then
		return
	end

	-- Group mode off: yourself and your group/raid are not tracked either
	if not addon.db.group and addon.Api.IsOwnGroup(unit) then
		return
	end

	local _, class = UnitClass(unit)

	-- Class and level are read now, the unit may be gone when the cast finishes
	pending[castGUID] = {
		name = who,
		class = class,
		level = UnitLevel(unit),
		spell = spellName,
	}
end

local function OnFinished(event, castGUID)
	local cast = pending[castGUID]

	if not cast then
		return
	end

	pending[castGUID] = nil

	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		addon.Stats:RecordSuccess(cast)
		addon.Report:Success(cast)
	else
		addon.Stats:RecordFailure(cast)
		addon.Report:Failure(cast)
	end
end

local EventFrame = CreateFrame("Frame")

for _, event in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED" }) do
	pcall(EventFrame.RegisterUnitEvent, EventFrame, event, "player")
end

EventFrame:SetScript("OnEvent", function(_, event, _, ...)
	if not addon.db then
		return
	end

	local args = { ... }

	pcall(function()
		if event == "UNIT_SPELLCAST_SENT" then
			OnSent(args[1], args[2], args[3])
		else
			OnFinished(event, args[1])
		end
	end)
end)
