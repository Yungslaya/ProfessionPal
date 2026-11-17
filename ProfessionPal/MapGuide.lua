--[[ ProfessionPal - map guide
  "Map" buttons in the guide lead here. It opens the world map on the zone, draws where the
  veins or herbs are (dots, a soft area around each, and a loop to follow), and marks where to start.

  The way there:
    - With Shortest Path Forever installed (optional, by cjber, https://github.com/cjber/shortest-path-forever),
      ProfessionPal asks it for a journey through its public API. It draws the road route, boats and flights.
    - Without it, ProfessionPal sets the game's own map pin on the start spot.

  Display only. Nothing here moves the character.
]]

local _, PP = ...

local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"   -- a plain white disc
local OWNER = "ProfessionPal"
local COLORS = { { 1, 0.82, 0 }, { 0.45, 0.9, 1 }, { 1, 0.55, 0.9 }, { 0.6, 1, 0.5 } }

-- ---------- node data ----------

local decoded = {}
-- Known spots for a vein or herb in one zone: { { x, y }, ... } in map percent, in loop order. nil = no data.
function PP:NodePoints(name, map)
    local zones = PP.NODES and PP.NODES[name]
    local packed = zones and zones[map]
    if not packed then return nil end
    local key = name .. ":" .. map
    if not decoded[key] then
        local points = {}
        for x, y in packed:match(":(%d*)$"):gmatch("(%d%d)(%d%d)") do
            points[#points + 1] = { tonumber(x), tonumber(y) }
        end
        decoded[key] = points
    end
    return decoded[key]
end

-- Spots at the very edge of a zone map are usually under the sea or up a cliff (Arathi's Drowned Reef).
-- They are never used as the place to start, and the route skips them.
function PP.Inland(point)
    return point[1] >= 12 and point[1] <= 90 and point[2] >= 10 and point[2] <= 86
end

local function apart(a, b)
    local dx, dy = a[1] - b[1], a[2] - b[2]
    return math.sqrt(dx * dx + dy * dy)
end

local loops = {}
-- One farming loop through every inland spot of the target's veins or herbs: nearest spot next,
-- then crossings untangled. Worked out once per zone and set of nodes.
function PP:FarmLoop(target)
    local key = target.m .. ":" .. table.concat(target.groups or {}, ",")
    if loops[key] then return loops[key] end
    local left = {}
    for _, name in ipairs(target.groups or {}) do
        for _, point in ipairs(self:NodePoints(name, target.m) or {}) do
            if PP.Inland(point) then left[#left + 1] = point end
        end
    end
    local route = {}
    if #left > 0 then
        table.sort(left, function(a, b) if a[1] ~= b[1] then return a[1] < b[1] end return a[2] < b[2] end)
        route[1] = table.remove(left, 1)
        while #left > 0 do
            local best, bestGap
            for i, point in ipairs(left) do
                local gap = apart(point, route[#route])
                if not bestGap or gap < bestGap then best, bestGap = i, gap end
            end
            route[#route + 1] = table.remove(left, best)
        end
        -- swap any two legs that cross (2-opt), a few passes at most
        local n = #route
        for _ = 1, 30 do
            local improved = false
            for i = 1, n - 2 do
                for j = i + 2, n do
                    local a, b, c, d = route[i], route[i + 1], route[j], route[j % n + 1]
                    if a ~= d and apart(a, b) + apart(c, d) > apart(a, c) + apart(b, d) + 0.001 then
                        local lo, hi = i + 1, j
                        while lo < hi do route[lo], route[hi] = route[hi], route[lo]; lo, hi = lo + 1, hi - 1 end
                        improved = true
                    end
                end
            end
            if not improved then break end
        end
    end
    loops[key] = route
    return route
end

-- How many spawn spots are known for a vein or herb in one zone (0 = none known).
function PP:NodeCount(name, map)
    local zones = PP.NODES and PP.NODES[name]
    return tonumber(zones and zones[map] and zones[map]:match("^(%d+):")) or 0
end

-- ---------- Shortest Path Forever (optional) ----------

local function pathAddon()
    local api = ShortestPathForever and ShortestPathForever.API
    return type(api) == "table" and type(api.NavigateRoute) == "function" and api or nil
end

function PP:HasRoadRoutes() return pathAddon() ~= nil end

local ARRIVE_YARDS = 60
local motion, heading, recovery = nil, nil, nil
local function clock() return GetTime and GetTime() or 0 end
local function sampleMotion()
    local map = PP:CurrentMap()
    local c, x, y = PP:PlayerWorld()
    local now = clock()
    if not c then motion, heading = nil, nil; return end
    if motion and motion.map == map and motion.c == c and now - motion.time <= 2 then
        local dx, dy = x - motion.x, y - motion.y
        local gap = math.sqrt(dx * dx + dy * dy)
        if gap >= 1 and gap <= 100 then
            heading = { x = dx / gap, y = dy / gap, time = now }
        elseif gap > 100 then heading = nil end -- loading screens / teleports
    else heading = nil end
    motion = { map = map, c = c, x = x, y = y, time = now }
end

local function stepIndex(index, direction, count) return (index - 1 + direction) % count + 1 end

-- Rejoin the closest leg in the direction actually travelled, not the camera's facing.
-- A stopped player keeps their previous loop direction. Reverse explicitly overrides it.
local function chooseEntry(target, route, fallback, forcedDirection)
    local direction = forcedDirection or target.direction or 1
    if #route < 2 or PP:CurrentMap() ~= target.m then return fallback, direction end
    sampleMotion()
    local travel = heading and clock() - heading.time <= 6 and heading or nil
    if not motion or (not travel and not forcedDirection) then return fallback, direction end
    local best, bestGap, along
    for i, a in ipairs(route) do
        local b = route[i % #route + 1]
        local ac, ax, ay = PP.WorldPos(target.m, a[1] / 100, a[2] / 100)
        local bc, bx, by = PP.WorldPos(target.m, b[1] / 100, b[2] / 100)
        if ac == motion.c and bc == ac and ax and bx then
            local dx, dy = bx - ax, by - ay
            local length2 = dx * dx + dy * dy
            if length2 > 0 then
                local t = math.max(0, math.min(1, ((motion.x - ax) * dx + (motion.y - ay) * dy) / length2))
                local ex, ey = motion.x - ax - t * dx, motion.y - ay - t * dy
                local gap = ex * ex + ey * ey
                if not bestGap or gap < bestGap then
                    best, bestGap = i, gap
                    along = travel and (travel.x * dx + travel.y * dy) / math.sqrt(length2) or 0
                end
            end
        end
    end
    if not best then return fallback, direction end
    if not forcedDirection and math.abs(along) > 0.2 then direction = along > 0 and 1 or -1 end
    local at = direction == 1 and best % #route + 1 or best
    -- A node we are already standing on is behind us for purposes of rejoining.
    local yards = PP:Distance(target.m, route[at][1], route[at][2])
    if yards and yards <= ARRIVE_YARDS then at = stepIndex(at, direction, #route) end
    return at, direction
end

-- ---------- drawing on the world map ----------

local overlay, bar, hooked, raise
local discs, strokes = {}, {}
local usedDiscs, usedStrokes, width, height = 0, 0, 1, 1

local function canvas()
    local map = WorldMapFrame
    if not map then return nil end
    if map.GetCanvas then
        local ok, child = pcall(map.GetCanvas, map)
        if ok and child then return child end
    end
    return map.ScrollContainer and map.ScrollContainer.Child
end

-- x, y are 0-1 across the map being viewed.
local function disc(x, y, size, color, alpha, layer)
    usedDiscs = usedDiscs + 1
    local texture = discs[usedDiscs]
    if not texture then
        texture = overlay:CreateTexture(nil, "ARTWORK")
        texture:SetTexture(CIRCLE)
        discs[usedDiscs] = texture
    end
    texture:SetDrawLayer(layer)
    texture:SetVertexColor(color[1], color[2], color[3], alpha)
    texture:SetSize(size, size)
    texture:ClearAllPoints()
    texture:SetPoint("CENTER", overlay, "TOPLEFT", x * width, -y * height)
    texture:Show()
end

local function stroke(x1, y1, x2, y2, thickness, color, alpha)
    if not overlay.CreateLine then return end
    usedStrokes = usedStrokes + 1
    local line = strokes[usedStrokes]
    if not line then
        line = overlay:CreateLine(nil, "BORDER")
        strokes[usedStrokes] = line
    end
    line:SetColorTexture(color[1], color[2], color[3], alpha)
    line:SetThickness(thickness)
    line:SetStartPoint("TOPLEFT", overlay, x1 * width, -y1 * height)
    line:SetEndPoint("TOPLEFT", overlay, x2 * width, -y2 * height)
    line:Show()
end

-- Where the target sits on a map other than its own (a continent map). nil when it is not on that map.
local function onOtherMap(target, viewed)
    if not (PP.WorldPos and C_Map and C_Map.GetMapPosFromWorldPos and CreateVector2D) then return nil end
    local continent, wx, wy = PP.WorldPos(target.m, target.x / 100, target.y / 100)
    if not continent then return nil end
    local ok, _, position = pcall(C_Map.GetMapPosFromWorldPos, continent, CreateVector2D(wx, wy), viewed)
    if not ok or type(position) ~= "table" then return nil end
    local x, y = position.x, position.y
    if position.GetXY then x, y = position:GetXY() end
    if type(x) ~= "number" or type(y) ~= "number" or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x, y
end

local function legend(target)
    local parts = {}
    for i, name in ipairs(target.groups or {}) do
        local color = COLORS[(i - 1) % #COLORS + 1]
        parts[#parts + 1] = ("|cff%02x%02x%02x%s|r"):format(color[1] * 255, color[2] * 255, color[3] * 255, name)
    end
    local text = target.what .. "  -  " .. target.title
    if #parts > 0 then text = text .. "    Dots: " .. table.concat(parts, ", ") end
    if target.note then text = text .. "    " .. target.note end
    if target.at then text = text .. ("    Spot %d of %d"):format(target.at, #PP:FarmLoop(target)) end
    return text
end

-- The map paints its explored-land art as pins above the bare canvas. Our drawings must sit above
-- that art or they only show over the sea. Ask the map where points of interest go and sit there.
function raise()
    local level
    local manager = WorldMapFrame.GetPinFrameLevelsManager and WorldMapFrame:GetPinFrameLevelsManager()
    if manager and manager.GetValidFrameLevel then
        for _, kind in ipairs({ "PIN_FRAME_LEVEL_AREA_POI", "PIN_FRAME_LEVEL_QUEST_BLOB" }) do
            local ok, value = pcall(manager.GetValidFrameLevel, manager, kind, 1)
            if ok and type(value) == "number" then level = value break end
        end
    end
    local parent = overlay:GetParent()
    overlay:SetFrameLevel(level or ((parent and parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 2000))
end

local function redraw()
    if not overlay then return end
    raise()
    usedDiscs, usedStrokes = 0, 0
    local target = PP.db and PP.db.guideTarget
    local showing = type(target) == "table" and WorldMapFrame:IsShown()
    if showing then
        width, height = overlay:GetWidth() or 0, overlay:GetHeight() or 0
        if width <= 0 or height <= 0 then width, height = 1002, 668 end   -- the map's usual size
        local unit = width / 1000
        local viewed = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
        local white, green = { 1, 1, 1 }, { 0.3, 1, 0.4 }
        if viewed == target.m then
            for i, name in ipairs(target.groups or {}) do
                local color = COLORS[(i - 1) % #COLORS + 1]
                for _, point in ipairs(PP:NodePoints(name, target.m) or {}) do
                    if PP.Inland(point) then
                        disc(point[1] / 100, point[2] / 100, 56 * unit, color, 0.16, "BACKGROUND")
                        disc(point[1] / 100, point[2] / 100, 9 * unit, color, 1, "ARTWORK")
                    else
                        -- at the map's edge (often under water): shown small and faint, never on the route
                        disc(point[1] / 100, point[2] / 100, 6 * unit, color, 0.45, "ARTWORK")
                    end
                end
            end
            -- one loop through every spot, whatever it holds
            local route = PP:FarmLoop(target)
            for j, point in ipairs(route) do
                local nextPoint = route[j % #route + 1]
                local far = math.abs(point[1] - nextPoint[1]) + math.abs(point[2] - nextPoint[2]) > 45
                if #route > 2 and not far then
                    stroke(point[1] / 100, point[2] / 100, nextPoint[1] / 100, nextPoint[2] / 100,
                        2 * unit, { 1, 0.95, 0.8 }, 0.5)
                end
            end
            -- a rough area (cooking and leather spots have no node list)
            if not target.areaOnly then
                if target.radius then
                    disc(target.x / 100, target.y / 100, target.radius * 20 * unit, COLORS[1], 0.22, "BACKGROUND")
                end
                disc(target.x / 100, target.y / 100, 20 * unit, white, 1, "OVERLAY")
                disc(target.x / 100, target.y / 100, 13 * unit, green, 1, "OVERLAY")
            end
        elseif viewed and not target.areaOnly then
            local x, y = onOtherMap(target, viewed)
            if x then
                disc(x, y, 26 * unit, white, 1, "OVERLAY")
                disc(x, y, 17 * unit, green, 1, "OVERLAY")
            end
        end
        bar:SetHeight(target.skinning and 142 or 56)
        bar.text:SetHeight(target.skinning and 104 or 18)
        bar.text:SetWordWrap(target.skinning and true or false)
        bar.text:SetText(legend(target))
        bar.next:SetShown(not target.skinning)
        bar.resume:SetShown(not target.skinning)
        bar.details:SetShown(target.skinning and true or false)
        bar.status:SetText(target.paused and "Paused - click Resume" or (target.retry and "Waiting for road route" or
            (target.at and ("Spot %d of %d"):format(target.at, #PP:FarmLoop(target)) or "Travel to the gathering area")))
        if target.skinning then
            bar.status:SetText(target.areaOnly and "Follow the written hunting directions" or
                (target.routed and "Follow Shortest Path Forever to the hunting area" or "Hunting-area map pin"))
        end
        bar.resume:SetText(target.paused and "Resume" or "Rejoin")
        bar.reverse:SetShown(not target.skinning and #PP:FarmLoop(target) > 1)
    end
    for i = usedDiscs + 1, #discs do discs[i]:Hide() end
    for i = usedStrokes + 1, #strokes do strokes[i]:Hide() end
    bar:SetShown(showing and true or false)
end

local function hook()
    if hooked or not WorldMapFrame then return hooked end
    local child = canvas()
    if not child then return false end
    hooked = true
    overlay = CreateFrame("Frame", nil, child)
    overlay:SetAllPoints(child)
    raise()

    bar = CreateFrame("Frame", nil, WorldMapFrame, "BackdropTemplate")
    bar:SetFrameStrata("HIGH")
    bar:SetHeight(56)
    bar:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer or WorldMapFrame, "BOTTOMLEFT", 8, 8)
    bar:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer or WorldMapFrame, "BOTTOMRIGHT", -8, 8)
    PP.Skin(bar)
    bar.text = PP.UIText(bar, 13, PP.C.white)
    bar.text:SetPoint("TOPLEFT", 10, -5)
    bar.text:SetPoint("TOPRIGHT", -10, -5)
    bar.text:SetHeight(18)
    if bar.text.SetWordWrap then bar.text:SetWordWrap(false) end
    bar.status = PP.UIText(bar, 12, PP.C.white)
    bar.status:SetPoint("BOTTOMLEFT", 10, 8)
    bar.status:SetPoint("BOTTOMRIGHT", -320, 8)
    bar.status:SetHeight(18)
    if bar.status.SetWordWrap then bar.status:SetWordWrap(false) end
    PP.UIButton(bar, "Clear", 66, 22, function() PP:ClearGuideTarget() end):SetPoint("BOTTOMRIGHT", -6, 5)
    -- nothing at this spot? jump the pin to the next one
    bar.next = PP.UIButton(bar, "Next", 62, 22, function() PP:NextGuideSpot() end)
    bar.next:SetPoint("BOTTOMRIGHT", -78, 5)
    bar.details = PP.UIButton(bar, "Directions", 100, 22, function()
        local target = PP.db and PP.db.guideTarget
        if target and PP.ShowFarmText then PP:ShowFarmText("Hunting directions", legend(target)) end
    end)
    bar.details:SetPoint("BOTTOMRIGHT", -78, 5)
    bar.reverse = PP.UIButton(bar, "Reverse", 76, 22, function() PP:RejoinGuide(true) end)
    bar.reverse:SetPoint("BOTTOMRIGHT", -146, 5)
    bar.resume = PP.UIButton(bar, "Rejoin", 82, 22, function() PP:RejoinGuide() end)
    bar.resume:SetPoint("BOTTOMRIGHT", -228, 5)
    bar:Hide()

    if hooksecurefunc and WorldMapFrame.OnMapChanged then hooksecurefunc(WorldMapFrame, "OnMapChanged", redraw) end
    WorldMapFrame:HookScript("OnShow", redraw)
    WorldMapFrame:HookScript("OnHide", redraw)
    return true
end

-- ---------- setting and clearing the target ----------

-- target = { m = map ID, x, y = start spot (map percent), title = zone, what = "Mine Iron and Gold",
--            groups = { node names drawn as dots }, radius = rough area size in map percent, note }
-- Points the way to the target's current spot: Shortest Path's journey when it is installed,
-- otherwise the game's own map pin. quiet = no chat line (the pin is hopping along the loop).
local function navigate(target, quiet)
    if target.areaOnly then return false end
    local api = pathAddon()
    local started = false
    if api then
        local ok, result = pcall(api.NavigateRoute, OWNER,
            { { map = target.m, x = target.x / 100, y = target.y / 100, title = target.what .. " - " .. target.title } })
        started = ok and result == true
        if not ok and PP.FarmDebugLog then PP:FarmDebugLog("Shortest Path error", result) end
    end
    if PP.FarmDebugLog then PP:FarmDebugLog("navigation", "map=" .. tostring(target.m) ..
        " x=" .. tostring(target.x) .. " y=" .. tostring(target.y) .. " SPF=" .. tostring(api ~= nil) .. " started=" .. tostring(started)) end
    target.routed = started
    -- Loading and combat can both reject a journey. Retry briefly, using the plain pin meanwhile.
    -- After a few failed tries (no road known to this spot), stay on the plain pin and keep the loop going.
    target.retry = (api ~= nil and not started and not target.noRoad) or nil
    if started then
        if not quiet then PP:Print(target.title .. ": route started. Follow the path on your map.") end
    elseif not quiet then
        PP:Pin({ m = target.m, x = target.x, y = target.y, n = target.what, p = target.title })
    elseif C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
        local point = PP.safe(UiMapPoint.CreateFromCoordinates, target.m, target.x / 100, target.y / 100)
        if point and pcall(C_Map.SetUserWaypoint, point) and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true)
        end
    end
    return started
end

function PP:SetGuideTarget(target)
    if self:InCombat() then self:Print("Open the map after combat.") return false end
    local old = self.db.guideTarget
    if old and (old.skinning or target.skinning) then self:ClearGuideTarget() end
    self.db.guideTarget = target
    target.paused, target.noRoad, recovery = nil, nil, nil
    navigate(target, false)
    if WorldMapFrame then
        if not WorldMapFrame:IsShown() then
            if ToggleWorldMap then pcall(ToggleWorldMap) else pcall(WorldMapFrame.Show, WorldMapFrame) end
        end
        if WorldMapFrame.SetMapID then pcall(WorldMapFrame.SetMapID, WorldMapFrame, target.m) end
    end
    if hook() then redraw() end
    return true
end

function PP:ClearGuideTarget()
    local target = self.db and self.db.guideTarget
    if not target then return end
    self.db.guideTarget = nil
    local api = pathAddon()
    if target.routed and api and api.Cancel then pcall(api.Cancel, OWNER) end
    if not target.routed and not target.paused and C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    recovery = nil
    if overlay then redraw() end
    if self.RequestRefresh then self:RequestRefresh() end
end

-- ---------- following the loop ----------
-- When you reach the pinned spot, the pin (and the arrow or route to it) hops to the next spot on
-- the loop. Display only: it changes where the pin is, never where you are.

function PP:RejoinGuide(reverse)
    local target = self.db and self.db.guideTarget
    if not target then return false end
    if self:InCombat() then self:Print("Resume the route after combat.") return false end
    local route = self:FarmLoop(target)
    if #route > 1 and not target.flight then
        local nearest, gap
        for i, point in ipairs(route) do
            local yards = self:Distance(target.m, point[1], point[2])
            if yards and (not gap or yards < gap) then nearest, gap = i, yards end
        end
        local forced = reverse and -(target.direction or 1) or nil
        local fallback = reverse and stepIndex(target.at or 1, forced, #route) or nearest or target.at or 1
        target.at, target.direction = chooseEntry(target, route, fallback, forced)
        target.x, target.y = route[target.at][1], route[target.at][2]
    end
    target.paused, target.noRoad, recovery = nil, nil, nil
    navigate(target, true)
    if overlay then redraw() end
    return true
end

local function pauseGuide(target)
    target.paused, target.routed, target.retry = true, false, nil
    recovery = nil
    if overlay then redraw() end
    if PP.RequestRefresh then PP:RequestRefresh() end
    PP:Print("Farm route paused. Your loop is saved. Click Resume on the map to follow it again.")
end

-- Moves the pin to the next spot on the loop. Also the map bar's Next button (a node that is not up).
function PP:NextGuideSpot()
    local target = self.db and self.db.guideTarget
    if type(target) ~= "table" then return false end
    if target.paused then return self:RejoinGuide() end
    if self:InCombat() then self:Print("Next spot after combat.") return false end
    local route = self:FarmLoop(target)
    if #route < 2 then return false end
    if target.flight or not target.at then
        -- just landed (or no spot chosen yet): begin with the spot closest to you
        local best, gap
        for i, point in ipairs(route) do
            local yards = self:Distance(target.m, point[1], point[2])
            if yards and (not gap or yards < gap) then best, gap = i, yards end
        end
        target.at, target.direction = chooseEntry(target, route, best or 1)
        target.flight, target.note = nil, nil
    else
        target.at = stepIndex(target.at, target.direction or 1, #route)
    end
    target.x, target.y = route[target.at][1], route[target.at][2]
    recovery = nil
    navigate(target, true)
    if overlay then redraw() end
    return true
end

local function watchArrival()
    sampleMotion()
    local target = PP.db and PP.db.guideTarget
    if type(target) ~= "table" or type(target.groups) ~= "table" or #target.groups == 0 then return end
    if target.paused then return end
    -- Moving the map pin in combat makes WoW block the map's own buttons ("action blocked" errors).
    -- Wait: the pin hops on as soon as combat ends.
    if PP:InCombat() then return end
    -- Shortest Path follows one journey at a time. If you (or your quest guide) started a different
    -- one, step aside instead of taking the route back at the next spot.
    local api = pathAddon()
    if (target.routed or target.retry) and api and api.CurrentStop and api.Ended then
        local ok, stop, state = pcall(api.CurrentStop, OWNER)
        if not ok or state == "loading" then return end
        if ok and not stop then
            local okEnded, reason = pcall(api.Ended, OWNER)
            if not okEnded then return end
            local active = api.Active and PP.safe(api.Active)
            if reason == "replaced" or reason == "cancelled" or reason == "cleared" or active then
                pauseGuide(target); return
            elseif reason == "arrived" and not target.retry then
                -- SPF can finish its road journey outside our approximate node arrival circle.
                if UnitOnTaxi and PP.safe(UnitOnTaxi, "player") then return end
                PP:NextGuideSpot(); return
            elseif not reason and type(api.Active) == "function" and active == false then
                target.retry = true -- lost journey after a reload or temporary interruption
            end
        end
    end
    if target.retry and not PP:InCombat() then
        if not recovery or recovery.target ~= target then recovery = { target = target, count = 0, at = 0 } end
        if clock() >= recovery.at then
            if recovery.count >= 3 then
                target.retry, target.noRoad, recovery = nil, true, nil
                PP:Print("No road route to this spot. Follow the map pin instead.")
                if overlay then redraw() end
            else
                recovery.count, recovery.at = recovery.count + 1, clock() + 2
                navigate(target, true)
                if overlay then redraw() end
            end
        end
    end
    if UnitOnTaxi and PP.safe(UnitOnTaxi, "player") then return end
    local yards = PP:Distance(target.m, target.x, target.y)
    if yards and yards <= ARRIVE_YARDS then PP:NextGuideSpot() end
end

local watcher, sinceWatch = CreateFrame("Frame"), 0
watcher:SetScript("OnUpdate", function(_, elapsed)
    sinceWatch = sinceWatch + (elapsed or 0)
    if sinceWatch >= 0.5 then
        sinceWatch = 0
        watchArrival()
    end
end)
PP.WatchGuideArrival = watchArrival   -- for the tests

-- "Map" next to a zone in the guide: show this step's veins or herbs in that zone.
function PP:ShowZoneOnMap(st, zoneName)
    local map = PP.ZONE_MAP[zoneName]
    if not map then self:Print(zoneName .. ": no map for this zone yet.") return false end
    local groups, any = {}, nil
    for _, node in ipairs(st.nodes or {}) do
        local points = self:NodePoints(node[1], map)
        if points then
            groups[#groups + 1] = node[1]
            any = any or points[1]
        end
    end
    -- Where to start: a spot on the loop (never the map's edge or the sea). The one closest to you
    -- when you are on that continent; otherwise the one with the most other spots around it.
    local route = self:FarmLoop({ m = map, groups = groups })
    local start, nearest, crowd
    for _, point in ipairs(route) do
        local yards = self:Distance(map, point[1], point[2])
        if yards and yards < 1e7 and (not nearest or yards < nearest) then start, nearest = point, yards end
    end
    if not start then
        for _, point in ipairs(route) do
            local near = 0
            for _, other in ipairs(route) do if apart(point, other) <= 12 then near = near + 1 end end
            if not crowd or near > crowd then start, crowd = point, near end
        end
    end
    start = start or any
    local at
    for i, point in ipairs(route) do if point == start then at = i end end
    local old = self.db and self.db.guideTarget
    local same = old and old.m == map and table.concat(old.groups or {}, ",") == table.concat(groups, ",")
    local direction = same and old.direction or 1
    if at then
        at, direction = chooseEntry({ m = map, direction = direction }, route, at)
        start = route[at]
    end
    local note = #groups == 0 and "No spot map for this zone yet. The pin is the middle of the zone." or nil
    -- Not in the zone yet: pin the flight point you can fly to, the one nearest the farm spots.
    local flight = self:CurrentMap() ~= map and self:FlightPointFor(map, route)
    if flight then
        start, at = { flight.x, flight.y }, nil
        note = "Fly to " .. flight.name .. ", then follow the loop."
    end
    return self:SetGuideTarget({ m = map, x = start and start[1] or 50, y = start and start[2] or 50,
        title = zoneName, what = st.text or "Farm", groups = groups, note = note,
        flight = flight and flight.name or nil, at = at, direction = direction })
end

-- The flight point in a zone that this character has discovered and may use, nearest to the farm
-- spots: { x, y (map percent), name }. nil when the zone has none you know (then the pin goes on a spot).
function PP:FlightPointFor(map, spots)
    if not (C_TaxiMap and C_TaxiMap.GetTaxiNodesForMap) then return nil end
    local nodes = PP.safe(C_TaxiMap.GetTaxiNodesForMap, map)
    if type(nodes) ~= "table" then return nil end
    local secret = issecretvalue or function() return false end
    local mine = self:Faction() == "Horde" and 1 or 2    -- the game's numbers: 0 neutral, 1 Horde, 2 Alliance
    local best, bestGap
    for _, node in ipairs(nodes) do
        if type(node) == "table" and not secret(node) then
            local faction, hidden, name, position = node.faction, node.isUndiscovered, node.name, node.position
            local usable = not secret(faction) and (faction == 0 or faction == mine)
                and not secret(hidden) and hidden == false
            local x, y
            if usable and type(position) == "table" and not secret(position) then
                x, y = position.x, position.y
                if position.GetXY then x, y = PP.safe(position.GetXY, position) end
            end
            if type(x) == "number" and type(y) == "number" and not secret(x) and not secret(y)
                and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
                local here = { x * 100, y * 100 }
                -- how far this flight point is from the nearest farm spot
                local gap = 0
                for _, spot in ipairs(spots or {}) do
                    local d = apart(here, spot)
                    if gap == 0 or d < gap then gap = d end
                end
                if not bestGap or gap < bestGap then
                    best, bestGap = { x = here[1], y = here[2],
                        name = type(name) == "string" and not secret(name) and name or "the flight point" }, gap
                end
            end
        end
    end
    return best
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    local target = PP.db and PP.db.guideTarget
    -- Skinning now uses beast spots like ore and herbs. A "directions only" skinning target saved by
    -- version 1.3.8-1.3.9 is cleared, so the map never opens on it again; pick the leather again in /prof farm.
    if target and (target.skinning or target.areaOnly or
        (type(target.note) == "string" and target.note:find("Zone-center pin", 1, true))) then
        PP:ClearGuideTarget()
    end
    hook()
end)
