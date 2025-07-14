
-- Plays ambient music
CreateClientConVar("echoes_music", "1")

cvars.AddChangeCallback("echoes_music", function(name, old, new)
	if (new == "1") then
		PlayMusic()
	else
		StopMusic()
	end
end, "echoes_music")

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

currentSong = currentSong or nil

function PlayMusic()
	local soundPath = songs[math.random(#songs)]
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

hook.Add("InitPostEntity", "music_InitPostEntity", function()
	if (!GetConVar("echoes_music"):GetBool()) then return end

	PlayMusic()
end)
