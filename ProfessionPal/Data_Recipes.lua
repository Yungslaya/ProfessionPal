--[[ ProfessionPal - recipe spells for every guide step (WoW: Forever)
  SOURCE (read 2026-11-04): Wowhead Forever profession spell lists
    https://www.wowhead.com/forever/spells/professions/<profession>
    https://www.wowhead.com/forever/spells/secondary-skills/<first-aid|cooking>
  Used to tell you "learn this recipe first" when a step needs one you don't know.
  Row: [recipe name] = { spellID, skill it unlocks at, where it comes from }
  "start" = Wowhead lists no source: usually known from the start, so never nagged.
]]
local _, PP = ...

PP.Recipes = {
    firstaid = {
        ["Linen Bandage"] = { 3275, 30, "start" }, ["Heavy Linen Bandage"] = { 3276, 40, "trainer" },
        ["Wool Bandage"] = { 3277, 80, "trainer" }, ["Heavy Wool Bandage"] = { 3278, 115, "trainer" },
        ["Silk Bandage"] = { 7928, 150, "trainer" }, ["Heavy Silk Bandage"] = { 7929, 180, "vendor" },
        ["Mageweave Bandage"] = { 10840, 210, "vendor" }, ["Heavy Mageweave Bandage"] = { 10841, 240, "trainer" },
        ["Runecloth Bandage"] = { 18629, 260, "trainer" }, ["Heavy Runecloth Bandage"] = { 18630, 290, "trainer" },
    },
    cooking = {
        ["Roasted Boar Meat"] = { 2540, 45, "start" }, ["Coyote Steak"] = { 2541, 50, "trainer" },
        ["Dry Pork Ribs"] = { 2546, 80, "trainer" }, ["Curiously Tasty Omelet"] = { 3376, 130, "vendor" },
        ["Roast Raptor"] = { 15855, 175, "vendor" }, ["Tender Wolf Steak"] = { 22480, 225, "vendor" },
    },
    alchemy = {
        ["Minor Arcane Elixir"] = { 1245246, 10, "start" }, ["Minor Mana Potion"] = { 2331, 25, "trainer" },
        ["Elixir of Minor Fortitude"] = { 2334, 50, "trainer" }, ["Elixir of Minor Defense"] = { 7183, 55, "start" },
        ["Elixir of Wisdom"] = { 3171, 90, "trainer" }, ["Lesser Mana Potion"] = { 3173, 120, "trainer" },
        ["Mana Potion"] = { 3452, 160, "trainer" }, ["Elixir of Agility"] = { 11449, 185, "trainer" },
        ["Greater Mana Potion"] = { 11448, 205, "trainer" }, ["Philosopher's Stone"] = { 11459, 225, "vendor" },
        ["Draught of Detect Undead"] = { 11460, 230, "trainer" }, ["Superior Mana Potion"] = { 17553, 260, "vendor" },
        ["Major Discolored Healing Potion"] = { 1231583, 250, "trainer" },
    },
    blacksmithing = {
        ["Rough Sharpening Stone"] = { 2660, 15, "start" }, ["Rough Grinding Stone"] = { 3320, 25, "trainer" },
        ["Runed Copper Gauntlets"] = { 3323, 35, "trainer" }, ["Runed Copper Belt"] = { 2666, 45, "trainer" },
        ["Coarse Grinding Stone"] = { 3326, 50, "trainer" }, ["Rough Bronze Leggings"] = { 2668, 80, "trainer" },
        ["Patterned Bronze Bracers"] = { 2672, 95, "trainer" }, ["Bronze Warhammer"] = { 9985, 100, "trainer" },
        ["Heavy Grinding Stone"] = { 3337, 100, "trainer" }, ["Green Iron Bracers"] = { 3501, 140, "trainer" },
        ["Golden Scale Bracers"] = { 7223, 160, "trainer" }, ["Heavy Mithril Gauntlet"] = { 9928, 180, "trainer" },
        ["Mithril Plate Pants"] = { 9931, 185, "trainer" }, ["Heavy Mithril Breastplate"] = { 9959, 205, "trainer" },
        ["Mithril Coif"] = { 9961, 205, "trainer" }, ["Big Black Mace"] = { 10001, 205, "trainer" },
        ["Heavy Mithril Boots"] = { 9968, 210, "trainer" }, ["Dense Weightstone"] = { 16640, 225, "trainer" },
        ["Arcanite Skeleton Key"] = { 19669, 250, "trainer" }, ["Ebon Shiv"] = { 10013, 255, "vendor" },
        ["Bold Dirk"] = { 1252365, 270, "vendor" }, ["Ornate Thorium Handaxe"] = { 16969, 275, "vendor" },
    },
    enchanting = {
        ["Runed Copper Rod"] = { 7421, 5, "start" }, ["Enchant Chest - Inferior Stamina"] = { 7420, 15, "trainer" },
        ["Enchant Bracer - Inferior Stamina"] = { 7418, 20, "start" }, ["Enchant Bracer - Minor Stamina"] = { 7457, 50, "trainer" },
        ["Enchant Cloak - Minor Protection"] = { 7771, 70, "trainer" }, ["Runed Silver Rod"] = { 7795, 100, "trainer" },
        ["Enchant Bracer - Lesser Stamina"] = { 13501, 130, "trainer" }, ["Runed Golden Rod"] = { 13628, 150, "trainer" },
        ["Enchant Boots - Lesser Agility"] = { 13637, 160, "trainer" }, ["Enchant Bracer - Strength"] = { 13661, 180, "trainer" },
        ["Runed Truesilver Rod"] = { 13702, 200, "trainer" }, ["Enchant Cloak - Greater Defense"] = { 13746, 205, "trainer" },
        ["Enchant Gloves - Agility"] = { 13815, 210, "trainer" }, ["Enchant Boots - Stamina"] = { 13836, 215, "trainer" },
        ["Enchant Chest - Superior Stamina"] = { 13858, 220, "trainer" }, ["Lesser Mana Oil"] = { 25127, 250, "vendor" },
        ["Enchant Shield - Greater Stamina"] = { 20017, 265, "vendor" }, ["Enchant Cloak - Superior Defense"] = { 20015, 285, "vendor" },
        ["Runed Arcanite Rod"] = { 20051, 290, "vendor" },
    },
    engineering = {
        ["Rough Blasting Powder"] = { 3918, 20, "start" }, ["Handful of Copper Bolts"] = { 3922, 30, "trainer" },
        ["Rough Copper Bomb"] = { 3923, 30, "trainer" }, ["Arclight Spanner"] = { 7430, 50, "trainer" },
        ["Coarse Blasting Powder"] = { 3929, 75, "trainer" }, ["Coarse Dynamite"] = { 3931, 75, "trainer" },
        ["Silver Contact"] = { 3973, 90, "trainer" }, ["Bronze Tube"] = { 3938, 105, "trainer" },
        ["Standard Scope"] = { 3978, 110, "trainer" }, ["Heavy Blasting Powder"] = { 3945, 125, "trainer" },
        ["Whirring Bronze Gizmo"] = { 3942, 125, "trainer" }, ["Bronze Framework"] = { 3953, 145, "trainer" },
        ["Explosive Sheep"] = { 3955, 150, "trainer" }, ["Solid Blasting Powder"] = { 12585, 175, "trainer" },
        ["Iron Grenade"] = { 3962, 175, "trainer" }, ["Mithril Tube"] = { 12589, 195, "trainer" },
        ["Unstable Trigger"] = { 12591, 200, "trainer" }, ["Mithril Casing"] = { 12599, 215, "trainer" },
        ["Mithril Frag Bomb"] = { 12603, 215, "trainer" }, ["Hi-Explosive Bomb"] = { 12619, 235, "trainer" },
        ["Dense Blasting Powder"] = { 19788, 250, "trainer" }, ["Thorium Widget"] = { 19791, 260, "vendor" },
        ["Thorium Tube"] = { 19795, 275, "vendor" },
    },
    leatherworking = {
        ["Light Armor Kit"] = { 2152, 30, "start" }, ["Cured Light Hide"] = { 3816, 30, "trainer" },
        ["Embossed Leather Gloves"] = { 3756, 40, "trainer" }, ["Fine Leather Belt"] = { 3763, 55, "trainer" },
        ["Light Leather Pants"] = { 9068, 70, "trainer" }, ["Medium Leather"] = { 20648, 75, "trainer" },
        ["Cured Medium Hide"] = { 3817, 75, "trainer" }, ["Dark Leather Belt"] = { 3766, 100, "trainer" },
        ["Heavy Leather"] = { 20649, 125, "trainer" }, ["Cured Heavy Hide"] = { 3818, 125, "trainer" },
        ["Heavy Armor Kit"] = { 3780, 125, "trainer" }, ["Barbaric Shoulders"] = { 7151, 150, "trainer" },
        ["Guardian Gloves"] = { 7156, 165, "trainer" }, ["Thick Armor Kit"] = { 10487, 175, "trainer" },
        ["Nightscape Headband"] = { 10507, 180, "trainer" }, ["Nightscape Pants"] = { 10548, 205, "trainer" },
        ["Cured Rugged Hide"] = { 19047, 225, "trainer" }, ["Wicked Leather Gauntlets"] = { 19049, 235, "vendor" },
        ["Heavy Scorpid Bracers"] = { 19048, 255, "vendor" }, ["Heavy Scorpid Helm"] = { 19088, 270, "vendor" },
    },
    tailoring = {
        ["Linen Belt"] = { 8776, 15, "trainer" }, ["Bolt of Linen Cloth"] = { 2963, 25, "start" },
        ["Bolt of Woolen Cloth"] = { 2964, 55, "trainer" }, ["Woolen Cape"] = { 2402, 55, "trainer" },
        ["Bolt of Silk Cloth"] = { 3839, 100, "trainer" }, ["Azure Silk Hood"] = { 8760, 120, "trainer" },
        ["Formal White Shirt"] = { 3871, 135, "trainer" }, ["Bolt of Mageweave"] = { 3865, 140, "trainer" },
        ["Crimson Silk Vest"] = { 8791, 150, "trainer" }, ["Crimson Silk Pantaloons"] = { 8799, 160, "trainer" },
        ["Black Mageweave Gloves"] = { 12053, 180, "trainer" }, ["Mageweave Bag"] = { 12065, 190, "trainer" },
        ["Runecloth Belt"] = { 18402, 210, "trainer" }, ["Runecloth Cloak"] = { 18409, 220, "vendor" },
        ["Runecloth Boots"] = { 18423, 235, "vendor" }, ["Runecloth Cuffs"] = { 1257487, 250, "vendor" },
        ["Wisdom of the Timbermaw"] = { 23662, 255, "vendor" }, ["Venomspew Gloves"] = { 1297120, 285, "vendor" },
        ["Venomspew Cord"] = { 1297121, 290, "vendor" }, ["Venomspew Footpads"] = { 1297122, 295, "vendor" },
    },
    mining = {
        ["Smelt Copper"] = { 2657, 25, "start" }, ["Smelt Tin"] = { 3304, 65, "trainer" },
        ["Smelt Bronze"] = { 2659, 65, "trainer" }, ["Smelt Silver"] = { 2658, 75, "trainer" },
        ["Smelt Iron"] = { 3307, 125, "trainer" }, ["Smelt Gold"] = { 3308, 155, "trainer" },
        ["Smelt Steel"] = { 3569, 165, "trainer" }, ["Smelt Mithril"] = { 10097, 175, "trainer" },
        ["Smelt Truesilver"] = { 10098, 230, "trainer" }, ["Smelt Thorium"] = { 16153, 250, "trainer" },
        ["Smelt Dark Iron"] = { 14891, 230, "start" },
    },
}
