--[[ ProfessionPal - Alchemy (WoW: Forever)
  SOURCES (read 2026-11-04):
    Icy Veins Forever Alchemy Leveling Guide -> 1-225 steps, trainers, ranks
      https://www.icy-veins.com/wow-forever/alchemy-leveling-guide
    Wowhead Forever Alchemy Leveling Guide 1-300 -> 225-300 steps (not tested live yet)
      https://www.wowhead.com/forever/profession-leveling-guides/alchemy
  NOT VERIFIED: Zephras Isle map ID (Icy Veins lists 2991 here, 2521 on other pages).
  Trainer row: { name, place, mapID, x, y }
]]
local _, PP = ...

PP:AddProfession{
    key = "alchemy", name = "Alchemy", skillLine = 171, icon = "Interface\\Icons\\Trade_Alchemy",
    -- tracker buttons (one click = one cast, like an action bar)
    spells = { { name = "Alchemy" } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 10 },
        { name = "Expert", cap = 225, skill = 125, level = 20 },
        { name = "Artisan", cap = 300, skill = 200, level = 35 },
    },
    trainers = PP.TrainerRanks({
        [1] = {
            A = {
                { "Tel'Athir", "Mage Quarter, Stormwind City", 1453, 55.5, 85.6 },
                { "Vosur Brakthel", "Tinker Town, Ironforge", 1455, 66.3, 55.7 },
                { "Milla Fairancora", "Craftsmen's Terrace, Darnassus", 1457, 55.4, 22.7 },
                { "Cyndra Kindwhisper", "Dolanaar, Teldrassil", 1438, 57.6, 60.6 },
                { "Alchemist Mallory", "Hills between Stormwind and Northshire, Elwynn Forest", 1429, 39.8, 48.6 },
                { "Ghak Healtouch", "Thelsamar, Loch Modan", 1432, 37.1, 49.4 },
                { "Iaadaria Bitterwind", "Valanaar, Zephras Isle", 2991, 66.2, 79.6 },
                { "Nyassa Swiftdraught", "Shen'dar Village, Zephras Isle", 2991, 43.8, 43.6 },
                { "Valiena Swiftgale", "Valanaar, Zephras Isle", 2991, 59.2, 76.2 },
            },
            H = {
                { "Whuut", "The Drag, Orgrimmar", 1454, 55.8, 32.9 },
                { "Doctor Martin Felben", "The Apothecarium, Undercity", 1458, 46.6, 74.1 },
                { "Kray", "Middle Rise, Thunder Bluff", 1456, 47, 34.6 },
                { "Carolai Anise", "Brill, Tirisfal Glades", 1420, 59.4, 52.2 },
                { "Miao'zan", "Sen'jin Village, Durotar", 1411, 55.4, 74 },
                { "Nyassa Swiftdraught", "Shen'dar Village, Zephras Isle", 2991, 43.8, 43.6 },
                { "Valiena Swiftgale", "Valanaar, Zephras Isle", 2991, 59.2, 76.2 },
            },
        },
        [2] = {
            A = {
                { "Lilyssia Nightbreeze", "Mage Quarter, Stormwind City", 1453, 55.7, 86.1 },
                { "Sylvanna Forestmoon", "Craftsmen's Terrace, Darnassus", 1457, 56.4, 24.2 },
                { "Tally Berryfizz", "Tinker Town, Ironforge", 1455, 67.2, 54.2 },
                { "Alchemist Narett", "Theramore Isle, Dustwallow Marsh", 1445, 64, 47.7 },
                { "Kylanna", "Silverwind Refuge, Ashenvale", 1440, 50.9, 67.1 },
                { "Jaxin Chong", "Booty Bay, Stranglethorn Vale", 1434, 28, 78 },
            },
            H = {
                { "Yelmak", "The Drag, Orgrimmar", 1454, 56.8, 33 },
                { "Doctor Marsh", "The Apothecarium, Undercity", 1458, 50.9, 74.6 },
                { "Bena Winterhoof", "Middle Rise, Thunder Bluff", 1456, 46.6, 33.2 },
                { "Serge Hinott", "Tarren Mill, Hillsbrad Foothills", 1424, 61.6, 19.2 },
                { "Jaxin Chong", "Booty Bay, Stranglethorn Vale", 1434, 28, 78 },
            },
        },
        [3] = {
            A = {
                { "Ainethil", "Craftsmen's Terrace, Darnassus", 1457, 54.9, 24 },
                { "Linzy Blackbolt", "Dalaran, Alterac Mountains", 1416, 18.6, 62.4 },
                { "Patricia Egan", "Dalaran, Alterac Mountains", 1416, 18.6, 62.4 },
            },
            H = {
                { "Doctor Herbert Halsey", "The Apothecarium, Undercity", 1458, 47.8, 73.3 },
            },
        },
        [4] = {
            A = {
                { "Kylanna Windwhisper", "Feathermoon Stronghold, Feralas", 1444, 32.6, 43.8 },
                { "Master Mycologist Shurome", "Emerald Sanctuary, Felwood", 1448, 51.4, 82 },
            },
            H = {
                { "Rogvar", "Stonard, Swamp of Sorrows", 1435, 48.5, 55.8 },
                { "Master Mycologist Shurome", "Emerald Sanctuary, Felwood", 1448, 51.4, 82 },
            },
        },
    }),
    steps = {
        { from = 1, to = 10, text = "Minor Arcane Elixir", crafts = 9, total = true,
          mats = { { 2447, 9, "Peacebloom" }, { 3371, 9, "Empty Vial" } } },
        { from = 10, to = 55, text = "Elixir of Minor Defense", crafts = 45, total = true,
          mats = { { 765, 45, "Silverleaf" }, { 2447, 45, "Peacebloom" }, { 3371, 45, "Empty Vial" } } },
        { from = 55, to = 65, text = "Minor Mana Potion", crafts = 10, total = true,
          mats = { { 785, 10, "Mageroyal" }, { 2447, 10, "Peacebloom" }, { 3371, 10, "Empty Vial" } } },
        { from = 65, to = 75, text = "Elixir of Minor Fortitude", crafts = 10, total = true,
          mats = { { 2449, 20, "Earthroot" }, { 2447, 10, "Peacebloom" }, { 3371, 10, "Empty Vial" } } },
        { from = 75, to = 90, text = "Elixir of Minor Fortitude", crafts = 17, total = true,
          mats = { { 2449, 34, "Earthroot" }, { 2447, 17, "Peacebloom" }, { 3371, 17, "Empty Vial" } } },
        { from = 90, to = 120, text = "Elixir of Wisdom", crafts = 30, total = true,
          mats = { { 785, 30, "Mageroyal" }, { 2450, 60, "Briarthorn" }, { 3371, 30, "Empty Vial" } } },
        { from = 120, to = 150, text = "Lesser Mana Potion", crafts = 31, total = true,
          mats = { { 785, 31, "Mageroyal" }, { 3820, 31, "Stranglekelp" }, { 3371, 31, "Empty Vial" } } },
        { from = 150, to = 160, text = "Lesser Mana Potion", crafts = 14, total = true,
          mats = { { 785, 14, "Mageroyal" }, { 3820, 14, "Stranglekelp" }, { 3371, 14, "Empty Vial" } } },
        { from = 160, to = 185, text = "Mana Potion", crafts = 26, total = true,
          mats = { { 3356, 26, "Kingsblood" }, { 3820, 26, "Stranglekelp" }, { 3372, 26, "Leaded Vial" } } },
        { from = 185, to = 205, text = "Elixir of Agility", crafts = 20, total = true,
          mats = { { 3821, 20, "Goldthorn" }, { 3820, 20, "Stranglekelp" }, { 3372, 20, "Leaded Vial" } } },
        { from = 205, to = 225, text = "Greater Mana Potion", crafts = 21, total = true,
          mats = { { 3821, 21, "Goldthorn" }, { 3358, 21, "Khadgar's Whisker" }, { 3372, 21, "Leaded Vial" } } },
        -- Wowhead 225-300
        { from = 225, to = 226, text = "Philosopher's Stone", crafts = 1, total = true, src = "wowhead",
          tip = "Buy Recipe: Philosopher's Stone (Alchemist Pestlezugg). Keep the stone.",
          mats = { { 3575, 4, "Iron Bar" }, { 9262, 1, "Black Vitriol" }, { 8831, 4, "Purple Lotus" }, { 4625, 4, "Firebloom" } } },
        { from = 226, to = 240, text = "Greater Mana Potion", crafts = 20, total = true, src = "wowhead",
          mats = { { 3358, 20, "Khadgar's Whisker" }, { 3821, 20, "Goldthorn" }, { 3372, 20, "Leaded Vial" } } },
        { from = 240, to = 260, text = "Draught of Detect Undead", crafts = 23, total = true, src = "wowhead",
          mats = { { 8836, 23, "Arthas' Tears" }, { 8925, 23, "Crystal Vial" } } },
        { from = 260, to = 270, text = "Superior Mana Potion", crafts = 10, total = true, src = "wowhead",
          tip = "Buy Recipe: Superior Mana Potion (Ulthir Algernon).",
          mats = { { 8838, 20, "Sungrass" }, { 8839, 20, "Blindweed" }, { 8925, 10, "Crystal Vial" } } },
        { from = 270, to = 300, text = "Major Discolored Healing Potion", crafts = 31, total = true, src = "wowhead",
          tip = "Taught after a short quest: the Odd Child (Westfall) or Apothecary Renferrel (Silverpine).",
          mats = { { 8925, 31, "Crystal Vial" }, { 13466, 31, "Plaguebloom" }, { 730, 31, "Murloc Eye" } } },
    },
}
