--[[ ProfessionPal - Skinning (WoW: Forever)
  SOURCE (read 2026-11-04): Icy Veins Forever Skinning Leveling Guide (1-300, routes, trainers)
    https://www.icy-veins.com/wow-forever/skinning-leveling-guide
  Gathering ranks: Expert level 10, Artisan level 25.
  Leather items shown are the usual Classic leathers (not from the guide).
]]
local _, PP = ...

local FULL = {
    A = {
        { "Maris Granger", "Old Town, Stormwind City", 1453, 72.3, 62.3 },
        { "Balthus Stoneflayer", "The Great Forge, Ironforge", 1455, 39.6, 32.6 },
        { "Eladriel", "Craftsmen's Terrace, Darnassus", 1457, 64.2, 21.8 },
        { "Helene Peltskinner", "Goldshire, Elwynn Forest", 1429, 46.2, 62.2 },
        { "Radnaal Maneweaver", "Road to Darnassus, Teldrassil", 1438, 42, 50 },
        { "Wilma Ranthal", "Redridge Mountains", 1433, 88.8, 71 },
        { "Jayla", "Silverwind Refuge, Ashenvale", 1440, 50, 67.2 },
        { "Mendalass Tattermend", "Shen'dar Village, Zephras Isle", 2521, 43.2, 43.4 },
        { "Ishlee Breezewhisper", "Valanaar, Zephras Isle", 2521, 59.6, 76 },
    },
    H = {
        { "Thuwd", "The Drag, Orgrimmar", 1454, 63.2, 45.2 },
        { "Mooranta", "Thunder Bluff", 1456, 44.6, 43 },
        { "Killian Hagey", "Rogues' Quarter, Undercity", 1458, 70.4, 59.2 },
        { "Yonn Deepcut", "Bloodhoof Village, Mulgore", 1412, 45.6, 57.8 },
        { "Rand Rhobart", "Tirisfal Glades", 1420, 65.6, 60 },
        { "Dranh", "Camp Taurajo, The Barrens", 1413, 45, 59 },
        { "Malux", "Shadowprey Village, Desolace", 1443, 23.2, 69.8 },
        { "Kulleg Stonehorn", "Camp Mojache, Feralas", 1444, 74.6, 42.8 },
        { "Mendalass Tattermend", "Shen'dar Village, Zephras Isle", 2521, 43.2, 43.4 },
        { "Ishlee Breezewhisper", "Valanaar, Zephras Isle", 2521, 59.6, 76 },
    },
}
local APP = {
    A = PP.Join(FULL.A, {
        { "Riley Peltskinner", "Northshire, Elwynn Forest", 1429, 47, 39.8, junior = true },
        { "Brighid Stormflayer", "Coldridge Valley, Dun Morogh", 1426, 29.2, 67.6, junior = true },
        { "Terunne Bearshaper", "Shadowglen, Teldrassil", 1438, 59.4, 38.6, junior = true },
    }),
    H = PP.Join(FULL.H, {
        { "Kagil", "Valley of Trials, Durotar", 1411, 40.8, 67.8, junior = true },
        { "Nawka Wildsong", "Red Cloud Mesa, Mulgore", 1412, 44.6, 76.8, junior = true },
        { "Margaret Weaver", "Deathknell, Tirisfal Glades", 1420, 32.6, 65.6, junior = true },
    }),
}

local LIGHT, MEDIUM, HEAVY, THICK, RUGGED = 2318, 2319, 4234, 4304, 8170

