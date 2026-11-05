--[[ ProfessionPal - First Aid (WoW: Forever)
  SOURCE (read 2026-11-04): Icy Veins Forever First Aid guide (bandage plan 1-300, trainers)
    https://www.icy-veins.com/wow-forever/first-aid
  Forever First Aid can also make healing potions (Icy Veins); this guide uses bandages.
  Expert = book "Expert First Aid - Under Wraps" (vendor). Artisan = quest "Triage", level 35.
]]
local _, PP = ...

local TRAINERS = {
    A = {
        { "Shaina Fuller", "Cathedral of Light, Stormwind City", 1453, 42.8, 26.6 },
        { "Nissa Firestone", "Great Forge, Ironforge", 1455, 54.8, 58.6 },
        { "Dannelor", "Craftsmen's Terrace, Darnassus", 1457, 51.6, 12.6 },
        { "Michelle Belle", "Goldshire, Elwynn Forest", 1429, 43.4, 65.6 },
        { "Thamner Pol", "Kharanos, Dun Morogh", 1426, 47.2, 52.6 },
        { "Byancie", "Dolanaar, Teldrassil", 1438, 55.2, 56.8 },
        { "Fremal Doohickey", "Menethil Harbor, Wetlands", 1437, 10.8, 61.2 },
        { "Angelique Butler", "Dalaran, Alterac Mountains", 1416, 17.2, 61.0 },
        { "Naleeia Tattermend", "Shen'dar Village, Zephras Isle", 2521, 43.0, 46.2 },
        { "Melasa Fairmend", "Valanaar, Zephras Isle", 2521, 63.0, 72.6 },
    },
    H = {
        { "Arnok", "Valley of Spirits, Orgrimmar", 1454, 34.0, 84.4 },
        { "Pand Stonebinder", "Spirit Rise, Thunder Bluff", 1456, 29.6, 21.4 },
        { "Mary Edras", "Rogues' Quarter, Undercity", 1458, 73.6, 55.6 },
        { "Rawrk", "Razor Hill, Durotar", 1411, 54.0, 42.0 },
        { "Vira Younghoof", "Bloodhoof Village, Mulgore", 1412, 46.8, 60.8 },
        { "Nurse Neela", "Brill, Tirisfal Glades", 1420, 61.8, 52.8 },
        { "Naleeia Tattermend", "Shen'dar Village, Zephras Isle", 2521, 43.0, 46.2 },
        { "Melasa Fairmend", "Valanaar, Zephras Isle", 2521, 63.0, 72.6 },
    },
}

PP:AddProfession{
    key = "firstaid", name = "First Aid", skillLine = 129, icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice",
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 0 },
        { name = "Expert", cap = 225, skill = 125, level = 0, note = "Buy and read the book Expert First Aid - Under Wraps." },
        { name = "Artisan", cap = 300, skill = 225, level = 35, note = "Do the quest Triage." },
    },
    trainers = {
        [1] = { Alliance = PP.TrainerList(TRAINERS.A), Horde = PP.TrainerList(TRAINERS.H), Neutral = {} },
        [2] = { Alliance = PP.TrainerList(TRAINERS.A), Horde = PP.TrainerList(TRAINERS.H), Neutral = {} },
        [3] = { Alliance = PP.TrainerList({ { "Deneb Walker (book)", "Stromgarde Keep, Arathi Highlands", 1417, 27.0, 58.8 } }),
                Horde = PP.TrainerList({ { "Balai Lok'Wein (book)", "Brackenwall Village, Dustwallow Marsh", 1445, 36.4, 30.4 } }), Neutral = {} },
        [4] = { Alliance = PP.TrainerList({ { "Doctor Gustaf VanHowzen (quest)", "Theramore Isle, Dustwallow Marsh", 1445, 67.6, 48.8 } }),
                Horde = PP.TrainerList({ { "Doctor Gregory Victor (quest)", "Hammerfall, Arathi Highlands", 1417, 73.4, 36.8 } }), Neutral = {} },
    },
    steps = {
        { from = 1, to = 40, text = "Linen Bandage", crafts = 50, total = true, mats = { { 2589, 50, "Linen Cloth" } } },
        { from = 40, to = 80, text = "Heavy Linen Bandage", crafts = 52, total = true, mats = { { 2589, 104, "Linen Cloth" } } },
        { from = 80, to = 115, text = "Wool Bandage", crafts = 50, total = true, mats = { { 2592, 50, "Wool Cloth" } } },
        { from = 115, to = 150, text = "Heavy Wool Bandage", crafts = 50, total = true, mats = { { 2592, 100, "Wool Cloth" } } },
        { from = 150, to = 180, text = "Silk Bandage", crafts = 45, total = true, mats = { { 4306, 45, "Silk Cloth" } } },
        { from = 180, to = 210, text = "Heavy Silk Bandage", crafts = 45, total = true, mats = { { 4306, 90, "Silk Cloth" } } },
        { from = 210, to = 225, text = "Mageweave Bandage", crafts = 20, total = true, mats = { { 4338, 20, "Mageweave Cloth" } } },
        { from = 225, to = 240, text = "Mageweave Bandage", crafts = 25, total = true, mats = { { 4338, 25, "Mageweave Cloth" } } },
        { from = 240, to = 260, text = "Heavy Mageweave Bandage", crafts = 25, total = true, mats = { { 4338, 50, "Mageweave Cloth" } } },
        { from = 260, to = 290, text = "Runecloth Bandage", crafts = 45, total = true, mats = { { 14047, 45, "Runecloth" } } },
        { from = 290, to = 300, text = "Heavy Runecloth Bandage", crafts = 15, total = true, mats = { { 14047, 30, "Runecloth" } } },
    },
}
