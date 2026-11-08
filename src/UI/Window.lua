local addonName, addon = ...

-- Window with tabs for statistics and achievements
local Window = {}
addon.Window = Window

local WINDOW_NAME = "AutoBufferWindow"
local WIDTH = 500
local HEIGHT = 520
local CONTENT_TOP = -96
local CONTENT_WIDTH = WIDTH - 60
local LABEL_WIDTH = 100
local ROW_SPACING = 8
local ACHIEVEMENT_HEIGHT = 44
local CATEGORY_HEIGHT = 26
local BAR_WIDTH = 120
local DEFAULT_ICON = "Interface\\Icons\\Spell_Holy_WordFortitude"
local ICON_UNLOCKED = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ICON_LOCKED = "Interface\\RaidFrame\\ReadyCheck-Waiting"

local TAB_STATISTICS = 1
local TAB_ACHIEVEMENTS = 2

local win
local tabs = {}
local pages = {}
local scopeButtons = {}
local selectedTab = TAB_STATISTICS
local statsScope -- nil = this character, "account" = all characters

local function PlayTabSound()
	pcall(PlaySound, SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB or 841)
end

-- Tries the Blizzard frame templates the client knows, falls back to a plain frame
local function CreateWindowFrame()
	local frame

	for _, template in ipairs({ "ButtonFrameTemplate", "PortraitFrameTemplate", "BasicFrameTemplateWithInset" }) do
		local ok, created = pcall(CreateFrame, "Frame", WINDOW_NAME, UIParent, template)

		if ok and created then
			frame = created

			break
		end
	end

	if not frame then
		frame = CreateFrame("Frame", WINDOW_NAME, UIParent, "BackdropTemplate")
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 14,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		frame:SetBackdropColor(0.08, 0.07, 0.06, 0.97)
		frame:SetBackdropBorderColor(0.48, 0.40, 0.27, 1)
	end

	-- Prefer the close button of the template, otherwise create one
	local close = frame.CloseButton
		or frame.closeButton
		or (frame.TitleContainer and frame.TitleContainer.CloseButton)
		or (frame.BorderBox and frame.BorderBox.CloseButton)

	if not close then
		close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
		close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
	end

	-- A plain Hide() also works in combat (HideUIPanel does not)
	close:SetScript("OnClick", function()
		frame:Hide()
	end)

	local title = frame.TitleText or (frame.TitleContainer and frame.TitleContainer.TitleText)

	if not title then
		title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title:SetPoint("TOP", 0, -6)
	end

	title:SetText(addonName)

	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()

		local point, _, relativePoint, xOffset, yOffset = self:GetPoint()
		addon.db.windowPos = { point, relativePoint, xOffset, yOffset }
	end)

	local pos = addon.db.windowPos

	if pos then
		frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end

	-- Close with Escape
	if UISpecialFrames then
		tinsert(UISpecialFrames, WINDOW_NAME)
	end

	return frame
end

-- Shows the icon of the selected buff in the round portrait of the frame template.
-- SetPortraitToTexture leaves it empty on Forever, so the icon is set directly and
-- cut to a circle with a mask (as WhatsTraining does).
local function UpdatePortrait()
	local container = win.PortraitContainer
	local portrait = win.portrait or (container and container.portrait)

	if not portrait then
		return
	end

	portrait:SetTexture(addon.Buffs:GetCurrent().icon or DEFAULT_ICON)

	if portrait.autoBufferMask or not portrait.AddMaskTexture then
		return
	end

	local ok, mask = pcall(portrait:GetParent().CreateMaskTexture, portrait:GetParent())

	if not ok or not mask then
		return
	end

	mask:SetAllPoints((container and container.CircleMask) or portrait)
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
	portrait:AddMaskTexture(mask)
	portrait.autoBufferMask = mask
end

local function CreateTab(index, text)
	local name = WINDOW_NAME .. "Tab" .. index
	local ok, tab = pcall(CreateFrame, "Button", name, win, "CharacterFrameTabButtonTemplate")

	if not ok or not tab then
		tab = CreateFrame("Button", name, win, "UIPanelButtonTemplate")
		tab:SetSize(120, 24)
		tab.isFallback = true
	end

	tab:SetID(index)
	tab:SetText(text)

	if tab.isFallback then
		if index == 1 then
			tab:SetPoint("TOPLEFT", win, "BOTTOMLEFT", 12, -2)
		else
			tab:SetPoint("LEFT", tabs[index - 1], "RIGHT", 4, 0)
		end
	else
		pcall(PanelTemplates_TabResize, tab, 0)

		if index == 1 then
			tab:SetPoint("TOPLEFT", win, "BOTTOMLEFT", 12, 2)
		else
			tab:SetPoint("LEFT", tabs[index - 1], "RIGHT", -16, 0)
		end
	end

	tab:SetScript("OnClick", function()
		PlayTabSound()
		Window:SelectTab(index)
	end)

	tabs[index] = tab
