# Release channels

Family Beta Uploader means the existing Dragbags Addon Updater, which reads GitHub releases.
A general "publish" request authorizes a Family Beta/GitHub release only.
CurseForge file uploads require a separate, specific request and the owner's explicit Approve click.
The owner authorized the current starter-setup releases for Family Beta. CurseForge uploads still require their separate Approve click.

## Public wording

Write short, plain release notes about changes players can see and any reload/restart instructions they need. Keep test counts, harness output, simulated checks, internal API details and review status out of public changelogs and project descriptions. Keep technical verification in developer notes. Preserve useful limitations such as estimated cooldowns or approximate gathering locations; never claim live testing that has not happened. Avoid stiff sales language. The owner's cleaned CurseForge descriptions and changelogs in Documents/CurseForgePublishing/public-copy-cleanup are the style reference.
## Market Ledger Companion

The Companion (`Companion/`) is a desktop app, not an addon. CurseForge hosts addons only, so it ships on GitHub, attached to the same release as the addon:

- Attach `Companion/Market Ledger Companion.pyw` as **`MarketLedgerCompanion.pyw`** (one file, not a zip). The Dragbags Addon Updater (1.1.0+) looks for that exact asset name. A second `.zip` on the release can make updater 1.0.1 pick the wrong file, so keep `ProfessionPal.zip` the only zip.
- Its `VERSION` line must equal the addon version in the `.toc`. The updater compares it with the release tag and refuses a mismatch. `tests/companion_checks.py` checks this. Bump both on every release and attach the Companion every time, even if it did not change.
- Keep `Documents\MarketLedgerCompanion\Market Ledger Companion.pyw` (the owner's installed copy) the same as the repo copy.

Never ship a personal `LedgerPlan.lua`; the release copy stays an empty stub (updater 1.1.0+ keeps the player's own plan across updates). Run `tests/ledger_checks.py` and `tests/companion_checks.py` before a release.

Every README, release note and CurseForge description that mentions AI Help must say what the player needs and where to get it: the Companion (Dragbags Addon Updater, or the GitHub release download), Python 3 (python.org), and any AI chat. Then the four steps: Scan Bags, Save and reload, Copy for AI chat / Paste AI reply, `/reload` and the Plan tab.
