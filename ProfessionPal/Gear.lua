--[[ ProfessionPal - "Gear for you" picks (all crafting professions, all classes)
  Looks at a profession's crafted gear list, keeps what YOUR class can use at your
  level, scores it with simple stat weights for your role, compares it with what
  you wear, and shows the best thing to make for every slot.
  Not from a written guide (none exists for Forever yet). Display only.
]]

local _, PP = ...
local safe = PP.safe

PP.ROLE_NAMES = { auto = "Auto", dps = "Damage", tank = "Tank", heal = "Healer" }
PP.ROLE_ORDER = { "auto", "dps", "tank", "heal" }

-- stat weights (simple, per point). School powers: fsp fire, frsp frost, ssp shadow,
-- asp arcane, nsp nature, hsp holy (only the schools your class uses count, see SCHOOLS).
local W = {
    melee   = { str = 2, agi = 1, sta = 0.5, crit = 1, hit = 1, ap = 0.5, dps = 10, rdps = 1, arm = 0.01, barm = 0.01 },
    ret     = { str = 2, agi = 0.5, sta = 0.5, sp = 0.7, int = 0.3, crit = 1, hit = 1, ap = 0.5, dps = 10, arm = 0.01 },
    tank    = { sta = 1.5, def = 1.5, dod = 1.5, par = 1.5, blk = 1, arm = 0.03, barm = 0.03, str = 1, agi = 0.8, dps = 4, rdps = 0.5 },
    paltank = { sta = 1.5, def = 1.5, dod = 1.5, par = 1.5, blk = 1, arm = 0.03, barm = 0.03, str = 0.8, sp = 0.6, dps = 3 },
    heal    = { heal = 1, sp = 0.8, int = 1, spi = 0.5, sta = 0.3, mp5 = 2, arm = 0.005 },
    hunter  = { agi = 2, ap = 0.5, sta = 0.5, crit = 1, hit = 1, int = 0.3, str = 0.1, dps = 3, rdps = 10, arm = 0.005 },
    rogue   = { agi = 2, str = 1, ap = 0.5, sta = 0.5, crit = 1, hit = 1, dps = 10, rdps = 1 },
    enh     = { str = 2, agi = 1, sta = 0.5, int = 0.3, ap = 0.5, crit = 1, hit = 1, dps = 10, arm = 0.01 },
    caster  = { sp = 1, int = 0.8, sta = 0.3, crit = 0.5, hit = 0.5, spi = 0.2, school = 0.9 },
    feral   = { agi = 2, str = 1.5, sta = 0.8, ap = 0.5, crit = 1, hit = 1, arm = 0.02, barm = 0.02 },
}

local CLASS_ROLE_WEIGHTS = {
    WARRIOR = { dps = "melee", tank = "tank", heal = "melee" },
    PALADIN = { dps = "ret", tank = "paltank", heal = "heal" },
    SHAMAN  = { dps = "enh", tank = "enh", heal = "heal" },
    HUNTER  = { dps = "hunter", tank = "hunter", heal = "hunter" },
    ROGUE   = { dps = "rogue", tank = "rogue", heal = "rogue" },
    DRUID   = { dps = "feral", tank = "feral", heal = "heal" },
    PRIEST  = { dps = "caster", tank = "caster", heal = "heal" },
    MAGE    = { dps = "caster", tank = "caster", heal = "caster" },
    WARLOCK = { dps = "caster", tank = "caster", heal = "caster" },
}
local AUTO_ROLE = { WARRIOR = "tank", PALADIN = "heal", SHAMAN = "heal", DRUID = "heal", PRIEST = "heal" }

-- spell schools each class uses for damage
local SCHOOLS = {
    MAGE = { fsp = true, frsp = true, asp = true },
    WARLOCK = { ssp = true, fsp = true },
    PRIEST = { ssp = true },
    DRUID = { nsp = true, asp = true },
    SHAMAN = { nsp = true, fsp = true },
}

