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
    size = math.max(14, size)
    fs:SetFont(size >= 18 and (PP.TITLE_FONT or PP.FONT) or PP.FONT, size, "")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetTextColor(unpack(color or C.white))
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function SetColor(fs, color) fs:SetTextColor(unpack(color)) end

local function OneLine(fs)
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    if fs.SetMaxLines then fs:SetMaxLines(1) end
    return fs
end

-- Flat navy button with gold text (lighter when you point at it, gold edge when selected)
local function Button(parent, label, w, h, onClick)
    local T = PP.THEME
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w, h or 30)
    PP.Skin(b, nil, { bg = T.btn, border = T.btnBorder })
    local fs = Text(b, 15, C.white, "CENTER")
    fs:SetPoint("LEFT", b, "LEFT", 4, 0)
    fs:SetPoint("RIGHT", b, "RIGHT", -4, 0)
    b:SetFontString(fs)
    b:SetText(label)
    b.selected = false
    local function paint(self, hover)
        if not self.SetBackdropColor then return end
        local fill = self.selected and T.btnSel or (hover and T.btnHover or T.btn)
        self:SetBackdropColor(unpack(fill))
        self:SetBackdropBorderColor(unpack(self.selected and T.selBorder or T.btnBorder))
    end
    b:SetScript("OnEnter", function(self) if self:IsEnabled() then paint(self, true) end end)
    b:SetScript("OnLeave", function(self) paint(self, false) end)
    b:SetScript("OnDisable", function(self) fs:SetTextColor(0.45, 0.47, 0.55); paint(self, false) end)
    b:SetScript("OnEnable", function(self) fs:SetTextColor(unpack(self.textColor or C.white)) end)
    b:SetScript("OnMouseDown", function(self) if self:IsEnabled() then fs:SetPoint("LEFT", self, "LEFT", 5, -1) end end)
    b:SetScript("OnMouseUp", function(self) fs:SetPoint("LEFT", self, "LEFT", 4, 0) end)
    function b:SetSelected(on) self.selected = on and true or false; paint(self, false) end
    function b:SetLabelColor(color) self.textColor = color; if self:IsEnabled() then fs:SetTextColor(unpack(color)) end end
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
    PP.Skin(f, 40)
    f.title = Text(f, 18, C.gold, "CENTER")
    f.title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -11)
    f.title:SetText(title)
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
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
    r.name = OneLine(Text(r, 15, C.white))
    r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2)
    r.name:SetWidth(TEXTW - 196)
    r.place = OneLine(Text(r, 14, C.gray))
    r.place:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -22)
    r.place:SetWidth(TEXTW - 196)
    r.pin = Button(r, "Map Pin", 90, 28, function() PP:Pin(r.who) end)
    r.pin:SetPoint("TOPRIGHT", r, "TOPRIGHT", -92, -4)
    r.tom = Button(r, "TomTom", 88, 28, function() PP:TomTom(r.who) end)
    r.tom:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -4)
    function r:SetWho(t, extra)
        self.who = t
        self.name:SetText(t.n .. (extra or ""))
        self.place:SetText(t.p)
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
    r.name = OneLine(Text(r, 15, C.white))
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
        local b = Button(f, def.name, 146, 30, function()
            PP.db.selected = def.key
            PP:Refresh()
        end)
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 25 + col * 152, -46 - row * 34)
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
    f.stepPanel = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.stepPanel:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.stepPanel:SetVertexColor(unpack(PP.THEME.inset))
    f.stepAccent = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    f.stepAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.stepAccent:SetVertexColor(unpack(PP.C.gold))
    f.stepAccent:SetWidth(3)
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
    for i = 1, 4 do
        local r = CreateFrame("Button", nil, f)
        r:SetSize(TEXTW, 40)
        r.icon = Icon(r, 34); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.name = OneLine(Text(r, 15, C.white)); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -1); r.name:SetWidth(TEXTW - 130)
        r.sub = OneLine(Text(r, 13, C.gray)); r.sub:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -21); r.sub:SetWidth(TEXTW - 130)
        r.list = Button(r, "Materials", 110, 26, function()
            if r.craft then PP:CraftGear(r.it) else PP:ShowGearShop({ r.it }) end
        end)
        r.list:SetPoint("RIGHT", r, "RIGHT", 0, 0)
        function r:SetCraft(on)
            self.craft = on
            self.list:SetText(on and "Craft it" or "Materials")
            self.list:SetLabelColor(on and C.green or C.gold)
        end
        r:SetScript("OnEnter", function(self) PP:GearTooltip(self, self.it) end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        r:Hide()
        f.gear[i] = r
    end
    f.gearNext = Text(f, 14, C.gray); f.gearNext:SetWidth(TEXTW)
    f.gearBtn = Button(f, "All Gear", 110, 26, function() PP:ToggleGear() end)
    f.gearShopBtn = Button(f, "All Materials", 130, 26, function() PP:ShowGearShopAll() end)

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
                         "stepSub", "stepPanel", "stepAccent", "whereHead", "zoneTip", "tool", "tip", "vendorHead", "vendor",
                         "secTrain", "trainText", "gearHead", "gearNext", "gearBtn", "gearShopBtn", "learn", "guideLine" }) do
        if f[k] then f[k]:Hide() end
    end
    for _, r in ipairs(f.gear or {}) do r:Hide() end
    for _, r in ipairs(f.rows) do r:Hide(); if r.find then r.find:Hide() end end
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
    if self.gearShop and self.gearShop:IsShown() then self:RefreshGearShop() end
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
        local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 25 + col * 152, -46 - row * 34)
        b:Show()
        local fs = b.GetFontString and b:GetFontString()
        if fs then fs:SetFont(PP.FONT, 15, ""); OneLine(fs) end
        b:SetText(b.def.name)
        -- too long for the button? drop the number (it is in the header anyway)
        local tw = fs and fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()
        if b.skill and type(tw) == "number" and tw > 136 then b:SetText(b.def.name) end
        -- selected tab: lighter fill, gold edge, gold text; others: white text
        b:SetLabelColor((b.def == def) and C.gold or C.white)
        b:SetSelected(b.def == def)
    end
    f.top = -46 - (math.floor((math.max(1, #shown) - 1) / 3) + 1) * 34 - 8

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
    P.y = P.y - 68
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
        P.y = P.y - 8
        P:Put(f.secNext, 18, 24, 8)
        f.stepPanel:ClearAllPoints()
        f.stepPanel:SetPoint("TOPLEFT", f.secNext, "TOPLEFT", -12, 8)
        f.stepPanel:SetPoint("BOTTOMRIGHT", f.stepSub, "BOTTOMRIGHT", 12, -10)
        f.stepPanel:Show()
        f.stepAccent:ClearAllPoints()
        f.stepAccent:SetPoint("TOPLEFT", f.stepPanel, "TOPLEFT", 0, 0)
        f.stepAccent:SetPoint("BOTTOMLEFT", f.stepPanel, "BOTTOMLEFT", 0, 0)
        f.stepAccent:Show()
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
            f.stepText:SetText((n > 0) and (n .. " x " .. st.text) or ("Make:  " .. st.text))
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
        P.y = P.y - math.max(48, th) - 20

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
                if self.BindFarmRow then self:BindFarmRow(r,m[1]) end
                SetColor(r.count, have >= need and C.green or C.red)
                P:Put(r, 32, 30, 4)
            end
        end
        P.y = P.y - 4

        -- where to go (gathering). Two formats: zone keys (Mining) or { name, tip } lists.
        local list = (st.zones or st.zoneList) and self:ZoneOptions(def, st) or {}
        if #list > 0 then
            f.whereHead:SetText("Go to:")
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
        local now, nextPick, betterPick = self:GearPicks(def, skill)
        if #now > 0 or nextPick or betterPick or #self:GearBySlot(def, skill) > 0 then
            f.gearHead:SetText("GEAR  /  " .. PP.ROLE_NAMES[self:Role()])
            P.y = P.y - 4
            f.gearBtn:ClearAllPoints(); f.gearBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -24, P.y - 24); f.gearBtn:Show()
            if #now > 0 then
                f.gearShopBtn:ClearAllPoints(); f.gearShopBtn:SetPoint("RIGHT", f.gearBtn, "LEFT", -6, 0); f.gearShopBtn:Show()
            end
            P:Put(f.gearHead, 54, 24, 4)
            if #now == 0 then
                f.gearNext:SetText("You wear better than you can make now.")
                P:Put(f.gearNext, 16, 30, 4)
            end
            for i, p in ipairs(now) do
                local r, it = f.gear[i], p.it
                r.it = it
                r.icon:SetTexture(self:Icon(it.id))
                r.name:SetText(it.name)
                r.name:SetTextColor(unpack(PP.QualityColor(it.q)))
                local wear = (it.level > lvl) and ("wear at level " .. it.level) or ("level " .. it.level)
                r.sub:SetText((PP.SLOT_NAMES[it.slot] or "") .. "  -  " .. wear .. "  -  " .. self:GearSourceText(it))
                r:SetCraft(self:CanCraft(it))
                P:Put(r, 40, 30, 4)
            end
            -- a better piece that needs plans or rare materials (hover = how to get them)
            if betterPick then
                local r, it = f.gear[4], betterPick.it
                r.it = it
                r.icon:SetTexture(self:Icon(it.id))
                r.name:SetText("Better: " .. it.name)
                r.name:SetTextColor(unpack(PP.QualityColor(it.q)))
                r.sub:SetText((PP.SLOT_NAMES[it.slot] or "") .. "  -  " .. betterPick.why)
                r:SetCraft(false)
                r.sub:SetTextColor(1, 0.55, 0.15)
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
        f.trainText:SetText("Visit a trainer")
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
            f.trainers[k]:SetWho(t, (t.junior and skill) and (def.key == "mining" and "  (no smelting)" or "  (low ranks)") or nil)
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
        if self.BindFarmRow then self:BindFarmRow(r,t.item) end
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
    g.scroll = CreateFrame("ScrollFrame", nil, g, "UIPanelScrollFrameTemplate")
    g.scroll:SetPoint("TOPLEFT", g, "TOPLEFT", 0, -68)
    g.scroll:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -24, 12)
    g.body = CreateFrame("Frame", nil, g.scroll)
    g.body:SetSize(516, 400)
    g.scroll:SetScrollChild(g.body)
    g.offset = 0
    g.scroll:EnableMouseWheel(true)
    g.scroll:SetScript("OnMouseWheel", function(_, delta)
        g.offset = math.max(0, math.min(g.maxScroll or 0, (g.offset or 0) - delta * 48))
        g.scroll:SetVerticalScroll(g.offset)
    end)
    g.rows = {}
    for i = 1, 12 do
        local r = CreateFrame("Button", nil, g.body)
        r:SetSize(480, 50)
        r.slot = Text(r, 14, C.gold); r.slot:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -2); r.slot:SetWidth(80)
        r.icon = Icon(r, 32); r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 84, 0)
        r.name = Text(r, 15, C.white); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1); r.name:SetWidth(240)
        r.state = Text(r, 14, C.green, "RIGHT"); r.state:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -2); r.state:SetWidth(110)
        r.list = Button(r, "Materials", 110, 24, function()
            if r.craft then PP:CraftGear(r.it) else PP:ShowGearShop({ r.it }) end
        end)
        r.list:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -20)
        r.sub = Text(r, 13, C.gray); r.sub:SetPoint("TOPLEFT", r, "TOPLEFT", 124, -48); r.sub:SetWidth(350)
        r:SetScript("OnEnter", function(self) PP:GearTooltip(self, self.it) end)
        r:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
        r:Hide()
        g.rows[i] = r
    end
    g.empty = Text(g.body, 15, C.gray); g.empty:SetWidth(480)
    g.key = Text(g.body, 13, C.gray); g.key:SetWidth(480)
    g.key:SetText("Picked by stats for your class and role. Hover an item for details.")
    g.campHead = Text(g.body, 15, C.gold); g.campHead:SetWidth(480); g.campHead:Hide()
    g.shopAll = Button(g.body, "All Materials", 400, 30, function() PP:ShowGearShopAll() end)
    g.camp = PersonRow(g.body)
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
    local y = -8
    local needCamp = false
    g.camp:Hide(); g.campHead:Hide()
    for i, row in ipairs(rows) do
        local r = g.rows[i]
        if not r then break end
        r.slot:SetText(row.name)
        local p = row.now or row.better or row.next
        local it = p.it
        r.it = it
        r.icon:SetTexture(self:Icon(it.id))
        r.name:SetText(it.name)
        r.name:SetTextColor(unpack(PP.QualityColor(it.q)))
        local sub = "level " .. it.level .. "  -  skill " .. it.skill .. "  -  " .. self:GearSourceText(it)
        local extra = 0
        if row.now and row.better then
            sub = sub .. "\nBetter: " .. row.better.it.name .. " - " .. row.better.why
            extra = extra + 14
        end
        if row.next and p ~= row.next then
            sub = sub .. "\nNext: " .. row.next.it.name .. " at skill " .. row.next.it.skill
            extra = extra + 14
        end
        if it.plan or (row.better and row.better.it.plan) then needCamp = true end
        r.craft = row.now and p == row.now and self:CanCraft(it)
        r.list:SetText(r.craft and "Craft it" or "Materials")
        r.list:SetLabelColor(r.craft and C.green or C.gold)
        r.sub:SetText(sub)
        if row.now and row.now.upgrade then
            r.state:SetText(row.now.state == "buy" and "Buy plans" or "Make it!"); SetColor(r.state, C.green)
        elseif row.now then
            r.state:SetText("You wear better"); SetColor(r.state, C.gray)
        elseif p == row.better then
            r.state:SetText("Needs plans/mats"); SetColor(r.state, C.orange)
        else
            r.state:SetText("At skill " .. it.skill); SetColor(r.state, C.orange)
        end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", g.body, "TOPLEFT", 30, y); r:Show()
        local textHeight = r.sub:GetStringHeight()
        if type(textHeight) ~= "number" then textHeight = 14 + extra end
        local rowHeight = math.max(68, 54 + textHeight)
        r:SetHeight(rowHeight)
        y = y - rowHeight - 8
    end
    if #rows == 0 then
        g.empty:SetText(skill and "Nothing here for your class right now." or "Learn this profession first.")
        g.empty:ClearAllPoints(); g.empty:SetPoint("TOPLEFT", g.body, "TOPLEFT", 30, y); g.empty:Show()
        y = y - 30
    end
    local camp = needCamp and self:FavorCamp()
    if camp then
        g.campHead:SetText("Plans for Merchant's Favor (you have " .. self:FavorHave() .. "):")
        g.campHead:ClearAllPoints(); g.campHead:SetPoint("TOPLEFT", g.body, "TOPLEFT", 30, y - 4); g.campHead:Show()
        g.camp:SetWho(camp)
        g.camp:ClearAllPoints(); g.camp:SetPoint("TOPLEFT", g.body, "TOPLEFT", 30, y - 26); g.camp:Show()
        y = y - 74
    end
    g.shopAll:Hide()
    if def and skill and #self:GearShopAllItems(def, skill) > 0 then
        g.shopAll:ClearAllPoints(); g.shopAll:SetPoint("TOP", g.body, "TOPLEFT", 270, y - 6); g.shopAll:Show()
        y = y - 44
    end
    g.key:ClearAllPoints(); g.key:SetPoint("TOPLEFT", g.body, "TOPLEFT", 30, y - 4); g.key:Show()
    local content = -y + 40
    local screen = UIParent.GetHeight and UIParent:GetHeight() or 900
    if type(screen) ~= "number" or screen <= 0 then screen = 900 end
    local height = math.min(content + 80, math.max(240, screen / (self.db.scale or 1) - 90))
    g:SetHeight(height)
    g.body:SetHeight(content)
    g.maxScroll = math.max(0, content - (height - 80))
    g.offset = math.min(g.offset or 0, g.maxScroll)
    g.scroll:SetVerticalScroll(g.offset)
