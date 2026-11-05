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


--[[ Merchant's Favor plans + scarce materials (WoW: Forever)
  SOURCE (read 2026-11-05):
    https://www.wowhead.com/forever/guide/azeroth-commerce-authority-reputation-professions
    https://www.wowhead.com/forever/guide/durotar-supply-and-logistics-reputation-professions
    https://www.wowhead.com/forever/currency=3402/merchants-favor
    Wowhead Forever item pages for the scarce materials and Waylaid Crates.
  How it works in Forever: Waylaid Crates drop at random from mobs (about 0.1%, level 10+)
  and can be bought on the Auction House. Fill a crate (for example 20 Copper Ore) and
  hand it in at the camp: 5 to 20 Merchant's Favor each. Plans cost Favor.
  Rows: { skill, Favor cost, crafted item names... }  (plan names without "Plans: ")
]]
PP.Favor = {
    currency = 3402,
    camps = {
        Alliance = { n = "Azeroth Commerce Authority", p = "Three Corners, Redridge Mountains", m = 1433, x = 10.5, y = 72.7 },
        Horde    = { n = "Durotar Supply and Logistics", p = "Outside the Crossroads, The Barrens", m = 1413, x = 42.0, y = 34.0 },
    },
}

-- Scarce materials: [itemID] = where to get it (short)
PP.ScarceMats = {
    [249427] = "A rare drop from beasts around level 10-25, and sometimes from skinning them. Or buy it on the Auction House.",  -- Pristine Leather
    [249410] = "Made by Alchemists. Buy it on the Auction House, or ask an Alchemist friend.",                                -- Sulfuric Acid
    [249432] = "Made by Engineers. Buy it on the Auction House, or ask an Engineer friend.",                                 -- Sandpaper
    [251290] = "Made by Alchemists (a transmute). Buy it on the Auction House.",                               -- Legionite Bar
    [249726] = "A new WoW Forever material. Buy it on the Auction House.",                                 -- Azerothium Bar
    [251291] = "A new WoW Forever material. Buy it on the Auction House.",                                 -- Heavy Thorium Bar
    [248820] = "A new WoW Forever material. Buy it on the Auction House.",                                 -- Torbernite
    [248822] = "A new WoW Forever herb. Buy it on the Auction House.",                                     -- Death Lotus
}

PP.ScarceNames = {
    [249427] = "Pristine Leather", [249410] = "Sulfuric Acid", [249432] = "Sandpaper", [251290] = "Legionite Bar",
    [249726] = "Azerothium Bar", [251291] = "Heavy Thorium Bar", [248820] = "Torbernite", [248822] = "Death Lotus",
}

