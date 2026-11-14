# ProfessionPal changes

## 1.3.1 — gathering markers and setup help

- Gathering markers reuse their existing frames and avoid unnecessary redraw work.
- Minimap tracking can fall back to readable tooltip text when the main tooltip data is incomplete.
- Expanded setup instructions for Market Ledger, TSM prices, AI plans and Shortest Path Forever routes.

Type `/reload` after updating. If you are adding a new addon, fully restart WoW once.

### Use the tools together

1. Open `/prof` and choose your profession guide.
2. Install the separate [Market Ledger](https://github.com/Yungslaya/MarketLedger) addon for selling and planning. At the Auction House, click **Scan Bags**. ProfessionPal's needed materials are reserved.
3. Optional: configure the [TradeSkillMaster](https://www.tradeskillmaster.com/) desktop app for your realm and enable its compatible addons. Market Ledger reads available pricing context automatically. Stop competing auction scans or switch to TSM's **WoW UI** if scanning is busy.
4. For advice, choose **AI Help → Copy for AI** in Market Ledger. Paste into a chat, then import the returned PLAN with **Paste reply → Save plan**. No API key is required for copy and paste.
5. Click **Map** in your profession guide, Market Ledger's **Farm** tab or a Farm plan step. With [Shortest Path Forever](https://github.com/cjber/shortest-path-forever), it requests a travel route. Without it, use the normal map pin.
6. **Next** skips a gathering spot. **Clear** or **Stop route** ends the guide.

Asking prices do not guarantee sales. Gathering spots are possible spawns, not live node detections. Each sale or craft needs your click, and you follow the route yourself.

Thanks to the **TradeSkillMaster team**, **cjber and Shortest Path Forever contributors**, and **Wowhead's database contributors**. Their pricing APIs, routing and gathering-location data support these optional features. [Full setup and credits](README.md#use-the-addons-together).

## 1.3.0 — maps and the separate Market Ledger

Map buttons open zones with ore/herb spots, a gathering loop and a pin that advances as you reach spots. Added Riverglades and Zephras Isle data and markers in unvisited zones. Optional Shortest Path Forever integration draws travel routes. Market Ledger moved to its own addon while the button in ProfessionPal still opens it.
