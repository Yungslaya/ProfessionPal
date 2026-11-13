"""Checks for the Market Ledger Companion. Usage: companion_checks.py [companion.pyw] [work folder]"""
import importlib.machinery
import importlib.util
import shutil
import sys
import time
from pathlib import Path

from lupa import lua51

import tempfile
here = Path(__file__).resolve().parent
source = sys.argv[1] if len(sys.argv) > 1 else str(here.parent / 'Companion' / 'Market Ledger Companion.pyw')
loader = importlib.machinery.SourceFileLoader("companion", source)
spec = importlib.util.spec_from_loader("companion", loader)
c = importlib.util.module_from_spec(spec)
loader.exec_module(c)

# the Companion ships with the addon release, so both carry the same version (the updater compares them)
import re
toc = (here.parent / "ProfessionPal" / "ProfessionPal.toc").read_text(encoding="utf-8")
assert c.VERSION == re.search(r"## Version: (\S+)", toc).group(1), c.VERSION
assert re.search(r'^VERSION = "[\d.]+"$', Path(source).read_text(encoding="utf-8"), re.M)

work = Path(sys.argv[2] if len(sys.argv) > 2 else tempfile.mkdtemp()) / "fakewow"
shutil.rmtree(work, ignore_errors=True)
saved = work / "_forever_" / "WTF" / "Account" / "TESTER" / "SavedVariables" / "ProfessionPal.lua"
addon = work / "_forever_" / "Interface" / "AddOns" / "ProfessionPal"
saved.parent.mkdir(parents=True)
addon.mkdir(parents=True)

SCAN = int(time.time()) - 600
REPORT = f"""Market Ledger report v1
All prices are copper per unit. Listings are asking prices.
Stock limit: 100%
Last completed scan (Unix time): {SCAN}
Items: name | bag quantity | available after reserves | already allocated to craft | recommended action | recommended quantity | vendor each | auction ask each | estimated auction net each
Silver Ore | 6 | 6 | 0 | Auction | 6 | 75 | 805 | 764
Coarse Stone | 14 | 14 | 14 | Craft | 0 | 15 | 72 | 68
Mining Pick | 1 | 0 | 0 | Keep | 0 | 2 | 100 | 95
Linen Cloth | 3 | 0 | 0 | Keep | 0 | 13 | 27 | 25
Tel'Abim Banana | 4 | 4 | 0 | Auction | 4 | 6 | 19 | 18
Arctic Buckler | 1 | 1 | 0 | Vendor | 1 | 3136 | unknown | unknown
Craft opportunities with known prices:
Coarse Grinding Stone | craftable 7 | output ask 189 | extra net per craft 43 | Coarse Stone x2
Sharpening Wheel | craftable 0 | output ask 266 | extra net per craft 169 | Copper Bar x1, Rough Stone x1"""
saved.write_text('ProfessionPalDB = {\n["ledgerAdviceExport"] = "PPLEDGER1:' + REPORT.encode().hex() + '",\n}\n',
                 encoding="utf-8")

# finding and reading
assert c.saved_files([work]) == [saved]
assert c.plan_path(saved) == (addon / "LedgerPlan.lua").resolve()
assert c.load_report(saved) == REPORT
info = c.parse_report(REPORT)
assert info["scan"] == SCAN and len(info["items"]) == 6, info
assert info["items"]["silver ore"] == {"name": "Silver Ore", "bags": 6, "available": 6, "vendor": 75, "ask": 805}
assert info["items"]["arctic buckler"]["ask"] is None
assert info["crafts"]["coarse grinding stone"]["craftable"] == 7
assert c.age_text(SCAN) == "10 min old" and c.age_text(None) == ""
assert c.age_text(SCAN - 3 * 3600 + 600) == "3 hours old"
print("PASS: find, read and parse the scan")

# money
assert c.copper("805") == 805 and c.copper("8s 05c") == 805 and c.copper("1g 20s 5c") == 12005
assert c.copper("1,250 copper") == 1250 and c.copper("soon") is None

