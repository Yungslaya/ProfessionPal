--[[ ProfessionPal - On-screen tracker
  A small box that stays on screen (like a leveling guide step box).
  Escape does NOT close it. Click it to open the full guide. Drag to move.
  Background opacity, size, lock and "hide in combat" are in Settings.

  Spell buttons (Find Minerals, Smelting, Blacksmithing...):
  Blizzard's SecureActionButtonTemplate. YOU click, the game casts ONE spell,
  exactly like an action bar button. Nothing is cast by itself.

  Combat rule: the tracker holds secure buttons, so in combat we never
  Show/Hide/move/resize it (WoW would block that). "Hide in combat" just
  fades it to invisible, and the layout waits until combat ends.
]]

local _, PP = ...
local C = PP.C
local TW = 300   -- tracker width
local BTN = 36   -- spell button size

local function SpellButton(t)
    local b = CreateFrame("Button", nil, t, "SecureActionButtonTemplate")
    b:SetSize(BTN, BTN)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "spell")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints(b)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", function(self)
        if GameTooltip and self.sp then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.sp.name)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b:Hide()
    return b
end

function PP:BuildTracker()
    if self.tracker then return end
    local Text, Icon = PP.UIText, PP.UIIcon

    local t = CreateFrame("Button", "ProfessionPalTracker", UIParent, "BackdropTemplate")
    self.tracker = t
    t:SetSize(TW, 80)
    t:SetFrameStrata("LOW")
    t:SetClampedToScreen(true)
    t:SetMovable(true)
    t:EnableMouse(true)
    t:RegisterForDrag("LeftButton")
    if t.RegisterForClicks then t:RegisterForClicks("LeftButtonUp") end
    if t.SetBackdrop then
        t:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 14,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
    end

    local pt = self.db.trackerPoint
    if type(pt) == "table" and pt[1] then
        t:SetPoint(pt[1], UIParent, pt[2] or pt[1], pt[3] or 0, pt[4] or 0)
    else
        t:SetPoint("RIGHT", UIParent, "RIGHT", -40, 120)
    end

    t:SetScript("OnDragStart", function(self)
        if not PP.db.trackerLocked and not PP:InCombat() then
            self.dragged = true
            self:StartMoving()
        end
    end)
    t:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint()
        PP.db.trackerPoint = { p, rp, x, y }
    end)
    t:SetScript("OnClick", function(self)
        if self.dragged then self.dragged = false return end
        PP:Toggle()
    end)
    t:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Click: open guide")
            if not PP.db.trackerLocked then GameTooltip:AddLine("Drag: move", 1, 1, 1) end
            GameTooltip:Show()
        end
    end)
    t:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    t.icon = Icon(t, 28)
    t.head = Text(t, 15, C.gold); t.head:SetWidth(TW - 60)
    t.step = Text(t, 16, C.white); t.step:SetWidth(TW - 24)
    t.sub = Text(t, 13, C.gray); t.sub:SetWidth(TW - 24)
    t.rows = {}
    for i = 1, 5 do
        local r = CreateFrame("Frame", nil, t)
        r:SetSize(TW - 24, 22)
        r.icon = Icon(r, 20); r.icon:SetPoint("LEFT", r, "LEFT", 0, 0)
        r.name = Text(r, 14, C.white); r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0); r.name:SetWidth(TW - 120)
        r.count = Text(r, 14, C.white, "RIGHT"); r.count:SetPoint("RIGHT", r, "RIGHT", 0, 0); r.count:SetWidth(80)
        r:Hide()
        t.rows[i] = r
    end
    t.zone = Text(t, 14, C.white); t.zone:SetWidth(TW - 24)
    t.train = Text(t, 15, C.orange); t.train:SetWidth(TW - 24)
    t.gearLine = Text(t, 14, C.green); t.gearLine:SetWidth(TW - 24)
    t.btns = {}   -- secure spell buttons, made out of combat only

    -- combat: fade only, re-layout after combat
    PP.inCombat = PP:InCombat()
    local ev = CreateFrame("Frame")
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_DISABLED")
    pcall(ev.RegisterEvent, ev, "PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function(_, e)
        PP.inCombat = (e == "PLAYER_REGEN_DISABLED")
        PP:ApplyTrackerAlpha()
        if not PP.inCombat then PP:RefreshTracker() end
    end)

    self:ApplyTrackerLook()
end

-- Whole box invisible while "hide in combat" is on and you are fighting
function PP:ApplyTrackerAlpha()
    local t = self.tracker
    if not t then return end
    if self.db.trackerHideCombat and self.inCombat then t:SetAlpha(0) else t:SetAlpha(1) end
end

function PP:ApplyTrackerLook()
    local t = self.tracker
    if not t then return end
    local a = self.db.trackerAlpha or 0.6
    if t.SetBackdropColor then
        t:SetBackdropColor(0, 0, 0, a)
        t:SetBackdropBorderColor(0.6, 0.6, 0.6, a)
    end
    self:ApplyTrackerAlpha()
    if not self:InCombat() then t:SetScale(self.db.trackerScale or 1) end
end

local function Put(t, w, h, y, x)
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", t, "TOPLEFT", x or 12, y)
    w:Show()
    return y - h
end

local function H(fs, min)
    local h = fs.GetStringHeight and fs:GetStringHeight() or 0
    if type(h) ~= "number" or h < min then h = min end
    return h
