--[[ ProfessionPal - Window
  Big classic-style window. One clear next step at the top.
  Display only: buttons here only open other windows or put a pin on YOUR map.
]]

local _, PP = ...
local C = PP.C
local W = 500          -- window width
local TEXTW = W - 60   -- text width

-- ---------- builders ----------
local function Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(PP.FONT, size, "")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetTextColor(unpack(color or C.white))
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function SetColor(fs, color) fs:SetTextColor(unpack(color)) end

local function Button(parent, label, w, h, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, h or 30)
    b:SetText(label)
    local fs = b.GetFontString and b:GetFontString()
    if fs then fs:SetFont(PP.FONT, 15, "") end
    b:SetScript("OnClick", onClick)
    return b
end

local function Icon(parent, size)
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetSize(size, size)
    t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    return t
end

local function Window(name, w, title)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(w, 300)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
    end
    f.title = Text(f, 18, C.gold, "CENTER")
    f.title:SetPoint("TOP", f, "TOP", 0, -18)
    f.title:SetText(title)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not (PP.db and PP.db.locked) then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    f:Hide()
    if UISpecialFrames then table.insert(UISpecialFrames, name) end
    return f
end

PP.UIText, PP.UIButton, PP.UIIcon = Text, Button, Icon

-- Puts things top-down. Returns a placer with :Put(widget, height, x)
local function Placer(frame, startY)
    local p = { y = startY }
    function p:Put(widget, h, x, gap)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", frame, "TOPLEFT", x or 24, self.y)
        widget:Show()
        self.y = self.y - (h or 20) - (gap or 6)
    end
    function p:TextH(fs, minH)
        local h = fs.GetStringHeight and fs:GetStringHeight() or 0
        if type(h) ~= "number" or h < (minH or 16) then h = minH or 16 end
        return h
    end
    return p
end

-- ---------- map pins (display only) ----------
function PP:Pin(t)
    if not (t and t.m and t.x) then return end
    local ok = false
    if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local can = true
        if C_Map.CanSetUserWaypointOnMap then can = PP.safe(C_Map.CanSetUserWaypointOnMap, t.m) ~= false end
        if can then
            local pt = PP.safe(UiMapPoint.CreateFromCoordinates, t.m, t.x / 100, t.y / 100)
            if pt and pcall(C_Map.SetUserWaypoint, pt) then
                ok = true
                if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                    pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
                end
            end
        end
    end
    if ok then
        self:Print("Map pin set: " .. t.n .. string.format(" (%.1f, %.1f)", t.x, t.y))
    else
        self:Print(t.n .. ": " .. t.p .. string.format("  %.1f, %.1f", t.x, t.y))
    end
end

function PP:TomTom(t)
    if not (TomTom and TomTom.AddWaypoint and t and t.m) then return end
    pcall(TomTom.AddWaypoint, TomTom, t.m, t.x / 100, t.y / 100, { title = t.n, from = "ProfessionPal" })
    self:Print("TomTom arrow: " .. t.n)
end

-- A row that shows a person (trainer or vendor) with pin buttons
local function PersonRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(TEXTW, 44)
    r.name = Text(r, 15, C.white)
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
    r.name:SetWidth(TEXTW - 190)
    r.place = Text(r, 14, C.gray)
    r.place:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
    r.place:SetWidth(TEXTW - 190)
    r.pin = Button(r, "Map Pin", 90, 28, function() PP:Pin(r.who) end)
    r.pin:SetPoint("TOPRIGHT", r, "TOPRIGHT", -92, -4)
    r.tom = Button(r, "TomTom", 88, 28, function() PP:TomTom(r.who) end)
    r.tom:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -4)
    function r:SetWho(t, extra)
        self.who = t
        self.name:SetText(t.n .. (extra or ""))
        if t.x then
            self.place:SetText(t.p .. "   " .. string.format("%.1f, %.1f", t.x, t.y))
        else
            self.place:SetText(t.p)
        end
        if t.m and t.x then self.pin:Show() else self.pin:Hide() end
        if t.m and t.x and TomTom and TomTom.AddWaypoint then self.tom:Show() else self.tom:Hide() end
    end
    r:Hide()
    return r
end

-- A row with a big item icon, a name and a count
local function ItemRow(parent)
    local r = CreateFrame("Frame", nil, parent)
    r:SetSize(TEXTW, 34)
    r.icon = Icon(r, 32)
    r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
    r.name = Text(r, 15, C.white)
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0)
    r.name:SetWidth(TEXTW - 170)
    r.count = Text(r, 16, C.white, "RIGHT")
    r.count:SetPoint("RIGHT", r, "RIGHT", 0, 0)
    r.count:SetWidth(150)
    r:Hide()
    return r
