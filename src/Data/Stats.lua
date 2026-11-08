local addonName, addon = ...

-- Statistics of successful buffs, saved per character and account-wide
local Stats = {}
addon.Stats = Stats

local DAY = 86400
local MINUTE = 60

-- The current login session (not saved)
local session = {
	total = 0,
	failed = 0,
	recent = {}, -- GetTime() of each buff within the last minute
}

-- Fills in missing fields, so older saved data keeps working
local function Ensure(stats)
	stats = stats or {}

	stats.total = stats.total or 0
	stats.failed = stats.failed or 0
	stats.uniquePlayers = stats.uniquePlayers or 0
	stats.bestMinute = stats.bestMinute or 0
	stats.bestSession = stats.bestSession or 0
	stats.spells = stats.spells or {} -- spell name -> count
	stats.players = stats.players or {} -- full name -> { count, class }
	stats.classes = stats.classes or {} -- class token -> count
	stats.levels = stats.levels or {} -- player level -> count
	stats.zones = stats.zones or {} -- zone name -> count
	stats.days = stats.days or {} -- "YYYY-MM-DD" -> count
	stats.hours = stats.hours or {} -- hour of the day (0-23) -> count

	return stats
end

local function Increment(counts, key)
	counts[key] = (counts[key] or 0) + 1
end

local function DayKey(timestamp)
	return date("%Y-%m-%d", timestamp)
end

-- Noon of the given day, so steps of one day stay on the right date despite DST
local function DayNoon(key)
	local year, month, day = key:match("^(%d+)-(%d+)-(%d+)$")

	return time({ year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 12 })
end

local function GetZone()
	if GetRealZoneText then
		return GetRealZoneText()
	end

	return GetZoneText()
end

local function Add(stats, cast, zone, today, now, buffsLastMinute)
	stats.total = stats.total + 1
	stats.firstTime = stats.firstTime or now
	stats.lastTime = now

	Increment(stats.spells, cast.spell)

	local player = stats.players[cast.name]

	if not player then
		player = { count = 0 }
		stats.players[cast.name] = player
		stats.uniquePlayers = stats.uniquePlayers + 1
	end

	player.count = player.count + 1
	player.class = cast.class or player.class

	if cast.class then
		Increment(stats.classes, cast.class)
	end

	-- Level is -1 or 0 when the game hides it (e.g. much higher level)
	if cast.level and cast.level > 0 then
		Increment(stats.levels, cast.level)
	end

	if zone and zone ~= "" then
		Increment(stats.zones, zone)
	end

	Increment(stats.days, today)
	Increment(stats.hours, tonumber(date("%H", now)))

	stats.bestMinute = math.max(stats.bestMinute, buffsLastMinute)
	stats.bestSession = math.max(stats.bestSession, session.total)
end

function Stats:Initialize(characterDb, accountDb)
	self.characterDb = characterDb
	self.accountDb = accountDb

	characterDb.stats = Ensure(characterDb.stats)
	accountDb.stats = Ensure(accountDb.stats)
end

-- scope: "account" or nil for the current character
function Stats:Get(scope)
	if scope == "account" then
		return self.accountDb.stats
	end

	return self.characterDb.stats
end

function Stats:GetSession()
	return session
end

function Stats:RecordSuccess(cast)
	local now = time()
	local clock = GetTime()

	session.total = session.total + 1

	local recent = {}

	for _, timestamp in ipairs(session.recent) do
		if clock - timestamp < MINUTE then
			recent[#recent + 1] = timestamp
		end
	end

	recent[#recent + 1] = clock
	session.recent = recent

	local zone = GetZone()
	local today = DayKey(now)

	Add(self:Get(), cast, zone, today, now, #recent)
	Add(self:Get("account"), cast, zone, today, now, #recent)
end

function Stats:RecordFailure()
	session.failed = session.failed + 1

	self:Get().failed = self:Get().failed + 1
	self:Get("account").failed = self:Get("account").failed + 1
end

-- Deletes the statistics of the current character (the account totals stay)
function Stats:ResetCharacter()
	self.characterDb.stats = Ensure(nil)
end

function Stats:GetToday(stats)
	return stats.days[DayKey(time())] or 0
end

function Stats:GetActiveDays(stats)
	local count = 0

	for _ in pairs(stats.days) do
		count = count + 1
	end

	return count
end

-- Consecutive days up to today (or up to yesterday, if there was no buff today yet)
function Stats:GetCurrentStreak(stats)
	local day = DayNoon(DayKey(time()))

	if not stats.days[DayKey(day)] then
		day = day - DAY
	end

	local streak = 0

	while stats.days[DayKey(day)] do
		streak = streak + 1
		day = day - DAY
	end

	return streak
end

function Stats:GetBestStreak(stats)
	local keys = {}

	for key in pairs(stats.days) do
		keys[#keys + 1] = key
	end

	table.sort(keys)

	local best, run, previous = 0, 0, nil

	for _, key in ipairs(keys) do
		local noon = DayNoon(key)

		-- One day apart; the tolerance covers DST changes
		if previous and math.abs(noon - previous - DAY) < 7200 then
			run = run + 1
		else
			run = 1
		end

		best = math.max(best, run)
		previous = noon
	end

	return best
end

-- The largest entries of a { key = count } table as { { key = ..., count = ... }, ... }.
-- getCount reads the count from table values that are not plain numbers.
function Stats.GetTop(counts, limit, getCount)
	local list = {}

	for key, value in pairs(counts) do
		list[#list + 1] = { key = key, value = value, count = getCount and getCount(value) or value }
	end

	table.sort(list, function(a, b)
		if a.count == b.count then
			return tostring(a.key) < tostring(b.key)
		end

		return a.count > b.count
	end)

	if limit then
		for i = #list, limit + 1, -1 do
			list[i] = nil
		end
	end

	return list
end
