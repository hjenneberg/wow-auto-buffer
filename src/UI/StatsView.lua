local addonName, addon = ...

-- Builds the statistics for the chat and the window
local StatsView = {}
addon.StatsView = StatsView

local TOP_PLAYERS = 5
local TOP_ZONES = 5
local SEPARATOR = " · "

local function Value(text)
	return "|cFFFFFFFF" .. text .. addon.ColorEnd
end

local function Number(number)
	return Value(addon.FormatNumber(number))
end


local function Join(parts)
	return table.concat(parts, SEPARATOR)
end

local function FormatTime(timestamp)
	if not timestamp then
		return "-"
	end

	return Value(date("%Y-%m-%d %H:%M", timestamp))
end

local function SpellsText(stats)
	local parts = {}

	for _, entry in ipairs(addon.Stats.GetTop(stats.spells)) do
		parts[#parts + 1] = entry.key .. " " .. Number(entry.count)
	end

	return Join(parts)
end

local function PlayersText(stats)
	local parts = {}

	local top = addon.Stats.GetTop(stats.players, TOP_PLAYERS, function(player)
		return player.count
	end)

	for _, entry in ipairs(top) do
		parts[#parts + 1] = addon.Api.ColorByClass(entry.key, entry.value.class) .. " " .. Number(entry.count) .. "x"
	end

	return Join(parts)
end

local function ClassesText(stats)
	local parts = {}

	for _, entry in ipairs(addon.Stats.GetTop(stats.classes)) do
		local name = addon.Api.GetClassName(entry.key)
		parts[#parts + 1] = addon.Api.ColorByClass(name, entry.key) .. " " .. Number(entry.count)
	end

	return Join(parts)
end

-- Groups levels into steps of ten: 1-10, 11-20, ...
local function LevelsText(stats)
	local buckets = {}

	for level, count in pairs(stats.levels) do
		local from = math.floor((level - 1) / 10) * 10 + 1
		buckets[from] = (buckets[from] or 0) + count
	end

	local keys = {}

	for from in pairs(buckets) do
		keys[#keys + 1] = from
	end

	table.sort(keys)

	local parts = {}

	for _, from in ipairs(keys) do
		parts[#parts + 1] = from .. "-" .. (from + 9) .. " " .. Number(buckets[from])
	end

	return Join(parts)
end

local function ZonesText(stats)
	local parts = {}

	for _, entry in ipairs(addon.Stats.GetTop(stats.zones, TOP_ZONES)) do
		parts[#parts + 1] = entry.key .. " " .. Number(entry.count)
	end

	return Join(parts)
end

-- The statistics as rows of { label = ..., text = ... }, used by the chat and the window.
-- Returns the rows and a message for when nothing was recorded yet.
function StatsView:GetRows(scope)
	local Stats = addon.Stats
	local stats = Stats:Get(scope)
	local session = Stats:GetSession()
	local rows = {}

	local function Add(label, text)
		rows[#rows + 1] = { label = label, text = text }
	end

	local attempts = stats.total + stats.failed

	if attempts == 0 then
		return rows, "No buffs recorded yet."
	end

	Add(
		"Buffs",
		Join({
			Number(stats.total) .. " total",
			"today " .. Number(Stats:GetToday(stats)),
			"this session " .. Number(session.total),
		})
	)
	Add(
		"Success rate",
		Value(string.format("%.1f%%", stats.total / attempts * 100)) .. " (" .. Number(stats.failed) .. " failed)"
	)
	Add("Players", Number(stats.uniquePlayers) .. " different")

	if stats.total == 0 then
		return rows
	end

	Add("Spells", SpellsText(stats))
	Add("Top players", PlayersText(stats))
	Add("Classes", ClassesText(stats))

	if next(stats.levels) then
		Add("Levels", LevelsText(stats))
	end

	if next(stats.zones) then
		Add("Top zones", ZonesText(stats))
	end

	Add(
		"Days",
		Join({
			Number(Stats:GetActiveDays(stats)) .. " active",
			"streak " .. Number(Stats:GetCurrentStreak(stats)),
			"best streak " .. Number(Stats:GetBestStreak(stats)),
		})
	)

	if next(stats.hours) then
		local busiest = addon.Stats.GetTop(stats.hours, 1)[1]
		Add("Busiest hour", Value(string.format("%02d:00", busiest.key)) .. " (" .. Number(busiest.count) .. " buffs)")
	end

	Add(
		"Records",
		Join({
			Number(stats.bestMinute) .. " per minute",
			Number(stats.bestSession) .. " per session",
		})
	)
	Add("First buff", FormatTime(stats.firstTime))
	Add("Last buff", FormatTime(stats.lastTime))

	return rows
end

function StatsView:Print(scope)
	if scope == "account" then
		addon.Print("Statistics (all characters)")
	else
		addon.Print("Statistics (this character)")
	end

	local rows, message = self:GetRows(scope)

	if message then
		addon.PrintLine("   " .. message)

		return
	end

	for _, row in ipairs(rows) do
		addon.PrintLine("   " .. row.label .. ": " .. row.text)
	end
end

-- Short line for the button tooltip
function StatsView:GetSummary()
	local stats = addon.Stats:Get()
	local today = addon.FormatNumber(addon.Stats:GetToday(stats))
	local total = addon.FormatNumber(stats.total)

	return "Today: " .. today .. SEPARATOR .. "Total: " .. total
end
