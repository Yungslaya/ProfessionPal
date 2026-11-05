--[[ ProfessionPal - Cooking (WoW: Forever)
  SOURCE (read 2026-11-04): Icy Veins Forever Cooking Leveling Guide (full 1-300)
    https://www.icy-veins.com/wow-forever/cooking-leveling-guide
  Expert = Expert Cookbook (vendor). Artisan = quest "Clamlette Surprise", level 35.
  NOT VERIFIED: Mount Hyjal map ID 2482 (new zone).
]]
local _, PP = ...

local COOKS = {
    A = {
        { "Stephen Ryback", "Old Town, Stormwind City", 1453, 78.2, 53 },
        { "Daryl Riknussun", "The Great Forge, Ironforge", 1455, 60.4, 38 },
        { "Alegorn", "Craftsmen's Terrace, Darnassus", 1457, 49.8, 21 },
        { "Tomas", "Goldshire, Elwynn Forest", 1429, 44.2, 66 },
        { "Gremlock Pilsnor", "Kharanos, Dun Morogh", 1426, 47.6, 52.4 },
        { "Cook Ghilm", "Gol'bolar Quarry, Dun Morogh", 1426, 68.4, 54.6 },
        { "Zarrin", "Dolanaar, Teldrassil", 1438, 57, 61.2 },
        { "Crystal Boughman", "Lakeshire, Redridge Mountains", 1433, 22.8, 43.6 },
        { "Katherine Lee", "Dalaran, Alterac Mountains", 1416, 12.6, 65.8 },
        { "Hnaz Blunderflame", "Elderwild, Mount Hyjal", 2482, 15.6, 50.2 },
        { "Nyalah Brightfire", "Valanaar, Zephras Isle", 2521, 60.6, 72.6 },
        { "Zerril Softbreeze", "Shen'dar Village, Zephras Isle", 2521, 43.8, 43.8 },
    },
    H = {
        { "Zamja", "The Drag, Orgrimmar", 1454, 57.6, 53.6 },
        { "Aska Mistrunner", "Central Rise, Thunder Bluff", 1456, 51, 52.8 },
        { "Eunice Burch", "Trade Quarter, Undercity", 1458, 62.6, 44.6 },
        { "Cook Torka", "Razor Hill, Durotar", 1411, 51.2, 42.6 },
        { "Pyall Silentstride", "Bloodhoof Village, Mulgore", 1412, 45, 61.6 },
        { "William Pickman", "Brill, Tirisfal Glades", 1420, 61.8, 51.6 },
        { "Duhng", "Outpost southeast of the Crossroads, The Barrens", 1413, 55.2, 31.8 },
        { "Mudduk", "Grom'gol Base Camp, Stranglethorn Vale", 1434, 31.4, 28 },
        { "Gorg", "Rog'mar, Riverglades", 2548, 58.6, 44.6 },
        { "Ortak Lomgok", "Elderwild, Mount Hyjal", 2482, 13.2, 52.8 },
        { "Nyalah Brightfire", "Valanaar, Zephras Isle", 2521, 60.6, 72.6 },
        { "Zerril Softbreeze", "Shen'dar Village, Zephras Isle", 2521, 43.8, 43.8 },
    },
}

PP:AddProfession{
    key = "cooking", name = "Cooking", skillLine = 185, icon = "Interface\\Icons\\INV_Misc_Food_15",
    -- tracker buttons (one click = one cast, like an action bar)
    spells = { { name = "Cooking" }, { name = "Basic Campfire", id = 818 } },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 0 },
        { name = "Expert", cap = 225, skill = 125, level = 0, note = "Buy and read the Expert Cookbook." },
        { name = "Artisan", cap = 300, skill = 225, level = 35, note = "Do the quest Clamlette Surprise." },
    },
    trainers = PP.TrainerRanks({ [1] = COOKS, [2] = COOKS }),
    steps = {
        { from = 1, to = 50, text = "Roasted Boar Meat", crafts = 52, total = true,
          mats = { { 769, 52, "Chunk of Boar Meat" } } },
        { from = 50, to = 75, text = "Coyote Steak", crafts = 25, total = true,
          mats = { { 2673, 25, "Coyote Meat" } } },
        { from = 75, to = 90, text = "Coyote Steak", crafts = 15, total = true,
          mats = { { 2673, 15, "Coyote Meat" } } },
        { from = 90, to = 130, text = "Dry Pork Ribs", crafts = 42, total = true,
          mats = { { 2677, 42, "Boar Ribs" }, { 2678, 42, "Mild Spices" } } },
        { from = 130, to = 150, text = "Curiously Tasty Omelet", crafts = 20, total = true,
          mats = { { 3685, 20, "Raptor Egg" }, { 2692, 20, "Hot Spices" } } },
        { from = 150, to = 175, text = "Curiously Tasty Omelet", crafts = 26, total = true,
          mats = { { 3685, 26, "Raptor Egg" }, { 2692, 26, "Hot Spices" } } },
        { from = 175, to = 225, text = "Roast Raptor", crafts = 52, total = true,
          mats = { { 12184, 52, "Raptor Flesh" }, { 2692, 52, "Hot Spices" } } },
        { from = 225, to = 285, text = "Tender Wolf Steak", crafts = 68, total = true,
          mats = { { 12208, 68, "Tender Wolf Meat" }, { 3713, 68, "Soothing Spices" } } },
        { from = 285, to = 300, text = "Tender Wolf Steak", crafts = 52, total = true,
          mats = { { 12208, 52, "Tender Wolf Meat" }, { 3713, 52, "Soothing Spices" } } },
    },
}
