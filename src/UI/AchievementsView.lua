local addonName, addon = ...

-- Prints the achievements to the chat
local AchievementsView = {}
addon.AchievementsView = AchievementsView

local COLOR_UNLOCKED = "|cFF40FF40"
local SEPARATOR = " · "

local function Unlocked(text)
	return COLOR_UNLOCKED .. text .. addon.ColorEnd
end

local function Progress(achievement)
	local current, goal = addon.Achievements:GetProgress(achievement)

	return addon.FormatNumber(current) .. "/" .. addon.FormatNumber(goal)
end

local function GetByCategory(category)
	local list = {}

	for _, achievement in ipairs(addon.AchievementList) do
		if achievement.category == category then
			list[#list + 1] = achievement
		end
	end

	return list
end

local function PrintHeader()
	local Achievements = addon.Achievements

	addon.Print(
		"Achievements: "
			.. Unlocked(Achievements:CountUnlocked())
			.. "/"
			.. #addon.AchievementList
			.. " unlocked (all characters)"
	)
end

-- One line per category: unlocked achievements, then the next one with its progress
function AchievementsView:PrintSummary()
	PrintHeader()

	for _, category in ipairs(addon.AchievementList.CATEGORIES) do
		local parts = {}

		for _, achievement in ipairs(GetByCategory(category)) do
			if addon.Achievements:IsUnlocked(achievement) then
				parts[#parts + 1] = Unlocked(achievement.name)
			else
				parts[#parts + 1] = "next: " .. addon.Highlight(achievement.name) .. " (" .. Progress(achievement) .. ")"

				break
			end
		end

		addon.PrintLine("   " .. category .. ": " .. table.concat(parts, SEPARATOR))
	end

	addon.PrintLine("   Type /autobuff achievements all for the full list.")
end

-- Every achievement with description, unlock date or progress
function AchievementsView:PrintAll()
	PrintHeader()

	for _, category in ipairs(addon.AchievementList.CATEGORIES) do
		addon.PrintLine(addon.Highlight(category))

		for _, achievement in ipairs(GetByCategory(category)) do
			local status

			if addon.Achievements:IsUnlocked(achievement) then
				status = Unlocked(date("%Y-%m-%d", addon.Achievements:GetUnlockTime(achievement)))
			else
				status = Progress(achievement)
			end

			addon.PrintLine("   " .. achievement.name .. " - " .. achievement.description .. SEPARATOR .. status)
		end
	end
end

-- Short line for the button tooltip
function AchievementsView:GetSummary()
	return "Achievements: " .. addon.Achievements:CountUnlocked() .. "/" .. #addon.AchievementList
end
