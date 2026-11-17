--[[ ProfessionPal - Tailoring (WoW: Forever)
  SOURCES (read 2026-11-04):
    Icy Veins Forever Tailoring Leveling Guide -> 1-225, trainers, ranks
      https://www.icy-veins.com/wow-forever/tailoring-leveling-guide
    Wowhead Forever Tailoring Leveling Guide -> 225-300 (not tested live yet)
      https://www.wowhead.com/forever/profession-leveling-guides/tailoring
  NOTE: Runecloth Cuffs pattern comes from Pexmit (rare demon, Mount Hyjal).
]]
local _, PP = ...

PP:AddProfession{
    key = "tailoring", name = "Tailoring", skillLine = 197, icon = "Interface\\Icons\\Trade_Tailoring",
    -- tracker buttons (one click = one cast, like an action bar)
    spells = { { name = "Tailoring" } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 10 },
        { name = "Expert", cap = 225, skill = 125, level = 20 },
        { name = "Artisan", cap = 300, skill = 200, level = 35 },
    },
    trainers = PP.TrainerRanks({
        [1] = {
            A = {
                { "Lawrence Schneider", "Mage Quarter, Stormwind City", 1453, 53.4, 81.6 },
                { "Uthrar Threx", "The Great Forge, Ironforge", 1455, 43.6, 28.2 },
                { "Trianna", "Craftsmen's Terrace, Darnassus", 1457, 63.6, 21.6 },
                { "Eldrin", "Eastvale Logging Camp, Elwynn Forest", 1429, 79.2, 69 },
                { "Grondal Moonbreeze", "Auberdine, Darkshore", 1439, 38.2, 40.6 },
            },
            H = {
                { "Snang", "The Drag, Orgrimmar", 1454, 63, 49.6 },
                { "Victor Ward", "Magic Quarter, Undercity", 1458, 70.2, 29.6 },
                { "Vhan", "Central Bluff, Thunder Bluff", 1456, 44, 44.6 },
                { "Bowen Brisboise", "Cold Hearth Manor, Tirisfal Glades", 1420, 52.6, 55.6 },
                { "Kil'hala", "The Crossroads, The Barrens", 1413, 52.2, 31.6 },
            },
        },
        [2] = {
            A = {
                { "Sellandus", "Mage Quarter, Stormwind City", 1453, 52.2, 83.5 },
                { "Jormund Stonebrow", "The Great Forge, Ironforge", 1455, 43.6, 28.2 },
                { "Me'lynn", "Craftsmen's Terrace, Darnassus", 1457, 62.6, 22.6 },
                { "Grarnik Goodstitch", "Booty Bay, Stranglethorn Vale", 1434, 28.6, 76.8 },
                { "Taleen Shimmerthread", "Shen'dar Village, Zephras Isle", 2521, 44.8, 44.2 },
                { "Othesia Evengale", "Valanaar, Zephras Isle", 2521, 64.4, 81 },
            },
            H = {
                { "Magar", "The Drag, Orgrimmar", 1454, 63.4, 50 },
                { "Rhiannon Davis", "Magic Quarter, Undercity", 1458, 70.6, 29.6 },
                { "Tepa", "Central Bluff, Thunder Bluff", 1456, 44.2, 45 },
                { "Mahani", "Camp Taurajo, The Barrens", 1413, 44.8, 59.4 },
                { "Grarnik Goodstitch", "Booty Bay, Stranglethorn Vale", 1434, 28.6, 76.8 },
                { "Taleen Shimmerthread", "Shen'dar Village, Zephras Isle", 2521, 44.8, 44.2 },
                { "Othesia Evengale", "Valanaar, Zephras Isle", 2521, 64.4, 81 },
            },
        },
        [3] = {
            A = {
                { "Georgio Bolero", "Mage Quarter, Stormwind City", 1453, 53.1, 81.4 },
                { "Charles Worth", "Dalaran, Alterac Mountains", 1416, 17.8, 60.6 },
            },
            H = { { "Josef Gregorian", "Magic Quarter, Undercity", 1458, 70.6, 30.6 } },
        },
        [4] = {
            A = { { "Timothy Worthington", "Theramore Isle, Dustwallow Marsh", 1445, 66.2, 51.6 } },
            H = { { "Daryl Stack", "Tarren Mill, Hillsbrad Foothills", 1424, 63.6, 20.8 } },
        },
    }),
    steps = {
        { from = 1, to = 30, text = "Bolt of Linen Cloth", crafts = 30, total = true, makes = 2996,
          mats = { { 2589, 60, "Linen Cloth" } } },
        { from = 30, to = 55, text = "Linen Belt", crafts = 28, total = true,
          mats = { { 2996, 28, "Bolt of Linen Cloth" }, { 2320, 28, "Coarse Thread" } } },
        { from = 55, to = 75, text = "Bolt of Woolen Cloth", crafts = 22, total = true, makes = 2997,
          mats = { { 2592, 66, "Wool Cloth" } } },
        { from = 75, to = 80, text = "Bolt of Woolen Cloth", crafts = 10, total = true, makes = 2997,
          mats = { { 2592, 30, "Wool Cloth" } } },
        { from = 80, to = 100, text = "Woolen Cape", crafts = 32, total = true,
          mats = { { 2997, 32, "Bolt of Woolen Cloth" }, { 2321, 32, "Fine Thread" } } },
        { from = 100, to = 120, text = "Bolt of Silk Cloth", crafts = 233, total = true, makes = 4305,
          mats = { { 4306, 932, "Silk Cloth" } }, tip = "Make them all. Keep the bolts for later steps." },
        { from = 120, to = 135, text = "Azure Silk Hood", crafts = 17, total = true,
          mats = { { 4305, 34, "Bolt of Silk Cloth" }, { 6260, 34, "Blue Dye" }, { 2321, 17, "Fine Thread" } } },
        { from = 135, to = 140, text = "Formal White Shirt", crafts = 5, total = true,
          mats = { { 4305, 15, "Bolt of Silk Cloth" }, { 2324, 10, "Bleach" }, { 2321, 5, "Fine Thread" } } },
        { from = 140, to = 150, text = "Bolt of Mageweave", crafts = 76, total = true, makes = 4339,
          mats = { { 4338, 380, "Mageweave Cloth" } }, tip = "Keep the bolts for Black Mageweave Gloves." },
        { from = 150, to = 170, text = "Crimson Silk Vest", crafts = 20, total = true,
          mats = { { 4305, 80, "Bolt of Silk Cloth" }, { 2604, 40, "Red Dye" }, { 2321, 40, "Fine Thread" } } },
        { from = 170, to = 190, text = "Crimson Silk Pantaloons", crafts = 26, total = true,
          mats = { { 4305, 104, "Bolt of Silk Cloth" }, { 2604, 52, "Red Dye" }, { 4291, 52, "Silken Thread" } } },
        { from = 190, to = 215, text = "Black Mageweave Gloves", crafts = 38, total = true,
          mats = { { 4339, 76, "Bolt of Mageweave" }, { 8343, 76, "Heavy Silken Thread" } } },
        { from = 215, to = 216, text = "Bolt of Mageweave", crafts = 104, total = true, makes = 4339,
          mats = { { 4338, 520, "Mageweave Cloth" } }, tip = "Make all 104 bolts for Mageweave Bags." },
        { from = 216, to = 225, text = "Mageweave Bag", crafts = 26, total = true,
          mats = { { 4339, 104, "Bolt of Mageweave" }, { 4291, 52, "Silken Thread" } } },
        -- Wowhead 225-300
        { from = 225, to = 234, text = "Runecloth Belt", crafts = 9, total = true, src = "wowhead",
          mats = { { 14048, 27, "Bolt of Runecloth" }, { 14341, 9, "Rune Thread" } } },
        { from = 234, to = 250, text = "Runecloth Cloak", crafts = 18, total = true, src = "wowhead",
          tip = "Buy Pattern: Runecloth Cloak (Darnall).",
          mats = { { 14048, 72, "Bolt of Runecloth" }, { 14227, 18, "Ironweb Spider Silk" }, { 14341, 18, "Rune Thread" } } },
        { from = 250, to = 260, text = "Runecloth Boots", crafts = 12, total = true, src = "wowhead",
          tip = "Buy Pattern: Runecloth Boots (Darnall).",
          mats = { { 14048, 48, "Bolt of Runecloth" }, { 14227, 24, "Ironweb Spider Silk" }, { 8170, 48, "Rugged Leather" }, { 14341, 12, "Rune Thread" } } },
        { from = 260, to = 280, text = "Runecloth Cuffs", crafts = 25, total = true, src = "wowhead",
          tip = "Buy Pattern: Runecloth Cuffs (Pexmit, rare spawn).",
          mats = { { 14048, 125, "Bolt of Runecloth" }, { 14227, 25, "Ironweb Spider Silk" }, { 14341, 25, "Rune Thread" } } },
        { from = 280, to = 285, text = "Wisdom of the Timbermaw", crafts = 8, total = true, src = "wowhead",
          tip = "Buy the pattern (Meilosh, Timbermaw rep).",
          mats = { { 14048, 64, "Bolt of Runecloth" }, { 7076, 24, "Essence of Earth" }, { 12803, 24, "Living Essence" }, { 14227, 16, "Ironweb Spider Silk" } } },
        { from = 285, to = 292, text = "Venomspew Gloves", crafts = 7, total = true, src = "wowhead",
          tip = "Buy the pattern (Mishta).",
          mats = { { 14048, 28, "Bolt of Runecloth" }, { 14343, 7, "Small Brilliant Shard" }, { 7082, 21, "Essence of Air" }, { 14341, 42, "Rune Thread" } } },
        { from = 292, to = 299, text = "Venomspew Cord", crafts = 9, total = true, src = "wowhead",
          tip = "Buy the pattern (Mishta).",
          mats = { { 14048, 54, "Bolt of Runecloth" }, { 14343, 9, "Small Brilliant Shard" }, { 7082, 27, "Essence of Air" }, { 14341, 54, "Rune Thread" } } },
        { from = 299, to = 300, text = "Venomspew Footpads", crafts = 4, total = true, src = "wowhead",
          tip = "Buy the pattern (Mishta).",
          mats = { { 14048, 20, "Bolt of Runecloth" }, { 14343, 4, "Small Brilliant Shard" }, { 7082, 12, "Essence of Air" }, { 14341, 24, "Rune Thread" } } },
    },
}
