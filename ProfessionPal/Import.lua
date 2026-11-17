--[[ ProfessionPal - Import a guide
  Copy any leveling guide page (Ctrl+A, Ctrl+C), paste it here (Ctrl+V), and the
  guide shows up in the normal ProfessionPal window and tracker.
  Addons can't go online, so the guide comes in by copy and paste.

  Reads:
    - table rows that start with a skill range: "1 to 25", "1-25", "1â€“25", "At 50", "To 75"
      then: what to make, how many, materials ("30Ã— Rough Stone", "30x Rough Stone", "30 Rough Stone")
    - extra material lines under a row (how copied tables look)
    - "Trainer" / "Vendor" / "Pattern: ..." lines (recipe source)
    - gathering guides: headings like "Mining from 65 to 125" + zone names + the first sentence
    - its own share format:  1-25 | Rough Sharpening Stone | 30 | 30x Rough Stone | go: Elwynn Forest | tip: ...
  Display only.
]]

local _, PP = ...
local C = PP.C

-- ---------- text helpers ----------
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function normalize(text)
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    text = text:gsub("\195\151", "x")                 -- Ã—
    text = text:gsub("\226\128\147", "-")             -- â€“
    text = text:gsub("\226\128\148", "-")             -- â€”
    text = text:gsub("\226\128\153", "'")             -- â€™
    text = text:gsub("\226\128\152", "'")             -- â€˜
    text = text:gsub("\194\160", " ")                 -- no-break space
    text = text:gsub("(%d)[ ]*x[ ]+(%a)", "%1x %2")   -- "30x   Rough Stone" -> "30x Rough Stone"
    return text
end

