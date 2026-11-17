ProfessionPal 1.4.0  -  a profession leveling guide for WoW: Forever
===================================================================

Every profession, skill 1 to 300, inside the game. Type /prof.

WHAT IT DOES
------------
- Reads your real profession skill and shows ONE clear next step:
  what to make (and how many), or where to gather.
- Counts your materials in bags + bank: "have / need", green or red.
- Tells you when to train, where the trainer is (zone + coordinates),
  and puts a pin on your map (or a TomTom arrow if you use TomTom).
- Shopping List: everything you need until your next training.
- Gear For You: the best piece you can craft for your class and role,
  slot by slot, compared to what you are wearing.
- On-screen tracker box (like a leveling guide) that stays up,
  with one-click Find Minerals / Find Herbs / Smelting buttons.
- Import any guide: copy a guide page in your browser (Ctrl+A, Ctrl+C),
  click Guides, paste it (Ctrl+V). ProfessionPal follows that guide instead.
  Switch back any time.
- Map buttons: the world map opens on a zone with every ore and herb
  spot and a loop to follow. The pin hops to the next spot when you
  get there. Optional road routes with Shortest Path Forever by cjber.
- Farm Planner (/prof farm): pick an ore, herb, leather or zone and choose a
  farm plan there. Go opens the map with the loop to follow.
  BEST marks the top zones for each ore and herb.
- Gathering HUD: one key puts your minimap over your character, big
  and see-through. Point at a dot to see its name, with a small
  farming counter underneath. Set the key in Key Bindings
  > AddOns > ProfessionPal, or type /prof hud.
- Works with the separate Market Ledger addon: it won't sell
  materials your guide still needs.
- Covers all 12 professions: Mining, Herbalism, Skinning, Fishing,
  Blacksmithing, Alchemy, Leatherworking, Tailoring, Engineering,
  Enchanting, Cooking, First Aid.

INSTALL
-------
1. Close World of Warcraft.
2. Unzip this file. You get a folder named "ProfessionPal".
3. Put that folder here (default install path):
     C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\
   so you end up with:
     ...\_forever_\Interface\AddOns\ProfessionPal\ProfessionPal.toc
   (Not ProfessionPal\ProfessionPal\... - one folder deep only.)
4. Start WoW. On the character screen click "AddOns" and make sure
   ProfessionPal is checked.
5. In game type:  /prof

SETTINGS (button in the window)
-------------------------------
- Window size, lock, tracker on/off, tracker see-through, hide in combat.
- "Gear for": Auto / Damage / Tank / Healer.
- Show all professions.
- Auto-learn at trainer: OFF by default. When on, it learns the recipes
  the guide needs while YOU have a trainer window open, up to a gold
  limit you pick. Same idea as an auto-repair addon.

IS IT SAFE?
-----------
It only reads and shows information. It never crafts, gathers, moves,
or buys by itself. The spell buttons are normal click buttons (one click
= one cast, like an action bar). The "Craft it" button is the same:
one click = one item, like the game's own Create button. The only thing that spends gold is the
optional auto-learn, and it is off until you turn it on.

WHERE THE DATA COMES FROM
-------------------------
Icy Veins WoW: Forever leveling guides (all 12 professions) and the
Wowhead WoW: Forever database (crafted gear stats, ore and herb spots,
and the 225-300 part of crafting professions where Icy Veins has no plan yet).

FOUND A PROBLEM?
----------------
Send a screenshot on the CurseForge page.
To see Lua errors in game, type:  /console scriptErrors 1
Known limits: crafting steps above 225 come from Wowhead's planner and
are not all checked in game yet; gear picks are ranked by item stats.

1.4.0: New Farm Planner. Leather shows beast spots on the map like ore and herbs. HUD hides in fights. Fully restart WoW after updating.
1.3.9: Skinning tab in the Farm Planner, Market Ledger prices, /prof debug. Fully restart WoW after updating.
1.3.8: Tells you when a newer version is out. Fully restart WoW after updating.
1.3.7: BEST marks the top farm zones. Type /reload after updating.
1.3.6: New Farm Planner (/prof farm). Fully restart WoW after updating.
1.3.5: The map pin waits until combat ends. Type /reload after updating.
1.3.4: Dot names on hover, farming counter. Fully restart WoW after updating.

Farm Planner diagnostics: /prof debug, reproduce the problem, then /prof debug report.
Copy the report with Ctrl+A and Ctrl+C. /prof debug off stops capture.
Skinning routes use recorded hunting areas where available; other areas show directions.