PP.FavorPlans = {
blacksmithing = {
  {45,30, "Acolyte's Chain Belt", "Crusader's Chain Belt", "Guard's Chain Belt", "Protector's Chain Belt", "Veteran's Chain Belt"},
  {80,30, "Acolyte's Gloves", "Crusader's Gloves", "Guard's Gloves", "Protector's Gloves", "Veteran's Gloves"},
  {85,30, "Acolyte's Boots", "Crusader's Boots", "Guard's Boots", "Protector's Boots", "Veteran's Boots"},
  {95,30, "Acolyte's Silvered Chain Helm", "Crusader's Silvered Chain Helm", "Guard's Silvered Chain Helm", "Protector's Silvered Chain Helm", "Veteran's Silvered Chain Helm"},
  {110,30, "Acolyte's Silvered Chain Shirt", "Crusader's Silvered Chain Shirt", "Guard's Silvered Chain Shirt", "Protector's Silvered Chain Shirt", "Veteran's Silvered Chain Shirt"},
  {125,30, "Acolyte's Silvered Chain Leggings", "Crusader's Silvered Chain Leggings", "Guard's Silvered Chain Leggings", "Protector's Silvered Chain Leggings", "Veteran's Silvered Chain Leggings"},
  {175,60, "Justicar's Gauntlet", "Officer's Gauntlet", "Prefect's Gauntlet", "Sentinel's Gauntlet", "Warder's Gauntlet"},
  {210,60, "Justicar's Pauldrons", "Officer's Pauldrons", "Prefect's Pauldrons", "Sentinel's Pauldrons", "Warder's Pauldrons"},
  {225,90, "Justicar's Wristguards", "Officer's Wristguard", "Prefect's Wristguard", "Sentinel's Wristguard", "Warder's Wristguard"},
  {240,90, "Justicar's Sabatons", "Officer's Sabatons", "Prefect's Sabatons", "Sentinel's Sabatons", "Warder's Sabatons"},
  {250,90, "Justicar's Waistguard", "Officer's Waistguard", "Prefect's Waistguard", "Sentinel's Waistguard", "Thorium Cestus", "Thorium Greatmace", "Warder's Waistguard"},
  {300,120, "Enriched Thorium Breastplate", "Enriched Thorium Helm", "Enriched Thorium Leggings", "Legionite Glaive"},
},
tailoring = {
  {60,30, "Flame Boots", "Pearly Boots", "Pristine Boots", "Shadow Boots", "Shining Boots", "Silky Boots"},
  {75,30, "Flame Gloves", "Pearly Gloves", "Pristine Gloves", "Shadow Gloves", "Shining Gloves", "Silky Gloves"},
  {85,30, "Flame Sash", "Pearly Sash", "Pristine Sash", "Shadow Sash", "Shining Sash", "Silky Sash"},
  {100,30, "Flame Circlet", "Pearly Circlet", "Pristine Circlet", "Shadow Circlet", "Shining Circlet", "Silky Circlet"},
  {110,30, "Flame Gown", "Pearly Gown", "Pristine Gown", "Shadow Gown", "Shining Gown", "Silky Gown"},
  {125,30, "Flame Leggings", "Pearly Leggings", "Pristine Leggings", "Shadow Leggings", "Shining Leggings", "Silky Leggings"},
  {165,60, "Black Handwraps", "Fiery Handwraps", "Frothing Handwraps", "Golden Handwraps", "Radiant Handwraps"},
  {190,60, "Mageweave Reagent Bag"},
  {195,60, "Netherflame Shoulders", "Netherfroth Shoulders", "Nethergeld Shoulders", "Netherlight Shoulders", "Netherpearl Shoulders", "Nethershine Shoulders"},
  {205,60, "Netherflame Cuffs", "Netherfroth Cuffs", "Nethergeld Cuffs", "Netherlight Cuffs", "Netherpearl Cuffs", "Nethershine Cuffs"},
  {215,60, "Black Waistcord", "Fiery Waistcord", "Frothing Waistcord", "Gilded Waistcord", "Golden Waistcord", "Radiant Waistcord", "Runecloth Reagent Bag"},
  {235,90, "Black Sandals", "Fiery Sandals", "Frothing Sandals", "Gilded Sandals", "Golden Sandals", "Radiant Sandals"},
},
leatherworking = {
  {60,30, "Brawler's Leather Belt", "Defender's Leather Belt", "Stormrider's Leather Belt", "Totemic Leather Belt", "Trapper's Leather Belt", "Wisdom's Leather Belt"},
  {70,30, "Brawler's Leather Boots", "Defender's Leather Boots", "Stormrider's Leather Boots", "Totemic Leather Boots", "Trapper's Leather Boots", "Wisdom's Leather Boots"},
  {80,30, "Brawler's Leather Tunic", "Defender's Leather Tunic", "Stormrider's Leather Tunic", "Totemic Leather Tunic", "Trapper's Leather Tunic", "Wisdom's Leather Tunic"},
  {90,30, "Brawler's Leather Gloves", "Defender's Leather Gloves", "Stormrider's Leather Gloves", "Totemic Leather Gloves", "Trapper's Leather Gloves", "Wisdom's Leather Gloves"},
  {100,30, "Brawler's Leather Legguards", "Defender's Leather Kilt", "Stormrider's Leather Kilt", "Totemic Leather Leggings", "Trapper's Leather Legguards", "Wisdom's Leather Leggings"},
  {110,30, "Brawler's Leather Hood", "Defender's Leather Hood", "Stormrider's Leather Hood", "Totemic Leather Hood", "Trapper's Leather Hood", "Wisdom's Leather Hood"},
  {175,60, "Skirmisher's Leather Gloves"},
  {185,60, "Forceful Thick Armor Kit"},
  {200,60, "Mender's Leather Gloves", "Prowler's Leather Gloves", "Skulker's Leather Gloves", "Skycaller's Leather Gloves", "Stalker's Leather Gloves", "Warden's Leather Gloves"},
  {210,60, "Mender's Leather Shoulders", "Mender's Mail Shoulders", "Prowler's Leather Shoulders", "Skirmisher's Mail Shoulders", "Skulker's Leather Shoulder", "Skycaller's Leather Shoulders", "Skycaller's Mail Shoulders", "Stalker's Mail Shoulders", "Warden's Leather Shoulders"},
  {220,90, "Mender's Leather Bracers", "Mender's Mail Bracers", "Prowler's Leather Bracers", "Skirmisher's Mail Bracers", "Skulker's Leather Bracers", "Skycaller's Leather Bracers", "Skycaller's Mail Bracers", "Stalker's Mail Bracers", "Warden's Leather Bracers"},
  {225,90, "Mender's Leather Waistguard", "Mender's Mail Belt", "Prowler's Leather Waistguard", "Skirmisher's Mail Belt", "Skulker's Leather Waistguard", "Skycaller's Leather Waistguard", "Skycaller's Mail Belt", "Stalker's Mail Belt", "Warden's Leather Waistguard"},
  {235,90, "Mender's Leather Boots", "Mender's Mail Sabatons", "Mystic Rugged Armor Kit", "Prowler's Leather Boots", "Skirmisher's Mail Sabatons", "Skulker's Leather Boots", "Skycaller's Leather Boots", "Skycaller's Mail Sabatons", "Stalker's Mail Sabatons", "Warden's Leather Boots"},
},
engineering = {
  {25,45, "SAF-T Dynamite", "SAF-T Tabs"}, {55,45, "SAF-T Copper Bomb"}, {85,45, "Satchel of Copper Bombs"},
  {100,45, "EZ-Thro Wrap"}, {130,45, "EZ-Thro Copper Bomb XL"}, {145,45, "No Slip SAF-T Padding"},
  {165,180, "Satchel of Bronze Bombs"},
  {175,180, "Clanking Cord", "Gizmo Girdle", "SAF-T Bell", "Whimsical Waistwrap"},
  {190,180, "EZ-Thro Fireproof Fuse"},
  {200,180, "Bent Goggles", "Dented Goggles", "Floppy Goggles", "Stuckbutton Goggles"},
  {225,270, "Compact Critter Carrier", "Emergency Field Cloak"}, {230,270, "Satchel of Iron Bombs"},
  {250,270, "Gnomish Army Knife", "SAF-T Disposable Parachute"}, {275,270, "Loot-A-Rang"},
  {285,270, "Satchel of Dark Iron Bombs"},
  {300,360, "Gnomish Poultryizer", "Stealthman 52", "Ultralight Goblin Glider", "Ultrasafe Rechargeable Battery"},
},
enchanting = {
  {130,45, "Mystic Mushroom", "Polished Driftwood Icon", "Tenets of the Silver Hand"},
  {140,45, "Enchant Weapon - Insight", "Enchant Weapon - Recovery", "Enchant Weapon - Revelation", "Glimmering Staff", "Orb of Mystic Insight", "Orb of Souls", "Soulstaff"},
  {210,120, "Enchant Necklace - Agility", "Enchant Necklace - Deflection", "Enchant Necklace - Healing Power", "Enchant Necklace - Spell Power", "Enchant Necklace - Strength", "Libram of Invocation", "Talons of Wrath", "Totem of Ancestral Protection"},
  {220,120, "Dreamstaff", "Enchant Chest - Absorption", "Radiant Staff", "Truesilver Conduit", "Twisting Essence Jar"},
  {275,180, "Brilliant Wand"},
  {300,240, "Enchant 2H Weapon - Mighty Healing Power", "Enchant 2H Weapon - Mighty Spell Power", "Enchant 2H Weapon - Spellblasting", "Enchant Bracer - Greater Spellpower", "Enchant Bracer - Superior Deflection", "Enchant Bracer - Superior Intellect", "Enchant Cloak - Agility", "Enchant Gloves - Arcane Power", "Enchant Gloves - Holy Power", "Enchant Gloves - Natural Power", "Enchant Gloves - Superior Strength", "Enchant Off Hand - Wisdom", "Idol of the Dream", "Libram of Holy Alacrity", "Totem of Thunder"},
},
alchemy = {
  {65,45, "Elixir of Lesser Spirit"}, {75,45, "Lesser Mageblood Elixir"},
  {95,45, "Elixir of Lesser Intellect", "Lesser Cleric's Elixir"}, {120,45, "Lesser Arcane Elixir"},
  {130,45, "Mender's Potion"}, {135,45, "Spellblasting Potion"}, {140,45, "Frenzy Potion"},
  {165,120, "Elixir of Greater Spirit"}, {175,120, "Greater Mageblood Elixir"}, {180,120, "Disorienting Smog Potion"},
  {195,120, "Greater Cleric's Elixir"}, {200,120, "Elixir of Greater Fortitude"}, {245,120, "Dragonfire Potion"},
  {250,180, "Elixir of the Phalanx"}, {265,180, "Caustic Smog Potion"},
  {275,180, "Elixir of Cunning", "Elixir of Ferocity", "Elixir of Sages", "Elixir of the Whale", "Potion of Venomous Blood"},
  {280,180, "Elixir of the Owl", "Major Mender's Potion", "Potion of Elemental Purging"},
  {285,180, "Elixir of Nature Power", "Elixir of Wicked Regeneration", "Major Spellblasting Potion"},
  {290,240, "Major Frenzy Potion"}, {300,240, "Elixir of the Grizzly"},
},
cooking = {
  {25,30, "Venomous Smoothie"}, {100,30, "Slimy Smoothie"}, {125,30, "Mrrggl Smrrthle"},
  {180,60, "Calcified Smoothie"}, {200,60, "Spicy Smoothie"}, {250,90, "Wicked Smoothie"},
},
}


