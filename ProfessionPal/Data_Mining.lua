--[[ ProfessionPal - Mining data (WoW: Forever)

  SOURCES (read 2026-11-04, launch day):
    Icy Veins - WoW Forever Mining Leveling Guide (updated Nov 4 2026)
      https://www.icy-veins.com/wow-forever/mining-leveling-guide
      -> smelting plan 1-105, trainer list + /mappin coords, zones per skill range, routes
    Icy Veins - WoW Forever Mining Guide (updated Nov 3 2026)
      https://www.icy-veins.com/wow-forever/mining
      -> node skill numbers (orange/yellow/green/gray), ore zones
    Icy Veins - WoW Forever Profession Guide (updated Nov 3 2026)
      https://www.icy-veins.com/wow-forever/professions-overview
      -> rank caps + character level needed (gathering: Expert lvl 10, Artisan lvl 25)

  NOT VERIFIED:
    - Zone level ranges ("lvl") are the old Classic numbers. Forever may differ.
    - Zephras Isle / Riverglades are new Forever zones; their levels are guesses.
    - Smelting crafts are "about" numbers; skill-ups are random.
]]

local _, PP = ...

-- Item IDs (Classic IDs, same in Forever)
local COPPER_ORE, TIN_ORE, IRON_ORE, SILVER_ORE, GOLD_ORE = 2770, 2771, 2772, 2775, 2776
local MITHRIL_ORE, TRUESILVER_ORE, THORIUM_ORE = 3858, 7911, 10620
local COPPER_BAR, TIN_BAR = 2840, 3576
local MINING_PICK = 2901

local function T(order, n, p, m, x, y, junior)
    return { order = order, n = n, p = p, m = m, x = x, y = y, junior = junior }
end

-- Trainers (Icy Veins tables). Junior trainers = starting areas, Apprentice only, no smelting.
local APP_A = {
    T(50, "Kelsey Fargo", "Northshire, Elwynn Forest", 1429, 47.2, 32.6, true),
    T(51, "Sally Swiftwrench", "Coldridge Valley, Dun Morogh", 1426, 28.8, 67.8, true),
    T(52, "Fanorran Stilloak", "Shadowglen, Teldrassil", 1438, 58.2, 41.6, true),
}
local APP_H = {
    T(50, "Norzsh", "Valley of Trials, Durotar", 1411, 40.6, 68.0, true),
    T(51, "Vartha Rockmane", "Red Cloud Mesa, Mulgore", 1412, 44.2, 78.2, true),
    T(52, "Walter Mason", "Deathknell, Tirisfal Glades", 1420, 32.2, 65.6, true),
}
local FULL_A = {
    T(1, "Gelman Stonehand", "Dwarven District, Stormwind City", 1453, 51.0, 17.2),
    T(2, "Geofram Bouldertoe", "The Great Forge, Ironforge", 1455, 50.2, 26.0),
    T(3, "Yarr Hammerstone", "Steelgrill's Depot, Dun Morogh", 1426, 50.0, 50.4),
    T(4, "Dank Drizzlecut", "Gol'Bolar Quarry, Dun Morogh", 1426, 69.2, 55.4),
    T(5, "Brock Stoneseeker", "Thelsamar, Loch Modan", 1432, 37.2, 46.8),
    T(6, "Kurdram Stonehammer", "Auberdine, Darkshore", 1439, 38.2, 41.0),
    T(7, "Matt Johnson", "Darkshire, Duskwood", 1431, 74.0, 49.6),
}
local FULL_H = {
    T(1, "Makaru", "Valley of Honor, Orgrimmar", 1454, 73.0, 26.4),
    T(2, "Brek Stonehoof", "Thunder Bluff", 1456, 34.6, 57.6),
    T(3, "Brom Killian", "War Quarter, Undercity", 1458, 56.0, 37.0),
    T(4, "Krunn", "Razor Hill, Durotar", 1411, 51.8, 40.8),
    T(5, "Johan Focht", "The Sepulcher, Silverpine Forest", 1421, 43.4, 40.6),
}
local NEUTRAL = {
    T(20, "Messana Crestwind", "Shen'dar Village, Zephras Isle", 2521, 44.8, 44.4),
    T(21, "Halavuul Cragwind", "Valanaar, Zephras Isle", 2521, 65.4, 80.4),
    T(22, "Pikkle", "Gadgetzan, Tanaris", 1446, 51.0, 28.0),
    T(23, "Grungle", "Powderfuse Port, Riverglades", 2548, 77.6, 51.8),
}
local FULL = { Alliance = FULL_A, Horde = FULL_H, Neutral = NEUTRAL }

