--[[ ProfessionPal - Core
  A display-only profession leveling guide for WoW: Forever.
  It never crafts, gathers, buys, moves or clicks anything for you.
  It only reads your skill level and bag/bank counts and shows text.

  How data works (so more professions can be added later):
    PP:AddProfession{ key, name, skillLine, icon, ranks, trainers, steps, altSteps, zones }
    steps = { { from, to, text, crafts, mats = { {id or name, perCraft, "Name"} }, ... } }
  See Data_Mining.lua and Data_Blacksmithing.lua.
]]

local ADDON, PP = ...
PP = PP or {}
_G.ProfessionPal = PP

PP.professions = {}
PP.byKey = {}

PP.FONT = "Fonts\\FRIZQT__.TTF"
PP.C = {
    gold   = { 1.00, 0.82, 0.00 },
    white  = { 1.00, 1.00, 1.00 },
    green  = { 0.20, 1.00, 0.20 },
    red    = { 1.00, 0.25, 0.25 },
    orange = { 1.00, 0.55, 0.15 },
    gray   = { 0.70, 0.70, 0.70 },
    yellow = { 1.00, 1.00, 0.55 },
}

local DEFAULTS = {
    selected = nil,       -- profession key shown in the window
    smeltFirst = {},      -- [key] = true : use the "buy ore and smelt" plan
    scale = 1.0,
    locked = false,
    point = nil,          -- saved window position
    told = {},            -- [key..rank] = true : "time to train" chat note already shown
    tracker = true,       -- small on-screen guide box
    trackerAlpha = 0.6,   -- tracker background opacity
    trackerScale = 1.0,
    trackerLocked = false,
    trackerHideCombat = true,
    trackerPoint = nil,
    trackerButtons = true, -- spell buttons (Find Minerals, Smelting, ...) on the tracker
    role = "auto",         -- gear picks: auto / dps / tank / heal
    showAll = false,       -- show every profession tab, not only the ones you know
    autoLearn = false,     -- learn guide recipes when a trainer window is open (OFF by default)
    autoLearnMax = 10,     -- spending limit per trainer visit, in gold
}

-- ---------- small safe helpers ----------
local function pack(...) return { n = select("#", ...), ... } end

local function safe(fn, ...)
    if type(fn) ~= "function" then return nil end
    local r = pack(pcall(fn, ...))
    if r[1] then return unpack(r, 2, r.n) end
    return nil
end
PP.safe = safe

local function isNum(v)
    if type(v) ~= "number" then return false end
    if issecretvalue and safe(issecretvalue, v) then return false end
    return true
end

function PP:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100ProfessionPal:|r " .. tostring(msg))
    end
end

