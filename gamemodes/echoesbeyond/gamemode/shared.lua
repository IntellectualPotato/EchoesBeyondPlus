CreateConVar(
  "echoes_allowsandbox",
  "0",
  { FCVAR_ARCHIVE, FCVAR_NOTIFY,
    FCVAR_REPLICATED,
    FCVAR_CLIENTCMD_CAN_EXECUTE
  }
)
if GetConVar("echoes_allowsandbox"):GetBool() then
	DeriveGamemode("sandbox")
end

-- File inclusion functions
local realms = {}
realms["cl"] = function(path)
	if (SERVER) then
		AddCSLuaFile(path)

		return
	end

	return include(path)
end
realms["sh"] = function(path)
	if (SERVER) then
		AddCSLuaFile(path)
	end

	return include(path)
end
realms["sv"] = function(path)
	return SERVER and include(path)
end

local function Include(path)
	if (path:match("sv_")) then
		if (!SERVER) then return end

		return include(path)
	elseif (path:match("sh_")) then
		if (SERVER) then
			AddCSLuaFile(path)
		end

		return include(path)
	elseif (path:match("cl_")) then
		if (SERVER) then
			AddCSLuaFile(path)
		else
			return include(path)
		end
	else -- Assume shared
		if (SERVER) then
			AddCSLuaFile(path)
		end

		return include(path)
	end
end

local function IncludeDirectory(path, bRecurse)
	local files, dirs = file.Find(path .. "/*", "LUA")

	for _, v in ipairs(files) do
		Include(path .. "/" .. v)
	end

	if (!bRecurse) then return end

	for _, v in ipairs(dirs) do
		IncludeDirectory(path .. "/" .. v, true)
	end
end

IncludeDirectory("echoesbeyond/gamemode/modules", true)
