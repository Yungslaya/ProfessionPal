import sys
from pathlib import Path
from lupa import lua51

# Usage: ledger_checks.py [addon folder] [harness.lua]  (defaults: this repo)
here = Path(__file__).resolve().parent
addon = Path(sys.argv[1]) if len(sys.argv) > 1 else here.parent / 'ProfessionPal'
harness = Path(sys.argv[2]) if len(sys.argv) > 2 else here / 'harness.lua'
l = lua51.LuaRuntime(unpack_returned_tuples=True)
l.execute(harness.read_text(encoding='utf-8-sig'))
l.execute('''
ITEMS = {
  -- id = {name, vendor, count, bound, listed}
  [1]    = {"Single Trade Good", 10, 1, false, 270},
  [2]    = {"Recipe: Cheap", 400, 1, false, 8},
  [3]    = {"Silk Cloth", 150, 5, false, 199},
  [2901] = {"Mining Pick", 2, 1, false, 100},
  [5956] = {"Blacksmith Hammer", 3, 1, false, 100},
  [6948] = {"Hearthstone", 0, 1, true, nil},
  [7]    = {"Bound Junk", 25, 1, true, nil},
  [8]    = {"Unpriced Single", 5, 1, false, nil},
}
SLOTS = {}
for id in pairs(ITEMS) do SLOTS[#SLOTS + 1] = id end
table.sort(SLOTS)
NUM_BAG_SLOTS = 0
C_Container = C_Container or {}
C_Container.GetContainerNumSlots = function(bag) return bag == 0 and #SLOTS or 0 end
C_Container.GetContainerItemInfo = function(bag, slot)
  local id = SLOTS[slot]; local it = id and ITEMS[id]
  if not it then return nil end
  return { hyperlink = "|Hitem:" .. id .. "::|h[" .. it[1] .. "]|h", itemID = id, stackCount = it[3],
           isBound = it[4], isLocked = false, hasNoValue = it[2] == 0 }
end
C_Container.GetContainerItemQuestInfo = function() return { isQuestItem = false, isActive = false } end
ItemLocation = { CreateFromBagAndSlot = function(_, b, s) return { b = b, s = s } end }
C_AuctionHouse = {
  GetItemKeyFromItemLink = function(link) return { itemID = tonumber(link:match("item:(%d+)")) } end,
  MakeItemKey = function(id) return { itemID = id } end,
}
''')
ns = l.eval('{}')
for n in (addon / 'ProfessionPal.toc').read_text().splitlines():
    if n and not n.startswith('#'):
        chunk = l.eval('loadstring')((addon / n).read_text(encoding='utf-8-sig'), n)
        if isinstance(chunk, tuple):
            raise AssertionError(chunk)
        chunk('ProfessionPal', ns)
