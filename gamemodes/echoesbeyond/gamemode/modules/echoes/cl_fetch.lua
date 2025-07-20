function InitPartyMode(msg, milestone)
	EchoNotify(msg)

	timer.Simple(3, function()
		partyMode = true

		StopMusic()
		timer.Remove("echoesMusic")

		if milestone then
			timer.Simple(20, function()
				EchoNotify("Thank you all for your continued support!")
			end)

			timer.Simple(40, function()
				EchoNotify("Click the 'End Party Mode' button in the main menu to stop at any time.")

				endPartyEnabled = true
			end)
		else
			endPartyEnabled = true
		end

		LocalPlayer():EmitSound("echoesbeyond/music/km_who_likes_to_party.mp3")

		timer.Create("echoesPartyColor", 0, 0, function()
			timer.Adjust("echoesPartyColor", 0.5)

			for i = 1, #echoes do
				local echo = echoes[i]
				echo.partyColor = Color(math.random(255), math.random(255), math.random(255))
				echo.partyOffset = Vector(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
			end

			vignetteColor = Color(math.random(255), math.random(255), math.random(255))
		end)

		timer.Create("echoesParty", 255, 1, function() -- Duration of the party music
			partyMode = false
			timer.Remove("echoesPartyColor")
			LocalPlayer():StopSound("echoesbeyond/music/km_who_likes_to_party.mp3")
			vignetteColor = color_black
			endPartyEnabled = false

			if (!EchoesSettings["echoes_music"]) then return end

			PlayMusic()
		end)
	end)
end


-- Fetch echoes and send them to the client
CreateClientConVar("echoes_windowflash", "1")

-- Initialize globals
mapCount = mapCount or 0 -- Total amount of maps with echoes, used in the main menu
endPartyEnabled = endPartyEnabled or false -- Whether the party mode can be ended
writtenEchoes = writtenEchoes or {} -- Echoes on the map written by the player
readEchoCount = readEchoCount or 0 -- Amount of echoes read by the player
globalEchoCount = globalEchoCount or 0 -- Total amount of echoes, ditto
vignetteColor = vignetteColor or color_black -- Vignette color
userCount = userCount or 0 -- Total amount of users, ditto
partyMode = partyMode or false -- Whether party mode is on
nextEcho = nextEcho or 0 -- Time a new echo can be made
mapList = mapList or {} -- List of maps with echoes
echoes = echoes or {} -- Echoes on the map

function SyncPinnedStatus()
    for _, echo in ipairs(echoes) do
        echo.pinned = false
        if IsEchoPinned(echo.id) then
            echo.pinned = true
        end
    end
end

function FetchEchoes()
	local map = game.GetMap()

	http.Fetch("https://resonance.flatgrass.net/note/view?map=" .. map, function(body, _, _, code)
		if (code != 200) then
			EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))

			return
		end

		local data = util.JSONToTable(body) or {}
		local echoData = data.notes
		if (!echoData) then return end

		local readEchoes = ReadEchoes()
		local echoCount = #echoData

		if (echoCount > #echoes) then
			EchoSound("echo_create")

			if (EchoesSettings["echoes_windowflash"]) then
				system.FlashWindow()
			end
		end

		readEchoCount = 0

		local deletedEchoes = table.Copy(echoes) -- Copy of the echoes table to check for deleted echoes
		local newEchoes = {}

		for i = 1, #echoData do
			local newEcho = echoData[i]
			local exists = false

			for k = 1, #echoes do
				if (echoes[k].id != newEcho.id) then continue end

				exists = true

				for j = 1, #deletedEchoes do
					if (deletedEchoes[j].id != newEcho.id) then continue end

					table.remove(deletedEchoes, j)

					break
				end

				break
			end

			local read = table.HasValue(readEchoes, newEcho.id)
			local isOwner = false

			for k = 1, #writtenEchoes do
				if (writtenEchoes[k].id != newEcho.id) then continue end

				isOwner = true

				break
			end

			if (read or isOwner) then
				readEchoCount = readEchoCount + 1
			end

			local position = Vector(tonumber(newEcho.position[1]), tonumber(newEcho.position[2]), tonumber(newEcho.position[3]))

			if (exists) then continue end

			newEchoes[#newEchoes + 1] = {
				id = newEcho.id,
				pos = position
			}

			local text = newEcho.comment
			local read = table.HasValue(readEchoes, newEcho.id)
			local isSpecial = string.StartsWith(text, "!&") and newEcho.admin
			local text = isSpecial and string.sub(text, string.StartsWith(text, "!& ") and 4 or 3) or text

			local newEchoTable = {
				explicit = IsOffensive(text),
				angle = Angle(0, 0, 90),
				readTime = read and 0,
				special = isSpecial,
				soundActive = false,
				drawPos = Vector(position),
				isOwner = isOwner,
				id = newEcho.id,
				pos = position,
				read = read,
				text = text,
				active = 0,
				init = 0,
				skin = "default"
			}

			if isSpecial then
				newEchoTable.color = Color(200, 0, 200)
				newEchoTable.light_color = Color(255, 0, 255)
			elseif isOwner then
				newEchoTable.color = Color(255, 255, 0)
				newEchoTable.light_color = Color(255, 255, 0)
			end

			echoes[#echoes + 1] = newEchoTable

		end

		ValidateEchoes(newEchoes)

		-- Remove echoes that were deleted
		for i = 1, #deletedEchoes do
			local echo = deletedEchoes[i]

			for k = 1, #echoes do
				if (echoes[k].id != echo.id) then continue end

				table.remove(echoes, k)

				break
			end
		end
		SyncPinnedStatus()
		IDsort()
	end, function(error)
		EchoNotify(error)
	end)
end

function FetchOwnEchoes()
	http.Fetch("https://resonance.flatgrass.net/note/mine", function(body, _, _, code)
		if (authToken) then
			if (code != 401) then
				if (code != 200) then
					EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))

					return
				end

				local data = util.JSONToTable(body) or {}
				local echoData = data.notes
				if (!echoData) then return end

				for i = 1, #echoData do
					echoData[i].position = Vector(tonumber(echoData[i].position[1]), tonumber(echoData[i].position[2]), tonumber(echoData[i].position[3]))
				end

				writtenEchoes = echoData
			else
				authToken = nil -- Invalidate the auth token to log the player out
			end
		end

		FetchEchoes()
	end, function(error)
		EchoNotify(error)
	end, {authorization = authToken})