--[[ Where to get crafting materials (used by the gear shopping lists)
  Plain words for a player. Classic sources, checked against the Wowhead Forever
  item pages for the new Forever materials (see PP.ScarceMats above).
  PP.MatInfo[itemID] = { "Name", "where to get it" }
  PP.MakeFrom[itemID] = { materialID, amount each }  -- things you make yourself
]]
local AH = " Or buy it on the Auction House."
local function ore(o, zones) return "Smelt " .. o .. " at any forge (Mining). You find " .. o .. " in " .. zones .. "." .. AH end
local function skin(lv) return "Skin beasts around level " .. lv .. " (Skinning)." .. AH end
local function cloth(lv) return "Drops from humanoid mobs (people) around level " .. lv .. "." .. AH end
local GEM = "Found now and then while mining ore veins." .. AH
local PEARL = "Open clams from murlocs, crabs and turtles along the coast." .. AH
local DUST = "Made by Enchanters when they disenchant green items." .. AH
local ELEM = "Drops from elemental mobs (fire, water, earth or air creatures)." .. AH
local HERB = "Pick it with Herbalism." .. AH
local VENDOR = "Sold by trade supply vendors in most towns."

PP.MatInfo = {
    -- bars
    [2840] = { "Copper Bar", ore("Copper Ore", "the starting zones: Elwynn Forest, Dun Morogh, Durotar, Mulgore, Tirisfal and Darkshore") },
    [3576] = { "Tin Bar", ore("Tin Ore", "Westfall, Redridge, Loch Modan, the Barrens and Silverpine") },
    [2841] = { "Bronze Bar", "Smelt 1 Copper Bar and 1 Tin Bar together at a forge (Mining 65)." .. AH },
    [2842] = { "Silver Bar", ore("Silver Ore", "Redridge, Hillsbrad and the Barrens (it is rare)") },
    [3575] = { "Iron Bar", ore("Iron Ore", "Arathi Highlands, Stranglethorn, Desolace and Thousand Needles") },
    [3577] = { "Gold Bar", ore("Gold Ore", "Arathi Highlands, Stranglethorn and the Badlands (it is rare)") },
    [3859] = { "Steel Bar", "Smelt 1 Iron Bar and 1 Coal at a forge (Mining 165). Mining supply vendors sell Coal." .. AH },
    [3860] = { "Mithril Bar", ore("Mithril Ore", "the Hinterlands, Tanaris, the Badlands and Searing Gorge") },
    [6037] = { "Truesilver Bar", ore("Truesilver Ore", "the same zones as Mithril (it is rare)") },
    [12359] = { "Thorium Bar", ore("Thorium Ore", "Un'Goro Crater, Winterspring, Burning Steppes and Eastern Plaguelands") },
    [12360] = { "Arcanite Bar", "Made by Alchemists (a transmute)." .. AH },
    [12655] = { "Enchanted Thorium Bar", "Made by Enchanters from a Thorium Bar." .. AH },
    -- stones and grinding stones (you make these)
    [2835] = { "Rough Stone", "Comes from mining Copper veins." .. AH },
    [2836] = { "Coarse Stone", "Comes from mining Tin veins." .. AH },
    [2838] = { "Heavy Stone", "Comes from mining Iron veins." .. AH },
    [7912] = { "Solid Stone", "Comes from mining Mithril veins." .. AH },
    [12365] = { "Dense Stone", "Comes from mining Thorium veins." .. AH },
    [3470] = { "Rough Grinding Stone", "You make this yourself (Blacksmithing): 2 Rough Stone each." },
    [3478] = { "Coarse Grinding Stone", "You make this yourself (Blacksmithing): 2 Coarse Stone each." },
    [3486] = { "Heavy Grinding Stone", "You make this yourself (Blacksmithing): 3 Heavy Stone each." },
    [7966] = { "Solid Grinding Stone", "You make this yourself (Blacksmithing): 4 Solid Stone each." },
    [12644] = { "Dense Grinding Stone", "You make this yourself (Blacksmithing): 4 Dense Stone each." },
    -- flux
    [2880] = { "Weak Flux", "Sold by blacksmithing and trade supply vendors in most towns." },
    [3466] = { "Strong Flux", "Sold by blacksmithing and trade supply vendors in most towns." },
    [18567] = { "Elemental Flux", "Sold by the Thorium Brotherhood vendor inside Blackrock Depths." .. AH },
    -- gems and pearls
    [774] = { "Malachite", GEM }, [818] = { "Tigerseye", GEM }, [1210] = { "Shadowgem", GEM },
    [1206] = { "Moss Agate", GEM }, [1705] = { "Lesser Moonstone", GEM }, [1529] = { "Jade", GEM },
    [3864] = { "Citrine", GEM }, [7909] = { "Aquamarine", GEM }, [7910] = { "Star Ruby", GEM },
    [12799] = { "Large Opal", GEM }, [12364] = { "Huge Emerald", GEM }, [12361] = { "Blue Sapphire", GEM },
    [5498] = { "Small Lustrous Pearl", PEARL }, [5500] = { "Iridescent Pearl", PEARL },
    [7971] = { "Black Pearl", PEARL }, [13926] = { "Golden Pearl", PEARL },
    -- leather and cloth
    [2318] = { "Light Leather", skin("1-20") }, [2319] = { "Medium Leather", skin("15-30") },
    [4234] = { "Heavy Leather", skin("25-40") }, [4304] = { "Thick Leather", skin("35-50") },
    [8170] = { "Rugged Leather", skin("45-60") },
    [2589] = { "Linen Cloth", cloth("5-15") }, [2592] = { "Wool Cloth", cloth("15-25") },
    [4306] = { "Silk Cloth", cloth("25-35") }, [4338] = { "Mageweave Cloth", cloth("35-45") },
    [14047] = { "Runecloth", cloth("45-60") },
    [2320] = { "Coarse Thread", VENDOR }, [2321] = { "Fine Thread", VENDOR }, [4291] = { "Silken Thread", VENDOR },
    [8343] = { "Heavy Silken Thread", VENDOR }, [14341] = { "Rune Thread", VENDOR },
    [2604] = { "Red Dye", VENDOR }, [2605] = { "Green Dye", VENDOR }, [4340] = { "Gray Dye", VENDOR },
    [2324] = { "Bleach", VENDOR }, [2325] = { "Black Dye", VENDOR }, [6260] = { "Blue Dye", VENDOR },
    [4289] = { "Salt", VENDOR },
    [3371] = { "Empty Vial", "Sold by alchemy supply vendors." }, [3372] = { "Leaded Vial", "Sold by alchemy supply vendors." },
    [8925] = { "Crystal Vial", "Sold by alchemy supply vendors." },
    -- enchanting
    [10940] = { "Strange Dust", DUST }, [10938] = { "Lesser Magic Essence", DUST }, [10939] = { "Greater Magic Essence", DUST },
    [11083] = { "Soul Dust", DUST }, [11137] = { "Vision Dust", DUST }, [11176] = { "Dream Dust", DUST },
    [16204] = { "Illusion Dust", DUST }, [11138] = { "Small Glowing Shard", DUST }, [11139] = { "Large Glowing Shard", DUST },
    [14343] = { "Small Brilliant Shard", DUST }, [14344] = { "Large Brilliant Shard", DUST },
    -- elemental
    [7067] = { "Elemental Earth", ELEM }, [7068] = { "Elemental Fire", ELEM }, [7069] = { "Elemental Air", ELEM },
    [7070] = { "Elemental Water", ELEM }, [7075] = { "Core of Earth", ELEM }, [7076] = { "Essence of Earth", ELEM },
    [7077] = { "Heart of Fire", ELEM }, [7078] = { "Essence of Fire", ELEM }, [7079] = { "Globe of Water", ELEM },
    [7080] = { "Essence of Water", ELEM }, [7081] = { "Breath of Wind", ELEM }, [7082] = { "Essence of Air", ELEM },
    [12803] = { "Living Essence", ELEM }, [12808] = { "Essence of Undeath", "Drops from undead mobs in the Plaguelands." .. AH },
    [12811] = { "Righteous Orb", "Drops from mobs in Stratholme." .. AH },
    -- herbs
    [2447] = { "Peacebloom", HERB }, [765] = { "Silverleaf", HERB }, [2449] = { "Earthroot", HERB },
    [785] = { "Mageroyal", HERB }, [2450] = { "Briarthorn", HERB }, [2452] = { "Swiftthistle", HERB },
    [2453] = { "Bruiseweed", HERB }, [3820] = { "Stranglekelp", HERB }, [3355] = { "Wild Steelbloom", HERB },
    [3356] = { "Kingsblood", HERB }, [3357] = { "Liferoot", HERB }, [3818] = { "Fadeleaf", HERB },
    [3821] = { "Goldthorn", HERB }, [3358] = { "Khadgar's Whisker", HERB }, [3819] = { "Wintersbite", HERB },
    [4625] = { "Firebloom", HERB }, [8831] = { "Purple Lotus", HERB }, [8836] = { "Arthas' Tears", HERB },
    [8838] = { "Sungrass", HERB }, [8839] = { "Blindweed", HERB }, [8845] = { "Ghost Mushroom", HERB },
    [8846] = { "Gromsblood", HERB }, [13463] = { "Dreamfoil", HERB }, [13464] = { "Golden Sansam", HERB },
    [13465] = { "Mountain Silversage", HERB }, [13466] = { "Plaguebloom", HERB }, [13467] = { "Icecap", HERB },
    -- made by other crafters
    [4255] = { "Green Leather Armor", "Made by Leatherworkers." .. AH },
    [5966] = { "Guardian Gloves", "Made by Leatherworkers." .. AH },
}

PP.MakeFrom = {
    [3470] = { 2835, 2 }, [3478] = { 2836, 2 }, [3486] = { 2838, 3 }, [7966] = { 7912, 4 }, [12644] = { 12365, 4 },
}
