
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("Echoes_ToggleAllowSandbox")

net.Receive("Echoes_ToggleAllowSandbox", function(len, ply)
  if not ply:IsAdmin() then return end
  local newVal = net.ReadBool()
  GetConVar("echoes_allowsandbox"):SetBool(newVal)
end)
