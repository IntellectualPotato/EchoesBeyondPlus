
-- Create echoes
if (SERVER) then
	util.AddNetworkString("echoCreateEcho")
	util.AddNetworkString("EchoGiveInfo")

	hook.Add("KeyPress", "echoes_create_KeyPress", function(client, key)
		if (key != IN_RELOAD) then return end
		local bypass = GetConVar("echoes_bypasschecks"):GetBool()

-- Prevent creating echoes too close to any spawn points
			for _, spawn in ipairs(ents.FindByClass("info_player_start")) do
				if (client:GetShootPos():DistToSqr(spawn:GetPos()) >= 10000) then continue end

				if bypass then EchoNotify(client, "Bypassed spawnPoint check.") continue end

				EchoNotify(client, "A good message gives breathing room to those beyond. You are too close to a spawn point.")

				return
			end

			-- Prevent creating echoes outside the world
			if (!util.IsInWorld(client:GetPos())) then

				if bypass then EchoNotify(client, "Bypassed void check.") else EchoNotify(client, "A good message is grounded in reality. You are outside the world.") return end

			end

			-- Prevent creating echoes in the air
			if (!client:IsOnGround()) and not (!util.IsInWorld(client:GetPos())) then

				if bypass then EchoNotify(client, "Bypassed ground check.") else EchoNotify(client, "A good message is built on solid ground. You are in the air.") return end

			end

			net.Start("echoCreateEcho")
			net.Send(client)
		end)
else
	createPos = vector_origin

	function CreateEcho(message)
		message = string.Trim(message)
		if (message == "") then return end

		-- Remove newlines
		message = string.gsub(message, "\n", " ")

		-- Enforce echo uniqueness
		for _, echo in ipairs(echoes) do
			if (string.lower(message) != string.lower(echo.text)) then continue end

			EchoNotify("A good message does not get lost in the noise. Your Echo must be unique.")

			return
		end

		local client = LocalPlayer()
		local isOffensive = IsOffensive(message)
		local curTime = CurTime()

		-- Create the echo in anticipation of the server response
		echoes[#echoes + 1] = {
			angle = Angle(0, 0, 90),
			creationTime = curTime,
			soundActive = false,
			drawPos = Vector(createPos),
			explicit = false,
			special = false,
			isOwner = false,
			failed = false,
			loading = true,
			pos = createPos,
			readTime = 0,
			id = curTime,
			read = false,
			text = message,
			active = 0,
			init = 0
		}

		EchoSound("echo_create")

		http.Post("https://resonance.flatgrass.net/note/create", {
			map = game.GetMap(),
			pos = createPos.x .. "," .. createPos.y .. "," .. createPos.z,
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

			FetchOwnEchoes()
			FetchInfo()

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

	net.Receive("echoCreateEcho", function()
		if (!authToken) then
			vgui.Create("echoAuthMenu")

			return
		end

		if (nextEcho > os.time()) then
			EchoNotify("A good message bides its time. You must wait another " .. (string.NiceTime(nextEcho - os.time())) .. " before creating a new Echo.")

			return
		end

		local client = LocalPlayer()
		createPos = client:GetPos() + Vector(0, 0, 32)

		-- Prevent creating echoes too close to other echoes
		for _, echo in ipairs(echoes) do
			if (echo.explicit) then continue end
			if ((client:GetPos() + Vector(0, 0, 32)):Distance(echo.pos) >= 75) then continue end

			EchoNotify("A good message needs an identity of its own. You are too close to another Echo.")

			return
		end

		vgui.Create("echoEntry")
	end)
end