local function splitLines(text)
    local out = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do out[#out + 1] = line end
    return out
end

-- ---------- item names -> item IDs we already know ----------
local itemIndex
local function ItemIdByName(name)
    if not itemIndex then
        itemIndex = {}
        for _, def in ipairs(PP.professions) do
            for _, list in ipairs({ def.steps or {}, def.altSteps and def.altSteps.steps or {} }) do
                for _, st in ipairs(list) do
                    for _, m in ipairs(st.mats or {}) do
                        if type(m[1]) == "number" and m[3] then itemIndex[m[3]:lower()] = m[1] end
                    end
                    for _, n in ipairs(st.nodes or {}) do
                        if n[3] then itemIndex[n[1]:lower()] = n[3] end
                    end
                end
            end
        end
    end
    return itemIndex[name:lower()]
end

-- "30x Rough Stone", "30 x Rough Stone", "30 Rough Stone"  -> 30, "Rough Stone"
local function parseMat(s)
    s = trim(s)
    local n, name = s:match("^(%d+)%s*x%s*(%a.*)$")
    if not n then n, name = s:match("^(%d+)%s+(%a.*)$") end
    if not n then name, n = s:match("^(%a.-)%s*x%s*(%d+)$") end
    if not (n and name) then return nil end
    name = trim(name:gsub("%s+", " "))
    if #name > 40 or name:find("%.") then return nil end
    local low = name:lower()
    if low:find("crafts") or low:find("skill") or low:find("level") then return nil end
    return tonumber(n), name
end

local SOURCE_WORDS = { trainer = "trainer", known = "known", vendor = "vendor", drop = "drop", quest = "quest" }
local RECIPE_PREFIX = { "Pattern:", "Plans:", "Recipe:", "Schematic:", "Formula:", "Manual:" }

-- A row of a guide table. Returns a step or nil.
local function parseRow(from, to, rest)
    local st = { from = from, to = to, total = true, mats = {}, imported = true }
    local cells = {}
    for cell in (rest .. "\t"):gmatch("(.-)[\t|]") do
        cell = trim(cell)
        if cell ~= "" then cells[#cells + 1] = cell end
    end
    -- Pasting into WoW turns table gaps into spaces, so the row may be one long line.
    -- 1) two or more spaces = a column gap
    if #cells == 1 and cells[1]:find("%S%s%s+%S") then
        local c2 = {}
        for cell in (cells[1] .. "  "):gmatch("(.-)%s%s+") do
            cell = trim(cell); if cell ~= "" then c2[#c2 + 1] = cell end
        end
        if #c2 > 1 then cells = c2 end
    end
    -- 2) commas: "Bandage, 50, 100 x Wool Cloth"
    if #cells == 1 and cells[1]:find(",") then
        local c2 = {}
        for cell in (cells[1] .. ","):gmatch("(.-),") do c2[#c2 + 1] = trim(cell) end
        cells = c2
    end
    -- 3) single spaces: "Bolt of Linen Cloth 54 108 Linen Cloth", "Wool Bandage x45 45 Wool Cloth"
    if #cells == 1 then
        local s = cells[1]
        local name, crafts, mats = s:match("^(.-)%s+x(%d+)%s+(.*)$")
        if not name then name, crafts, mats = s:match("^(%a.-)%s+(%d+)%s+(%d+%s*x?%s*%a.*)$") end
        if not name then name, crafts = s:match("^(%a.-)%s+x?(%d+)$") end
        if name then cells = { name, crafts, mats } end
    end
    -- 4) no gap at all: "Bolt of Linen Cloth54108 Linen Cloth" - find the recipe name we know
    if #cells == 1 then
        local s = cells[1]
        local best
        for _, list in pairs(PP.Recipes or {}) do
            for name in pairs(list) do
                if s:sub(1, #name) == name and (not best or #name > #best) then best = name end
            end
        end
        if not best then best = s:match("^(%a[^%d]-%a)%d") end      -- any name glued to digits
        if best then
            local rest = trim(s:sub(#best + 1))
            local digits, matName = rest:match("^(%d+)%s*x?%s*(%a.*)$")
            cells = { best }
            if digits and matName then
                -- "54108" = crafts then amount. Try every split; amount must be a whole multiple of
                -- crafts; the closest pair wins (33|33 beats 3|333).
                local pick
                for cut = 1, #digits - 1 do
                    local c, n = tonumber(digits:sub(1, cut)), tonumber(digits:sub(cut + 1))
                    if c > 0 and n >= c and n % c == 0 and digits:sub(cut + 1, cut + 1) ~= "0" then
                        if not pick or n / c < pick[2] / pick[1] then pick = { c, n } end
                    end
                end
                if pick then cells = { best, tostring(pick[1]), pick[2] .. "x " .. matName } end
            elseif rest:match("^%d+$") then
                cells = { best, rest }
            end
        end
    end
    for _, cell in ipairs(cells) do
        local low = cell:lower()
        if low:match("^go:") then
            st.zones = {}
            for z in (cell:sub(4) .. ","):gmatch("(.-),") do
                z = trim(z); if z ~= "" then st.zones[#st.zones + 1] = z end
            end
        elseif low:match("^tip:") then
            st.tip = trim(cell:sub(5))
        elseif not st.crafts and cell:match("^%d+$") and st.text then
            st.crafts = tonumber(cell)
        elseif not st.crafts and st.text and (cell:match("^x(%d+)$") or cell:match("^(%d+)x$")) then
            st.crafts = tonumber(cell:match("(%d+)"))
        elseif st.text and parseMat(cell) then
            local n, name = parseMat(cell)
            st.mats[#st.mats + 1] = { ItemIdByName(name) or name, n, name }
        elseif not st.text and cell:find("%a") and not cell:match("^%d") then
            local name, crafts = cell:match("^(.-)%s+x(%d+)$")
            if name then st.text, st.crafts = trim(name), tonumber(crafts) else st.text = cell end
            st.text = st.text:gsub("^Make%s+", "")
        end
    end
    if not st.text then return nil end
    return st
end

-- Skill range at the start of a line
local function parseRange(line, prevTo)
    local a, b, rest = line:match("^(%d+)%s*%-%s*(%d+)%s*[:|]?%s*(.*)$")
    if not a then a, b, rest = line:match("^(%d+)%s+to%s+(%d+)%s*[:|]?%s*(.*)$") end
    if not a then
        local n, r = line:match("^[Aa]t%s+(%d+)%s*[\t|:]%s*(.*)$")
        if n then a, b, rest = n, tostring(tonumber(n) + 1), r end
    end
    if not a then
        local n, r = line:match("^[Tt]o%s+(%d+)%s*[\t|:]%s*(.*)$")
        if n and prevTo then a, b, rest = tostring(prevTo), n, r end
    end
    a, b = tonumber(a), tonumber(b)
    if not (a and b) or b <= a or b > 300 or a < 0 then return nil end
    return a, b, rest or ""
end

local function zoneSet()
    local z = {}
    for name in pairs(PP.ZONE_MAP or {}) do z[name:lower()] = name end
    return z
end

local function firstSentence(s)
    return trim(s:match("^(.-[%.!%?])%s") or s)
end

-- ---------- the reader ----------
-- Returns { title, prof = key or nil, steps = {...}, kind = "craft"/"gather" } or nil, reason
function PP.ParseGuide(text)
    if type(text) ~= "string" or not text:find("%d") then return nil, "Nothing to read. Paste a guide first." end
    if #text > 250000 then return nil, "Guide too long. Copy only the leveling table." end
    text = normalize(text)
    local lines = splitLines(text)
    local zones = zoneSet()
    local rows, sections = {}, {}
    local title, profHint, titleHasProf
    local row, sec, prevTo

    for _, raw in ipairs(lines) do
        local line = trim(raw)
        local hdrProf, hdrTitle = line:match("^ProfessionPal guide:%s*(.-)%s+%-%s+(.+)$")
        if hdrProf then profHint, title = hdrProf, hdrTitle end
        -- the guide's name: a short line with "guide" or "leveling" in it, not the site's search box
        if #line > 8 and #line < 90 and line:find("%a%a%a") and not line:find("\t") then
            local low = line:lower()
            if (low:find("guide") or low:find("leveling")) and not low:find("search") and not line:find("%.%.%.")
               and not low:find("^skill") then
                local hasProf = false
                for _, def in ipairs(PP.professions) do
                    if low:find(def.name:lower(), 1, true) then hasProf = true end
                end
                -- a title that names a profession beats one that doesn't
                if not title or (hasProf and not titleHasProf) then title, titleHasProf = line, hasProf end
            end
        end

        local a, b, rest = parseRange(line, prevTo)
        local sa, sb = nil, nil
        if not a and #line < 90 and not line:find("\t") then
            sa, sb = line:match("[Ff]rom%s+(%d+)%s+to%s+(%d+)")
            sa, sb = tonumber(sa), tonumber(sb)
            if sa and sb and (sb <= sa or sb > 300) then sa, sb = nil, nil end
        end

        if a then
            row = parseRow(a, b, rest)
            sec = nil
            if row then rows[#rows + 1] = row; prevTo = b end
        elseif sa then
            sec = { from = sa, to = sb, zones = {}, prose = {}, imported = true }
            sections[#sections + 1] = sec
            row = nil
            if not profHint then profHint = line:match("^(%a[%a ]-)%s+[Ff]rom%s+%d") end
        elseif row and line ~= "" then
            local n, name = parseMat(line)
            local low = line:lower()
            if n and #line < 50 then
                row.mats[#row.mats + 1] = { ItemIdByName(name) or name, n, name }
            elseif SOURCE_WORDS[low] then
                row.source = SOURCE_WORDS[low]
            else
                local isRecipe = false
                for _, p in ipairs(RECIPE_PREFIX) do
                    if line:sub(1, #p) == p then row.recipeItem = line; isRecipe = true end
                end
                if not isRecipe then
                    if row.recipeItem and not row.vendor and #line < 40 and not line:find("%.") then
                        row.vendor = line
                    else
                        row = nil      -- prose: the table ended
                    end
                end
            end
        elseif sec and line ~= "" then
            local z = zones[line:lower()]
            if z then
                local dup = false
                for _, have in ipairs(sec.zones) do if have == z then dup = true end end
                if not dup then sec.zones[#sec.zones + 1] = z end
            elseif #line > 25 and line:find("%a%a%a") and line ~= "ADVERTISEMENT" then
                sec.prose[#sec.prose + 1] = line
            end
        end
    end

    local steps, kind = {}, "craft"
    if #rows >= 2 then
        for _, r in ipairs(rows) do
            if r.recipeItem then
                r.tip = "Buy " .. r.recipeItem .. (r.vendor and (" (" .. r.vendor .. ")") or "") .. " first."
            end
            if r.zones then
                r.zoneList = { Horde = {}, Alliance = {} }
                for _, z in ipairs(r.zones) do
                    r.zoneList.Horde[#r.zoneList.Horde + 1] = { z, "" }
                    r.zoneList.Alliance[#r.zoneList.Alliance + 1] = { z, "" }
                end
                r.nodes = {}
                if not r.crafts then r.crafts = nil end
            end
            steps[#steps + 1] = r
        end
    elseif #sections >= 2 then
        kind = "gather"
        for _, s in ipairs(sections) do
            local st = { from = s.from, to = s.to, imported = true, nodes = {}, text = "Gather",
                         zoneList = { Horde = {}, Alliance = {} } }
            -- the zones are listed for both factions; closest-first sorting puts yours on top
            for _, z in ipairs(s.zones) do
                st.zoneList.Horde[#st.zoneList.Horde + 1] = { z, "" }
                st.zoneList.Alliance[#st.zoneList.Alliance + 1] = { z, "" }
            end
            if s.prose[1] then st.tip = firstSentence(s.prose[1]) end
            if s.prose[2] and #s.prose[1] < 60 then st.tip = st.tip .. " " .. firstSentence(s.prose[2]) end
            steps[#steps + 1] = st
        end
    else
        return nil, "Couldn't find steps. Copy the whole page with the skill ranges (like 1-25) in it."
    end
    table.sort(steps, function(x, y) if x.from ~= y.from then return x.from < y.from end return x.to < y.to end)

    -- which profession is it?
    local best, bestScore = nil, 0
    local hint = (profHint or "") .. " " .. (title or "")
    for _, def in ipairs(PP.professions) do
        local score = 0
        if hint:lower():find(def.name:lower(), 1, true) then score = score + 10 end
        local known = {}
        for _, s in ipairs(def.steps or {}) do known[s.text] = true end
        for name in pairs((PP.Recipes or {})[def.key] or {}) do known[name] = true end
        for _, s in ipairs(steps) do if known[s.text] then score = score + 3 end end
        if score > bestScore then best, bestScore = def.key, score end
    end
    local verb = { mining = "Mine", herbalism = "Pick herbs", skinning = "Skin beasts", fishing = "Fish" }
    if kind == "gather" and best and verb[best] then
        for _, s in ipairs(steps) do s.text = verb[best] end
    end

    return { title = title or "Imported guide", prof = best, steps = steps, kind = kind }
end

-- ---------- the share text (ProfessionPal's own simple format) ----------
function PP.GuideToText(def, guide)
    local out = { "ProfessionPal guide: " .. def.name .. " - " .. (guide.title or "Imported guide") }
    for _, st in ipairs(guide.steps) do
        local cells = { st.from .. "-" .. st.to, st.text }
        if st.crafts then cells[#cells + 1] = tostring(st.crafts) end
        for _, m in ipairs(st.mats or {}) do cells[#cells + 1] = m[2] .. "x " .. (m[3] or tostring(m[1])) end
        local zl = st.zoneList and st.zoneList.Alliance
        if zl and #zl > 0 then
            local names = {}
            for _, z in ipairs(zl) do names[#names + 1] = z[1] end
            cells[#cells + 1] = "go: " .. table.concat(names, ", ")
        end
        if st.tip then cells[#cells + 1] = "tip: " .. st.tip:gsub("|", "/") end
        out[#out + 1] = table.concat(cells, " | ")
    end
    return table.concat(out, "\n")
end

-- ---------- using an imported guide ----------
function PP:ImportedGuide(def)
    local g = self.db and self.db.guides and self.db.guides[def.key]
    if g and self.db.useGuide and self.db.useGuide[def.key] then return g end
end

-- ---------- Guides window ----------
function PP:BuildGuides()
    if self.guidesWin then return end
    local Text, Button = PP.UIText, PP.UIButton
    local g = CreateFrame("Frame", "ProfessionPalGuides", UIParent, "BackdropTemplate")
    self.guidesWin = g
    g:SetSize(560, 600)
    g:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    g:SetFrameStrata("DIALOG")
    g:SetClampedToScreen(true)
    PP.Skin(g, 40)
    g:EnableMouse(true); g:SetMovable(true); g:RegisterForDrag("LeftButton")
    g:SetScript("OnDragStart", g.StartMoving); g:SetScript("OnDragStop", g.StopMovingOrSizing)
    g:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, "ProfessionPalGuides") end
    local close = CreateFrame("Button", nil, g, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", g, "TOPRIGHT", -2, -2)

    g.title = Text(g, 18, C.gold, "CENTER"); g.title:SetPoint("TOP", g, "TOP", 0, -11)
    g.using = Text(g, 15, C.white); g.using:SetWidth(500); g.using:SetPoint("TOPLEFT", g, "TOPLEFT", 30, -48)

    g.useDefault = Button(g, "Use ProfessionPal guide", 220, 30, function() PP:SetGuide(false) end)
    g.useDefault:SetPoint("TOPLEFT", g, "TOPLEFT", 28, -96)
    g.useMine = Button(g, "Use imported guide", 190, 30, function() PP:SetGuide(true) end)
    g.useMine:SetPoint("LEFT", g.useDefault, "RIGHT", 8, 0)
    g.share = Button(g, "Share", 90, 30, function() PP:ShareGuide() end)
    g.share:SetPoint("TOPLEFT", g, "TOPLEFT", 28, -132)
    g.delete = Button(g, "Delete imported", 160, 30, function() PP:DeleteGuide() end)
    g.delete:SetPoint("LEFT", g.share, "RIGHT", 8, 0)

    g.head = Text(g, 16, C.gold); g.head:SetPoint("TOPLEFT", g, "TOPLEFT", 30, -178)
    g.head:SetText("IMPORT A GUIDE")
    g.how = Text(g, 14, C.gray); g.how:SetWidth(500); g.how:SetPoint("TOPLEFT", g, "TOPLEFT", 30, -200)
    g.how:SetText("1. Open the guide in your web browser.\n2. Press Ctrl+A, then Ctrl+C.\n3. Click in the box below and press Ctrl+V.")

    -- the paste box
    local box = CreateFrame("Frame", nil, g, "BackdropTemplate")
    box:SetSize(500, 150)
    box:SetPoint("TOPLEFT", g, "TOPLEFT", 28, -262)
    PP.Skin(box, nil, { bg = PP.THEME.inset })
    local ok, sf = pcall(CreateFrame, "ScrollFrame", "ProfessionPalGuidesScroll", box, "UIPanelScrollFrameTemplate")
    if not ok then sf = CreateFrame("ScrollFrame", "ProfessionPalGuidesScroll", box) end
    sf:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -8)
    sf:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -28, 8)
    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(0)
    eb:SetFont(PP.FONT, 13, "")
    eb:SetTextColor(1, 1, 1)
    eb:SetWidth(460)
    eb:SetHeight(140)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf:SetScrollChild(eb)
    box:EnableMouse(true)
    box:SetScript("OnMouseDown", function() eb:SetFocus() end)
    g.edit = eb

    g.read = Button(g, "Read guide", 140, 32, function() PP:ReadPasted() end)
    g.read:SetPoint("TOPLEFT", g, "TOPLEFT", 28, -422)
    g.clear = Button(g, "Clear", 90, 32, function() g.edit:SetText(""); g.parsed = nil; PP:RefreshGuides() end)
    g.clear:SetPoint("LEFT", g.read, "RIGHT", 8, 0)

    g.forText = Text(g, 15, C.white); g.forText:SetPoint("TOPLEFT", g, "TOPLEFT", 30, -468)
    g.change = Button(g, "Change", 100, 28, function() PP:CycleImportProf() end)
    g.change:SetPoint("TOPRIGHT", g, "TOPRIGHT", -30, -462)
    g.preview = Text(g, 14, C.white); g.preview:SetWidth(500); g.preview:SetPoint("TOPLEFT", g, "TOPLEFT", 30, -496)
    g.use = Button(g, "Use this guide", 180, 34, function() PP:SaveParsed() end)
    g.status = Text(g, 14, C.yellow); g.status:SetWidth(500)

    g:SetScript("OnShow", function() PP:RefreshGuides() end)
end

function PP:GuidesStatus(text, color)
    local g = self.guidesWin
    if not g then return end
    g.statusText, g.statusColor = text, color
    self:RefreshGuides()
end

function PP:RefreshGuides()
    local g = self.guidesWin
    if not (g and g:IsShown()) then return end
    local def = self:SelectedDef()
    if not def then return end
    g.title:SetText(def.name .. " - Guides")
    local saved = self.db.guides and self.db.guides[def.key]
    local active = self:ImportedGuide(def)
    if active then
        g.using:SetText("Using: " .. active.title .. "  (" .. #active.steps .. " steps, imported)")
        g.using:SetTextColor(unpack(C.green))
    else
        g.using:SetText("Using: ProfessionPal guide" .. (saved and ("\nSaved, not in use: " .. saved.title) or ""))
        g.using:SetTextColor(unpack(C.white))
    end
    local function onoff(btn, on) if on then btn:Enable() else btn:Disable() end end
    onoff(g.useDefault, active ~= nil)
    onoff(g.useMine, saved ~= nil and not active)
    onoff(g.share, saved ~= nil)
    onoff(g.delete, saved ~= nil)

    -- preview of what was read
    local y = -496
    local p = g.parsed
    if p then
        local pdef = p.prof and self.byKey[p.prof]
        g.forText:SetText("For: " .. (pdef and pdef.name or "?  pick one ->"))
        g.forText:Show(); g.change:Show()
        local lines = {}
        local last = p.steps[#p.steps]
        lines[1] = "Found " .. #p.steps .. " steps, skill " .. p.steps[1].from .. " to " .. last.to .. ":"
        for i = 1, math.min(5, #p.steps) do
            local s = p.steps[i]
            local t = "   " .. s.from .. "-" .. s.to .. "   " .. s.text
            if s.crafts then t = t .. "  x" .. s.crafts end
            if s.zoneList and s.zoneList.Alliance[1] then
                local names = {}
                for k, z in ipairs(s.zoneList.Alliance) do if k <= 3 then names[#names + 1] = z[1] end end
                t = t .. ":  " .. table.concat(names, ", ")
            end
            lines[#lines + 1] = t
        end
        if #p.steps > 5 then lines[#lines + 1] = "   ... and " .. (#p.steps - 5) .. " more" end
        g.preview:SetText(table.concat(lines, "\n"))
        g.preview:Show()
        local h = g.preview:GetStringHeight()
        if type(h) ~= "number" or h < 16 then h = 17 * #lines end
        y = y - h - 12
        g.use:ClearAllPoints(); g.use:SetPoint("TOPLEFT", g, "TOPLEFT", 28, y); g.use:Show()
        if pdef then g.use:Enable() else g.use:Disable() end
        y = y - 44
    else
        g.forText:Hide(); g.change:Hide(); g.preview:Hide(); g.use:Hide()
    end
    if g.statusText then
        g.status:SetText(g.statusText)
        g.status:SetTextColor(unpack(g.statusColor or C.yellow))
        g.status:ClearAllPoints(); g.status:SetPoint("TOPLEFT", g, "TOPLEFT", 30, y); g.status:Show()
        y = y - 40
    else
        g.status:Hide()
    end
    g:SetHeight(-y + 20)
end

function PP:ReadPasted()
    local g = self.guidesWin
    local guide, why = PP.ParseGuide(g.edit:GetText() or "")
    g.parsed = guide
    if not guide then self:GuidesStatus(why, C.red) return end
    if not guide.prof then
        local def = self:SelectedDef()
        guide.prof = def and def.key
        self:GuidesStatus("I couldn't tell which profession this is. Check 'For:' and click Change if needed.", C.yellow)
    else
        self:GuidesStatus(nil)
    end
end

function PP:CycleImportProf()
    local p = self.guidesWin.parsed
    if not p then return end
    local idx = 0
    for i, def in ipairs(self.professions) do if def.key == p.prof then idx = i end end
    p.prof = self.professions[idx % #self.professions + 1].key
    self:RefreshGuides()
end

function PP:SaveParsed()
    local g = self.guidesWin
    local p = g.parsed
    if not (p and p.prof) then return end
    self.db.guides = self.db.guides or {}
    self.db.useGuide = self.db.useGuide or {}
    self.db.guides[p.prof] = { title = p.title, steps = p.steps, kind = p.kind }
    self.db.useGuide[p.prof] = true
    self.db.selected = p.prof
    g.parsed = nil
    g.edit:SetText("")
    local def = self.byKey[p.prof]
    self:GuidesStatus("Done. " .. def.name .. " now follows: " .. p.title, C.green)
    self:Refresh()
end

function PP:SetGuide(useImported)
    local def = self:SelectedDef()
    self.db.useGuide = self.db.useGuide or {}
    self.db.useGuide[def.key] = useImported and true or nil
    self:GuidesStatus(useImported and "Now using your imported guide." or "Now using the ProfessionPal guide.", C.green)
    self:Refresh()
end

function PP:DeleteGuide()
    local def = self:SelectedDef()
    if self.db.guides then self.db.guides[def.key] = nil end
    if self.db.useGuide then self.db.useGuide[def.key] = nil end
    self:GuidesStatus("Imported guide deleted. Using the ProfessionPal guide.", C.white)
    self:Refresh()
end

function PP:ShareGuide()
    local def = self:SelectedDef()
    local saved = self.db.guides and self.db.guides[def.key]
    if not saved then return end
    local g = self.guidesWin
    g.edit:SetText(PP.GuideToText(def, saved))
    g.edit:SetFocus()
    g.edit:HighlightText()
    g.parsed = nil
    self:GuidesStatus("Press Ctrl+C to copy it, then paste it to a friend. They paste it in their Import box.", C.green)
end

function PP:ToggleGuides()
    self:BuildGuides()
    if self.guidesWin:IsShown() then self.guidesWin:Hide() else self.guidesWin:Show() end
end
