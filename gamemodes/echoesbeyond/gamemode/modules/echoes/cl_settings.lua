EchoesSettings = {}
EchoesHUDHide = {}

local function addSetting(name, default, getType, onChange)
    local cvar = CreateClientConVar(name, default, true, false)
    local value = cvar["Get" .. getType](cvar)
    EchoesSettings[name] = value

    cvars.AddChangeCallback(name, function(_, _, new)
        if getType == "Bool" then
            EchoesSettings[name] = (new == "1")
        elseif getType == "Int" then
            EchoesSettings[name] = tonumber(new)
        elseif getType == "Float" then
            EchoesSettings[name] = tonumber(new)
        else
            EchoesSettings[name] = new
        end
        if onChange then onChange(new) end
    end, "EchoesSettings_" .. name)
end

local function UpdateHUDHideTable()
    local hide = {}
    
    if EchoesSettings["echoes_hidehud_suit"] then
        hide["CHudAmmo"] = true
        hide["CHudBattery"] = true
        hide["CHudSecondaryAmmo"] = true
        hide["CHudSuitPower"] = true
        hide["CHudHealth"] = true
    end
    
    if EchoesSettings["echoes_hidehud_crosshair"] then
        hide["CHudCrosshair"] = true
    end
    
    if EchoesSettings["echoes_hidehud_weaponsel"] then
        hide["CHudWeaponSelection"] = true
    end
    
    EchoesHUDHide = hide
end

function UpdateShouldShow() --New system to hide echoes in better way imo
	for _, echo in ipairs(echoes) do
		echo.ShouldShow = true
		if echo.explicit and not EchoesSettings["echoes_profanity"] then
			echo.ShouldShow = false
		elseif echo.read and not EchoesSettings["echoes_showread"] then
			echo.ShouldShow = false
		elseif echo.inVoid and not EchoesSettings["echoes_enablevoidechoes"] then
			echo.ShouldShow = false
		elseif echo.failed then
			echo.ShouldShow = false
		end
	end
end

addSetting("echoes_showread", "1", "Bool", function(new)
	UpdateShouldShow()
end)
addSetting("echoes_renderdist", "25000000", "Int")
addSetting("echoes_disablereadsys", "0", "Bool")
addSetting("echoes_disablesigning", "0", "Bool")
addSetting("echoes_showsignaturecolors", "1", "Bool")
addSetting("echoes_allowsigsown", "1", "Bool")
addSetting("echoes_gabenmode", "0", "Bool")
addSetting("echoes_bypasschecks", "0", "Bool")
addSetting("echoes_debuginfo", "0", "Bool")
addSetting("echoes_dlights", "1", "Bool")
addSetting("echoes_dlights_brightness", "3", "Int")
addSetting("echoes_enablevoidechoes", "0", "Bool", function(new)
	UpdateShouldShow()
end)
addSetting("echoes_enableairechoes", "1", "Bool")
addSetting("echoes_enable_drafts", "0", "Bool")
addSetting("echoes_profanity", "0", "Bool", function(new)
	UpdateShouldShow()
end)
addSetting("echoes_music", "1", "Bool")
addSetting("echoes_smoothview", "1", "Bool")
addSetting("echoes_speed", "100", "Int")
addSetting("echoes_windowflash", "1", "Bool")
addSetting("echoes_personalshowall", "0", "Bool")
addSetting("echoes_scarymode", "0", "Bool")
addSetting("echoes_slowactivate", "0", "Bool")
addSetting("echoes_visibleonly", "0", "Bool")
addSetting("echoes_visiblefov", "180", "Int")
addSetting("echoes_notifynew", "0", "Bool")
addSetting("echoes_immersivemode", "1", "Bool")
addSetting("echoes_enableparticles", "1", "Bool")

local hudSettings = {"echoes_hidehud_suit", "echoes_hidehud_crosshair", "echoes_hidehud_weaponsel"}

for _, setting in ipairs(hudSettings) do
    addSetting(setting, "0", "Bool")
    
    cvars.AddChangeCallback(setting, function(_, _, new)
        EchoesSettings[setting] = (new == "1")
        UpdateHUDHideTable()
    end, "EchoesHUD_" .. setting)
