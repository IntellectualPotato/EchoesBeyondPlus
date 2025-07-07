
hook.Add("InitPostEntity", "echoes_gamemodenotice", function()
	local gamemode = gmod.GetGamemode()
	if (gamemode.FolderName == "echoesbeyond") then return end
	if (file.Exists("echoesbeyond/readechoes.txt", "DATA")) then return end

	EchoesConfirm(
		"Did you mean to play Echoes Beyond?",
		"You recently installed Echoes Beyond, which is a gamemode, not an addon. Would you like to switch to it now?",
		function()
			RunConsoleCommand("gamemode", "echoesbeyond")
			RunConsoleCommand("changelevel", game.GetMap())
		end,
		function()
			file.CreateDir("echoesbeyond")
			file.Write("echoesbeyond/readechoes.txt", "") -- Make sure the notice doesn't show up again
		end
	)
end)