PP:AddProfession{
    key = "skinning", name = "Skinning", skillLine = 393, icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01", gather = true,
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 0 },
        { name = "Expert", cap = 225, skill = 125, level = 10 },
        { name = "Artisan", cap = 300, skill = 200, level = 25 },
    },
    trainers = PP.TrainerRanks({ [1] = APP, [2] = FULL, [3] = FULL, [4] = FULL }),
    steps = {
        { from = 1, to = 75, text = "Skin beasts", tip = "Start close to town and skin as you quest.",
          nodes = { { "Light Leather", 0, LIGHT } },
          zoneList = { Horde = { { "Durotar", "Mottled Boars and Scorpid Workers in the Valley of Trials." }, { "Mulgore", "Plainstriders on Red Cloud Mesa, then toward Bloodhoof Village." }, { "Tirisfal Glades", "Young Scavengers and Duskbats around Deathknell." }, { "Zephras Isle", "" } },
                       Alliance = { { "Elwynn Forest", "Young Wolves and Timber Wolves northwest of Northshire Abbey." }, { "Dun Morogh", "Ragged wolves in Coldridge Valley." }, { "Teldrassil", "Thistle Boars in Shadowglen." }, { "Zephras Isle", "" } } } },
        { from = 75, to = 125, text = "Skin beasts", tip = "Level 17 beasts at 75, level 18 at 80.",
          nodes = { { "Light Leather", 0, LIGHT }, { "Medium Leather", 0, MEDIUM } },
          zoneList = { Horde = { { "The Barrens", "North of Camp Taurajo, east across the plain." } },
                       Alliance = { { "Loch Modan", "Eastern shore and slopes below Mo'grosh Stronghold." } } } },
        { from = 125, to = 150, text = "Skin beasts", tip = "Train Expert at 125 to go past 150.",
          nodes = { { "Medium Leather", 0, MEDIUM } },
          zoneList = { Horde = { { "Hillsbrad Foothills", "Lions and bears between Hillsbrad Fields and Tarren Mill." } },
                       Alliance = { { "Wetlands", "Circle Whelgar's Excavation Site." }, { "Hillsbrad Foothills", "Lions and bears between Hillsbrad Fields and Tarren Mill." } } } },
        { from = 150, to = 185, text = "Skin beasts", tip = "At 150 you can skin level 30 beasts.",
          nodes = { { "Heavy Leather", 0, HEAVY } },
          zoneList = { Horde = { { "Thousand Needles", "Basilisks and tortoises in the northwest Shimmering Flats." }, { "Arathi Highlands", "Highland Striders west of Refuge Pointe." } },
                       Alliance = { { "Arathi Highlands", "Highland Striders west of Refuge Pointe." }, { "Thousand Needles", "Basilisks and tortoises in the northwest Shimmering Flats." } } } },
        { from = 185, to = 225, text = "Skin beasts", tip = "Beasts up to level 37 first, then higher as you go.",
          nodes = { { "Heavy Leather", 0, HEAVY }, { "Thick Leather", 0, THICK } },
          zoneList = { Horde = { { "Dustwallow Marsh", "Vicejaws south of Brackenwall Village." }, { "Badlands", "South of Angor Fortress." }, { "Stranglethorn Vale", "Lashtail Raptors by Lake Nazferiti." } },
                       Alliance = { { "Stranglethorn Vale", "Lashtail Raptors by Lake Nazferiti." }, { "Badlands", "South of Angor Fortress." }, { "Dustwallow Marsh", "Vicejaws south of Brackenwall Village." } } } },
        { from = 225, to = 250, text = "Skin beasts", tip = "Open desert in Tanaris or yetis in Feralas.",
          nodes = { { "Thick Leather", 0, THICK } },
          zoneList = { Horde = { { "Tanaris", "Southwest of Gadgetzan into the Abyssal Sands." }, { "Feralas", "Feral Scar Vale, south of Dire Maul." } },
                       Alliance = { { "Feralas", "Feral Scar Vale, south of Dire Maul." }, { "Tanaris", "Southwest of Gadgetzan into the Abyssal Sands." } } } },
        { from = 250, to = 275, text = "Skin beasts", tip = "Ravasaurs in Un'Goro Crater.",
          nodes = { { "Thick Leather", 0, THICK }, { "Rugged Leather", 0, RUGGED } },
          zoneList = { Horde = { { "Un'Goro Crater", "From Tanaris, north along the west edge of the marsh." }, { "Felwood", "Western road around Irontree Woods." } },
                       Alliance = { { "Un'Goro Crater", "From Tanaris, north along the west edge of the marsh." }, { "Felwood", "Western road around Irontree Woods." } } } },
        { from = 275, to = 300, text = "Skin beasts", tip = "You can reach 300 on beasts below level 60.",
          nodes = { { "Rugged Leather", 0, RUGGED } },
          zoneList = { Horde = { { "Western Plaguelands", "Just east of Dalson's Tears." }, { "Winterspring", "North from Starfall Village to Frostsaber Rock." } },
                       Alliance = { { "Winterspring", "North from Starfall Village to Frostsaber Rock." }, { "Western Plaguelands", "Just east of Dalson's Tears." } } } },
    },
}
