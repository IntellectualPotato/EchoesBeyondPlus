EchoesSettings = {}

local function addSetting(name, default, getType)
    local cvar = CreateClientConVar(name, default, true, false)
    local value = cvar["Get" .. getType](cvar)
    EchoesSettings[name] = value

    cvars.AddChangeCallback(name, function(_, _, new)
        if getType == "Bool" then
            EchoesSettings[name] = (new == "1")
        elseif getType == "Int" then
            EchoesSettings[name] = tonumber(new)
        else
            EchoesSettings[name] = new
        end
    end, "EchoesSettings_" .. name)
end

addSetting("echoes_showread", "1", "Bool")
addSetting("echoes_renderdist", "25000000", "Int")
addSetting("echoes_disablereadsys", "0", "Bool")
addSetting("echoes_disablesigning", "0", "Bool")
addSetting("echoes_gabenmode", "0", "Bool")
addSetting("echoes_bypasschecks", "0", "Bool")
addSetting("echoes_debuginfo", "0", "Bool")
addSetting("echoes_dlights", "1", "Bool")
addSetting("echoes_dlights_brightness", "3", "Int")
addSetting("echoes_enablevoidechoes", "0", "Bool")
addSetting("echoes_enableairechoes", "1", "Bool")
addSetting("echoes_profanity", "0", "Bool")
addSetting("echoes_music", "1", "Bool")
addSetting("echoes_smoothview", "1", "Bool")
addSetting("echoes_speed", "100", "Int")
addSetting("echoes_windowflash", "1", "Bool")
addSetting("echoes_personalshowall", "0", "Bool")

return EchoesSettings 