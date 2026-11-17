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
local function hide(id, name, level) return { id = id, name = name, prof = "skinning", skill = 1, level = level } end

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

    hide(2318, "Light Leather", 1), hide(2319, "Medium Leather", 15), hide(4234, "Heavy Leather", 25),
    hide(4304, "Thick Leather", 35), hide(8170, "Rugged Leather", 45),
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
    ["Copper Ore"] = { 1426, 1411 },          -- Dun Morogh, Durotar
    ["Tin Ore"] = { 1413, 1437 },             -- The Barrens, Wetlands
    ["Silver Ore"] = { 1413, 1417 },          -- The Barrens, Arathi Highlands
    ["Iron Ore"] = { 1417, 1441 },            -- Arathi Highlands, Thousand Needles
    ["Gold Ore"] = { 1417, 1441 },            -- Arathi Highlands, Thousand Needles (rare Iron)
    ["Mithril Ore"] = { 1425, 1446 },         -- The Hinterlands, Tanaris
    ["Truesilver Ore"] = { 1425, 1446 },      -- The Hinterlands, Tanaris (rare Mithril)
    ["Thorium Ore"] = { 1449, 1452 },         -- Un'Goro Crater, Winterspring (Rich veins)
    ["Dark Iron Ore"] = { 1428, 1427 },       -- Burning Steppes, Searing Gorge

    ["Peacebloom"] = { 1420, 1412 },          -- Tirisfal Glades, Mulgore
    ["Silverleaf"] = { 1411, 1420 },          -- Durotar, Tirisfal Glades
    ["Earthroot"] = { 1420, 1411 },           -- Tirisfal Glades, Durotar
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
}

-- 1 = the best zone for this ore / herb, 2 = second best, nil = not a top pick.
function PP:BestZoneRank(itemName, map)
    for rank, id in ipairs(self.BEST_ZONES[itemName] or {}) do
        if id == map then return rank end
    end
end

-- Targeted leather farms, reviewed 2026-11-16. Rankings are curated recommendations,
-- not measured Forever yields. Classic farming evidence is cross-checked against
-- Forever leveling guidance where available. No spawn coordinates are inferred.
-- Sources and ranking rationale: docs/skinning-farms.md (development documentation).
PP.SKINNING_FARMS = {
    ["Light Leather"] = {
        { map = 1439, rank = { Alliance = 1, Horde = 2 }, skill = 60, maxSkill = 100, levels = "16-20",
          tip = "Southern Darkshore: Moonstalker Matriarchs, Giant Foreststriders and Grizzled Thistle Bears. A lower-level alternative to Taurajo.", source = "WP-Light; WH-Forever" },
        { map = 1413, rank = { Alliance = 2, Horde = 1 }, skill = 100, maxSkill = 110, levels = "20-22",
          tip = "Around Camp Taurajo: Thunderhawk Cloudscrapers, Thunderheads and Zhevra Coursers. Stay clear of Horde guards as Alliance; some Medium Leather also drops.", source = "WP-Light; WH-Classic" },
    },
    ["Medium Leather"] = {
        { map = 1431, rank = { Alliance = 1 }, skill = 140, maxSkill = 155, levels = "28-31",
          tip = "Duskwood: skin worgen at Rotting Orchard and Roland's Doom, alternating the orchard and cave. Watch for respawns inside.", source = "WP-Medium; WH-Forever" },
        { map = 1440, rank = { Horde = 1 }, skill = 140, maxSkill = 150, levels = "28-30",
          tip = "Ashenvale: hunt Terrowulf Fleshrippers and Shadow Weavers along the approach to their cave and inside. Clear the approach again when the cave is empty.", source = "WP-Medium; WH-Forever" },
        { map = 1437, rank = { Alliance = 2 }, skill = 125, maxSkill = 135, levels = "25-27",
          tip = "Whelgar's Excavation Site: skin Mottled Scytheclaws and Razormaws on the dig floor. Lower-level alternative to Duskwood; higher raptors need 135 Skinning.", source = "WP-Medium; IV-Forever; WH-Classic" },
        { map = 1424, rank = { Horde = 2 }, skill = 150, maxSkill = 160, levels = "30-32",
          tip = "Foothill Caverns: Cave Yetis and Ferocious Yetis. A compact farm, but fast kills can leave you waiting for respawns. Avoid the roaming elite yeti.", source = "WP-Medium; WH-Classic" },
    },
    ["Heavy Leather"] = {
        { map = 1434, rank = 1, skill = 200, maxSkill = 205, levels = "40-41",
          tip = "Jungle north of Gurubashi Arena: Jungle Stalkers and Young Jungle Stalkers. Good for targeting Heavy Leather; expect competition and spread-out kills. Stay outside the arena.", source = "WP-Heavy; WH-Classic; IV-Forever" },
        { map = 1417, rank = 2, skill = 150, maxSkill = 185, levels = "30-37",
          tip = "Arathi raptors: begin west of Refuge Pointe, then move farther from the main road for higher-level raptors. Lower-level alternative; expect Medium Leather too.", source = "WH-Classic; IV-Forever" },
    },
    ["Thick Leather"] = {
        { map = 1449, rank = 1, skill = 240, maxSkill = 255, levels = "48-51",
          tip = "Southern Un'Goro marsh: hunt Ravasaurs, Runners, Hunters and Venomhides. A targeted Thick Leather farm with some Rugged Leather; avoid wandering elite Devilsaurs.", source = "WP-Thick; IV-Forever" },
        { map = 1445, rank = 2, skill = 200, maxSkill = 220, levels = "40-44",
          tip = "Dustwallow: skin dragonkin between Stonemaul Ruins and the Den of Flame. Lower-level mixed Thick/Heavy farm; use it when Un'Goro is too tough or crowded.", source = "WP-Thick; WP-Heavy" },
    },
    ["Rugged Leather"] = {
        { map = 1452, rank = 1, skill = 275, maxSkill = 290, levels = "55-58",
          tip = "South of Everlook: Ice Thistle Yetis, Matriarchs and Patriarchs outside and inside the cave. A concentrated farm, often contested; check mob levels before pulling.", source = "WP-Rugged; WH-Classic" },
        { map = 1449, rank = 2, skill = 260, maxSkill = 275, levels = "52-55",
          tip = "Western Un'Goro: skin Elder Diemetradons and Frenzied Pterrordaxes. A mixed Rugged/Thick alternative; avoid elite Devilsaurs and beware of pterrordax fear pulling extra enemies.", source = "WH-Classic; WP-Rugged" },
    },
}