l.globals().NS = ns
l.execute('''
local P = NS
FIRE("PLAYER_LOGIN")
UnitName = function() return "Alpha" end
GetRealmName = function() return "TestRealm" end
C_Item = C_Item or {}
C_Item.CanBeAuctioned = function() return true end
C_Item.GetItemInfo = function(link)
  local id = type(link) == "number" and link or tonumber(link:match("item:(%d+)"))
  local it = ITEMS[id]; if not it then return nil end
  return it[1], nil, nil, nil, nil, nil, nil, nil, nil, nil, it[2]
end
GetItemInfo = C_Item.GetItemInfo
local prices = {}
for id, it in pairs(ITEMS) do if it[5] then prices[id .. ":0:0:0"] = it[5] end end
P.db.ledgerPrices = { ["TestRealm:" .. UnitFactionGroup("player")] = prices }
-- an old saved plan (made before the fix) must be thrown away
P.db.auctionTestPercent = 50
P.db.ledgerStockPlans = { ["Alpha-TestRealm"] = { percent = 50, keep = { ["|Hitem:1::|h[Single Trade Good]|h"] = 1 } } }
CLICKS1 = {}; local clicks = CLICKS1
local make = P.UIButton
P.UIButton = function(parent, text, w, h, fn) clicks[text] = fn; return make(parent, text, w, h, fn) end
local window = P.UIWindow
P.UIWindow = function(...) local w = window(...); w.GetWidth = function() return 720 end; return w end
-- no scan yet: nothing is exported at logout, and the guide starts at step 1
FIRE("PLAYER_LOGOUT")
assert(P.db.ledgerAdviceExport == nil, "no export before the first scan")
P:ToggleMarketLedger()
assert(clicks["AI Help"], "help button"); clicks["AI Help"]()
function GUIDETEXT() return VISIBLE(ProfessionPalLedgerAdvice) end
assert(GUIDETEXT():find("Next: go to the Auction House and click Scan Bags.", 1, true), GUIDETEXT())
assert(clicks["Scan Bags"], "guide button exists")
-- a scan finished earlier and was saved: logout writes the report
local T = os.time() - 600; P.db.ledgerScanAt = T
FIRE("PLAYER_LOGOUT")
assert(P.db.ledgerExportScan == T, "export remembers its scan")
FIRE("BAG_UPDATE_DELAYED")
assert(GUIDETEXT():find("Next: open Market Ledger Companion on your PC.", 1, true), GUIDETEXT())
assert(GUIDETEXT():find("Done, ", 1, true) and GUIDETEXT():find("Do this now", 1, true), GUIDETEXT())
-- an old export (scan 30) with a newer scan (40) means: save first
P.db.ledgerExportScan = T - 100; FIRE("BAG_UPDATE_DELAYED")
assert(GUIDETEXT():find("Next: click Save and reload.", 1, true), GUIDETEXT())
RELOADS = 0; ReloadUI = function() RELOADS = RELOADS + 1 end
for _, f in ipairs(FRAMES) do
  if f._text == "Save and reload" and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "LeftButton") end
end
assert(RELOADS == 1 and P.db.ledgerExportScan == T, "save button exports and reloads")
-- a plan made from this scan: follow it
P.ledgerPlan = { at = 1, scan = T, steps = { { action = "Keep", name = "Mining Pick" } } }
FIRE("BAG_UPDATE_DELAYED")
assert(GUIDETEXT():find("Next: work down the Plan tab.", 1, true), GUIDETEXT())
P.ledgerPlan = nil
-- old prices: say so before the AI sees them
P.db.ledgerScanAt = T - 3 * 3600; P.db.ledgerExportScan = T - 3 * 3600; FIRE("BAG_UPDATE_DELAYED")
assert(GUIDETEXT():find("Your prices are 3 hours old", 1, true), GUIDETEXT())
P.db.ledgerScanAt = 40; P.db.ledgerExportScan = 40
ProfessionPalLedgerAdvice:Hide()
local hex = P.db.ledgerAdviceExport:match("^PPLEDGER1:(%x+)$")
REPORT = hex:gsub("%x%x", function(b) return string.char(tonumber(b, 16)) end)
''')
report = l.globals().REPORT
print(report)
rows = {}
for line in report.splitlines():
    parts = [p.strip() for p in line.split('|')]
    if len(parts) == 9 and parts[0] != 'Items: name':
        rows[parts[0]] = parts

def check(name, action, qty):
    r = rows[name]
    assert (r[4], r[5]) == (action, str(qty)), (name, r)

check('Single Trade Good', 'Auction', 1)      # lone item is now offered
check('Recipe: Cheap', 'Vendor', 1)           # vendor beats auction
check('Silk Cloth', 'Auction', 2)             # stacks unchanged: half, rounded down
check('Mining Pick', 'Keep', 0)               # tools are kept
check('Blacksmith Hammer', 'Keep', 0)
check('Bound Junk', 'Vendor', 1)              # bound item with vendor value still listed
check('Unpriced Single', 'Check price', 1)
assert 'Hearthstone' not in rows, 'Hearthstone should be left out'
assert report.rstrip().endswith('Craft opportunities with known prices:\nnone'), 'empty craft section says none'
print('\nALL LEDGER CHECKS PASSED')