end

local function CreatePage()
	local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", win, "TOPLEFT", 18, CONTENT_TOP)
	scroll:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -36, 28)

	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(CONTENT_WIDTH, 1)
	scroll:SetScrollChild(content)

	scroll.content = content
	content.strings = {}
	content.rows = {}

	return scroll
end

-- Reuses font strings between refreshes instead of creating new ones every time
local function GetString(content, index, fontObject)
	local fontString = content.strings[index]

	if not fontString then
		fontString = content:CreateFontString(nil, "OVERLAY")
		fontString:SetJustifyH("LEFT")
		fontString:SetJustifyV("TOP")
		content.strings[index] = fontString
	end

	fontString:SetFontObject(fontObject)
	fontString:ClearAllPoints()
	fontString:SetWidth(0)
	fontString:Show()

	return fontString
end

local function HideUnused(list, used)
	for i = used + 1, #list do
		list[i]:Hide()
	end
end

-- A heading (e.g. "Statistics (this character)") at the top of a page
local function SetHeading(content, index, text, y)
	local heading = GetString(content, index, "GameFontNormalLarge")
	heading:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
	heading:SetText(text)

	return y - heading:GetStringHeight() - ROW_SPACING * 2
end

local function RenderStatistics()
	local content = pages[TAB_STATISTICS].content
	local rows, message = addon.StatsView:GetRows(statsScope)
	local used = 0
	local y = 0

	used = used + 1

	if statsScope == "account" then
		y = SetHeading(content, used, "Statistics (all characters)", y)
	else
		y = SetHeading(content, used, "Statistics (this character)", y)
	end

	if message then
		used = used + 1
		local text = GetString(content, used, "GameFontHighlight")
		text:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
		text:SetText(message)
		y = y - text:GetStringHeight()
	end

	for _, row in ipairs(rows) do
		used = used + 1
		local label = GetString(content, used, "GameFontNormal")
		label:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
		label:SetWidth(LABEL_WIDTH)
		label:SetText(row.label)

		used = used + 1
		local value = GetString(content, used, "GameFontHighlight")
		value:SetPoint("TOPLEFT", content, "TOPLEFT", LABEL_WIDTH + 8, y)
		value:SetWidth(CONTENT_WIDTH - LABEL_WIDTH - 8)
		value:SetText(row.text)

		y = y - math.max(label:GetStringHeight(), value:GetStringHeight()) - ROW_SPACING
	end

	HideUnused(content.strings, used)
	content:SetHeight(math.max(1, -y))
end

local function CreateAchievementRow(content)
	local row = CreateFrame("Frame", nil, content)
	row:SetSize(CONTENT_WIDTH, ACHIEVEMENT_HEIGHT)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(24, 24)
	row.icon:SetPoint("LEFT", 0, 0)

	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 8, 4)
	row.name:SetPoint("RIGHT", row, "RIGHT", -BAR_WIDTH - 12, 0)
	row.name:SetJustifyH("LEFT")

	row.description = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.description:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
	row.description:SetPoint("RIGHT", row, "RIGHT", -BAR_WIDTH - 12, 0)
	row.description:SetJustifyH("LEFT")

	row.bar = CreateFrame("StatusBar", nil, row)
	row.bar:SetSize(BAR_WIDTH, 14)
	row.bar:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.bar:SetStatusBarColor(0.2, 0.6, 0.2)

	row.bar.background = row.bar:CreateTexture(nil, "BACKGROUND")
	row.bar.background:SetAllPoints()
	row.bar.background:SetColorTexture(0, 0, 0, 0.5)

	row.bar.text = row.bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.bar.text:SetPoint("CENTER")

	row.date = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.date:SetPoint("RIGHT", row, "RIGHT", 0, 0)

	return row
end

