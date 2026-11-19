--[[ ProfessionPal - things you can gather and sell (used by Market Ledger's Farm tab)

  FARMABLE: item ID, item name, the vein or herb it comes from (a name in Data_Nodes.lua),
            the gathering profession, the skill needed, and for leather the character level
            where the beasts that drop it start.
  ZONE_LEVEL: map ID -> lowest and highest monster level in the zone.

  NOT VERIFIED: skill numbers and zone levels are the Classic ones; WoW: Forever may differ.
  Riverglades and Zephras Isle levels are guesses.
]]

local _, PP = ...

local function ore(id, name, node, skill) return { id = id, name = name, node = node, prof = "mining", skill = skill } end
local function herb(id, name, skill) return { id = id, name = name, node = name, prof = "herbalism", skill = skill } end
-- Leather comes from beasts: node = "<Leather> beasts" (Data_Beasts.lua), skill = Skinning for the lowest-level
-- beasts that give it (Icy Veins: level 11-20 beasts need (level-10)x10, level 20+ need level x5).
local function hide(id, name, level, skill) return { id = id, name = name, node = name .. " beasts", prof = "skinning", skill = skill, level = level } end

PP.FARMABLE = {
    ore(2770, "Copper Ore", "Copper Vein", 1), ore(2771, "Tin Ore", "Tin Vein", 65),
    ore(2775, "Silver Ore", "Silver Vein", 75), ore(2772, "Iron Ore", "Iron Deposit", 125),
    ore(2776, "Gold Ore", "Gold Vein", 155), ore(3858, "Mithril Ore", "Mithril Deposit", 175),
    ore(7911, "Truesilver Ore", "Truesilver Deposit", 230), ore(10620, "Thorium Ore", "Small Thorium Vein", 245),
    ore(11370, "Dark Iron Ore", "Dark Iron Deposit", 230),

    herb(2447, "Peacebloom", 1), herb(765, "Silverleaf", 1), herb(2449, "Earthroot", 15),
    herb(785, "Mageroyal", 50), herb(2450, "Briarthorn", 70), herb(3820, "Stranglekelp", 85),
    herb(2453, "Bruiseweed", 100), herb(3355, "Wild Steelbloom", 115), herb(3369, "Grave Moss", 120),
    herb(3356, "Kingsblood", 125), herb(3357, "Liferoot", 150), herb(3818, "Fadeleaf", 160),
    herb(3821, "Goldthorn", 170), herb(3358, "Khadgar's Whisker", 185), herb(3819, "Wintersbite", 195),
    herb(4625, "Firebloom", 205), herb(8831, "Purple Lotus", 210), herb(8836, "Arthas' Tears", 220),
    herb(8838, "Sungrass", 230), herb(8839, "Blindweed", 235), herb(8845, "Ghost Mushroom", 245),
    herb(8846, "Gromsblood", 250), herb(13464, "Golden Sansam", 260), herb(13463, "Dreamfoil", 270),
    herb(13465, "Mountain Silversage", 280), herb(13466, "Plaguebloom", 285), herb(13467, "Icecap", 290),
    herb(13468, "Black Lotus", 300),

    hide(2318, "Light Leather", 1, 10), hide(2319, "Medium Leather", 15, 105), hide(4234, "Heavy Leather", 25, 155),
    hide(4304, "Thick Leather", 35, 205), hide(8170, "Rugged Leather", 45, 255),
}

PP.ZONE_LEVEL = {
    [1411] = { 1, 10 }, [1412] = { 1, 10 }, [1413] = { 10, 25 }, [1416] = { 30, 40 }, [1417] = { 30, 40 },
    [1418] = { 35, 45 }, [1419] = { 45, 55 }, [1420] = { 1, 10 }, [1421] = { 10, 20 }, [1422] = { 51, 58 },
    [1423] = { 53, 60 }, [1424] = { 20, 30 }, [1425] = { 40, 50 }, [1426] = { 1, 10 }, [1427] = { 43, 50 },
    [1428] = { 50, 58 }, [1429] = { 1, 10 }, [1431] = { 18, 30 }, [1432] = { 10, 20 }, [1433] = { 15, 25 },
    [1434] = { 30, 45 }, [1435] = { 35, 45 }, [1436] = { 10, 20 }, [1437] = { 20, 30 }, [1438] = { 1, 10 },
    [1439] = { 10, 20 }, [1440] = { 18, 30 }, [1441] = { 25, 35 }, [1442] = { 15, 27 }, [1443] = { 30, 40 },
    [1444] = { 40, 50 }, [1445] = { 35, 45 }, [1446] = { 40, 50 }, [1447] = { 45, 55 }, [1448] = { 48, 55 },
    [1449] = { 48, 55 }, [1451] = { 55, 60 }, [1452] = { 55, 60 },
    [2521] = { 1, 10 }, [2548] = { 25, 40 },   -- Zephras Isle, Riverglades: guesses
}

--[[ BEST_ZONES: the 1-2 best zones to farm each ore and herb, best first (map IDs).

  Spawn counts alone are misleading: a zone can have many spots that are scattered, far apart or
  full of elites (Desolace for Mithril). These picks come from guides that rate routes, not counts:
    Wowhead "Best Mining and Ore Farming Routes in WoW Classic" (updated 2025-05-05) and
    "Best Herbalism Farming Routes 1-150 / 150-300" -- each lists Best Zones by density and route.
    Icy Veins "WoW Forever Mining / Herbalism Leveling Guide" (updated 2026-11-03) -- Forever routes.
  Rule: zones both guides name come first, then Wowhead's Best Zones in its order. Only zones that
  have spawn spots in Data_Nodes.lua are used (Felwood has none there yet, so it can't be picked).
  Read 2026-11-15. Mobalytics had no ore or herb zone guide.
]]
PP.BEST_ZONES = {
    -- Starter ore and herbs per faction: Icy Veins Forever routes (Alliance / Horde), zones with spawn spots.
    ["Copper Ore"] = { Alliance = { 1426, 1429 }, Horde = { 1411, 1412 } },  -- Dun Morogh, Elwynn | Durotar, Mulgore
    ["Tin Ore"] = { Alliance = { 1437, 1440 }, Horde = { 1413, 1424 } },     -- Wetlands, Ashenvale | Barrens, Hillsbrad
    ["Silver Ore"] = { Alliance = { 1417, 1424 }, Horde = { 1413, 1417 } },  -- Arathi, Hillsbrad | Barrens, Arathi
    ["Iron Ore"] = { 1417, 1441 },            -- Arathi Highlands, Thousand Needles
    ["Gold Ore"] = { 1417, 1441 },            -- Arathi Highlands, Thousand Needles (rare Iron)
    ["Mithril Ore"] = { 1425, 1446 },         -- The Hinterlands, Tanaris
    ["Truesilver Ore"] = { 1425, 1446 },      -- The Hinterlands, Tanaris (rare Mithril)
    ["Thorium Ore"] = { 1449, 1452 },         -- Un'Goro Crater, Winterspring (Rich veins)
    ["Dark Iron Ore"] = { 1428, 1427 },       -- Burning Steppes, Searing Gorge

    ["Peacebloom"] = { Alliance = { 1429, 1426 }, Horde = { 1420, 1412 } },  -- Elwynn, Dun Morogh | Tirisfal, Mulgore
    ["Silverleaf"] = { Alliance = { 1429, 1438 }, Horde = { 1411, 1420 } },  -- Elwynn, Teldrassil | Durotar, Tirisfal
    ["Earthroot"] = { Alliance = { 1426, 1429 }, Horde = { 1420, 1411 } },   -- Dun Morogh, Elwynn | Tirisfal, Durotar
    ["Mageroyal"] = { 1440, 1439 },           -- Ashenvale, Darkshore
    ["Briarthorn"] = { 1431, 1440 },          -- Duskwood, Ashenvale
    ["Stranglekelp"] = { 1440, 1439 },        -- Ashenvale, Darkshore
    ["Bruiseweed"] = { 1442, 1424 },          -- Stonetalon Mountains, Hillsbrad Foothills
    ["Wild Steelbloom"] = { 1417, 1442 },     -- Arathi Highlands, Stonetalon Mountains
    ["Grave Moss"] = { 1431, 1443 },          -- Duskwood, Desolace
    ["Kingsblood"] = { 1434, 1424 },          -- Stranglethorn Vale, Hillsbrad Foothills
    ["Liferoot"] = { 1434, 1437 },            -- Stranglethorn Vale, Wetlands
    ["Fadeleaf"] = { 1417, 1435 },            -- Arathi Highlands, Swamp of Sorrows
    ["Goldthorn"] = { 1434, 1417 },           -- Stranglethorn Vale, Arathi Highlands
    ["Khadgar's Whisker"] = { 1434, 1417 },   -- Stranglethorn Vale, Arathi Highlands
    ["Wintersbite"] = { 1416 },               -- Alterac Mountains
    ["Firebloom"] = { 1446, 1427 },           -- Tanaris, Searing Gorge
    ["Purple Lotus"] = { 1447, 1425 },        -- Azshara, The Hinterlands
    ["Arthas' Tears"] = { 1422 },             -- Western Plaguelands
    ["Sungrass"] = { 1425, 1447 },            -- The Hinterlands, Azshara
    ["Blindweed"] = { 1435 },                 -- Swamp of Sorrows
    ["Ghost Mushroom"] = { 1425 },            -- The Hinterlands
    ["Golden Sansam"] = { 1449, 1447 },       -- Un'Goro Crater, Azshara
    ["Dreamfoil"] = { 1449, 1447 },           -- Un'Goro Crater, Azshara
    ["Mountain Silversage"] = { 1452, 1449 }, -- Winterspring, Un'Goro Crater
    ["Plaguebloom"] = { 1423, 1422 },         -- Eastern, Western Plaguelands
    ["Icecap"] = { 1452 },                    -- Winterspring
    ["Black Lotus"] = { 1428, 1452 },         -- Burning Steppes, Winterspring

    -- Leather: Wowhead "Best Leather Farming and Leveling 1-300 Routes" (top 3 zones per leather, scored on
    -- beast density, camps, competition and elites) and Icy Veins "WoW Forever Skinning Leveling Guide"
    -- (Alliance / Horde routes). Zones both name; per faction where Icy Veins splits them. Read 2026-11-17.
    ["Light Leather"] = { Alliance = { 1432, 1413 }, Horde = { 1413, 1432 } },   -- Loch Modan, The Barrens
    ["Medium Leather"] = { Alliance = { 1437, 1424 }, Horde = { 1424, 1437 } },  -- Wetlands, Hillsbrad Foothills
    ["Heavy Leather"] = { 1434, 1417 },       -- Stranglethorn Vale, Arathi Highlands
    ["Thick Leather"] = { 1446, 1444 },       -- Tanaris, Feralas
    ["Rugged Leather"] = { 1452, 1449 },      -- Winterspring, Un'Goro Crater
}

-- The other faction's starting zones: never a farming pick (guards are hostile and the trip is long).
PP.FACTION_HOME = {
    Alliance = { [1429] = true, [1426] = true, [1438] = true, [1436] = true, [1432] = true, [1439] = true },
    Horde = { [1411] = true, [1412] = true, [1420] = true, [1421] = true },
}
function PP:EnemyHome(map)
    local mine = self.Faction and self:Faction() or "Alliance"
    local other = mine == "Horde" and "Alliance" or "Horde"
    return self.FACTION_HOME[other][map] == true
end

-- 1 = the best zone for this ore / herb, 2 = second best, nil = not a top pick.
function PP:BestZoneRank(itemName, map)
    local zones = self.BEST_ZONES[itemName] or {}
    if zones.Alliance or zones.Horde then zones = zones[self.Faction and self:Faction() or "Alliance"] or {} end
    for rank, id in ipairs(zones) do
        if id == map then return rank end
    end
end
