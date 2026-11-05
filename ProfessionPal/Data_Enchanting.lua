--[[ ProfessionPal - Enchanting (WoW: Forever)
  SOURCES (read 2026-11-04):
    Icy Veins Forever Enchanting Leveling Guide -> 1-225, trainers, ranks
      https://www.icy-veins.com/wow-forever/enchanting-leveling-guide
    Wowhead Forever Enchanting Leveling Guide -> 225-300 (not tested live yet)
      https://www.wowhead.com/forever/profession-leveling-guides/enchanting
  NOTE: Artisan trainer Annora is inside Uldaman (dungeon).
]]
local _, PP = ...

PP:AddProfession{
    key = "enchanting", name = "Enchanting", skillLine = 333, icon = "Interface\\Icons\\Trade_Engraving",
    -- tracker buttons (one click = one cast, like an action bar)
    spells = { { name = "Enchanting" }, { name = "Disenchant", id = 13262 } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 10 },
        { name = "Expert", cap = 225, skill = 125, level = 20 },
        { name = "Artisan", cap = 300, skill = 200, level = 35 },
    },
    trainers = PP.TrainerRanks({
        [1] = {
            A = {
                { "Betty Quin", "Mage Quarter, Stormwind City", 1453, 43.2, 63.8 },
                { "Thonys Pillarstone", "The Great Forge, Ironforge", 1455, 60.6, 44.2 },
                { "Lalina Summermoon", "Craftsmen's Terrace, Darnassus", 1457, 59.6, 12.6 },
                { "Alanna Raveneye", "Oracle Glade, Teldrassil", 1438, 36.8, 34.2 },
                { "Nasalanna Windsinger", "Shen'dar Village, Zephras Isle", 2521, 43.2, 43.2 },
                { "Eaysaa Brightgust", "Valanaar, Zephras Isle", 2521, 59.2, 76.2 },
            },
            H = {
                { "Jhag", "The Drag, Orgrimmar", 1454, 53.6, 38.2 },
                { "Malcomb Wynn", "The Apothecarium, Undercity", 1458, 62.6, 60.4 },
                { "Mot Dawnstrider", "Thunder Bluff", 1456, 45, 38.4 },
                { "Vance Undergloom", "Brill, Tirisfal Glades", 1420, 61.6, 51.6 },
                { "Pa'zula", "Sen'jin Village, Durotar", 1411, 56.4, 73.6 },
                { "Nasalanna Windsinger", "Shen'dar Village, Zephras Isle", 2521, 43.2, 43.2 },
                { "Eaysaa Brightgust", "Valanaar, Zephras Isle", 2521, 59.2, 76.2 },
            },
        },
        [2] = {
            A = {
                { "Lucan Cordell", "Mage Quarter, Stormwind City", 1453, 43, 64.4 },
                { "Gimble Thistlefuzz", "The Great Forge, Ironforge", 1455, 60, 45.4 },
                { "Taladan", "Craftsmen's Terrace, Darnassus", 1457, 58.6, 13.6 },
                { "Xylinnia Starshine", "Feathermoon Stronghold, Feralas", 1444, 31.6, 44.2 },
            },
            H = {
                { "Godan", "The Drag, Orgrimmar", 1454, 53.8, 38.4 },
                { "Lavinia Crowe", "The Apothecarium, Undercity", 1458, 62.6, 61.4 },
                { "Teg Dawnstrider", "Thunder Bluff", 1456, 45, 38 },
            },
        },
        [3] = {
            A = {
                { "Kitta Firewind", "Tower of Azora, Elwynn Forest", 1429, 64.8, 70.6 },
                { "Vanessa Sellers", "Dalaran, Alterac Mountains", 1416, 16.6, 62.6 },
            },
            H = { { "Hgarth", "Sun Rock Retreat, Stonetalon Mountains", 1442, 49.2, 57.2 } },
        },
        [4] = {
            A = { { "Annora", "Inside Uldaman", 1418, 66, 43 } },
            H = { { "Annora", "Inside Uldaman", 1418, 66, 43 } },
        },
    }),
    steps = {
        { from = 1, to = 2, text = "Runed Copper Rod", crafts = 1, total = true,
          mats = { { 6217, 1, "Copper Rod" }, { 247786, 1, "Mote of Magic" } } },
        { from = 2, to = 20, text = "Enchant Bracer - Inferior Stamina", crafts = 18, total = true,
          mats = { { 247786, 18, "Mote of Magic" } } },
        { from = 20, to = 70, text = "Enchant Chest - Inferior Stamina", crafts = 50, total = true,
          mats = { { 10940, 50, "Strange Dust" } } },
        { from = 70, to = 75, text = "Enchant Bracer - Minor Stamina", crafts = 5, total = true,
          mats = { { 10940, 10, "Strange Dust" } } },
        { from = 75, to = 100, text = "Enchant Bracer - Minor Stamina", crafts = 25, total = true,
          mats = { { 10940, 50, "Strange Dust" } } },
        { from = 100, to = 129, text = "Enchant Cloak - Minor Protection", crafts = 36, total = true,
          mats = { { 10940, 72, "Strange Dust" } } },
        { from = 129, to = 130, text = "Runed Silver Rod", crafts = 1, total = true,
          mats = { { 6338, 1, "Silver Rod" }, { 10940, 3, "Strange Dust" }, { 10938, 4, "Lesser Magic Essence" }, { 1210, 1, "Shadowgem" } } },
        { from = 130, to = 150, text = "Enchant Bracer - Lesser Stamina", crafts = 20, total = true,
          mats = { { 11083, 20, "Soul Dust" } } },
        { from = 150, to = 159, text = "Enchant Bracer - Lesser Stamina", crafts = 10, total = true,
          mats = { { 11083, 10, "Soul Dust" } } },
        { from = 159, to = 160, text = "Runed Golden Rod", crafts = 1, total = true,
          mats = { { 11128, 1, "Golden Rod" }, { 5500, 1, "Iridescent Pearl" }, { 11082, 1, "Greater Astral Essence" }, { 11083, 1, "Soul Dust" } } },
        { from = 160, to = 180, text = "Enchant Boots - Lesser Agility", crafts = 20, total = true,
          mats = { { 11083, 20, "Soul Dust" } } },
        { from = 180, to = 204, text = "Enchant Bracer - Strength", crafts = 25, total = true,
          mats = { { 11137, 25, "Vision Dust" } } },
        { from = 204, to = 205, text = "Runed Truesilver Rod", crafts = 1, total = true,
          mats = { { 11144, 1, "Truesilver Rod" }, { 7971, 1, "Black Pearl" }, { 11135, 1, "Greater Mystic Essence" }, { 11137, 1, "Vision Dust" } } },
        { from = 205, to = 225, text = "Enchant Cloak - Greater Defense", crafts = 20, total = true,
          mats = { { 11137, 20, "Vision Dust" } } },
        -- Wowhead 225-300
        { from = 225, to = 230, text = "Enchant Gloves - Agility", crafts = 5, total = true, src = "wowhead",
          mats = { { 11137, 5, "Vision Dust" } } },
        { from = 230, to = 235, text = "Enchant Boots - Stamina", crafts = 5, total = true, src = "wowhead",
          mats = { { 11137, 10, "Vision Dust" } } },
        { from = 235, to = 250, text = "Enchant Chest - Superior Stamina", crafts = 16, total = true, src = "wowhead",
          mats = { { 11137, 48, "Vision Dust" } } },
        { from = 250, to = 265, text = "Lesser Mana Oil", crafts = 15, total = true, src = "wowhead",
          tip = "Buy Formula: Lesser Mana Oil (Lokhtos Darkbargainer).",
          mats = { { 11176, 15, "Dream Dust" }, { 8831, 15, "Purple Lotus" }, { 8925, 15, "Crystal Vial" } } },
        { from = 265, to = 294, text = "Enchant Shield - Greater Stamina", crafts = 30, total = true, src = "wowhead",
          tip = "Buy the formula (Mythrin'dir or Daniel Bartlett).",
          mats = { { 11176, 180, "Dream Dust" } } },
        { from = 294, to = 295, text = "Runed Arcanite Rod", crafts = 1, total = true, src = "wowhead",
          tip = "Buy the formula (Lorelae Wintersong). Keep the rod.",
          mats = { { 16206, 1, "Arcanite Rod" }, { 13926, 1, "Golden Pearl" }, { 16204, 10, "Illusion Dust" }, { 16203, 4, "Greater Eternal Essence" }, { 14343, 4, "Small Brilliant Shard" }, { 14344, 2, "Large Brilliant Shard" } } },
        { from = 295, to = 300, text = "Enchant Cloak - Superior Defense", crafts = 5, total = true, src = "wowhead",
          tip = "Buy the formula (Lorelae Wintersong).",
          mats = { { 16204, 40, "Illusion Dust" } } },
    },
}
