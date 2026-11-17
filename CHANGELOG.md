# ProfessionPal changes

Every released version, newest first.

## 1.3.9 (2026-11-17)

- **Skinning in the Farm Planner.** A new Skinning tab covers Light, Medium, Heavy, Thick and Rugged Leather, with the best farming spots for your faction, the creature levels and the Skinning skill you need. These picks come from Classic farming guides, so WoW: Forever drop rates may differ.
- Mining, Herbalism and Skinning each get their own tab in a roomier Farm Planner. Hover over a place to read its full directions.
- Skinning spots that don't have a confirmed location show written directions instead of a map pin in the wrong place. Darkshore now points to a real hunting area.
- New spots: Riverglades for Heavy and Thick Leather, and Zephras Isle for Light Leather.
- **Prices from Market Ledger.** With Market Ledger 1.3.8 installed, picking a material shows its last scanned Auction House asking price and how old it is. Prices are only shown; they never change the plans.
- **Problem reports.** Type `/prof debug`, make the problem happen again, then `/prof debug report` and copy the text. `/prof debug off` turns it off. Nothing is sent anywhere.

Fully restart WoW after updating (a new file was added).

## 1.3.8 (2026-11-16)

- **Update notices.** If someone in your guild or group has a newer version, you get one message saying an update is out in the CurseForge app. Only version numbers are shared, and nothing is sent in combat.

Fully restart WoW after updating (a new file was added).

## 1.3.7 (2026-11-16)

- **Best zones to farm.** The Farm Planner now marks the top 1 or 2 zones for each ore and herb with a gold **BEST**, and lists them first. For example, Mithril shows The Hinterlands and Tanaris instead of Desolace.
- The picks come from Wowhead's ranked farming guides and Icy Veins' WoW: Forever routes. They look at good loops and spots close together, not just how many spots a zone has.
- When you click **Go** on a best zone, the map label says "(best zone)".
- Felwood has no spot map yet, so it can't be picked.

Type `/reload` after updating.

## 1.3.6 (2026-11-15)

- New **Farm Planner**. Type `/prof farm` or click **Farm Planner** at the top of the window.
- **By ore / herb:** pick something like Iron Ore and see every zone that has it, closest first, with how many spots it has and the zone's level.
- **By zone:** pick a zone and choose a plan there: one ore or herb, **All ore you can mine**, **All herbs you can pick**, or **Ore and herbs** if you have both professions.
- Green means your skill can gather it now. **Go** opens the map with the spots and a loop to follow.

Fully restart WoW after updating (a new file was added).

## 1.3.5 (2026-11-15)

- **Fewer errors in combat:** the farm route's map pin now waits until a fight ends before it moves to the next spot. This stops the "action blocked" errors you could get when opening the map or pressing Escape during combat.
- The map's **Next** button says "Next spot after combat" if you click it mid-fight.

Type `/reload` after updating.

## 1.3.4 (2026-11-15)

- **Gathering HUD:** point at a yellow ore or herb dot to see its name. No key needed, and clicks still go through to the world. Hold **Alt** if you want to click the map itself.
- New **farming counter** under the HUD: what you're gathering, how many are in your bags, full stacks, and how many you picked up this run. The ore or herb you just pointed at goes to the top. Drag it anywhere you like.
- Your saved spot marks step aside while the HUD is up, so they never cover the game's own dots.
- The node arrow now follows the dot you point at, instead of picking a possible spawn by itself. It starts off; turn it on in Settings with **Show arrow for the node I hover**.
- Easier-to-read text in the Gold Ledger theme, and buttons keep their labels on one line.

Fully restart WoW after updating, because this adds a new file.

## 1.3.3 (2026-11-15)

- New **Gathering HUD**: one key puts your minimap over your character, big and see-through, so ore and herb dots show up around you instead of in the corner. Press it again to put the minimap back.
- Clicks pass straight through the HUD to the world. Hold **Alt** and point at a dot to see what it is, like Iron Deposit or Mithril Deposit.
- It turns with your character, fades out in combat, and its size, see-through and height are in Settings.
- Set the key in **Key Bindings > AddOns > ProfessionPal**, or type `/prof hud`.

