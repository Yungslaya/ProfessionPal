"""Checks for the map guide: node data, Map buttons, farm spots on the world map, and the way there."""
from pathlib import Path
from lupa import lua51

root = Path(__file__).resolve().parents[1]
lua = lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute((root / 'tests/harness.lua').read_text(encoding='utf-8-sig'))
lua.execute(r"""
-- a fake world map: a frame with a canvas, a current map and the usual hooks
WorldMapFrame = CreateFrame("Frame", "WorldMapFrame")
WorldMapFrame:Hide()
WorldMapFrame.ScrollContainer = { Child = CreateFrame("Frame") }
VIEW = nil
WorldMapFrame.GetMapID = function() return VIEW end
WorldMapFrame.SetMapID = function(self, id) VIEW = id; self:OnMapChanged() end
WorldMapFrame.OnMapChanged = function() end
ToggleWorldMap = function() WorldMapFrame:SetShown(not WorldMapFrame:IsShown()) end
function hooksecurefunc(object, name, hook)
  local original = object[name]
  object[name] = function(...) original(...); hook(...) end
end
""")
ns = lua.table()
for name in (root / 'ProfessionPal/ProfessionPal.toc').read_text().splitlines():
    if name.endswith('.lua'):
        lua.eval('function(s,n) return assert(loadstring(s,n)) end')(
            (root / 'ProfessionPal' / name).read_text(encoding='utf-8-sig'), name)('ProfessionPal', ns)
