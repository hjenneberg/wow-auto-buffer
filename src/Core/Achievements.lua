local addonName, addon = ...

-- Unlocks achievements (account-wide) and announces them
local Achievements = {}
addon.Achievements = Achievements

addon.ColorAchievement = "|cFFFFD100"

local UNLOCK_SOUND = 888 -- level up sound

function Achievements:Initialize(accountDb)
	accountDb.achievements = accountDb.achievements or {} -- id -> unlock time
	self.unlocked = accountDb.achievements
end

function Achievements:IsUnlocked(achievement)
	return self.unlocked[achievement.id] ~= nil
end

function Achievements:GetUnlockTime(achievement)
	return self.unlocked[achievement.id]
end

-- Returns current value (capped at the goal) and goal
function Achievements:GetProgress(achievement)
	local goal = achievement.goal

	if type(goal) == "function" then
		goal = goal()
	end

	local current = achievement.progress(addon.Stats:Get("account")) or 0

	return math.min(current, goal), goal
end

function Achievements:CountUnlocked()
	local count = 0

	for _, achievement in ipairs(addon.AchievementList) do
		if self:IsUnlocked(achievement) then
			count = count + 1
		end
	end

	return count
end

local function Announce(achievement)
	addon.Print(
		"Achievement unlocked: "
			.. addon.ColorAchievement
			.. achievement.name
			.. addon.ColorEnd
			.. " - "
			.. achievement.description
	)

	pcall(PlaySound, UNLOCK_SOUND)
end

-- Unlocks every achievement whose goal is reached.
-- silent: no announcement per achievement, only a summary (used at login).
function Achievements:CheckAll(silent)
	local unlockedNow = {}

	for _, achievement in ipairs(addon.AchievementList) do
		if not self:IsUnlocked(achievement) then
			local ok, current, goal = pcall(self.GetProgress, self, achievement)

			if ok and goal > 0 and current >= goal then
				self.unlocked[achievement.id] = time()
				unlockedNow[#unlockedNow + 1] = achievement
			end
		end
	end

	if #unlockedNow == 0 then
		return
	end

	if silent then
		addon.Print(
			#unlockedNow .. " achievements unlocked by your existing statistics. Type /autobuff achievements"
		)

		return
	end

	for _, achievement in ipairs(unlockedNow) do
		Announce(achievement)
	end
end