-- weapon types each class can use (Classic rules): 0/1 axe, 3 gun, 4/5 mace, 6 polearm,
-- 7/8 sword, 10 staff, 13 fist, 15 dagger, 19 wand
local WEAPONS = {
    WARRIOR = { [0] = 1, [1] = 1, [3] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1 },
    PALADIN = { [0] = 1, [1] = 1, [4] = 1, [5] = 1, [6] = 1, [7] = 1, [8] = 1 },
    HUNTER  = { [0] = 1, [1] = 1, [3] = 1, [6] = 1, [7] = 1, [8] = 1, [10] = 1, [13] = 1, [15] = 1 },
    ROGUE   = { [3] = 1, [4] = 1, [7] = 1, [13] = 1, [15] = 1 },
    SHAMAN  = { [0] = 1, [1] = 1, [4] = 1, [5] = 1, [10] = 1, [13] = 1, [15] = 1 },
    DRUID   = { [4] = 1, [5] = 1, [6] = 1, [10] = 1, [13] = 1, [15] = 1 },
    PRIEST  = { [4] = 1, [10] = 1, [15] = 1, [19] = 1 },
    MAGE    = { [7] = 1, [10] = 1, [15] = 1, [19] = 1 },
    WARLOCK = { [7] = 1, [10] = 1, [15] = 1, [19] = 1 },
}
local TWO_HAND = { [1] = true, [5] = true, [6] = true, [8] = true, [10] = true }
local RANGED = { [3] = true, [19] = true }
local LEATHER = { WARRIOR = 1, PALADIN = 1, HUNTER = 1, ROGUE = 1, SHAMAN = 1, DRUID = 1 }
local SHIELD = { WARRIOR = 1, PALADIN = 1, SHAMAN = 1 }
local HELD_OFFHAND = { MAGE = 1, WARLOCK = 1, PRIEST = 1, DRUID = 1, SHAMAN = 1, PALADIN = 1 }

-- inventory type -> equipped slot we compare with
local EQUIP_SLOT = { [1] = 1, [3] = 3, [5] = 5, [20] = 5, [6] = 6, [7] = 7, [8] = 8, [9] = 9, [10] = 10,
                     [16] = 15, [13] = 16, [17] = 16, [21] = 16, [14] = 17, [22] = 17, [23] = 17,
                     [15] = 18, [25] = 18, [26] = 18 }
PP.SLOT_ORDER = { 1, 3, 5, 9, 10, 6, 7, 8, 15, 16, 17, 18 }
PP.EQUIP_NAMES = { [1] = "Head", [3] = "Shoulders", [5] = "Chest", [9] = "Wrists", [10] = "Hands",
                   [6] = "Waist", [7] = "Legs", [8] = "Feet", [15] = "Cloak", [16] = "Weapon",
                   [17] = "Off-hand", [18] = "Ranged" }
PP.SLOT_NAMES = setmetatable({}, { __index = function(_, invType)
    return PP.EQUIP_NAMES[EQUIP_SLOT[invType] or 0] or ""
end })

-- Blizzard stat names -> our short keys
local STAT_KEYS = {
    ITEM_MOD_STRENGTH_SHORT = "str", ITEM_MOD_AGILITY_SHORT = "agi", ITEM_MOD_STAMINA_SHORT = "sta",
    ITEM_MOD_INTELLECT_SHORT = "int", ITEM_MOD_SPIRIT_SHORT = "spi", RESISTANCE0_NAME = "arm",
    ITEM_MOD_SPELL_POWER_SHORT = "sp", ITEM_MOD_SPELL_HEALING_DONE_SHORT = "heal",
    ITEM_MOD_HIT_RATING_SHORT = "hit", ITEM_MOD_CRIT_RATING_SHORT = "crit",
    ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "def", ITEM_MOD_DODGE_RATING_SHORT = "dod",
    ITEM_MOD_PARRY_RATING_SHORT = "par", ITEM_MOD_BLOCK_RATING_SHORT = "blk",
    ITEM_MOD_ATTACK_POWER_SHORT = "ap", ITEM_MOD_DAMAGE_PER_SECOND_SHORT = "dps",
    ITEM_MOD_MANA_REGENERATION_SHORT = "mp5",
}

