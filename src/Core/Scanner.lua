local addonName, addon = ...

-- Finds players who are missing the selected buff
local Scanner = {}
addon.Scanner = Scanner

-- Players a buff failed on (out of sight, stronger buff, ...) are skipped for a
-- while, so the next click picks someone else instead of failing again
local SKIP_SECONDS = 60
local skipped = {} -- GUID -> GetTime() until which the player is skipped

Scanner.SKIP_SECONDS = SKIP_SECONDS

local function IsSkipped(guid)
	local skipUntil = skipped[guid]

	if not skipUntil then
		return false
	end

	if GetTime() >= skipUntil then
		skipped[guid] = nil

		return false
	end

	return true
end

function Scanner:Skip(guid)
	if guid then
		skipped[guid] = GetTime() + SKIP_SECONDS
	end
end

local function GetGroupUnits()
	local list = {}

	if addon.Api.IsInRaid() then
		for i = 1, 40 do
			list[#list + 1] = "raid" .. i
		end
	else
		for i = 1, 4 do
			list[#list + 1] = "party" .. i
		end
	end

	return list
end

local function GetCandidates()
	local list = {}

	if addon.db.group then
		list[1] = "player"

		for _, unit in ipairs(GetGroupUnits()) do
			list[#list + 1] = unit
		end
	end

	if addon.db.nameplates then
		for i = 1, 40 do
			list[#list + 1] = "nameplate" .. i
		end
	end

	return list
end

local function NeedsBuff(unit, seen, buff)
	if not UnitExists(unit) or not UnitIsPlayer(unit) then
		return false
	end

	local guid = UnitGUID(unit)

	if not guid or seen[guid] then
		return false
	end

	seen[guid] = true

	if IsSkipped(guid) then
		return false
	end

	if not UnitCanAssist("player", unit) then
		return false
	end

	-- Group mode off: skip yourself and group/raid members (they can show up as nameplates too)
	if not addon.db.group and addon.Api.IsOwnGroup(unit) then
		return false
	end

	if UnitIsDeadOrGhost(unit) or not UnitIsConnected(unit) then
		return false
	end

	if not addon.Api.IsSpellInRange(buff.name, unit) then
		return false
	end

	return not addon.Api.HasBuff(unit, buff.names)
end

-- Returns the first matching unit and the number of all matching units
function Scanner:FindNext()
	local buff = addon.Buffs:GetCurrent()

	if not buff.name then
		return nil, 0
	end

	local first, count, seen = nil, 0, {}

	for _, unit in ipairs(GetCandidates()) do
		local ok, needsBuff = pcall(NeedsBuff, unit, seen, buff)

		if ok and needsBuff then
			count = count + 1
			first = first or unit
		end
	end

	return first, count
end

-- Finds a unit token for a player name (cast events only give the name)
function Scanner:FindUnitByName(name, preferredUnit)
	local units = {}

	if preferredUnit then
		units[1] = preferredUnit
	end

	for _, unit in ipairs({ "target", "mouseover", "player" }) do
		units[#units + 1] = unit
	end

	for i = 1, 40 do
		units[#units + 1] = "raid" .. i
	end

	for i = 1, 4 do
		units[#units + 1] = "party" .. i
	end

	for i = 1, 40 do
		units[#units + 1] = "nameplate" .. i
	end

	for _, unit in ipairs(units) do
		local ok, isMatch = pcall(function()
			return UnitExists(unit) and (addon.Api.GetFullName(unit) == name or UnitName(unit) == name)
		end)

		if ok and isMatch then
			return unit
		end
	end
end
