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

	-- Logged in, new spells learned or combat ended: pick a default buff if still missing
	if not InCombatLockdown() then
		addon.Buffs:PickDefault()
		addon.Button:ApplyVisibility()
	end
end)
