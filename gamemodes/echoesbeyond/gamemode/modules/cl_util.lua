
-- Reads a json file and creates it if it doesn't exist
function file.ReadOrCreate(name)
	-- Split the name into folders and file
	local folders = string.Explode("/", name)

	for i = 1, #folders - 1 do
		local folder = table.concat(folders, "/", 1, i)

		if (!file.Exists(folder, "DATA")) then
			file.CreateDir(folder)
		end
	end

	if (!file.Exists(name, "DATA")) then
		file.Write(name, "[]")
	end

	return util.JSONToTable(file.Read(name, "DATA"))
end

-- Lerps a color
function LerpColor(frac, from, to)
	return Color(
		Lerp(frac, from.r, to.r),
		Lerp(frac, from.g, to.g),
		Lerp(frac, from.b, to.b),
		Lerp(frac, from.a, to.a)
	)
end

local hexChars = "0123456789ABCDEF"

function GenerateHex()
	local hex = ""

	for i = 1, 32 do
		hex = hex .. hexChars[math.random(16)]
	end

	return hex
end

function EchoSound(path, pitch, volume)
	LocalPlayer():EmitSound("echoesbeyond/" .. path .. ".wav", 75, pitch or math.random(95, 105), volume or 1)
end

function RemoveSigning(text)
    local s, e = text:find("[%-~][^%-~]*$")  -- This pattern matches from the last dash/tilde to the end.
    if (!s) then return text end

	local candidate = text:sub(s+1):match("^%s*(.-)%s*$") -- Extract the candidate signing text (trim whitespace).

	-- If the candidate isn't empty, starts with a letter, and is short, assume it's a signing block and remove it.
	if (candidate and candidate:match("^[A-Za-z]") and #candidate <= 30) then
		return text:sub(1, s-1)
	end

    return text
end

function ReadEchoes()
	if not file.Exists("echoesbeyond/readechoes.txt", "DATA") then return {} end
	local raw = file.Read("echoesbeyond/readechoes.txt", "DATA") or ""
	
	-- Convert JSON to newline format if it is json --------------------------
	if string.Trim(raw):sub(1,1) == "[" then
		local ok, data = pcall(util.JSONToTable, raw)
		if ok and istable(data) then
			local out = {}
			for _, v in ipairs(data) do
				local id = tonumber(v)
				if id then out[#out+1] = id end
			end
			file.Write("echoesbeyond/readechoes.txt", table.concat(out, "\n"))
			raw = table.concat(out, "\n")
		end
	end
	--------------------------------------------------------------------------

	local t, seen = {}, {}
	for id in string.gmatch(raw, "[^\r\n]+") do
		id = tonumber(id)
		if id and not seen[id] then t[#t + 1] = id; seen[id] = true end
	end
	return t
end

function WriteEchoes(t)
	local seen, out = {}, {}
	for i = 1, #t do
		local id = tonumber(t[i])
		if id and not seen[id] then out[#out + 1] = id; seen[id] = true end
	end
	file.CreateDir("echoesbeyond")
	file.Write("echoesbeyond/readechoes.txt", table.concat(out, "\n"))
end

idToSequential = {}
function IDsort()
	table.sort(echoes, function(a, b)
		return a.id < b.id
	end)

	for i, entry in ipairs(echoes) do
		idToSequential[entry.id] = i
	end
end

EchoesOnMaps = {}
function UpdateEchoesOnMaps()
	EchoesOnMaps[game.GetMap()] = 0
	for _, v in pairs(writtenEchoes) do
	    EchoesOnMaps[v.map] = 0
	end
	for _, v in pairs(writtenEchoes) do
		EchoesOnMaps[v.map] = EchoesOnMaps[v.map] + 1
	end
end
UpdateEchoesOnMaps()
