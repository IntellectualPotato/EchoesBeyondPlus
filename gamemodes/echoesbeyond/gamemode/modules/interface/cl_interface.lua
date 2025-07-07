
-- Hide HUD
--[[
hook.Add("HUDShouldDraw", "interface_HUDShouldDraw", function(name)
	return name == "CHudGMod"
end)
]]

-- Block chat binds
--[[
local binds = {
	["messagemode"] = true,
	["messagemode2"] = true
}
]]

hook.Add("PlayerBindPress", "interface_PlayerBindPress", function(client, bind, pressed)
	if (!binds[bind]) then return end

	return true
end)

-- Draw vignette
local vignette = Material("echoesbeyond/vignette.png")

hook.Add("HUDPaint", "interface_HUDPaint", function()
	surface.SetDrawColor(vignetteColor)
	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end)

-- Hide Scoreboard
hook.Add("ScoreboardShow", "interface_ScoreboardShow", function()
	return false
end)
