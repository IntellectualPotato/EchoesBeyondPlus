
-- Create echoes
if (SERVER) then
	util.AddNetworkString("echoCreateEcho")
	util.AddNetworkString("EchoGiveInfo")
    util.AddNetworkString("Echoes_ScaryMode_Toggled")

	hook.Add("KeyPress", "echoes_create_KeyPress", function(client, key)
		if (key != IN_RELOAD) then return end
		local bypass = GetConVar("echoes_bypasschecks"):GetBool()

        --prevent creating echoes while dead
        if client:Health() <= 0 then
            EchoNotify(client, "A good message needs a voice. You cannot create an Echo while dead.")
            return
        end

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

		net.Receive("Echoes_ScaryMode_Toggled", function(len, ply)
			local enabled = net.ReadBool()
			for _, sun in pairs(ents.FindByClass("env_sun")) do
				if enabled then
					sun:Fire("TurnOff")
				else
					sun:Fire("TurnOn")
				end
			end
		end)
else
	createPos = vector_origin

	--CreateEcho moved to cl_fetch.lua with draft support

	net.Receive("echoCreateEcho", function()
		if (!authToken) then
			vgui.Create("echoAuthMenu")
			return
		end

		local enableDrafts = GetConVar("echoes_enable_drafts"):GetBool()
		if not enableDrafts then
			if nextEcho > os.time() then
				EchoNotify("A good message bides its time. You must wait another " .. string.NiceTime(nextEcho - os.time()) .. " before creating a new Echo.")
				return
			end
		else
			if #drafts >= 3 then
				EchoNotify("Reached the maximum of 3 drafts. delete a draft from Personal Echoes or wait")
				return
			end
		end

		local client = LocalPlayer()
		createPos = client:GetPos() + Vector(0, 0, 32)

		-- Prevent creating echoes too close to other echoes
		for _, echo in ipairs(echoes) do
			if echo.id == -1 and not echo.isDraft then continue end
			if echo.explicit then continue end
			if (createPos:Distance(echo.pos) >= 75) then continue end

			EchoNotify("A good message needs an identity of its own. You are too close to another Echo.")
			return
		end

		vgui.Create("echoEntry")
	end)
end
