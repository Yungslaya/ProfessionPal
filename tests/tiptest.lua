local P = ProfessionPal
C_CurrencyInfo = { GetCurrencyInfo = function() return { quantity = 12 } end }
local lines = {}
GameTooltip = { SetOwner = function() end, SetText = function(_, t) lines[#lines+1] = t end,
  AddLine = function(_, t) lines[#lines+1] = t end, AddDoubleLine = function(_, a, b) lines[#lines+1] = a .. "  ->  " .. b end, Show = function() end }
STATE.class = "WARRIOR"; STATE.level = 14; STATE.faction = "Alliance"; STATE.equip = {}
STATE.profs = { { name = "Blacksmithing", line = 164, rank = 50, max = 75 } }
local _, _, b = P:GearPicks(P.byKey.blacksmithing, 50)
P:GearTooltip({}, b.it)
print(table.concat(lines, "\n"))
