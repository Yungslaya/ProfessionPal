-- Tiny fake WoW for ProfessionPal tests
FRAMES, LOG, MISSING = {}, {}, {}
STATE = { faction = "Horde", level = 30, map = 1454, profs = {}, bags = {}, tomtom = false }

local noop = function() end
local Widget = {}
local WMT = { __index = function(t, k)
    local v = rawget(Widget, k); if v then return v end
    if type(k) == "string" and k:match("^%u") then return noop end
    return nil
end }

local function new(kind, parent)
    local o = setmetatable({ _kind = kind, _shown = true, _parent = parent, _scripts = {}, _points = {} }, WMT)
    FRAMES[#FRAMES + 1] = o
    return o
end
function Widget:SetText(t) self._text = t end
function Widget:GetText() return self._text end
function Widget:SetFont(f, s) self._font, self._size = f, s; return true end
function Widget:GetStringHeight() if self._text and self._text ~= "" then return self._size or 14 end return 0 end
function Widget:Show() self._shown = true; if self._scripts.OnShow then self._scripts.OnShow(self) end end
function Widget:Hide() self._shown = false end
function Widget:SetShown(v) if v then self:Show() else self:Hide() end end
function Widget:IsShown() return self._shown end
function Widget:IsVisible()
    local o = self
    while o do if not o._shown then return false end o = o._parent end
    return true
end
function Widget:SetScript(n, f) self._scripts[n] = f end
function Widget:GetScript(n) return self._scripts[n] end
function Widget:SetPoint(...) self._points[#self._points + 1] = { ... } end
function Widget:ClearAllPoints() self._points = {} end
function Widget:GetPoint() local p = self._points[1] or { "CENTER" }; return p[1], UIParent, p[3] or p[1], 0, 0 end
function Widget:SetChecked(v) self._checked = v end
function Widget:GetChecked() return self._checked end
function Widget:CreateFontString() local o = new("FontString", self); return o end
function Widget:CreateTexture() local o = new("Texture", self); return o end
function Widget:SetTexture(t) self._tex = t end
function Widget:GetTexture() return self._tex end
function Widget:GetFontString() if not self._fs then self._fs = new("FontString", self) end return self._fs end
function Widget:RegisterEvent(e)
    if e == "BOGUS" then error("unknown event") end
    self._events = self._events or {}; self._events[e] = true
end
function Widget:SetHeight(h) self._h = h end
function Widget:SetScale(s) self._scale = s end
function Widget:SetAlpha(a) self._alpha = a end

-- combat lockdown simulation: protected frames (and their parents) can't be changed in combat
BLOCKED = {}
for _, m in ipairs({ "Show", "Hide", "SetPoint", "ClearAllPoints", "SetHeight", "SetScale", "SetAttribute", "StartMoving", "SetSize" }) do
    local orig = Widget[m] or noop
    Widget[m] = function(self, ...)
        if STATE.combat and (rawget(self, "_protected") or rawget(self, "_hasProt")) then
            BLOCKED[#BLOCKED + 1] = m .. " on " .. tostring(rawget(self, "_name") or rawget(self, "_kind"))
            return
        end
        return orig(self, ...)
    end
end
function Widget:SetAttribute(k, v) self._attr = self._attr or {}; self._attr[k] = v end
do -- re-wrap SetAttribute after defining it
    local orig = Widget.SetAttribute
    Widget.SetAttribute = function(self, ...)
        if STATE.combat and rawget(self, "_protected") then BLOCKED[#BLOCKED + 1] = "SetAttribute"; return end
        return orig(self, ...)
    end
end

UIParent = new("Frame")
function CreateFrame(kind, name, parent, template)
    local o = new(kind, parent)
    o._name = name; o._template = template
    if template and template:find("Secure") then
        o._protected = true
        local p = parent
        while p and p ~= UIParent do p._hasProt = true; p = p._parent end
    end
    if name then _G[name] = o end
    return o
end
STATE.spells = {}
function IsPlayerSpell(id) return STATE.spells[id] or false end
C_Spell = {
    GetSpellInfo = function(n) if STATE.spells[n] then return { name = n } end end,
    GetSpellTexture = function(n) return 136025 end,
}
UISpecialFrames = {}
SlashCmdList = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) LOG[#LOG + 1] = m end }

function InCombatLockdown() return STATE.combat end
-- trainer window mock
STATE.trainer = {}; STATE.money = 50000; BOUGHT = {}
function GetNumTrainerServices() return #STATE.trainer end
function GetTrainerServiceInfo(i) local s = STATE.trainer[i]; return s.name, s.sub, s.typ end
function GetTrainerServiceCost(i) return STATE.trainer[i].cost end
function BuyTrainerService(i) local s = STATE.trainer[i]; STATE.money = STATE.money - s.cost; s.typ = "used"; BOUGHT[#BOUGHT + 1] = s.name .. (s.sub ~= "" and ("/" .. s.sub) or "") end
function GetMoney() return STATE.money end
function SetTrainerServiceTypeFilter() end
STATE.class = "WARRIOR"; STATE.equip = {}
function UnitClass() return "x", STATE.class end
function GetInventoryItemLink(_, slot) return STATE.equip[slot] and ("link" .. slot) or nil end
function GetItemStats(link) local s = tonumber(link:match("%d+")); return STATE.equip[s] end
GameTooltip = CreateFrame("GameTooltip", "GameTooltip")
function UnitFactionGroup() return STATE.faction end
function UnitLevel() return STATE.level end
function issecretvalue(v) return type(v) == "table" and v.secret == true end

-- retail profession API
function GetProfessions()
    local idx = {}
    for i, p in ipairs(STATE.profs) do idx[i] = i end
    return unpack(idx, 1, 8)
end
function GetProfessionInfo(i)
    local p = STATE.profs[i]
    if not p then error("bad index") end
    return p.name, 1, p.rank, p.max, 0, 0, p.line
end

C_Item = {
    GetItemCount = function(item, bank) return STATE.bags[item] or 0 end,
    GetItemIconByID = function(id) return 134400 end,
    RequestLoadItemDataByID = noop,
}
C_Map = {
    GetBestMapForUnit = function() return STATE.map end,
    SetUserWaypoint = function(pt) STATE.pin = pt end,
    CanSetUserWaypointOnMap = function() return true end,
}
UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { m = m, x = x, y = y } end }
C_SuperTrack = { SetSuperTrackedUserWaypoint = noop }
C_Timer = { After = function(_, f) f() end }
C_TradeSkillUI = {}

function FIRE(e, ...)
    for _, f in ipairs(FRAMES) do
        if f._events and f._events[e] and f._scripts.OnEvent then f._scripts.OnEvent(f, e, ...) end
    end
end

-- visible text of a frame tree, in creation order
function VISIBLE(root)
    local out = {}
    for _, f in ipairs(FRAMES) do
        if (f._kind == "FontString") and f._text and f._text ~= "" and f:IsVisible() then
            local o, inside = f, false
            while o do if o == root then inside = true break end o = o._parent end
            if inside then out[#out + 1] = f._text end
        end
    end
    return table.concat(out, " | ")
end

function CLICKALL(root)
    local n = 0
    for _, f in ipairs(FRAMES) do
        local o, inside = f, false
        while o do if o == root then inside = true break end o = o._parent end
        if inside and f._scripts.OnClick and f:IsVisible() then
            if f._template == "UICheckButtonTemplate" then f._checked = not f._checked end
            f._scripts.OnClick(f); n = n + 1
        end
    end
    return n
end

-- fake world map for distance tests: map -> continent, center x, y (yards)
WORLD = {
  [1429] = {0, 0, 0}, [1453] = {0, -300, 200}, [1426] = {0, 0, 2500}, [1455] = {0, 100, 2600},
  [1432] = {0, 800, 3200}, [1431] = {0, 600, -900}, [1436] = {0, -900, -400}, [1437] = {0, 300, 4500},
  [1438] = {1, 0, 0}, [1457] = {1, -100, 80}, [1439] = {1, 200, -2000}, [1440] = {1, 600, -4000},
  [1411] = {1, 5000, -6000}, [1412] = {1, 2000, -9000}, [1446] = {1, 4000, -14000}, [1442] = {1, 1000, -5500},
  [2521] = {2, 0, 0}, [2548] = {3, 0, 0}, [1420] = {0, -2000, 7000}, [1454] = {1, 5200, -5600},
}
STATE.pos = nil; STATE.zone = nil; STATE.race = "Human"
function GetZoneText() return STATE.zone or "" end
function UnitRace() return "x", STATE.race end
function CreateVector2D(x, y) return { x = x, y = y } end
C_Map.GetPlayerMapPosition = function(map, unit) if STATE.pos then return { x = STATE.pos[1], y = STATE.pos[2] } end end
C_Map.GetWorldPosFromMapPos = function(map, v)
  local w = WORLD[map]; if not w then return nil end
  return w[1], { x = w[2] + (v.x - 0.5) * 1000, y = w[3] + (v.y - 0.5) * 1000 }
end

-- Harvest reminders use the game clock but never interact with the world.
HARVEST_TIME=1000
function GetTime() return HARVEST_TIME end