function PP:SkinningFarmRank(farm)
    if type(farm.rank) == "table" then return farm.rank[self:Faction()] end
    return farm.rank
end


-- Recorded Forever NPC spawn points (not zone centers or a verified walking loop).
-- Selected existing point nearest the spawn-set centroid. Wowhead NPC pages, 2026-11-16:
-- 2165 Grizzled Thistle Bear; 259055 Wildplains Huntress; 251245 Prideclaw.
for _, farm in ipairs(PP.SKINNING_FARMS["Light Leather"]) do
    if farm.map == 1439 then
        farm.x, farm.y, farm.npc = 40, 79.8, 2165
        farm.tip = "Start at the recorded Grizzled Thistle Bear location in southern Darkshore, then hunt nearby bears, foreststriders and moonstalkers. The pin marks a hunting area, not a live beast."
    end
end
local function foreverFarm(map, x, y, npc, skill, maxSkill, levels, tip)
    return { map = map, x = x, y = y, npc = npc, skill = skill, maxSkill = maxSkill,
             levels = levels, tip = tip, expansion = "Forever", source = "Wowhead Forever NPC " .. npc }
end
-- Available alternatives, not claimed to outperform the curated best farms.
table.insert(PP.SKINNING_FARMS["Light Leather"], foreverFarm(2521, 43.4, 47.4, 251245, 1, 1, "5-6",
    "Zephras Isle: Prideclaws around Shen'dar Village. Skinning records include Light Leather and Ruined Leather Scraps; expect scraps at these low levels."))
for _, material in ipairs({ "Heavy Leather", "Thick Leather" }) do
    table.insert(PP.SKINNING_FARMS[material], foreverFarm(2548, 59.3, 53.9, 259055, 190, 195, "38-39",
        "Riverglades: Wildplains Huntresses between Terral's Watch and Rog'mar. Recorded skins include Heavy and Thick Leather; this is mainly a Heavy Leather farm, with Thick as a secondary yield. Hunt around the marked area."))
end
