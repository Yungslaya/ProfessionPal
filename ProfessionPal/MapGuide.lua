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
            if target.radius then
                disc(target.x / 100, target.y / 100, target.radius * 20 * unit, COLORS[1], 0.22, "BACKGROUND")
            end
            disc(target.x / 100, target.y / 100, 20 * unit, white, 1, "OVERLAY")
            disc(target.x / 100, target.y / 100, 13 * unit, green, 1, "OVERLAY")
        elseif viewed then
            local x, y = onOtherMap(target, viewed)
            if x then
                disc(x, y, 26 * unit, white, 1, "OVERLAY")
                disc(x, y, 17 * unit, green, 1, "OVERLAY")
            end
        end
        bar.text:SetText(legend(target))
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
    bar:SetSize(700, 30)
    bar:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer or WorldMapFrame, "BOTTOMLEFT", 8, 8)
    PP.Skin(bar)
    bar.text = PP.UIText(bar, 13, PP.C.white)
    bar.text:SetPoint("LEFT", 10, 0)
    bar.text:SetPoint("RIGHT", -150, 0)
    if bar.text.SetWordWrap then bar.text:SetWordWrap(false) end
    PP.UIButton(bar, "Clear", 66, 22, function() PP:ClearGuideTarget() end):SetPoint("RIGHT", -6, 0)
    -- nothing at this spot? jump the pin to the next one
    PP.UIButton(bar, "Next", 62, 22, function() PP:NextGuideSpot() end):SetPoint("RIGHT", -78, 0)
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
    local api = pathAddon()
    local started = false
    if api then
        local ok, result = pcall(api.NavigateRoute, OWNER,
            { { map = target.m, x = target.x / 100, y = target.y / 100, title = target.what .. " - " .. target.title } })
        started = ok and result == true
    end
    target.routed = started
    -- Shortest Path says no during combat: use the plain pin now and ask it again afterwards.
    target.retry = (api ~= nil and not started and PP:InCombat()) or nil
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
    self.db.guideTarget = target
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
    if not target.routed and C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
    if overlay then redraw() end
    if self.RequestRefresh then self:RequestRefresh() end
end

-- ---------- following the loop ----------
-- When you reach the pinned spot, the pin (and the arrow or route to it) hops to the next spot on
-- the loop. Display only: it changes where the pin is, never where you are.

local ARRIVE_YARDS = 60   -- spots are known to about one map percent, so "there" is a generous circle

-- Moves the pin to the next spot on the loop. Also the map bar's Next button (a node that is not up).
function PP:NextGuideSpot()
    local target = self.db and self.db.guideTarget
    if type(target) ~= "table" then return false end
    local route = self:FarmLoop(target)
    if #route < 2 then return false end
    if target.flight or not target.at then
        -- just landed (or no spot chosen yet): begin with the spot closest to you
        local best, gap
        for i, point in ipairs(route) do
            local yards = self:Distance(target.m, point[1], point[2])
            if yards and (not gap or yards < gap) then best, gap = i, yards end
        end
        target.at = best or 1
        target.flight, target.note = nil, nil
    else
        target.at = target.at % #route + 1
    end
    target.x, target.y = route[target.at][1], route[target.at][2]
    navigate(target, true)
    if overlay then redraw() end
    return true
end

local function watchArrival()
    local target = PP.db and PP.db.guideTarget
    if type(target) ~= "table" or type(target.groups) ~= "table" or #target.groups == 0 then return end
    if target.retry and not PP:InCombat() then navigate(target, true) end
    -- Shortest Path follows one journey at a time. If you (or your quest guide) started a different
    -- one, step aside instead of taking the route back at the next spot.
    local api = pathAddon()
    if target.routed and api and api.CurrentStop and api.Ended then
        local ok, stop = pcall(api.CurrentStop, OWNER)
        if ok and not stop then
            local okEnded, reason = pcall(api.Ended, OWNER)
            if okEnded and (reason == "replaced" or reason == "cancelled") then
                PP.db.guideTarget = nil
                if overlay then redraw() end
                if PP.RequestRefresh then PP:RequestRefresh() end
                PP:Print("Farm route stopped, because another journey started. Click Map to start it again.")
                return
            end
        end
    end
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
    local note = #groups == 0 and "No spot map for this zone yet. The pin is the middle of the zone." or nil
    -- Not in the zone yet: pin the flight point you can fly to, the one nearest the farm spots.
    local flight = self:CurrentMap() ~= map and self:FlightPointFor(map, route)
    if flight then
        start, at = { flight.x, flight.y }, nil
        note = "Fly to " .. flight.name .. ", then follow the loop."
    end
    return self:SetGuideTarget({ m = map, x = start and start[1] or 50, y = start and start[2] or 50,
        title = zoneName, what = st.text or "Farm", groups = groups, note = note,
        flight = flight and flight.name or nil, at = at })
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
events:SetScript("OnEvent", function() hook() end)
