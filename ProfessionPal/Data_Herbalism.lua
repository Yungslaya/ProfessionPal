--[[ ProfessionPal - Herbalism (WoW: Forever)
  SOURCE (read 2026-11-04): Icy Veins Forever Herbalism Leveling Guide (1-300, routes, trainers)
    https://www.icy-veins.com/wow-forever/herbalism-leveling-guide
  Gathering ranks: Expert needs level 10, Artisan level 25 (Icy Veins profession overview).
  Starting-area trainers (first 3 of each faction) teach Apprentice only.
]]
local _, PP = ...

local FULL = {
    A = {
        { "Tannysa", "Mage Quarter, Stormwind City", 1453, 44.8, 77 },
        { "Shylamiir", "The Park, Stormwind City", 1453, 15.2, 49.8 },
        { "Reyna Stonebranch", "The Great Forge, Ironforge", 1455, 55.6, 58.4 },
        { "Firodren Mooncaller", "Temple Gardens, Darnassus", 1457, 48, 68.4 },
        { "Malorne Bladeleaf", "Dolanaar, Teldrassil", 1438, 57.6, 60.6 },
        { "Herbalist Pomeroy", "Stormwind gates, Elwynn Forest", 1429, 39.8, 48.4 },
        { "Kali Healtouch", "Thelsamar, Loch Modan", 1432, 36.6, 48.4 },
        { "Alma Jainrose", "Lakeshire, Redridge Mountains", 1433, 21.8, 45.8 },
        { "Cylania Rootstalker", "Silverwind Refuge, Ashenvale", 1440, 50.6, 67 },
        { "Telurinon Moonshadow", "Menethil Harbor, Wetlands", 1437, 8, 55.8 },
        { "Brant Jasperbloom", "Theramore Isle, Dustwallow Marsh", 1445, 64, 47.6 },
        { "Edward Egan", "Dalaran, Alterac Mountains", 1416, 18.4, 63.2 },
        { "Halassa Fernbreeze", "Shen'dar Village, Zephras Isle", 2521, 43, 43.6 },
        { "Syriel Nightrain", "Valanaar, Zephras Isle", 2521, 57.8, 75.4 },
        { "Flora Silverwind", "Booty Bay, Stranglethorn Vale", 1434, 27.6, 77.8 },
        { "Malvor", "Nighthaven, Moonglade", 1450, 45.6, 46.8 },
    },
    H = {
        { "Jandi", "The Drag, Orgrimmar", 1454, 55.6, 39.6 },
        { "Komin Winterhoof", "Thunder Bluff", 1456, 49.8, 39.8 },
        { "Martha Alliestar", "Apothecarium, Undercity", 1458, 54.6, 50.4 },
        { "Mishiki", "Sen'jin Village, Durotar", 1411, 55.4, 75 },
        { "Faruza", "Brill, Tirisfal Glades", 1420, 59.8, 52 },
        { "Aranae Venomblood", "Tarren Mill, Hillsbrad Foothills", 1424, 61.6, 19.6 },
        { "Angrun", "Grom'gol Base Camp, Stranglethorn Vale", 1434, 32.2, 27.6 },
        { "Ruw", "Camp Mojache, Feralas", 1444, 76, 43.4 },
        { "Halassa Fernbreeze", "Shen'dar Village, Zephras Isle", 2521, 43, 43.6 },
        { "Syriel Nightrain", "Valanaar, Zephras Isle", 2521, 57.8, 75.4 },
        { "Flora Silverwind", "Booty Bay, Stranglethorn Vale", 1434, 27.6, 77.8 },
        { "Malvor", "Nighthaven, Moonglade", 1450, 45.6, 46.8 },
    },
}
local APP = {
    A = PP.Join(FULL.A, {
        { "Nancy Songflower", "Northshire, Elwynn Forest", 1429, 52.4, 43.8, junior = true },
        { "Emrys Flintbeard", "Coldridge Valley, Dun Morogh", 1426, 28.8, 66.6, junior = true },
        { "Eleyna Duskbreeze", "Shadowglen, Teldrassil", 1438, 59.8, 41.4, junior = true },
    }),
    H = PP.Join(FULL.H, {
        { "Zor'la", "Valley of Trials, Durotar", 1411, 42.6, 67.4, junior = true },
        { "Garan Sunstrider", "Red Cloud Mesa, Mulgore", 1412, 44.2, 77.8, junior = true },
        { "Florence Nightshade", "Deathknell, Tirisfal Glades", 1420, 32.4, 65.2, junior = true },
    }),
}

