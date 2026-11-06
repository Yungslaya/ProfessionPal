# ProfessionPal code review

Reviewed: published GitHub HEAD `22db363` (1.2.7), compared with the local game copy. The game copy also contains the unpublished layout cleanup.

These changes are included in release 1.2.8. No addon data has been re-researched during this code review.

## Fixed

- Craft readiness included bank materials. Shopping still includes the bank; Craft now requires bag materials and a recipe known by this character.
- Recipe IDs were shared across characters. They are now stored per character. Each craft click rechecks the recipe name, learned state, output item when available, and the game's craftable count. A click requests one craft, with a visible message when the call fails.
- Another player's linked profession list could populate learned recipes. Those lists are ignored.
- An empty material table could count as ready. It now falls back to a scanned recipe or remains unavailable.
- Gear recommendations allowed items two levels early, and checked armor proficiency at the item's future level. Current picks now respect your actual level and armor access.
- An imported step starting in the middle of a built-in step could be skipped by the shopping calculator. Totals now split at that boundary.
- Shopping could claim everything was ready even when plans or recipe information were missing. Status now includes those requirements.
- All Gear and gear shopping windows could grow off-screen. Both now scroll and fit the screen. Gear details and action buttons have separate space.
- The layout cleanup silently hid the fourth starting zone. All available zone choices are displayed again.
- Auto-learn treated an unreadable price as zero. It now refuses that purchase. Deferred purchase callbacks also stop when the trainer visit changes.
- Imported text is capped at 250,000 characters before parsing.
- Named trainer rows are copied before applying rank-specific sort order, avoiding shared-row mutation.

## Validation

Lua 5.1: focused regression checks plus the original full harness and existing recipe, zone, travel, Favor, shopping, and import checks. No Lua errors; simulated combat reports no blocked changes.

Re-run from the repo with `python -m pip install -r tests/requirements.txt`, then `python tests/review_checks.py`.

The mock does not prove visual rendering, workstation detection, server behavior, protected action permissions, or live Forever API compatibility. Crafting still lets the game enforce its rules; no delayed crafting is added.

## Remaining limitations

- Boats, walking speed, and higher-rank trainer penalties are estimates, not actual measured travel times. Routes do not account for every Forever portal, unlocked flight path, enemy territory, or terrain barrier.
- Most Stormwind coordinates were mathematically converted from two points. That is an estimate, not verification of every trainer's location.
- Gear scoring uses simple stat weights. It does not fully model weapon speed, two-hand/off-hand tradeoffs, set bonuses, procs, specializations, or talent builds. Treat recommendations as candidates to compare, not guaranteed upgrades.
- Some recipe materials are unavailable until the profession window is opened. Recipe caches can become stale after unlearning a profession; craft clicks revalidate with the game.
- Source comments and previous messages make precise claims about crate drop rates and Favor rewards without preserving adequate evidence for each number. Those figures need a separate source audit.

API reference inspected: Blizzard's generated TradeSkillUI API documentation, mirrored at https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TradeSkillUIDocumentation.lua . Forever may differ from the retail API.
