local addonName, addon = ...

-- Report mode: prints who got which buff
local Report = {}
addon.Report = Report

function Report:Success(cast)
	if not addon.db.report then
		return
	end

	addon.Print("Buffed " .. addon.Api.ColorByClass(cast.name, cast.class) .. " with " .. addon.Highlight(cast.spell))
end

function Report:Failure(cast)
	if not addon.db.report then
		return
	end

	addon.Print(
		addon.ColorError
			.. "Failed"
			.. addon.ColorEnd
			.. ": "
			.. cast.spell
			.. " on "
			.. addon.Api.ColorByClass(cast.name, cast.class)
	)
end
