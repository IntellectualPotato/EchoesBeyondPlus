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
IDsort()

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
local empty = Material("echoesbeyond/nothing.png", "mips")
local lightRenderDist = 3000000 -- How far the dynamic light should render
local activationDist = 6500 -- How close the player should be to activate the echo
local echoFadeDist = 2500 -- How far the echo should start fading
local echoToGroundFrac = 0

resource.AddSingleFile("addons/EchoesBeyondPlus/resource/fonts/8bitoperator_jve.ttf")
surface.CreateFont("utdr_font", {
	font = "8bitoperator JVE",
	size = 25,
	antialias = false,
	extended = true,
	shadow = true,
	outline = true
})

resource.AddSingleFile("addons/EchoesBeyondPlus/resource/fonts/Pixelmax-Regular.ttf")
surface.CreateFont("vp_font", {
	font = "Pixelmax",
	size = 23,
	antialias = false,
	extended = true,
	shadow = true,
	rotary = true,
	outline = true
})

local TBG = Material("echoesbeyond/Skins/TBGnote.png", "mips")
local TBGsnd = {}
for i = 1,11 do
	table.insert(TBGsnd, tostring("TBG/"..i))
end

--example with all valid parameters
--[[
 ["example"] = {
        mat1 = Material("echoesbeyond/Skins/example.png", "mips"), --mips isnt 100% needed	
        mat2 = Material("echoesbeyond/Skins/example.png", "mips"),
        dotmat = Material("echoesbeyond/Skins/example.png", "mips"),
		mat_read = Material("echoesbeyond/Skins/example.png", "mips"),
		dotWave = 100,
        sound = "echo_activate",
        color = Color(150, 255, 255),
		color_light = Color(150, 255, 255),
        point = false,
		font = "TargetID"
    },

	 ["default"] = {
        mat1 = echoMat,
        mat2 = echoBlankMat,
        dotmat = echoDotSingleMat,
		dotWave = 100,
        sound = "echo_activate",
        color = Color(150, 255, 255),
        point = false,
		font = "TargetID"
    },

]]

local skins = {
    ["default"] = {
        mat1 = echoMat,
        mat2 = echoBlankMat,
        dotmat = echoDotSingleMat,
    },
    ["star"] = {
        mat1 = Material("echoesbeyond/Skins/starecho.png", "mips"),
        mat2 = Material("echoesbeyond/Skins/starecho_blank.png", "mips"),
        dotmat = echoDotSingleMat,
        sound = "echo_activate_star",
    },
	["tbg"] = {
        mat1 = TBG,
        mat2 = TBG,
        dotmat = empty,
        sound = TBGsnd,
        color = Color(140, 245, 245),
	},
	["UTDR"] = {
        mat1 = Material("echoesbeyond/Skins/UTDRsoul2.png"),
        mat2 = Material("echoesbeyond/Skins/UTDRsoul.png"),
        dotmat = {
            mat = Material("echoesbeyond/Skins/pixeldot.png"),
            posOffset = Vector(0, 0, 1),
            scale = 0.022,
            x_coords = {-1200+10, -960, -720-10}
        },
		dotWave = 50,
        sound = "utdr_spell",
        color = Color(100, 200, 255),
        point = true,
		font = "utdr_font"
    },
	["VoidPlaces"] = {
        mat1 = Material("echoesbeyond/Skins/vpecho.png", "mips"),
        mat2 = Material("echoesbeyond/Skins/vpecho_blank.png", "mips"),
        dotmat = Material("echoesbeyond/Skins/vpecho_dot.png"),
		mat_read = Material("echoesbeyond/Skins/vpecho_read.png", "mips"),
        sound = "echo_activate_vp",
        color = Color(200, 200, 200),
		color_light = Color(255, 95, 255),
		font = "vp_font"
    },
}

local function getSkin(echo)
	return skins[echo.skin]
end

local mapSkins = {
	["gm_mttresort"] = "UTDR",
	["ttt_mttresort_v2"] = "UTDR",
	["gm_deltarune_card_castle"] = "UTDR",
	["gm_deltarune"] = "UTDR",
	["gm_finalcorridor"] = "UTDR",
	["gm_voidplaces"] = "VoidPlaces",
	["otherside"] = "VoidPlaces"
}