lua.execute(r"""
STATE.faction = 'Alliance'; STATE.level = 32; STATE.map = 1429
STATE.profs = { { name = "Mining", rank = 137, max = 225, line = 186 } }
FIRE('PLAYER_LOGIN'); FIRE('PLAYER_ENTERING_WORLD')
local P = ProfessionPal
local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local function discs()
  local n = 0
  for _, f in ipairs(FRAMES) do if f._kind == "Texture" and f._tex == CIRCLE and f:IsVisible() then n = n + 1 end end
  return n
end
local function lines()
  local n = 0
  for _, f in ipairs(FRAMES) do if f._kind == "Line" and f:IsVisible() then n = n + 1 end end
  return n
end
local function bar()
  for _, f in ipairs(FRAMES) do
    if f._kind == "FontString" and f._text and f._text:find("Arathi Highlands", 1, true) and f._parent and f._parent._parent == WorldMapFrame then
      return f:IsVisible() and f._text or nil
    end
  end
end

-- data: every node has points inside the map, and every map is one the addon knows
local known = {}
for _, id in pairs(P.ZONE_MAP) do known[id] = true end
local nodes, zones = 0, 0
for name, byMap in pairs(P.NODES) do
  nodes = nodes + 1
  for map in pairs(byMap) do
    zones = zones + 1
    assert(known[map], name .. ": unknown map " .. map)
    local points = P:NodePoints(name, map)
    assert(#points >= 3 and #points <= 24, name .. " " .. map .. ": " .. #points .. " points")
    assert(P:NodeCount(name, map) >= 8 and P:NodeCount(name, map) >= #points, name .. " " .. map .. ": spawn count")
    for _, p in ipairs(points) do assert(p[1] >= 0 and p[1] <= 99 and p[2] >= 0 and p[2] <= 99) end
    assert(P:NodePoints(name, map) == points, "points are decoded once")
  end
end
assert(nodes == 38 and zones > 150, nodes .. " nodes, " .. zones .. " zones")
assert(P:NodePoints("Iron Deposit", 1) == nil and P:NodePoints("Nothing", 1417) == nil)
assert(P:NodeCount("Iron Deposit", 1417) == 145 and P:NodeCount("Iron Deposit", 1) == 0)
-- the new Forever zones are in: Riverglades iron, Zephras Isle copper
assert(P:NodeCount("Iron Deposit", 2548) == 86 and #P:NodePoints("Iron Deposit", 2548) >= 10)
assert(P:NodeCount("Copper Vein", 2521) > 100 and P:NodeCount("Peacebloom", 2521) > 100)
-- every vein and herb the guides name has spot data
for _, key in ipairs({ "mining", "herbalism" }) do
  for _, st in ipairs(P.byKey[key].steps) do
    for _, node in ipairs(st.nodes or {}) do
      assert(P.NODES[node[1]] or node[1] == "Poor Copper Vein", key .. ": no spots for " .. node[1])
    end
  end
end
print("PASS: node data")

-- the guide window shows a Map button beside each zone
P:Toggle()
local shown = {}
for _, f in ipairs(FRAMES) do if f._text == "Map" and f.zone and f:IsVisible() then shown[#shown + 1] = f end end
assert(#shown == 4, "Map buttons for Arathi, Desolace, Thousand Needles, Riverglades: " .. #shown)
local arathi
for _, f in ipairs(shown) do if f.zone == "Arathi Highlands" then arathi = f end end
assert(arathi and arathi.step.text == "Mine Iron and Gold")

-- no path addon: the map opens on the zone, the spots are drawn, and the game's own pin is set
local pins = {}
P.Pin = function(_, t) pins[#pins + 1] = t end
local iron, gold = P:NodePoints("Iron Deposit", 1417), P:NodePoints("Gold Vein", 1417)
-- spots at the map's edge (Arathi's Drowned Reef is under the sea) are drawn faint and never used to start
local inland, edge = 0, 0
for _, list in ipairs({ iron, gold }) do
  for _, p in ipairs(list) do if P.Inland(p) then inland = inland + 1 else edge = edge + 1 end end
end
assert(edge >= 1 and inland >= 20, "Arathi has edge spots and inland spots: " .. edge .. " / " .. inland)
assert(P.Inland({ 50, 50 }) and not P.Inland({ 7, 91 }) and not P.Inland({ 18, 89 }) and not P.Inland({ 95, 40 }))
local near
for _, p in ipairs(iron) do if P.Inland(p) then near = p end end
local reef
for _, p in ipairs(iron) do if not P.Inland(p) then reef = p end end
-- you stand right on a reef spot: the start is still the closest spot on land
P.Distance = function(_, map, x, y) return math.abs(x - reef[1]) + math.abs(y - reef[2]) end
local best
for _, list in ipairs({ iron, gold }) do
  for _, p in ipairs(list) do
    if P.Inland(p) and (not best or P:Distance(1417, p[1], p[2]) < P:Distance(1417, best[1], best[2])) then best = p end
  end
end
near = best
assert(P:HasRoadRoutes() == false)
arathi._scripts.OnClick(arathi, "LeftButton")
local t = P.db.guideTarget
assert(t and t.m == 1417 and t.title == "Arathi Highlands" and t.what == "Mine Iron and Gold")
assert(t.groups[1] == "Iron Deposit" and t.groups[2] == "Gold Vein" and #t.groups == 2)
assert(t.x == near[1] and t.y == near[2], "start = the spot closest to you")
assert(#pins == 1 and pins[1].m == 1417 and pins[1].x == near[1] and t.routed == false, "plain pin without a path addon")
assert(WorldMapFrame:IsShown() and VIEW == 1417, "map opens on the zone")
assert(discs() == 2 * inland + edge + 2, "an area and a dot per inland spot, a faint dot per edge spot, the start marker: " .. discs())
local route = P:FarmLoop(t)
assert(#route == inland and P:FarmLoop(t) == route, "one loop through every inland spot, worked out once")
assert(lines() >= inland - 4 and lines() <= inland, "one line per leg of the loop (very long jumps are not drawn): " .. lines())
local total = 0
for i, p in ipairs(route) do local q = route[i % #route + 1]; total = total + math.sqrt((p[1]-q[1])^2 + (p[2]-q[2])^2) end
assert(total < 420, "the loop is short, not a web: " .. total)
local text = bar()
assert(text and text:find("Mine Iron and Gold  -  Arathi Highlands", 1, true) and text:find("Iron Deposit", 1, true)
  and text:find("Gold Vein", 1, true), tostring(text))
-- another zone's map: no spots; a continent the target is not on: nothing
WorldMapFrame:SetMapID(1429)
assert(discs() == 0 and lines() == 0, "nothing drawn on other maps here")
WorldMapFrame:SetMapID(1417)
assert(discs() == 2 * inland + edge + 2)
WorldMapFrame:Hide(); WorldMapFrame._scripts = WorldMapFrame._scripts
-- Clear
P:ClearGuideTarget()
assert(P.db.guideTarget == nil)
WorldMapFrame:Show(); WorldMapFrame:SetMapID(1417)
assert(discs() == 0 and lines() == 0 and bar() == nil, "cleared")

-- with Shortest Path Forever: it gets the journey, and no pin is set
local asked, cancelled = {}, 0
ShortestPathForever = { API = {
  NavigateRoute = function(owner, stops) asked[#asked + 1] = { owner = owner, stop = stops[1], n = #stops }; return ROUTE_OK end,
  Cancel = function(owner) cancelled = cancelled + 1; return true end,
} }
ROUTE_OK = true
assert(P:HasRoadRoutes() == true)
assert(P:ShowZoneOnMap(arathi.step, "Arathi Highlands") == true)
assert(#asked == 1 and asked[1].owner == "ProfessionPal" and asked[1].n == 1)
assert(asked[1].stop.map == 1417 and asked[1].stop.x == near[1] / 100 and asked[1].stop.y == near[2] / 100)
assert(asked[1].stop.title == "Mine Iron and Gold - Arathi Highlands")
assert(#pins == 1 and P.db.guideTarget.routed == true, "no pin when the journey started")
P:ClearGuideTarget(); assert(cancelled == 1, "clearing cancels our journey")
-- it refuses (in combat for it, or journeys switched off): fall back to the pin
ROUTE_OK = false
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
assert(#pins == 2 and P.db.guideTarget.routed == false, "pin when the journey did not start")
P:ClearGuideTarget(); assert(cancelled == 1, "nothing to cancel")
-- it breaks: still no error for the player
ShortestPathForever.API.NavigateRoute = function() error("boom") end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands"); assert(#pins == 3)
ShortestPathForever = nil

-- far away (another continent, or the game will not say where you are): start where the spots are thickest
P.Distance = function() return nil end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
t = P.db.guideTarget
assert(P.Inland({ t.x, t.y }), "the start is on land even with no position: " .. t.x .. "," .. t.y)
-- not in the zone: the pin goes on the flight point you know and may use, the one nearest the farm spots
local function at(x, y) return { GetXY = function() return x, y end } end
C_TaxiMap = { GetTaxiNodesForMap = function(map)
  if map ~= 1417 then return {} end
  return {
    { name = "Hammerfall, Arathi", faction = 1, isUndiscovered = false, position = at(0.73, 0.33) },          -- Horde
    { name = "Refuge Pointe, Arathi", faction = 2, isUndiscovered = false, position = at(0.46, 0.46) },
    { name = "Far Post", faction = 2, isUndiscovered = false, position = { x = 0.02, y = 0.02 } },            -- known but far from the spots
    { name = "Secret Post", faction = 0, isUndiscovered = true, position = at(0.47, 0.47) },                  -- not discovered
    { name = "Broken", faction = 2, isUndiscovered = false, position = at(7, 7) },
  }
end }
STATE.map = 1429
P.Distance = function() return 1e7 end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
t = P.db.guideTarget
assert(t.x == 46 and t.y == 46 and t.flight == "Refuge Pointe, Arathi", t.x .. "," .. t.y .. " " .. tostring(t.flight))
assert(t.note == "Fly to Refuge Pointe, Arathi, then follow the loop.")
assert(bar():find("Fly to Refuge Pointe, Arathi, then follow the loop.", 1, true))
STATE.faction = 'Horde'
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
assert(P.db.guideTarget.flight == "Hammerfall, Arathi", "your own faction's flight point")
STATE.faction = 'Alliance'
-- already in the zone: straight to the nearest spot on land, no flight
STATE.map = 1417
P.Distance = function(_, map, x, y) return math.abs(x - near[1]) + math.abs(y - near[2]) end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
t = P.db.guideTarget
assert(t.flight == nil and t.x == near[1] and t.y == near[2] and t.note == nil)
-- no flight point you know there: the pin stays on a farm spot
STATE.map = 1429
C_TaxiMap.GetTaxiNodesForMap = function() return { { name = "Secret Post", faction = 0, isUndiscovered = true, position = at(0.47, 0.47) } } end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
assert(P.db.guideTarget.flight == nil and P.Inland({ P.db.guideTarget.x, P.db.guideTarget.y }))
C_TaxiMap.GetTaxiNodesForMap = function() error("no taxi data") end
P:ShowZoneOnMap(arathi.step, "Arathi Highlands"); assert(P.db.guideTarget.flight == nil)
C_TaxiMap = nil
-- following the loop: reaching the pinned spot moves the pin to the next spot, and so on round the loop
STATE.map = 1417
local hops = {}
ShortestPathForever = { API = {
  NavigateRoute = function(owner, stops) hops[#hops + 1] = stops[1]; return NAV_OK end,
  Cancel = function() return true end,
} }
NAV_OK = true
P.Distance = function(_, map, x, y) return math.abs(x - near[1]) + math.abs(y - near[2]) + 500 end   -- far from every spot
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
t = P.db.guideTarget
local loop = P:FarmLoop(t)
assert(t.at and loop[t.at][1] == t.x and loop[t.at][2] == t.y and #hops == 1, "the pin starts on a loop spot and knows which")
assert(bar():find("Spot " .. t.at .. " of " .. #loop, 1, true), bar())
local first, lines0 = t.at, #LOG
P.WatchGuideArrival(); assert(t.at == first and #hops == 1, "not there yet: nothing moves")
-- you arrive
P.Distance = function(_, map, x, y) return (x == t.x and y == t.y) and 20 or 900 end
P.WatchGuideArrival()
local second = first % #loop + 1
assert(t.at == second and t.x == loop[second][1] and t.y == loop[second][2], "pin hops to the next spot")
assert(#hops == 2 and hops[2].x == t.x / 100 and hops[2].y == t.y / 100, "the route is pointed at the new spot")
assert(#LOG == lines0, "no chat line for each hop")
assert(bar():find("Spot " .. second .. " of " .. #loop, 1, true), bar())
-- the last spot leads back to the first; the Next button does the same without arriving
t.at = #loop; t.x, t.y = loop[#loop][1], loop[#loop][2]
P.WatchGuideArrival(); assert(t.at == 1, "the loop goes round")
P.Distance = function() return 900 end
for _, f in ipairs(FRAMES) do if f._text == "Next" and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "LeftButton") end end
assert(t.at == 2 and #hops == 4, "Next skips a spot that has nothing")
-- in combat Shortest Path says no: the plain pin is used, and it is asked again after combat
NAV_OK = false; STATE.combat = true
P:NextGuideSpot(); assert(t.at == 3 and t.routed == false and t.retry == true and STATE.pin and STATE.pin.x == t.x / 100)
NAV_OK = true; STATE.combat = false
local before = #hops
P.WatchGuideArrival(); assert(#hops == before + 1 and t.routed == true and t.retry == nil, "asked again after combat")
P.WatchGuideArrival(); assert(#hops == before + 1, "and only once")
-- Shortest Path follows one journey at a time. When you or your quest guide start another one, the farm
-- route steps aside instead of grabbing the route back; when its own journey simply arrived, it carries on.
local mine, ended = true, nil
ShortestPathForever.API.CurrentStop = function(owner) assert(owner == "ProfessionPal"); if mine then return 1 end return nil, "none" end
ShortestPathForever.API.Ended = function(owner) return ended end
P.Distance = function() return 900 end
P.WatchGuideArrival(); assert(P.db.guideTarget == t, "our journey is running")
mine, ended = false, "arrived"
P.WatchGuideArrival(); assert(P.db.guideTarget == t, "arriving is not a reason to stop")
ended = "replaced"; before = #hops
P.WatchGuideArrival()
assert(P.db.guideTarget == nil and #hops == before, "another journey started: the farm route stops and does not take it back")
assert(LOG[#LOG]:find("Farm route stopped", 1, true), LOG[#LOG])
P.WatchGuideArrival(); assert(#hops == before)
mine, ended = true, nil
-- the guide window's Stop route button does the same as Clear on the map
P:ShowZoneOnMap(arathi.step, "Arathi Highlands"); P:Refresh()
local stop
for _, f in ipairs(FRAMES) do if f._text == "Stop route" and f._scripts.OnClick and f:IsVisible() then stop = f end end
assert(stop, "Stop route button shows while a farm route runs")
stop._scripts.OnClick(stop, "LeftButton"); P:Refresh()
assert(P.db.guideTarget == nil and not stop:IsVisible(), "it stops the route and goes away")-- flying in: at the flight point the pin moves to the spot closest to you
C_TaxiMap = { GetTaxiNodesForMap = function() return { { name = "Refuge Pointe", faction = 2, isUndiscovered = false, position = { x = 0.46, y = 0.46 } } } end }
STATE.map = 1429
P:ShowZoneOnMap(arathi.step, "Arathi Highlands")
t = P.db.guideTarget
assert(t.flight == "Refuge Pointe" and t.at == nil and not bar():find("Spot ", 1, true))
P.Distance = function(_, map, x, y) return (x == 46 and y == 46) and 30 or (math.abs(x - 46) + math.abs(y - 46)) * 36 end
P.WatchGuideArrival()
assert(t.flight == nil and t.note == nil and t.at and P.Inland({ t.x, t.y }), "landed: the pin is on a farm spot now")
local closest
for i, p in ipairs(loop) do if not closest or P:Distance(1417, p[1], p[2]) < P:Distance(1417, loop[closest][1], loop[closest][2]) then closest = i end end
assert(t.at == closest, "the spot closest to where you landed")
-- a rough area with no loop (cooking, leather) never hops, and nothing happens with no target
P.db.guideTarget = { m = 1417, x = 50, y = 50, title = "x", what = "y", radius = 6 }
P.Distance = function() return 5 end
P.WatchGuideArrival(); assert(P.db.guideTarget.x == 50 and P:NextGuideSpot() == false)
P.db.guideTarget = nil; P.WatchGuideArrival(); assert(P:NextGuideSpot() == false)
ShortestPathForever = nil; C_TaxiMap = nil-- Riverglades has its own spots
P:ShowZoneOnMap(arathi.step, "Riverglades")
t = P.db.guideTarget
assert(t.m == 2548 and t.groups[1] == "Iron Deposit" and VIEW == 2548 and discs() > 20, "Riverglades iron on the map")
-- a zone with no spot data: middle of the zone and a plain note. An unknown zone: a message, nothing set.
P:ShowZoneOnMap({ text = "Skin beasts", nodes = { { "Light Leather", 0, 2318 } } }, "Zephras Isle")
t = P.db.guideTarget
assert(t.m == 2521 and t.x == 50 and t.y == 50 and #t.groups == 0 and t.note:find("No spot map", 1, true))
assert(P:ShowZoneOnMap({ text = "x" }, "Nowhere") == false and P.db.guideTarget == t)
-- in combat: nothing changes
STATE.combat = true
assert(P:ShowZoneOnMap(arathi.step, "Arathi Highlands") == false and P.db.guideTarget == t)
STATE.combat = false
assert(#BLOCKED == 0, "protected frame changes")
print("ALL MAP GUIDE CHECKS PASSED")
""")
