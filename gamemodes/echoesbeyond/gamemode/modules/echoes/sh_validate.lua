
-- Validates new Echoes
if (SERVER) then
	util.AddNetworkString("echoValidateEchoes")

	net.Receive("echoValidateEchoes", function(_, client)
		local requestID = net.ReadUInt(8)
		local numEchoes = net.ReadUInt(12)
		local voidResponse = {}
		local airResponse = {}

		for i = 1, numEchoes do
			local x = net.ReadInt(16)
			local y = net.ReadInt(16)
			local z = net.ReadInt(16)
			local echoPos = Vector(x, y, z)
			local trace = util.TraceLine({
				start = echoPos,
				endpos = echoPos + Vector(0, 0, -9999999)
			})

			if (util.IsInWorld(echoPos)) then
				if (echoPos:DistToSqr(trace.HitPos) <= 1050) then continue end
				local ground_z = trace.HitPos.z + 32

				airResponse[i] = echoPos.z - ground_z -- echo height off ground
			else
				voidResponse[i] = true
			end
		end

		-- max transmittable echo responses = 4094 ((65533 - 20 bit header) / 16 bits per echo)
		net.Start("echoValidateEchoes")
			net.WriteUInt(requestID, 8)
			net.WriteUInt(numEchoes, 12)

			-- each response echo is 28 bits
			for i = 1, numEchoes do				
				net.WriteBool(voidResponse[i] == true) --1 bit
				net.WriteUInt(airResponse[i] or 0, 15) --15 bits (max 32767 units [max map size along any axis])
			end
		net.Send(client)
	end)
else
	CreateClientConVar("echoes_enablevoidechoes", "0")
	CreateClientConVar("echoes_enableairechoes", "1")

	-- max transmittable echo requests = 1364 ((65533 - 20 bit header) / 48 bits per echo)
	local MAX_ECHOES_TO_SEND = 1364

	local requestHookName = "echoesPumpValidateRequests"
	local validateRequests = {}
	local numPendingRequests = 0
	local nextRequestID = 0
	local nextBatchSendTime = 0

	-- Send a batch of echoes to the server for validation
	local function SendValidateBatch(batch, requestID)
		net.Start("echoValidateEchoes")
		net.WriteUInt((requestID-1) % 255, 8)
		net.WriteUInt(#batch, 12)

		-- 48 bits per echo
		for i = 1, #batch do
			local x, y, z = batch[i].pos:Unpack()

			net.WriteInt(x, 16)
			net.WriteInt(y, 16)
			net.WriteInt(z, 16)
		end

		net.SendToServer()
	end

	-- Pumps the batch queue
	-- Sends a single request to the server every second
	local function ServiceBatchQueue()
		if (nextBatchSendTime > CurTime()) then return end -- Only send one request per second
		nextBatchSendTime = CurTime() + 1

		-- Find the next unsent request
		for i = 1, #validateRequests do
			local request = validateRequests[i]
			if (request.sent) then continue end

			-- Send it to the server
			SendValidateBatch(request.batch, i)
			request.sent = true

			break -- Only sending one request per think
		end
	end

	-- Queue up an array of echo markers {id, pos} to be sent to the server
	function ValidateEchoes(inEchoes)
		if (#inEchoes == 0) then return end -- Nothing to queue

		-- Spin up request pump to send pending requests
		if (numPendingRequests == 0) then
			hook.Add("Think", requestHookName, ServiceBatchQueue) 
		end

		local base = 0
		
		-- Queue up as many batches as needed
		while base <= #inEchoes do
			local batch = {}
			local batchSize = math.min(MAX_ECHOES_TO_SEND, #inEchoes)
			local requestID = nextRequestID + 1
			nextRequestID = nextRequestID + 1

			-- 'batchSize' echoes into batch
			for i = 1, batchSize do batch[i] = inEchoes[base + i] end
			base = base + batchSize

			numPendingRequests = numPendingRequests + 1
			validateRequests[requestID] = {
				batch = batch,
				sent = false,
				received = false,
			}
		end
	end

	net.Receive("echoValidateEchoes", function()
		local echoesByID = {}

		-- Lookup table to currently active list of echoes
		for _, echo in ipairs(echoes) do echoesByID[echo.id] = echo end

		local requestID = net.ReadUInt(8)+1
		local numIDs = net.ReadUInt(12)
		local request = validateRequests[requestID]
		local validatedEchoes = request.batch

		-- Just to ensure the counts match (they should)
		assert(numIDs == #validatedEchoes, "Echo count mismatch on validate!")

		-- Get validated data from server and write to each echo
		for i = 1, numIDs do
			local inVoid = net.ReadBool()
			local airHeight = net.ReadUInt(15)

			local echo = echoesByID[validatedEchoes[i].id]
			if (echo == nil) then continue end

			echo.inVoid = inVoid
			echo.airHeight = airHeight
		end

		numPendingRequests = numPendingRequests - 1
		request.received = true

		-- Stop request pump once everything has been received
		if (numPendingRequests != 0) then return end

		hook.Remove("Think", requestHookName, ServiceBatchQueue)
	end)
end
