-- ProfessionPal: a slim "what you're farming" counter under the Gathering HUD.
-- One row per item (at most three): icon, name, how many are in your bags, how many full stacks,
-- and how many you picked up since you opened the HUD. It reads your bags only.
local _, PP = ...

local MAX_ROWS = 3
local ROW_H = 28
local panel, rows
local start = {}        -- item ID -> bag count when the HUD opened, for "+N this run"
local stackSize = {}

local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(fn, ...)
    if ok then return a, b, c, d, e, f, g, h end
end

local function itemFor(nodeName)
    for _, it in ipairs(PP.FARMABLE or {}) do
        if it.node == nodeName or it.name == nodeName then return it end
    end
end

-- What you are farming right now: the veins/herbs on your running farm route first,
-- otherwise the ones your current guide step says to gather.
function PP:FarmingItems()
    local list, seen = {}, {}
    local function add(id, name)
        if type(id) == "number" and not seen[id] and #list < MAX_ROWS then
            seen[id] = true
            list[#list + 1] = { id = id, name = name }
        end
    end
    -- The native dot the player just inspected takes priority over a guide's guesses.
    local hovered = self.harvestHoveredNode
    local map = C_Map and read(C_Map.GetBestMapForUnit, "player")
    if hovered and hovered.map == map and hovered.expires and hovered.expires > GetTime() then
        local it = itemFor(hovered.name)
        if it then add(it.id, it.name) end
    end
    local target = self.db and self.db.guideTarget
    if type(target) == "table" and type(target.groups) == "table" then
        for _, node in ipairs(target.groups) do
            local it = itemFor(node)
            if it then add(it.id, it.name) end
        end
    end
    if #list == 0 and self.SelectedDef and self.StepFor then
        local def = self:SelectedDef()
        if def then
            local skill = self:GetSkill(def)
            local st = self:StepFor(def, skill or 1)
            for _, node in ipairs(st and st.nodes or {}) do
                local id = node[3]
                local it = itemFor(node[1])
                add(id or (it and it.id), it and it.name)
            end
        end
    end
    for _, item in ipairs(list) do
        item.name = item.name or read(C_Item and C_Item.GetItemNameByID, item.id) or read(GetItemInfo, item.id)
    end
    return list
end

local function stackOf(id)
    if stackSize[id] then return stackSize[id] end
    local size = read(C_Item and C_Item.GetItemMaxStackCount, id)
    if type(size) ~= "number" then size = select(8, read(GetItemInfo, id)) end
    if type(size) == "number" and size > 1 then stackSize[id] = size end
    return stackSize[id]
end

-- "2 stacks + 6", "1 stack", "6" -- plain words, no symbols
function PP.StackText(count, size)
    if not size or count < size then return nil end
    local full, rest = math.floor(count / size), count % size
    local words = full .. (full == 1 and " stack" or " stacks")
    return rest > 0 and (words .. " + " .. rest) or words
end

local function build()
    panel = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    panel:SetFrameStrata("MEDIUM")
    panel:SetSize(250, ROW_H + 12)
    if panel.SetBackdrop then
        panel:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        panel:SetBackdropColor(0.055, 0.06, 0.065, 0.97)
        panel:SetBackdropBorderColor(0.25, 0.25, 0.23, 1)
    end
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:StartMoving()
    end)
    local function stopMoving(self)
        if not self.dragging then return end
        self:StopMovingOrSizing()
        self.dragging = nil
        local point, _, relativePoint, x, y = self:GetPoint()
        if point and type(x) == "number" and type(y) == "number" then
            PP.db.gatherCountPoint = { point, relativePoint, x, y }
        end
    end
    panel:SetScript("OnDragStop", stopMoving)
    panel:SetScript("OnHide", stopMoving)
    PP.gatherCountPanel = panel
    rows = {}
    for i = 1, MAX_ROWS do
        local r = CreateFrame("Frame", nil, panel)
        r:SetSize(230, ROW_H)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(22, 22)
        r.icon:SetPoint("TOPLEFT", r, "TOPLEFT", 0, -3)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.name = PP.UIText(r, 13, PP.C.white)
        r.name:SetPoint("TOPLEFT", r, "TOPLEFT", 30, -7)
        r.name:SetWidth(150)
        r.name:SetWordWrap(false)
        r.count = PP.UIText(r, 14, PP.C.gold, "RIGHT")
        r.count:SetPoint("TOPRIGHT", r, "TOPRIGHT", 0, -6)
        r.count:SetWidth(44)
        r.count:SetWordWrap(false)
        r.extra = PP.UIText(r, 12, PP.C.gray, "RIGHT")
        r.extra:SetPoint("TOPLEFT", r, "TOPLEFT", 30, -25)
        r.extra:SetWidth(200)
        r.extra:SetJustifyH("LEFT")
        r.extra:SetWordWrap(false)
        rows[i] = r
    end
end

function PP:GatherCountRefresh()
    local show = self.db and self.db.hudCounter ~= false and self.GatherHUDOn and self:GatherHUDOn()
        and not self:GatherHUDFaded()
    local items = show and self:FarmingItems() or {}
    if #items == 0 then
        if panel then panel:Hide() end
        return
    end
    if not panel then build() end
    if not panel.dragging then
        panel:ClearAllPoints()
        local p = self.db.gatherCountPoint
        if type(p) == "table" and type(p[1]) == "string" and type(p[2]) == "string"
            and type(p[3]) == "number" and type(p[4]) == "number" then
            panel:SetPoint(p[1], UIParent, p[2], p[3], p[4])
        else
            panel:SetPoint("TOP", Minimap, "BOTTOM", 0, -10)
        end
    end
    local height = 6
    for i, r in ipairs(rows) do
        local item = items[i]
        if item then
            local count = self:Count(item.id, true) or 0
            if start[item.id] == nil then start[item.id] = count end
            local gained = count - start[item.id]
            r.icon:SetTexture(self:Icon(item.id))
            r.name:SetText(item.name or "")
            r.count:SetText(tostring(count))
            local stacks = PP.StackText(count, stackOf(item.id))
            local parts = {}
            if stacks then parts[#parts + 1] = stacks end
            if gained > 0 then parts[#parts + 1] = "|cff73de99+" .. gained .. "|r" end
            r.extra:SetText(table.concat(parts, "   "))
            local rowHeight = #parts > 0 and 44 or ROW_H
            r.extra:SetShown(#parts > 0)
            r:SetHeight(rowHeight)
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -height)
            height = height + rowHeight
            r:Show()
        else
            r:Hide()
        end
    end
    panel:SetHeight(height + 6)
    panel:Show()
end

-- a new HUD session starts a new "+N" count
function PP:GatherCountReset() for k in pairs(start) do start[k] = nil end end

local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function() if PP.db then PP:GatherCountRefresh() end end)
local clock = 0
events:SetScript("OnUpdate", function(_, dt)
    clock = clock + dt
    if clock < 1 then return end      -- notices a new farm route or guide step within a second
    clock = 0
    if PP.db and ((panel and panel:IsShown()) or (PP.GatherHUDOn and PP:GatherHUDOn())) then PP:GatherCountRefresh() end
end)