function PP:AddProfession(def)
    self.professions[#self.professions + 1] = def
    self.byKey[def.key] = def
end

-- Join several trainer lists into one (used for "who teaches this rank").
function PP.Join(...)
    local out = {}
    for i = 1, select("#", ...) do
        local list = select(i, ...)
        if list then for _, t in ipairs(list) do out[#out + 1] = t end end
    end
    return out
end

-- Short trainer rows { name, place, mapID, x, y, junior = true } -> { n, p, m, x, y, order }
function PP.TrainerList(rows)
    local out = {}
    for i, r in ipairs(rows or {}) do
        if r.n then
            out[#out + 1] = r
        else
            out[#out + 1] = { n = r[1], p = r[2], m = r[3], x = r[4], y = r[5], order = i, junior = r.junior }
        end
    end
    return out
end

-- { [rank] = { A = rows, H = rows } } -> trainers[rank] = { Alliance, Horde, Neutral }.
-- A trainer for a higher rank also teaches the lower ranks, so each rank gets
-- its own list plus every higher list. Names on both sides become Neutral.
function PP.TrainerRanks(byRank)
    local out = {}
    for r = 1, 4 do
        local seenA, seenH, a, h = {}, {}, {}, {}
        for k = r, 4 do
            local set = byRank[k]
            if set then
                for _, t in ipairs(PP.TrainerList(set.A)) do
                    if not seenA[t.n] then seenA[t.n] = true; t.order = (k - r) * 50 + (t.order or 0); a[#a + 1] = t end
                end
                for _, t in ipairs(PP.TrainerList(set.H)) do
                    if not seenH[t.n] then seenH[t.n] = true; t.order = (k - r) * 50 + (t.order or 0); h[#h + 1] = t end
                end
            end
        end
        if #a > 0 or #h > 0 then
            local res = { Alliance = {}, Horde = {}, Neutral = {} }
            for _, t in ipairs(a) do
                if seenH[t.n] then res.Neutral[#res.Neutral + 1] = t else res.Alliance[#res.Alliance + 1] = t end
            end
            for _, t in ipairs(h) do
                if not seenA[t.n] then res.Horde[#res.Horde + 1] = t end
            end
            out[r] = res
        end
    end
    return out
end

-- How many of a material for n crafts. Steps marked total = true list the
-- material for the whole step, others list it per craft.
function PP.MatNeed(st, m, n)
    if st.total then
        if not st.crafts or st.crafts <= 0 then return m[2] end
        return math.ceil(m[2] * n / st.crafts)
    end
    return m[2] * n
end

-- ---------- reading the player's real skill ----------
-- Returns skill, maxSkill  (nil if you do not know the profession)
function PP:GetSkill(def)
    -- Retail-style API (Forever uses the 12.x client)
    if GetProfessions and GetProfessionInfo then
        local list = pack(safe(GetProfessions))
        for i = 1, list.n do
            local idx = list[i]
            if idx then
                local p = pack(safe(GetProfessionInfo, idx))
                local name, rank, max, line = p[1], p[3], p[4], p[7]
                if (line == def.skillLine or name == def.name) and isNum(rank) then
                    return rank, isNum(max) and max or nil
                end
            end
        end
    end
    -- Classic-style skill list
    if GetNumSkillLines and GetSkillLineInfo then
        local n = safe(GetNumSkillLines) or 0
        if not isNum(n) then n = 0 end
        for i = 1, n do
            local p = pack(safe(GetSkillLineInfo, i))
            if p[1] == def.name and not p[2] and isNum(p[4]) then
                return p[4], isNum(p[7]) and p[7] or nil
            end
        end
    end
    -- Last try: trade skill API (works once the profession window was opened)
    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = safe(C_TradeSkillUI.GetProfessionInfoBySkillLineID, def.skillLine)
        if type(info) == "table" and isNum(info.skillLevel) and info.skillLevel > 0 then
            return info.skillLevel, isNum(info.maxSkillLevel) and info.maxSkillLevel or nil
        end
    end
    return nil
end

-- ---------- bags + bank counts ----------
function PP:Count(item)
    if item == nil then return 0 end
    local n
    if C_Item and C_Item.GetItemCount then
        n = safe(C_Item.GetItemCount, item, true, false, true, true)
        if n == nil then n = safe(C_Item.GetItemCount, item, true) end
    end
    if n == nil and GetItemCount then n = safe(GetItemCount, item, true) end
    if not isNum(n) then return 0 end
    return n
end

function PP:Icon(item, fallback)
    local icon
    if type(item) == "number" and C_Item then
        icon = safe(C_Item.GetItemIconByID, item)
        if not icon and C_Item.RequestLoadItemDataByID then
            safe(C_Item.RequestLoadItemDataByID, item)
        end
    elseif type(item) == "string" and C_Item and C_Item.GetItemIconByID then
        icon = safe(C_Item.GetItemIconByID, item)
    end
    return icon or fallback or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function PP:Faction()
    local f = safe(UnitFactionGroup, "player")
    if f == "Horde" or f == "Alliance" then return f end
    return "Alliance"
end

function PP:PlayerLevel()
    local l = safe(UnitLevel, "player")
    return isNum(l) and l or 1
end

function PP:CurrentMap()
    if C_Map and C_Map.GetBestMapForUnit then
        local m = safe(C_Map.GetBestMapForUnit, "player")
        if isNum(m) then return m end
    end
end

-- ---------- profession spells (for the tracker buttons) ----------
function PP:KnowsSpell(sp)
    if sp.id and IsPlayerSpell and safe(IsPlayerSpell, sp.id) then return true end
    if sp.id and C_SpellBook and C_SpellBook.IsSpellKnown and safe(C_SpellBook.IsSpellKnown, sp.id) then return true end
    if C_Spell and C_Spell.GetSpellInfo and safe(C_Spell.GetSpellInfo, sp.name) then return true end
    return false
end

-- Spells you know from professions you have learned
function PP:ActionSpells()
    local out = {}
    for _, def in ipairs(self.professions) do
        if def.spells and self:GetSkill(def) then
            for _, sp in ipairs(def.spells) do
                if self:KnowsSpell(sp) then out[#out + 1] = sp end
            end
        end
    end
    return out
end

function PP:SpellIcon(sp)
    local tex
    if C_Spell and C_Spell.GetSpellTexture then
        tex = safe(C_Spell.GetSpellTexture, sp.name) or (sp.id and safe(C_Spell.GetSpellTexture, sp.id))
    end
    return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

function PP:InCombat()
    return safe(InCombatLockdown) and true or false
end

-- ---------- where you are: distances, closest first ----------
-- Classic zone map IDs, so we can measure how far a zone is from you.
local ZONE_MAP = {
    ["Durotar"] = 1411, ["Mulgore"] = 1412, ["The Barrens"] = 1413, ["Alterac Mountains"] = 1416,
    ["Arathi Highlands"] = 1417, ["Badlands"] = 1418, ["Tirisfal Glades"] = 1420, ["Silverpine Forest"] = 1421,
    ["Western Plaguelands"] = 1422, ["Eastern Plaguelands"] = 1423, ["Hillsbrad Foothills"] = 1424,
    ["The Hinterlands"] = 1425, ["Dun Morogh"] = 1426, ["Searing Gorge"] = 1427, ["Burning Steppes"] = 1428,
    ["Elwynn Forest"] = 1429, ["Duskwood"] = 1431, ["Loch Modan"] = 1432, ["Redridge Mountains"] = 1433,
    ["Stranglethorn Vale"] = 1434, ["Swamp of Sorrows"] = 1435, ["Westfall"] = 1436, ["Wetlands"] = 1437,
    ["Teldrassil"] = 1438, ["Darkshore"] = 1439, ["Ashenvale"] = 1440, ["Thousand Needles"] = 1441,
    ["Stonetalon Mountains"] = 1442, ["Desolace"] = 1443, ["Feralas"] = 1444, ["Dustwallow Marsh"] = 1445,
    ["Tanaris"] = 1446, ["Azshara"] = 1447, ["Felwood"] = 1448, ["Un'Goro Crater"] = 1449,
    ["Moonglade"] = 1450, ["Silithus"] = 1451, ["Winterspring"] = 1452,
    ["Zephras Isle"] = 2521, ["Riverglades"] = 2548,
}
PP.ZONE_MAP = ZONE_MAP

-- Each race's starting zone (used only if your position can't be read)
local HOME_ZONE = {
    Human = "Elwynn Forest", Dwarf = "Dun Morogh", Gnome = "Dun Morogh", NightElf = "Teldrassil",
    Orc = "Durotar", Troll = "Durotar", Tauren = "Mulgore", Scourge = "Tirisfal Glades", Undead = "Tirisfal Glades",
}

local worldCache = {}
-- World position of a map point: continentID, x, y  (nil if the game won't say)
local function WorldPos(map, x, y)
    if not (map and C_Map and C_Map.GetWorldPosFromMapPos) then return nil end
    local key = map .. ":" .. x .. ":" .. y
    local c = worldCache[key]
    if c then return c[1], c[2], c[3] end
    local vec = CreateVector2D and safe(CreateVector2D, x, y) or { x = x, y = y }
    local p = pack(safe(C_Map.GetWorldPosFromMapPos, map, vec))
    local cont, pos = p[1], p[2]
    if not (isNum(cont) and type(pos) == "table") then return nil end
    local px = pos.x or (pos.GetXY and select(1, pos:GetXY()))
    local py = pos.y or (pos.GetXY and select(2, pos:GetXY()))
    if not (isNum(px) and isNum(py)) then return nil end
    worldCache[key] = { cont, px, py }
    return cont, px, py
end

-- Your own world position: continentID, x, y
function PP:PlayerWorld()
    local map = self:CurrentMap()
    if map and C_Map and C_Map.GetPlayerMapPosition then
        local pos = safe(C_Map.GetPlayerMapPosition, map, "player")
        if type(pos) == "table" then
            local x = pos.x or (pos.GetXY and select(1, pos:GetXY()))
            local y = pos.y or (pos.GetXY and select(2, pos:GetXY()))
            if isNum(x) and isNum(y) then
                local c, wx, wy = WorldPos(map, x, y)
                if c then return c, wx, wy end
            end
        end
    end
    if UnitPosition then
        local p = pack(safe(UnitPosition, "player"))
        if isNum(p[1]) and isNum(p[2]) and isNum(p[4]) then return p[4], p[2], p[1] end
    end
    return nil
end

-- Yards from you to a map point (x, y in 0-100). Other continent = very far. nil = unknown.
function PP:Distance(map, x, y, me)
    me = me or { self:PlayerWorld() }
    if not me[1] or not map then return nil end
    local c, wx, wy = WorldPos(map, (x or 50) / 100, (y or 50) / 100)
    if not c then return nil end
    if c ~= me[1] then return 1e7 end
    local dx, dy = wx - me[2], wy - me[3]
    return math.sqrt(dx * dx + dy * dy)
end

function PP:CurrentZoneName()
    local z = safe(GetZoneText)
    if type(z) == "string" and z ~= "" then return z end
    local map = self:CurrentMap()
    if map and C_Map and C_Map.GetMapInfo then
        local info = safe(C_Map.GetMapInfo, map)
        if type(info) == "table" and type(info.name) == "string" then return info.name end
    end
end

-- Zones for this step and your faction, closest to you first:
-- { {name, level, tip, here, dist}, ... }
function PP:ZoneOptions(def, st)
    local list = {}
    local fac = self:Faction()
    if st.zones and def.zones then
        for _, key in ipairs(st.zones[fac] or {}) do
            local z = def.zones[key]
            if z then list[#list + 1] = { name = z[1], level = z[2], tip = z[3] } end
        end
    elseif st.zoneList then
        for _, z in ipairs(st.zoneList[fac] or {}) do
            list[#list + 1] = { name = z[1], tip = (z[2] and z[2] ~= "") and z[2] or nil }
        end
    end
    local me = { self:PlayerWorld() }
    local here = self:CurrentZoneName()
    local race = select(2, safe(UnitRace, "player"))
    local home = race and HOME_ZONE[race]
    for i, z in ipairs(list) do
        z.order = i
        z.here = (here ~= nil and z.name == here)
        z.dist = self:Distance(ZONE_MAP[z.name], 50, 50, me)
    end
    table.sort(list, function(a, b)
        if a.here ~= b.here then return a.here end
        if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
        if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
        local ah, bh = (home and a.name == home) and 1 or 0, (home and b.name == home) and 1 or 0
        if ah ~= bh then return ah > bh end
        return a.order < b.order
    end)
    return list
end

-- ---------- ranks + training ----------
-- cur = index of the rank you have (0 = not learned), nxt = next rank table
function PP:RankInfo(def, skill, max)
    if not skill then return 0, def.ranks[1], 1 end
    local cur
    if max then
        for i, r in ipairs(def.ranks) do if r.cap == max then cur = i end end
    end
    if not cur then
        cur = #def.ranks
        for i, r in ipairs(def.ranks) do if skill < r.cap then cur = i break end end
    end
    return cur, def.ranks[cur + 1], cur + 1
end

-- Highest skill you can reach right now (your current cap)
function PP:BracketEnd(def, skill, max)
    if max and max > 0 then return max end
    local cur = self:RankInfo(def, skill, max)
    local r = def.ranks[cur] or def.ranks[1]
    return r.cap
end

-- Trainers for a rank (your faction + neutral), closest to you first.
-- If your position can't be read: same zone first, then the guide's order.
function PP:TrainersFor(def, rankIndex)
    local set = def.trainers and def.trainers[rankIndex]
    if not set then return {} end
    local fac = self:Faction()
    local list = PP.Join(set[fac], set.Neutral)
    local map = self:CurrentMap()
    local me = { self:PlayerWorld() }
    for _, t in ipairs(list) do t.dist = self:Distance(t.m, t.x, t.y, me) end
    table.sort(list, function(a, b)
        if a.dist and b.dist and a.dist ~= b.dist then return a.dist < b.dist end
        if (a.dist ~= nil) ~= (b.dist ~= nil) then return a.dist ~= nil end
        local ah, bh = (map and a.m == map) and 1 or 0, (map and b.m == map) and 1 or 0
        if ah ~= bh then return ah > bh end
        return (a.order or 99) < (b.order or 99)
    end)
    return list
end

-- ---------- the plan ----------
function PP:UsingAlt(def, skill)
    return def.altSteps and self.db.smeltFirst[def.key] and (skill or 0) < def.altSteps.upTo
end

function PP:StepFor(def, skill)
    skill = skill or 0
    if self:UsingAlt(def, skill) then
        for _, st in ipairs(def.altSteps.steps) do
            if skill >= st.from and skill < st.to then return st end
        end
    end
    for _, st in ipairs(def.steps) do
        if skill >= st.from and skill < st.to then return st end
    end
    return nil
end

-- About how many crafts you need to go from skill a to skill b inside a step
function PP.CraftsFor(st, a, b)
    if not st.crafts then return 0 end
    a = math.max(a, st.from); b = math.min(b, st.to)
    if b <= a then return 0 end
    return math.max(1, math.ceil(st.crafts * (b - a) / (st.to - st.from)))
end

-- How many crafts to show for the step you are on right now
function PP:CraftsNow(st, skill)
    local n = PP.CraftsFor(st, skill or 1, st.to)
    if st.keepAll and st.makes then
        n = math.max(n, st.crafts - self:Count(st.makes))
    end
    return n
end

-- Shopping list from your skill up to the end of your bracket.
-- Returns list of { item, name, need, have, made }, endSkill, notes
function PP:ShoppingList(def, skill, max)
    skill = skill or 1
    local stop = self:BracketEnd(def, skill, max)
    if skill >= stop then
        local _, nxt = self:RankInfo(def, skill, max)
        if nxt then stop = nxt.cap end
    end
    local totals, order, notes = {}, {}, {}
    local made = {}
    local s, guard = skill, 0
    while s < stop and guard < 100 do
        guard = guard + 1
        local st = self:StepFor(def, s)
        if not st then break end
        local e = math.min(st.to, stop)
        local n = PP.CraftsFor(st, s, e)
        if st.keepAll and st.makes and e >= st.to then
            n = math.max(n, st.crafts - self:Count(st.makes))
        end
        if st.makes then made[st.makes] = true end
        for _, m in ipairs(st.mats or {}) do
            local key = m[1]
            if not totals[key] then
                totals[key] = { item = m[1], name = m[3] or tostring(m[1]), need = 0 }
                order[#order + 1] = key
            end
            totals[key].need = totals[key].need + PP.MatNeed(st, m, n)
        end
        if st.buyNote then notes[#notes + 1] = st.buyNote end
        if e <= s then break end
        s = e
    end
    local out = {}
    for _, key in ipairs(order) do
        local t = totals[key]
        t.have = self:Count(t.item)
        t.made = made[key] and true or false
        out[#out + 1] = t
    end
    return out, stop, notes
end

-- ---------- events ----------
local ev = CreateFrame("Frame")
PP.eventFrame = ev
local pending = false

function PP:RequestRefresh()
    if pending then return end
    pending = true
    local function go()
        pending = false
        PP:CheckTraining()
        if PP.Refresh then PP:Refresh() end
    end
    if C_Timer and C_Timer.After then C_Timer.After(0.2, go) else go() end
end

-- One chat note per rank when it is time to train (display only).
function PP:CheckTraining()
    if not self.db then return end
    for _, def in ipairs(self.professions) do
        local skill, max = self:GetSkill(def)
        if skill then
            local _, nxt, ni = self:RankInfo(def, skill, max)
            if nxt and skill >= nxt.skill then
                local k = def.key .. ni
                if not self.db.told[k] and self:PlayerLevel() >= (nxt.level or 0) then
                    self.db.told[k] = true
                    self:Print("Time to train |cffff8c26" .. nxt.name .. " " .. def.name .. "|r. Type /prof")
                end
            end
        end
    end
end

local EVENTS = {
    "PLAYER_LOGIN", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "TRADE_SKILL_LIST_UPDATE",
    "BAG_UPDATE_DELAYED", "BANKFRAME_OPENED", "PLAYERBANKSLOTS_CHANGED",
    "GET_ITEM_INFO_RECEIVED", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "PLAYER_LEVEL_UP", "SPELLS_CHANGED",
}
for _, e in ipairs(EVENTS) do pcall(ev.RegisterEvent, ev, e) end

ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        ProfessionPalDB = ProfessionPalDB or {}
        for k, v in pairs(DEFAULTS) do
            if ProfessionPalDB[k] == nil then
                if type(v) == "table" then ProfessionPalDB[k] = {} else ProfessionPalDB[k] = v end
            end
        end
        PP.db = ProfessionPalDB
        if PP.BuildUI then PP:BuildUI() end
    end
    if PP.db then PP:RequestRefresh() end
end)

SLASH_PROFESSIONPAL1 = "/prof"
SLASH_PROFESSIONPAL2 = "/professionpal"
SlashCmdList.PROFESSIONPAL = function()
    if PP.Toggle then PP:Toggle() end
end
