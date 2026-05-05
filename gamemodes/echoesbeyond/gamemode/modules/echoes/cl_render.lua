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

cvars.AddChangeCallback("echoes_disablesigning", function(name, old, new)
    for i = 1, #echoes do
        echoes[i].cachedText = nil
    end
end, "echoes_disablesigning")

cvars.AddChangeCallback("echoes_showsignaturecolors", function(name, old, new)
    ReloadEchoColors()
end, "echoes_showsignaturecolors")

cvars.AddChangeCallback("echoes_allowsigsown", function(name, old, new)
    ReloadEchoColors()
end, "echoes_allowsigsown")

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
local echoPinMat = Material("echoesbeyond/echo_pin.png", "mips")
local echoTranslateMat = Material("echoesbeyond/echo_translate.png", "mips")
local echoOptionMat = Material("echoesbeyond/echo_option.png", "mips")
local echoArrowMat = Material("echoesbeyond/echo_arrow.png", "mips") -- Added Arrow Material
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
        readcolor = Color(100, 100, 100),
        readcolor_light = Color(25, 25, 25),
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
		font = "vp_font",
	    readcolor = Color(100, 100, 100),
	    readcolor_light = Color(25, 25, 25),
	},
	["Apocalypse"] = {
        mat1 = Material("echoesbeyond/Skins/apocecho.png", "mips"),
        mat2 = Material("echoesbeyond/Skins/apocecho_blank.png", "mips"),
        dotmat = Material("echoesbeyond/Skins/apocecho_dot.png"),
        color = Color(220, 255, 230),
    },
	["hls"] = {
	    mat1 = Material("echoesbeyond/Skins/hlsecho.png"),
	    mat2 = Material("echoesbeyond/Skins/hlsecho_blank.png"),
		mat_read = Material("echoesbeyond/Skins/hlsecho_read.png", "mips"),
	    dotmat = {
	       mat = Material("echoesbeyond/Skins/hls_dot.png"),
	    	scale = 0.0024,
	       x_coords = {-1200-1000, -960, -720+1000}
	    },
	    sound = "echo_activate_hls",
		dotWave = 300,
	    color = Color(200, 200, 200),
		color_light = Color(255, 150, 150),
	    readcolor = Color(100, 100, 100),
	    readcolor_light = Color(25, 25, 25),
	},
	["blueprint"] = {
        mat1 = Material("echoesbeyond/Skins/echo_blueprint.png"),
        mat2 = Material("echoesbeyond/Skins/echo_blueprint_blank.png"),
		 dotmat = {
            mat = Material("echoesbeyond/Skins/echo_blueprint_dot.png"),
            x_coords = {-1200-75, -960, -720+80}
        },
    },
   }
   
   local signatureColors = {
    {color = Color(120, 200, 120), names = {"intellectualpotato", "i.p.", "intellecutalpotato", "intelelctualpotato"}}, --i suck at spelling my own name sometimes shush
    --{color = Color(20, 20, 200), names = {"m"}}, --Was legacy but i dont think its best to have 1 character signature colors
    {color = Color(80, 0, 50), names = {"aether"}},
    {color = Color(125, 64, 113), names = {"salithin"}}, --requested-new
    {color = Color(200, 50, 50), names = {"run", "run!!!"}},
    {color = Color(255, 105, 97), names = {"vivian"}},
    {color = Color(160, 100, 50), names = {"muffin"}},
    {color = Color(180, 180, 255), names = {"tomi"}},
    {color = Color(255, 115, 20), names = {"mari"}},
    {color = Color(5, 0, 5), names = {"dark"}},
    {color = Color(255, 117, 0), names = {"mark", "markku"}},
    {color = Color(170, 50, 170), names = {"akari"}},
    {color = Color(87, 59, 183), names = {"dodeca"}},
    {color = Color(100, 100, 150), names = {"lng1lnd"}},
    {color = Color(0, 255, 0), names = {"panton_cleo"}},
    {color = Color(255, 160, 232), names = {"skolli", "skoli"}},
    {color = Color(150, 41, 134), names = {"n.r."}}, --requested-new
    {color = Color(255, 115, 50), names = {"fish"}},
    {color = Color(0, 128, 128), names = {"lafta"}}, --requested-new
    {color = Color(255, 105, 180), names = {"pix"}}, --requested-new
    {color = Color(150, 150, 255), names = {"shimmer"}},
    {color = Color(60, 180, 60), names = {"gecko"}},
    {color = Color(65, 130, 95), names = {"den4ik17"}}, --requested-new
    {color = Color(90, 100, 255), names = {"echoblu"}},
	{color = Color(229, 175, 110), names = {"traya tyto"}},
	{color = Color(101, 165, 227), names = {"hazmat141"}}, --requested-new
	{color = Color(157, 0, 111), names = {"chlebiri"}}, --requested-new
	{color = Color(255, 110, 231), names = {"artanis"}}, --requested-new
	{color = Color(242, 242, 162), names = {"m.d."}}, --requested-new
    {color = Color(255,95,0), names = {"g3"}}, --requested-new
    {color = Color( 255, 255, 125), names = {"goldbrick"}}, --requested-new
   }
   
   local function GetSignature(text)
    local s, e = text:find("[%-~][^%-~]*$")
    if not s then return nil end

    local candidate = text:sub(s+1):match("^%s*(.-)%s*$")
    if candidate and candidate:match("^[A-Za-z]") and #candidate <= 30 then
    	return candidate:lower()
    end
    return nil
   end

   function GetSignatureColor(sig)
    for _, entry in ipairs(signatureColors) do
     for _, name in ipairs(entry.names) do
      if name == sig then return entry.color end
     end
    end
    return nil
   end
   
   local function getSkin(echo)
	return skins[echo.skin]
