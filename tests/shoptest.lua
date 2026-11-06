local P = ProfessionPal
local f = ProfessionPalFrame
C_CurrencyInfo = { GetCurrencyInfo = function() return { quantity = STATE.favor or 0 } end }
STATE.equip = {}; STATE.level = 14; STATE.class = "WARRIOR"; STATE.faction = "Alliance"
STATE.map = 1429; STATE.zone = "Elwynn Forest"; STATE.pos = {0.5, 0.5}
STATE.profs = { { name = "Blacksmithing", line = 164, rank = 50, max = 75 } }
STATE.favor = 12; STATE.bags[2840] = 20; STATE.bags[2835] = 3
P.db.selected = "blacksmithing"; f:Show(); P:Refresh()
local function dump(label) print(label .. "\n   " .. VISIBLE(P.gearShop):gsub("\n", "\n   ")) end
-- click "What I need" on the Better row (4th) and the first row
f.gear[4].list:GetScript("OnClick")(f.gear[4].list); dump("[Better row: Guard's Chain Belt]")
f.gear[1].list:GetScript("OnClick")(f.gear[1].list); dump("[First pick]")
f.gearShopBtn:GetScript("OnClick")(f.gearShopBtn); dump("[Shop for All]")
-- leatherworking piece with no data until the window is opened
STATE.profs = { { name = "Leatherworking", line = 165, rank = 120, max = 150 } }; STATE.level = 25; STATE.class = "ROGUE"
P.db.selected = "leatherworking"; P:Refresh()
local items = P:GearShopAllItems(P.byKey.leatherworking, 120)
print("LW picks: " .. #items)
if #items > 0 then P:ShowGearShop({ items[1] }); dump("[LW, materials unknown]")
  P.db.recipeMats = P.db.recipeMats or {}; P.db.recipeMats[items[1].name] = { { 2319, 8 }, { 2321, 2 }, { 99999, 1 } }
  P:RefreshGearShop(); dump("[LW, after reading the window]") end
