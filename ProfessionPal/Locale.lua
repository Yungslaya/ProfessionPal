--[[ ProfessionPal - other languages

  English is written in the code. When the game runs in another language, every piece of text
  the addon shows passes through PP.T() on its way to the screen:
    1. a whole line that has a translation is swapped for it;
    2. a zone name is swapped for the game's own name of that zone (from its map);
    3. a line built from parts ("Until skill 90") is matched by a pattern and rebuilt;
    4. anything else stays in English.
  Item, recipe, trainer and ore names in the guides are data and stay in English for now.

  A language file adds its lines with PP:AddLocale("deDE", { lines }, { patterns }).
  Patterns are Lua patterns for the whole English line; %1, %2 in the answer are its captures.
]]
local _, PP = ...

local locale = (GetLocale and GetLocale()) or "enUS"
if locale == "esMX" then locale = "esES" end
PP.locale = locale
PP.LOCALES = {}

local lines, patterns   -- the tables of the language in use (nil in English)

function PP:AddLocale(code, exact, shaped)
    PP.LOCALES[code] = { exact = exact or {}, patterns = shaped or {} }
    if code == PP.locale then lines, patterns = PP.LOCALES[code].exact, PP.LOCALES[code].patterns end
end

-- For tests: switch language after loading.
function PP:UseLocale(code)
    PP.locale = code
    local l = PP.LOCALES[code]
    lines, patterns = l and l.exact or nil, l and l.patterns or nil
    PP.tCache = {}
end

-- The game's own name for a zone we only know in English.
local function zoneName(text)
    local map = PP.ZONE_MAP and PP.ZONE_MAP[text]
    if not (map and C_Map and C_Map.GetMapInfo) then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, map)
    local name = ok and type(info) == "table" and info.name
    if type(name) == "string" and name ~= "" and not (issecretvalue and issecretvalue(name)) then return name end
end

-- "or  Westfall   (level 12)   - you are here": the zone lines of the guide.
local function zoneLine(text)
    local body, lead = text, ""
    if body:sub(1, 4) == "or  " then lead, body = (lines["or"] or "or") .. "  ", body:sub(5) end
    local here = body:find("   - you are here", 1, true)
    if here then body = body:sub(1, here - 1) end
    local zone, level = body:match("^(.-)   %(level (%d+)%)$")
    zone = zone or body
    if not (PP.ZONE_MAP and PP.ZONE_MAP[zone]) then return nil end
    local out = lead .. (zoneName(zone) or zone)
    if level then out = out .. "   (" .. (lines["level"] or "level") .. " " .. level .. ")" end
    if here then out = out .. "   - " .. (lines["you are here"] or "you are here") end
    return out
end

PP.tCache = {}
local function translate(text)
    local hit = lines[text]
    if hit then return hit end
    -- the same line with spaces or a colon around it: "LEARN:  ", "Guide: "
    local lead, core, tail = text:match("^(%s*)(.-)([%s:]*)$")
    if core ~= "" and core ~= text and lines[core] then return lead .. lines[core] .. tail end
    local zone = zoneLine(text)
    if zone then return zone end
    for i = 1, #patterns do
        local rule = patterns[i]
        if text:find(rule[1]) then return (text:gsub(rule[1], rule[2])) end
    end
    return nil
end

-- Translate one line of text for the screen. Text the addon does not know stays as it is.
function PP.T(text)
    if not lines or type(text) ~= "string" or text == "" then return text end
    if issecretvalue and issecretvalue(text) then return text end
    local cached = PP.tCache[text]
    if cached ~= nil then return cached or text end
    local out = translate(text)
    -- a line with several parts joined by "  -  " : translate each part
    if not out and text:find("  -  ", 1, true) then
        local parts, changed = {}, false
        for part in (text .. "  -  "):gmatch("(.-)  %-  ") do
            local t = translate(part)
            if t then changed = true end
            parts[#parts + 1] = t or part
        end
        if changed then out = table.concat(parts, "  -  ") end
    end
    PP.tCache[text] = out or false
    return out or text
end

-- Text made by the addon's own kit goes through PP.T by itself.
function PP.LocalizeText(fs)
    if not fs or rawget(fs, "ppLocalized") then return fs end
    rawset(fs, "ppLocalized", true)
    local set, setf = fs.SetText, fs.SetFormattedText
    if set then
        fs.SetText = function(self, text, ...) return set(self, PP.T(text), ...) end
    end
    if set and setf then
        fs.SetFormattedText = function(self, format, ...)
            local ok, text = pcall(string.format, format, ...)
            if ok then return set(self, PP.T(text)) end
            return setf(self, format, ...)
        end
    end
    return fs
end

-- Languages that the addon's Latin fonts cannot draw use the game's own font.
function PP:LocaleFonts()
    if (PP.locale == "ruRU" or PP.locale == "zhCN" or PP.locale == "zhTW" or PP.locale == "koKR")
        and type(STANDARD_TEXT_FONT) == "string" then
        PP.FONT, PP.TITLE_FONT = STANDARD_TEXT_FONT, STANDARD_TEXT_FONT
    end
end