Fully restart WoW after updating, because this adds new files.

## 1.3.2 (2026-11-15)

- Your farm loop waits on the map when another guide or quest route takes over. Click **Resume** to get it back.
- **Rejoin** picks the loop back up near you, in the direction you were going. **Reverse** turns you around.
- If no road route can be found, the normal map pin keeps hopping from spot to spot.
- The map bar has its own row for buttons and shows which spot you are on.

Type `/reload` after updating.

## 1.3.1 (2026-11-14)



- Gathering markers reuse their existing frames and avoid unnecessary redraw work.

- Minimap tracking can fall back to readable tooltip text when the main tooltip data is incomplete.

- Expanded setup instructions for Market Ledger, TSM prices, AI plans and Shortest Path Forever routes.



Type `/reload` after updating. If you are adding a new addon, fully restart WoW once.



#### Use the tools together



1. Open `/prof` and choose your profession guide.

2. Install the separate [Market Ledger](https://github.com/Yungslaya/MarketLedger) addon for selling and planning. At the Auction House, click **Scan Bags**. ProfessionPal's needed materials are reserved.

3. Optional: configure the [TradeSkillMaster](https://www.tradeskillmaster.com/) desktop app for your realm and enable its compatible addons. Market Ledger reads available pricing context automatically. Stop competing auction scans or switch to TSM's **WoW UI** if scanning is busy.

4. For advice, choose **AI Help → Copy for AI** in Market Ledger. Paste into a chat, then import the returned PLAN with **Paste reply → Save plan**. No API key is required for copy and paste.

5. Click **Map** in your profession guide, Market Ledger's **Farm** tab or a Farm plan step. With [Shortest Path Forever](https://github.com/cjber/shortest-path-forever), it requests a travel route. Without it, use the normal map pin.

6. **Next** skips a gathering spot. **Clear** or **Stop route** ends the guide.



Asking prices do not guarantee sales. Gathering spots are possible spawns, not live node detections. Each sale or craft needs your click, and you follow the route yourself.



Thanks to the **TradeSkillMaster team**, **cjber and Shortest Path Forever contributors**, and **Wowhead's database contributors**. Their pricing APIs, routing and gathering-location data support these optional features. [Full setup and credits](https://github.com/Yungslaya/ProfessionPal#use-the-addons-together).

## 1.3.0 (2026-11-14)

- **Map buttons.** Every zone in the guide has a **Map** button. The world map opens on that zone with a dot for every known ore or herb spot and one loop to ride through them.
- **A pin that leads you.** If you are not in the zone, the pin goes on the flight point you know that is closest to the spots. When you reach a spot, the pin hops to the next one. **Next** skips a spot, **Clear** or **Stop route** ends it.
- **Arrow and minimap marks in new zones.** They now use the same spot data, so they work in zones you have not gathered in yet.
- **Riverglades and Zephras Isle** spots added.
- **Market Ledger moved out.** It is now [its own addon](https://github.com/Yungslaya/MarketLedger). Install it to keep using it; your saved prices and settings move over by themselves. The Market Ledger button here still opens it.

Spots are places a vein or herb can spawn, good to about 40 yards. They are not proof one is up right now.

**Optional:** with [Shortest Path Forever](https://github.com/cjber/shortest-path-forever) by cjber installed, the way there is drawn as its road route. Without it you get the game's own map pin. Spot data is from Wowhead's WoW: Forever database.

This release adds new files. **Fully restart WoW** after updating.

## 1.2.16 (2026-11-13)

- **AI Help** window in Market Ledger. It shows four steps and one button for the step you are on.
- Scans now save themselves when you reload or log out. The old Export step is gone.
- New **Plan** tab: it lists the AI's picks and ticks them off as you sell. Craft steps can make the whole amount with one click.
- New **Market Ledger Companion** app (attached below).
- New themes in Settings: Journal, Gold Ledger, Midnight, Emerald and Crimson.

### How to use AI Help

WoW addons cannot reach the internet, so a small Windows app carries your scan to the AI and brings the plan back.

**What you need**

- **Market Ledger Companion.** Download `MarketLedgerCompanion.pyw` below and double-click it.
- **[Python 3](https://www.python.org/downloads/)**, which is free. The Companion needs it to run.
- **Any AI chat**, such as ChatGPT or Claude. A free account works. No API key is needed.

**The four steps**

1. At the Auction House, open Market Ledger (`/ppauction`) and click **Scan Bags**.
2. Click **AI Help**, then **Save and reload**.
3. Open the Companion. Click **Copy for AI chat**, paste into your AI chat and send it. Copy the whole reply, then click **Paste AI reply**.
4. Type `/reload` and open the **Plan** tab.

The Companion only reads and writes files on your PC. It never touches the running game, and every auction, sale and craft is still your own click.

This release adds a new file. **Fully restart WoW** after updating.

## 1.2.15 (2026-11-11)

- Market Ledger now includes soulbound bag items with a sell price on the **Vendor** tab. Single pieces can appear even at 50% stock.
- Right-click a piece you want to keep to blacklist it. Use **Blacklist → Restore** to include it again.

Type `/reload` after updating.

## 1.2.14 (2026-11-11)

- **Blacklist items.** Right-click an item name in Market Ledger to skip it in future scans and recommendations. Open **Blacklist** and click **Restore** to include it again. Your list survives reloads.
- **Keep your stock limit.** At 50%, a scan of 8 items sets aside 4 to keep. After you sell the other 4, the Ledger leaves those last 4 alone. A new scan or a percentage change starts a new plan.

Type `/reload` after updating.

## 1.2.13 (2026-11-11)

Open Market Ledger from ProfessionPal to compare auction prices, vendor values and crafting opportunities. Scan prices at the Auction House and review listings before posting. Type /reload after updating.

## 1.2.12 (2026-11-10)

Aligned material counts and made Craft it open the right profession. Type /reload after updating.

## 1.2.11 (2026-11-09)

Find farming areas and pin them from material lists. Optional flight assistance starts off. Node guidance clears when you walk away. Restart WoW after updating.

## 1.2.10 (2026-11-08)

- Added green herb markers and gold ore markers to the world map and minimap.
- Fixed directions for overlapping nodes and nodes above or below you.
- Smaller direction arrow with just the node name and distance. Extra details are optional in Settings.
- Stops pointing at an empty spot after a short check.

Node directions start off in the starter setup. Saved map markers have their own switch in Settings. Saved spots are approximate and may be empty.

Type `/reload` after updating.

## 1.2.9 (2026-11-08)



- Quieter first-install setup: locked tracker, hidden in combat, showing learned professions. Extra spell buttons, gathering reminders, saved-node guidance and trainer purchases are opt-in. Existing settings are preserved.

- /prof starter and /prof restore switch presentation preferences without deleting imported guides, recipe data or saved gathering spots.

- Settings now fit inside a scrolling window.

- Optional display-only harvest reminders and guidance to previously discovered herb/ore spots. Saved locations are approximate and do not guarantee a node is present.

- Simpler gear picks hide rare-plan/hard-material recommendations by default; the full selection remains available in Settings.



Restart WoW after updating to load the new Harvest module, then use /prof.

## 1.2.8 (2026-11-06)

- New charcoal navy and warm gold look, clearer body text, and a highlighted next step.
- Profession buttons all use the same text size now (3 per row), and trainer, material and gear rows stay on one line, so text no longer overlaps.
- More space in the tracker and shorter button labels.
- Gear and gear shopping windows now scroll.
- Crafting checks materials in your bags and recipes learned by your character. Each click rechecks the recipe and requests one craft.
- Fixed gear recommendations appearing before your character could wear them.
- Fixed imported guide steps being skipped in shopping totals.
- Shopping status now accounts for missing plans. All starting zone choices show again.
- Auto-learn stops if a price cannot be read, and old callbacks stop when a trainer visit ends.

Update and type `/reload`. No new addon files were added.

## 1.2.7 (2026-11-05)

**What changed in 1.2.7**

- When you have **all the materials** for a gear piece, its button turns into a green **"Craft it"**.
  - First click: opens your profession window at that recipe.
  - Next click: makes **one** of that item, same as the game's own Create button.
- The "What You Need" window gets a big Craft it button too, with a note about where to stand (an anvil for Blacksmithing, a cooking fire for Cooking).
- If you don't know the recipe yet, it tells you to learn it at your trainer first.
- One click = one item, every time. Nothing repeats on its own.

Just update and `/reload`. No restart needed.

## 1.2.6 (2026-11-05)

**What changed in 1.2.6**

- Every gear pick now has a **"What I need"** button. It opens a shopping list for that piece:
  - Each material with **have / need** (green = you have enough, red = you don't).
  - **Where to get it** in plain words, for example "Smelt Copper Ore at any forge... You find it in Elwynn Forest, Dun Morogh..." or "Sold by trade supply vendors in most towns."
  - Things you make yourself (like grinding stones) also show what they're made from.
  - Plans you still need come first, with the Favor cost and a map pin to the camp.
- New **"Shop for All"** button: one list that adds up everything for all the pieces it recommends right now.
- For professions other than Blacksmithing, open your profession window once and it remembers each recipe's materials.

Just update and `/reload`. No restart needed.

## 1.2.5 (2026-11-05)

**What changed in 1.2.5**

- Gear picks now check if you can really make a piece:
  - Plans that cost **Merchant's Favor** (all crafting professions), and how much Favor you have.
  - Rare materials like **Pristine Leather**, Sulfuric Acid and Sandpaper.
  - Recipes you already know (open your profession window once so it can see them).
- If you can't make the best piece yet, it shows one you **can** make now, plus a **"Better:"** line with what the better piece needs.
- Hover a piece to see where to buy the plans, how to get Favor (fill Waylaid Crates, hand them in at the camp), and where rare materials come from.
- The gear window shows the Favor camp with a map pin: Three Corners in Redridge (Alliance), or outside the Crossroads in the Barrens (Horde).
- New setting: "Gear: hide pieces that need plans or rare mats".

Just update and `/reload`. No restart needed.

## 1.2.4 (2026-11-05)

**What changed in 1.2.4**

- Fixed: the Blacksmithing button on the tracker showed a purple gem. It now shows the Blacksmithing hammer.
- All profession buttons now always use their own profession icon.

Just update and `/reload`. No restart needed.

## 1.2.3 (2026-11-05)

**What changed in 1.2.3**

- Trainers and farm zones are now sorted by how long the trip really takes, not just by map distance.
- It counts boats, the Deeprun Tram and zeppelins for your faction.
- Example: in Auberdine, Journeyman Engineering now sends you to Stormwind by boat instead of Gadgetzan or Hyjal.
- Trainers who only teach higher ranks are listed lower, unless nobody else is close.

Just update and `/reload`. No restart needed.

## 1.2.2 (2026-11-05)

Fix: map pins for Stormwind trainers and vendors now point to the right spot on WoW Forever's Stormwind map. Also fixed Alchemy trainers on Zephras Isle and two trainers who moved. /reload is enough after updating.

## 1.2.1 (2026-11-05)

New look: dark navy windows with a lighter header strip, thin blue borders and flat navy buttons with gold text. Tip: for a solid look, open Settings and press Darker next to Background a few times. /reload is enough after updating.

## 1.2.0 (2026-11-05)

New: import any guide. Open a leveling guide in your browser, press Ctrl+A then Ctrl+C, click Guides in /prof and paste it. ProfessionPal follows that guide with the same have/need counts, trainers and tracker. Share it with friends as text, or switch back any time. Restart WoW after updating (new file).

## 1.1.2 (2026-11-05)

New: the guide tells you when a step needs a new recipe (like Heavy Linen Bandage at First Aid 40) and shows the closest trainer. The tracker now has a button for every profession you have. Restart WoW after updating (new file).

## 1.1.1 (2026-11-05)

Closest first: the guide now lists every starting zone and sorts zones and trainers by how far they are from you ("you are here" marks your zone). The tracker shows the closest zone too. To update: delete your old ProfessionPal folder, unzip this one into the same AddOns folder, then /reload.

## 1.1.0 (2026-11-05)

First public beta. Download ProfessionPal.zip below, unzip it into _forever_\Interface\AddOns, start WoW, type /prof. All 12 professions, class gear picks, on-screen tracker. Auto-learn ships off.
