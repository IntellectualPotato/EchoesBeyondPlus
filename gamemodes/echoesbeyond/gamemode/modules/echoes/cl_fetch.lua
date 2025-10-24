local hasFetchedStatsOnce = hasFetchedStatsOnce or false

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
drafts = drafts or {} --pending echo drafts (up to 3)
readEchoCount = readEchoCount or 0 -- Amount of echoes read by the player
globalEchoCount = globalEchoCount or 0 -- Total amount of echoes, ditto
vignetteColor = vignetteColor or color_black -- Vignette color
userCount = userCount or 0 -- Total amount of users, ditto
partyMode = partyMode or false -- Whether party mode is on
nextEcho = nextEcho or 0
mapList = mapList or {} -- List of maps with echoes
echoes = echoes or {}
EchoesOnMaps = EchoesOnMaps or {}

mapCooldowns = mapCooldowns or {}

local INTERVAL = 60

function LoadMapCooldowns()
	local content = file.Read("echoesbeyond/map_cooldowns.json", "DATA") or "{}"
	mapCooldowns = util.JSONToTable(content) or {}
end

function SaveMapCooldowns()
	file.Write("echoesbeyond/map_cooldowns.json", util.TableToJSON(mapCooldowns, true))
end

function GetCurrentMapNext()
	local map = game.GetMap()
	local nextT = mapCooldowns[map]
	local currentTime = os.time()
	if not nextT then
		return currentTime
	end
	return math.max(nextT, currentTime)
end

function ReprojectDraftsOnMap(map)
	local currentTime = os.time()
	local nextSlot = mapCooldowns[map] or currentTime
	local waitToNext = nextSlot - currentTime
	if waitToNext < 0 then waitToNext = 0; nextSlot = currentTime end
	local baseK = math.floor(waitToNext / INTERVAL)

	local draftsOnMap = {}
	for _, d in ipairs(drafts) do
		if d.map == map then
			table.insert(draftsOnMap, d)
		end
	end

	table.sort(draftsOnMap, function(a, b) return a.timestamp < b.timestamp end)

	local thisSend = nextSlot
	for i, draft in ipairs(draftsOnMap) do
		draft.sendTime = thisSend
		thisSend = thisSend + INTERVAL * (baseK + i)
	end
end

function ReprojectAllDrafts()
	local maps = {}
	for _, d in ipairs(drafts) do
		maps[d.map] = true
	end
	for m, _ in pairs(maps) do
		ReprojectDraftsOnMap(m)
	end
end

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

		--preserve draft dummies
		local draftDummies = {}
		for i = #echoes, 1, -1 do
			if echoes[i].isDraft then
				table.insert(draftDummies, table.remove(echoes, i))
			end
		end

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

		-- Remove deleted real echoes from echoes table
		for i = 1, #deletedEchoes do
			local echoId = deletedEchoes[i].id
			for k = #echoes, 1, -1 do
				if not echoes[k].isDraft and echoes[k].id == echoId then
					table.remove(echoes, k)
					break
				end
			end
		end

		local currentMap = game.GetMap()
		local currentMapReadCount = 0

		for _, echo in ipairs(echoes) do
			if not echo.isDraft and (echo.read or echo.isOwner or echo.special) then
				currentMapReadCount = currentMapReadCount + 1
			end
		end

		if readMapCounts[currentMap] ~= currentMapReadCount then
			readMapCounts[currentMap] = currentMapReadCount
			SaveReadMapCounts()
		end

		SyncPinnedStatus()

		--add back draft dummies only to echoes for visualization
		for _, dummy in ipairs(draftDummies) do
			table.insert(echoes, dummy)
		end

		IDsort()

		local mapSkins = {
			["gm_mttresort"] = "UTDR",
			["ttt_mttresort_v2"] = "UTDR",
			["gm_finalcorridor"] = "UTDR",
			["gm_greenroom"] = "UTDR",
			["undertaleyellowsnowdin"] = "UTDR",
			["gm_uty_darkruins"] = "UTDR",
			["gm_dlt_ridearoundtown"] = "UTDR",
			["gm_voidplaces"] = "VoidPlaces",
			["otherside"] = "VoidPlaces",
			["rp_asheville"] = "Apocalypse",
			["gm_city_of_silence"] = "Apocalypse"
		}

		local mapPrefixSkins = {
			["tbg_"] = "tbg",
			["vp_"] = "VoidPlaces",
			["vpc_"] = "VoidPlaces",
			["gm_deltarune"] = "UTDR",
			["hls"] = "hls"
		}

		local function DetermineDefaultSkin()
			local map = game.GetMap() or ""
			if mapSkins[map] then
				return mapSkins[map]
			end
			for prefix, skin in pairs(mapPrefixSkins) do
				if string.StartWith(map, prefix) then
					return skin
				end
			end
			return "default"
		end

		local DefaultSkin = DetermineDefaultSkin()
		local realEchoes = {}
		for _, echo in ipairs(echoes) do
			if not echo.isDraft then
				table.insert(realEchoes, echo)
			end
		end
		for i, echo in ipairs(realEchoes) do
			echo.skin = (i == 1 or echo.special) and "star" or DefaultSkin
		end

		for _, echo in ipairs(echoes) do
			if echo.isDraft then
				echo.skin = "blueprint"
			end
		end
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

		if EchoesSettings["echoes_notifynew"] and not EchoesSettings["echoes_immersivemode"] then
			local newMaps = data.maps
			if newMaps then
				--check if this is the first time we're fetching the stats
				if not hasFetchedStatsOnce then
					hasFetchedStatsOnce = true
				else
					for mapName, newCount in pairs(newMaps) do
						local oldCount = mapList[mapName] or 0

						if newCount > oldCount then
							print(mapName .. " New echo")
							EchoNotify("A new echo was written on " .. mapName .. "!")
						end
					end
				end
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

		local map = game.GetMap()
		local currentTime = os.time()
		local noteCooldown = data.note_cooldown or 0
		local nextSlot = currentTime + noteCooldown
		mapCooldowns[map] = nextSlot
		nextEcho = GetCurrentMapNext()
		ReprojectDraftsOnMap(map)
		SaveMapCooldowns()
	end, function(error)
		EchoNotify(error)
	end, {authorization = authToken})
