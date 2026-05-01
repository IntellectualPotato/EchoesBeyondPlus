
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

function CreateProgressColorTable(current, total)
    local tbl = {}
    local progress = (total > 0 and current / total or 0)

    --the color for the 'current' number based on progress
    local currentColor
    if progress >= 1 then
        currentColor = Color(100, 255, 100) --bright green (100%)
    elseif progress >= 0.9 then
        currentColor = Color(173, 255, 47)  --light green (90%+)
    elseif progress >= 0.75 then
        currentColor = Color(255, 255, 100) --yellow (75%+)
    elseif progress >= 0.5 then
        currentColor = Color(255, 165, 0)   --orange (50%+)
    elseif progress > 0 then
        currentColor = Color(255, 69, 0)    --red-orange (1%+)
    else
        currentColor = Color(200, 200, 200) --white/grey (0%)
    end

    --the color for the 'total' number
    local totalColor = Color(100, 255, 100)     --default Bright Green

    table.insert(tbl, {text = tostring(current), color = currentColor})
    table.insert(tbl, {text = "/", color = Color(150, 150, 150)}) --grey slash
    table.insert(tbl, {text = tostring(total), color = totalColor})

    return tbl
end


readMapCounts = readMapCounts or {}

function LoadReadMapCounts()
    local json = file.Read("echoesbeyond/read_map_counts.json", "DATA")
    if json and json ~= "" then
        local success, data = pcall(util.JSONToTable, json)
        if success and type(data) == "table" then
            readMapCounts = data
            return
        end
    end
    readMapCounts = {}
end

function SaveReadMapCounts()
    file.Write("echoesbeyond/read_map_counts.json", util.TableToJSON(readMapCounts, true))
end

function ReadEchoes()
	if not file.Exists("echoesbeyond/readechoes_plus.txt", "DATA") then
		-- Migrate from legacy file if it exists
		if file.Exists("echoesbeyond/readechoes.txt", "DATA") then
			local raw = file.Read("echoesbeyond/readechoes.txt", "DATA") or ""
			local out = {}
			if string.Trim(raw):sub(1,1) == "[" then
				local ok, data = pcall(util.JSONToTable, raw)
				if ok and istable(data) then
					for _, v in ipairs(data) do
						local id = tonumber(v)
						if id then out[#out+1] = id end
					end
				end
			else
				for id in string.gmatch(raw, "[^\r\n]+") do
					id = tonumber(id)
					if id then out[#out+1] = id end
				end
			end
			file.Write("echoesbeyond/readechoes_plus.txt", table.concat(out, "\n"))
		end
	end
	if not file.Exists("echoesbeyond/readechoes_plus.txt", "DATA") then return {} end
	local raw = file.Read("echoesbeyond/readechoes_plus.txt", "DATA") or ""
	-- Convert JSON to newline format if it is json --------------------------
	if string.Trim(raw):sub(1,1) == "[" then
		local ok, data = pcall(util.JSONToTable, raw)
		if ok and istable(data) then
			local out = {}
			for _, v in ipairs(data) do
				local id = tonumber(v)
				if id then out[#out+1] = id end
			end
			file.Write("echoesbeyond/readechoes_plus.txt", table.concat(out, "\n"))
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
	if #out == 0 or #out < #t then return end -- Prevent writing if empty or entries missing due to invalid data
	file.CreateDir("echoesbeyond")
	file.Write("echoesbeyond/readechoes_plus.txt", table.concat(out, "\n"))
end

idToSequential = {}
function IDsort()
	local realEchoes = {}
	for _, entry in ipairs(echoes) do
		if not entry.isDraft and entry.id >= 0 then
			table.insert(realEchoes, entry)
		end
	end

	table.sort(realEchoes, function(a, b)
		return a.id < b.id
	end)

	table.Empty(idToSequential)

	for i, entry in ipairs(realEchoes) do
		idToSequential[entry.id] = i
	end

	local sortedEchoes = {}
	for _, entry in ipairs(realEchoes) do
		table.insert(sortedEchoes, entry)
	end
	for _, entry in ipairs(echoes) do
		if entry.isDraft then
			table.insert(sortedEchoes, entry)
		end
	end
	echoes = sortedEchoes
end

EchoesOnMaps = {}
function UpdateEchoesOnMaps()
	EchoesOnMaps[game.GetMap()] = 0
	for _, v in pairs(writtenEchoes or {}) do
	    EchoesOnMaps[v.map] = 0
	end
	for _, v in pairs(writtenEchoes or {}) do
		EchoesOnMaps[v.map] = EchoesOnMaps[v.map] + 1
	end
end
function CalculateWrappedHeight(label, text, width)
    surface.SetFont(label:GetFont())
    local _, lineHeight = surface.GetTextSize("A")
    local words = string.Explode(" ", text)
    local lines = 1
    local currentLine = ""
    for _, word in ipairs(words) do
        local testLine = currentLine .. (currentLine == "" and "" or " ") .. word
        local textWidth = surface.GetTextSize(testLine)
        if textWidth > width then
            lines = lines + 1
            currentLine = word
        else
            currentLine = testLine
        end
    end
    return lines * lineHeight
end
UpdateEchoesOnMaps()