-- Blacksmithing plans sold by the Azeroth Commerce Authority (Wowhead overview)
local ACA_NAMES = { "^Acolyte's", "^Crusader's", "^Guard's", "^Protector's", "^Veteran's",
                    "^Justicar's", "^Officer's", "^Prefect's", "^Sentinel's", "^Warder's",
                    "^Thorium Cestus", "^Thorium Greatmace", "^Enriched Thorium", "^Legionite Glaive" }

-- turn a data row into a named table (once)
local function Item(r, profKey)
    if r.id then return r end
    r.id, r.name, r.skill, r.level, r.class, r.sub, r.slot, r.q, r.src, r.spec, r.st, r.mats =
        r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12]
    r.st = r.st or {}
    local school = PP.GearSchool and PP.GearSchool[r.id]
    if school then for k, v in pairs(school) do r.st[k] = v end end
    if r.src == "P" and profKey == "blacksmithing" then
        for _, pat in ipairs(ACA_NAMES) do
            if r.name:find(pat) then r.aca = true break end
        end
    end
    return r
end

function PP:PlayerClass()
    local p = { safe(UnitClass, "player") }
    return p[2] or "WARRIOR"
end

function PP:Role()
    local r = self.db and self.db.role
    if r and r ~= "auto" then return r end
    return AUTO_ROLE[self:PlayerClass()] or "dps"
end

function PP:Weights()
    local cls = self:PlayerClass()
    local map = CLASS_ROLE_WEIGHTS[cls] or CLASS_ROLE_WEIGHTS.WARRIOR
    return W[map[self:Role()]] or W.melee
end

local function Score(st, w, cls)
    local s, schools = 0, SCHOOLS[cls] or {}
    for k, v in pairs(st) do
        if type(v) == "number" then
            if w[k] then
                s = s + v * w[k]
            elseif schools[k] then
                s = s + v * (w.school or w.sp or 0)
            end
        end
    end
    return s
end

-- Can this class use the item at this character level?
function PP:CanUse(it, level)
    local cls = self:PlayerClass()
    local role = self:Role()
    if it.class == 2 then
        if not (WEAPONS[cls] or {})[it.sub] then return false end
        if role == "tank" and TWO_HAND[it.sub] and cls ~= "DRUID" then return false end
        return true
    end
    local sub = it.sub
    if sub == -6 or sub == 1 then return true end                       -- cloaks, cloth
    if sub == -5 then return HELD_OFFHAND[cls] and true or false end     -- held in off-hand
    if sub == 6 then return SHIELD[cls] and role ~= "dps" or (cls == "WARRIOR" and role == "tank") end
    if sub == 2 then return LEATHER[cls] and true or false end
    if sub == 3 then
        if cls == "WARRIOR" or cls == "PALADIN" then return true end
        if cls == "HUNTER" or cls == "SHAMAN" then return level >= 40 end
        return false
    end
    if sub == 4 then return (cls == "WARRIOR" or cls == "PALADIN") and level >= 40 end
    return false
end

local function KnowsSpec(spec)
    if not spec or spec == 0 then return true end
    return (IsPlayerSpell and safe(IsPlayerSpell, spec)) and true or false
end