PP:AddProfession{
    key = "herbalism", name = "Herbalism", skillLine = 182, icon = "Interface\\Icons\\Spell_Nature_NatureTouchGrow", gather = true,
    spells = { { name = "Find Herbs", id = 2383 } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 0 },
        { name = "Expert", cap = 225, skill = 125, level = 10 },
        { name = "Artisan", cap = 300, skill = 200, level = 25 },
    },
    trainers = PP.TrainerRanks({ [1] = APP, [2] = FULL, [3] = FULL, [4] = FULL }),
    steps = {
        { from = 1, to = 70, text = "Pick herbs", tip = "Peacebloom in clearings, Silverleaf by trees. Earthroot from 15.",
          nodes = { { "Peacebloom", 0, 2447 }, { "Silverleaf", 0, 765 }, { "Earthroot", 0, 2449 } },
          zoneList = { Horde = { { "Durotar", "From Sen'jin Village, west side of the road to Razor Hill." }, { "Mulgore", "From Bloodhoof Village, around Stonebull Lake." }, { "Tirisfal Glades", "From Brill, northwest, then the fields north of Brightwater Lake." }, { "Zephras Isle", "From Shen'dar Village, north along the inlet toward Thendal Village." } },
                       Alliance = { { "Elwynn Forest", "From Goldshire, the trees above Mirror Lake." }, { "Dun Morogh", "From Kharanos north, then east toward Gol'Bolar Quarry." }, { "Teldrassil", "East of Dolanaar, around Starbreeze Village." }, { "Zephras Isle", "From Shen'dar Village, north along the inlet toward Thendal Village." } } } },
        { from = 70, to = 115, text = "Pick herbs", tip = "Mageroyal and Briarthorn from 70. Stranglekelp at 85, Bruiseweed at 100.",
          nodes = { { "Mageroyal", 0, 785 }, { "Briarthorn", 0, 2450 }, { "Stranglekelp", 0, 3820 }, { "Bruiseweed", 0, 2453 } },
          zoneList = { Horde = { { "The Barrens", "West of the Crossroads, then north before the mountains." }, { "Silverpine Forest", "East of the Sepulcher, fields west of Lordamere Lake." } },
                       Alliance = { { "Darkshore", "South of Auberdine, inland side of the road." }, { "Loch Modan", "From Thelsamar to the eastern bank of the Loch." } } } },
        { from = 115, to = 170, text = "Pick herbs", tip = "Wild Steelbloom on slopes, Bruiseweed on the way. Then Kingsblood and Liferoot.",
          nodes = { { "Wild Steelbloom", 0, 3355 }, { "Bruiseweed", 0, 2453 }, { "Kingsblood", 0, 3356 }, { "Liferoot", 0, 3357 } },
          zoneList = { Horde = { { "Hillsbrad Foothills", "From the bridge by Tarren Mill, follow the east bank north." }, { "Stonetalon Mountains", "Trail northeast into Windshear Crag." } },
                       Alliance = { { "Wetlands", "Road north of Whelgar's Excavation Site." }, { "Hillsbrad Foothills", "From the bridge by Tarren Mill, follow the east bank north." }, { "Stonetalon Mountains", "Trail northeast into Windshear Crag." } } } },
        { from = 170, to = 205, text = "Pick herbs", tip = "Goldthorn on rocky slopes, Fadeleaf around trees.",
          nodes = { { "Goldthorn", 0, 3821 }, { "Fadeleaf", 0, 3818 }, { "Khadgar's Whisker", 0, 3358 } },
          zoneList = { Horde = { { "Arathi Highlands", "Ponds north of Stromgarde Keep." }, { "Stranglethorn Vale", "Upriver to Lake Nazferiti." } },
                       Alliance = { { "Arathi Highlands", "Ponds north of Stromgarde Keep." }, { "Stranglethorn Vale", "Upriver to Lake Nazferiti." } } } },
        { from = 205, to = 230, text = "Pick herbs", tip = "Firebloom from 205 in Tanaris or Searing Gorge.",
          nodes = { { "Firebloom", 0, 4625 }, { "Purple Lotus", 0, 8831 }, { "Wintersbite", 0, 3819 } },
          zoneList = { Horde = { { "Tanaris", "Sand south of Dunemaul Compound, then toward Southmoon Ruins." }, { "Searing Gorge", "Southern rim of the Cauldron." }, { "Alterac Mountains", "Snowfields southeast of the Ruins of Alterac." } },
                       Alliance = { { "Tanaris", "Sand south of Dunemaul Compound, then toward Southmoon Ruins." }, { "Searing Gorge", "Southern rim of the Cauldron." }, { "Alterac Mountains", "Snowfields southeast of the Ruins of Alterac." } } } },
        { from = 230, to = 270, text = "Pick herbs", tip = "Start with Sungrass.",
          nodes = { { "Sungrass", 0, 8838 }, { "Purple Lotus", 0, 8831 }, { "Ghost Mushroom", 0, 8845 }, { "Golden Sansam", 0, 13464 } },
          zoneList = { Horde = { { "Feralas", "South of Dire Maul, into the High Wilderness." }, { "The Hinterlands", "From Skulk Rock, east across the grass below the river." } },
                       Alliance = { { "The Hinterlands", "From Skulk Rock, east across the grass below the river." }, { "Feralas", "South of Dire Maul, into the High Wilderness." } } } },
        { from = 270, to = 300, text = "Pick herbs", tip = "Dreamfoil from 270.",
          nodes = { { "Dreamfoil", 0, 13463 }, { "Mountain Silversage", 0, 13465 }, { "Plaguebloom", 0, 13466 } },
          zoneList = { Horde = { { "Felwood", "Northern road through Irontree Woods toward Felpaw Village." }, { "Eastern Plaguelands", "North from the Darrowshire junction, then east to Corin's Crossing." } },
                       Alliance = { { "Eastern Plaguelands", "North from the Darrowshire junction, then east to Corin's Crossing." }, { "Felwood", "Northern road through Irontree Woods toward Felpaw Village." } } } },
    },
}
