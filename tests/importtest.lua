local P = ProfessionPal
local f = ProfessionPalFrame
local T = ProfessionPalTracker
local function readfile(n) return GUIDES[n] end
local function summary(label, g, why)
  if not g then print(label .. ": FAILED - " .. tostring(why)) return end
  local parts = {}
  for i, s in ipairs(g.steps) do
    local m = {}
    for _, x in ipairs(s.mats or {}) do m[#m+1] = x[2] .. " " .. x[3] .. (type(x[1]) == "number" and "#" or "") end
    local z = {}
    for _, x in ipairs((s.zoneList or {}).Alliance or {}) do z[#z+1] = x[1] end
    parts[#parts+1] = string.format("%d-%d %s%s%s%s%s", s.from, s.to, s.text, s.crafts and (" x" .. s.crafts) or "",
      #m > 0 and (" [" .. table.concat(m, ", ") .. "]") or "", #z > 0 and (" {" .. table.concat(z, ", ") .. "}") or "",
      s.tip and (" tip=" .. s.tip:sub(1, 50)) or "")
  end
  print(label .. ": prof=" .. tostring(g.prof) .. " kind=" .. g.kind .. " title=" .. g.title .. " steps=" .. #g.steps)
  for _, p in ipairs(parts) do print("    " .. p) end
end
for _, n in ipairs({ "iv_blacksmithing", "wh_tailoring", "own_firstaid", "iv_mining" }) do
  summary(n, P.ParseGuide(readfile(n)))
end
summary("empty paste", P.ParseGuide(""))
summary("junk paste", P.ParseGuide("hello this is not a guide 123"))

-- ===== in the window =====
STATE.equip = {}; STATE.level = 30; STATE.faction = "Horde"; STATE.race = "Orc"; STATE.map = 1411; STATE.zone = "Durotar"; STATE.pos = {0.5, 0.5}
STATE.spells = { [2660] = true }
STATE.profs = { { name = "Blacksmithing", line = 164, rank = 70, max = 75 } }
P.db.selected = "blacksmithing"; P.db.tracker = true; f:Show(); P:Refresh()
P:ToggleGuides()
local g = ProfessionPalGuides
g.edit:SetText(readfile("iv_blacksmithing"))
P:ReadPasted()
print("GUIDES WINDOW after Read:\n   " .. VISIBLE(g):gsub("\n", " / "))
P:SaveParsed()
print("GUIDES WINDOW after Use:\n   " .. VISIBLE(g):gsub("\n", " / "))
print("MAIN at 70:\n   " .. VISIBLE(f):gsub("\n", " / "))
print("TRACKER at 70:\n   " .. VISIBLE(T):gsub("\n", " / "))
STATE.profs[1] = { name = "Blacksmithing", line = 164, rank = 240, max = 300 }; FIRE("CHAT_MSG_SKILL")
print("MAIN at 240 (imported guide stops at 225):\n   " .. VISIBLE(f):gsub("\n", " / "))
-- share -> paste back in -> same steps
P:ShareGuide()
local shared = g.edit:GetText()
print("SHARE TEXT (first 3 lines):\n   " .. table.concat({ shared:match("^([^\n]*)\n([^\n]*)\n([^\n]*)") }, "\n   "))
local back = P.ParseGuide(shared)
print("SHARE ROUNDTRIP: " .. #back.steps .. " steps, prof=" .. tostring(back.prof) .. ", title=" .. back.title)
-- switch back to ProfessionPal guide
P:SetGuide(false)
STATE.profs[1].rank = 70; FIRE("CHAT_MSG_SKILL")
print("MAIN back on ProfessionPal guide at 70:\n   " .. VISIBLE(f):gsub("\n", " / "):sub(1, 220))
-- gathering import
STATE.profs = { { name = "Mining", line = 186, rank = 80, max = 150 } }
P.db.selected = "mining"; g.edit:SetText(readfile("iv_mining")); P:ReadPasted(); P:SaveParsed()
print("MAIN mining 80 imported:\n   " .. VISIBLE(f):gsub("\n", " / "))
P:DeleteGuide()
print("after delete: using imported? " .. tostring(P:ImportedGuide(P.byKey.mining) ~= nil))