end

hook.Add("InitPostEntity", "echoes_fetch_InitPostEntity", function()
	
	authToken = file.Read("echoesbeyond/authtoken.txt", "DATA")
	authToken = authToken and string.find(authToken, "\n", 1, true) and string.Explode("\n", authToken)[2]

	LoadPinnedEchoes()
	LoadMapCooldowns()
	LoadDrafts()
	ReprojectAllDrafts()
	FetchOwnEchoes()
	FetchInfo()
	FetchStats()
	LoadReadMapCounts()

	-- Fetch echoes, info, and stats every minute
	timer.Create("echoesFetchEchoes", 60, 0, function()
		FetchEchoes()
		FetchInfo()
		FetchStats()
	end)

	--autosend drafts when cooldown expires (why does this torture me sm)\
	--i cant get cooldowns to be consistent and ive probably butchered the code already
	--so im leaving it broken some what probably and jsut makign it optional lol
	timer.Create("echoesAutoSendDrafts", 5, 0, function()
		if #drafts > 0 then
			local readyDraft = nil
			local minSendTime = os.time()
			for i, draft in ipairs(drafts) do
				if draft.sendTime <= os.time() and (not readyDraft or draft.sendTime < minSendTime) then
					readyDraft = draft
					minSendTime = draft.sendTime
				end
			end
			if readyDraft then
				--add 5 second buffer before attempting send prevent cooldown errors
				local bufferTime = readyDraft.sendTime + 5
				if os.time() < bufferTime then
					return
				end
				local index = nil
				for i, d in ipairs(drafts) do
					if d == readyDraft then
						index = i
						break
					end
				end
				
				--temporarily remove draft for sending
				table.remove(drafts, index)
				local autoSendSuccess = false
				
				--create echo with callback tracking
				local sendPos = readyDraft.pos
				local sendText = readyDraft.text
				local sendMap = readyDraft.map
				http.Post("https://resonance.flatgrass.net/note/create", {
					map = sendMap,
					pos = sendPos.x .. "," .. sendPos.y .. "," .. sendPos.z,
					comment = sendText
				}, function(body, _, _, code)
					if code == 200 then
						autoSendSuccess = true
						EchoNotify("Draft sent!")
						
						-- Locally update counts and cooldowns immediately
						EchoesOnMaps[sendMap] = (EchoesOnMaps[sendMap] or 0) + 1
						local newCount = EchoesOnMaps[sendMap]
						mapCooldowns[sendMap] = os.time() + newCount * 60
						ReprojectDraftsOnMap(sendMap)
						SaveMapCooldowns()
						nextEcho = GetCurrentMapNext()
						
						FetchOwnEchoes()  --refresh written echoes
						FetchInfo()  --refetch cooldown/baseCooldown which will reproject
					
						--auto mark read across maps when it sends the draft
						local currentMap = game.GetMap()
						if sendMap ~= currentMap then
							readMapCounts[sendMap] = (readMapCounts[sendMap] or 0) + 1
							SaveReadMapCounts()
						end
						
						--remove dummy only on success from echoes table (drafts not in real logic)
						for i = #echoes, 1, -1 do
							if echoes[i].isDraft and echoes[i].draftId == readyDraft.tempId then
								table.remove(echoes, i)
								break
							end
						end
						
						SaveDrafts()
					else
						--failure: restore draft and handle cooldown misalignment locally
						table.insert(drafts, index, readyDraft)
						local map = sendMap
						local count = EchoesOnMaps[map] or 0
						local projectedNext = os.time() + count * 60
						mapCooldowns[map] = projectedNext
						ReprojectDraftsOnMap(map)
						SaveMapCooldowns()
						if code == 401 then
							EchoNotify("Auth expired during auto-send. Please log in again.")
							authToken = nil
						else
							EchoNotify("Auto-send failed (code " .. code .. "). Draft preserved.")
						end
						print("Auto-send failed: Code " .. code .. ", Body: " .. (body or "nil"))
					end
				end, function(error)
					table.insert(drafts, index, readyDraft)
					readyDraft.sendTime = readyDraft.sendTime + 60
					for _, draft in ipairs(drafts) do
						if draft.map == sendMap then
							draft.sendTime = math.max(draft.sendTime, readyDraft.sendTime)
						end
					end
					SaveDrafts()
					EchoNotify("Auto-send network error: " .. error)
					print("Auto-send network error: " .. error)
				end, {authorization = authToken})
				
				nextEcho = GetCurrentMapNext()
			end
		end
	end)
end)

