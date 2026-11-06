local P = ProfessionPal
local f = ProfessionPalFrame
C_CurrencyInfo = { GetCurrencyInfo = function(id) return { quantity = STATE.favor or 0 } end }
local function show(label)
  P:Refresh()
  print(label)
  print("   MAIN: " .. VISIBLE(f):gsub("\n", " | "):match("GEAR.-TRAINER") )
  print("   TRACKER: " .. (VISIBLE(ProfessionPalTracker):match("Gear:[^\n]*") or "-"))
  if not P.gearWin or not P.gearWin:IsShown() then P:ToggleGear() end
  P:RefreshGear()
  print("   GEAR WIN: " .. VISIBLE(P.gearWin):gsub("\n", " | "))
end
STATE.equip = {}; STATE.level = 14; STATE.class = "WARRIOR"; STATE.faction = "Alliance"
STATE.map = 1429; STATE.zone = "Elwynn Forest"; STATE.pos = {0.5, 0.5}
STATE.profs = { { name = "Blacksmithing", line = 164, rank = 50, max = 75 } }
P.db.selected = "blacksmithing"; P.db.tracker = true; f:Show()
STATE.favor = 0
show("[1] Warrior 14, BS 50, 0 Favor, no Pristine Leather")
STATE.favor = 40; STATE.bags[249427] = 2
show("[2] 40 Favor + 2 Pristine Leather")
C_TradeSkillUI.GetAllRecipeIDs = function() return { 1 } end
C_TradeSkillUI.GetRecipeInfo = function() return { learned = true, name = "Guard's Chain Belt" } end
FIRE("TRADE_SKILL_SHOW")
show("[3] Guard's Chain Belt learned")
STATE.bags[249427] = 0
show("[4] learned but out of Pristine Leather")
P.db.gearHideHard = true
show("[5] setting: hide pieces that need plans/rare mats")
STATE.faction = "Horde"; P.db.gearHideHard = false; P.db.known = {}
show("[6] Horde, plans not known")

