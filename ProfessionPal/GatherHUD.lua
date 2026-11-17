-- ProfessionPal: Gathering HUD.
-- One key moves your own minimap to the middle of the screen, big and see-through, so ore and herb
-- dots sit around your character instead of in the corner. Press it again and the minimap goes back.
-- Display only: it moves and resizes the game's minimap and nothing else. Clicks pass straight through.
local _, PP = ...

local saved          -- how the minimap looked before, so it can be put back exactly
local hiddenParts    -- minimap decorations we hid while the HUD is up
local combatHidden = false
local hideTip        -- defined with the cursor names below

local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d, e = pcall(fn, ...)
    if ok then return a, b, c, d, e end
end
local function call(obj, method, ...)
    local fn = obj and obj[method]
    if type(fn) == "function" then return pcall(fn, obj, ...) end
end
local function getCVar(name) return read((C_CVar and C_CVar.GetCVar) or GetCVar, name) end
local function setCVar(name, value)
    local fn = (C_CVar and C_CVar.SetCVar) or SetCVar
    if type(fn) == "function" then pcall(fn, name, value) end
end

-- Corner decorations that would otherwise float around the big map: zoom buttons, compass ring, border.
local PARTS = { "MinimapCompassTexture", "MinimapBorder", "MinimapBorderTop", "MinimapZoomIn", "MinimapZoomOut",
    "MinimapNorthTag", "MinimapBackdrop", "MiniMapTracking", "MiniMapWorldMapButton" }

