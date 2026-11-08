local addonName, addon = ...

-- All achievements. They are checked against the account-wide statistics.
--
-- id          = saved key, never change it
-- category    = one of CATEGORIES
-- goal        = number to reach (or a function returning it)
-- progress    = function(stats) returning the current value
local AchievementList = {}
addon.AchievementList = AchievementList

AchievementList.CATEGORIES = { "Buffs", "Players", "Loyalty", "Classes", "Zones", "Speed", "Streaks", "Special" }

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local NEWBIE_LEVEL = 10 -- players below this level count as newbies
local NIGHT_END_HOUR = 4 -- night lasts from midnight until this hour

local function Total(stats)
	return stats.total
end

local function UniquePlayers(stats)
	return stats.uniquePlayers
end

local function MostBuffedPlayer(stats)
	local best = 0

	for _, player in pairs(stats.players) do
		best = math.max(best, player.count)
	end

	return best
end

local function ClassesBuffed(stats)
	local count = 0

	for _, class in ipairs(CLASSES) do
		if stats.classes[class] then
			count = count + 1
		end
	end

	return count
end

local function Zones(stats)
	local count = 0

	for _ in pairs(stats.zones) do
		count = count + 1
	end

	return count
end

local function BestMinute(stats)
	return stats.bestMinute
end

local function BestSession(stats)
	return stats.bestSession
end

local function BestStreak(stats)
	return addon.Stats:GetBestStreak(stats)
end

local function NewbieBuffs(stats)
	local count = 0

	for level = 1, NEWBIE_LEVEL - 1 do
		count = count + (stats.levels[level] or 0)
	end

	return count
end

local function NightBuffs(stats)
	local count = 0

	for hour = 0, NIGHT_END_HOUR - 1 do
		count = count + (stats.hours[hour] or 0)
	end

	return count
end

-- Buffs of your class you know and have cast at least once
local function KnownBuffsCast(stats)
	local count = 0

	for _, preset in ipairs(addon.Presets:GetAvailable()) do
		local name = addon.Api.GetSpellInfo(preset.cast)

		if name and stats.spells[name] then
			count = count + 1
		end
	end

	return count
end

-- At least two, so classes with a single buff (or none) don't get it for free
local function KnownBuffsGoal()
	return math.max(2, #addon.Presets:GetAvailable())
end

local function Add(id, category, name, description, goal, progress)
	AchievementList[#AchievementList + 1] = {
		id = id,
		category = category,
		name = name,
		description = description,
		goal = goal,
		progress = progress,
	}
end

Add("buffs_1", "Buffs", "First Blessing", "Buff a player for the first time", 1, Total)
Add("buffs_10", "Buffs", "Helping Hand", "Buff 10 players", 10, Total)
Add("buffs_100", "Buffs", "Friend of the People", "Buff 100 players", 100, Total)
Add("buffs_500", "Buffs", "Walking Buff Station", "Buff 500 players", 500, Total)
Add("buffs_1000", "Buffs", "Benefactor", "Buff 1,000 players", 1000, Total)
Add("buffs_5000", "Buffs", "Patron Saint", "Buff 5,000 players", 5000, Total)
Add("buffs_10000", "Buffs", "Living Legend", "Buff 10,000 players", 10000, Total)

Add("players_10", "Players", "Making Friends", "Buff 10 different players", 10, UniquePlayers)
Add("players_50", "Players", "Social Butterfly", "Buff 50 different players", 50, UniquePlayers)
Add("players_100", "Players", "Known Face", "Buff 100 different players", 100, UniquePlayers)
Add("players_500", "Players", "Town Favorite", "Buff 500 different players", 500, UniquePlayers)
Add("players_1000", "Players", "Everyone's Buddy", "Buff 1,000 different players", 1000, UniquePlayers)

Add("loyal_10", "Loyalty", "Regular Customer", "Buff the same player 10 times", 10, MostBuffedPlayer)
Add("loyal_25", "Loyalty", "Personal Buffer", "Buff the same player 25 times", 25, MostBuffedPlayer)

Add("classes_all", "Classes", "Equal Treatment", "Buff a player of every class", #CLASSES, ClassesBuffed)

Add("zones_10", "Zones", "Traveler", "Buff players in 10 different zones", 10, Zones)
Add("zones_25", "Zones", "Globetrotter", "Buff players in 25 different zones", 25, Zones)

Add("speed_10", "Speed", "Quick Hands", "Buff 10 players within one minute", 10, BestMinute)
Add("speed_20", "Speed", "Buff Storm", "Buff 20 players within one minute", 20, BestMinute)
Add("session_100", "Speed", "Marathon", "Buff 100 players in one session", 100, BestSession)

Add("streak_7", "Streaks", "Creature of Habit", "Buff players on 7 days in a row", 7, BestStreak)
Add("streak_30", "Streaks", "Unstoppable", "Buff players on 30 days in a row", 30, BestStreak)

Add("newbies_50", "Special", "Mentor", "Buff players below level " .. NEWBIE_LEVEL .. " 50 times", 50, NewbieBuffs)
Add("night_owl", "Special", "Night Owl", "Buff a player between midnight and 4 a.m.", 1, NightBuffs)
Add(
	"all_buffs",
	"Special",
	"Allrounder",
	"Cast every buff of your class you know at least once",
	KnownBuffsGoal,
	KnownBuffsCast
)