# ---- Plan tab ----
l.execute('''
local P = NS
C_Item.GetItemCount = function(id) return ITEMS[id] and ITEMS[id][3] or 0 end
CLICKS = {}
local make = P.UIButton
P.UIButton = function(parent, text, w, h, fn)
  local b = make(parent, text, w, h, fn); CLICKS[#CLICKS + 1] = { text = text, fn = fn, b = b }; return b
end
P.ledgerPlan = { at = 100, scan = 50, steps = {
  { action = "Auction", name = "Silk Cloth", qty = 2, price = 199, note = "sell slow" },
  { action = "Vendor", name = "Recipe: Cheap", qty = 1 },
  { action = "Vendor", name = "Not Here", qty = 1 },
  { action = "Hold", name = "Mining Pick", note = "tool" },
}}
function TEXTS()
  local out = {}
  for _, f in ipairs(FRAMES) do
    if f._kind == "FontString" and f._text and f:IsVisible() then out[#out + 1] = f._text end
  end
  return table.concat(out, "\\n")
end
function TAB(name) for _, c in ipairs(CLICKS) do if c.text == name then c.fn(c.b, "LeftButton") end end end
function SOLD(id, n)
  ITEMS[id][3] = ITEMS[id][3] - n
  if ITEMS[id][3] <= 0 then
    for i, v in ipairs(SLOTS) do if v == id then table.remove(SLOTS, i) break end end
  end
  FIRE("BAG_UPDATE_DELAYED")
end
P:ToggleMarketLedger()  -- close
P:ToggleMarketLedger()  -- open again
-- the shipped plan file is empty, so the window opens on Auction: click the Plan tab
for _, f in ipairs(FRAMES) do
  if f._text == "Plan" and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "LeftButton") end
end
''')
g = l.globals()
texts = lambda: g.TEXTS()
l.execute('FIRE("BAG_UPDATE_DELAYED")')
t = texts(); print(t, '\n---')
assert 'Plan: 0 of 3 done' in t, 'header'
assert 'Silk Cloth ×2' in t and 'sell slow' in t and 'Recipe: Cheap ×1' in t and 'Not in bags' in t
assert 'Mining Pick - tool' in t and 'Hold' in t
g.SOLD(3, 1)
t = texts()
assert 'Plan: 0 of 3 done' in t and 'Silk Cloth ×1' in t, 'half sold shows what is left'
g.SOLD(3, 1)
assert 'Plan: 1 of 3 done' in texts(), 'auction step ticks off'
g.SOLD(2, 1)
t = texts(); print(t, '\n---')
assert 'Plan: 2 of 3 done' in t, 'vendor step ticks off'
# rescan after the plan was written -> warning line
l.execute('NS.db.ledgerScanAt = 60'); l.execute('FIRE("BAG_UPDATE_DELAYED")')
assert 'Prices were rescanned' in texts()
# a new plan resets progress
l.execute('NS.ledgerPlan = { at = 200, scan = 60, steps = { { action = "Vendor", name = "Bound Junk", qty = 1 } } }'); l.execute('FIRE("BAG_UPDATE_DELAYED")')
t = texts()
assert 'Plan: 0 of 1 done' in t and 'Prices were rescanned' not in t
g.SOLD(7, 1)
assert 'Plan complete' in texts()
l.execute('NS.ledgerPlan = nil'); l.execute('FIRE("BAG_UPDATE_DELAYED")')
assert 'No plan yet' in texts()
# items crafted after the plan was made still tick off (2 held, craft 3 more, sell 3)
l.execute('''
ITEMS[1][3] = 2
NS.ledgerPlan = { at = 300, scan = 60, steps = {
  { action = "Craft", name = "Single Trade Good", note = "make 3" },
  { action = "Auction", name = "Single Trade Good", qty = 3, price = 270 } } }
FIRE("BAG_UPDATE_DELAYED")
ITEMS[1][3] = 5; FIRE("BAG_UPDATE_DELAYED")
''')
t = texts()
assert 'Plan: 0 of 1 done' in t and 'Single Trade Good ×3' in t and 'Single Trade Good - make 3' in t
l.execute('ITEMS[1][3] = 2; FIRE("BAG_UPDATE_DELAYED")')
assert 'Plan complete' in texts(), 'crafted then sold ticks off'
# tools are kept even at 100%
l.execute('''
for _, f in ipairs(FRAMES) do if f._text == "50" then f:SetText("100") end end
FIRE("BAG_UPDATE_DELAYED"); FIRE("PLAYER_LOGOUT")
local hex = NS.db.ledgerAdviceExport:match("^PPLEDGER1:(%x+)$")
local r = hex:gsub("%x%x", function(b) return string.char(tonumber(b, 16)) end)
assert(r:find("Stock limit: 100%%"), "limit is 100")
assert(r:find("Mining Pick | 1 | 0 | 0 | Keep | 0 |", 1, true), "pick kept at 100%")
assert(r:find("Blacksmith Hammer | 1 | 0 | 0 | Keep | 0 |", 1, true), "hammer kept at 100%")
''')
print('ALL PLAN CHECKS PASSED')