end

-- ---------- gear shopping list: everything one piece (or all picks) needs ----------
local SHOPW = 500
function PP:BuildGearShop()
    local w = Window("ProfessionPalGearShop", SHOPW, "What You Need")
    self.gearShop = w
    w:SetPoint("TOPLEFT", self.frame, "TOPRIGHT", 4, 0)
    w.scroll = CreateFrame("ScrollFrame", nil, w, "UIPanelScrollFrameTemplate")
    w.scroll:SetPoint("TOPLEFT", w, "TOPLEFT", 0, -42)
    w.scroll:SetPoint("BOTTOMRIGHT", w, "BOTTOMRIGHT", -24, 12)
    local body = CreateFrame("Frame", nil, w.scroll)
    body:SetSize(SHOPW - 24, 400)
    w.body = body
    w.scroll:SetScrollChild(body)
    w.offset = 0
    w.scroll:EnableMouseWheel(true)
    w.scroll:SetScript("OnMouseWheel", function(_, delta)
        w.offset = math.max(0, math.min(w.maxScroll or 0, (w.offset or 0) - delta * 48))
        w.scroll:SetVerticalScroll(w.offset)
    end)
    w.head = Text(body, 16, C.white); w.head:SetWidth(SHOPW - 60)
    w.forText = Text(body, 14, C.gray); w.forText:SetWidth(SHOPW - 60)
    w.status = Text(body, 16, C.green); w.status:SetWidth(SHOPW - 60)
    w.matHead = Text(body, 16, C.gold); w.matHead:SetText("MATERIALS")
    w.planHead = Text(body, 16, C.gold); w.planHead:SetText("RECIPES")
    w.rows = {}
    for i = 1, 120 do
        local r = CreateFrame("Frame", nil, body)
        r:SetSize(SHOPW - 60, 40)
        r.icon = Icon(r, 32); r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, 0)
        r.name = Text(r, 15, C.white); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, -1); r.name:SetWidth(SHOPW - 230)
        r.count = Text(r, 17, C.white, "RIGHT"); r.count:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -1); r.count:SetWidth(120)
        r.where = Text(r, 13, C.gray); r.where:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3); r.where:SetWidth(SHOPW - 110)
        r:Hide()
        w.rows[i] = r
    end
    w.camp = PersonRow(body)
    w.craftBtn = Button(body, "Craft it", 180, 34, function() PP:CraftGear(w.items and w.items[1]) end)
    w.craftBtn:SetLabelColor(C.green)
    w.craftWhere = Text(body, 14, C.white); w.craftWhere:SetWidth(SHOPW - 260)
    w.note = Text(body, 14, C.yellow); w.note:SetWidth(SHOPW - 60)
    w.key = Text(body, 13, C.gray); w.key:SetWidth(SHOPW - 60)
    w.key:SetText("Green = you have enough. Counts include your bags and bank.")
    w:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    w:SetScale(self.db.scale or 1)
    -- keep counts fresh while it is open
    w:SetScript("OnShow", function() PP:RefreshGearShop() end)
