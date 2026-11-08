local addonName, addon = ...

local function OnOff(value)
	return value and "on" or "off"
end

local function PrintCommand(command, description)
	addon.PrintLine(addon.ColorCommand .. "/autobuff " .. command .. addon.ColorEnd .. " - " .. description)
end

local function PrintHelp()
	local list = addon.Presets:GetAvailable()

	addon.Print("Current: " .. addon.Highlight(addon.Buffs:GetCurrent().name or "none"))

	if #list == 0 then
		addon.Print("No known buffs for your class. Use /autobuff spell <name or ID>.")
	else
		for i, preset in ipairs(list) do
			addon.PrintLine(string.format("   %d) %s", i, (addon.Api.GetSpellInfo(preset.cast))))
		end
	end

	PrintCommand("<number>", "Pick a buff from the list")
	PrintCommand("spell <name or ID>", "Pick any spell")
	PrintCommand("others", "Toggle other players (nameplates): " .. OnOff(addon.db.nameplates))
	PrintCommand("group", "Toggle yourself and your group/raid (buffing and report): " .. OnOff(addon.db.group))
	PrintCommand("report", "Toggle chat report of each buff: " .. OnOff(addon.db.report))
	PrintCommand("show | hide", "Show or hide the button")
	PrintCommand("reset", "Move the button back to its initial position")
	addon.PrintLine("Key binding: Options > Keybindings > AddOns > AutoBuffer")
end

local function SelectPreset(index)
	local preset = addon.Presets:GetAvailable()[index]

	if preset then
		addon.Buffs:Set(preset.cast, preset.covers)
	else
		addon.Print("Invalid number.")
	end
end

local function SelectSpell(spell)
	if spell == "" then
		addon.Print("Example: /autobuff spell Thorns")

		return
	end

	addon.Buffs:Set(tonumber(spell) or spell, {})
end

local function ToggleOthers()
	addon.db.nameplates = not addon.db.nameplates

	if addon.db.nameplates then
		addon.Print("Other players: on (show friendly nameplates with Shift+V)")
	else
		addon.Print("Other players: off")
	end
end

local function ToggleGroup()
	addon.db.group = not addon.db.group
	addon.Print("Yourself and group/raid: " .. OnOff(addon.db.group))
end

local function ToggleReport()
	addon.db.report = not addon.db.report
	addon.Print("Report: " .. OnOff(addon.db.report))
end

local function ShowButton()
	addon.db.hidden = false
	addon.Button:ApplyVisibility()
end

local function HideButton()
	addon.db.hidden = true
	addon.Button:ApplyVisibility()
	addon.Print("Hidden. The key binding still works.")
end

local function ResetPosition()
	addon.Button:ResetPosition()
end

local commands = {
	help = PrintHelp,
	spell = SelectSpell,
	others = ToggleOthers,
	group = ToggleGroup,
	report = ToggleReport,
	show = ShowButton,
	hide = HideButton,
	reset = ResetPosition,
}

SLASH_AUTOBUFFER1 = "/autobuff"
SLASH_AUTOBUFFER2 = "/abuff"

SlashCmdList.AUTOBUFFER = function(msg)
	if not addon.db then
		return
	end

	local name, argument = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
	name = (name or ""):lower()

	if tonumber(name) then
		SelectPreset(tonumber(name))

		return
	end

	local command = commands[name]

	if command then
		command(argument)
	else
		PrintHelp()
	end
end