-- Score of what you wear in that equipped slot (nil if the game won't tell us)
local equipCache = {}
function PP:EquippedScore(inv, w)
    if not inv or not GetInventoryItemLink then return nil end
    local link = safe(GetInventoryItemLink, "player", inv)
    if not link then return 0 end
    local stats = equipCache[link]
    if not stats then
        local raw = (C_Item and C_Item.GetItemStats and safe(C_Item.GetItemStats, link))
                    or (GetItemStats and safe(GetItemStats, link))
        if type(raw) ~= "table" then return nil end
        stats = {}
        for k, v in pairs(raw) do
            local key = STAT_KEYS[k]
            if key and type(v) == "number" then stats[key] = (stats[key] or 0) + v end
        end
        equipCache[link] = stats
    end
    return Score(stats, w, self:PlayerClass())
end

function PP:GearListFor(def)
    if not def then return nil end
    if def.gear then return def.gear end
    return PP.GearLists and PP.GearLists[def.key]
end

-- One row per equipped slot:
--   { inv, name, now = {it, score, gain, upgrade}, next = {it, score} }
function PP:GearBySlot(def, skill)
    local list = self:GearListFor(def)
    if not list then return {} end
    skill = skill or 0
    local level = self:PlayerLevel()
    local w = self:Weights()
    local cls = self:PlayerClass()
    local best, soon = {}, {}

    for _, r in ipairs(list) do
        local it = Item(r, def.key)
        local inv = EQUIP_SLOT[it.slot]
        if inv and KnowsSpec(it.spec) and self:CanUse(it, math.max(level, it.level)) then
            local sc = Score(it.st, w, cls)
            if sc >= 3 then
                if skill >= it.skill and it.level <= level + 2 then
                    if not best[inv] or sc > best[inv].score then best[inv] = { it = it, score = sc } end
                elseif it.skill > skill and it.skill <= skill + 40 and it.level <= level + 8 then
                    local s = soon[inv]
                    if not s or it.skill < s.it.skill or (it.skill == s.it.skill and sc > s.score) then
                        soon[inv] = { it = it, score = sc }
                    end
                end
            end
        end
    end

    local rows = {}
    for _, inv in ipairs(PP.SLOT_ORDER) do
        local now, nx = best[inv], soon[inv]
        if now or nx then
            local eq = self:EquippedScore(inv, w)
            if now then
                now.gain = now.score - (eq or 0)
                now.upgrade = (eq == nil) or now.score > eq * 1.05 + 0.5
            end
            local floor = math.max(now and now.score or 0, eq or 0)
            if nx and not (nx.score > floor * 1.1 + 1) then nx = nil end
            if now or nx then
                rows[#rows + 1] = { inv = inv, name = PP.EQUIP_NAMES[inv], now = now, next = nx, eq = eq }
            end
        end
    end
    return rows
end

-- Top 3 upgrades you can make now (best gain first) and the soonest good unlock
function PP:GearPicks(def, skill)
    local now, nextPick = {}, nil
    for _, row in ipairs(self:GearBySlot(def, skill)) do
        if row.now and row.now.upgrade then now[#now + 1] = row.now end
        if row.next and (not nextPick or row.next.it.skill < nextPick.it.skill) then nextPick = row.next end
    end
    table.sort(now, function(a, b) return a.gain > b.gain end)
    while #now > 3 do table.remove(now) end
    return now, nextPick
end

function PP:GearSourceText(it)
    if it.src == "T" then return "trainer" end
    if it.aca then return "plans: Commerce Authority" end
    return "recipe needed"
end

-- Hover text for a gear row
function PP:GearTooltip(owner, it)
    if not (GameTooltip and it) then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if GameTooltip.SetItemByID then
        if not pcall(GameTooltip.SetItemByID, GameTooltip, it.id) then GameTooltip:SetText(it.name) end
    else
        GameTooltip:SetText(it.name)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Skill " .. it.skill .. "  -  " .. self:GearSourceText(it), 1, 0.82, 0)
    for _, m in ipairs(it.mats or {}) do
        local name = (C_Item and C_Item.GetItemNameByID and safe(C_Item.GetItemNameByID, m[1])) or ("item " .. m[1])
        local have = self:Count(m[1])
        local ok = have >= m[2]
        GameTooltip:AddDoubleLine(name, have .. " / " .. m[2], 1, 1, 1, ok and 0.2 or 1, ok and 1 or 0.25, ok and 0.2 or 0.25)
    end
    GameTooltip:AddLine("Picked by stats for: " .. PP.ROLE_NAMES[self:Role()], 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

local QUALITY = { [2] = { 0.12, 1, 0 }, [3] = { 0, 0.55, 1 }, [4] = { 0.64, 0.21, 0.93 } }
function PP.QualityColor(q) return QUALITY[q] or { 1, 1, 1 } end

-- hook the gear lists onto professions
if PP.byKey.blacksmithing then PP.byKey.blacksmithing.gear = PP.BSGear end

-- refresh when gear changes
if PP.eventFrame then
    pcall(PP.eventFrame.RegisterEvent, PP.eventFrame, "PLAYER_EQUIPMENT_CHANGED")
end