end

function PP:ShowGearShop(items, isAll)
    if not items or #items == 0 then return end
    if not self.gearShop then self:BuildGearShop() end
    self.gearShop.items, self.gearShop.isAll = items, isAll
    self.gearShop.offset = 0
    if self.gearShop:IsShown() then self:RefreshGearShop() else self.gearShop:Show() end
end

function PP:ShowGearShopAll()
    local def = self:SelectedDef()
    local skill = def and self:GetSkill(def)
    if not skill then return end
    local items = self:GearShopAllItems(def, skill)
    if #items == 0 then
        if not self.gearShop then self:BuildGearShop() end
        self.gearShop.items, self.gearShop.isAll = {}, true
        self.gearShop:Show(); self:RefreshGearShop()
        return
    end
    self:ShowGearShop(items, true)
end

function PP:RefreshGearShop()
    local w = self.gearShop
    if not (w and w:IsShown()) then return end
    local items = w.items or {}
    for _, r in ipairs(w.rows) do r:Hide() end
    for _, k in ipairs({ "head", "forText", "status", "matHead", "planHead", "camp", "note", "craftBtn", "craftWhere" }) do w[k]:Hide() end
    local body = w.body
    local P = Placer(body, -10)
    local function fit()
        local content = -P.y + 38
        local screen = UIParent.GetHeight and UIParent:GetHeight() or 900
        if type(screen) ~= "number" or screen <= 0 then screen = 900 end
        local cap = math.max(240, screen / (self.db.scale or 1) - 90)
        local height = math.min(content + 54, cap)
        w:SetHeight(height)
        body:SetHeight(content)
        w.maxScroll = math.max(0, content - (height - 54))
        w.offset = math.min(w.offset or 0, w.maxScroll)
        w.scroll:SetVerticalScroll(w.offset)
    end
    local function slotName(it) return PP.SLOT_NAMES[it.slot] or "" end

    -- what this list is for
    if #items == 0 then
        w.title:SetText("Shopping List")
        w.head:SetText("Nothing to make right now. Your gear is as good as what you can craft.")
        P:Put(w.head, P:TextH(w.head, 18), 30, 8)
        w.key:ClearAllPoints(); w.key:SetPoint("TOPLEFT", body, "TOPLEFT", 30, P.y); w.key:Show()
        fit()
        return
    end
    if #items == 1 then
        local it = items[1]
        w.title:SetText("What You Need")
        w.head:SetText("To make  " .. it.name .. "  (" .. slotName(it) .. ")")
        w.head:SetTextColor(unpack(PP.QualityColor(it.q)))
        P:Put(w.head, P:TextH(w.head, 18), 30, 6)
    else
        w.title:SetText("Shopping List - All Picks")
        w.head:SetText(#items .. " recommended pieces")
        SetColor(w.head, C.white)
        P:Put(w.head, P:TextH(w.head, 18), 30, 4)
        local names = {}
        for _, it in ipairs(items) do names[#names + 1] = it.name .. " (" .. slotName(it) .. ")" end
        w.forText:SetText(table.concat(names, ",  "))
        P:Put(w.forText, P:TextH(w.forText, 16), 30, 6)
    end

    local mats, plans, nomats = self:GearShopping(items)
    local missing = 0
    for _, m in ipairs(mats) do if not m.sub and m.have < m.need then missing = missing + 1 end end
    if #mats > 0 then
        if missing == 0 and #plans == 0 and #nomats == 0 then
            w.status:SetText("Materials ready")
            SetColor(w.status, C.green)
        else
            w.status:SetText(#plans > 0 and "Recipe needed" or (#nomats > 0 and "Open profession to check materials" or ("Missing " .. missing .. " materials")))
            SetColor(w.status, C.orange)
        end
        P:Put(w.status, 20, 30, 10)
    end
    -- one piece and everything is ready: a big Craft button
    if #items == 1 and self:CanCraft(items[1]) then
        local def = self:SelectedDef()
        w.craftWhere:SetText((def and PP.CRAFT_WHERE[def.key]) or "Works anywhere.")
        local th = P:TextH(w.craftWhere, 16)
        P:Put(w.craftBtn, math.max(34, th), 30, 10)
        w.craftWhere:ClearAllPoints(); w.craftWhere:SetPoint("LEFT", w.craftBtn, "RIGHT", 14, 0); w.craftWhere:Show()
    end

    -- recipes / plans you don't have yet
    local ri = 0
    local needCamp = false
    if #plans > 0 then
        P:Put(w.planHead, 20, 24, 6)
        local have = self:FavorHave()
        for _, it in ipairs(plans) do
            ri = ri + 1
            local r = w.rows[ri]
            if not r then break end
            r.icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
            r.name:SetText("Recipe: " .. it.name)
            SetColor(r.name, C.white)
            if it.plan then
                needCamp = true
                local camp = self:FavorCamp()
                r.count:SetText(it.plan.cost .. " Favor")
                SetColor(r.count, have >= it.plan.cost and C.green or C.red)
                r.where:SetText((camp and camp.p or "Trade camp") .. " | Favor: " .. have .. "/" .. it.plan.cost)
            else
                r.count:SetText("")
                r.where:SetText("Vendor or drop recipe. Check Wowhead for the source.")
            end
            local h = math.max(40, 22 + P:TextH(r.where, 14))
            P:Put(r, h, 30, 8)
        end
        if needCamp then
            local camp = self:FavorCamp()
            if camp then w.camp:SetWho(camp); P:Put(w.camp, 42, 30, 8) end
        end
        P.y = P.y - 4
    end

    -- materials
    if #mats > 0 then
        P:Put(w.matHead, 20, 24, 6)
        for _, m in ipairs(mats) do
            ri = ri + 1
            local r = w.rows[ri]
            if not r then break end
            r.icon:SetTexture(self:Icon(m.id))
            if m.sub then
                r.name:SetText("For those, you need:  " .. m.name)
                SetColor(r.name, C.white)
            else
                r.name:SetText(m.name .. (m.rare and "  (rare)" or ""))
                SetColor(r.name, m.rare and C.orange or C.white)
            end
            r.count:SetText(m.have .. " / " .. m.need)
            SetColor(r.count, m.have >= m.need and C.green or C.red)
            r.where:SetText(m.where)
            if self.BindFarmRow then self:BindFarmRow(r,m.id) end
            local h = math.max(40, 22 + P:TextH(r.where, 14))
            P:Put(r, h, m.sub and 62 or 30, 8)
        end
    end

    -- pieces where we don't know the materials yet
    if #nomats > 0 then
        local names = {}
        for _, it in ipairs(nomats) do names[#names + 1] = it.name end
        local def = self:SelectedDef()
        w.note:SetText("I don't know the materials for " .. table.concat(names, ", ") .. " yet. Open your "
            .. (def and def.name or "profession") .. " window once and I'll remember them.")
        P:Put(w.note, P:TextH(w.note, 16), 30, 8)
    end

    w.key:ClearAllPoints(); w.key:SetPoint("TOPLEFT", body, "TOPLEFT", 30, P.y - 2); w.key:Show()
    fit()
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
    c.refresh=function(self) self:SetChecked(get() and true or false) end
    c:SetScript("OnShow",c.refresh)
    c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); PP:Refresh() end)
    return c
end

function PP:BuildSettings()
    local outer = Window("ProfessionPalSettings", 490, "ProfessionPal Settings")
    self.settings = outer
    outer:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    outer:SetHeight(math.min(620,(UIParent:GetHeight() or 760)-80))
    local scroll=CreateFrame("ScrollFrame",nil,outer,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",0,-48);scroll:SetPoint("BOTTOMRIGHT",-30,20)
    local s=CreateFrame("Frame",nil,scroll);s:SetWidth(460);scroll:SetScrollChild(s)
    local y = -10
    s.checks = {};outer.checks=s.checks
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
            function(v)
                PP.db[field] = v
                if field=="harvestGuide" or field=="harvestGuideDetails" or field=="harvestAlert" then
                    if PP.HarvestGuideUpdate then PP:HarvestGuideUpdate() end
                elseif field=="harvestMarkers" and PP.HarvestPinsUpdate then PP:HarvestPinsUpdate() end
            end)
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
    AddCheck("Gear: hide pieces that need plans or rare mats", "gearHideHard")

    local starter=Button(s,"Use starter setup",190,30,function() PP:StarterSetup() end)
    starter:SetPoint("TOPLEFT",24,y)
    local restore=Button(s,"Restore my setup",190,30,function() PP:StarterSetup(true) end)
    restore:SetPoint("LEFT",starter,"RIGHT",10,0);y=y-44

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
    AddCheck("Show harvest reminders (herbs, ore, skinning)", "harvestAlert")
    AddCheck("Show node direction and distance", "harvestGuide")
    AddCheck("Show detailed node text", "harvestGuideDetails")
    AddCheck("Auto-fly to my selected farming spot", "farmAutoFly")
    AddCheck("Saved node map markers", "harvestMarkers")
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
    function PP:RefreshSettings()
        for _,c in ipairs(s.checks) do c:refresh() end
        for _,set in ipairs(steppers) do set(0) end
    end
    outer:SetScript("OnShow",function() PP:RefreshSettings() end)
    if self.shop then self.shop:SetScale(self.db.scale or 1) end
end

function PP:ToggleSettings()
    if self.settings:IsShown() then self.settings:Hide() else self.settings:Show() end
end
