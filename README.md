# ProfessionPal

**Every profession in WoW: Forever, from skill 1 to 300, inside the game.**
It reads your real skill, counts your bags and bank, and tells you the one thing to do next.

### [⬇ Download ProfessionPal (zip)](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/ProfessionPal.zip)

No account needed. Beta 1.2.16 · for WoW: Forever (interface 16001)

**Want it to update itself?** Get the **[Dragbags Addon Updater](https://github.com/Yungslaya/DragbagsAddonUpdater)**: one click installs ProfessionPal, and it keeps it up to date every time you log in to Windows.

| 12 | 1–300 | 521 | 9 |
|:--:|:--:|:--:|:--:|
| professions | every skill point mapped | crafted items ranked | classes, 3 roles |

---

## Starter setup (starter setup)

New installs use your learned professions, a locked tracker that hides in combat, automatic gear role selection, and simpler gear picks. Extra tracker spell buttons, harvest reminders, saved-node guidance and automatic trainer purchases start off. Guide imports and other options remain available.

Use `/prof` for the guide and Settings. `/prof starter` previews the starter options; `/prof restore` restores your previous preferences. Imported guides, learned recipes, selected plans and saved gathering spots are retained. Existing users keep their settings. Settings now fit inside a scrolling window.

## What it does

- **One next step.** "Make 25 × Bronze Warhammer" or "Mine Tin and Silver in Hillsbrad". Updates the moment you skill up.
- **Have / need for every material,** counted across your bags and bank. Green when you're covered.
- **Trainers on the map.** Knows when you're about to cap, which trainer teaches your next rank, and drops a map pin (or a TomTom arrow).
- **Shopping list** for everything until your next training.
- **Gear For You.** Ranks the gear your profession can craft for your class and role, slot by slot, against what you're wearing right now.
- **On-screen tracker.** A small guide box that stays up, with one-click Find Minerals, Find Herbs and Smelting buttons. See-through, movable, hides in combat.
- **Import any guide.** Copy a guide page in your browser (Ctrl+A, Ctrl+C), click **Guides**, paste it. ProfessionPal turns it into its own step-by-step view with the same have/need counts, trainers and tracker. Share it with friends as text, or switch back to the built-in guide any time.
- **Optional auto-learn.** At a trainer you opened, it learns the recipes the guide needs, up to a gold limit you set. Off until you turn it on.

Covers Mining, Herbalism, Skinning, Fishing, Blacksmithing, Alchemy, Leatherworking, Tailoring, Engineering, Enchanting, Cooking and First Aid.

## Market Ledger: sell your bags smarter

Type `/ppauction`, or click **Market Ledger** in the guide window. At the Auction House, click **Scan Bags**. It prices what you carry and sorts it into Auction, Vendor, Craft and Keep. Every auction, sale and craft is one click from you. Nothing is sold for you.

### AI Help: let an AI plan your sales

The addon cannot talk to an AI by itself, because WoW addons cannot reach the internet. A small Windows app, the **Market Ledger Companion**, carries your scan to the AI and brings the plan back.

**What you need**

- **The Market Ledger Companion.** Get it one of two ways:
  - Easy: open the [Dragbags Addon Updater](https://github.com/Yungslaya/DragbagsAddonUpdater), tick **Market Ledger Companion (app)** and click **Update / Install**. It puts a shortcut on your Desktop and keeps the app up to date.
  - By hand: [download MarketLedgerCompanion.pyw](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/MarketLedgerCompanion.pyw), save it anywhere and double-click it.
- **[Python 3](https://www.python.org/downloads/)**, which is free. The Companion needs it to run. Nothing else to install.
- **Any AI chat**: ChatGPT, Claude or another one. A free account works. No API key is needed.

**The four steps.** Click **AI Help** in Market Ledger. The window marks the step you are on.

1. **Scan prices.** Stand at the Auction House and click **Scan Bags**.
2. **Save the scan.** Click **Save and reload**. This writes your scan to disk.
3. **Ask the AI.** Open the Companion. Click **Copy for AI chat**, paste into your AI chat and send it. Copy the AI's whole reply, then click **Paste AI reply**. The Companion checks the plan against your scan and saves it.
4. **Follow the plan.** Type `/reload` in WoW and open the **Plan** tab. Rows tick off as you sell.

The Companion only reads and writes files on your PC, the same way the TradeSkillMaster app does. It never touches the running game, and you still click every sale yourself. Your plan is kept when the updater updates ProfessionPal (updater 1.1.0 or newer).

## What's new

- **1.2.16:** Market Ledger has a new **AI Help** window with four clear steps and one button for the step you are on. Scans now save themselves when you reload or log out. A new **Plan** tab lists the AI's picks and ticks them off as you sell. New [Market Ledger Companion](#ai-help-let-an-ai-plan-your-sales) app, which the Dragbags Addon Updater can install. New themes in Settings: Journal, Gold Ledger, Midnight, Emerald and Crimson. New file: fully restart WoW after updating.
- **1.2.15:** Market Ledger lists soulbound bag items with a sell price on the Vendor tab.
- **1.2.14:** Right-click an item in Market Ledger to blacklist it.
- **1.2.13:** Market Ledger added: scan your bags at the Auction House and see what to auction, vendor, craft or keep.

- **1.2.10:** Added saved herb and ore map markers, smaller node directions, and fixes for overlapping and elevated nodes. Type `/reload` after updating.

- **1.2.9:** Starter setup with optional extras, preserved existing preferences, and reversible presentation presets. See the release notes for fixes and validation.

- **1.2.9 (local test, not published):** Harvest reminders for your character's Mining, Herbalism and Skinning. A small floating icon shows the object and whether it is in reach, farther away, blocked or above your skill. Uses the game's nearby interaction target, mouseover or selected corpse; it does not scan the whole world. No gathering or setting changes happen automatically. New file: fully restart WoW to try it.
- **1.2.8:** New charcoal-and-gold look, clearer text and a highlighted next step. No more overlapping text: same-size profession buttons, one-line trainer rows. Gear windows scroll. Fixed crafting checks, early armor recommendations, and imported shopping totals.
- **1.2.7:** When you have all the materials for a gear piece, its button turns into a green "Craft it". Click once to open your profession at that recipe, click again to make it. It also tells you where to stand (anvil, cooking fire...).
- **1.2.6:** Every gear pick has a "What I need" button: a shopping list with have/need and where to get each material. "Shop for All" adds up everything for all the pieces it recommends.
- **1.2.5:** Gear picks now know about Merchant's Favor plans and rare materials (like Pristine Leather). If you can't make a piece yet, you get one you can make now, plus a "Better:" line that says what the better piece needs and where to get it.
- **1.2.4:** Fixed the Blacksmithing button showing a purple gem. Profession buttons now always show their own icon.
- **1.2.3:** Trainers and farm zones are now sorted by real travel time, using boats, the tram and zeppelins, not just map distance. In Auberdine, Journeyman Engineering now sends you to Stormwind by boat instead of Gadgetzan.
- **1.2.2:** Map pins fixed for WoW Forever's Stormwind map.
- **1.2.1:** New navy look that matches RestedXP.
- **1.2.0:** Import any guide by pasting it in.
- **1.1.2:** Reminders to learn new recipes, and a button for every profession.

All versions: [Releases](https://github.com/Yungslaya/ProfessionPal/releases)

## Install (2 minutes)

1. **[Download the zip](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/ProfessionPal.zip)**, then close WoW.
2. **Unzip it.** You get one folder called `ProfessionPal`.
3. **Move that folder** into your AddOns folder. On a default install:
   ```
   C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns
   ```
   It should be one folder deep: `AddOns\ProfessionPal\ProfessionPal.toc`.
4. **Start WoW.** On the character screen click **AddOns** and make sure ProfessionPal is ticked.
5. In game, type **`/prof`**.

## Is it safe to run?

Yes. It reads your skill and your bags and shows you text. It never crafts, gathers, moves your character or buys anything by itself. The spell buttons are ordinary click buttons, one click and one cast, same as your action bar. The **Craft it** button works the same way: one click makes one item, just like the Create button in the game's own profession window. The only thing that can spend gold is auto-learn, and it ships switched off.

## Testers

This is a beta. If anything looks off, send a screenshot. To see error messages in game, type `/console scriptErrors 1` once.

Known limits: crafting steps above skill 225 come from Wowhead's planner and haven't been run live yet, and gear picks are ranked by item stats.

## Data

Built from the [Icy Veins WoW: Forever profession guides](https://www.icy-veins.com/wow-forever/professions-overview) for all 12 professions and the [Wowhead WoW: Forever](https://www.wowhead.com/forever/guides/professions) item database.

## Code review

Crafting checks bag materials and this character's recipes. Gear and shopping windows scroll. Current gear picks respect your level. See [review findings](REVIEW.md) for fixes, tests, and remaining limits.

Visual refresh: charcoal navy panels, warm gold accents, clear body text, a highlighted next step, and wider tracker rows. Included in 1.2.8.

## Harvest reminders (local 1.2.9 test)

Learn Mining, Herbalism or Skinning. The reminder only shows matches for the current character's professions, and stays hidden during combat.

- For nearby detection, enable **Interact Key** in WoW's **Options > Controls**. ProfessionPal does not change that setting itself.
- You can also hover an object or select a skinnable corpse. The game's selected interaction object is used; resources outside that selection are not all scanned.
- **In reach** requires a positive harvest cursor and range check. Unknown range is labelled as unconfirmed. A grey cursor is shown as blocked, without guessing why. Skill requirements are read from readable English tooltip text when available.
- `/prof harvest test` shows a five-second preview.
- `/prof harvest unlock` lets you drag the reminder. `/prof harvest lock` makes it click-through again.
- `/prof harvest off` / `/prof harvest on` turn it off or on. There is also a checkbox in ProfessionPal Settings.
- `/prof harvest reset` restores its starting position.

Test near a herb, ore vein or a looted skinnable corpse, then move in and out of reach. This is a local test build; it has not been published to GitHub or the addon updater.

### Saved-node arrow (local 1.2.9 test)

- Hover a new herb/ore dot on your minimap once. Its name and an approximate direction arrow appear above your character. You can move the mouse away immediately.
- When a nearby herb/ore node has a usable cursor and is in reach, ProfessionPal saves the approximate spot in its saved settings. It also learns the name. Hovering a dot alone does not save a confirmed gathering spot.
- On later visits, saved nodes within 150 yards generate a **Possible** name and arrow automatically, with no hovering. Historical coordinates never prove a node is spawned.
- A matching, detected nearby node changes the prompt to **Detected nearby**. If no live node is confirmed at the spot, the prompt says to search nearby, then pauses that spot rather than claiming it is empty.
- The coordinate and distance estimates are approximate. The arrow stays separate from your quest/TomTom waypoint and does not move your character.
- Skinning still uses live nearby detection; corpses are not saved as permanent node spawns.
- `/prof harvest skip` skips the current spot for two minutes. `/prof harvest map` shows the saved count for this zone.
- `/prof harvest guide off` / `guide on` control the arrow; there is also a **Guide to saved herb and ore spots** checkbox.

Reload to test this extension. New live nodes are still limited by what the game exposes: this is historical guidance plus live nearby confirmation, not an unattended scan of undiscovered minimap dots. Nothing in this local test has been published.