local mapPrefixSkins = {
	["tbg_"] = "tbg",
	["vp_"] = "VoidPlaces"
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
		local skin = getSkin(echo)
		local font = (skin and skin.font) or "TargetID"

		-- If text is already cached with the correct font, skip it
		if (echo.cachedText and echo.cachedFont == font) then continue end
		echo.cachedFont = font -- Store which font was used for caching

		local text = echo.text
		if (disableSigning) then text = RemoveSigning(text) end

		local words = string.Explode(" ", text)
		local lines = {}
		local line = ""

		surface.SetFont(font) -- Use the correct font for measuring text size

		for j = 1, #words do
			local word = words[j]

			if (surface.GetTextSize(line .. " " .. word) > 512) then
				table.insert(lines, line)
				line = word
			else
				line = (line == "" and word or line .. " " .. word)
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

		if (dot > 0) then continue end

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
						local seq = idToSequential[echo.id] or -1
						echo.skin = (seq == 1 or echo.special) and "star" or DefaultSkin
						local skin = getSkin(echo)
						EchoSound(istable(skin.sound) and skin.sound[math.random(1, #skin.sound)] or skin.sound or "echo_activate", echo.special and math.random(115, 125) or echo.explicit and math.random(65, 75) or math.random(95, 105), echo.read and 0.4 or 1)
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
	local curTimeSpeed = curTime * 1.5
	local showDlights = GetConVar("echoes_dlights"):GetBool()
	local DlightBright = GetConVar("echoes_dlights_brightness"):GetInt()
	local enableAir = GetConVar("echoes_enableairechoes"):GetBool()
	local drawColor = Color(0, 0, 0)

	echoToGroundFrac = Lerp(frameTime * 2, echoToGroundFrac, enableAir and 0 or 1)

	ComputeSqrEchoDist(clientPos)
	UpdateEchoInteractions(echoes, curTimeSpeed, frameTime)
	local sortedEchoes = GetSortedVisibleEchoes()
	local echoCount = #sortedEchoes
	UpdateEchoRotations(sortedEchoes, frameTime)

	for i = 1, echoCount do
		local echo = sortedEchoes[i]
		local seq = idToSequential[echo.id] or -1
		echo.skin = (seq == 1 or echo.special) and "star" or DefaultSkin
	end

	UpdateEchoTextCache(sortedEchoes)

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

		if (read and !showRead) then
			echo.readTime = echo.readTime or curTime

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

		if (echo.init == 0) then continue end

		local loading = echo.loading
		echo.z_offset = echo.z_offset or 0

		local ex,ey,ez = GetEchoPosition(echo)
		__vsetunpacked(echo.drawPos, ex,ey,ez + echo.z_offset)

		if (partyMode) then
			echo.partyOffsetLerp = echo.partyOffsetLerp or Vector()
			echo.partyOffsetLerp = LerpVector(frameTime * 3, echo.partyOffsetLerp, (echo.partyOffset or Vector(0, 0, 0)))
			__vadd(echo.drawPos, echo.partyOffsetLerp)
			lastPartyModeTime = curTime
		elseif lastPartyModeTime ~= 0 and curTime - lastPartyModeTime < 10 then
			echo.partyOffsetLerp = echo.partyOffsetLerp or Vector()
			__vmul(echo.partyOffsetLerp, math.max(1 - frameTime * 3, 0))
			__vadd(echo.drawPos, echo.partyOffsetLerp)
		end

		local alpha = (math.Clamp((echoDistSqr - echoFadeDist / 2) / echoFadeDist, 0, 1) * 255) * echo.init
		local special = echo.special
		local active = echo.active
		local explicit = echo.explicit
		local skin = getSkin(echo)
		local font = (skin and skin.font) or "TargetID" -- Get the font for this skin

		if (skin.point) then
			render.PushFilterMag(TEXFILTER.POINT)
			render.PushFilterMin(TEXFILTER.POINT)
		else
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		end

		local r, g, b
		local rDraw, gDraw, bDraw

		if (not read and not loading) then
			if (special) then
				r, g, b = 255, 255 * active, 255
				rDraw, bDraw = 200 + 55 * active, 200 + 55 * active
				gDraw = 255 * active
			elseif (explicit) then
				r, g, b = 255, 25 + 230 * active, 25 + 230 * active
				rDraw = 255
				gDraw, bDraw = 50 + 205 * active, 50 + 205 * active
			elseif (bOwner) then
				r, g, b = 255, 255, 255 * active
				rDraw, gDraw = 255, 255
				bDraw = 255 * active
			else
				local baseDrawColor = skin.color or Color(150, 255, 255)
				local baseDrawColor_light = skin.color_light or baseDrawColor
				local baseDlightColor = Color(math.max(0, baseDrawColor_light.r - 50), baseDrawColor_light.g, baseDrawColor_light.b)

				r = Lerp(active, baseDlightColor.r, 255)
				g = Lerp(active, baseDlightColor.g, 255)
				b = Lerp(active, baseDlightColor.b, 255)

				rDraw = Lerp(active, baseDrawColor.r, 255)
				gDraw = Lerp(active, baseDrawColor.g, 255)
				bDraw = Lerp(active, baseDrawColor.b, 255)
			end
		else
			r, g, b = 25 + 230 * active, 25 + 230 * active, 25 + 230 * active
			rDraw, gDraw, bDraw = 100 + 155 * active, 100 + 155 * active, 100 + 155 * active
		end

		if (echoDistSqr <= lightRenderDist and showDlights and i >= (echoCount - (32 - dLightCount))) then
			local dLight = DynamicLight(echo.id)
			if (dLight) then
				dLight.Pos = echo.drawPos
				dLight.r = partyMode and echo.partyColor and echo.partyColor.r or r
				dLight.g = partyMode and echo.partyColor and echo.partyColor.g or g
				dLight.b = partyMode and echo.partyColor and echo.partyColor.b or b
				dLight.Brightness = DlightBright
				dLight.Size = 256 * (((lightRenderDist - echoDistSqr) / lightRenderDist) * echo.init) * (alpha / 255)
				dLight.Decay = 1000
				dLight.DieTime = curTime + 0.1
			end
		end

		drawColor:SetUnpacked(rDraw, gDraw, bDraw, alpha)

ComputeEchoMtx(echo_mtx, echo.drawPos, echo._angle, 0.1)
		cam.PushModelMatrix(echo_mtx, true)
		
		local finalColor = partyMode and echo.partyColor or drawColor
		
		--logic for skins with a custom read texture
		if (skin.mat_read) then
			echo.readTransition = echo.readTransition or (read and 1 or 0)
			local targetReadTransition = (read and not bOwner) and 1 or 0
			echo.readTransition = Lerp(frameTime * 2.5, echo.readTransition, targetReadTransition)
			
			-- Draw base (normal) texture, fading out
			if (echo.readTransition < 1) then
				surface.SetDrawColor(finalColor.r, finalColor.g, finalColor.b, finalColor.a * (1 - echo.readTransition))
				surface.SetMaterial(skin.mat1)
				surface.DrawTexturedRect(-96, -96, 192, 192)
			end
			
			if (echo.readTransition > 0) then
				surface.SetDrawColor(finalColor.r, finalColor.g, finalColor.b, finalColor.a * echo.readTransition)
				surface.SetMaterial(skin.mat_read)
				surface.DrawTexturedRect(-96, -96, 192, 192)
			end
			
			--overlay the active/blank texture
			if (loading or active > 0) then
				local activeAlpha = loading and finalColor.a or (finalColor.a * active)
				surface.SetDrawColor(finalColor.r, finalColor.g, finalColor.b, activeAlpha)
				surface.SetMaterial(skin.mat2)
				surface.DrawTexturedRect(-96, -96, 192, 192)
			end
		
		--Default behaviour
		else
			surface.SetDrawColor(finalColor)
			surface.SetMaterial((loading or active > 0) and skin.mat2 or skin.mat1)
			surface.DrawTexturedRect(-96, -96, 192, 192)
		end
		
		if (loading) then
			surface.SetDrawColor(0, 0, 0, alpha)
			surface.SetMaterial(echoDotsMat)
			surface.DrawTexturedRectRotated(0, 0, 192, 192, curTime * -350)
		end

		if (alpha ~= 0 and active ~= 0) then
			cam.IgnoreZ(true)

			for j = 1, #echo.cachedText do
				draw.SimpleText(echo.cachedText[j], font, 1, -(150 + j * 15), Color(0, 0, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(echo.cachedText[j], font, 0, -(151 + j * 15), Color(255, 255, 255, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			if GetConVar("echoes_debuginfo"):GetBool() then
				IDsort()
				local seq = idToSequential[echo.id] or -1

				local idStr = (echo.id == 1 and "➀" or tostring(echo.id))
				if echo.id % 1000 == 0 then
					idStr = idStr .. "★"
				elseif echo.id % 100 == 0 then
					idStr = idStr .. "☆"
				end

				local seqStr = (seq == 1 and "➀" or tostring(seq))
				if seq % 1000 == 0 then
					seqStr = seqStr .. "★"
				elseif seq % 100 == 0 then
					seqStr = seqStr .. "☆"
				end

				local txt = "ID: " .. idStr .. " | " .. seqStr

				draw.SimpleText(txt, font, 1, 100, Color(0, 0, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(txt, font, 0, 101, Color(233, 233, 0, math.min(active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

				if echo.inVoid then
					draw.SimpleText("VOID", font, 0, 80, Color(255, 100, 100, math.min(echo.active * 255, alpha)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

			end

			cam.IgnoreZ(false)
		end


		cam.PopModelMatrix()

		if (alpha ~= 0 and active ~= 0) then
			local dot_config = skin.dotmat
			local is_custom = (type(dot_config) == "table" and dot_config.mat)

			local dot_material = is_custom and dot_config.mat or dot_config
			local pos_offset   = is_custom and dot_config.posOffset or Vector(0, 0, 0)
			local scale        = is_custom and dot_config.scale or 0.01
			local x_coords     = is_custom and (dot_config.x_coords or {}) or {-1240, -960, -680}

			ComputeEchoMtx(echo_mtx, echo.drawPos + pos_offset, echo._angle, scale)
			cam.PushModelMatrix(echo_mtx, true)

			surface.SetMaterial(dot_material)

			local dotWave = skin.dotWave or 100

			local z = (0.5 * math.sin(curTimeSpeed)) * active * dotWave
			surface.DrawTexturedRect(x_coords[1] or 0, -960 + z, 1920, 1920)

			local z = (0.5 * math.sin(curTimeSpeed + 20)) * active * dotWave
			surface.DrawTexturedRect(x_coords[2] or 0, -960 + z, 1920, 1920)

			local z = (0.5 * math.sin(curTimeSpeed + 40)) * active * dotWave
			surface.DrawTexturedRect(x_coords[3] or 0, -960 + z, 1920, 1920)

			cam.PopModelMatrix()
		end

		render.PopFilterMag()
		render.PopFilterMin()
	end
end)