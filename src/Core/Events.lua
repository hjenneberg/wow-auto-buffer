local addonName, addon = ...

local EventFrame = CreateFrame("Frame")

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_LOGIN")
EventFrame:RegisterEvent("SPELLS_CHANGED")
EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

EventFrame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddon = ...

		if loadedAddon ~= addonName then
			return
		end

		AutoBufferCharDB = AutoBufferCharDB or {}
		addon.db = AutoBufferCharDB

		AutoBufferDB = AutoBufferDB or {}
		addon.accountDb = AutoBufferDB

		addon.Stats:Initialize(addon.db, addon.accountDb)
		addon.Achievements:Initialize(addon.accountDb)

		if addon.db.nameplates == nil then
			addon.db.nameplates = true
		end

		addon.Button:Create()
		addon.Button:RestorePosition()
		addon.Button:ApplyVisibility()

		return
	end

	if not addon.db then
		return
	end

	-- Spells are known at login, so achievements depending on them can be checked now
	if event == "PLAYER_LOGIN" then
		addon.Achievements:CheckAll(true)
	end

	-- Logged in, new spells learned or combat ended: pick a default buff if still missing
	if not InCombatLockdown() then
		addon.Buffs:PickDefault()
		addon.Button:ApplyVisibility()
	end
end)
