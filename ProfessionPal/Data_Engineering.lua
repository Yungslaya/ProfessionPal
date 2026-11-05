--[[ ProfessionPal - Engineering (WoW: Forever)
  SOURCES (read 2026-11-04):
    Icy Veins Forever Engineering Leveling Guide -> 1-225, trainers, ranks
      https://www.icy-veins.com/wow-forever/engineering-leveling-guide
    Wowhead Forever Engineering Leveling Guide -> 225-300 (not tested live yet)
      https://www.wowhead.com/forever/profession-leveling-guides/engineering
  NOT VERIFIED: Mount Hyjal map ID 2482, Zephras Isle 2521.
]]
local _, PP = ...

PP:AddProfession{
    key = "engineering", name = "Engineering", skillLine = 202, icon = "Interface\\Icons\\Trade_Engineering",
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 10 },
        { name = "Expert", cap = 225, skill = 125, level = 20 },
        { name = "Artisan", cap = 300, skill = 200, level = 35 },
    },
    trainers = PP.TrainerRanks({
        [1] = {
            A = {
                { "Sprite Jumpsprocket", "Dwarven District, Stormwind City", 1453, 61.8, 30.8 },
                { "Jemma Quikswitch", "Tinker Town, Ironforge", 1455, 67.8, 43.8 },
                { "Bronk Guzzlegear", "Steelgrill's Depot, Dun Morogh", 1426, 50.2, 50.4 },
                { "Deek Fizzlebizz", "Stonewrought Dam, Loch Modan", 1432, 45.8, 13.6 },
                { "Jenna Lemkenilli", "Auberdine, Darkshore", 1439, 38.2, 41 },
                { "Tinkerwiz", "Ratchet, The Barrens", 1413, 62.6, 36.2 },
                { "Strange Hermit", "Shadowgale Forest, Zephras Isle", 2521, 54, 39 },
            },
            H = {
                { "Thund", "Valley of Honor, Orgrimmar", 1454, 75.8, 24.6 },
                { "Graham Van Talen", "Rogues' Quarter, Undercity", 1458, 75.6, 73.2 },
                { "Mukdrak", "Razor Hill, Durotar", 1411, 52.2, 40.8 },
                { "Twizwick Sprocketgrind", "Venture Co. Mine, Mulgore", 1412, 61.8, 31.4 },
                { "Tinkerwiz", "Ratchet, The Barrens", 1413, 62.6, 36.2 },
                { "Strange Hermit", "Shadowgale Forest, Zephras Isle", 2521, 54, 39 },
            },
        },
        [2] = {
            A = {
                { "Lilliam Sparkspindle", "Dwarven District, Stormwind City", 1453, 62.2, 30.4 },
                { "Trixie Quikswitch", "Tinker Town, Ironforge", 1455, 67.8, 43.2 },
                { "Finbus Geargrind", "Darkshire, Duskwood", 1431, 77.4, 48.4 },
            },
            H = {
                { "Nogg", "Valley of Honor, Orgrimmar", 1454, 75.8, 25.2 },
                { "Franklin Lloyd", "Rogues' Quarter, Undercity", 1458, 76, 73.4 },
            },
        },
        [3] = {
            A = { { "Springspindle Fizzlegear", "Tinker Town, Ironforge", 1455, 68.4, 44 } },
            H = { { "Roxxik", "Valley of Honor, Orgrimmar", 1454, 76, 25 } },
        },
        [4] = {
            A = {
                { "Buzzek Bracketswing", "Gadgetzan, Tanaris", 1446, 52.2, 27.6 },
                { "Kaylaena Springwhisper", "Mount Hyjal", 2482, 60.2, 61.4 },
            },
            H = {
                { "Buzzek Bracketswing", "Gadgetzan, Tanaris", 1446, 52.2, 27.6 },
                { "Kaylaena Springwhisper", "Mount Hyjal", 2482, 60.2, 61.4 },
            },
        },
    }),
    steps = {
        { from = 1, to = 30, text = "Rough Blasting Powder", crafts = 60, total = true, makes = 4357,
          mats = { { 2835, 60, "Rough Stone" } }, tip = "Keep the powder for Rough Copper Bombs." },
        { from = 30, to = 50, text = "Handful of Copper Bolts", crafts = 30, total = true, makes = 4359,
          mats = { { 2840, 30, "Copper Bar" } }, tip = "Keep the bolts for Rough Copper Bombs." },
        { from = 50, to = 51, text = "Arclight Spanner", crafts = 1, total = true,
          mats = { { 2840, 6, "Copper Bar" } }, tip = "Keep the spanner in your bags." },
        { from = 51, to = 75, text = "Rough Copper Bomb", crafts = 30, total = true,
          mats = { { 2840, 30, "Copper Bar" }, { 4359, 30, "Handful of Copper Bolts" }, { 4357, 60, "Rough Blasting Powder" }, { 2589, 30, "Linen Cloth" } } },
        { from = 75, to = 90, text = "Coarse Blasting Powder", crafts = 45, total = true, makes = 4364,
          mats = { { 2836, 45, "Coarse Stone" } } },
        { from = 90, to = 100, text = "Coarse Dynamite", crafts = 15, total = true,
          mats = { { 4364, 45, "Coarse Blasting Powder" }, { 2589, 15, "Linen Cloth" } } },
        { from = 100, to = 105, text = "Silver Contact", crafts = 5, total = true,
          mats = { { 2842, 5, "Silver Bar" } } },
        { from = 105, to = 115, text = "Bronze Tube", crafts = 12, total = true, makes = 4371,
          mats = { { 2841, 24, "Bronze Bar" }, { 2880, 12, "Weak Flux" } } },
        { from = 115, to = 125, text = "Standard Scope", crafts = 10, total = true,
          mats = { { 4371, 10, "Bronze Tube" }, { 1206, 10, "Moss Agate" } } },
        { from = 125, to = 126, text = "Heavy Blasting Powder", crafts = 42, total = true, makes = 4377,
          mats = { { 2838, 42, "Heavy Stone" } }, tip = "Make all 42. Keep them for later." },
        { from = 126, to = 150, text = "Whirring Bronze Gizmo", crafts = 15, total = true, makes = 4375,
          mats = { { 2841, 30, "Bronze Bar" }, { 2592, 15, "Wool Cloth" } } },
        { from = 150, to = 160, text = "Bronze Framework", crafts = 15, total = true, makes = 4382,
          mats = { { 2841, 30, "Bronze Bar" }, { 2319, 15, "Medium Leather" }, { 2592, 15, "Wool Cloth" } } },
        { from = 160, to = 175, text = "Explosive Sheep", crafts = 15, total = true,
          mats = { { 4382, 15, "Bronze Framework" }, { 4375, 15, "Whirring Bronze Gizmo" }, { 4377, 30, "Heavy Blasting Powder" }, { 2592, 30, "Wool Cloth" } } },
        { from = 175, to = 190, text = "Solid Blasting Powder", crafts = 26, total = true, makes = 10505,
          mats = { { 7912, 52, "Solid Stone" } } },
        { from = 190, to = 195, text = "Iron Grenade", crafts = 12, total = true,
          mats = { { 3575, 12, "Iron Bar" }, { 4377, 12, "Heavy Blasting Powder" }, { 4306, 12, "Silk Cloth" } } },
        { from = 195, to = 200, text = "Mithril Tube", crafts = 6, total = true,
          mats = { { 3860, 18, "Mithril Bar" } } },
        { from = 200, to = 215, text = "Unstable Trigger", crafts = 20, total = true, makes = 10560,
          mats = { { 3860, 20, "Mithril Bar" }, { 4338, 20, "Mageweave Cloth" }, { 10505, 20, "Solid Blasting Powder" } } },
        { from = 215, to = 225, text = "Mithril Frag Bomb", crafts = 6, total = true,
          tip = "Make 6 Mithril Casings first (3 Mithril Bars each).",
          mats = { { 3860, 18, "Mithril Bar" }, { 10560, 6, "Unstable Trigger" }, { 10505, 6, "Solid Blasting Powder" } } },
        -- Wowhead 225-300
        { from = 225, to = 238, text = "Mithril Casing", crafts = 19, total = true, src = "wowhead", makes = 10561,
          mats = { { 3860, 57, "Mithril Bar" } } },
        { from = 238, to = 250, text = "Hi-Explosive Bomb", crafts = 15, total = true, src = "wowhead",
          mats = { { 10561, 30, "Mithril Casing" }, { 10560, 15, "Unstable Trigger" }, { 10505, 30, "Solid Blasting Powder" } } },
        { from = 250, to = 260, text = "Dense Blasting Powder", crafts = 27, total = true, src = "wowhead",
          mats = { { 12365, 54, "Dense Stone" } } },
        { from = 260, to = 285, text = "Thorium Widget", crafts = 25, total = true, src = "wowhead",
          tip = "Buy Schematic: Thorium Widget (Gearcutter Cogspinner or Sovik).",
          mats = { { 12359, 75, "Thorium Bar" }, { 14047, 25, "Runecloth" } } },
        { from = 285, to = 300, text = "Thorium Tube", crafts = 15, total = true, src = "wowhead",
          tip = "Buy Schematic: Thorium Tube (Xizzer Fizzbolt).",
          mats = { { 12359, 90, "Thorium Bar" } } },
    },
}
