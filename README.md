# ProfessionPal

**Every profession in WoW: Forever, from skill 1 to 300, inside the game.**
It reads your real skill, counts your bags and bank, and tells you the one thing to do next.

### [⬇ Download ProfessionPal (zip)](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/ProfessionPal.zip)

No account needed. Beta 1.2.5 · for WoW: Forever (interface 16001)

**Want it to update itself?** Get the **[Dragbags Addon Updater](https://github.com/Yungslaya/DragbagsAddonUpdater)**: one click installs ProfessionPal, and it keeps it up to date every time you log in to Windows.

| 12 | 1–300 | 521 | 9 |
|:--:|:--:|:--:|:--:|
| professions | every skill point mapped | crafted items ranked | classes, 3 roles |

---

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

## What's new

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

Yes. It reads your skill and your bags and shows you text. It never crafts, gathers, moves your character or buys anything by itself. The spell buttons are ordinary click buttons, one click and one cast, same as your action bar. The only thing that can spend gold is auto-learn, and it ships switched off.

## Testers

This is a beta. If anything looks off, send a screenshot. To see error messages in game, type `/console scriptErrors 1` once.

Known limits: crafting steps above skill 225 come from Wowhead's planner and haven't been run live yet, and gear picks are ranked by item stats.

## Data

Built from the [Icy Veins WoW: Forever profession guides](https://www.icy-veins.com/wow-forever/professions-overview) for all 12 professions and the [Wowhead WoW: Forever](https://www.wowhead.com/forever/guides/professions) item database.
