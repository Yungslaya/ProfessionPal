local P = ProfessionPal
local f = ProfessionPalFrame
local T = ProfessionPalTracker
local function show(label)
  print(label .. "\n   " .. VISIBLE(f):gsub("\n", " ") .. "\n   TRACKER: " .. VISIBLE(T):gsub("\n", " "))
end
STATE.equip = {}; STATE.level = 12; STATE.faction = "Alliance"; STATE.race = "Human"
STATE.map = 1429; STATE.zone = "Elwynn Forest"; STATE.pos = {0.5, 0.5}
P.db.selected = "firstaid"; P.db.tracker = true; f:Show()
-- knows Linen Bandage (starter) but NOT Heavy Linen Bandage, skill 40
STATE.spells = { [3275] = true }
STATE.profs = { { name = "First Aid", line = 129, rank = 40, max = 75 } }
FIRE("CHAT_MSG_SKILL"); show("[First Aid 40, Heavy Linen NOT learned]")
STATE.profs[1].rank = 47; FIRE("CHAT_MSG_SKILL"); show("[First Aid 47, still not learned]")
-- learns it
STATE.spells[3276] = true; FIRE("SPELLS_CHANGED"); show("[First Aid 47, learned]")
-- game won't tell us (starter not reported): gentle reminder only at start of step
STATE.spells = {}
STATE.profs[1].rank = 41; FIRE("CHAT_MSG_SKILL"); show("[First Aid 41, can't tell]")
STATE.profs[1].rank = 46; FIRE("CHAT_MSG_SKILL"); show("[First Aid 46, can't tell -> quiet]")
-- vendor recipe: Heavy Silk Bandage at 180
STATE.spells = { [3275] = true }
STATE.profs[1] = { name = "First Aid", line = 129, rank = 182, max = 225 }; STATE.level = 40
FIRE("CHAT_MSG_SKILL"); show("[First Aid 182, vendor recipe]")
-- lots of professions -> buttons wrap
STATE.spells = { [2580]=true, [2656]=true, [2383]=true, [13262]=true, [818]=true, ["Blacksmithing"]=true, ["Enchanting"]=true,
  ["Cooking"]=true, ["First Aid"]=true, ["Fishing"]=true, [3275]=true }
STATE.profs = { { name = "Mining", line = 186, rank = 100, max = 150 }, { name = "Herbalism", line = 182, rank = 100, max = 150 },
  { name = "Blacksmithing", line = 164, rank = 100, max = 150 }, { name = "Enchanting", line = 333, rank = 100, max = 150 },
  { name = "Cooking", line = 185, rank = 100, max = 150 }, { name = "First Aid", line = 129, rank = 100, max = 150 },
  { name = "Fishing", line = 356, rank = 100, max = 150 } }
FIRE("SPELLS_CHANGED")
local n, rows = 0, {}
for _, b in ipairs(T.btns) do if b:IsShown() then n = n + 1; local p = b._points[1]; rows[p[5]] = (rows[p[5]] or 0) + 1 end end
local r = {}; for yv, c in pairs(rows) do r[#r+1] = c .. " at y=" .. yv end
print("BUTTONS shown " .. n .. " (" .. table.concat(r, ", ") .. "), tracker height " .. tostring(T._h))
local names = {}; for _, b in ipairs(T.btns) do if b:IsShown() then names[#names+1] = b._attr.spell end end
print("   " .. table.concat(names, ", "))
for _, m in ipairs(LOG) do if m:find("Learn") or m:find("Buy") then print("CHAT: " .. m) end end