end

function FetchStats()
	http.Fetch("https://resonance.flatgrass.net/stats", function(body, _, _, code)
		if (code != 200) then
			EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))

			return
		end

		local data = util.JSONToTable(body)
		if (!data) then return end

		if (IsValid(mainMenu)) then
			mainMenu:UpdateStats(data.user_count, data.note_count, data.map_count, data.maps)
		end

		if (globalEchoCount != 0 and globalEchoCount < data.note_count) then
			local previousCount = math.floor(globalEchoCount / 1000) * 1000
			local newCount = math.floor(data.note_count / 1000) * 1000

			if (newCount > previousCount) then
				InitPartyMode("A new milestone has been reached! " .. newCount .. " Echoes have been written! Engage party mode!", true)
			end
		end

		userCount = data.user_count
		globalEchoCount = data.note_count
		mapCount = data.map_count
		mapList = data.maps

	end, function(error)
		EchoNotify(error)
	end)
end

function FetchInfo()
	if (!authToken) then return end

	http.Fetch("https://resonance.flatgrass.net/info?map=" .. game.GetMap(), function(body, _, _, code)
		if (code == 401) then
			authToken = nil

			return
		end

		if (code != 200) then
			EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))

			return
		end

		local data = util.JSONToTable(body)
		if (!data) then return end

		nextEcho = os.time() + data.note_cooldown
	end, function(error)
		EchoNotify(error)
	end, {authorization = authToken})
end

hook.Add("InitPostEntity", "echoes_fetch_InitPostEntity", function()
	authToken = file.Read("echoesbeyond/authtoken.txt", "DATA")
	authToken = authToken and string.find(authToken, "\n", 1, true) and string.Explode("\n", authToken)[2]

	LoadPinnedEchoes()
	FetchOwnEchoes()
	FetchInfo()

	-- Fetch echoes, info, and stats every minute
	timer.Create("echoesFetchEchoes", 60, 0, function() FetchEchoes() FetchInfo() FetchStats() end)
end)
