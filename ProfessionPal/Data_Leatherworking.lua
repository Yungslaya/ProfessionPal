--[[ ProfessionPal - Leatherworking (WoW: Forever)
  SOURCES (read 2026-11-04):
    Icy Veins Forever Leatherworking Leveling Guide -> 1-225, trainers, ranks
      https://www.icy-veins.com/wow-forever/leatherworking-leveling-guide
    Wowhead Forever Leatherworking Leveling Guide -> 225-300 (not tested live yet)
      https://www.wowhead.com/forever/profession-leveling-guides/leatherworking
]]
local _, PP = ...

PP:AddProfession{
    key = "leatherworking", name = "Leatherworking", skillLine = 165, icon = "Interface\\Icons\\Trade_LeatherWorking",
    -- tracker buttons (one click = one cast, like an action bar)
    spells = { { name = "Leatherworking" } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 10 },
        { name = "Expert", cap = 225, skill = 125, level = 20 },
        { name = "Artisan", cap = 300, skill = 200, level = 35 },
    },
    trainers = PP.TrainerRanks({
        [1] = {
            A = {
                { "Randal Worth", "Old Town, Stormwind City", 1453, 67.4, 49.4 },
                { "Gretta Finespindle", "The Great Forge, Ironforge", 1455, 39, 32.4 },
                { "Darianna", "Craftsmen's Terrace, Darnassus", 1457, 64.4, 21.2 },
                { "Adele Fielder", "Goldshire, Elwynn Forest", 1429, 46.4, 62.2 },
                { "Nadyia Maneweaver", "Dolanaar, Teldrassil", 1438, 41.8, 49.4 },
                { "Waldor", "Cave above Wailing Caverns, The Barrens", 1414, 51.8, 55.4 },
                { "Indari Sunseam", "Zephras Isle", 2521, 44.6, 44.4 },
            },
            H = {
                { "Kamari", "The Drag, Orgrimmar", 1454, 63, 45 },
                { "Thuwd", "The Drag, Orgrimmar", 1454, 63.2, 45.2 },
                { "Dan Golthas", "Rogues' Quarter, Undercity", 1458, 70.4, 58.4 },
                { "Mak", "Thunder Bluff", 1456, 42.2, 43.2 },
                { "Chaw Stronghide", "Bloodhoof Village, Mulgore", 1412, 45, 61.4 },
                { "Shelene Rhobart", "Brill, Tirisfal Glades", 1420, 65.4, 60 },
                { "Waldor", "Cave above Wailing Caverns, The Barrens", 1414, 51.8, 55.4 },
                { "Indari Sunseam", "Zephras Isle", 2521, 44.6, 44.4 },
            },
        },
        [2] = {
            A = {
                { "Simon Tanner", "Old Town, Stormwind City", 1453, 67.2, 49.4 },
                { "Fimble Finespindle", "The Great Forge, Ironforge", 1455, 39.4, 33 },
                { "Faldron", "Craftsmen's Terrace, Darnassus", 1457, 64.4, 21.4 },
                { "Aayndia Floralwind", "Astranaar, Ashenvale", 1440, 35.8, 52 },
                { "Emerii Tallgust", "Zephras Isle", 2521, 63.8, 80.4 },
            },
            H = {
                { "Karolek", "The Drag, Orgrimmar", 1454, 62.8, 44.4 },
                { "Arthur Moore", "Rogues' Quarter, Undercity", 1458, 70.6, 57.8 },
                { "Tarn", "Thunder Bluff", 1456, 42.4, 43 },
                { "Brawn", "Grom'gol Base Camp, Stranglethorn Vale", 1434, 31.6, 28.8 },
                { "Krulmoo Fullmoon", "Camp Taurajo, The Barrens", 1413, 44.8, 59.4 },
                { "Narv Hidecrafter", "Ghost Walker Post, Desolace", 1443, 55.2, 56.2 },
                { "Emerii Tallgust", "Zephras Isle", 2521, 63.8, 80.4 },
            },
        },
        [3] = {
            A = { { "Telonis", "Craftsmen's Terrace, Darnassus", 1457, 64.4, 21.4 } },
            H = { { "Una", "Thunder Bluff", 1456, 41.4, 42.6 } },
        },
        [4] = {
            A = { { "Drakk Stonehand", "Aerie Peak, The Hinterlands", 1425, 13.4, 43.4 } },
            H = { { "Hahrana Ironhide", "Camp Mojache, Feralas", 1444, 74.4, 43 } },
        },
    }),
    steps = {
        { from = 1, to = 30, text = "Light Armor Kit", crafts = 29, total = true,
          mats = { { 2318, 29, "Light Leather" } } },
        { from = 30, to = 55, text = "Cured Light Hide", crafts = 27, total = true, makes = 4231,
          mats = { { 783, 27, "Light Hide" }, { 4289, 27, "Salt" } }, tip = "Keep the cured hides for skill 100." },
        { from = 55, to = 75, text = "Embossed Leather Gloves", crafts = 21, total = true,
          mats = { { 2318, 63, "Light Leather" }, { 2320, 42, "Coarse Thread" } } },
        { from = 75, to = 80, text = "Medium Leather", crafts = 8, total = true,
          mats = { { 2318, 32, "Light Leather" } } },
        { from = 80, to = 90, text = "Cured Medium Hide", crafts = 10, total = true, makes = 4233,
          mats = { { 4232, 10, "Medium Hide" }, { 4289, 10, "Salt" } } },
        { from = 90, to = 100, text = "Fine Leather Belt", crafts = 16, total = true, makes = 4246,
          mats = { { 2318, 96, "Light Leather" }, { 2320, 32, "Coarse Thread" } }, tip = "Keep 10 belts for Dark Leather Belts." },
        { from = 100, to = 115, text = "Light Leather Pants", crafts = 22, total = true,
          mats = { { 2318, 220, "Light Leather" }, { 4231, 22, "Cured Light Hide" }, { 2321, 22, "Fine Thread" } } },
        { from = 115, to = 125, text = "Dark Leather Belt", crafts = 10, total = true,
          mats = { { 4246, 10, "Fine Leather Belt" }, { 4233, 10, "Cured Medium Hide" }, { 2321, 20, "Fine Thread" }, { 4340, 10, "Gray Dye" } } },
        { from = 125, to = 130, text = "Heavy Leather", crafts = 7, total = true,
          mats = { { 2319, 35, "Medium Leather" } } },
        { from = 130, to = 131, text = "Cured Heavy Hide", crafts = 20, total = true, makes = 4236,
          mats = { { 4235, 20, "Heavy Hide" }, { 4289, 60, "Salt" } }, tip = "Make all 20. Keep them for skill 155." },
        { from = 131, to = 150, text = "Heavy Armor Kit", crafts = 9, total = true,
          mats = { { 4234, 45, "Heavy Leather" }, { 2321, 9, "Fine Thread" } } },
        { from = 150, to = 155, text = "Heavy Armor Kit", crafts = 8, total = true,
          mats = { { 4234, 40, "Heavy Leather" }, { 2321, 8, "Fine Thread" } } },
        { from = 155, to = 165, text = "Barbaric Shoulders", crafts = 10, total = true,
          mats = { { 4234, 80, "Heavy Leather" }, { 4236, 10, "Cured Heavy Hide" }, { 2321, 20, "Fine Thread" } } },
        { from = 165, to = 175, text = "Guardian Gloves", crafts = 10, total = true,
          mats = { { 4234, 40, "Heavy Leather" }, { 4236, 10, "Cured Heavy Hide" }, { 4291, 10, "Silken Thread" } } },
        { from = 175, to = 195, text = "Thick Armor Kit", crafts = 20, total = true,
          mats = { { 4304, 100, "Thick Leather" }, { 4291, 20, "Silken Thread" } } },
        { from = 195, to = 210, text = "Nightscape Headband", crafts = 20, total = true,
          mats = { { 4304, 100, "Thick Leather" }, { 4291, 40, "Silken Thread" } } },
        { from = 210, to = 225, text = "Nightscape Pants", crafts = 15, total = true,
          mats = { { 4304, 210, "Thick Leather" }, { 4291, 60, "Silken Thread" } } },
        -- Wowhead 225-300
        { from = 225, to = 230, text = "Cured Rugged Hide", crafts = 6, total = true, src = "wowhead",
          mats = { { 8171, 6, "Rugged Hide" }, { 15409, 6, "Refined Deeprock Salt" } } },
        { from = 230, to = 240, text = "Nightscape Pants", crafts = 20, total = true, src = "wowhead",
          mats = { { 4304, 280, "Thick Leather" }, { 4291, 80, "Silken Thread" } } },
        { from = 240, to = 255, text = "Wicked Leather Gauntlets", crafts = 15, total = true, src = "wowhead",
          tip = "Buy the pattern (Leonard Porter or Werg Thickblade).",
          mats = { { 8170, 120, "Rugged Leather" }, { 2325, 15, "Black Dye" }, { 14341, 15, "Rune Thread" } } },
        { from = 255, to = 260, text = "Heavy Scorpid Bracers", crafts = 6, total = true, src = "wowhead",
          tip = "Buy the pattern (Zannok Hidepiercer).",
          mats = { { 8170, 24, "Rugged Leather" }, { 15408, 24, "Heavy Scorpid Scale" }, { 14341, 6, "Rune Thread" } } },
        { from = 260, to = 270, text = "Wicked Leather Gauntlets", crafts = 20, total = true, src = "wowhead",
          mats = { { 8170, 160, "Rugged Leather" }, { 2325, 20, "Black Dye" }, { 14341, 20, "Rune Thread" } } },
        { from = 270, to = 300, text = "Heavy Scorpid Helm", crafts = 33, total = true, src = "wowhead",
          tip = "Buy the pattern (Zannok Hidepiercer).",
          mats = { { 8170, 264, "Rugged Leather" }, { 15408, 396, "Heavy Scorpid Scale" }, { 15407, 33, "Cured Rugged Hide" }, { 14341, 33, "Rune Thread" } } },
    },
}
