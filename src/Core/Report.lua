local addonName, addon = ...

-- Report mode: prints who got which buff
local pending = {} -- castGUID -> colored target name, for casts of the selected buff

local function OnSent(target, castGUID, spellID)
	local name = addon.Api.GetSpellInfo(spellID)

	if not name or not addon.Buffs:GetCurrent().names[name] then
		return
	end

	-- Self-casts may come without a target name
	local who = target

	if not who or who == "" then
		who = addon.Api.GetFullName("player")
	end

	local unit = addon.Scanner:FindUnitByName(who, addon.Button:GetLastUnit())

	-- Only friendly players; NPCs and unidentified targets are not reported
	if not unit or not UnitIsPlayer(unit) or not UnitCanAssist("player", unit) then
		return
	end

	-- Group mode off: yourself and your group/raid are not reported either
	if not addon.db.group and addon.Api.IsOwnGroup(unit) then
		return
	end

	pending[castGUID] = addon.Api.ColorByClass(who, unit)
end

local function OnFinished(event, castGUID, spellID)
	local target = pending[castGUID]

	if not target then
		return
	end

	pending[castGUID] = nil

	local name = addon.Api.GetSpellInfo(spellID) or "?"

	if event == "UNIT_SPELLCAST_SUCCEEDED" then
		addon.Print("Buffed " .. target .. " with " .. addon.Highlight(name))
	else
		addon.Print(addon.ColorError .. "Failed" .. addon.ColorEnd .. ": " .. name .. " on " .. target)
	end
end

local EventFrame = CreateFrame("Frame")

for _, event in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED" }) do
	pcall(EventFrame.RegisterUnitEvent, EventFrame, event, "player")
end

EventFrame:SetScript("OnEvent", function(_, event, _, ...)
	if not (addon.db and addon.db.report) then
		return
	end

	local args = { ... }

	pcall(function()
		if event == "UNIT_SPELLCAST_SENT" then
			OnSent(args[1], args[2], args[3])
		else
			OnFinished(event, args[1], args[2])
		end
	end)
end)