end

-- Maps Steam/GMod cl_language values to ISO 639-1 codes
local steamLangToISO = {
	english    = "en",
	russian    = "ru",
	german     = "de",
	french     = "fr",
	spanish    = "es",
	latam      = "es",
	portuguese = "pt",
	brazilian  = "pt",
	italian    = "it",
	dutch      = "nl",
	polish     = "pl",
	czech      = "cs",
	hungarian  = "hu",
	roumanian  = "ro",
	turkish    = "tr",
	greek      = "el",
	swedish    = "sv",
	norwegian  = "no",
	danish     = "da",
	finnish    = "fi",
	japanese   = "ja",
	korean     = "ko",
	koreana    = "ko",
	schinese   = "zh-CN",
	tchinese   = "zh-TW",
	thai       = "th",
	bulgarian  = "bg",
	ukrainian  = "uk",
	vietnamese = "vi",
	arabic     = "ar",
}

local function GetTranslateTargetLang()
	local steamLang = GetConVar("cl_language"):GetString():lower()

	return steamLangToISO[steamLang] or "en"
end

-- Offline language detection: Unicode script blocks + distinctive Latin diacritics
-- Returns an ISO 639-1 code if the language is detectable, or nil for plain ASCII / ambiguous text.
-- Uses raw UTF-8 byte arithmetic to avoid requiring the bit library.
-- I hate this with every fiber of my being and if it breaks I will kill myself
local function DetectTextScript(text)
	local i = 1
	local n = #text

	while i <= n do
		local b1 = text:byte(i)

		if (b1 < 0x80) then
			i = i + 1
		elseif (b1 >= 0xC2 and b1 <= 0xDF) then -- 2-byte UTF-8 sequence (U+0080 – U+07FF)
			local b2 = text:byte(i + 1) or 0x80

			if (b2 >= 0x80 and b2 <= 0xBF) then
				local cp = (b1 - 0xC0) * 64 + (b2 - 0x80)

				if (cp >= 0x0400 and cp <= 0x04FF) then return "ru" -- Cyrillic
				elseif (cp >= 0x0370 and cp <= 0x03FF) then return "el" -- Greek
				elseif (cp >= 0x0600 and cp <= 0x06FF) then return "ar" -- Arabic
				elseif (cp == 0x00DF or cp == 0x00E4 or cp == 0x00F6 or
				       cp == 0x00FC or cp == 0x00C4 or cp == 0x00D6 or
				       cp == 0x00DC) then return "de" -- ß ä ö ü (German)
				elseif (cp == 0x00F1 or cp == 0x00D1) then return "es" -- ñ (Spanish)
				elseif (cp == 0x00E3 or cp == 0x00F5 or
				       cp == 0x00C3 or cp == 0x00D5) then return "pt" -- ã õ (Portuguese)
				elseif (cp == 0x0105 or cp == 0x0119 or cp == 0x0142 or
				       cp == 0x0107 or cp == 0x0106 or cp == 0x0144 or
				       cp == 0x015B or cp == 0x015A or cp == 0x017A or
				       cp == 0x017C or cp == 0x017B) then return "pl" -- ą ę ł ć ś ź ż (Polish)
				elseif (cp == 0x0151 or cp == 0x0150 or
				       cp == 0x0171 or cp == 0x0170) then return "hu" -- ő ű (Hungarian)
				elseif (cp == 0x015F or cp == 0x015E or
				       cp == 0x011F or cp == 0x011E or
				       cp == 0x0131 or cp == 0x0130) then return "tr" -- ş ğ ı (Turkish)
				elseif (cp == 0x00E7 or cp == 0x00C7 or
				       cp == 0x0153 or cp == 0x0152) then return "fr" -- ç œ (French)
				end
			end

			i = i + 2
		elseif (b1 >= 0xE0 and b1 <= 0xEF) then -- 3-byte UTF-8 sequence (U+0800 – U+FFFF)
			local b2 = text:byte(i + 1) or 0x80
			local b3 = text:byte(i + 2) or 0x80

			if (b2 >= 0x80 and b2 <= 0xBF and b3 >= 0x80 and b3 <= 0xBF) then
				local cp = (b1 - 0xE0) * 4096 + (b2 - 0x80) * 64 + (b3 - 0x80)

				if (cp >= 0x3040 and cp <= 0x309F) then return "ja" -- Hiragana
				elseif (cp >= 0x30A0 and cp <= 0x30FF) then return "ja" -- Katakana
				elseif (cp >= 0x4E00 and cp <= 0x9FFF) then return "zh-CN" -- CJK Ideographs
				elseif (cp >= 0xAC00 and cp <= 0xD7FF) then return "ko" -- Hangul
				elseif (cp >= 0x0E00 and cp <= 0x0E7F) then return "th" -- Thai
				end
			end

			i = i + 3
		elseif (b1 >= 0xF0) then
			i = i + 4
		else
			i = i + 1
		end
	end

	return nil
