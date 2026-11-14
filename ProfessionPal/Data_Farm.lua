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
