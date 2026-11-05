--[[ ProfessionPal - Fishing (WoW: Forever)
  SOURCE (read 2026-11-04): Icy Veins Forever Fishing Leveling Guide (1-300, spots, trainers)
    https://www.icy-veins.com/wow-forever/fishing-leveling-guide
  Expert = book "Expert Fishing - The Bass and You" (Old Man Heming, Booty Bay), level 20.
  Artisan = Nat Pagle's quest (Dustwallow Marsh), level 35.
]]
local _, PP = ...

local TRAINERS = {
    A = {
        { "Arnold Leland", "Canal by the Trade District, Stormwind City", 1453, 55, 69.6 },
        { "Grimnur Stonebrand", "Forlorn Cavern, Ironforge", 1455, 48.4, 6.4 },
        { "Astaia", "Temple Gardens, Darnassus", 1457, 47.6, 56.6 },
        { "Lee Brown", "Goldshire, Elwynn Forest", 1429, 47.6, 62.2 },
        { "Paxton Ganter", "Brewnall Village, Dun Morogh", 1426, 35.6, 40.4 },
        { "Androl Oakhand", "Rut'theran Village, Teldrassil", 1438, 55.8, 93.6 },
        { "Warg Deepwater", "Thelsamar, Loch Modan", 1432, 40.6, 39.6 },
        { "Matthew Hooper", "Lakeshire, Redridge Mountains", 1433, 26.8, 50.4 },
        { "Harold Riggs", "Menethil Harbor, Wetlands", 1437, 8.2, 58.6 },
        { "Donald Rabonne", "Southshore, Hillsbrad Foothills", 1424, 50.6, 61 },
        { "Hunter Moore", "Hillsbrad Foothills", 1424, 54, 80.2 },
        { "Brannock", "Feathermoon Stronghold, Feralas", 1444, 32.2, 41.6 },
        { "Baelann Swiftcurrent", "Valanaar, Zephras Isle", 2521, 63.2, 75.6 },
        { "Fenn Fairweather", "Shen'dar Village, Zephras Isle", 2521, 45, 48.4 },
        { "Krix", "Powderfuse Port, Riverglades", 2548, 79.2, 54.8 },
        { "Myizz Luckycatch", "Booty Bay, Stranglethorn Vale", 1434, 27.6, 77 },
    },
    H = {
        { "Lumak", "Valley of Honor, Orgrimmar", 1454, 69.8, 29.6 },
        { "Kah Mistrunner", "Middle Tier, Thunder Bluff", 1456, 56, 46.8 },
        { "Armand Cromwell", "Magic Quarter, Undercity", 1458, 80.8, 31.2 },
        { "Lau'Tiki", "South of Sen'jin Village, Durotar", 1411, 53.2, 81.6 },
        { "Uthan Stillwater", "Bloodhoof Village, Mulgore", 1412, 44.6, 60.6 },
        { "Clyde Kellen", "Brightwater Lake, Tirisfal Glades", 1420, 67.2, 51 },
        { "Kil'Hiwana", "South of Blackfathom Deeps, Ashenvale", 1440, 10.8, 33.6 },
        { "Lui'Mala", "Shadowprey Village, Desolace", 1443, 22.6, 72.6 },
        { "Katoom the Angler", "Revantusk Village, The Hinterlands", 1425, 80.2, 81.4 },
        { "Baelann Swiftcurrent", "Valanaar, Zephras Isle", 2521, 63.2, 75.6 },
        { "Fenn Fairweather", "Shen'dar Village, Zephras Isle", 2521, 45, 48.4 },
        { "Krix", "Powderfuse Port, Riverglades", 2548, 79.2, 54.8 },
        { "Myizz Luckycatch", "Booty Bay, Stranglethorn Vale", 1434, 27.6, 77 },
    },
}

PP:AddProfession{
    key = "fishing", name = "Fishing", skillLine = 356, icon = "Interface\\Icons\\Trade_Fishing", gather = true,
    tool = { 6256, "Fishing Pole" },
    ranks = {
        { name = "Apprentice", cap = 75, skill = 0, level = 0 },
        { name = "Journeyman", cap = 150, skill = 50, level = 0 },
        { name = "Expert", cap = 225, skill = 125, level = 20, note = "Buy the book Expert Fishing - The Bass and You (Old Man Heming, Booty Bay)." },
        { name = "Artisan", cap = 300, skill = 225, level = 35, note = "Do Nat Pagle's quest on his island in Dustwallow Marsh." },
    },
    trainers = PP.TrainerRanks({ [1] = TRAINERS, [2] = TRAINERS }),
    steps = {
        { from = 1, to = 75, text = "Fish", tip = "Pick water close to your trainer. Buy a pole from the fishing vendor.",
          nodes = { { "Raw Brilliant Smallfish", 0, 6291 } },
          zoneList = { Horde = { { "Durotar", "Beach south of Sen'jin Village." }, { "Mulgore", "The water by Bloodhoof Village." }, { "Tirisfal Glades", "Brightwater Lake, east of Brill." }, { "Zephras Isle", "" } },
                       Alliance = { { "Elwynn Forest", "Crystal Lake, northeast of Goldshire." }, { "Dun Morogh", "Iceflow Lake by Brewnall Village." }, { "Teldrassil", "Water near Dolanaar." }, { "Zephras Isle", "" } } } },
        { from = 75, to = 150, text = "Fish", tip = "Your starting zone or a capital city is fine.",
          nodes = {},
          zoneList = { Horde = { { "The Barrens", "Lushwater Oasis outside Wailing Caverns." }, { "Silverpine Forest", "North Tide's Run beach." } },
                       Alliance = { { "Loch Modan", "Western shore of the loch, northeast of Thelsamar." }, { "Darkshore", "The open sea at Auberdine." } } } },
        { from = 150, to = 225, text = "Fish", tip = "Get the Expert book in Booty Bay first.",
          nodes = {},
          zoneList = { Horde = { { "Stranglethorn Vale", "Booty Bay docks." }, { "Dustwallow Marsh", "Nat Pagle's island, southwest of Theramore." } },
                       Alliance = { { "Dustwallow Marsh", "Nat Pagle's island, southwest of Theramore." }, { "Stranglethorn Vale", "Booty Bay docks." } } } },
        { from = 225, to = 300, text = "Fish", tip = "After Nat Pagle's quest you can fish to 300 on his island.",
          nodes = {},
          zoneList = { Horde = { { "Dustwallow Marsh", "Nat Pagle's island in Tidefury Cove." }, { "Tanaris", "Shore by Steamwheedle Port." }, { "The Hinterlands", "Pier at Revantusk Village." } },
                       Alliance = { { "Dustwallow Marsh", "Nat Pagle's island in Tidefury Cove." }, { "Tanaris", "Shore by Steamwheedle Port." }, { "Feralas", "Verdantis River bridge, southeast of Dire Maul." } } } },
    },
}
