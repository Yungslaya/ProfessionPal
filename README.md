# ProfessionPal

**Every profession in WoW: Forever, from skill 1 to 300, inside the game.**
It reads your skill, counts your bags and bank, and tells you the one thing to do next.

### [⬇ Download ProfessionPal (zip)](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/ProfessionPal.zip)

Also on CurseForge. Version 1.3.4 · for WoW: Forever (interface 16001)

| 12 | 1–300 | 521 | 9 |
|:--:|:--:|:--:|:--:|
| professions | every skill point mapped | crafted items ranked | classes, 3 roles |

---

## What it does

- **One next step.** "Make 25 × Bronze Warhammer" or "Mine Tin and Silver in Hillsbrad". It updates the moment you skill up.
- **Have / need for every material,** counted across your bags and bank. Green when you have enough.
- **Trainers on the map.** It knows when you're about to cap, which trainer teaches your next rank, and drops a map pin (or a TomTom arrow).
- **Shopping list** for everything until your next training.
- **Gear For You.** Ranks the gear your profession can craft for your class and role, slot by slot, against what you're wearing.
- **On-screen tracker.** A small box that stays up, with Find Minerals, Find Herbs and Smelting buttons. Movable, and it hides in combat.
- **Import any guide.** Copy a guide page in your browser (Ctrl+A, Ctrl+C), click **Guides** and paste it. You get the same step view, counts and trainers. Switch back to the built-in guide any time.
- **Auto-learn (optional).** At a trainer you opened, it learns the recipes the guide needs, up to a gold limit you set. Off until you turn it on.

Covers Mining, Herbalism, Skinning, Fishing, Blacksmithing, Alchemy, Leatherworking, Tailoring, Engineering, Enchanting, Cooking and First Aid.

Type `/prof` or click the minimap button to open it. `/prof starter` shows the simple starting settings, and `/prof restore` puts your old settings back.

## Show me where to go

Every zone in the guide has a **Map** button. Click it and the world map opens on that zone with:

- a dot for every known ore or herb spot, and one loop to ride through them
- a pin on the closest flight point you know, or on the nearest spot if you are already in the zone
- a bar with the route buttons

When you reach the pin, it hops to the next spot.

- **Next** skips a spot that has nothing.
- **Rejoin** picks the loop back up near you, in the direction you were going.
- **Reverse** turns you around on the loop.
- **Clear** on the map, or **Stop route** in the guide window, ends it.

If another guide or quest route takes over, your loop waits on the map. Click **Resume** to get it back.

Saved minimap marks show places a node *can* spawn, good to about 40 yards. A node may not be up when you get there.

**Optional:** with [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) by cjber installed, you get a road route with boats and flights. Without it you get the game's map pin. None of its code is included.

## Farm Planner

Type `/prof farm` or click **Farm Planner** at the top of the window. Pick **Mining**, **Herbalism** or **Skinning** at the top, then:

- **By material:** pick something like Iron Ore or Thick Leather and see every zone that has it.
- **By zone:** pick a zone and choose what to farm there, including **All ore you can mine**, **All herbs you can pick** and **All leather you can skin**.

All three work the same way. Each zone shows its spots (for leather: the beasts you can skin), the zone level and how far away it is. A gold **BEST** marks the top 1 or 2 zones for each ore, herb and leather, picked from Wowhead's ranked farming guides and Icy Veins' WoW: Forever routes, and they are listed first. **Map** opens the map with every spot and a loop to ride.

Leather spots are where skinnable beasts of the right level spawn, from the Wowhead WoW: Forever database. Travel times come from [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) when you have it installed.

## Gathering HUD

Press one key and your minimap moves over your character, big and see-through, so ore and herb dots show up around you while you ride. Press it again to put it back.

- Clicks pass straight through to the world.
- Point at a yellow ore or herb dot to see its name. Hold **Alt** if you want to click the map itself.
- A small **farming counter** under the HUD shows what you're gathering: bag count, full stacks, and how many you picked up this run. Drag it anywhere.
- It turns with you and fades out in combat. Size, see-through and height are in Settings.
- Set the key in **Key Bindings > AddOns > ProfessionPal**, or type `/prof hud`.

It only moves the game's own minimap. It never moves you or gathers for you.

## Gathering reminders

Learn Mining, Herbalism or Skinning. When you hover a node, look at it with the Interact Key, or target a skinnable corpse, a small icon shows what it is and whether you can reach it and have the skill.

- `/prof harvest test` shows a preview.
- `/prof harvest unlock` lets you drag it. `/prof harvest lock` locks it again.
- `/prof harvest off` / `on` turns it off or on. There is also a box in Settings.
- `/prof harvest guide on` / `off` turns the node arrow on or off. It follows the dot you point at on the minimap or HUD. It starts off.
- `/prof harvest skip` skips the current spot for two minutes.

It only reads what the game shows you. It never gathers or moves you.

## Works with Market Ledger

