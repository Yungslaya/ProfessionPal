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

-- ---------- Merchant's Favor plans, known recipes, rare materials ----------
-- Some Forever plans are bought with Merchant's Favor (crate hand-ins) and some
-- pieces need rare materials. Picks you can't make right now get an easier
-- alternative, and the better piece is shown as "Better:" with what it needs.
local planIdx
local function norm(s) return (s:lower():gsub("s$", "")) end

function PP:FavorPlan(profKey, name)
    if not planIdx then
        planIdx = {}
        for pk, rows in pairs(PP.FavorPlans or {}) do
            local t = {}
            planIdx[pk] = t
            for _, r in ipairs(rows) do
                for i = 3, #r do t[norm(r[i])] = { skill = r[1], cost = r[2], name = r[i] } end
            end
        end
    end
    local t = profKey and planIdx[profKey]
    return t and name and t[norm(name)]
end

function PP:FavorHave()
    local id = PP.Favor and PP.Favor.currency
    if id and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = safe(C_CurrencyInfo.GetCurrencyInfo, id)
        if type(info) == "table" and type(info.quantity) == "number" then return info.quantity end
    end
    return 0
end

function PP:FavorCamp()
    local camps = PP.Favor and PP.Favor.camps
    return camps and camps[self:Faction()]
end

local function CharKey()
    return (safe(UnitName, "player") or "?") .. "-" .. (safe(GetRealmName) or "")
end