local function FillAchievementRow(row, achievement)
	local Achievements = addon.Achievements
	local unlocked = Achievements:IsUnlocked(achievement)

	row.name:SetText(achievement.name)
	row.description:SetText(achievement.description)

	if unlocked then
		row.icon:SetTexture(ICON_UNLOCKED)
		row.name:SetFontObject("GameFontNormal")
		row.date:SetText(date("%Y-%m-%d", Achievements:GetUnlockTime(achievement)))
		row.date:Show()
		row.bar:Hide()

		return
	end

	local current, goal = Achievements:GetProgress(achievement)

	row.icon:SetTexture(ICON_LOCKED)
	row.name:SetFontObject("GameFontDisable")
	row.date:Hide()
	row.bar:SetMinMaxValues(0, goal)
	row.bar:SetValue(current)
	row.bar.text:SetText(addon.FormatNumber(current) .. " / " .. addon.FormatNumber(goal))
	row.bar:Show()
end

local function RenderAchievements()
	local content = pages[TAB_ACHIEVEMENTS].content
	local Achievements = addon.Achievements
	local usedStrings = 1
	local usedRows = 0

	local y = SetHeading(
		content,
		usedStrings,
		"Achievements: " .. Achievements:CountUnlocked() .. "/" .. #addon.AchievementList .. " (all characters)",
		0
	)

	for _, category in ipairs(addon.AchievementList.CATEGORIES) do
		usedStrings = usedStrings + 1
		local header = GetString(content, usedStrings, "GameFontNormal")
		header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y - 4)
		header:SetText(addon.ColorAchievement .. category .. addon.ColorEnd)
		y = y - CATEGORY_HEIGHT

		for _, achievement in ipairs(addon.AchievementList) do
			if achievement.category == category then
				usedRows = usedRows + 1
				local row = content.rows[usedRows]

				if not row then
					row = CreateAchievementRow(content)
					content.rows[usedRows] = row
				end

				row:ClearAllPoints()
				row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, y)
				FillAchievementRow(row, achievement)
				row:Show()

				y = y - ACHIEVEMENT_HEIGHT
			end
		end
	end

	HideUnused(content.strings, usedStrings)
	HideUnused(content.rows, usedRows)
	content:SetHeight(math.max(1, -y))
end

local function UpdateScopeButtons()
	for scope, button in pairs(scopeButtons) do
		button:SetShown(selectedTab == TAB_STATISTICS)
		button:SetEnabled(scope ~= (statsScope or "character"))
	end
end

local function CreateScopeButton(scope, text, anchor)
	local button = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
	button:SetSize(130, 22)
	button:SetText(text)
	button:SetScript("OnClick", function()
		statsScope = scope ~= "character" and scope or nil
		PlayTabSound()
		Window:Refresh()
	end)

	if anchor then
		button:SetPoint("LEFT", anchor, "RIGHT", 6, 0)
	else
		button:SetPoint("TOPRIGHT", win, "TOPRIGHT", -180, -60)
	end

	scopeButtons[scope] = button

	return button
end

local function Create()
	win = CreateWindowFrame()

	CreateTab(TAB_STATISTICS, "Statistics")
	CreateTab(TAB_ACHIEVEMENTS, "Achievements")
	pcall(PanelTemplates_SetNumTabs, win, #tabs)

	pages[TAB_STATISTICS] = CreatePage()
	pages[TAB_ACHIEVEMENTS] = CreatePage()

	local characterButton = CreateScopeButton("character", "This character")
	CreateScopeButton("account", "All characters", characterButton)

	win:SetScript("OnShow", function()
		Window:Refresh()
	end)

	win:Hide()
end

function Window:SelectTab(index)
	selectedTab = index

	for i, tab in ipairs(tabs) do
		if tab.isFallback then
			tab:SetEnabled(i ~= index)
		elseif i == index then
			pcall(PanelTemplates_SelectTab, tab)
		else
			pcall(PanelTemplates_DeselectTab, tab)
		end
	end

	for i, page in ipairs(pages) do
		page:SetShown(i == index)
	end

	self:Refresh()
end

-- Redraws the visible tab (called after every tracked buff, too)
function Window:Refresh()
	if not win or not win:IsShown() then
		return
	end

	UpdateScopeButtons()
	UpdatePortrait()

	if selectedTab == TAB_ACHIEVEMENTS then
		RenderAchievements()
	else
		RenderStatistics()
	end
end

-- tab: optional TAB_* index to open
function Window:Toggle(tab)
	if not win then
		Create()
		self:SelectTab(selectedTab)
	end

	if win:IsShown() and (not tab or tab == selectedTab) then
		win:Hide()

		return
	end

	if tab then
		self:SelectTab(tab)
	end

	win:Show()
end

Window.TAB_STATISTICS = TAB_STATISTICS
Window.TAB_ACHIEVEMENTS = TAB_ACHIEVEMENTS
