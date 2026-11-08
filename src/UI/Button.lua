local addonName, addon = ...

-- The secure button that casts the buff (by click or key binding)
local Button = {}
addon.Button = Button

local BUTTON_NAME = "AutoBufferButton"
local BUTTON_SIZE = 36
local DEFAULT_X = 0
local DEFAULT_Y = -150
local UPDATE_INTERVAL = 1

BINDING_HEADER_AUTOBUFFER = "AutoBuffer"
_G["BINDING_NAME_CLICK " .. BUTTON_NAME .. ":LeftButton"] = "Buff next player"

local frame
local timeSinceLastUpdate = 0
local lastCycle = 0
local lastMessage = 0
local lastUnit -- unit of the last cast set up by the button (used by the report)

-- WoW Forever does not let addons cast directly on nameplate units
-- (tested: player/target work, nameplateN does not). Other players are
-- therefore briefly targeted by full name, like a regular macro would.
local function ApplyCast(self, unit)
	local buffName = addon.Buffs:GetCurrent().name

	lastUnit = unit

	if unit:find("^nameplate") then
		local name = addon.Api.GetFullName(unit)

		self:SetAttribute("type", "macro")
		self:SetAttribute(
			"macrotext",
			"/targetexact " .. name .. "\n" .. "/cast [@target,help,nodead] " .. buffName .. "\n" .. "/targetlasttarget"
		)
	else
		self:SetAttribute("type", "spell")
		self:SetAttribute("spell", buffName)
		self:SetAttribute("unit", unit)
	end
end

-- Press and release both fire PreClick. Blizzard's template decides which
-- edge actually casts, so we set the target on both and only throttle
-- chat messages and buff cycling.
local function OnPreClick(self, mouseButton)
	-- In combat attributes can't be changed, the last target is kept
	if InCombatLockdown() then
		return
	end

	-- Shift + mouse on the button = move it, don't cast
	if IsShiftKeyDown() and self:IsMouseOver() then
		self:SetAttribute("type", nil)

		return
	end

	if mouseButton == "RightButton" then
		self:SetAttribute("type", nil)

		if GetTime() - lastCycle > 0.3 then
			lastCycle = GetTime()
			addon.Buffs:Cycle()
		end

		return
	end

	local buffName = addon.Buffs:GetCurrent().name

	if not buffName then
		self:SetAttribute("type", nil)
		addon.Print("No buff selected. Type /autobuff")

		return
	end

	local unit = addon.Scanner:FindNext()

	if unit then
		ApplyCast(self, unit)

		return
	end

	self:SetAttribute("type", nil)

	if GetTime() - lastMessage > 1 then
		lastMessage = GetTime()
		addon.Print("Everyone in range has " .. buffName .. ".")
	end
end

local function OnDragStart(self)
	if IsShiftKeyDown() and not InCombatLockdown() then
		self:StartMoving()
	end
end

local function OnDragStop(self)
	self:StopMovingOrSizing()

	local point, _, relativePoint, xOffset, yOffset = self:GetPoint()
	addon.db.pos = { point, relativePoint, xOffset, yOffset }
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(addonName)
	GameTooltip:AddLine(addon.Buffs:GetCurrent().name or "No buff selected", 1, 1, 1)
	GameTooltip:AddLine(addon.StatsView:GetSummary(), 1, 1, 1)
	GameTooltip:AddLine("Left-click: buff next player", 0.7, 0.7, 0.7)
	GameTooltip:AddLine("Right-click: change buff", 0.7, 0.7, 0.7)
	GameTooltip:AddLine("Shift + drag: move", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

local function OnLeave()
	GameTooltip:Hide()
end

-- Counter: how many players in range still need the buff
local function OnUpdate(self, elapsed)
	timeSinceLastUpdate = timeSinceLastUpdate + elapsed

	if timeSinceLastUpdate < UPDATE_INTERVAL then
		return
	end

	timeSinceLastUpdate = 0

	local _, count = addon.Scanner:FindNext()

	self.count:SetText(count > 0 and count or "")
	self.icon:SetDesaturated(count == 0)
end

function Button:Create()
	frame = CreateFrame("Button", BUTTON_NAME, UIParent, "SecureActionButtonTemplate")
	frame:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	frame:SetPoint("CENTER", DEFAULT_X, DEFAULT_Y)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForClicks("AnyUp", "AnyDown")
	frame:RegisterForDrag("LeftButton")
	frame:SetAttribute("type", "spell")

	frame.icon = frame:CreateTexture(nil, "ARTWORK")
	frame.icon:SetAllPoints()
	frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

	frame.count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
	frame.count:SetPoint("BOTTOMRIGHT", -2, 2)

	frame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

	frame:SetScript("PreClick", OnPreClick)
	frame:SetScript("OnDragStart", OnDragStart)
	frame:SetScript("OnDragStop", OnDragStop)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	frame:SetScript("OnUpdate", OnUpdate)
end

function Button:GetLastUnit()
	return lastUnit
end

function Button:SetSpell(name, icon)
	frame:SetAttribute("spell", name)
	frame.icon:SetTexture(icon)
end

function Button:ApplyVisibility()
	if InCombatLockdown() then
		return
	end

	-- Not Hide(), so the key binding and /click keep working
	frame:SetAlpha(addon.db.hidden and 0 or 1)
	frame:EnableMouse(not addon.db.hidden)
end

function Button:RestorePosition()
	local pos = addon.db.pos

	if not pos then
		return
	end

	frame:ClearAllPoints()
	frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
end

function Button:ResetPosition()
	if InCombatLockdown() then
		return
	end

	addon.db.pos = nil

	frame:ClearAllPoints()
	frame:SetPoint("CENTER", DEFAULT_X, DEFAULT_Y)
end