-- Zones: name, level (Classic numbers, unverified), short route tip (from Icy Veins routes)
local Z = {
    durotar    = { "Durotar", "1-10", "Hills from Razor Hill north to Orgrimmar. Smelt at Razor Hill." },
    mulgore    = { "Mulgore", "1-10", "Cave south of Bael'dun Digsite, west of Bloodhoof Village." },
    tirisfal   = { "Tirisfal Glades", "1-10", "From Brill to Agamand Mills, then hills to Deathknell." },
    zephras    = { "Zephras Isle", "1-10", "From Shen'dar Village go southwest to Falaath Village. Forge in Shen'dar." },
    elwynn     = { "Elwynn Forest", "1-10", "Fargodeep Mine, south of Goldshire. Then the hills east." },
    dunmorogh  = { "Dun Morogh", "1-10", "Around Iceflow Lake, west of Kharanos. Forge in Kharanos." },
    teldrassil = { "Teldrassil", "1-10", "Fel Rock cave, north of Dolanaar. Amber nodes give copper." },
    silverpine = { "Silverpine Forest", "10-20", "Beren's Peril cave, south past Ambermill." },
    hillsbrad  = { "Hillsbrad Foothills", "20-30", "East river bank by Durnholde Keep. Stay outside the keep." },
    barrens    = { "The Barrens", "10-25", "Hills by Razorfen Kraul, south of Camp Taurajo." },
    ashenvale  = { "Ashenvale", "18-30", "Slopes near Maestra's Post, then hills toward Zoram Strand." },
    stonetalon = { "Stonetalon Mountains", "15-27", "Slopes around Stonetalon Peak, past Mirkfallon Lake." },
    wetlands   = { "Wetlands", "20-30", "Thelgen Rock cave, just north of Dun Algaz." },
    westfall   = { "Westfall", "10-20", "Gold Coast Quarry, west of Sentinel Hill." },
    needles    = { "Thousand Needles", "25-35", "Canyon walls below Freewind Post. Skip the salt flats." },
    arathi     = { "Arathi Highlands", "30-40", "Hills from Boulderfist Hall to Drywhisker Gorge, then west." },
    desolace   = { "Desolace", "30-40", "Hills around the Kodo Graveyard and Mannoroc Coven." },
    hinter     = { "The Hinterlands", "40-50", "Loop: Shaol'watha, Altar of Zul, Skulk Rock. Skip Seradane." },
    tanaris    = { "Tanaris", "40-50", "West of Gadgetzan, south to Thistleshrub Valley, back by the Gaping Chasm." },
    ungoro     = { "Un'Goro Crater", "48-55", "Crater wall east of Marshal's Refuge. Fungal Rock cave." },
    felwood    = { "Felwood", "48-55", "Small Thorium Veins along the hills." },
    winter     = { "Winterspring", "55-60", "Circle Lake Kel'Theril from Everlook, then Frostsaber Rock." },
    epl        = { "Eastern Plaguelands", "53-60", "Rich and Small Thorium Veins along the hills." },
}

