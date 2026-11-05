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

-- Trainers for a rank: ones in your current zone first, then your faction, then neutral.
function PP:TrainersFor(def, rankIndex)
    local set = def.trainers and def.trainers[rankIndex]
    if not set then return {} end
    local fac = self:Faction()
    local list = PP.Join(set[fac], set.Neutral)
    local map = self:CurrentMap()
    table.sort(list, function(a, b)
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
    "GET_ITEM_INFO_RECEIVED", "ZONE_CHANGED_NEW_AREA", "PLAYER_LEVEL_UP", "SPELLS_CHANGED",
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
