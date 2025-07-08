local __vtab = FindMetaTable("Vector")
local __vunpack = __vtab.Unpack
local __vset = __vtab.Set
local __vadd = __vtab.Add
local __vmul = __vtab.Mul
local __vsetunpacked = __vtab.SetUnpacked

local __mtab = FindMetaTable("VMatrix")
local __msetunpacked = __mtab.SetUnpacked

local echo_mtx = Matrix()
local __cos = math.cos
local __sin = math.sin

CreateClientConVar("echoes_showread", "1")
CreateClientConVar("echoes_renderdist", "25000000")
CreateClientConVar("echoes_disablereadsys", "0")
CreateClientConVar("echoes_disablesigning", "0")
CreateClientConVar("echoes_gabenmode", "0")
CreateClientConVar("echoes_bypasschecks", "0")
CreateClientConVar("echoes_debuginfo", "0")

cvars.AddChangeCallback("echoes_disablesigning", function(name, old, new)
	for i = 1, #echoes do
		echoes[i].cachedText = nil
	end
end, "echoes_disablesigning")

local gabenNodeSounds = {
	"/gaben/al_intro",
	"/gaben/hl2_intro",
	"/gaben/l4d2_intro",
	"/gaben/l4d_intro",
	"/gaben/lc_intro",
	"/gaben/p2_intro"
}

local gabenIntroSounds = {
	"/gaben/al_node",
	"/gaben/ep1_node",
	"/gaben/ep2_node",
	"/gaben/hl2_node",
	"/gaben/l4d2_node",
	"/gaben/l4d_node",
	"/gaben/lc_node",
	"/gaben/p1_node",
	"/gaben/p2_node",
	"/gaben/tf2_node"
}

cvars.AddChangeCallback("echoes_gabenmode", function(name, old, new)
	if (new == "0") then return end

	EchoSound(table.Random(gabenNodeSounds), nil, 0.75)
end, "echoes_gabenmode")

local echoMat = Material("echoesbeyond/echo.png", "mips")
local echoBlankMat = Material("echoesbeyond/echo_blank.png", "mips")
local echoDotsMat = Material("echoesbeyond/echo_dots.png", "mips")
local echoDotSingleMat = Material("echoesbeyond/echo_dot_single.png", "mips")
local lightRenderDist = 3000000 -- How far the dynamic light should render
local activationDist = 6500 -- How close the player should be to activate the echo
local echoFadeDist = 2500 -- How far the echo should start fading
local echoToGroundFrac = 0

local idToSequential = {}
local function IDsort()
	table.sort(echoes, function(a, b)
		return a.id < b.id
	end)

	for i, entry in ipairs(echoes) do
		idToSequential[entry.id] = i
	end
end

local function GetEchoPosition(echo)
	local x, y, z = __vunpack(echo.pos)

	return x, y, z - (echo.airHeight or 0) * echoToGroundFrac
end

local function ComputeSqrEchoDist(origin)
	local v = Vector()

	for i = 1, #echoes do
		local echo = echoes[i]
		local x, y, z = GetEchoPosition(echo)

		__vsetunpacked(v,x, y, z)
		echo.distSqr = origin:DistToSqr(v)
	end
end

