-- rough real-scale world (continent, x, y in yards) for map centers; each map spans 1000 yards
WORLD = {
  -- Kalimdor
  [1439] = {1, 0, 0}, [2482] = {1, 1500, -2500}, [1438] = {1, -1500, 1500}, [1457] = {1, -1600, 1700},
  [1440] = {1, 1000, -3500}, [1442] = {1, -500, -6000}, [1413] = {1, 3500, -8000}, [1411] = {1, 6000, -6000},
  [1454] = {1, 6000, -5600}, [1445] = {1, 4500, -11000}, [1446] = {1, 4500, -15000}, [1412] = {1, 1500, -9000},
  [1456] = {1, 1300, -8800}, [1443] = {1, -2000, -9000}, [1444] = {1, -1500, -12500}, [1448] = {1, 2500, -1000},
  -- Eastern Kingdoms
  [1453] = {0, -8000, 800}, [1429] = {0, -8800, 500}, [1455] = {0, -5000, -800}, [1426] = {0, -5500, -500},
  [1431] = {0, -10500, -200}, [1437] = {0, -3500, -2000}, [1434] = {0, -12500, 500}, [1420] = {0, 2200, 300},
  [1458] = {0, 1600, 300}, [1421] = {0, 500, 1200}, [1436] = {0, -10500, 1500}, [1432] = {0, -5000, -3000},
  [1433] = {0, -9300, -2000}, [1416] = {0, 500, -500}, [1417] = {0, -1500, -2000}, [1424] = {0, -500, -500},
  [1418] = {0, -6500, -3500}, [1435] = {0, -10500, -3500}, [1425] = {0, 0, -3500},
  -- islands (own "continents")
  [2521] = {2, 0, 0}, [2548] = {3, 0, 0},
}
local P = ProfessionPal
local function trainers(label, faction, map, pos, prof, line, rank, max, level)
  STATE.faction = faction; STATE.map = map; STATE.pos = pos; STATE.level = level or 30
  STATE.profs = { { name = prof, line = line, rank = rank, max = max } }
  local def; for _, d in ipairs(P.professions) do if d.name == prof then def = d end end
  local _, nxt, ni = P:RankInfo(def, rank, max)
  local list = P:TrainersFor(def, ni)
  local out = {}
  for i = 1, math.min(4, #list) do
    local t = list[i]
    out[#out + 1] = string.format("%s (%s) %s", t.n, t.p, t.dist and string.format("%.1f min", t.dist / 60) or "?")
  end
  print(label .. "  [needs " .. nxt.name .. "]") ; for i, o in ipairs(out) do print("   " .. i .. ". " .. o) end
end
trainers("Alliance in Auberdine, Engineering 55", "Alliance", 1439, {0.32, 0.44}, "Engineering", 202, 55, 75)
trainers("Alliance in Auberdine, Blacksmithing 130", "Alliance", 1439, {0.32, 0.44}, "Blacksmithing", 164, 130, 150)
trainers("Alliance in Elwynn, Mining 55", "Alliance", 1429, {0.5, 0.5}, "Mining", 186, 55, 75)
trainers("Alliance in Darnassus, Tailoring 55", "Alliance", 1457, {0.5, 0.5}, "Tailoring", 197, 55, 75)
trainers("Horde in the Barrens, Engineering 55", "Horde", 1413, {0.5, 0.3}, "Engineering", 202, 55, 75)
trainers("Horde in Tirisfal, Blacksmithing 130", "Horde", 1420, {0.6, 0.5}, "Blacksmithing", 164, 130, 150)
trainers("Horde in Stranglethorn, Alchemy 210", "Horde", 1434, {0.3, 0.3}, "Alchemy", 171, 210, 225, 40)