**[Market Ledger](https://github.com/Yungslaya/MarketLedger)** is a separate addon. It prices your bags at the Auction House and tells you what to auction, vendor, craft or keep. With both installed:

- Market Ledger won't sell materials your guide still needs.
- Its **Farm** tab uses ProfessionPal's maps.
- The **Market Ledger** button in the guide window opens it.

ProfessionPal works fine without it.

## What's new

- **1.6.0:** New look for every window and the tracker, button text that fits, and a What's new window after updates. Fully restart WoW after updating.
- **1.5.2:** One herb/ore label instead of two; the label over your head says In reach, Move closer or the skill you need. Type `/reload` after updating.
- **1.5.1:** Floating icon over herbs and ore (turns on WoW's Interact Key, so herb and ore reminders work), and farm zones follow your faction. Type `/reload` after updating.
- **1.5.0:** New look, skill-up chance and skill bar, shopping list cost, five more languages. Fully restart WoW after updating.
- **1.4.4:** The minimap checkbox in Settings follows `/prof minimap`. Type `/reload` after updating.
- **1.4.3:** New minimap button to open the guide (right-click for Settings). Fully restart WoW after updating.
- **1.4.2:** The Gathering HUD no longer causes an error in the quest tracker. Type `/reload` after updating.
- **1.4.1:** Farm Planner fixes: button names stay next to their icons, and the scroll note no longer covers the bottom line. Type `/reload` after updating.
- **1.4.0:** A rebuilt **Farm Planner**: leather now shows beast spots and a loop on the map, just like ore and herbs, with **BEST** leather zones from the farming guides. Real travel times with Shortest Path Forever. The Gathering HUD now always hides in fights. Fully restart WoW after updating.
- **1.3.9:** New **Skinning** tab in the Farm Planner with the best leather farms, Market Ledger prices for your materials, and `/prof debug` problem reports. Fully restart WoW after updating.
- **1.3.8:** A message tells you when a newer version is out in the CurseForge app. Fully restart WoW after updating (a new file was added).
- **1.3.7:** The Farm Planner marks the **BEST** 1 or 2 zones for each ore and herb, from Wowhead's and Icy Veins' farming guides. Type `/reload` after updating.
- **1.3.6:** New **Farm Planner**: pick an ore, herb or zone and start a farm loop there. Type `/prof farm`. Fully restart WoW after updating.
- **1.3.5:** The map pin waits until combat ends, so no more "action blocked" errors in fights. Type `/reload` after updating.
- **1.3.4:** Point at a HUD dot to see its name, a new farming counter under the HUD, and an arrow that follows the dot you point at. Fully restart WoW after updating.
- **1.3.3:** New **Gathering HUD**: your minimap over your character, big and see-through. Hold Alt to read a dot. Fully restart WoW after updating.
- **1.3.2:** Farm loops wait on the map instead of stopping when another route takes over, with **Resume**, **Rejoin** and **Reverse** buttons. If no road route can be found, the normal map pin keeps hopping. Type `/reload` after updating.
- **1.3.1:** Gathering marks draw faster. Minimap hover works with more node tooltips. Type `/reload` after updating.
- **1.3.0:** New **Map** buttons with every ore and herb spot, a loop to follow, and a pin that hops to the next spot. Riverglades and Zephras Isle spots added. Market Ledger moved to its own addon. Fully restart WoW after updating.
- **1.2.16:** New themes in Settings: Journal, Gold Ledger, Midnight, Emerald and Crimson.
- **1.2.13 – 1.2.15:** Market Ledger was added (it is now its own addon).
- **1.2.10:** Herb and ore marks on the world map and minimap, and better directions for nodes that overlap or sit above you.
- **1.2.9:** Gathering reminders and simple starting settings.
- **1.2.8:** New charcoal-and-gold look. Gear windows scroll. Fixed crafting checks and some gear picks.
- **1.2.7:** When you have the materials, a gear pick's button turns into a green **Craft it**.
- **1.2.6:** **What I need** shopping list on every gear pick, and **Shop for All**.
- **1.2.5:** Gear picks know about Merchant's Favor plans and rare materials.
- **1.2.3:** Trainers and farm zones sorted by real travel time, with boats, the tram and zeppelins.
- **1.2.0:** Import any guide by pasting it in.

All versions: [Releases](https://github.com/Yungslaya/ProfessionPal/releases)

## Install

1. **[Download the zip](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/ProfessionPal.zip)**, then close WoW.
2. **Unzip it.** You get one folder called `ProfessionPal`.
3. **Move that folder** into your AddOns folder. On a default install:
   ```
   C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns
   ```
   It should be one folder deep: `AddOns\ProfessionPal\ProfessionPal.toc`.
4. **Start WoW.** On the character screen click **AddOns** and make sure ProfessionPal is ticked.
5. In game, type **`/prof`**.

## Is it safe?

Yes. It reads your skill and bags and shows you text. It never crafts, gathers, moves you or buys anything by itself. The spell buttons and **Craft it** work like your action bar: one click, one cast. The only thing that can spend gold is auto-learn, and it starts off.

## Found a problem?

Send a screenshot and your profession skill on the [issues page](https://github.com/Yungslaya/ProfessionPal/issues). To see error messages in game, type `/console scriptErrors 1` once.

Crafting steps above skill 225 come from Wowhead's planner and haven't all been checked in game yet. Gear picks are ranked by item stats.

## Credits

- Guides built from the [Icy Veins WoW: Forever profession guides](https://www.icy-veins.com/wow-forever/professions-overview) and the [Wowhead WoW: Forever](https://www.wowhead.com/forever/guides/professions) item database.
- Ore, herb and beast spots from the [Wowhead WoW: Forever database](https://www.wowhead.com/forever).
- Best farming zones from Wowhead's [mining](https://www.wowhead.com/classic/guide/classic-mining-best-farming-basics-early-ores) and herbalism ([1-150](https://www.wowhead.com/classic/guide/classic-herbalism-best-farming-basics-early-herbs), [150-300](https://www.wowhead.com/classic/guide/classic-herbalism-best-farming-high-end-herbs)) and [leather](https://www.wowhead.com/classic/guide/classic-leather-farming-early-leather) farming guides and the [Icy Veins WoW: Forever mining](https://www.icy-veins.com/wow-forever/mining-leveling-guide) and [herbalism](https://www.icy-veins.com/wow-forever/herbalism-leveling-guide) leveling guides, plus the [Icy Veins WoW: Forever skinning guide](https://www.icy-veins.com/wow-forever/skinning-leveling-guide).
- Road routes by [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) by cjber (optional).