end

function PP:RefreshTracker()
    local t = self.tracker
    if not t then return end
    self:ApplyTrackerAlpha()
    -- In combat the box may not be moved, resized, shown or hidden. Wait.
    if self:InCombat() then return end

    local def = self.db and self:SelectedDef()
    if not (self.db.tracker and def) then
        t:Hide()
        return
    end
    t:Show()
    for _, k in ipairs({ "step", "sub", "zone", "train", "gearLine" }) do t[k]:Hide() end
    for _, r in ipairs(t.rows) do r:Hide() end
    for _, b in ipairs(t.btns) do b:Hide() end

    local skill, max = self:GetSkill(def)
    t.icon:SetTexture(def.icon)
    t.icon:ClearAllPoints(); t.icon:SetPoint("TOPLEFT", t, "TOPLEFT", 10, -8)
    t.head:SetText(def.name .. "   " .. (skill and (skill .. " / " .. (max or "?")) or "not learned"))
    t.head:ClearAllPoints(); t.head:SetPoint("LEFT", t.icon, "RIGHT", 8, 0); t.head:Show()
    local y = -42

    if skill and skill >= 300 then
        t.step:SetText("Done!")
        t.step:SetTextColor(unpack(C.green))
        y = Put(t, t.step, 20, y)
    else
        local st = self:StepFor(def, skill or 1)
        if st then
            local n = self:CraftsNow(st, skill or 1)
            if st.nodes then
                t.step:SetText(st.text)
            elseif st.smelt then
                t.step:SetText(st.text .. "  x " .. n)
            else
                t.step:SetText((n > 0) and ("Make " .. n .. " x " .. st.text) or ("Make: " .. st.text))
            end
            t.step:SetTextColor(unpack(C.white))
            y = Put(t, t.step, H(t.step, 18) + 2, y)
            t.sub:SetText("until " .. st.to .. (st.smelt and "  -  forge" or "") .. (st.anvil and "  -  anvil" or ""))
            y = Put(t, t.sub, H(t.sub, 15) + 4, y)

            if st.mats then
                for i, m in ipairs(st.mats) do
                    local r = t.rows[i]
                    if not r then break end
                    local need, have = PP.MatNeed(st, m, n), self:Count(m[1])
                    r.icon:SetTexture(self:Icon(m[1]))
                    r.name:SetText(m[3] or tostring(m[1]))
                    r.count:SetText(have .. "/" .. need)
                    r.count:SetTextColor(unpack(have >= need and C.green or C.red))
                    y = Put(t, r, 23, y)
                end
            end
            local z = (st.zones or st.zoneList) and self:ZoneOptions(def, st)[1]
            if z then
                t.zone:SetText(z.name .. (z.here and "  (here)" or (z.level and ("  (lvl " .. z.level .. ")") or "")))
                y = Put(t, t.zone, H(t.zone, 16) + 2, y)
            end
        end
    end

    -- training alert
    local _, nxt = self:RankInfo(def, skill, max)
    local msg
    if not skill then
        msg = "Learn " .. def.name .. " at a trainer"
    elseif nxt and skill >= nxt.skill then
        if self:PlayerLevel() >= (nxt.level or 0) then
            msg = "TRAIN NOW: " .. nxt.name
        else
            msg = nxt.name .. " at level " .. nxt.level
        end
    end
    if not msg and skill then
        local rec = self:RecipeToLearn(def, self:StepFor(def, skill), skill)
        if rec then msg = (rec.src == "vendor" and "BUY RECIPE: " or "LEARN: ") .. rec.name end
    end
    if msg then
        t.train:SetText(msg)
        y = Put(t, t.train, H(t.train, 17) + 2, y - 2)
    end

    -- best gear piece you can make right now
    if skill and self.GearPicks and self:GearListFor(def) then
        local now = self:GearPicks(def, skill)
        local p = now[1]
        if p then
            t.gearLine:SetText("Gear: " .. p.it.name .. " (" .. (PP.SLOT_NAMES[p.it.slot] or "") .. ")")
            t.gearLine:SetTextColor(unpack(PP.QualityColor(p.it.q)))
            y = Put(t, t.gearLine, H(t.gearLine, 16) + 2, y - 2)
        end
    end

    -- spell buttons: all profession spells you know (one click = one cast)
    if self.db.trackerButtons then
        local spells = self:ActionSpells()
        if #spells > 0 then
            y = y - 6
            local PER_ROW = 7
            local shown = math.min(#spells, PER_ROW * 2)
            for i = 1, shown do
                local sp = spells[i]
                local b = t.btns[i] or SpellButton(t)
                t.btns[i] = b
                b.sp = sp
                b:SetAttribute("spell", sp.name)
                b.icon:SetTexture(self:SpellIcon(sp))
                local col, row = (i - 1) % PER_ROW, math.floor((i - 1) / PER_ROW)
                b:ClearAllPoints()
                b:SetPoint("TOPLEFT", t, "TOPLEFT", 12 + col * (BTN + 4), y - row * (BTN + 4))
                b:Show()
            end
            local rows = math.floor((shown - 1) / PER_ROW) + 1
            y = y - rows * (BTN + 4) + 2
        end
    end
    t:SetHeight(-y + 8)
end