PP:AddProfession{
    key = "mining",
    name = "Mining",
    skillLine = 186,
    icon = "Interface\\Icons\\Trade_Mining",
    gather = true,
    tool = { MINING_PICK, "Mining Pick" },
    -- Spell buttons on the tracker (one click = one cast, like an action bar button)
    spells = {
        { name = "Find Minerals", id = 2580 },
        { name = "Smelting", id = 2656 },
    },
    -- smelting recipes the auto-learn option may buy at a Mining trainer
    learn = { "Smelt Copper", "Smelt Tin", "Smelt Bronze", "Smelt Silver", "Smelt Iron", "Smelt Gold",
              "Smelt Steel", "Smelt Mithril", "Smelt Truesilver", "Smelt Thorium", "Smelt Dark Iron" },
    zones = Z,

    -- Gathering ranks: character level from the Icy Veins profession table
    ranks = {
        { name = "Apprentice", cap = 75,  skill = 0,   level = 0 },
        { name = "Journeyman", cap = 150, skill = 50,  level = 0 },
        { name = "Expert",     cap = 225, skill = 125, level = 10 },
        { name = "Artisan",    cap = 300, skill = 200, level = 25 },
    },
    trainers = {
        [1] = { Alliance = PP.Join(FULL_A, APP_A), Horde = PP.Join(FULL_H, APP_H), Neutral = NEUTRAL },
        [2] = FULL, [3] = FULL, [4] = FULL,
    },

    -- Main plan: gather your own ore
    steps = {
        { from = 1, to = 65, text = "Mine Copper",
          nodes = { { "Copper Vein", 1, COPPER_ORE }, { "Poor Copper Vein", 1, COPPER_ORE } },
          zones = { Horde = { "durotar", "mulgore", "tirisfal", "zephras" },
                    Alliance = { "elwynn", "dunmorogh", "teldrassil", "zephras" } },
          tip = "Smelt your copper at a forge. It gives extra points." },
        { from = 65, to = 125, text = "Mine Tin and Silver",
          nodes = { { "Tin Vein", 65, TIN_ORE }, { "Silver Vein", 75, SILVER_ORE } },
          zones = { Horde = { "silverpine", "hillsbrad", "barrens", "ashenvale", "stonetalon" },
                    Alliance = { "wetlands", "westfall", "ashenvale", "stonetalon" } },
          tip = "Train Journeyman before 75. Copper is gray at 100." },
        { from = 125, to = 175, text = "Mine Iron and Gold",
          nodes = { { "Iron Deposit", 125, IRON_ORE }, { "Gold Vein", 155, GOLD_ORE } },
          zones = { Horde = { "needles", "arathi", "desolace" },
                    Alliance = { "arathi", "desolace", "needles" } },
          tip = "Train Expert at 125. Mine outside, skip slow caves." },
        { from = 175, to = 225, text = "Mine Mithril",
          nodes = { { "Mithril Deposit", 175, MITHRIL_ORE }, { "Gold Vein", 155, GOLD_ORE } },
          zones = { Horde = { "hinter", "tanaris" }, Alliance = { "tanaris", "hinter" } },
          tip = "Smelting Mithril gives no points. Mine it." },
        { from = 225, to = 245, text = "Mine Mithril and Truesilver",
          nodes = { { "Mithril Deposit", 175, MITHRIL_ORE }, { "Truesilver Deposit", 230, TRUESILVER_ORE } },
          zones = { Horde = { "hinter", "tanaris" }, Alliance = { "tanaris", "hinter" } },
          tip = "Train Artisan (skill 200, level 25) to go past 225." },
        { from = 245, to = 275, text = "Mine Small Thorium",
          nodes = { { "Small Thorium Vein", 245, THORIUM_ORE }, { "Truesilver Deposit", 230, TRUESILVER_ORE } },
          zones = { Horde = { "ungoro", "felwood" }, Alliance = { "ungoro", "felwood" } },
          tip = "Rich Thorium Veins need 275." },
        { from = 275, to = 300, text = "Mine Rich and Small Thorium",
          nodes = { { "Rich Thorium Vein", 275, THORIUM_ORE }, { "Small Thorium Vein", 245, THORIUM_ORE } },
          zones = { Horde = { "winter", "epl" }, Alliance = { "winter", "epl" } },
          tip = "Both vein sizes give points up to 300." },
    },

    -- Option: buy cheap ore and smelt at a forge, 1 to about 105 (Icy Veins plan)
    altSteps = {
        label = "Mining: buy ore and smelt first (skill 1-105)",
        upTo = 105,
        steps = {
            { from = 1, to = 65, smelt = true, text = "Smelt Copper", crafts = 130,
              mats = { { COPPER_ORE, 1, "Copper Ore" } },
              tip = "Use a forge in town. Keep 70 Copper Bars for Bronze.",
              buyNote = "Buy about 130 Copper Ore." },
            { from = 65, to = 75, smelt = true, text = "Smelt Tin", crafts = 70,
              mats = { { TIN_ORE, 1, "Tin Ore" } },
              tip = "Train Journeyman first. Learn Tin and Bronze smelting.",
              needTrainer = true,
              buyNote = "Buy 70 Tin Ore." },
            { from = 75, to = 105, smelt = true, text = "Smelt Bronze", crafts = 70,
              mats = { { COPPER_BAR, 1, "Copper Bar" }, { TIN_BAR, 1, "Tin Bar" } },
              tip = "Each smelt makes 2 Bronze Bars. Keep or sell them." },
        },
    },
}
