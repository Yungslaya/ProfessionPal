ProfessionPal 1.2.6 (beta)  -  a profession leveling guide for WoW: Forever
==========================================================================

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
  Share it with friends as text. Switch back any time.
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
or buys for you. The spell buttons are normal click buttons (one click
= one cast, like an action bar). The only thing that spends gold is the
optional auto-learn, and it is off until you turn it on.

WHERE THE DATA COMES FROM
-------------------------
Icy Veins WoW: Forever leveling guides (all 12 professions) and the
Wowhead WoW: Forever database (crafted gear stats, and the 225-300 part
of crafting professions where Icy Veins has no plan yet).

BETA - PLEASE REPORT
--------------------
This is a test build. If something looks wrong, send a screenshot.
To see Lua errors in game, type:  /console scriptErrors 1
Known limits: crafting steps above 225 come from Wowhead's planner and
are not tested live yet; gear picks are ranked by item stats.