end

-- ---------- main window ----------
function PP:BuildUI()
    if self.frame then return end
    local f = Window("ProfessionPalFrame", W, "ProfessionPal")
    self.frame = f
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    local pt = self.db.point
    if type(pt) == "table" and pt[1] then
        f:ClearAllPoints()
        f:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
    end
    f:SetScale(self.db.scale or 1)
    f:SetScript("OnDragStop", function(s)
        s:StopMovingOrSizing()
        local p, _, rp, x, y = s:GetPoint()
        PP.db.point = { p, rp, x, y }
    end)
    f:SetScript("OnShow", function() PP:Refresh() end)

    -- profession buttons (4 per row)
    f.tabs = {}
    for i, def in ipairs(self.professions) do
        local b = Button(f, def.name, 112, 30, function()
            PP.db.selected = def.key
            PP:Refresh()
        end)
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 22 + col * 116, -46 - row * 34)
        b.def = def
        b:Hide()
        f.tabs[i] = b
    end
    f.top = -46 - 34 - 8

    f.headIcon = Icon(f, 48)
    f.headName = Text(f, 18, C.gold)
    f.headSkill = Text(f, 18, C.white)
    f.alert = Text(f, 16, C.red); f.alert:SetWidth(TEXTW)

    f.secNext = Text(f, 16, C.gold); f.secNext:SetText("NEXT STEP")
    f.stepIcon = Icon(f, 44)
    f.stepText = Text(f, 18, C.white); f.stepText:SetWidth(TEXTW - 56)
    f.stepSub = Text(f, 15, C.gray); f.stepSub:SetWidth(TEXTW - 56)

    f.rows = {}
    for i = 1, 6 do f.rows[i] = ItemRow(f) end

    f.whereHead = Text(f, 15, C.gold); f.whereHead:SetText("Go to:")
    f.zones = {}
    for i = 1, 5 do
        local z = Text(f, 15, C.white); z:SetWidth(TEXTW)
        f.zones[i] = z
    end
    f.zoneTip = Text(f, 14, C.gray); f.zoneTip:SetWidth(TEXTW - 16)
    f.tool = Text(f, 15, C.red); f.tool:SetWidth(TEXTW)
    f.tip = Text(f, 14, C.yellow); f.tip:SetWidth(TEXTW)
    f.learn = Text(f, 16, C.orange); f.learn:SetWidth(TEXTW)

    f.vendorHead = Text(f, 15, C.gold); f.vendorHead:SetText("Plans from:")
    f.vendor = PersonRow(f)

    -- "GEAR FOR YOU" rows (hover = item tooltip + materials)
    f.gearHead = Text(f, 16, C.gold)
    f.gear = {}
    for i = 1, 3 do
        local r = CreateFrame("Button", nil, f)
        r:SetSize(TEXTW, 40)
        r.icon = Icon(r, 34); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.name = Text(r, 15, C.white); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -1); r.name:SetWidth(TEXTW - 50)
        r.sub = Text(r, 13, C.gray); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.sub:SetWidth(TEXTW - 50)
        r:SetScript("OnEnter", function(self) PP:GearTooltip(self, self.it) end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        r:Hide()
        f.gear[i] = r
    end
    f.gearNext = Text(f, 14, C.gray); f.gearNext:SetWidth(TEXTW)
    f.gearBtn = Button(f, "All Gear", 110, 26, function() PP:ToggleGear() end)

    f.secTrain = Text(f, 16, C.gold)
    f.trainText = Text(f, 16, C.white); f.trainText:SetWidth(TEXTW)
    f.trainers = { PersonRow(f), PersonRow(f) }

    f.shopBtn = Button(f, "Shopping List", 150, 32, function() PP:ToggleShop() end)
    f.setBtn = Button(f, "Settings", 120, 32, function() PP:ToggleSettings() end)
    f.guideBtn = Button(f, "Guides", 120, 32, function() PP:ToggleGuides() end)
    f.guideLine = Text(f, 13, C.green); f.guideLine:SetWidth(TEXTW)

    self:BuildShop()
    if self.BuildTracker then self:BuildTracker() end
    self:BuildSettings()
end

local function HideAll(f)
    for _, k in ipairs({ "headIcon", "headName", "headSkill", "alert", "secNext", "stepIcon", "stepText",
                         "stepSub", "whereHead", "zoneTip", "tool", "tip", "vendorHead", "vendor",
                         "secTrain", "trainText", "gearHead", "gearNext", "gearBtn", "learn", "guideLine" }) do
        if f[k] then f[k]:Hide() end
    end
    for _, r in ipairs(f.gear or {}) do r:Hide() end
    for _, r in ipairs(f.rows) do r:Hide() end
    for _, z in ipairs(f.zones) do z:Hide() end
    for _, r in ipairs(f.trainers) do r:Hide() end
end

function PP:SelectedDef()
    local def = self.db.selected and self.byKey[self.db.selected]
    if def then return def end
    for _, d in ipairs(self.professions) do
        if self:GetSkill(d) then self.db.selected = d.key return d end
    end
    self.db.selected = self.professions[1] and self.professions[1].key
    return self.professions[1]
end

function PP:Refresh()
    local f = self.frame
    if not f then return end
    if self.RefreshTracker then self:RefreshTracker() end
    if self.shop and self.shop:IsShown() then self:RefreshShop() end
    if self.gearWin and self.gearWin:IsShown() then self:RefreshGear() end
    if not f:IsShown() then return end
    local def = self:SelectedDef()
    if not def then return end
    HideAll(f)

    -- tabs: your professions (or all of them), with your skill on each
    local shown = {}
    for _, b in ipairs(f.tabs) do
        local s = self:GetSkill(b.def)
        b.skill = s
        if self.db.showAll or s or b.def == def then shown[#shown + 1] = b else b:Hide() end
    end
    if #shown <= 1 and not self.db.showAll then
        -- nothing learned yet: show every profession so you can pick one
        shown = {}
        for _, b in ipairs(f.tabs) do shown[#shown + 1] = b end
    end
    for i, b in ipairs(shown) do
        local col, row = (i - 1) % 4, math.floor((i - 1) / 4)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 22 + col * 116, -46 - row * 34)
        b:Show()
        b:SetText(b.skill and (b.def.name .. " " .. b.skill) or b.def.name)
        local fs = b.GetFontString and b:GetFontString()
        if fs then
            fs:SetFont(PP.FONT, (#b:GetText() > 10) and 13 or 15, "")
            SetColor(fs, (b.def == def) and C.gold or C.white)
        end
        if b.def == def then b:LockHighlight() else b:UnlockHighlight() end
    end
    f.top = -46 - (math.floor((math.max(1, #shown) - 1) / 4) + 1) * 34 - 8

    local skill, max = self:GetSkill(def)
    local P = Placer(f, f.top)

    -- header
    f.headIcon:SetTexture(def.icon)
    P:Put(f.headIcon, 0, 24, 0)
    f.headName:SetText(def.name)
    f.headName:ClearAllPoints(); f.headName:SetPoint("TOPLEFT", f.headIcon, "TOPRIGHT", 12, -2); f.headName:Show()
    if skill then
        f.headSkill:SetText("Skill  " .. skill .. " / " .. (max or "?"))
        SetColor(f.headSkill, C.white)
    else
        f.headSkill:SetText("Not learned yet")
        SetColor(f.headSkill, C.red)
    end
    f.headSkill:ClearAllPoints(); f.headSkill:SetPoint("TOPLEFT", f.headName, "BOTTOMLEFT", 0, -4); f.headSkill:Show()
    P.y = P.y - 56
    local imported = self.ImportedGuide and self:ImportedGuide(def)
    if imported then
        local st = skill and self:StepFor(def, skill)
        local t = "Guide: " .. imported.title
        if st and not st.imported then t = t .. "  (it stops before your skill, so this is the ProfessionPal step)" end
        f.guideLine:SetText(t)
        P:Put(f.guideLine, P:TextH(f.guideLine, 15), 24, 4)
    end

    local cur, nxt, ni = self:RankInfo(def, skill, max)
    local lvl = self:PlayerLevel()

    if skill and skill >= 300 then
        f.alert:SetText("All done! You are at 300.")
        SetColor(f.alert, C.green)
        P:Put(f.alert, 20)
    elseif skill and max and skill >= max then
        f.alert:SetText("Skill is stuck at " .. max .. ". Train now!")
        SetColor(f.alert, C.red)
        P:Put(f.alert, 20)
    end

    -- next step
    local st = self:StepFor(def, skill or 1)
    local recipeNeed
    if st and not (skill and skill >= 300) then
        P:Put(f.secNext, 18, 24, 4)
        local s = skill or 1
        local n = self:CraftsNow(st, s)
        local iconItem
        if st.nodes then
            f.stepText:SetText(st.text)
            iconItem = st.nodes[1] and st.nodes[1][3]
        elseif st.smelt then
            f.stepText:SetText(st.text .. "  x " .. n)
            iconItem = st.mats[1][1]
        else
            f.stepText:SetText((n > 0) and ("Make " .. n .. "  x  " .. st.text) or ("Make:  " .. st.text))
            iconItem = st.mats and st.mats[1] and st.mats[1][1]
        end
        local sub = "Until skill " .. st.to
        if st.smelt then sub = sub .. "  -  at a forge" end
        if st.anvil then sub = sub .. "  -  at an anvil" end
        f.stepSub:SetText(sub)
        f.stepIcon:SetTexture(self:Icon(iconItem, def.icon))
        P:Put(f.stepIcon, 0, 24, 0)
        f.stepText:ClearAllPoints(); f.stepText:SetPoint("TOPLEFT", f.stepIcon, "TOPRIGHT", 12, 0); f.stepText:Show()
        f.stepSub:ClearAllPoints(); f.stepSub:SetPoint("TOPLEFT", f.stepText, "BOTTOMLEFT", 0, -4); f.stepSub:Show()
        local th = P:TextH(f.stepText, 20) + P:TextH(f.stepSub, 16) + 8
        P.y = P.y - math.max(48, th) - 6

        -- a new recipe this step needs (e.g. Heavy Linen Bandage at First Aid 40)
        recipeNeed = self:RecipeToLearn(def, st, skill)
        if recipeNeed then
            if recipeNeed.sure then
                f.learn:SetText("LEARN FIRST:  " .. self:RecipeText(def, recipeNeed))
            else
                f.learn:SetText("New recipe:  " .. self:RecipeText(def, recipeNeed) .. " (if you don't have it yet)")
            end
            P:Put(f.learn, P:TextH(f.learn, 18), 24, 6)
        end

        -- materials you need, or the veins you mine
        local i = 0
        if st.nodes then
            for _, node in ipairs(st.nodes) do
                i = i + 1
                local r = f.rows[i]
                if not r then break end
                r.icon:SetTexture(self:Icon(node[3]))
                local ok = s >= node[2]
                r.name:SetText(node[2] > 0 and (node[1] .. "  (skill " .. node[2] .. ")") or node[1])
                SetColor(r.name, ok and C.white or C.gray)
                r.count:SetText("have " .. self:Count(node[3]))
                SetColor(r.count, C.white)
                P:Put(r, 32, 30, 4)
            end
        else
            for _, m in ipairs(st.mats or {}) do
                i = i + 1
                local r = f.rows[i]
                if not r then break end
                local need = PP.MatNeed(st, m, n)
                local have = self:Count(m[1])
                r.icon:SetTexture(self:Icon(m[1]))
                r.name:SetText(m[3] or tostring(m[1]))
                SetColor(r.name, C.white)
                r.count:SetText(have .. " / " .. need)
                SetColor(r.count, have >= need and C.green or C.red)
                P:Put(r, 32, 30, 4)
            end
        end
        P.y = P.y - 4

        -- where to go (gathering). Two formats: zone keys (Mining) or { name, tip } lists.
        local list = (st.zones or st.zoneList) and self:ZoneOptions(def, st) or {}
        if #list > 0 then
            f.whereHead:SetText(#list > 1 and "Go to (closest first):" or "Go to:")
            P:Put(f.whereHead, 16, 24, 4)
            for zi = 1, math.min(#f.zones, #list) do
                local z = list[zi]
                local fs = f.zones[zi]
                local t = (zi == 1 and "" or "or  ") .. z.name
                if z.level then t = t .. "   (level " .. z.level .. ")" end
                if z.here then t = t .. "   - you are here" end
                fs:SetText(t)
                SetColor(fs, zi == 1 and C.white or C.gray)
                P:Put(fs, P:TextH(fs, 16), 36, 3)
                if zi == 1 and z.tip then
                    f.zoneTip:SetText(z.tip)
                    P:Put(f.zoneTip, P:TextH(f.zoneTip, 15), 50, 6)
                end
            end
        end

        -- plans vendor
        if st.vendor then
            P:Put(f.vendorHead, 16, 24, 2)
            f.vendor:SetWho(st.vendor)
            P:Put(f.vendor, 42, 36, 4)
        end

        -- tool check
        if def.tool and skill and self:Count(def.tool[1]) == 0 then
            f.tool:SetText("You need a " .. def.tool[2] .. " in your bags.")
            P:Put(f.tool, P:TextH(f.tool, 16), 24, 4)
        end
        if st.tip then
            f.tip:SetText(st.tip)
            P:Put(f.tip, P:TextH(f.tip, 15), 24, 8)
        end
    end

    -- gear you can make for your class
    if self:GearListFor(def) and skill then
        local now, nextPick = self:GearPicks(def, skill)
        if #now > 0 or nextPick or #self:GearBySlot(def, skill) > 0 then
            f.gearHead:SetText("GEAR FOR YOU  (" .. PP.ROLE_NAMES[self:Role()] .. ")")
            P.y = P.y - 4
            f.gearBtn:ClearAllPoints(); f.gearBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, P.y + 4); f.gearBtn:Show()
            P:Put(f.gearHead, 22, 24, 4)
            if #now == 0 then
                f.gearNext:SetText("You wear better than you can make now.")
                P:Put(f.gearNext, 16, 30, 4)
            end
            for i, p in ipairs(now) do
                local r, it = f.gear[i], p.it
                r.it = it
                r.icon:SetTexture(self:Icon(it.id))
                r.name:SetText("Make: " .. it.name)
                r.name:SetTextColor(unpack(PP.QualityColor(it.q)))
                local wear = (it.level > lvl) and ("wear at level " .. it.level) or ("level " .. it.level)
                r.sub:SetText((PP.SLOT_NAMES[it.slot] or "") .. "  -  " .. wear .. "  -  " .. self:GearSourceText(it))
                P:Put(r, 40, 30, 4)
            end
            if nextPick and #now > 0 then
                local it = nextPick.it
                f.gearNext:SetText("Coming up: " .. it.name .. " (" .. (PP.SLOT_NAMES[it.slot] or "") .. ") at skill " .. it.skill)
                P:Put(f.gearNext, P:TextH(f.gearNext, 16), 30, 6)
            end
        end
    end

    -- training
    local showTrainers = false
    if not skill then
        f.secTrain:SetText("LEARN IT")
        f.trainText:SetText("Learn " .. def.name .. " from a trainer:")
        SetColor(f.trainText, C.white)
        showTrainers = true
    elseif nxt then
        f.secTrain:SetText("TRAINER")
        if skill >= nxt.skill then
            if lvl < (nxt.level or 0) then
                f.trainText:SetText(nxt.name .. ": needs character level " .. nxt.level .. " (you are " .. lvl .. ")")
                SetColor(f.trainText, C.red)
            elseif nxt.note then
                f.trainText:SetText("GET " .. nxt.name:upper() .. " NOW:  " .. nxt.note)
                SetColor(f.trainText, C.orange)
            else
                f.trainText:SetText("TRAIN NOW:  " .. nxt.name)
                SetColor(f.trainText, C.orange)
            end
            showTrainers = true
        else
            local t = "Next: " .. nxt.name .. " at skill " .. nxt.skill
            if (nxt.level or 0) > 0 then t = t .. ", level " .. nxt.level end
            if nxt.note then t = t .. ". " .. nxt.note end
            f.trainText:SetText(t)
            SetColor(f.trainText, C.gray)
            showTrainers = skill >= nxt.skill - 10
        end
    else
        f.secTrain:SetText("TRAINER")
        f.trainText:SetText("No more training. Max skill is 300.")
        SetColor(f.trainText, C.gray)
    end
    -- a trainer recipe to learn wins over "Next: ... at skill X"
    local trainerRank = ni
    if recipeNeed and recipeNeed.src == "trainer" and skill and not (nxt and skill >= nxt.skill) then
        f.secTrain:SetText("TRAINER")
        f.trainText:SetText("LEARN:  " .. recipeNeed.name)
        SetColor(f.trainText, C.orange)
        showTrainers = true
        trainerRank = math.max(1, cur or 1)
    end
    P.y = P.y - 4
    P:Put(f.secTrain, 18, 24, 4)
    P:Put(f.trainText, P:TextH(f.trainText, 18), 24, 6)
    if showTrainers then
        local list = self:TrainersFor(def, trainerRank)
        for k = 1, math.min(2, #list) do
            local t = list[k]
            f.trainers[k]:SetWho(t, t.junior and (def.key == "mining" and "  (no smelting)" or "  (Apprentice only)") or nil)
            P:Put(f.trainers[k], 42, 36, 6)
        end
    end

    -- bottom buttons
    P.y = P.y - 6
    f.shopBtn:ClearAllPoints(); f.shopBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 24, P.y)
    f.setBtn:ClearAllPoints(); f.setBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, P.y)
    f.guideBtn:ClearAllPoints(); f.guideBtn:SetPoint("TOP", f, "TOP", 10, P.y)
    f:SetHeight(-P.y + 54)
end

function PP:Toggle()
    if not self.frame then
        if not self.db then return end
        self:BuildUI()
    end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); self:Refresh() end
end

-- ---------- shopping list ----------
function PP:BuildShop()
    local s = Window("ProfessionPalShop", 440, "Shopping List")
    self.shop = s
    s:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
    s.sub = Text(s, 15, C.white, "CENTER"); s.sub:SetWidth(380)
    s.sub:SetPoint("TOP", s, "TOP", 0, -44)
    s.rows = {}
    for i = 1, 18 do
        local r = CreateFrame("Frame", nil, s)
        r:SetSize(380, 32)
        r.icon = Icon(r, 28); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.name = Text(r, 15, C.white); r.name:SetPoint("LEFT", r.icon, "RIGHT", 10, 0); r.name:SetWidth(230)
        r.count = Text(r, 16, C.white, "RIGHT"); r.count:SetPoint("RIGHT", r, "RIGHT", 0, 0); r.count:SetWidth(120)
        r:Hide()
        s.rows[i] = r
    end
    s.notes = Text(s, 14, C.yellow); s.notes:SetWidth(380)
    s.key = Text(s, 14, C.gray); s.key:SetWidth(380)
    s.key:SetText("Green = you have enough.  Counts include your bank.")
    s:SetScript("OnShow", function() PP:RefreshShop() end)
    s:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
end

function PP:RefreshShop()
    local s = self.shop
    if not (s and s:IsShown()) then return end
    local def = self:SelectedDef()
    if not def then return end
    local skill, max = self:GetSkill(def)
    local list, stop, notes = self:ShoppingList(def, skill or 1, max)
    s.title:SetText(def.name .. " - Shopping List")
    s.sub:SetText("From skill " .. (skill or 1) .. " to " .. stop)
    for _, r in ipairs(s.rows) do r:Hide() end
    local y = -72
    for i, t in ipairs(list) do
        local r = s.rows[i]
        if not r then break end
        r.icon:SetTexture(self:Icon(t.item))
        r.name:SetText(t.name .. (t.made and "  (you make)" or ""))
        SetColor(r.name, t.made and C.gray or C.white)
        r.count:SetText(t.have .. " / " .. t.need)
        SetColor(r.count, t.have >= t.need and C.green or C.red)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y); r:Show()
        y = y - 34
    end
    local extra = {}
    for _, n in ipairs(notes or {}) do extra[#extra + 1] = n end
    if #list == 0 then
        extra[#extra + 1] = def.gather and "Nothing to buy. Just go mine!" or "Nothing to buy for this part."
    end
    if def.tool then extra[#extra + 1] = "Keep a " .. def.tool[2] .. " in your bags." end
    s.notes:SetText(table.concat(extra, "\n"))
    s.notes:ClearAllPoints(); s.notes:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y - 6); s.notes:Show()
    local nh = s.notes:GetStringHeight()
    if type(nh) ~= "number" or nh < 16 then nh = 16 * #extra end
    y = y - 6 - nh - 10
    s.key:ClearAllPoints(); s.key:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y); s.key:Show()
    s:SetHeight(-y + 40)
end

function PP:ToggleShop()
    if self.shop:IsShown() then self.shop:Hide() else self.shop:Show() end
end

-- ---------- gear window: best piece to make for every slot ----------
function PP:BuildGear()
    local g = Window("ProfessionPalGear", 540, "Gear You Can Make")
    self.gearWin = g
    g:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", -4, 0)
    g.sub = Text(g, 15, C.white, "CENTER"); g.sub:SetWidth(480)
    g.sub:SetPoint("TOP", g, "TOP", 0, -44)
    g.rows = {}
    for i = 1, 12 do
        local r = CreateFrame("Button", nil, g)
        r:SetSize(480, 50)
        r.slot = Text(r, 14, C.gold); r.slot:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2); r.slot:SetWidth(80)
        r.icon = Icon(r, 32); r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 84, 0)
        r.name = Text(r, 15, C.white); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1); r.name:SetWidth(270)
        r.state = Text(r, 14, C.green, "RIGHT"); r.state:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -2); r.state:SetWidth(110)
        r.sub = Text(r, 13, C.gray); r.sub:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -2); r.sub:SetWidth(380)
        r:SetScript("OnEnter", function(self) PP:GearTooltip(self, self.it) end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        r:Hide()
        g.rows[i] = r
    end
    g.empty = Text(g, 15, C.gray); g.empty:SetWidth(480)
    g.key = Text(g, 13, C.gray); g.key:SetWidth(480)
    g.key:SetText("Picked by stats for your class and role. Hover an item for details.")
    g:SetScript("OnShow", function() PP:RefreshGear() end)
    g:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    g:SetScale(self.db.scale or 1)
end

function PP:RefreshGear()
    local g = self.gearWin
    if not (g and g:IsShown()) then return end
    local def = self:SelectedDef()
    local skill = def and self:GetSkill(def)
    g.title:SetText((def and def.name or "") .. " - Gear")
    g.sub:SetText(PP.ROLE_NAMES[self:Role()] .. "  -  level " .. self:PlayerLevel() .. "  -  skill " .. (skill or 0))
    for _, r in ipairs(g.rows) do r:Hide() end
    g.empty:Hide()
    local rows = (def and skill) and self:GearBySlot(def, skill) or {}
    local y = -72
    for i, row in ipairs(rows) do
        local r = g.rows[i]
        if not r then break end
        r.slot:SetText(row.name)
        local p = row.now or row.next
        local it = p.it
        r.it = it
        r.icon:SetTexture(self:Icon(it.id))
        r.name:SetText(it.name)
        r.name:SetTextColor(unpack(PP.QualityColor(it.q)))
        local sub = "level " .. it.level .. "  -  skill " .. it.skill .. "  -  " .. self:GearSourceText(it)
        if row.now and row.next then
            sub = sub .. "\nNext: " .. row.next.it.name .. " at skill " .. row.next.it.skill
        end
        r.sub:SetText(sub)
        if row.now and row.now.upgrade then
            r.state:SetText("Make it!"); SetColor(r.state, C.green)
        elseif row.now then
            r.state:SetText("You wear better"); SetColor(r.state, C.gray)
        else
            r.state:SetText("At skill " .. it.skill); SetColor(r.state, C.orange)
        end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", g, "TOPLEFT", 30, y); r:Show()
        y = y - ((row.now and row.next) and 64 or 50)
    end
    if #rows == 0 then
        g.empty:SetText(skill and "Nothing here for your class right now." or "Learn this profession first.")
        g.empty:ClearAllPoints(); g.empty:SetPoint("TOPLEFT", g, "TOPLEFT", 30, y); g.empty:Show()
        y = y - 30
    end
    g.key:ClearAllPoints(); g.key:SetPoint("TOPLEFT", g, "TOPLEFT", 30, y - 4); g.key:Show()
    g:SetHeight(-y + 44)
end

function PP:ToggleGear()
    if not self.gearWin then self:BuildGear() end
    if self.gearWin:IsShown() then self.gearWin:Hide() else self.gearWin:Show() end
end

-- ---------- settings ----------
local function Check(parent, label, get, set)
    local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    c:SetSize(32, 32)
    c.label = Text(parent, 15, C.white)
    c.label:SetPoint("LEFT", c, "RIGHT", 6, 0)
    c.label:SetWidth(330)
    c.label:SetText(label)
    c:SetScript("OnShow", function(self) self:SetChecked(get() and true or false) end)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); PP:Refresh() end)
    return c
end

function PP:BuildSettings()
    local s = Window("ProfessionPalSettings", 460, "ProfessionPal Settings")
    self.settings = s
    s:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    local y = -54
    s.checks = {}
    for _, def in ipairs(self.professions) do
        if def.altSteps then
            local key = def.key
            local c = Check(s, def.altSteps.label,
                function() return PP.db.smeltFirst[key] end,
                function(v) PP.db.smeltFirst[key] = v end)
            c:SetPoint("TOPLEFT", s, "TOPLEFT", 24, y)
            y = y - 44
            s.checks[#s.checks + 1] = c
        end
    end
    local function AddCheck(label, field)
        local c = Check(s, label,
            function() return PP.db[field] end,
            function(v) PP.db[field] = v end)
        c:SetPoint("TOPLEFT", s, "TOPLEFT", 24, y)
        y = y - 40
        s.checks[#s.checks + 1] = c
    end

    -- A "Label: 60%  [less] [more]" row
    local steppers = {}
    local function AddStepper(label, field, minv, maxv, apply, lessText, moreText)
        local txt = Text(s, 16, C.white)
        txt:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y - 6)
        local function set(d)
            local v = math.floor(((PP.db[field] or 1) + d) * 10 + 0.5) / 10
            if v < minv then v = minv end
            if v > maxv then v = maxv end
            PP.db[field] = v
            apply(v)
            txt:SetText(label .. ":  " .. math.floor(v * 100 + 0.5) .. "%")
        end
        local minus = Button(s, lessText or "Smaller", 90, 30, function() set(-0.1) end)
        minus:SetPoint("TOPLEFT", s, "TOPLEFT", 250, y)
        local plus = Button(s, moreText or "Bigger", 90, 30, function() set(0.1) end)
        plus:SetPoint("LEFT", minus, "RIGHT", 6, 0)
        y = y - 42
        steppers[#steppers + 1] = set
    end

    AddCheck("Lock the guide window", "locked")
    AddStepper("Guide size", "scale", 0.8, 1.5, function(v)
        PP.frame:SetScale(v)
        if PP.shop then PP.shop:SetScale(v) end
    end)

    -- role for "Gear for you"
    local roleText = Text(s, 16, C.white)
    roleText:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y - 6)
    local function showRole()
        local r = PP.db.role or "auto"
        local t = "Gear for:  " .. PP.ROLE_NAMES[r]
        if r == "auto" then t = t .. " (" .. PP.ROLE_NAMES[PP:Role()] .. ")" end
        roleText:SetText(t)
    end
    local roleBtn = Button(s, "Change", 120, 30, function()
        local cur, nxt = PP.db.role or "auto", 1
        for i, r in ipairs(PP.ROLE_ORDER) do if r == cur then nxt = i % #PP.ROLE_ORDER + 1 end end
        PP.db.role = PP.ROLE_ORDER[nxt]
        showRole()
        PP:Refresh()
    end)
    roleBtn:SetPoint("TOPLEFT", s, "TOPLEFT", 250, y)
    y = y - 42
    steppers[#steppers + 1] = function() showRole() end
    AddCheck("Show all professions (not only mine)", "showAll")

    -- auto-learn at the trainer (off by default) + spending limit
    local thead = Text(s, 16, C.gold)
    thead:SetPoint("TOPLEFT", s, "TOPLEFT", 24, y - 8)
    thead:SetText("AUTO-LEARN AT TRAINER")
    y = y - 34
    AddCheck("Learn what the guide needs (spends gold)", "autoLearn")
    local LIMITS = { 1, 5, 10, 25, 50, 100, 250, 500, 1000 }
    local limitText = Text(s, 16, C.white)
    limitText:SetPoint("TOPLEFT", s, "TOPLEFT", 30, y - 6)
    local function setLimit(d)
        local cur, idx = PP.db.autoLearnMax or 10, 3
        for i, v in ipairs(LIMITS) do if v == cur then idx = i end end
        idx = math.max(1, math.min(#LIMITS, idx + d))
        PP.db.autoLearnMax = LIMITS[idx]
        limitText:SetText("Spend up to:  " .. LIMITS[idx] .. " gold")
    end
    local lless = Button(s, "Less", 90, 30, function() setLimit(-1) end)
    lless:SetPoint("TOPLEFT", s, "TOPLEFT", 250, y)
    local lmore = Button(s, "More", 90, 30, function() setLimit(1) end)
    lmore:SetPoint("LEFT", lless, "RIGHT", 6, 0)
    y = y - 42
    steppers[#steppers + 1] = function() setLimit(0) end

    local head = Text(s, 16, C.gold)
    head:SetPoint("TOPLEFT", s, "TOPLEFT", 24, y - 8)
    head:SetText("ON-SCREEN TRACKER")
    y = y - 34
    AddCheck("Show the tracker", "tracker")
    AddCheck("Hide it in combat", "trackerHideCombat")
    AddCheck("Lock the tracker", "trackerLocked")
    AddCheck("Show spell buttons (Find Minerals...)", "trackerButtons")
    AddStepper("Background", "trackerAlpha", 0, 1, function() PP:ApplyTrackerLook() end, "Lighter", "Darker")
    AddStepper("Tracker size", "trackerScale", 0.7, 1.5, function() PP:ApplyTrackerLook() end)

    y = y - 4
    local reset = Button(s, "Reset positions", 170, 30, function()
        PP.db.point = nil
        PP.frame:ClearAllPoints()
        PP.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        PP.db.trackerPoint = nil
        if PP.tracker and not PP:InCombat() then
            PP.tracker:ClearAllPoints()
            PP.tracker:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
        end
    end)
    reset:SetPoint("TOPLEFT", s, "TOPLEFT", 24, y)
    y = y - 46
    s:SetHeight(-y + 24)
    s:SetScript("OnShow", function() for _, set in ipairs(steppers) do set(0) end end)
    if self.shop then self.shop:SetScale(self.db.scale or 1) end
end

function PP:ToggleSettings()
    if self.settings:IsShown() then self.settings:Hide() else self.settings:Show() end
end