# the real plan file must load cleanly
real = l.eval('loadstring')((addon / 'LedgerPlan.lua').read_text(encoding='utf-8'), 'LedgerPlan.lua')
assert not isinstance(real, tuple), real
real('ProfessionPal', ns)
print('PLAN FILE LOADS')

# ---- Craft button with amount ----
l.execute('''
local P = NS
ITEMS[1][3] = 2; ITEMS[3] = {"Silk Cloth", 150, 10, false, 199}
P.db.recipeIDs = { ["Alpha-TestRealm"] = { ["Single Trade Good"] = 501 } }
P.db.recipeMats = { ["Single Trade Good"] = { {3, 2} } }
P.db.known = { ["Alpha-TestRealm"] = { ["Single Trade Good"] = true } }
C_TradeSkillUI.GetRecipeItemLink = function(id) return id == 501 and "|Hitem:1::|h[Single Trade Good]|h" or nil end
C_TradeSkillUI.GetRecipeSchematic = function() return { quantityMin = 1, reagentSlotSchematics = {} } end
C_TradeSkillUI.GetRecipeInfo = function() return { name = "Single Trade Good", learned = true } end
C_TradeSkillUI.GetCraftableCount = function() return 5 end
C_TradeSkillUI.GetBaseProfessionInfo = function() return nil end
CRAFTED = {}
C_TradeSkillUI.CraftRecipe = function(id, n) CRAFTED[#CRAFTED + 1] = id .. "x" .. n end
ProfessionsFrame = CreateFrame("Frame"); ProfessionsFrame:Show()
InCombatLockdown = function() return false end
P.ledgerPlan = { at = 400, scan = 60, steps = {
  { action = "Craft", name = "Single Trade Good", qty = 4, note = "uses silk" },
  { action = "Craft", name = "Mystery Thing", qty = 2 },
  { action = "Craft", name = "Reminder Only", note = "no amount" } } }
FIRE("BAG_UPDATE_DELAYED")
function PRESS(label)
  for _, f in ipairs(FRAMES) do
    if f._text == label and f._scripts.OnClick and f:IsVisible() then f._scripts.OnClick(f, "LeftButton") return true end
  end
end
''')
t = texts()
assert 'Plan: 0 of 2 done' in t and 'Single Trade Good ×4' in t, t
assert 'Recipe unknown' in t and 'Reminder Only - no amount' in t
assert g.PRESS('Craft ×4'), 'craft button found'
assert list(g.CRAFTED.values()) == ['501x4'], list(g.CRAFTED.values())
l.execute('ITEMS[1][3] = 4; FIRE("BAG_UPDATE_DELAYED")')
assert 'Single Trade Good ×2' in texts(), 'two made, two left'
l.execute('C_TradeSkillUI.GetCraftableCount = function() return 1 end')
g.PRESS('Craft ×2')
assert list(g.CRAFTED.values())[-1] == '501x1', 'never asks for more than the game says you can make'
l.execute('ITEMS[1][3] = 6; FIRE("BAG_UPDATE_DELAYED")')
assert 'Plan: 1 of 2 done' in texts(), 'craft step ticks off'
print('ALL CRAFT CHECKS PASSED')

# ---- Craft step follows its sell step; no materials hides the button ----
l.execute('''
ITEMS[1][3] = 3; ITEMS[3][3] = 10
NS.ledgerPlan = { at = 500, scan = 60, steps = {
  { action = "Craft", name = "Single Trade Good", qty = 4 },
  { action = "Auction", name = "Single Trade Good", qty = 3, price = 270 } } }
FIRE("BAG_UPDATE_DELAYED")
ITEMS[3][3] = 1; FIRE("BAG_UPDATE_DELAYED")
''')
t = texts()
assert 'Plan: 0 of 2 done' in t and 'No materials' in t, t
assert not g.PRESS('Craft ×4'), 'no craft button without materials'
l.execute('ITEMS[1][3] = 0; FIRE("BAG_UPDATE_DELAYED"); FIRE("BAG_UPDATE_DELAYED")')
assert 'Plan complete' in texts(), texts()
print('ALL CRAFT FOLLOW-UP CHECKS PASSED')