--draft persistence functions
function LoadDrafts()
	local loaded = file.ReadOrCreate("echoesbeyond/drafts.json")
	drafts = {}
	for i, draftData in ipairs(loaded) do
		if draftData.text and draftData.text:Trim() ~= "" and #drafts < 3 then
			local pos_table = draftData.pos
			local pos = Vector(pos_table[1] or 0, pos_table[2] or 0, pos_table[3] or 0)
			local sendTime = draftData.sendTime or os.time()
			local newDraft = {
				text = draftData.text,
				pos = pos,
				timestamp = draftData.timestamp or os.time(),
				tempId = draftData.tempId,
				map = draftData.map or game.GetMap(),
				sendTime = sendTime
			}
			table.insert(drafts, newDraft)
			
			--add dummy echo for loaded drafts only if map matches
			local curTime = CurTime()
			local currentMap = game.GetMap()
			if draftData.map == currentMap then
				local dummyEcho = CreateDummyEcho(draftData.text, pos, draftData.tempId, curTime)
				table.insert(echoes, dummyEcho)
			end
		end
	end
	IDsort()
	
	nextEcho = GetCurrentMapNext()
end


function LoadNextEcho()
	local loaded = file.Read("echoesbeyond/nextecho.txt")
	if loaded then
		local loadedTime = tonumber(loaded) or 0
		nextEcho = math.max(nextEcho, loadedTime)
		persistedNextEcho = loadedTime
	end
end



function SaveDrafts()
	local validDrafts = {}
	for _, draft in ipairs(drafts) do
		if draft.text and draft.text:Trim() ~= "" then
			table.insert(validDrafts, draft)
		end
	end
	drafts = validDrafts
	file.Write("echoesbeyond/drafts.json", util.TableToJSON(drafts, true))
end

function CreateDummyEcho(text, pos, tempId, curTime)
	local dummyEcho = {
		angle = Angle(0, 0, 90),
		creationTime = curTime,
		soundActive = false,
		drawPos = Vector(pos),
		explicit = false,
		special = false,
		isOwner = true,
		failed = false,
		loading = false,
		pos = pos,
		readTime = 0,
		id = -1,
		read = false,
		text = text,
		active = 0,
		init = 0,
		color = Color(219, 157, 51),
		light_color = Color(220, 146, 18),
		skin = "blueprint",
		isDraft = true,
		draftId = tempId
	}
	return dummyEcho
end

