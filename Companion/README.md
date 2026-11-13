# Market Ledger Companion

A small Windows app for the ProfessionPal **Market Ledger**. WoW addons cannot reach the internet, so the Companion carries your scan to an AI and writes the AI's plan into the addon's **Plan** tab.

## Get it

- **Easy:** open the [Dragbags Addon Updater](https://github.com/Yungslaya/DragbagsAddonUpdater), tick **Market Ledger Companion (app)** and click **Update / Install**. It puts a shortcut on your Desktop and keeps the app up to date.
- **By hand:** [download MarketLedgerCompanion.pyw](https://github.com/Yungslaya/ProfessionPal/releases/latest/download/MarketLedgerCompanion.pyw) and save it anywhere.

You also need [Python 3](https://www.python.org/downloads/), which is free. Nothing else.

## Use it

1. In WoW, at the Auction House: open Market Ledger (`/ppauction`), click **Scan Bags**, then **AI Help**, then **Save and reload**.
2. Open the Companion. It finds your scan by itself.
3. Click **Copy for AI chat**. Paste into ChatGPT, Claude or any AI chat and send it.
4. Copy the AI's whole reply and click **Paste AI reply**.
5. Type `/reload` in WoW and open the **Plan** tab.

The gold line at the top of the Companion always says what to do next. No account or key is needed for this. If you have an API key, **Ask now** does steps 3 and 4 in one click.

## What it touches

- Reads `WTF\Account\...\SavedVariables\ProfessionPal.lua` (your saved scan).
- Writes `Interface\AddOns\ProfessionPal\LedgerPlan.lua` (the plan).
- Sends the scan (item names, counts and prices) to an AI only when you click **Ask now**. Your API key is never saved.

It never touches the running game. You still click every auction, sale and craft yourself. This is the same file hand-off the TradeSkillMaster app uses.

Each plan line is checked against your scan before it is saved: unknown items are left out, and no step sells more than you have spare.
