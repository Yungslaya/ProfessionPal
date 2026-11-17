--[[ ProfessionPal - Farm Planner (/prof farm)

  Mining, Herbalism and Skinning all work the same way:
    By material: pick an ore, herb or leather and see every zone that has it, the guides' BEST zones first.
    By zone:     pick a zone and see what you can farm there.
  Map opens the zone with every spot and a loop to ride (PP:ShowZoneOnMap), and starts the way there.
  Spots: Data_Nodes.lua (veins and herbs) and Data_Beasts.lua (skinnable beasts), both from Wowhead WoW: Forever.
  BEST zones: Data_Farm.lua BEST_ZONES (Wowhead farming guides + Icy Veins Forever routes).
  Travel times: Shortest Path Forever when it is installed, otherwise ProfessionPal's own estimate.
]]

local _, PP = ...
local C = PP.C

-- extra node kinds that drop the same thing
local MORE_NODES = { ["Thorium Ore"] = { "Rich Thorium Vein" } }
local VERB = { mining = "Mine", herbalism = "Pick", skinning = "Skin" }
local PROFS = { "mining", "herbalism", "skinning" }
local PROF_NAME = { mining = "Mining", herbalism = "Herbalism", skinning = "Skinning" }
local PROF_ICON = { mining = "Interface\\Icons\\Trade_Mining", herbalism = "Interface\\Icons\\Trade_Herbalism",
                    skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" }

local function spots(code)
    return tonumber(type(code) == "string" and code:match("^(%d+):") or "") or 0
end

local function zoneName(map)
    for name, id in pairs(PP.ZONE_MAP or {}) do if id == map then return name end end
end

-- "391 beasts" for leather, "120 spots" for veins and herbs
local function spotWord(prof, n)
    return n .. (prof == "skinning" and " beasts" or " spots")
end

local function itemIcon(id)
    if not id then return nil end
    local get = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    if not get then return nil end
    local ok, icon = pcall(get, id)
    if ok and (type(icon) == "number" or type(icon) == "string") then return icon end
end

-- your skill per gathering profession (nil = you don't know it)
function PP:GatherSkills()
    local have = {}
    for _, def in ipairs(self.professions or {}) do
        if def.key == "mining" or def.key == "herbalism" or def.key == "skinning" then
            local skill = self:GetSkill(def)
            if type(skill) == "number" then have[def.key] = skill end
        end
    end
    return have
end

-- Every ore, herb and leather that has mapped spots:
-- { id, name, prof, skill, nodes = { node names }, zones = { map = spots } }
function PP:FarmPlannerItems()
    if self.farmPlannerItems then return self.farmPlannerItems end
    local list = {}
    for _, f in ipairs(self.FARMABLE or {}) do
        if (f.prof == "mining" or f.prof == "herbalism" or f.prof == "skinning") and f.node then
            local item = { id = f.id, name = f.name, prof = f.prof, skill = f.skill or 1, nodes = {}, zones = {} }
            local names = { f.node }
            for _, extra in ipairs(MORE_NODES[f.name] or {}) do names[#names + 1] = extra end
            for _, node in ipairs(names) do
                local byZone = self.NODES and self.NODES[node]
                if byZone then
                    item.nodes[#item.nodes + 1] = node
                    for map, code in pairs(byZone) do
                        if zoneName(map) then item.zones[map] = (item.zones[map] or 0) + spots(code) end
                    end
                end
            end
            if next(item.zones) then list[#list + 1] = item end
        end
    end
    local order = { mining = 1, herbalism = 2, skinning = 3 }
    table.sort(list, function(a, b)
        if a.prof ~= b.prof then return order[a.prof] < order[b.prof] end
        if a.skill ~= b.skill then return a.skill < b.skill end
        return a.name < b.name
    end)
    self.farmPlannerItems = list
    return list
end

local function levelText(map)
    local lv = PP.ZONE_LEVEL and PP.ZONE_LEVEL[map]
    return lv and ("level " .. lv[1] .. "-" .. lv[2]) or nil
end

local function awayText(map)
    if PP:CurrentMap() == map then return "you are here" end
    local t = PP:TravelTime(map, 50, 50)
    if type(t) ~= "number" then return nil end
    local minutes = math.max(1, math.floor(t / 60 + 0.5))
    return minutes .. " min away"
end

local function joinNames(items)
    local names = {}
    for _, item in ipairs(items) do names[#names + 1] = (item.name:gsub(" Ore$", "")) end
    return table.concat(names, ", ")
end

-- A plan = { title, what, nodes = { { node name }, ... }, prof, skill (highest needed), items }
local function plan(title, items, prof)
    local nodes, top = {}, 0
    for _, item in ipairs(items) do
        for _, node in ipairs(item.nodes) do nodes[#nodes + 1] = { node } end
        if item.skill > top then top = item.skill end
    end
    local verb = prof and VERB[prof] or "Gather"
    return { title = title, what = verb .. " " .. joinNames(items), nodes = nodes, prof = prof, skill = top,
             items = items }
end

-- Plans for one zone: each material alone, then all ore, all herbs, all leather, and ore + herbs.
-- Only things your skill can gather go into the "all" plans (when you know that profession).
function PP:FarmZonePlans(map)
    local have = self:GatherSkills()
    local byProf, singles = { mining = {}, herbalism = {}, skinning = {} }, {}
    for _, item in ipairs(self:FarmPlannerItems()) do
        if item.zones[map] then
            singles[#singles + 1] = plan(item.name, { item }, item.prof)
            singles[#singles].spots = item.zones[map]
            local skill = have[item.prof]
            if skill == nil or skill >= item.skill then table.insert(byProf[item.prof], item) end
        end
    end
    local plans = {}
    if #byProf.mining >= 2 then plans[#plans + 1] = plan("All ore you can mine", byProf.mining, "mining") end
    if #byProf.herbalism >= 2 then plans[#plans + 1] = plan("All herbs you can pick", byProf.herbalism, "herbalism") end
    if #byProf.skinning >= 2 then plans[#plans + 1] = plan("All leather you can skin", byProf.skinning, "skinning") end
    if #byProf.mining >= 1 and #byProf.herbalism >= 1 and have.mining and have.herbalism then
        local both = {}
        for _, item in ipairs(byProf.mining) do both[#both + 1] = item end
        for _, item in ipairs(byProf.herbalism) do both[#both + 1] = item end
        plans[#plans + 1] = plan("Ore and herbs", both, nil)
    end
    for _, p in ipairs(singles) do plans[#plans + 1] = p end
    return plans
end

-- Zones that have spots, closest first.
function PP:FarmPlannerZones()
    -- one entry per zone, kept between refreshes so the picked zone stays picked
    self.farmPlannerZoneCache = self.farmPlannerZoneCache or {}
    local cache, seen, list, current = self.farmPlannerZoneCache, {}, {}, self:CurrentMap()
    for _, item in ipairs(self:FarmPlannerItems()) do
        for map in pairs(item.zones) do
            if not seen[map] then
                seen[map] = true
                local z = cache[map] or { map = map, name = zoneName(map) }
                cache[map] = z
                z.away, z.here = self:TravelTime(map, 50, 50), current == map
                list[#list + 1] = z
            end
        end
    end
    table.sort(list, function(a, b)
        if a.here ~= b.here then return a.here end
        if a.away and b.away and a.away ~= b.away then return a.away < b.away end
        if (a.away ~= nil) ~= (b.away ~= nil) then return a.away ~= nil end
        return a.name < b.name
    end)
    return list
end

-- Zones for one material: the guides' best zones first, then closest first, the most spots breaking ties.
function PP:FarmItemZones(item)
    local list = {}
    for map, count in pairs(item.zones) do
        list[#list + 1] = { map = map, name = zoneName(map), spots = count, away = self:TravelTime(map, 50, 50),
                            here = self:CurrentMap() == map, best = self:BestZoneRank(item.name, map) }
    end
    table.sort(list, function(a, b)
        if (a.best or 99) ~= (b.best or 99) then return (a.best or 99) < (b.best or 99) end
        if a.here ~= b.here then return a.here end
        if a.away and b.away and a.away ~= b.away then return a.away < b.away end
        if (a.away ~= nil) ~= (b.away ~= nil) then return a.away ~= nil end
        if a.spots ~= b.spots then return a.spots > b.spots end
        return a.name < b.name
    end)
    return list
end

-- Is this zone a best zone for the one material in the plan?
local function bestFor(p, map)
    if not (p.items and #p.items == 1) then return nil end
    return PP:BestZoneRank(p.items[1].name, map)
end

-- Start a plan: the map opens on the zone with the dots and the loop, and the way there starts.
function PP:StartFarmPlan(p, map)
    local name = zoneName(map)
    if not (name and self.ShowZoneOnMap) then return false end
    local text = bestFor(p, map) and (p.what .. " (best zone)") or p.what
    return self:ShowZoneOnMap({ text = text, nodes = p.nodes }, name)
end

-- ---------- optional Market Ledger prices (shown only; never changes plans or rankings) ----------
local MARKET_URL = "https://www.curseforge.com/wow/addons/market-ledger"
local FRESH_SECONDS = 24 * 60 * 60   -- older prices are labelled stale
local CLOCK_SKEW = 5 * 60            -- a price "seen" further in the future than this is invalid

local function finitePositive(v) return type(v) == "number" and v > 0 and v == v and v < math.huge end

-- "missing", "old" (no price lookup), "none", "error", or "ok", copper, seenAt
function PP:FarmMarketPrice(itemID, nowTime)
    local ledger = _G.MarketLedger
    if type(ledger) ~= "table" then return "missing" end
    if type(ledger.PriceForItem) ~= "function" then return "old" end
    if type(itemID) ~= "number" then return "none" end
    local ok, copper, seenAt = pcall(ledger.PriceForItem, ledger, itemID)
    if not ok then
        if self.FarmDebugLog then self:FarmDebugLog("Market Ledger price error", copper) end
        return "error"
    end
    if copper == nil and seenAt == nil then return "none" end
    local whole = finitePositive(copper) and math.floor(copper) or 0
    local problem
    if whole < 1 or not finitePositive(seenAt) then problem = "unexpected values"
    elseif seenAt > (nowTime or time()) + CLOCK_SKEW then problem = "price time is in the future" end
    if problem then
        if self.FarmDebugLog then self:FarmDebugLog("Market Ledger price", problem .. " for item " .. itemID) end
        return "error"
    end
    return "ok", whole, seenAt
end

local function moneyText(copper)
    local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    local parts = {}
    if g > 0 then parts[#parts + 1] = g .. "g" end
    if s > 0 then parts[#parts + 1] = s .. "s" end
    if c > 0 or #parts == 0 then parts[#parts + 1] = c .. "c" end
    return table.concat(parts, " ")
end

local function ageText(seconds)
    if seconds < 3600 then return "under an hour ago" end
    if seconds < 86400 then
        local h = math.floor(seconds / 3600)
        return h .. (h == 1 and " hour ago" or " hours ago")
    end
    local d = math.floor(seconds / 86400)
    return d .. (d == 1 and " day ago" or " days ago")
end

-- text, colour, tooltip, state, seconds until the price turns stale. nil text = show nothing.
function PP:FarmPriceLine(itemID, nowTime)
    nowTime = nowTime or time()
    local state, copper, seenAt = self:FarmMarketPrice(itemID, nowTime)
    if state == "none" then
        return "No price data", C.gray,
            "Have this material in your bags, then open Market Ledger at the Auction House and click Scan Bags.", state
    end
    if state ~= "ok" then return nil, nil, nil, state end
    local age = math.max(0, nowTime - seenAt)
    local text = "AH estimate: " .. moneyText(copper) .. " each"
    local tip = "Seen " .. ageText(age) .. " in your last Market Ledger scan. This is the lowest asking price, " ..
        "before the 5% Auction House cut. An asking price is not a guaranteed sale."
    if age >= FRESH_SECONDS then
        return text .. "  (stale)", C.gray, tip .. " Scan again for a current estimate.", state
    end
    return text, C.white, tip, state, FRESH_SECONDS - age
end

-- Market Ledger calls this after a scan finishes or prices are cleared.
function PP:OnMarketLedgerPrices()
    if self.RefreshFarmPlanner then self:RefreshFarmPlanner() end
end

-- One timer while the planner is open, so a price turns "stale" on time without per-frame work.
local staleTimer
local function watchStale(seconds)
    if staleTimer then staleTimer:Cancel(); staleTimer = nil end
    if not (seconds and C_Timer and C_Timer.NewTimer) then return end
    staleTimer = C_Timer.NewTimer(seconds + 1, function()
        staleTimer = nil
        PP:RefreshFarmPlanner()
    end)
end
PP.FarmPriceTimer = function() return staleTimer end   -- for the tests

local info
function PP:ShowMarketLedgerInfo()
    if not info then
        info = PP.UIWindow("ProfessionPalMarketLedgerInfo", 460, "Market Ledger — optional integration")
        info:SetHeight(250)
        info:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        info:SetFrameStrata("DIALOG")
        info.body = PP.UIText(info, 14, C.white)
        info.body:SetPoint("TOPLEFT", info, "TOPLEFT", 20, -50)
        info.body:SetWidth(420)
        if info.body.SetWordWrap then info.body:SetWordWrap(true) end
        info.label = PP.UIText(info, 12, C.gray)
        info.label:SetPoint("BOTTOMLEFT", info, "BOTTOMLEFT", 20, 76)
        info.label:SetText("CurseForge page - select the link and press Ctrl+C")
        info.link = CreateFrame("EditBox", nil, info, "InputBoxTemplate")
        info.link:SetSize(410, 24)
        info.link:SetPoint("BOTTOMLEFT", info, "BOTTOMLEFT", 26, 46)
        info.link:SetAutoFocus(false)
        info.link:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
        info.link:SetScript("OnEditFocusGained", function(e) e:HighlightText() end)
        info.link:SetScript("OnTextChanged", function(e, user) if user then e:SetText(MARKET_URL); e:HighlightText() end end)
        PP.UIButton(info, "Close", 80, 26, function() info:Hide() end):SetPoint("BOTTOMRIGHT", info, "BOTTOMRIGHT", -16, 12)
    end
    local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
    if type(sw) == "number" and type(sh) == "number" and sw > 0 and sh > 0 then info:SetScale(math.min(1, sw / 500, sh / 290)) end
    local ledger = _G.MarketLedger
    if type(ledger) ~= "table" then
        info.body:SetText("See Auction House price estimates for your materials and compare selling them " ..
            "with crafting.\n\nGet Market Ledger from CurseForge (link below).")
    elseif type(ledger.PriceForItem) ~= "function" then
        info.body:SetText("Update Market Ledger to see Auction House price estimates for your " ..
            "materials in Farm Planner.\n\nUpdate it in the CurseForge app.")
    else
        info.body:SetText("Market Ledger is installed. In Farm Planner, choose By material and select a material " ..
            "to see its Auction House price estimate.\n\nScan Bags in Market Ledger at the Auction House to update prices.")
    end
    info.link:SetText(MARKET_URL)
    info:Show()
    return info
end

-- ---------- the window ----------
-- Big, plain and easy to read: profession tabs on top, materials (or zones) on the left,
-- one card per zone on the right with one short line of facts and a Map button.
local W, H = 860, 610
local LEFT_ROWS, RIGHT_ROWS = 11, 7
local LEFT_X, RIGHT_X, LIST_Y = 20, 300, -168
local LEFT_W, RIGHT_W, ROW_H, CARD_H = 262, 540, 36, 58
local frame

local function canColor(prof, skill)
    local have = PP:GatherSkills()[prof]
    if have == nil then return C.gray end
    return have >= skill and C.green or C.gray
end

-- an icon picture (a do-nothing stand-in if the frame can't hold one)
local NO_ICON = {}
for _, m in ipairs({ "SetTexture", "SetSize", "SetPoint", "SetTexCoord", "Show", "Hide", "ClearAllPoints" }) do
    NO_ICON[m] = function() end
end
local function iconTexture(parent, size)
    local icon = parent.CreateTexture and parent:CreateTexture(nil, "ARTWORK")
    if not icon then return NO_ICON end
    icon:SetSize(size, size)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return icon
end

-- a button with an icon on its left
local function iconButton(parent, w, h, onClick)
    local b = PP.UIButton(parent, "", w, h, onClick)
    b.icon = iconTexture(b, h - 8)
    b.icon:SetPoint("LEFT", b, "LEFT", 5, 0)
    local fs = b.GetFontString and b:GetFontString()
    if fs then
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", b, "LEFT", h + 2, 0)
        fs:SetPoint("RIGHT", b, "RIGHT", -8, 0)
        fs:SetJustifyH("LEFT")
    end
    return b
end

function PP:BuildFarmPlanner()
    if frame then return frame end
    local f = PP.UIWindow("ProfessionPalFarmPlanner", W, "Farm Planner")
    frame = f
    f:SetHeight(H)
    -- shrink to fit small screens (the screen size can be missing very early in loading)
    local screenW, screenH = UIParent:GetWidth(), UIParent:GetHeight()
    if type(screenW) == "number" and type(screenH) == "number" and screenW > 0 and screenH > 0 then
        f:SetScale(math.min(1, screenW / (W + 40), screenH / (H + 40)))
    end
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f.mode = PP.db.farmPlannerMode == "zone" and "zone" or "item"
    f.offset = 0

    -- profession tabs
    f.filters = {}
    for i, key in ipairs(PROFS) do
        local b = iconButton(f, 172, 40, function()
            f.prof, f.picked, f.offset, f.rightOffset = key, nil, 0, 0
            PP.db.farmPlannerProf = key
            PP:RefreshFarmPlanner()
        end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + (i - 1) * 180, -50)
        b.icon:SetTexture(PROF_ICON[key])
        b:SetText(PROF_NAME[key])
        f.filters[key] = b
    end
    f.prof = PP.db.farmPlannerProf
    if not f.filters[f.prof] then
        f.prof = "mining"
        for _, key in ipairs(PROFS) do
            if PP:GatherSkills()[key] then f.prof = key; break end
        end
    end
    f.byItem = PP.UIButton(f, "By material", 124, 40, function() PP:FarmPlannerMode("item") end)
    f.byItem:SetPoint("TOPRIGHT", f, "TOPRIGHT", -152, -50)
    f.byZone = PP.UIButton(f, "By zone", 124, 40, function() PP:FarmPlannerMode("zone") end)
    f.byZone:SetPoint("LEFT", f.byItem, "RIGHT", 8, 0)

    -- header of the right side: big icon, name, one line about your skill, and the price
    f.headIcon = iconTexture(f, 44)
    f.headIcon:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X, -104)
    f.rightHead = PP.UIText(f, 20, C.gold)
    f.rightHead:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X + 54, -104)
    f.rightHead:SetWidth(RIGHT_W - 54)
    if f.rightHead.SetWordWrap then f.rightHead:SetWordWrap(false) end
    f.skillLine = PP.UIText(f, 14, C.gray)
    f.skillLine:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X + 54, -130)
    f.skillLine:SetWidth(220)

    -- material price (Market Ledger, optional): text, a hover for details, or a hint when it is missing
    f.price = PP.UIText(f, 14, C.white)
    f.price:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -130)
    f.price:SetWidth(250)
    f.price:SetJustifyH("RIGHT")
    if f.price.SetWordWrap then f.price:SetWordWrap(false) end
    f.priceHover = CreateFrame("Frame", nil, f)
    f.priceHover:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, -124)
    f.priceHover:SetSize(290, 26)
    f.priceHover:EnableMouse(true)
    f.priceHover:SetScript("OnEnter", function(hover)
        -- worked out now, so the age is current and matches the selected material
        local text, _, tip = PP:FarmPriceLine(f.priceItem)
        if not (text and tip) then return end
        GameTooltip:SetOwner(hover, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Material price")
        GameTooltip:AddLine(tip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    f.priceHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.priceHint = PP.UIButton(f, "Prices: Market Ledger", 170, 26, function() PP:ShowMarketLedgerInfo() end)
    f.priceHint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -78, -124)
    f.priceDismiss = PP.UIButton(f, "Hide", 54, 26, function()
        PP.db.farmMarketHintDismissed = true
        PP:RefreshFarmPlanner()
    end)
    f.priceDismiss:SetPoint("LEFT", f.priceHint, "RIGHT", 4, 0)

    -- left list: materials or zones
    f.leftHead = PP.UIText(f, 15, C.gold)
    f.leftHead:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + 2, -114)
    f.left = {}
    for i = 1, LEFT_ROWS do
        local b = iconButton(f, LEFT_W, ROW_H - 4, function(self) PP:FarmPlannerPick(self.value) end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X, LIST_Y + 28 - (i - 1) * ROW_H)
        b:Hide()
        f.left[i] = b
    end
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        local total = #(f.leftValues or {})
        f.offset = math.max(0, math.min(f.offset - delta * 3, total - LEFT_ROWS))
        PP:RefreshFarmPlanner()
    end)
    f.more = PP.UIText(f, 13, C.gray)
    f.more:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + 2, LIST_Y + 28 - LEFT_ROWS * ROW_H - 4)

    -- right list: one card per zone (or plan)
    f.right = {}
    for i = 1, RIGHT_ROWS do
        local r = CreateFrame("Frame", nil, f, "BackdropTemplate")
        PP.Skin(r, nil, { bg = PP.THEME.inset, border = PP.THEME.btnBorder })
        r:SetSize(RIGHT_W, CARD_H - 4)
        r:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X, LIST_Y - (i - 1) * CARD_H)
        r.best = PP.UIText(r, 13, C.gold)
        r.best:SetPoint("TOPRIGHT", r, "TOPRIGHT", -112, -8)
        r.name = PP.UIText(r, 17, C.white)
        r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 12, -7)
        r.name:SetWidth(RIGHT_W - 130)
        r.sub = PP.UIText(r, 14, C.gray)
        r.sub:SetPoint("TOPLEFT", r, "TOPLEFT", 12, -30)
        r.sub:SetWidth(RIGHT_W - 130)
        if r.sub.SetWordWrap then r.sub:SetWordWrap(false) end
        if r.name.SetWordWrap then r.name:SetWordWrap(false) end
        r:EnableMouse(true)
        r.go = PP.UIButton(r, "Map", 92, 38, function()
            if r.plan and r.map then
                if PP:StartFarmPlan(r.plan, r.map) then f:Hide() end
            end
        end)
        r.go:SetPoint("RIGHT", r, "RIGHT", -8, 0)
        r:Hide()
        f.right[i] = r
    end
    -- the right list scrolls on its own when the mouse is over it
    local wheel = CreateFrame("Frame", nil, f)
    wheel:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X - 4, LIST_Y + 4)
    wheel:SetSize(RIGHT_W + 8, RIGHT_ROWS * CARD_H)
    wheel:EnableMouseWheel(true)
    wheel:SetScript("OnMouseWheel", function(_, delta)
        f.rightOffset = math.max(0, math.min((f.rightOffset or 0) - delta * 2, (f.rightTotal or 0) - RIGHT_ROWS))
        PP:RefreshFarmPlanner()
    end)
    for _, r in ipairs(f.right) do
        r:SetFrameLevel(wheel:GetFrameLevel() + 1)
        r:EnableMouseWheel(true)
        r:SetScript("OnMouseWheel", wheel:GetScript("OnMouseWheel"))
        r.go:EnableMouseWheel(true)
        r.go:SetScript("OnMouseWheel", wheel:GetScript("OnMouseWheel"))
    end
    f.rightWheel = wheel
    f.rightMore = PP.UIText(f, 13, C.gray)
    f.rightMore:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X + 2, LIST_Y - RIGHT_ROWS * CARD_H - 2)
    f.empty = PP.UIText(f, 15, C.gray)
    f.empty:SetPoint("TOPLEFT", f, "TOPLEFT", RIGHT_X + 4, LIST_Y - 10)
    f.empty:SetWidth(RIGHT_W)
    f.foot = PP.UIText(f, 13, C.gray)
    f.foot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", LEFT_X + 2, 14)
    f.foot:SetWidth(W - 40)
    f.foot:SetText("Map shows every spot and a loop to ride.   BEST = top zones in the Wowhead and Icy Veins farming guides.")
    f:SetScript("OnShow", function() PP:RefreshFarmPlanner() end)
    f:SetScript("OnHide", function() watchStale(nil) end)
    return f
end

function PP:FarmPlannerMode(mode)
    local f = self:BuildFarmPlanner()
    if f.mode ~= mode then f.mode, f.offset, f.picked, f.rightOffset = mode, 0, nil, 0 end
    self.db.farmPlannerMode = mode
    self:RefreshFarmPlanner()
end

function PP:FarmPlannerPick(value)
    local f = self:BuildFarmPlanner()
    f.picked, f.rightOffset = value, 0
    self:RefreshFarmPlanner()
end

local function showRow(r, title, titleColor, sub, p, map, best)
    r.name:SetText(title); r.name:SetTextColor(unpack(titleColor))
    r.sub:SetText(sub or "")
    r.best:SetText(best and "BEST" or "")
    r.plan, r.map = p, map
    r:Show()
end

local function skillText(prof, need)
    local have = PP:GatherSkills()[prof]
    if not have then return "Needs " .. PROF_NAME[prof] .. " " .. need, C.gray end
    if have >= need then return "Your " .. PROF_NAME[prof] .. ": " .. have .. "  (needs " .. need .. ")", C.green end
    return "Your " .. PROF_NAME[prof] .. ": " .. have .. "  (needs " .. need .. ")", C.orange
end

function PP:RefreshFarmPlanner()
    local f = frame
    if not (f and f:IsShown()) then return end
    f.byItem:SetSelected(f.mode == "item"); f.byZone:SetSelected(f.mode == "zone")
    for _, b in ipairs(f.left) do b:Hide() end
    for _, r in ipairs(f.right) do r:Hide() end
    f.empty:SetText("")

    -- left: materials of the chosen profession, or zones
    local values = f.mode == "item" and self:FarmPlannerItems() or self:FarmPlannerZones()
    for key, b in pairs(f.filters) do
        b:SetSelected(key == f.prof)
        b:SetLabelColor(key == f.prof and C.gold or C.white)
        b:SetShown(f.mode == "item")
    end
    if f.mode == "item" then
        local filtered = {}
        for _, item in ipairs(values) do
            if item.prof == f.prof then filtered[#filtered + 1] = item end
        end
        values = filtered
    end
    f.leftValues = values
    f.offset = math.max(0, math.min(f.offset, #values - LEFT_ROWS))
    if f.picked == nil then
        if f.mode == "zone" then f.picked = values[1] else
            -- start on the highest material your skill can gather
            local have = self:GatherSkills()
            for _, item in ipairs(values) do
                local s = have[item.prof]
                if s and s >= item.skill then f.picked = item end
            end
            f.picked = f.picked or values[1]
        end
        for i, value in ipairs(values) do
            if value == f.picked then f.offset = math.max(0, math.min(i - 1, #values - LEFT_ROWS)); break end
        end
    end
    f.leftHead:SetText(f.mode == "item" and "Pick a material" or "Pick a zone")
    for i = 1, LEFT_ROWS do
        local v, b = values[i + f.offset], f.left[i]
        if v then
            b.value = v
            if f.mode == "item" then
                b:SetText(v.name .. "  (" .. v.skill .. ")")
                b.icon:SetTexture(itemIcon(v.id) or PROF_ICON[v.prof])
                b:SetLabelColor(canColor(v.prof, v.skill))
            else
                b:SetText(v.name)
                b.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
                b:SetLabelColor(v.here and C.green or C.white)
            end
            b:SetSelected(v == f.picked)
            b:Show()
        end
    end
    f.more:SetText(#values > LEFT_ROWS and "Scroll for more" or "")

    -- right: zones for the material, or plans for the zone
    local picked, rows = f.picked, {}
    f.rightMore:SetText("")
    local priceText, priceColor, priceTip, priceState, staleIn
    f.priceItem = f.mode == "item" and picked and picked.id or nil
    if f.priceItem then priceText, priceColor, priceTip, priceState, staleIn = self:FarmPriceLine(f.priceItem) end
    local hint = (priceState == "missing" or priceState == "old") and not self.db.farmMarketHintDismissed
    f.price:SetText(priceText or "")
    if priceColor then f.price:SetTextColor(unpack(priceColor)) end
    f.priceTip = priceText and priceTip or nil
    f.priceHover:SetShown(priceText ~= nil)
    f.priceHint:SetShown(hint and true or false)
    f.priceDismiss:SetShown(hint and true or false)
    watchStale(staleIn)
    if GameTooltip:IsOwned(f.priceHover) then
        GameTooltip:Hide()
        if priceText then f.priceHover:GetScript("OnEnter")(f.priceHover) end
    end
    if not picked then
        f.rightHead:SetText(""); f.skillLine:SetText(""); f.headIcon:Hide()
        f.empty:SetText("Nothing to farm here yet.")
        return
    end
    f.headIcon:Show()
    if f.mode == "item" then
        f.headIcon:SetTexture(itemIcon(picked.id) or PROF_ICON[picked.prof])
        f.rightHead:SetText("Where to " .. VERB[picked.prof]:lower() .. " " .. picked.name)
        local text, color = skillText(picked.prof, picked.skill)
        f.skillLine:SetText(text); f.skillLine:SetTextColor(unpack(color))
        local p = plan(picked.name, { picked }, picked.prof)
        local list = self:FarmItemZones(picked)
        rows = list
        for i = 1, RIGHT_ROWS do
            local z, r = list[i + (f.rightOffset or 0)], f.right[i]
            if not z then break end
            local bits = { spotWord(picked.prof, z.spots), levelText(z.map), awayText(z.map) }
            local title, color = z.name, z.here and C.green or C.white
            if z.best then title, color = z.name .. "  -  BEST", C.gold end
            showRow(r, title, color, table.concat(bits, "   -   "), p, z.map, false)
        end
    else
        f.headIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
        f.rightHead:SetText(picked.name)
        f.skillLine:SetTextColor(unpack(C.gray))
        f.skillLine:SetText(table.concat({ levelText(picked.map) or "", awayText(picked.map) or "" }, "   -   "))
        local plans = self:FarmZonePlans(picked.map)
        rows = plans
        for i = 1, RIGHT_ROWS do
            local p, r = plans[i + (f.rightOffset or 0)], f.right[i]
            if not p then break end
            local sub = p.spots and (spotWord(p.prof, p.spots) .. "   -   " .. PROF_NAME[p.prof] .. " " .. p.skill)
                or joinNames(p.items)
            local color = p.prof and canColor(p.prof, p.skill) or C.gold
            if not p.spots then color = C.gold end
            local title = p.title
            if bestFor(p, picked.map) then title = title .. "  -  BEST" end
            showRow(r, title, color, sub, p, picked.map, false)
        end
        if #plans == 0 then f.empty:SetText("Nothing to farm in this zone yet.") end
    end
    f.rightTotal = #rows
    f.rightOffset = math.max(0, math.min(f.rightOffset or 0, #rows - RIGHT_ROWS))
    if #rows > RIGHT_ROWS then f.rightMore:SetText("Scroll for more  (" .. #rows .. " in all)") end
end

function PP:ToggleFarmPlanner()
    local f = self:BuildFarmPlanner()
    if f:IsShown() then f:Hide() else f:Show() end
end