function CreateEcho(message, pos, isDraft)
	message = string.Trim(message)
	if (message == "") then return end

	-- Remove newlines
	message = string.gsub(message, "\n", " ")

	-- Enforce echo uniqueness (check against existing echoes AND drafts)
	local allTexts = {}
	for _, echo in ipairs(echoes) do
		if not echo.isDraft then
			allTexts[string.lower(echo.text)] = true
		end
	end
	for _, draft in ipairs(drafts) do
		allTexts[string.lower(draft.text)] = true
	end

	if allTexts[string.lower(message)] then
		EchoNotify("A good message does not get lost in the noise. Your Echo must be unique.")
		return
	end

	local client = LocalPlayer()
	local isOffensive = IsOffensive(message)
	local curTime = CurTime()
	local usePos = pos or createPos or (client:GetPos() + Vector(0, 0, 32))

	local map = game.GetMap()
	local currentMapNext = GetCurrentMapNext()

	local enableDrafts = GetConVar("echoes_enable_drafts"):GetBool()

	if not enableDrafts or currentMapNext <= os.time() then
		if currentMapNext > os.time() then
			EchoNotify("A good message bides its time. You must wait another " .. string.NiceTime(currentMapNext - os.time()) .. " before creating a new Echo.")
			return
		end
		isDraft = false
	else
		if #drafts >= 3 then
			local minWait = math.huge
			for _, draft in ipairs(drafts) do
				minWait = math.min(minWait, math.max(0, draft.sendTime - os.time()))
			end
			EchoNotify("You have reached the maximum of 3 drafts. Please delete a draft from Personal Echoes or wait for auto-send in " .. string.NiceTime(minWait) .. ".")
			return
		end

		local tempId = "draft_" .. curTime .. "_" .. GenerateHex():sub(1, 8)
		local newDraft = {
			text = message,
			pos = usePos,
			timestamp = os.time(),
			tempId = tempId,
			map = map,
			sendTime = 0
		}
		table.insert(drafts, newDraft)
		ReprojectDraftsOnMap(map)
		SaveDrafts()
		local newSendTime = newDraft.sendTime
		EchoNotify("Saved as draft (" .. #drafts .. "/3). It will be sent automatically in " .. string.NiceTime(newSendTime - os.time()) .. ".")
		EchoSound("echo_create")

		local dummyEcho = CreateDummyEcho(message, usePos, tempId, curTime)
		table.insert(echoes, dummyEcho)
		IDsort()
		nextEcho = GetCurrentMapNext()
		return
	end

	-- Create the echo in anticipation of the server response
	local DefaultSkin = "default"
	echoes[#echoes + 1] = {
		angle = Angle(0, 0, 90),
		creationTime = curTime,
		soundActive = false,
		drawPos = Vector(usePos),
		explicit = false,
		special = false,
		isOwner = true, -- Mark as owner for new echoes
		failed = false,
		loading = true,
		pos = usePos,
		readTime = 0,
		id = curTime,
		read = false,
		text = message,
		active = 0,
		init = 0,
		skin = DefaultSkin
	}

	EchoSound("echo_create")

	http.Post("https://resonance.flatgrass.net/note/create", {
		map = game.GetMap(),
		pos = usePos.x .. "," .. usePos.y .. "," .. usePos.z,
		comment = message
	}, function(body, _, _, code)
		if (code != 200) then
			if (code == 401) then
				EchoNotify("Your authentication token has expired. Please log in again.")
				authToken = nil
			else
				EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))
			end

			local echo = echoes[#echoes]
			echo.explicit = true -- Just to make it red
			echo.loading = false
			echo.failed = true

			timer.Simple(3, function()
				echoes[#echoes] = nil
			end)

			return
		end

		local map = game.GetMap()
		EchoesOnMaps[map] = (EchoesOnMaps[map] or 0) + 1
		local newCount = EchoesOnMaps[map]
		mapCooldowns[map] = os.time() + newCount * 60
		ReprojectDraftsOnMap(map)
		SaveMapCooldowns()
		nextEcho = GetCurrentMapNext()
		
		FetchOwnEchoes()
		FetchInfo()
		
		local currentMap = game.GetMap()
		readMapCounts[currentMap] = (readMapCounts[currentMap] or 0) + 1
		SaveReadMapCounts()
		
		if (isOffensive) then
			local profanity = GetConVar("echoes_profanity")
			profanity:SetBool(true)
		end
		
	end, function()
		local echo = echoes[#echoes]
		echo.explicit = true -- Just to make it red
		echo.loading = false
		echo.failed = true

		timer.Simple(3, function()
			echoes[#echoes] = nil
		end)
	end, {authorization = authToken})
end

function GetProjectedDraftSendTime(map)
	if not map then map = game.GetMap() end
	local currentTime = os.time()
	local nextSlot = mapCooldowns[map] or currentTime
	local waitToNext = nextSlot - currentTime
	if waitToNext < 0 then 
		waitToNext = 0 
		nextSlot = currentTime 
	end
	local baseK = math.floor(waitToNext / 60)
	local draftsOnMap = {}
	for _, d in ipairs(drafts) do
		if d.map == map then
			table.insert(draftsOnMap, d)
		end
	end
	table.sort(draftsOnMap, function(a, b) return a.timestamp < b.timestamp end)
	local thisSend = nextSlot
	for i = 1, #draftsOnMap do
		thisSend = thisSend + 60 * (baseK + i)
	end
	return thisSend
end