# an AI reply with the usual mess: markdown, bullets, wrong case, too many, unknown and reserved items
REPLY = """Here is my advice. Sell the silver first.

| not a plan | line |

**PLAN**
- Craft | coarse grinding stone | 9
- Auction | Silver Ore | 10 | 8s 05c
* Auction | Coarse Grinding Stone | 7 | 189
1. Auction | Tel'Abim Banana | 4
Vendor | Arctic Buckler | 1
Vendor | Linen Cloth | 3
Auction | Thunderfury | 1 | 999999
Craft | Sharpening Wheel | 3
Keep | Mining Pick | your "tool" \\ always
Check | Mystery Box | open it first
Some closing words that are not a step."""
steps, skipped = c.parse_plan(REPLY, REPORT)
assert steps == [
    {"action": "Craft", "name": "Coarse Grinding Stone", "qty": 7},
    {"action": "Auction", "name": "Silver Ore", "qty": 6, "price": 805},
    {"action": "Auction", "name": "Coarse Grinding Stone", "qty": 7, "price": 189},
    {"action": "Auction", "name": "Tel'Abim Banana", "qty": 4, "price": 19},
    {"action": "Vendor", "name": "Arctic Buckler", "qty": 1},
    {"action": "Craft", "name": "Sharpening Wheel", "qty": 3},
    {"action": "Keep", "name": "Mining Pick", "note": "your tool always"},
    {"action": "Check", "name": "Mystery Box", "note": "open it first"},
], steps
assert skipped == ["Linen Cloth: kept for your professions", "Thunderfury: not in your scan"], skipped
assert c.parse_plan("Sorry, I cannot help with that.", REPORT) == ([], [])
# without the PLAN word, plan-shaped lines still count
assert c.parse_plan("Vendor | Arctic Buckler | 1", REPORT)[0] == [{"action": "Vendor", "name": "Arctic Buckler", "qty": 1}]
print("PASS: AI reply -> checked plan steps")

# the plan file must be real Lua that the addon can read
c.write_plan(addon / "LedgerPlan.lua", steps, SCAN)
assert c.saved_plan_scan(addon / "LedgerPlan.lua") == SCAN
lua = lua51.LuaRuntime(unpack_returned_tuples=True)
chunk = lua.eval("loadstring")((addon / "LedgerPlan.lua").read_text(encoding="utf-8"), "LedgerPlan.lua")
assert not isinstance(chunk, tuple), chunk
ns = lua.eval("{}")
chunk("ProfessionPal", ns)
plan = ns.ledgerPlan
assert plan.scan == SCAN and len(plan.steps) == len(steps)
assert plan.steps[2].name == "Silver Ore" and plan.steps[2].qty == 6 and plan.steps[2].price == 805
assert plan.steps[7].note == "your tool always"
evil = c.plan_lua([{"action": "Keep", "name": 'x"] = os.exit() --\n\\', "note": "a\\b"}], 1, 2)
chunk = lua.eval("loadstring")(evil, "evil")
assert not isinstance(chunk, tuple), chunk
chunk("ProfessionPal", ns)
assert ns.ledgerPlan.steps[1].name == 'x"] = os.exit() -- \\', ns.ledgerPlan.steps[1].name
try:
    c.write_plan(work / "nowhere" / "LedgerPlan.lua", steps, SCAN)
    raise AssertionError("missing addon folder must fail")
except OSError:
    pass
print("PASS: plan file is valid Lua, hostile text stays text")

# the window: build it against the fake install and walk the four steps
c.SETTINGS = work / "settings.json"
c.REVIEW_FOLDER = work / "Claude Review"
c.wow_roots = lambda: [work]
(addon / "LedgerPlan.lua").unlink()
import tkinter as tk
root = tk.Tk()
root.withdraw()
app = c.Companion(root)
root.update()
assert app.step() == 2 and "Copy for AI chat" in app.status.get(), app.status.get()
assert (work / "Claude Review" / "Market Ledger.txt").read_text(encoding="utf-8") == REPORT
assert "6 items" in app.states[0].cget("text"), app.states[0].cget("text")
app.copy_for_chat()
assert app.step() == 3 and root.clipboard_get() == c.chat_prompt(REPORT)
app.paste_reply()   # clipboard still holds our own prompt
assert not app.plan_saved and "Copy the AI's reply first" in app.status.get(), app.status.get()
root.clipboard_clear(); root.clipboard_append(REPLY)
app.paste_reply()
assert app.step() == 4 and "Plan saved with 8 steps" in app.status.get() and "Left out 2" in app.status.get(), app.status.get()
assert c.saved_plan_scan(addon / "LedgerPlan.lua") == SCAN
# a plan written by someone else (Claude Code) is noticed
app.plan_saved = False
app.watch(); root.update()
assert app.plan_saved and app.step() == 4
# a new scan in the save file is picked up and restarts the steps
NEW = REPORT.replace(str(SCAN), str(SCAN + 60))
saved.write_text('["ledgerAdviceExport"] = "PPLEDGER1:' + NEW.encode().hex() + '",', encoding="utf-8")
import os
os.utime(saved, (time.time() + 5, time.time() + 5))
app.watch(); root.update()
assert app.report == NEW and app.step() == 2, (app.step(), app.status.get())
assert c.load_settings()["saved_file"] == str(saved)
root.destroy()
# no WoW at all
c.wow_roots = lambda: []
c.SETTINGS = work / "none.json"
root = tk.Tk(); root.withdraw()
app = c.Companion(root); root.update()
assert app.step() == 1 and "WoW was not found" in app.status.get(), app.status.get()
root.destroy()
print("PASS: window walks the four steps")
print("ALL COMPANION CHECKS PASSED")