end

UpdateHUDHideTable()
UpdateShouldShow()

local previousSkyName = nil
local previousMatSpecular = nil
local userRenderDist = nil
local scaryRenderDist = 665100

cvars.AddChangeCallback("echoes_renderdist", function(name, old, new)
    if EchoesSettings["echoes_scarymode"] then return end
    userRenderDist = tonumber(new)
end, "scarymode_renderdist")

print(system.UpTime())

function ApplyScaryMode(enabled)
    net.Start("Echoes_ScaryMode_Toggled")
    net.WriteBool(enabled)
    net.SendToServer()
    local function lightEnv_updateCVar(newVal, cvarName)
        if LocalPlayer():IsListenServerHost() then
            if isbool(newVal) then
                RunConsoleCommand(cvarName, newVal and "1" or "0")
            else
                RunConsoleCommand(cvarName, tostring(newVal))
            end
            return
        end
        net.Start("Environments_server_setcv")
        net.WriteString(cvarName)
        if isbool(newVal) then
            net.WriteUInt(0, 2)
            net.WriteBool(newVal)
        elseif isnumber(newVal) then
            net.WriteUInt(1, 2)
            net.WriteUInt(newVal, 8)
        elseif isstring(newVal) then
            net.WriteUInt(2, 2)
            net.WriteString(newVal)
        end
        net.SendToServer()
    end
    if enabled then
        if not previousSkyName then
            previousSkyName = GetConVar("sv_skyname"):GetString()
        end
        if not previousMatSpecular then
            previousMatSpecular = GetConVar("mat_specular"):GetInt()
        end
        if not userRenderDist then
            userRenderDist = GetConVar("echoes_renderdist"):GetInt()
        end
        EchoesSettings["echoes_renderdist"] = scaryRenderDist
        lightEnv_updateCVar(1, "Environment_ambientLightLevel")
        lightEnv_updateCVar(1, "Environment_SunLightLevel")
        RunConsoleCommand("Environment_Destroy_Soundscapes")
        RunConsoleCommand("Environment_stopsoundscape")
        timer.Simple(5, function()
            lightEnv_updateCVar(1, "Environment_DisableStaticSelfIllum")
        end)
        timer.Simple(10, function()
            RunConsoleCommand("Environment_DisableStaticAmbientLighting")
        end)
        lightEnv_updateCVar("black", "sv_skyname")
        RunConsoleCommand("mat_specular", "0")

        hook.Add("SetupWorldFog", "ScaryModeBlackFog", function()
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0)
            render.FogEnd(900)
            render.FogMaxDensity(1)
            render.FogColor(0, 0, 0)
            return true
        end)
        hook.Add("SetupSkyboxFog", "ScaryModeBlackFog", function(scale)
            render.FogMode(MATERIAL_FOG_LINEAR)
            render.FogStart(0)
            render.FogEnd(600 * (scale or 1))
            render.FogMaxDensity(1)
            render.FogColor(0, 0, 0)
            return true
        end)
    else
        if userRenderDist then
            EchoesSettings["echoes_renderdist"] = userRenderDist
        else
            EchoesSettings["echoes_renderdist"] = GetConVar("echoes_renderdist"):GetInt()
        end
        lightEnv_updateCVar(12, "Environment_ambientLightLevel")
        lightEnv_updateCVar(12, "Environment_SunLightLevel")
        timer.Simple(5, function()
            lightEnv_updateCVar(0, "Environment_DisableStaticSelfIllum")
        end)
        if previousSkyName then
            lightEnv_updateCVar(previousSkyName, "sv_skyname")
        end
        if previousMatSpecular then
            RunConsoleCommand("mat_specular", tostring(previousMatSpecular))
        end

        hook.Remove("SetupWorldFog", "ScaryModeBlackFog")
        hook.Remove("SetupSkyboxFog", "ScaryModeBlackFog")
        --no way to re-enable static ambient lighting, have to reload map :(
    end
end

hook.Add("InitPostEntity", "echoes_scarymode_autoapply", function()
    if GetConVar("echoes_scarymode"):GetBool() then
        timer.Simple(0.1, function()
            ApplyScaryMode(true)
        end)
    end
end)

return EchoesSettings 