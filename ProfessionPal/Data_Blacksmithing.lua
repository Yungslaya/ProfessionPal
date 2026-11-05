--[[ ProfessionPal - Blacksmithing data (WoW: Forever)

  SOURCES (read 2026-11-04, launch day):
    Icy Veins - WoW Forever Blacksmithing Leveling Guide (updated Nov 4 2026)
      https://www.icy-veins.com/wow-forever/blacksmithing-leveling-guide
      -> steps 1-225, crafts, materials, trainers + /mappin coords, rank level needs
         (Icy Veins says it has no 225-300 plan yet)
    Wowhead - WoW Forever Blacksmithing Leveling Guide 1-300 ("checked against Forever's data")
      https://www.wowhead.com/forever/profession-leveling-guides/blacksmithing
      -> steps 225-300 and the plan vendors
    Wowhead NPC pages: Magnus Frostwake (Western Plaguelands 68.0 77.5, both factions),
      Pexmit (rare demon, Mount Hyjal, no coords listed)

  NOT VERIFIED:
    - 225-300 is Wowhead's planner table. It is expensive (lots of Thorium + new
      Azerothium Bars). Nobody has tested it on live servers yet.
    - Pexmit is a RARE spawn in Mount Hyjal. He may be hard to find.
    - Which crafts need an anvil (marked "anvil") is from Classic.
]]

local _, PP = ...

-- Item IDs (Classic IDs). Azerothium Bar is new in Forever: looked up by name.
local ROUGH_STONE, COARSE_STONE, HEAVY_STONE, DENSE_STONE = 2835, 2836, 2838, 12365
local COPPER, BRONZE, IRON, STEEL, MITHRIL = 2840, 2841, 3575, 3859, 3860
local TRUESILVER, THORIUM, ARCANITE = 6037, 12359, 12360
local AZEROTHIUM = "Azerothium Bar"
local MED_LEATHER, THICK_LEATHER, RUGGED_LEATHER = 2319, 4304, 8170
local MAGEWEAVE, STRONG_FLUX, GREEN_DYE = 4338, 3466, 2605
local ROUGH_GS, COARSE_GS, HEAVY_GS, SOLID_GS, DENSE_GS = 3470, 3478, 3486, 7966, 12644
local BLACK_PEARL, SHADOWGEM, STAR_RUBY, LARGE_OPAL, ESS_AIR = 7971, 1210, 7910, 12799, 7082
local HAMMER = 5956

local function T(order, n, p, m, x, y)
    return { order = order, n = n, p = p, m = m, x = x, y = y }
end

-- Trainers (Icy Veins). Each list = trainers whose HIGHEST rank is that one.
local APP = {
    Alliance = {
        T(10, "Dane Lindgren", "Dwarven District, Stormwind City", 1453, 69.4, 52.9),
        T(11, "Groum Stonebeard", "The Great Forge, Ironforge", 1455, 52.3, 41.9),
        T(12, "Smith Argus", "Goldshire, Elwynn Forest", 1429, 41.7, 65.5),
        T(13, "Tognus Flintfire", "Kharanos, Dun Morogh", 1426, 45.3, 51.9),
        T(14, "Delfrum Flintbeard", "Auberdine, Darkshore", 1439, 38.2, 40.9),
        T(15, "Alphonse Dumas", "Farholde Keep, Riverglades", 2548, 64.4, 82.0),
    },
    Horde = {
        T(10, "Ug'thok", "Valley of Honor, Orgrimmar", 1454, 80.8, 23.7),
        T(11, "Basil Frye", "War Quarter, Undercity", 1458, 60.2, 29.1),
        T(12, "Thrag Stonehoof", "Lower Rise, Thunder Bluff", 1456, 39.4, 56.7),
        T(13, "Dwukk", "Razor Hill, Durotar", 1411, 52.0, 40.7),
        T(14, "Guillaume Sorouy", "The Sepulcher, Silverpine Forest", 1421, 43.2, 41.1),
        T(15, "Gur'dok", "Rog'mar, Riverglades", 2548, 60.0, 46.2),
    },
    Neutral = { T(30, "Aedi Thriceforged", "Shen'dar Village, Zephras Isle", 2521, 44.8, 44.4) },
}
local JOUR = {
    Alliance = {
        T(5, "Therum Deepforge", "Dwarven District, Stormwind City", 1453, 69.1, 52.9),
        T(6, "Rotgath Stonebeard", "The Great Forge, Ironforge", 1455, 52.4, 42.6),
        T(7, "Clarise Gnarltree", "Darkshire, Duskwood", 1431, 74.0, 48.5),
    },
    Horde = {
        T(5, "Snarl", "Valley of Honor, Orgrimmar", 1454, 79.6, 23.3),
        T(6, "James Van Brunt", "War Quarter, Undercity", 1458, 61.3, 30.6),
        T(7, "Karn Stonehoof", "Lower Rise, Thunder Bluff", 1456, 39.4, 55.1),
        T(8, "Traugh", "The Crossroads, The Barrens", 1413, 51.3, 28.9),
        T(9, "Angus Hammerhand", "Bandarion Keep, Tirisfal Glades", 1420, 21.1, 46.2),
    },
    Neutral = { T(29, "Daeann Steelwind", "Valanaar, Zephras Isle", 2521, 65.4, 80.2) },
}
local EXP = {
    Alliance = {
        T(1, "Bengus Deepforge", "The Great Forge, Ironforge", 1455, 52.5, 41.5),
        T(2, "Alard Schmied", "Dalaran, Alterac Mountains", 1416, 19.6, 63.3),
    },
    Horde = { T(1, "Saru Steelfury", "Valley of Honor, Orgrimmar", 1454, 82.3, 23.0) },
    Neutral = {},
}
local ART = {
    Alliance = {}, Horde = {},
    Neutral = { T(0, "Brikk Keencraft", "Booty Bay, Stranglethorn Vale", 1434, 29.0, 75.6) },
}
local function Merge(...)
    local out = { Alliance = {}, Horde = {}, Neutral = {} }
    for i = 1, select("#", ...) do
        local s = select(i, ...)
        for _, f in ipairs({ "Alliance", "Horde", "Neutral" }) do
            out[f] = PP.Join(out[f], s[f])
        end
    end
    return out