local function hideParts()
    hiddenParts = {}
    local list = {}
    for _, name in ipairs(PARTS) do list[#list + 1] = _G[name] end
    if Minimap then list[#list + 1] = Minimap.ZoomIn; list[#list + 1] = Minimap.ZoomOut; list[#list + 1] = Minimap.ZoomHitArea end
    list[#list + 1] = MinimapCluster
    for _, part in ipairs(list) do
        if type(part) == "table" and read(part.IsShown, part) then
            hiddenParts[#hiddenParts + 1] = part
            call(part, "Hide")
        end
    end
end

local function showParts()
    for _, part in ipairs(hiddenParts or {}) do call(part, "Show") end
    hiddenParts = nil
end

function PP:GatherHUDOn() return saved ~= nil end
function PP:GatherHUDFaded() return combatHidden end
local function counter(reset)
    if reset and PP.GatherCountReset then PP:GatherCountReset() end
    if PP.GatherCountRefresh then PP:GatherCountRefresh() end
end

-- Reading node names: the map normally lets every click through to the world. While you hold the
-- hover key (Alt by default), the map takes the mouse so hovering a dot shows what it is: the game
-- names its own ore/herb dots, and ProfessionPal names its spot marks. Let go and clicks pass through.
local KEYS = { ALT = IsAltKeyDown, CTRL = IsControlKeyDown, SHIFT = IsShiftKeyDown }
PP.HUD_HOVER_KEYS = { "ALT", "CTRL", "SHIFT", "ALWAYS" }
local function setHover(on)
    on = on and true or false

    PP.hudHover = on
    -- Receive native blip hover events without swallowing world clicks.
    if Minimap and Minimap.SetMouseMotionEnabled and Minimap.SetMouseClickEnabled then
        call(Minimap, "SetMouseMotionEnabled", saved ~= nil and not combatHidden)
        call(Minimap, "SetMouseClickEnabled", on)
    else
        call(Minimap, "EnableMouse", on) -- older clients: hold the hover key
    end
    for _, f in ipairs(PP.harvestMiniPins or {}) do call(f, "EnableMouse", false) end
    if not on and GameTooltip and read(GameTooltip.IsShown, GameTooltip) then call(GameTooltip, "Hide") end
end
function PP:GatherHUDHoverCheck()
    if not saved or combatHidden then setHover(false) return end
    local key = self.db.hudHoverKey or "ALT"
    if key == "ALWAYS" then setHover(true) return end
    setHover(read(KEYS[key] or IsAltKeyDown) == true)
end

-- Size and see-through can change while it is up.
function PP:ApplyGatherHUD()
    if not saved or not Minimap then return end
    local screen = read(UIParent.GetHeight, UIParent) or 768
    local size = math.floor(screen * (self.db.hudSize or 0.6) + 0.5)
    call(Minimap, "SetSize", size, size)
    call(Minimap, "ClearAllPoints")
    call(Minimap, "SetPoint", "CENTER", UIParent, "CENTER", 0, self.db.hudOffset or 0)
    call(Minimap, "SetAlpha", combatHidden and 0 or (self.db.hudAlpha or 0.5))
end

function PP:SetGatherHUD(on)
    if not Minimap then return false end
    if on == (saved ~= nil) then return true end
    if self:InCombat() then self:Print("The gathering HUD can be turned on or off after combat.") return false end
    if on then
        local points = {}
        for i = 1, (read(Minimap.GetNumPoints, Minimap) or 0) do points[i] = { read(Minimap.GetPoint, Minimap, i) } end
        saved = {
            parent = read(Minimap.GetParent, Minimap), points = points,
            w = read(Minimap.GetWidth, Minimap), h = read(Minimap.GetHeight, Minimap),
            alpha = read(Minimap.GetAlpha, Minimap) or 1, scale = read(Minimap.GetScale, Minimap) or 1,
            strata = read(Minimap.GetFrameStrata, Minimap), level = read(Minimap.GetFrameLevel, Minimap),
            motion = read(Minimap.IsMouseMotionEnabled, Minimap),
            clicks = read(Minimap.IsMouseClickEnabled, Minimap),
            mouse = read(Minimap.IsMouseEnabled, Minimap), wheel = read(Minimap.IsMouseWheelEnabled, Minimap),
            rotate = getCVar("rotateMinimap"),
        }
        hideParts()
        call(Minimap, "SetParent", UIParent)
        call(Minimap, "SetScale", 1)
        call(Minimap, "SetFrameStrata", "BACKGROUND")
        call(Minimap, "EnableMouse", false)          -- clicks go to the world, not the map
        call(Minimap, "EnableMouseWheel", false)
        if self.db.hudRotate ~= false then setCVar("rotateMinimap", "1") end   -- up = the way you face
        combatHidden = false
        self.hudHover = false
        self:ApplyGatherHUD()
        self:GatherHUDHoverCheck()
        counter(true)
        if self.HarvestPinsUpdate then self:HarvestPinsUpdate() end
    else
        setHover(false)
        hideTip()
        self.hudHover = nil
        local s = saved
        saved = nil
        call(Minimap, "SetParent", s.parent or MinimapCluster or UIParent)
        call(Minimap, "ClearAllPoints")
        for _, p in ipairs(s.points) do if p[1] then call(Minimap, "SetPoint", unpack(p)) end end
        if s.w and s.h then call(Minimap, "SetSize", s.w, s.h) end
        call(Minimap, "SetScale", s.scale)
        call(Minimap, "SetAlpha", s.alpha)
        if s.strata then call(Minimap, "SetFrameStrata", s.strata) end
        if s.level then call(Minimap, "SetFrameLevel", s.level) end
        if s.mouse ~= nil then call(Minimap, "EnableMouse", s.mouse) end
        if s.motion ~= nil then call(Minimap, "SetMouseMotionEnabled", s.motion) end
        if s.clicks ~= nil then call(Minimap, "SetMouseClickEnabled", s.clicks) end
        if s.wheel ~= nil then call(Minimap, "EnableMouseWheel", s.wheel) end
        if s.rotate and getCVar("rotateMinimap") ~= s.rotate then setCVar("rotateMinimap", s.rotate) end
        showParts()
        combatHidden = false
        counter()
        if self.HarvestPinsUpdate then self:HarvestPinsUpdate() end
    end
    return true
end

function PP:ToggleGatherHUD()
    local want = saved == nil
    if self:SetGatherHUD(want) and not self.db.hudTold then
        self.db.hudTold = true
        self:Print("Gathering HUD: press the key again (or /prof hud) to put the minimap back. Size and see-through are in Settings.")
    end
end

-- The key binding (Key Bindings > AddOns > ProfessionPal) calls this.
BINDING_HEADER_PROFESSIONPAL = "ProfessionPal"
BINDING_NAME_PROFESSIONPAL_HUD = "Gathering HUD (minimap over your character)"
function ProfessionPal_ToggleGatherHUD() if PP.db then PP:ToggleGatherHUD() end end

function PP:GatherHUDCommand(arg)
    arg = arg or ""
    local num = tonumber(arg:match("^size%s+(%d+)"))
    local see = tonumber(arg:match("^alpha%s+(%d+)"))
    if arg == "" then self:ToggleGatherHUD()
    elseif arg == "on" then self:SetGatherHUD(true)
    elseif arg == "off" then self:SetGatherHUD(false)
    elseif num then self.db.hudSize = math.max(30, math.min(100, num)) / 100; self:ApplyGatherHUD()
    elseif see then self.db.hudAlpha = math.max(10, math.min(100, see)) / 100; self:ApplyGatherHUD()
    else self:Print("/prof hud  turns the gathering HUD on or off.  /prof hud size 60  /prof hud alpha 50") end
end

-- Names without a key: the game reports which minimap dot is under the pointer even while the map
-- lets clicks through, so point at a dot and its name shows by the cursor. Nothing takes the mouse.
local tipShown = false
hideTip = function()
    if tipShown and GameTooltip then
        if read(GameTooltip.GetOwner, GameTooltip) == UIParent then call(GameTooltip, "Hide") end
    end
    tipShown = false
end
local function dotNames()
    local data = C_TooltipInfo and read(C_TooltipInfo.GetMinimapMouseover)
    if type(data) ~= "table" or type(data.lines) ~= "table" then return nil end
    local names = {}
    for _, line in ipairs(data.lines) do
        local t = type(line) == "table" and line.leftText
        if type(t) == "string" and not (issecretvalue and issecretvalue(t)) then
            for part in t:gmatch("[^\n]+") do
                part = part:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("^%s+", ""):gsub("%s+$", "")
                if part ~= "" then names[#names + 1] = part end
            end
        end
    end
    return #names > 0 and names or nil
end
function PP:GatherHUDTooltipTick()
    -- the map itself shows the game's tooltip while it has the mouse (hover key held)
    if not saved or combatHidden or not Minimap or read(Minimap.IsMouseOver, Minimap) ~= true then
        hideTip() return
    end
    local data = C_TooltipInfo and read(C_TooltipInfo.GetMinimapMouseover)
    if data and self.HarvestMinimapHint then self:HarvestMinimapHint(data) end
    if self.hudHover then hideTip() return end
    local names = dotNames()
    if not names or not GameTooltip then hideTip() return end
    call(GameTooltip, "SetOwner", UIParent, "ANCHOR_CURSOR")
    call(GameTooltip, "ClearLines")
    for i, name in ipairs(names) do
        if i == 1 then call(GameTooltip, "AddLine", name, 1, 0.82, 0) else call(GameTooltip, "AddLine", name, 1, 1, 1) end
    end
    call(GameTooltip, "Show")
    tipShown = true
end
local tipClock = 0
local tipDriver = CreateFrame("Frame")
tipDriver:SetScript("OnUpdate", function(_, dt)
    if not saved then if tipShown then hideTip() end return end
    tipClock = tipClock + dt
    if tipClock < 0.1 then return end
    tipClock = 0
    PP:GatherHUDTooltipTick()
end)

-- Hide it during fights if you like, and always give the minimap back before logging out.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("MODIFIER_STATE_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if not saved or not PP.db then return end
    if event == "MODIFIER_STATE_CHANGED" then
        PP:GatherHUDHoverCheck()
    elseif event == "PLAYER_LOGOUT" then
        PP:SetGatherHUD(false)
    elseif event == "PLAYER_REGEN_DISABLED" and PP.db.hudHideCombat then
        combatHidden = true
        call(Minimap, "SetAlpha", 0)
        PP:GatherHUDHoverCheck()
        counter()
    elseif event == "PLAYER_REGEN_ENABLED" and combatHidden then
        combatHidden = false
        call(Minimap, "SetAlpha", PP.db.hudAlpha or 0.5)
        PP:GatherHUDHoverCheck()
        counter()
    end
end)