-- Remember the recipes you know (read when your profession window is open)
function PP:ScanKnownRecipes()
    if not (self.db and C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs) then return end
    local ids = safe(C_TradeSkillUI.GetAllRecipeIDs)
    if type(ids) ~= "table" or #ids == 0 then return end
    self.db.known = self.db.known or {}
    local key = CharKey()
    local t = self.db.known[key] or {}
    self.db.known[key] = t
    self.db.recipeMats = self.db.recipeMats or {}
    local mats = self.db.recipeMats
    local added = false
    for _, id in ipairs(ids) do
        local info = safe(C_TradeSkillUI.GetRecipeInfo, id)
        if type(info) == "table" and info.name then
            if info.learned and not t[info.name] then
                t[info.name] = true
                added = true
            end
            if info.learned then
                self.db.recipeIDs = self.db.recipeIDs or {}
                self.db.recipeIDs[info.name] = id
            end
            -- remember what this recipe needs (for the gear shopping lists)
            if not mats[info.name] and C_TradeSkillUI.GetRecipeSchematic then
                local sch = safe(C_TradeSkillUI.GetRecipeSchematic, id, false)
                if type(sch) == "table" and type(sch.reagentSlotSchematics) == "table" then
                    local list = {}
                    for _, slot in ipairs(sch.reagentSlotSchematics) do
                        local r = slot.reagents and slot.reagents[1]
                        local n = slot.quantityRequired
                        if r and r.itemID and type(n) == "number" and n > 0 and slot.required ~= false then
                            list[#list + 1] = { r.itemID, n }
                        end
                    end
                    if #list > 0 then mats[info.name] = list end
                end
            end
        end
    end
    if added and self.RequestRefresh then self:RequestRefresh() end
end

function PP:KnowsCraft(name)
    local t = self.db and self.db.known and self.db.known[CharKey()]
    return (t and name and t[name]) and true or false
end

-- Materials for one crafted piece: from our data, or read from your profession window
function PP:GearMats(it)
    if it.mats then return it.mats end
    local m = self.db and self.db.recipeMats
    return m and m[it.name]
end

function PP:MatName(id)
    return (C_Item and C_Item.GetItemNameByID and safe(C_Item.GetItemNameByID, id))
        or (PP.MatInfo and PP.MatInfo[id] and PP.MatInfo[id][1])
        or (PP.ScarceNames and PP.ScarceNames[id]) or ("Item " .. id)
end

function PP:MatWhere(id)
    if PP.ScarceMats and PP.ScarceMats[id] then return PP.ScarceMats[id] end
    local mi = PP.MatInfo and PP.MatInfo[id]
    if mi then return mi[2] end
    return "Buy it on the Auction House, or ask a friend who makes or gathers it."
end

-- Shopping list for one or more gear pieces (one of each).
-- Returns mats { id, name, have, need, where, rare, sub, done }, plans {it}, nomats {it}
function PP:GearShopping(items)
    local need, order, plans, nomats = {}, {}, {}, {}
    for _, it in ipairs(items) do
        local mats = self:GearMats(it)
        if mats then
            for _, m in ipairs(mats) do
                if not need[m[1]] then need[m[1]] = 0; order[#order + 1] = m[1] end
                need[m[1]] = need[m[1]] + m[2]
            end
        else
            nomats[#nomats + 1] = it
        end
        if it.src ~= "T" and not self:KnowsCraft(it.name) then plans[#plans + 1] = it end
    end
    -- groups: a material, plus what you make it from when you are short
    local groups = {}
    for i, id in ipairs(order) do
        local have, n = self:Count(id), need[id]
        local g = { i = i, done = have >= n }
        g[1] = { id = id, name = self:MatName(id), have = have, need = n, where = self:MatWhere(id),
                 rare = PP.ScarceMats and PP.ScarceMats[id] and true }
        local mk = PP.MakeFrom and PP.MakeFrom[id]
        if mk and have < n then
            g[2] = { id = mk[1], name = self:MatName(mk[1]), have = self:Count(mk[1]), need = (n - have) * mk[2],
                     where = self:MatWhere(mk[1]), sub = true }
        end
        groups[#groups + 1] = g
    end
    -- missing things first, things you already have at the bottom
    table.sort(groups, function(a, b)
        if a.done ~= b.done then return not a.done end
        return a.i < b.i
    end)
    local out = {}
    for _, g in ipairs(groups) do
        for _, r in ipairs(g) do out[#out + 1] = r end
    end
    return out, plans, nomats
end

-- Every piece the guide says to make right now (the "Make it!" rows)
function PP:GearShopAllItems(def, skill)
    local items = {}
    for _, row in ipairs(self:GearBySlot(def, skill)) do
        if row.now and row.now.upgrade then items[#items + 1] = row.now.it end
    end
    return items
end

-- ---------- "Craft it" button ----------
-- One click = one craft, exactly like the Create button in the game's own
-- profession window. The game itself checks for the anvil / fire / tools.
PP.CRAFT_WHERE = {
    blacksmithing = "Stand next to an anvil, with a Blacksmith Hammer in your bags.",
    cooking = "Stand next to a cooking fire. (You can make one with Basic Campfire.)",
    engineering = "Keep a Blacksmith Hammer and an Arclight Spanner in your bags for some items.",
    enchanting = "Works anywhere. Some items need an enchanting rod in your bags.",
}

function PP:MatsReady(it)
    local mats = self:GearMats(it)
    if not mats then return false end
    for _, m in ipairs(mats) do
        if self:Count(m[1]) < m[2] then return false end
    end
    return true
end

-- Show the Craft button: you have the materials and know (or can train) the recipe
function PP:CanCraft(it)
    return self:MatsReady(it) and (it.src == "T" or self:KnowsCraft(it.name))
end

local function ProfessionOpen()
    local pf = _G.ProfessionsFrame or _G.TradeSkillFrame
    return pf and pf.IsShown and pf:IsShown() and true or false
end

function PP:CraftGear(it)
    local ui = C_TradeSkillUI
    if not (it and ui) then return end
    if self:InCombat() then self:Print("You can't craft in combat.") return end
    local id = self.db.recipeIDs and self.db.recipeIDs[it.name]
    if id and ProfessionOpen() and ui.CraftRecipe then
        local info = safe(ui.GetRecipeInfo, id)
        if type(info) == "table" and info.learned == false then
            self:Print("Learn " .. it.name .. " at your trainer first.")
            return
        end
        safe(ui.CraftRecipe, id, 1)
        return
    end
    if not id and ProfessionOpen() and self:RecipesScanned() then
        self:Print("You don't know " .. it.name .. " yet. Learn it at your trainer first.")
        return
    end
    -- not open yet: open your profession at this recipe, then click again to craft
    if id and ui.OpenRecipe then
        safe(ui.OpenRecipe, id)
    else
        local def = self:SelectedDef()
        if def and def.skillLine and ui.OpenTradeSkill then safe(ui.OpenTradeSkill, def.skillLine) end
    end
    self:Print("Opened your profession. Click |cff33ff33Craft it|r again to make " .. it.name .. ".")
end

function PP:RecipesScanned()
    return (self.db and self.db.known and self.db.known[CharKey()]) and true or false
end

-- Can you make it right now?
--   "ready" : trainer recipe or one you know, rare materials in your bags
--   "buy"   : plans cost Merchant's Favor and you have enough
--   "need"  : plans/recipe you can't get yet, or rare materials you don't have
function PP:GearAccess(it)
    local state, why = "ready", {}
    if it.src ~= "T" and not self:KnowsCraft(it.name) then
        if it.plan then
            local have = self:FavorHave()
            if have >= it.plan.cost then
                state = "buy"
                why[#why + 1] = "buy plans: " .. it.plan.cost .. " Favor"
            else
                state = "need"
                why[#why + 1] = "needs plans: " .. it.plan.cost .. " Favor (you have " .. have .. ")"
            end
        else
            state = "need"
            why[#why + 1] = "needs a recipe (drop or vendor)"
        end
    end
    for _, m in ipairs(self:GearMats(it) or {}) do
        if PP.ScarceMats and PP.ScarceMats[m[1]] then
            local have = self:Count(m[1])
            if have < m[2] then
                local nm = (C_Item and C_Item.GetItemNameByID and safe(C_Item.GetItemNameByID, m[1])) or (PP.ScarceNames and PP.ScarceNames[m[1]]) or "rare material"
                state = "need"
                why[#why + 1] = "needs " .. (m[2] - have) .. " " .. nm
            end
        end
    end
    return state, table.concat(why, ", ")
end

local scan = CreateFrame("Frame")
for _, e in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "NEW_RECIPE_LEARNED", "CURRENCY_DISPLAY_UPDATE" }) do
    pcall(scan.RegisterEvent, scan, e)
end
scan:SetScript("OnEvent", function(_, event)
    if event == "CURRENCY_DISPLAY_UPDATE" then
        if PP.db and PP.RequestRefresh then PP:RequestRefresh() end
    else
        PP:ScanKnownRecipes()
    end
end)

-- turn a data row into a named table (once)
local function Item(r, profKey)
    if r.id then return r end
    r.id, r.name, r.skill, r.level, r.class, r.sub, r.slot, r.q, r.src, r.spec, r.st, r.mats =
        r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12]
    r.st = r.st or {}
    local school = PP.GearSchool and PP.GearSchool[r.id]
    if school then for k, v in pairs(school) do r.st[k] = v end end
    if r.src == "P" then r.plan = PP:FavorPlan(profKey, r.name) end
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
    local best, soon, better = {}, {}, {}
    local hideHard = self.db and self.db.gearHideHard

    for _, r in ipairs(list) do
        local it = Item(r, def.key)
        local inv = EQUIP_SLOT[it.slot]
        if inv and KnowsSpec(it.spec) and self:CanUse(it, math.max(level, it.level)) then
            local sc = Score(it.st, w, cls)
            if sc >= 3 then
                if skill >= it.skill and it.level <= level + 2 then
                    local state, why = self:GearAccess(it)
                    local c = { it = it, score = sc, state = state, why = why }
                    if state ~= "need" then
                        if not best[inv] or sc > best[inv].score then best[inv] = c end
                    elseif not hideHard then
                        if not better[inv] or sc > better[inv].score then better[inv] = c end
                    end
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
        local now, nx, bt = best[inv], soon[inv], better[inv]
        if now or nx or bt then
            local eq = self:EquippedScore(inv, w)
            if now then
                now.gain = now.score - (eq or 0)
                now.upgrade = (eq == nil) or now.score > eq * 1.05 + 0.5
            end
            local floor = math.max(now and now.score or 0, eq or 0)
            if nx and not (nx.score > floor * 1.1 + 1) then nx = nil end
            -- "Better:" only when it clearly beats both the easy pick and what you wear
            if bt and not (bt.score > floor * 1.05 + 0.5) then bt = nil end
            if bt then bt.gain = bt.score - (eq or 0) end
            if now or nx or bt then
                rows[#rows + 1] = { inv = inv, name = PP.EQUIP_NAMES[inv], now = now, next = nx, better = bt, eq = eq }
            end
        end
    end
    return rows
end

-- Top 3 upgrades you can make now (best gain first) and the soonest good unlock
function PP:GearPicks(def, skill)
    local now, nextPick, betterPick = {}, nil, nil
    for _, row in ipairs(self:GearBySlot(def, skill)) do
        if row.now and row.now.upgrade then now[#now + 1] = row.now end
        if row.next and (not nextPick or row.next.it.skill < nextPick.it.skill) then nextPick = row.next end
        if row.better and (not betterPick or row.better.gain > betterPick.gain) then betterPick = row.better end
    end
    table.sort(now, function(a, b) return a.gain > b.gain end)
    while #now > 3 do table.remove(now) end
    return now, nextPick, betterPick
end

function PP:GearSourceText(it)
    local state, why = self:GearAccess(it)
    if state ~= "ready" then return why end
    if it.src == "T" then return "trainer" end
    return "you know it"
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
    for _, m in ipairs(self:GearMats(it) or {}) do
        local name = (C_Item and C_Item.GetItemNameByID and safe(C_Item.GetItemNameByID, m[1])) or ("item " .. m[1])
        local have = self:Count(m[1])
        local ok = have >= m[2]
        local rare = PP.ScarceMats and PP.ScarceMats[m[1]]
        GameTooltip:AddDoubleLine(name .. (rare and "  (rare)" or ""), have .. " / " .. m[2], 1, 1, 1, ok and 0.2 or 1, ok and 1 or 0.25, ok and 0.2 or 0.25)
        if rare and not ok then GameTooltip:AddLine("   " .. rare, 0.7, 0.7, 0.7, true) end
    end
    if it.plan and not self:KnowsCraft(it.name) then
        local have = self:FavorHave()
        local ok = have >= it.plan.cost
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Plans: " .. it.plan.cost .. " Merchant's Favor", "you have " .. have,
            1, 0.82, 0, ok and 0.2 or 1, ok and 1 or 0.25, ok and 0.2 or 0.25)
        local camp = self:FavorCamp()
        if camp then
            GameTooltip:AddLine("Buy at: " .. camp.n .. ", " .. camp.p .. "  " .. string.format("%.1f, %.1f", camp.x, camp.y), 1, 1, 1, true)
        end
        if not ok then
            GameTooltip:AddLine("Get Favor: fill Waylaid Crates (rare mob drop, or Auction House) and hand them in at the camp. 5-20 Favor each.", 0.7, 0.7, 0.7, true)
        end
    elseif it.src ~= "T" and not self:KnowsCraft(it.name) and not self:RecipesScanned() then
        GameTooltip:AddLine("Open your profession window once so I can see which recipes you know.", 0.7, 0.7, 0.7, true)
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
