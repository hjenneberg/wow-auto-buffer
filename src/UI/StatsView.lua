local addonName, addon = ...

-- Prints the statistics to the chat
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

local function Line(label, text)
	addon.PrintLine("   " .. label .. ": " .. text)
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

function StatsView:Print(scope)
	local Stats = addon.Stats
	local stats = Stats:Get(scope)
	local session = Stats:GetSession()

	if scope == "account" then
		addon.Print("Statistics (all characters)")
	else
		addon.Print("Statistics (this character)")
	end

	local attempts = stats.total + stats.failed

	if attempts == 0 then
		addon.PrintLine("   No buffs recorded yet.")

		return
	end

	Line(
		"Buffs",
		Join({
			Number(stats.total) .. " total",
			"today " .. Number(Stats:GetToday(stats)),
			"this session " .. Number(session.total),
		})
	)
	Line(
		"Success rate",
		Value(string.format("%.1f%%", stats.total / attempts * 100)) .. " (" .. Number(stats.failed) .. " failed)"
	)
	Line("Players", Number(stats.uniquePlayers) .. " different")

	if stats.total == 0 then
		return
	end

	Line("Spells", SpellsText(stats))
	Line("Top players", PlayersText(stats))
	Line("Classes", ClassesText(stats))

	if next(stats.levels) then
		Line("Levels", LevelsText(stats))
	end

	if next(stats.zones) then
		Line("Top zones", ZonesText(stats))
	end

	Line(
		"Days",
		Join({
			Number(Stats:GetActiveDays(stats)) .. " active",
			"streak " .. Number(Stats:GetCurrentStreak(stats)),
			"best streak " .. Number(Stats:GetBestStreak(stats)),
		})
	)
	if next(stats.hours) then
		local busiest = addon.Stats.GetTop(stats.hours, 1)[1]
		Line("Busiest hour", Value(string.format("%02d:00", busiest.key)) .. " (" .. Number(busiest.count) .. " buffs)")
	end

	Line(
		"Records",
		Join({
			Number(stats.bestMinute) .. " per minute",
			Number(stats.bestSession) .. " per session",
		})
	)
	Line("First buff", FormatTime(stats.firstTime) .. SEPARATOR .. "last buff " .. FormatTime(stats.lastTime))
end

-- Short line for the button tooltip
function StatsView:GetSummary()
	local stats = addon.Stats:Get()
	local today = addon.FormatNumber(addon.Stats:GetToday(stats))
	local total = addon.FormatNumber(stats.total)

	return "Today: " .. today .. SEPARATOR .. "Total: " .. total
end