end

local MAGNUS = { n = "Magnus Frostwake", p = "Western Plaguelands", m = 1422, x = 68.0, y = 77.5 }
local PEXMIT = { n = "Pexmit (rare demon)", p = "Mount Hyjal" }

PP:AddProfession{
    key = "blacksmithing",
    name = "Blacksmithing",
    skillLine = 164,
    icon = "Interface\\Icons\\Trade_BlackSmithing",
    tool = { HAMMER, "Blacksmith Hammer" },
    -- Opens the Blacksmithing window (spell ID differs per rank, so it is found by name)
    spells = { { name = "Blacksmithing" } },

    ranks = {
        { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
        { name = "Journeyman", cap = 150, skill = 50,  level = 10 },
        { name = "Expert",     cap = 225, skill = 125, level = 20 },
        { name = "Artisan",    cap = 300, skill = 200, level = 35 },
    },
    trainers = {
        [1] = Merge(EXP, JOUR, APP),
        [2] = Merge(EXP, JOUR),
        [3] = Merge(EXP, ART),
        [4] = Merge(ART),
    },

    -- mats = { itemID or name, per craft, "Name" }. crafts = about how many for the whole step.
    steps = {
        -- Icy Veins 1-225
        { from = 1, to = 25, text = "Rough Sharpening Stone", crafts = 30,
          mats = { { ROUGH_STONE, 1, "Rough Stone" } } },
        { from = 25, to = 50, text = "Rough Grinding Stone", crafts = 30, makes = ROUGH_GS,
          mats = { { ROUGH_STONE, 2, "Rough Stone" } },
          tip = "Keep them. You need 16 at skill 67." },
        { from = 50, to = 67, text = "Coarse Grinding Stone", crafts = 36, makes = COARSE_GS, keepAll = true,
          mats = { { COARSE_STONE, 2, "Coarse Stone" } },
          tip = "Make all 36, even past 67. Keep them for Bronze Bracers." },
        { from = 67, to = 75, text = "Runed Copper Gauntlets", crafts = 8, anvil = true,
          mats = { { COPPER, 8, "Copper Bar" }, { ROUGH_GS, 2, "Rough Grinding Stone" } } },
        { from = 75, to = 80, text = "Runed Copper Belt", crafts = 5, anvil = true,
          mats = { { COPPER, 10, "Copper Bar" } },
          tip = "Train Journeyman first (level 10)." },
        { from = 80, to = 95, text = "Rough Bronze Leggings", crafts = 15, anvil = true,
          mats = { { BRONZE, 6, "Bronze Bar" } } },
        { from = 95, to = 100, text = "Patterned Bronze Bracers", crafts = 5, anvil = true,
          mats = { { BRONZE, 5, "Bronze Bar" }, { COARSE_GS, 2, "Coarse Grinding Stone" } } },
        { from = 100, to = 112, text = "Heavy Grinding Stone", crafts = 20, makes = HEAVY_GS, keepAll = true,
          mats = { { HEAVY_STONE, 3, "Heavy Stone" } },
          tip = "Make all 20, even past 112. Keep them for skill 175." },
        { from = 112, to = 125, text = "Patterned Bronze Bracers", crafts = 13, anvil = true,
          mats = { { BRONZE, 5, "Bronze Bar" }, { COARSE_GS, 2, "Coarse Grinding Stone" } } },
        { from = 125, to = 150, text = "Bronze Warhammer", crafts = 25, anvil = true,
          mats = { { BRONZE, 8, "Bronze Bar" }, { MED_LEATHER, 1, "Medium Leather" }, { STRONG_FLUX, 1, "Strong Flux" } },
          tip = "Strong Flux: Blacksmithing Supplies vendor." },
        { from = 150, to = 165, text = "Bronze Warhammer", crafts = 19, anvil = true,
          mats = { { BRONZE, 8, "Bronze Bar" }, { MED_LEATHER, 1, "Medium Leather" }, { STRONG_FLUX, 1, "Strong Flux" } },
          tip = "Train Expert first (level 20)." },
        { from = 165, to = 175, text = "Green Iron Bracers", crafts = 15, anvil = true,
          mats = { { IRON, 6, "Iron Bar" }, { GREEN_DYE, 1, "Green Dye" } },
          tip = "Green Dye: Tamar (Orgrimmar) or Bombus Finespindle (Ironforge)." },
        { from = 175, to = 185, text = "Golden Scale Bracers", crafts = 10, anvil = true,
          mats = { { STEEL, 5, "Steel Bar" }, { HEAVY_GS, 2, "Heavy Grinding Stone" } },
          tip = "Use the 20 Heavy Grinding Stones you saved." },
        { from = 185, to = 200, text = "Heavy Mithril Gauntlet", crafts = 15, anvil = true,
          mats = { { MITHRIL, 6, "Mithril Bar" }, { MAGEWEAVE, 4, "Mageweave Cloth" } } },
        { from = 200, to = 215, text = "Mithril Plate Pants", crafts = 19, anvil = true,
          mats = { { MITHRIL, 12, "Mithril Bar" } },
          tip = "Train Artisan now (level 35): Booty Bay." },
        { from = 215, to = 225, text = "Heavy Mithril Breastplate", crafts = 10, anvil = true,
          mats = { { MITHRIL, 16, "Mithril Bar" } } },

        -- Wowhead 225-300 (not tested live yet)
        { from = 225, to = 235, text = "Dense Weightstone", crafts = 15,
          mats = { { DENSE_STONE, 1, "Dense Stone" } } },
        { from = 235, to = 240, text = "Mithril Coif", crafts = 12, anvil = true,
          mats = { { MITHRIL, 10, "Mithril Bar" }, { MAGEWEAVE, 6, "Mageweave Cloth" } } },
        { from = 240, to = 246, text = "Heavy Mithril Boots", crafts = 17, anvil = true,
          mats = { { MITHRIL, 14, "Mithril Bar" }, { THICK_LEATHER, 4, "Thick Leather" } } },
        { from = 246, to = 250, text = "Big Black Mace", crafts = 12, anvil = true,
          mats = { { MITHRIL, 16, "Mithril Bar" }, { BLACK_PEARL, 1, "Black Pearl" }, { SHADOWGEM, 4, "Shadowgem" },
                   { SOLID_GS, 1, "Solid Grinding Stone" }, { THICK_LEATHER, 2, "Thick Leather" } } },
        { from = 250, to = 257, text = "Arcanite Skeleton Key", crafts = 10,
          mats = { { ARCANITE, 1, "Arcanite Bar" }, { DENSE_GS, 1, "Dense Grinding Stone" } } },
        { from = 257, to = 270, text = "Ebon Shiv", crafts = 20, anvil = true, vendor = MAGNUS,
          mats = { { MITHRIL, 12, "Mithril Bar" }, { TRUESILVER, 6, "Truesilver Bar" }, { STAR_RUBY, 2, "Star Ruby" },
                   { SOLID_GS, 1, "Solid Grinding Stone" }, { THICK_LEATHER, 2, "Thick Leather" } },
          tip = "Buy Plans: Ebon Shiv first." },
        { from = 270, to = 275, text = "Bold Dirk", crafts = 5, anvil = true, vendor = PEXMIT,
          mats = { { THORIUM, 30, "Thorium Bar" }, { ESS_AIR, 4, "Essence of Air" },
                   { AZEROTHIUM, 10, "Azerothium Bar" }, { RUGGED_LEATHER, 4, "Rugged Leather" } },
          tip = "Buy Plans: Bold Dirk first. Pexmit is a rare spawn." },
        { from = 275, to = 279, text = "Ornate Thorium Handaxe", crafts = 4, anvil = true, vendor = MAGNUS,
          mats = { { THORIUM, 20, "Thorium Bar" }, { LARGE_OPAL, 2, "Large Opal" },
                   { DENSE_GS, 2, "Dense Grinding Stone" }, { RUGGED_LEATHER, 4, "Rugged Leather" } },
          tip = "Buy Plans: Ornate Thorium Handaxe first." },
        { from = 279, to = 300, text = "Bold Dirk", crafts = 24, anvil = true, vendor = PEXMIT,
          mats = { { THORIUM, 30, "Thorium Bar" }, { ESS_AIR, 4, "Essence of Air" },
                   { AZEROTHIUM, 10, "Azerothium Bar" }, { RUGGED_LEATHER, 4, "Rugged Leather" } } },
    },
}