local function UpdateEchoTextCache(inEchoes)
	local disableSigning = GetConVar("echoes_disablesigning"):GetBool()

	for _, echo in ipairs(inEchoes) do
		if (echo.cachedText) then continue end -- Already cached

		-- Cache wrapped text to avoid recalculations
		local text = echo.text

		if (disableSigning) then text = RemoveSigning(text) end

		local words = string.Explode(" ", text)
		local lines = {}
		local line = ""

		for j = 1, #words do
			local word = words[j]

			if (surface.GetTextSize(line .. " " .. word) > 512) then
				table.insert(lines, line)

				line = word
			else
				line = (line == ""and word or line .. " " .. word)
			end
		end

		table.insert(lines, line)

		for j = 1, math.floor(#lines / 2)do
			lines[j], lines[#lines - j + 1] = lines[#lines - j + 1], lines[j]
		end

		echo.cachedText = lines
	end
end

local cameraData = { 
	cx = 0, cy = 0, cz = 0,
	fx = 0, fy = 0, fz = 0
}

local function EchoDistSortFunc(a,b) return a.distSqr > b.distSqr end
local function GetSortedVisibleEchoes()
	local renderVoidEchoes = GetConVar("echoes_enablevoidechoes"):GetBool()
	local cutOffDist = GetConVar("echoes_renderdist"):GetInt()
	local sortedEchoes = {}
	local cdata = cameraData
	local cx, cy, cz = cdata.cx, cdata.cy, cdata.cz
	local fx, fy, fz = cdata.fx, cdata.fy, cdata.fz

	for _, echo in ipairs(echoes) do
		if (echo.distSqr > cutOffDist) then continue end
		if (echo.inVoid and !renderVoidEchoes) then continue end

		local x, y, z = GetEchoPosition(echo)
		local dot = ((cx-x) * fx + (cy-y) * fy + (cz-z) * fz)

		if (dot > 0) then continue end -- Don't bother with anything behind the camera

		sortedEchoes[#sortedEchoes+1] = echo
	end

	table.sort(sortedEchoes, EchoDistSortFunc)

	return sortedEchoes
end

local function UpdateEchoRotations(inEchoes, dt)
	local lerpFactor = math.Clamp(dt * 5, 0, 1)
	local cdata = cameraData
	local cx, cy, cz = cdata.cx, cdata.cy, cdata.cz

	for _, echo in ipairs(inEchoes) do
		local px, py, pz = GetEchoPosition(echo)
		local a = math.atan2(px - cx, py - cy)
		local b = echo._angle or 0
		local d = ((a - b) + math.pi) % (math.pi * 2) - math.pi
		local t = b + (d < math.pi and d or d - (math.pi * 2))

		echo._angle = b * (1-lerpFactor) + t * lerpFactor
	end
end

local function UpdateEchoInteractions(inEchoes, curTimeSpeed, dt)
	local disableReadSys = GetConVar("echoes_disablereadsys"):GetBool()
	local breathLayer = math.sin(curTimeSpeed) * 0.5
	local activeZOffset = 24 + breathLayer
	local readZOffset = 20
	local gabenMode = GetConVar("echoes_gabenmode"):GetBool()
	local profanity = GetConVar("echoes_profanity"):GetBool()

	for _, echo in ipairs(inEchoes) do
		echo.z_offset = echo.z_offset or 0
		local read = echo.read and !disableReadSys
		local bOwner = echo.isOwner

		if (((echo.explicit and profanity) or !echo.explicit) and !echo.loading) then
			if (echo.distSqr < activationDist) then
				local active = math.min(echo.active + dt * 3, 1)

				local cameraZ = cameraData.cz
				local _, _, echoZ = echo.pos:Unpack()
				local heightDiff = cameraZ - echoZ -32

				echo.active = active
				echo.z_offset = Lerp(dt * 3, echo.z_offset, activeZOffset  + heightDiff)

				if (!echo.soundActive) then
					echo.soundActive = true

					if (gabenMode) then
						EchoSound(table.Random(gabenIntroSounds), nil, 0.75)
					else
						EchoSound("echo_activate", echo.special and math.random(115, 125) or echo.explicit and math.random(65, 75) or math.random(95, 105), echo.read and 0.4 or 1)
					end
				end

				if (active == 1 and !bOwner and !echo.read and !echo.special) then
					local savedData = ReadEchoes()
					savedData[#savedData + 1] = echo.id

					echo.read = true

					readEchoCount = readEchoCount + 1
					WriteEchoes(savedData)
				end
			else
				echo.active = math.max(echo.active - dt * 0.5, 0)
				echo.z_offset = Lerp(dt * 1.5, echo.z_offset, (read and -readZOffset or 0))

				if (echo.soundActive) then
					echo.soundActive = false
				end
			end
		end
	end
end

local function ComputeEchoMtx(mtx, pos, rot, size, z_offset)
    local px, py, pz = __vunpack(pos)
	local c,s = __cos(rot), __sin(rot)

    __msetunpacked(mtx,
    c * size, 0 * size, s * size, px,
    -s * size, 0 * size, c * size, py,
    0 * size, -1 * size, 0 * size, pz + (z_offset or 0),
    0,0,0,1)
end

local lastPartyModeTime = 0

hook.Add("PreDrawEffects", "echoes_render_PreDrawEffects", function(bDrawingDepth, bDrawingSkybox)
	if (bDrawingDepth or bDrawingSkybox) then return end

	local org, ang = EyePos(), EyeAngles()
	local fwd = ang:Forward()
	local d = cameraData
	d.cx, d.cy, d.cz = __vunpack(org)
	d.fx, d.fy, d.fz = __vunpack(fwd)

	local client = LocalPlayer()
	local clientPos = client:GetShootPos()
	local frameTime = FrameTime()
	local curTime = CurTime()
	local profanity = GetConVar("echoes_profanity"):GetBool()
	local showRead = GetConVar("echoes_showread"):GetBool()
	local disableReadSys = GetConVar("echoes_disablereadsys"):GetBool()
	local lerpFactor = math.Clamp(frameTime * 5, 0, 1)
	local curTimeSpeed = curTime * 1.5
	local readOffset = Vector(0, 0, 20)
	local showDlights = GetConVar("echoes_dlights"):GetBool()
	local enableAir = GetConVar("echoes_enableairechoes"):GetBool()
	local drawColor = Color(0, 0, 0)

	echoToGroundFrac = Lerp(frameTime * 2, echoToGroundFrac, enableAir and 0 or 1)

	surface.SetFont("TargetID") -- Set the font for text size calculations

	-- Compute squared distance to all echoes
	ComputeSqrEchoDist(clientPos)

	-- Update interactions with all echoes (relies on computed distances)
	UpdateEchoInteractions(echoes, curTimeSpeed, frameTime)

	-- Create a shallow copy of echoes and sort by distance (squared)
	local sortedEchoes = GetSortedVisibleEchoes()
	local echoCount = #sortedEchoes

	UpdateEchoRotations(sortedEchoes, frameTime)
	UpdateEchoTextCache(sortedEchoes)

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	for i = 1, echoCount do
		local echo = sortedEchoes[i]

		if (!echo.creationTime) then
			echo.creationTime = curTime + 0.01 * (echoCount - i)
		end

		if (echo.creationTime > curTime) then continue end

		local echoDistSqr = echo.distSqr
		local read = echo.read and !disableReadSys
		local bOwner = echo.isOwner
		if read and bOwner then read = false end

		-- Update initialization factor based on explicit flag and profanity setting
		if (read and !showRead) then
			echo.readTime = echo.readTime or curTime

			-- Fade out echo if it was read for more than 60 seconds
			if (curTime - echo.readTime > 60) then
				echo.init = math.max(echo.init - frameTime, 0)
			end
		else
			if ((echo.explicit and !profanity) or echo.failed) then
				echo.init = math.max(echo.init - frameTime, 0)
			elseif (echo.init < 1 and ((echo.explicit and profanity) or !echo.explicit) or disableReadSys) then
				echo.init = math.min(echo.init + frameTime, 1)
			end
		end

		if (echo.init == 0) then continue end -- Skip rendering if echo is not initialized

		local loading = echo.loading
		echo.z_offset = echo.z_offset or 0

		local ex,ey,ez = GetEchoPosition(echo)
		__vsetunpacked(echo.drawPos, ex,ey,ez + echo.z_offset)

		if (partyMode) then
			echo.partyOffsetLerp = echo.partyOffsetLerp or Vector()
			echo.partyOffsetLerp = LerpVector(frameTime * 3, echo.partyOffsetLerp, (echo.partyOffset or Vector(0, 0, 0)))
			__vadd(echo.drawPos, echo.partyOffsetLerp)
			lastPartyModeTime = curTime
		elseif lastPartyModeTime ~= 0 and curTime - lastPartyModeTime < 10 then -- for about 10 seconds after partymode, lerp party offset back to 0
			echo.partyOffsetLerp = echo.partyOffsetLerp or Vector()
			__vmul(echo.partyOffsetLerp, math.max(1 - frameTime * 3, 0))
			__vadd(echo.drawPos, echo.partyOffsetLerp)
		end

		local alpha = (math.Clamp((echoDistSqr - echoFadeDist / 2) / echoFadeDist, 0, 1) * 255) * echo.init
		local special = echo.special
		local active = echo.active
		local explicit = echo.explicit

		-- Render dynamic light if within render distance (using echo.pos for distance)
		if (echoDistSqr <= lightRenderDist and showDlights and i >= (echoCount - (32 - dLightCount))) then -- Source can only handle 32 dynamic lights, so that's the
			local r = !read and !loading and (special and 255 or explicit and 255 or bOwner and 255 or (100 + 155 * active)) or (25 + 230 * active) -- limit we use, minus the number of map-created dynamic lights
			local g = !read and !loading and (special and (255 * active) or explicit and (25 + 230 * active) or bOwner and 255 or 255) or (25 + 230 * active)
			local b = !read and !loading and (special and 255 or explicit and (25 + 230 * active) or bOwner and (255 * active) or 255) or (25 + 230 * active)

			local dLight = DynamicLight(echo.id)

			if (dLight) then
				dLight.Pos = echo.drawPos
				dLight.r = partyMode and echo.partyColor and echo.partyColor.r or r
				dLight.g = partyMode and echo.partyColor and echo.partyColor.g or g
				dLight.b = partyMode and echo.partyColor and echo.partyColor.b or b
				dLight.Brightness = 3
				dLight.Size = 256 * (((lightRenderDist - echoDistSqr) / lightRenderDist) * echo.init) * (alpha / 255)
				dLight.Decay = 1000
				dLight.DieTime = curTime + 0.1
			end
		end

		-- Draw the echo's texture and text
		local rDraw = !read and !loading and (special and (200 + 55 * active) or explicit and 255 or bOwner and 255 or (150 + 105 * active)) or (100 + 155 * active)
		local gDraw = !read and !loading and (special and (255 * active) or explicit and (50 + 205 * active) or bOwner and 255 or 255) or (100 + 155 * active)
		local bDraw = !read and !loading and (special and (200 + 55 * active) or explicit and (50 + 205 * active) or bOwner and (255 * active) or 255) or (100 + 155 * active)

		drawColor:SetUnpacked(rDraw, gDraw, bDraw, alpha)

		-- Main echo
		ComputeEchoMtx(echo_mtx, echo.drawPos, echo._angle, 0.1)
		cam.PushModelMatrix(echo_mtx, true)

		surface.SetDrawColor(partyMode and echo.partyColor or drawColor)
		surface.SetMaterial((loading or active > 0) and echoBlankMat or echoMat)
		surface.DrawTexturedRect(-96, -96, 192, 192)

		if (loading) then
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.SetMaterial(echoDotsMat)
			surface.DrawTexturedRectRotated(0, 0, 192, 192, curTime * -350)
		end

		if (alpha != 0 and active != 0) then
			cam.IgnoreZ(true)

			for j = 1, #echo.cachedText do
				draw.SimpleText(echo.cachedText[j], "TargetID", 1, -(150 + j * 15), Color(0, 0, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(echo.cachedText[j], "TargetID", 0, -(151 + j * 15), Color(255, 255, 255, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			if GetConVar("echoes_debuginfo"):GetBool() then
				IDsort()
			    local seq = idToSequential[echo.id] or -1
                --print(seq)
                local txt = "ID: " .. (echo.id == 1 and "➀" or echo.id) ..
                            (echo.id % 1000 == 0 or echo.id % 100 == 0 and "☆" and "★" or "") ..
                            "|" ..
                            (seq == 1 and "➀" or seq .. (seq % 1000 == 0 and "★" or seq % 100 == 0 and "☆" or ""))
                draw.SimpleText(txt, "TargetID", 1, 100, Color(0, 0, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText(txt, "TargetID", 0, 101, Color(233, 233, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                if echo.inVoid then
                	draw.SimpleText("VOID", "TargetID", 0, 20, Color(255, 100, 100, math.min(echo.active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

				cam.IgnoreZ(false)
			end
		end

		cam.PopModelMatrix()

		-- Animated dots
		if (alpha != 0 and active != 0) then
			-- Scaled down matrix for better integer coordinate animation
			ComputeEchoMtx(echo_mtx, echo.drawPos, echo._angle, 0.01)
			cam.PushModelMatrix(echo_mtx, true)

			surface.SetMaterial(echoDotSingleMat)

			local z = (0.5 * math.sin(curTimeSpeed)) * active * 100
			surface.DrawTexturedRect(-1240, -960 + z, 1920, 1920)

			local z = (0.5 * math.sin(curTimeSpeed + 20)) * active * 100
			surface.DrawTexturedRect(-960, -960 + z, 1920, 1920)

			local z = (0.5 * math.sin(curTimeSpeed + 40)) * active * 100
			surface.DrawTexturedRect(-680, -960 + z, 1920, 1920)

			cam.PopModelMatrix()
		end
	end

	render.PopFilterMag()
	render.PopFilterMin()
end)