end

local function UntranslateEcho(echo)
	echo.text = echo.originalText
	echo._detectedLang = nil  -- force re-detection from the restored original text
	echo.originalText = nil
	echo.translateDuration = nil
	echo.color = nil
	echo.cachedText = nil
	echo.loading = false

	EchoSound("echo_translate", 75, 0.5)
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

local cutOffDist = EchoesSettings["echoes_renderdist"] or 0

local function UpdateEchoVisibilityStates()
	local curTime = CurTime()

	for _, echo in ipairs(echoes) do
		local inRange = echo.distSqr <= cutOffDist

		if not echo.creationTime then
			echo.creationTime = curTime + 0.01 * (#echoes - _)
		end

		local canFadeIn = inRange and curTime >= echo.creationTime and (echo.ShouldShow ~= false or (echo.read and curTime < (echo.readTime or 0) + 30))

		if canFadeIn then
			echo.init = math.min((echo.init or 0) + FrameTime(), 1)
		else
			echo.init = math.max((echo.init or 0) - FrameTime(), 0)
		end
	end
end

local function UpdateEchoTextCache(inEchoes)
	local disableSigning = EchoesSettings["echoes_disablesigning"]

	for _, echo in ipairs(inEchoes) do
		local skin = getSkin(echo)
		local font = (skin and skin.font) or "TargetID"

		local text = echo.text
		if (disableSigning) then text = RemoveSigning(text) end

		local sig = GetSignature(text)
		if echo.cachedSig ~= sig then
			echo.cachedSig = sig
			echo.color = nil
			echo.light_color = nil
			echo.readcolor = nil
			echo.readcolor_light = nil
		end

		-- If text is already cached with the correct font, skip it
		if (echo.cachedText and echo.cachedFont == font) then continue end
		echo.cachedFont = font

		local words = string.Explode(" ", text)
		local lines = {}
		local line = ""

		surface.SetFont(font)

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

local function GetCameraPos()
	return cameraData.cx, cameraData.cy, cameraData.cz
end

local function GetCameraFwd()
	return cameraData.fx, cameraData.fy, cameraData.fz
end

local function EchoDistSortFunc(a,b) return a.distSqr > b.distSqr end
local function GetSortedVisibleEchoes()
	cutOffDist = EchoesSettings["echoes_renderdist"]
	local sortedEchoes = {}
	local cx, cy, cz = GetCameraPos()
	local fx, fy, fz = GetCameraFwd()

	for _, echo in ipairs(echoes) do
		if (echo.init == 0) then
			echo.wasVisibleLastFrame = false
			continue
		end
		if (echo.inVoid and not EchoesSettings["echoes_enablevoidechoes"]) then
			echo.wasVisibleLastFrame = false
			continue
		end

		local x, y, z = GetEchoPosition(echo)
		local dot = ((cx-x) * fx + (cy-y) * fy + (cz-z) * fz)

		if (dot > 0) then
			echo.wasVisibleLastFrame = false
			continue
		end

		sortedEchoes[#sortedEchoes+1] = echo
	end

	table.sort(sortedEchoes, EchoDistSortFunc)

	return sortedEchoes
end

local function UpdateEchoRotations(inEchoes, dt)
	local lerpFactor = math.Clamp(dt * 5, 0, 1)
	local cx, cy, cz = GetCameraPos()

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
	local disableReadSys = EchoesSettings["echoes_disablereadsys"]
	local breathLayer = math.sin(curTimeSpeed) * 0.5
	local activeZOffset = 24 + breathLayer
	local readZOffset = 20
	local gabenMode = EchoesSettings["echoes_gabenmode"]
	local slowActivate = EchoesSettings["echoes_slowactivate"]
	local activateSpeed = slowActivate and 1.5 or 3
	local cx, cy, cz = GetCameraPos()
	local fx, fy, fz = GetCameraFwd()
	local visibleOnly = EchoesSettings["echoes_visibleonly"]
	local visibleFov, dotThreshold
	if visibleOnly then
		visibleFov = EchoesSettings["echoes_visiblefov"]
		dotThreshold = math.cos(math.rad(visibleFov / 2))
	end

	for _, echo in ipairs(inEchoes) do
		echo.z_offset = echo.z_offset or 0
		local read = echo.read and !disableReadSys
		local bOwner = echo.isOwner

		if (!echo.loading and echo.ShouldShow ~= false) then
			local x, y, z = GetEchoPosition(echo)
			local _, _, cameraZ = GetCameraPos()
			local heightDiff = cameraZ - z -32
			local predictedZOffset = activeZOffset + heightDiff

			local shouldActivate = echo.distSqr < activationDist
			if visibleOnly then
				local directionToEcho = Vector(x - cx, y - cy, z - cz + predictedZOffset)
				directionToEcho:Normalize()
				local dot = directionToEcho:Dot(Vector(fx, fy, fz))
				shouldActivate = shouldActivate and dot >= dotThreshold
			end

			if shouldActivate then

				if EchoesSettings["echoes_enableparticles"] then
					local x, y, z = GetEchoPosition(echo)
					local pos = Vector(x, y, z + (echo.z_offset or 0))
					if not echo.emitter then
						echo.emitter = ParticleEmitter(pos)
					end
					if CurTime() % 0.1 < 0.003 then
						local dir = VectorRand():GetNormalized()
						local dist = math.Rand(0, 5)
						local vPos = pos + dir * dist
						local particle = echo.emitter:Add("particle/particle_glow_04_additive", vPos)
						if particle then
							particle:SetVelocity(dir * 4)
							particle:SetLifeTime(0)
							particle:SetDieTime(math.Rand(3,5))
							particle:SetStartAlpha(5)
							particle:SetEndAlpha(0)
							particle:SetStartSize(math.random(4,7))
							particle:SetEndSize(0)
							particle:SetColor(200,200,200)
							particle:SetAirResistance(10)
							particle:SetGravity(Vector(0,0,-1))
							particle:SetCollide(false)
						end
					end
				end

				local active = math.min(echo.active + dt * activateSpeed, 1)

				echo.active = active
				echo.z_offset = Lerp(dt * activateSpeed, echo.z_offset, predictedZOffset)

				if (!echo.soundActive) then
					echo.soundActive = true

					if (gabenMode) then
						EchoSound(table.Random(gabenIntroSounds), nil, 0.75)
					else
						local skin = getSkin(echo)
						local soundName = istable(skin.sound) and skin.sound[math.random(1, #skin.sound)] or skin.sound or "echo_activate"
						if slowActivate and soundName == "echo_activate" then
							soundName = "echo_activate_slow"
						end
						EchoSound(soundName, echo.special and math.random(115, 125) or echo.explicit and math.random(65, 75) or math.random(95, 105), echo.read and 0.4 or 1)
					end
				end

				if (active == 1 and !bOwner and !echo.read and !echo.special) then
					local savedData = ReadEchoes()
					savedData[#savedData + 1] = echo.id

					echo.read = true
					echo.readTime = CurTime()

					readEchoCount = readEchoCount + 1

					local mapName = game.GetMap()
				         		readMapCounts[mapName] = (readMapCounts[mapName] or 0) + 1
				         		SaveReadMapCounts()

					WriteEchoes(savedData)
				end
			else
				if echo.emitter then
					echo.emitter:Finish()
					echo.emitter = nil
				end

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

function TranslateEcho(echo)
    if echo.isTranslating then return end

	-- Already translated: reverse it
	if (echo.originalText) then
		local delay = echo.translateDuration or 0

		if (delay > 0) then
			echo.isTranslating = true
			echo.active = 0
			echo.loading = true

			EchoSound("echo_translate", 100)

			timer.Simple(delay, function()
				echo.isTranslating = false
				UntranslateEcho(echo)
			end)
		else
			UntranslateEcho(echo)
		end

		return
	end

    echo.isTranslating = true
    echo.originalText = echo.originalText or echo.text
    echo.cachedText = nil
	echo.active = 0
	echo.loading = true
	echo._translateStart = SysTime()
	EchoSound("echo_translate_fast", 70, 0.5)

    local apiKey = "AIzaSyATBXajvzQLTDHEQbcpq0Ihe0vWDHmO520" --This is an official google api key, dw
    local url = "https://translate-pa.googleapis.com/v1/translateHtml?key=" .. apiKey

    local bodyTable = {
        {
            {echo.originalText},
            "auto",
            "en"
        },
        "wt_lib"
    }

    local request = {
        method = "POST",
        url = url,
        headers = {
            ["Content-Type"] = "application/json+protobuf",
            ["X-Goog-API-Key"] = apiKey
        },
        body = util.TableToJSON(bodyTable),
        
        success = function(code, body, headers)
            echo.isTranslating = false
			echo.translateDuration = echo._translateStart and (SysTime() - echo._translateStart) or 0
			echo._translateStart = nil
            if code == 200 then
                local success, data = pcall(util.JSONToTable, body)
                if success and data and data[1] and data[1][1] then
                    echo.text = string.gsub(data[1][1], "&#(%d+);", function(n) return string.char(tonumber(n)) end)
					echo._detectedLang = nil  -- text changed; will re-detect if later untranslated
					echo.color = nil
                else
                    EchoNotify("Translation failed. (Invalid response)")
					echo.originalText = nil
                end
            else
                EchoNotify("Translation failed. (HTTP " .. tostring(code) .. ")")
				echo.originalText = nil
            end
            echo.cachedText = nil
			echo.loading = false
			EchoSound("echo_translate_done", 120)
        end,
        
        failed = function(error)
            echo.isTranslating = false
            EchoNotify("Translation failed. (" .. tostring(error) .. ")")
            echo.cachedText = nil
			echo.loading = false
			EchoSound("echo_translate_done", 120)
			echo.originalText = nil
			echo._translateStart = nil
        end
    }

    HTTP(request)
end

local lastPartyModeTime = 0
local isAltEMenuOpen = false
local altEMenuTargetEcho = nil
local altEMenuSelectedOption = 1
local altEMenuFadeStartTime = 0

function ReloadEchoColors()
	for _, echo in ipairs(echoes) do
		echo.color = nil
		echo.light_color = nil
		echo.readcolor = nil
		echo.readcolor_light = nil
	end
end

concommand.Add("echoes_reload_colors", function()
	ReloadEchoColors()
	EchoNotify("Echo colors reloaded!")
end)

hook.Add("PreDrawEffects", "echoes_render_PreDrawEffects", function(bDrawingDepth, bDrawingSkybox)
	if (bDrawingDepth or bDrawingSkybox) then return end

	local profanity = EchoesSettings["echoes_profanity"]
	local showRead = EchoesSettings["echoes_showread"]
	local disableReadSys = EchoesSettings["echoes_disablereadsys"]
	local showDlights = EchoesSettings["echoes_dlights"]
	local DlightBright = EchoesSettings["echoes_dlights_brightness"]
	local enableAir = EchoesSettings["echoes_enableairechoes"]
	local debugInfo = EchoesSettings["echoes_debuginfo"]
	local immersiveMode = EchoesSettings["echoes_immersivemode"]
	if immersiveMode then debugInfo = false end

	local org, ang = EyePos(), EyeAngles()
	local fwd = ang:Forward()
	local d = cameraData
	d.cx, d.cy, d.cz = __vunpack(org)
	d.fx, d.fy, d.fz = __vunpack(fwd)

	local client = LocalPlayer()
	local clientPos = client:GetShootPos()
	local frameTime = FrameTime()
	local curTime = CurTime()
	local curTimeSpeed = curTime * 1.5
	local drawColor = Color(0, 0, 0)
	local targetLang = GetTranslateTargetLang()

	echoToGroundFrac = Lerp(frameTime * 2, echoToGroundFrac, enableAir and 0 or 1)

	ComputeSqrEchoDist(clientPos)
	UpdateEchoInteractions(echoes, curTimeSpeed, frameTime)
	local sortedEchoes = GetSortedVisibleEchoes()
	local echoCount = #sortedEchoes
	UpdateEchoRotations(sortedEchoes, frameTime)
	UpdateEchoVisibilityStates()

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
		local font = (skin and skin.font) or "TargetID"
		local translated = echo.originalText != nil

		-- Lazily detect the script/language of untranslated echoes (cached on the echo itself)
		if (echo._detectedLang == nil and !translated) then
			echo._detectedLang = DetectTextScript(echo.text) or "en" -- "en" = checked, plain ASCII / indeterminate Latin
		end

		local showTransIcon = ((echo._detectedLang and echo._detectedLang != targetLang) or translated)

		-- This is probably a janky way of doing it for pixel ones but lolol
		if (skin.point) then
			render.PushFilterMag(TEXFILTER.POINT)
			render.PushFilterMin(TEXFILTER.POINT)
		else
			render.PushFilterMag(TEXFILTER.ANISOTROPIC)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		end

		if not echo.color then
			if translated then
				echo.color = Color(30, 80, 180)
				echo.light_color = Color(30, 80, 180)
				echo.readcolor = Color(20, 40, 80)
				echo.readcolor_light = Color(10, 20, 40)
			elseif explicit then
				echo.color = Color(255, 50, 50)
				echo.light_color = Color(255, 25, 25)
				echo.readcolor = Color(100, 80, 80)
				echo.readcolor_light = Color(30, 20, 20)
			elseif echo.special then
				echo.color = Color(200, 0, 200)
				echo.light_color = Color(255, 0, 255)
				echo.readcolor = Color(100, 100, 100)
				echo.readcolor_light = Color(25, 25, 25)
			else
				local sig = GetSignature(echo.text)
				local sigColor = sig and GetSignatureColor(sig)
				local useSigColor = EchoesSettings["echoes_showsignaturecolors"] and sigColor and (not bOwner or EchoesSettings["echoes_allowsigsown"])
				if useSigColor then
					echo.color = sigColor
					echo.light_color = sigColor
					echo.readcolor = Color(
						Lerp(0.1, 100, sigColor.r),
						Lerp(0.1, 100, sigColor.g),
						Lerp(0.1, 100, sigColor.b)
					)
					echo.readcolor_light = Color(25, 25, 25)
				elseif bOwner then
					echo.color = Color(255, 255, 0)
					echo.light_color = Color(255, 255, 0)
					echo.readcolor = Color(100, 100, 100)
					echo.readcolor_light = Color(25, 25, 25)
				else
					echo.color = skin.color or Color(150, 255, 255)
					echo.light_color = skin.color_light or echo.color
					echo.readcolor = skin.readcolor or Color(100, 100, 100)
					echo.readcolor_light = skin.readcolor_light or Color(25, 25, 25)
				end
			end
		end

		local r, g, b
		local rDraw, gDraw, bDraw

		if (not read and not loading) then
			local baseDrawColor = echo.color
			local baseLightColor = echo.light_color

			if not bOwner and not special then
				 baseLightColor = Color(math.max(0, baseLightColor.r - 50), baseLightColor.g, baseLightColor.b)
			end

			-- Unified color animation logic, lerping from base color to white
			r = Lerp(active, baseLightColor.r, 255)
			g = Lerp(active, baseLightColor.g, 255)
			b = Lerp(active, baseLightColor.b, 255)

			rDraw = Lerp(active, baseDrawColor.r, 255)
			gDraw = Lerp(active, baseDrawColor.g, 255)
			bDraw = Lerp(active, baseDrawColor.b, 255)
		else
			--read use readcolor instead
			local baseDrawColor = echo.readcolor
			local baseLightColor = echo.readcolor_light

			r = Lerp(active, baseLightColor.r, 255)
			g = Lerp(active, baseLightColor.g, 255)
			b = Lerp(active, baseLightColor.b, 255)

			rDraw = Lerp(active, baseDrawColor.r, 255)
			gDraw = Lerp(active, baseDrawColor.g, 255)
			bDraw = Lerp(active, baseDrawColor.b, 255)
		end

		if (echoDistSqr <= lightRenderDist and showDlights and i >= (echoCount - (32 - dLightCount))) then
			local dLight = DynamicLight(echo.id)
			if (dLight) then
				dLight.Pos = echo.drawPos
				dLight.r = partyMode and echo.color.r or r
				dLight.g = partyMode and echo.color.g or g
				dLight.b = partyMode and echo.color.b or b
				dLight.Brightness = DlightBright
				dLight.Size = 256 * (((lightRenderDist - echoDistSqr) / lightRenderDist) * echo.init) * (alpha / 255)
				dLight.Decay = 1000
				dLight.DieTime = curTime + 0.1
			end
		end

		drawColor:SetUnpacked(rDraw, gDraw, bDraw, alpha)

		ComputeEchoMtx(echo_mtx, echo.drawPos, echo._angle, 0.1)
		cam.PushModelMatrix(echo_mtx, true)
		
		local finalColor = partyMode and echo.color or drawColor

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

		if echo.pinned then
            local pinSpawnTime = echo.pinTime or (echo.creationTime or 0)
            local timeSincePin = CurTime() - pinSpawnTime
            local fadeDuration = 0.7 --quick fade
            local pinAlpha = math.min(timeSincePin / fadeDuration, 1)

			--use echo's color for the pin
            local pinColor = finalColor
            surface.SetDrawColor(pinColor.r, pinColor.g, pinColor.b, pinColor.a * pinAlpha)
            surface.SetMaterial(echoPinMat)
            
            local iconSize = 96
            surface.DrawTexturedRect(96 - iconSize, 96 - iconSize - 10, iconSize, iconSize)
			surface.SetDrawColor(finalColor)
        end

		if (alpha ~= 0 and active ~= 0) then
			cam.IgnoreZ(true)
			surface.SetFont(font)
			local textAlpha = math.min(active * 255, alpha)
			local maxWidth = 0
			for _, line in ipairs(echo.cachedText) do
				local w, _ = surface.GetTextSize(line)
				maxWidth = math.max(maxWidth, w)
			end

			local _, fontHeight = surface.GetTextSize("A")
			local numLines = #echo.cachedText
			local lineSpacing = 15
			local padding = 15

			local boxWidth = maxWidth + padding * 10
			local boxHeight = (numLines - 1) * lineSpacing + fontHeight + padding * 2
			local boxX = -boxWidth / 2
			--highest point of the text block is the top of the last line drawn
			local highestLineCenterY = -(151 + numLines * lineSpacing)
			local boxY = highestLineCenterY - (fontHeight / 2) - padding
			local r, g, b = echo.color.r, echo.color.g, echo.color.b
			local bgColor = Color(r * 0.2, g * 0.2, b * 0.2, textAlpha * 0.4)
			surface.SetMaterial(echoOptionMat)
			surface.SetDrawColor(bgColor)
			surface.DrawTexturedRect(boxX, boxY, boxWidth, boxHeight)
			surface.SetDrawColor(finalColor)
			for j = 1, #echo.cachedText do
				draw.SimpleText(echo.cachedText[j], font, 1, -(150 + j * lineSpacing), Color(0, 0, 0, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				draw.SimpleText(echo.cachedText[j], font, 0, -(151 + j * lineSpacing), Color(255, 255, 255, textAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			
			if debugInfo then
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

		-- translate badge
		if (showTransIcon and alpha != 0) then
			cam.IgnoreZ(true)
			local transColor = 100 + 155 * active
			surface.SetDrawColor(loading and Color(transColor, transColor, transColor, alpha) or finalColor)
			surface.SetMaterial(echoTranslateMat)
			surface.DrawTexturedRect(16, -80, 64, 64)
			cam.IgnoreZ(false)
		end

		-- Alt + e menu, i half have no idea what im doing sue me please LOL
        if isAltEMenuOpen and altEMenuTargetEcho == echo then
			cam.IgnoreZ(true)
            local fadeInDuration = 0.15
            local timeSinceOpen = CurTime() - altEMenuFadeStartTime
            local openAlpha = math.min(timeSinceOpen / fadeInDuration, 1)
            
            if openAlpha > 0 then
                local menuAlpha = finalColor.a * openAlpha

                local boxSize = 80
                local boxPadding = 10
                local totalWidth = (boxSize * 2) + boxPadding
                local startX = -totalWidth / 2
                local startY = 96 + 20
                local trans_x = startX + boxSize + boxPadding

                local target1 = (altEMenuSelectedOption == 1) and 1 or 0
                local target2 = (altEMenuSelectedOption == 2) and 1 or 0
                local colorLerpSpeed = 12
                echo.selectionLerp1 = Lerp(frameTime * colorLerpSpeed, echo.selectionLerp1, target1)
                echo.selectionLerp2 = Lerp(frameTime * colorLerpSpeed, echo.selectionLerp2, target2)

                local deselectedColor = Color(150, 150, 150)
                local selectedColor = echo.color
                local color1 = Color(Lerp(echo.selectionLerp1, deselectedColor.r, selectedColor.r), Lerp(echo.selectionLerp1, deselectedColor.g, selectedColor.g), Lerp(echo.selectionLerp1, deselectedColor.b, selectedColor.b), menuAlpha)
                local color2 = Color(Lerp(echo.selectionLerp2, deselectedColor.r, selectedColor.r), Lerp(echo.selectionLerp2, deselectedColor.g, selectedColor.g), Lerp(echo.selectionLerp2, deselectedColor.b, selectedColor.b), menuAlpha)

                local targetArrowX = (altEMenuSelectedOption == 1) and (startX + boxSize/2) or (trans_x + boxSize/2)
                local arrowLerpSpeed = 20
                echo.arrowLerpX = Lerp(frameTime * arrowLerpSpeed, echo.arrowLerpX, targetArrowX)

                local arrowSize = 32
                local arrowY = startY - arrowSize/2 - 5
                surface.SetMaterial(echoArrowMat)
                surface.SetDrawColor(255, 255, 255, menuAlpha)
                surface.DrawTexturedRectRotated(echo.arrowLerpX, arrowY, arrowSize, arrowSize, 180) -- 180 degrees to be upside down

                surface.SetMaterial(echoOptionMat)

                --1: Pin
                surface.SetDrawColor(color1)
                surface.DrawTexturedRect(startX, startY, boxSize, boxSize)
                surface.SetMaterial(echoPinMat)
                surface.SetDrawColor(255, 255, 255, menuAlpha)
                surface.DrawTexturedRect(startX + boxSize/4, startY + boxSize/4, boxSize/2, boxSize/2)
                draw.SimpleText("Pin", "TargetID", startX + boxSize/2, startY + boxSize + 5, Color(255, 255, 255, menuAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

                --2: Translate
                surface.SetMaterial(echoOptionMat)
                surface.SetDrawColor(color2)
                surface.DrawTexturedRect(trans_x, startY, boxSize, boxSize)
                surface.SetMaterial(echoTranslateMat)
                surface.SetDrawColor(255, 255, 255, menuAlpha)
                surface.DrawTexturedRect(trans_x + boxSize/4, startY + boxSize/4, boxSize/2, boxSize/2)
                draw.SimpleText("Translate", "TargetID", trans_x + boxSize/2, startY + boxSize + 5, Color(255, 255, 255, menuAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
				surface.SetDrawColor(finalColor)
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

local was_e_key_pressed = false
local was_alt_key_down = false

hook.Add("Think", "Echoes_thinkloop", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local is_alt_down = input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_RALT)
    local is_e_down = input.IsKeyDown(KEY_E)

	--alt released
    if not is_alt_down and was_alt_key_down and isAltEMenuOpen then
        if altEMenuTargetEcho then
            if altEMenuSelectedOption == 1 then --pin
                TogglePin(altEMenuTargetEcho)
            elseif altEMenuSelectedOption == 2 then --translate
                TranslateEcho(altEMenuTargetEcho)
            end

			--clean up
            altEMenuTargetEcho.selectionLerp1 = nil
            altEMenuTargetEcho.selectionLerp2 = nil
            altEMenuTargetEcho.arrowLerpX = nil
        end
        isAltEMenuOpen = false
        altEMenuTargetEcho = nil
    end

    --pressed e while holding alt
    if is_e_down and not was_e_key_pressed and is_alt_down then
        if not isAltEMenuOpen then -- Open the menu
            local plyPos = ply:GetShootPos()
            local closestEcho = nil
            local minDistSqr = activationDist

            for i = 1, #echoes do
                local echo = echoes[i]
                if echo.active and echo.active > 0.9 then
                    local distSqr = plyPos:DistToSqr(echo.pos)
                    if distSqr < minDistSqr then
                        minDistSqr = distSqr
                        closestEcho = echo
                    end
                end
            end

            if closestEcho then
                isAltEMenuOpen = true
                altEMenuTargetEcho = closestEcho
                altEMenuSelectedOption = 1

                altEMenuFadeStartTime = CurTime()
                altEMenuTargetEcho.selectionLerp1 = 1
                altEMenuTargetEcho.selectionLerp2 = 0

                local boxSize = 80
                local boxPadding = 10
                local totalWidth = (boxSize * 2) + boxPadding
                local startX = -totalWidth / 2
                altEMenuTargetEcho.arrowLerpX = startX + boxSize/2
            end
        else
            altEMenuSelectedOption = altEMenuSelectedOption % 2 + 1
			EchoSound("echo_select", math.random(95,105), 0.3)
        end
    end

    was_e_key_pressed = is_e_down
    was_alt_key_down = is_alt_down
end)