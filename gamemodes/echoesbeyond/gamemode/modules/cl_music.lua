
-- Plays ambient music
CreateClientConVar("echoes_music", "1")


local songs = {
	"echoesbeyond/music/eo_all_around us.mp3",
	"echoesbeyond/music/eo_a_sunset.mp3",
	"echoesbeyond/music/eo_below_the clouds.mp3",
	"echoesbeyond/music/eo_dead_metal.mp3",
	"echoesbeyond/music/eo_its_expanding.mp3",
	"echoesbeyond/music/eo_monolith.mp3",
	"echoesbeyond/music/eo_red_ocean.mp3",
	"echoesbeyond/music/eo_reflect.mp3",
	"echoesbeyond/music/eo_reverse.mp3",
	"echoesbeyond/music/eo_strange_flyer.mp3",
	"echoesbeyond/music/eo_the_heights.mp3",
	"echoesbeyond/music/eo_the_oddity.mp3",
	"echoesbeyond/music/eo_yesterday.mp3",
	"echoesbeyond/music/eo_yesterdays.mp3"
}

local scarySongs = { --random songs ive gathered, some of these may or may not be good choices, forgive me LOL
	"echoesbeyond/music/scary/yn_uboa.mp3",
	"echoesbeyond/music/scary/am_bridges.mp3",
	"echoesbeyond/music/scary/am_archives.mp3",
	"echoesbeyond/music/scary/the_sewers.mp3",
	"echoesbeyond/music/scary/underground_archives.mp3",
	"echoesbeyond/music/scary/y2_blood_world.mp3",
	"echoesbeyond/music/scary/y2_bgm036.mp3",
	"echoesbeyond/music/scary/y2_dusty_pinwheel_path.mp3",
	"echoesbeyond/music/scary/y2_flesh_paths_world.mp3",
	"echoesbeyond/music/scary/y2_cultivated_lands.mp3",
	"echoesbeyond/music/scary/y2_honoring_the_dead_event.mp3",
	"echoesbeyond/music/scary/y2_grass_world.mp3",
	"echoesbeyond/music/scary/y2_forest_interlude.mp3",
	"echoesbeyond/music/scary/y2_mare_tranquillitatis.mp3",
	"echoesbeyond/music/scary/y2_aureate_clockworks.mp3",
	"echoesbeyond/music/scary/step_p3-4.mp3",
	"echoesbeyond/music/scary/os_my_burden_is_dead.mp3",
	"echoesbeyond/music/scary/os_deep_mines.mp3",
	"echoesbeyond/music/scary/os_ambience_I.mp3",
	"echoesbeyond/music/scary/os_ambience_II.mp3",
	"echoesbeyond/music/scary/os_ambience_IV.mp3",
	"echoesbeyond/music/scary/pbg_foreboding7.mp3",
	"echoesbeyond/music/scary/pbg_foreboding10.mp3",
	"echoesbeyond/music/scary/uty_honest_days_work.mp3",
	"echoesbeyond/music/scary/om_thalassophobia.mp3",
	"echoesbeyond/music/scary/om_long_way_down.mp3",
	"echoesbeyond/music/scary/om_fleur.mp3",
	"echoesbeyond/music/scary/om_calm.mp3",
	"echoesbeyond/music/scary/om_nawa.mp3",
	"echoesbeyond/music/scary/om_your_catastrophes.mp3",
	"echoesbeyond/music/scary/om_listening.mp3",
}

local currentSong = currentSong or nil
local currentSongIndex = nil
local useScarySongs = false
timer.Simple(0.25, function()
	useScarySongs = GetConVar("echoes_scarymode"):GetBool()
end)

local function GetActiveSongTable()
	return useScarySongs and scarySongs or songs
end

function PlayMusic(index)
	print(useScarySongs)
	local songTable = GetActiveSongTable()
	local soundPath
	if index and songTable[index] then
		soundPath = songTable[index]
		currentSongIndex = index
	else
		currentSongIndex = nil
		soundPath = songTable[math.random(#songTable)]
	end
	local soundDuration = SoundDuration(soundPath) + 10

	timer.Create("echoesMusic", soundDuration, 1, function()
		PlayMusic()
	end)

	sound.PlayFile("sound/" .. soundPath, "mono", function(station)
		if (!IsValid(station)) then return end

		if (IsValid(currentSong)) then
			currentSong:Stop()
		end

		station:SetVolume(0.5)
		station:Play()

		currentSong = station
	end)
end

function StopMusic()
	if (IsValid(currentSong)) then
		currentSong:Stop()
	end

	timer.Remove("echoesMusic")
end

cvars.AddChangeCallback("echoes_music", function(name, old, new)
	if (new == "1") then
		PlayMusic()
	else
		StopMusic()
	end
end, "echoes_music")

concommand.Add("echoes_playmusic", function(ply, cmd, args) --to debug the songs how they sound ingame lolol
	local idx = tonumber(args[1])
	if idx then
		StopMusic()
		PlayMusic(idx)
	end
end)

cvars.AddChangeCallback("echoes_scarymode", function(name, old, new)
	useScarySongs = (new == "1")
	if (not EchoesSettings["echoes_music"]) then return end
	StopMusic()
	PlayMusic()
end, "music_scarymode_switch")

hook.Add("InitPostEntity", "music_InitPostEntity", function()
	timer.Simple(0.25, function()
	if (not EchoesSettings["echoes_music"]) then return end
	PlayMusic()
	end)
end)
