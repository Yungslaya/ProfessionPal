local P = ProfessionPal
local f = ProfessionPalFrame
local function line(label)
  local d = P.byKey[P.db.selected]
  print(label .. "\n   " .. VISIBLE(f):gsub("\n", " "))
  print("   TRACKER: " .. VISIBLE(ProfessionPalTracker):gsub("\n", " "))
end
STATE.equip = {}; STATE.level = 8
-- Night Elf in Teldrassil, Mining 20
STATE.faction = "Alliance"; STATE.race = "NightElf"; STATE.map = 1438; STATE.zone = "Teldrassil"; STATE.pos = {0.55, 0.45}
STATE.profs = { { name = "Mining", line = 186, rank = 20, max = 75 } }
P.db.selected = "mining"; P.db.smeltFirst.mining = false; P.db.tracker = true
f:Show(); P:Refresh(); line("[NightElf in Teldrassil, Mining 20]")
-- trainers when not learned yet
STATE.profs = {}; P:Refresh(); line("[NightElf in Teldrassil, Mining not learned]")
-- Human in Elwynn, Herbalism 10
STATE.race = "Human"; STATE.map = 1429; STATE.zone = "Elwynn Forest"; STATE.pos = {0.5, 0.6}
STATE.profs = { { name = "Herbalism", line = 182, rank = 10, max = 75 } }
P.db.selected = "herbalism"; P:Refresh(); line("[Human in Elwynn, Herbalism 10]")
-- Dwarf standing in Ironforge (zone not in list), Fishing 10 -> closest = Dun Morogh
STATE.race = "Dwarf"; STATE.map = 1455; STATE.zone = "Ironforge"; STATE.pos = {0.5, 0.5}
STATE.profs = { { name = "Fishing", line = 356, rank = 10, max = 75 } }
P.db.selected = "fishing"; P:Refresh(); line("[Dwarf in Ironforge, Fishing 10]")
-- position unreadable -> race home zone first
STATE.pos = nil; STATE.map = nil; STATE.zone = nil; STATE.race = "NightElf"
STATE.profs = { { name = "Mining", line = 186, rank = 20, max = 75 } }
P.db.selected = "mining"; P:Refresh(); line("[NightElf, position unknown]")
-- Horde Orc in Durotar at trainer rank 2 time (Mining 55)
STATE.faction = "Horde"; STATE.race = "Orc"; STATE.map = 1411; STATE.zone = "Durotar"; STATE.pos = {0.5, 0.5}; STATE.level = 12
STATE.profs = { { name = "Mining", line = 186, rank = 55, max = 75 } }
P:Refresh(); line("[Orc in Durotar, Mining 55]")
