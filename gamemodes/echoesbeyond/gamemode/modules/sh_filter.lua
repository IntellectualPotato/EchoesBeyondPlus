
-- Recognizes offensive language in text
if (CLIENT) then
	include("echoes/cl_settings.lua")
	CreateClientConVar("echoes_profanity", "0")

	cvars.AddChangeCallback("echoes_profanity", function(name, old, new)
		if (not EchoesSettings["echoes_profanity"]) then return end
		if (new == "0") then return end

		for i = 1, #echoes do
			local echo = echoes[i]
			if (!echo.explicit) then continue end

			echo.init = 0
		end
	end, "echoes_profanity")
end

-- Common letter substitutions
local substitutions = {
	a = "[aA@4αΑа]",			-- Latin a, @, 4, Greek alpha (lower & upper), Cyrillic a
	b = "[bB8βВв]",			-- Latin b, 8, Greek beta, Cyrillic Ve (both cases)
	c = "[cCçćčс]",			-- Latin c, cedilla/accents, Cyrillic es
	d = "[dDđ]",				-- Latin d, with đ (a common variant)
	e = "[eE3€εєе]",			-- Latin e, 3, euro sign, Greek epsilon, Ukrainian IE, Cyrillic е
	f = "[fFƒ4]",				-- Latin f, plus the function symbol ƒ
	g = "[gG69]",				-- Latin g, 6, 9 (often used)
	h = "[hH]",				-- Latin h (no common homoglyphs added)
	i = "[iI1!|íìîïιі]",		-- Latin i, 1, exclamation, vertical bar, accented forms, Greek iota, Ukrainian i
	j = "[jJ]",				-- Latin j (rarely substituted)
	k = "[kKκк]",				-- Latin k, Greek kappa, Cyrillic ka
	l = "[lL1|ł]",			-- Latin l, 1, vertical bar, Polish ł
	m = "[mM]",				-- Latin m (no common homoglyphs added)
	n = "[nNñÑн]",			-- Latin n, ñ (both cases), Cyrillic en
	o = "[oO0öóòôοОо]",		-- Latin o, 0, umlauted/accents, Greek omicron, Cyrillic O/o
	p = "[pPρр]",				-- Latin p, Greek rho, Cyrillic er
	q = "[qQ9]",				-- Latin q (and sometimes 9 is substituted)
	r = "[rR]",				-- Latin r (not many typical substitutions)
	s = "[sS$5šśѕ]",			-- Latin s, $, 5, accented s variants, Cyrillic es (ѕ)
	t = "[tT7+τт]",			-- Latin t, 7, +, Greek tau, Cyrillic te
	u = "[uUυυу]",			-- Latin u, Greek upsilon, Cyrillic u (note: some upsilon variants may repeat)
	v = "[vVνв]",				-- Latin v, Greek nu (ν), Cyrillic ve
	w = "[wWω]",				-- Latin w, Greek omega (as a rough visual substitute)
	x = "[xXχх]",				-- Latin x, Greek chi, Cyrillic ha
	y = "[yY¥]",				-- Latin y, yen symbol (a common substitution)
	z = "[zZ2žźз]"			-- Latin z, 2, accented z's, Cyrillic ze
}

-- Bleach your eyes
local wordList = {
	"kil yourself",
	"tranies",
	"retard",
	"fagot",
	"trany",
	"negro",
	"niger",
	"chink",
	"honky",
	"spic",
	"niga",
	"gook",
	"kike",
	"dyke",
	"fgt",
	"fag",
	"kys"
}

-- This is silly, but I'm not sure how else to do this
local exemptWords = {
	"jacksepticeye",
	"underground",
	"especially",
	"satisfies",
	"flatgrass",
	"minigame",
	"fragment",
	"bouncing",
	"thinking",
	"bonding",
	"finding",
	"running",
	"getting",
	"spooky",
	"pitch",
	"fight",
	"flag",
	"frag"
}

-- Helper function to remove repeated characters from a string
local function RemoveRepeatedChars(text)
	local result = ""
	local mapping = {}  -- mapping[i] = original index of i-th char in result
	local prev = ""

	for i = 1, #text do
		local char = text:sub(i, i)

		if (char != prev) then
			result = result .. char
			table.insert(mapping, i)
		end

		prev = char
	end

	return result, mapping
end

local maxGap = 1 -- Gotta figure out a better way to do this...

-- Check if the pattern exists in the given string
local function FuzzyMatchFrom(text, target, pos, branchStart, lastMatchEnd)
	if (target == "") then
		return true, branchStart, lastMatchEnd
	end

	local char = target:sub(1, 1)
	local pattern = substitutions[char] or char
	local s, e = string.find(text, pattern, pos)

	while (s) do
		local valid = true

		if (lastMatchEnd and (s - lastMatchEnd - 1 > maxGap)) then
			valid = false
		end

		if (valid) then -- Only set branchStart if we haven't yet for this branch.
			local newBranchStart = branchStart or s
			local res, matchStart, matchEnd = FuzzyMatchFrom(text, target:sub(2), e + 1, newBranchStart, e)

			if (res) then
				return true, matchStart, matchEnd
			end
		end

		s, e = string.find(text, pattern, s + 1)
	end

	return false
end

local function FuzzyMatch(text, target)
	local processedText, mapping = RemoveRepeatedChars(text)
	local res, procMatchStart, procMatchEnd = FuzzyMatchFrom(processedText, target, 1, nil, nil)

	if (res) then -- Map processed indices back to original text indices.
		local origStart = mapping[procMatchStart]
		local origEnd = mapping[procMatchEnd]

		return true, origStart, origEnd
	else
		return false
	end
end

-- Helper function: checks if more than 50% of alphabetic characters are Cyrillic.
local function IsMostlyCyrillic(text)
	local totalAlpha = 0
	local cyrillicCount = 0
	local len = string.utf8len(text)

	for i = 1, len do
		local char = string.utf8sub(text, i, i)

		-- Check if the character is an alphabetic letter
		if (!char:match("[A-Za-zА-Яа-яЁё]")) then continue end

		totalAlpha = totalAlpha + 1

		if (char:match("[А-Яа-яЁё]")) then
			cyrillicCount = cyrillicCount + 1
		end
	end

	if (totalAlpha == 0) then
		return false
	end

	return (cyrillicCount / totalAlpha) > 0.5
end

local function GetMatchedWord(text, matchStart, matchEnd)
	local wordStart = matchStart
	local wordEnd = matchEnd


	while (wordStart > 1) do -- Expand backward until a non-letter is encountered.
		local char = text:sub(wordStart - 1, wordStart - 1)
		if (!char:match("[%a]")) then break end

		wordStart = wordStart - 1
	end

	-- Expand forward until a non-letter is encountered.
	while (wordEnd < #text) do
		local char = text:sub(wordEnd + 1, wordEnd + 1)
		if (!char:match("[%a]")) then break end

		wordEnd = wordEnd + 1
	end

	return text:sub(wordStart, wordEnd)
end

function IsOffensive(text)
	text = text:lower()

	-- Don't bother checking Cyrillic text.
	if (IsMostlyCyrillic(text)) then return false end

	for _, target in ipairs(wordList) do
		local res, matchStart, matchEnd = FuzzyMatch(text, target)
		if (!res) then continue end

		local matchedWord = GetMatchedWord(text, matchStart, matchEnd)
		local isExempt = false

		for _, exempt in ipairs(exemptWords) do
			if (!matchedWord:find(exempt)) then continue end
			isExempt = true

			break
		end

		if (isExempt) then continue end

		return true
	end

	return false
end
