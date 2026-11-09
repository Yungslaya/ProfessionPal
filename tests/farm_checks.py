from pathlib import Path
from lupa import lua51
root=Path(__file__).resolve().parents[1]
lua=lua51.LuaRuntime(unpack_returned_tuples=True)
lua.execute((root/'tests/harness.lua').read_text(encoding='utf-8-sig'))
ns=lua.table()
for name in (root/'ProfessionPal/ProfessionPal.toc').read_text().splitlines():
 if name.endswith('.lua'):
  lua.eval('function(s,n) return assert(loadstring(s,n)) end')((root/'ProfessionPal'/name).read_text(encoding='utf-8-sig'),name)('ProfessionPal',ns)
lua.execute(r"""
FIRE('PLAYER_LOGIN')
local P=ProfessionPal
assert(P.db.farmAutoFly==false,'auto-fly enabled by default')
STATE.faction='Alliance'; STATE.level=26; STATE.map=1429
P.Distance=function(_,map,x,y) return map==STATE.map and 100 or 10000 end
local options=P:FarmOptions(769)
assert(options[1].m==1429,'nearby Alliance boar recommendation')
for _,a in ipairs(options) do assert(a.faction~='Horde','enemy starting area recommendation') end
P:OpenFarm(769);assert(P.farmWindow:IsShown(),'farm window failed')
P.Pin=function(self,t) self.testPin=t end
P:SelectFarm(769,1); assert(P.farmTrip.m==1429 and P.testPin,'farm destination pin')
local trips=0
TakeTaxiNode=function(slot) assert(slot==4);trips=trips+1 end
TaxiNodeCost=function() return 20 end
GetMoney=function() return 100 end
C_Map.GetMapInfo=function(map) return {parentMapID=map==1429 and 1415 or 0} end
C_Map.GetMapWorldSize=function() return 1000,800 end
local function point(x,y) return {GetXY=function() return x,y end} end
C_TaxiMap={GetTaxiNodesForMap=function() return {
 {nodeID=10,position=point(.34,.84),faction=2,isUndiscovered=false},
 {nodeID=20,position=point(.36,.84),faction=2,isUndiscovered=true},
 {nodeID=30,position=point(.35,.84),faction=1,isUndiscovered=false}} end,
 GetAllTaxiNodes=function() return {{nodeID=10,name='Destination',slotIndex=4,state=1},
 {nodeID=20,slotIndex=5,state=1},{nodeID=30,slotIndex=6,state=1}} end}
P:FarmFlightOpened();assert(trips==0,'opt-out still flew')
P.db.farmAutoFly=true;P:FarmFlightOpened();assert(trips==1,'selected reachable flight failed')
P:FarmFlightOpened();assert(trips==1,'trip repeated without new selection')
P:SelectFarm(769,1);GetMoney=function() return 0 end
P:FarmFlightOpened();assert(trips==1,'flew without enough money')
GetMoney=function() return 100 end
STATE.combat=true;P:FarmFlightOpened();assert(trips==1,'flew during combat')
STATE.combat=false
C_TaxiMap.GetAllTaxiNodes=function() return {{nodeID=10,slotIndex=4,state=0}} end
P:FarmFlightOpened();assert(trips==1,'flew despite already at closest point')
P:OpenFarm(2678);assert(not P.farmWindow.rows[1].button:IsShown(),'vendor ingredient got invented farm')
P:OpenFarm(999999);assert(not P.farmWindow.rows[1].button:IsShown(),'unknown material got invented pin')
STATE.faction='Horde';STATE.map=1411
assert(P:FarmOptions(769)[1].m==1411,'Horde boar recommendation failed')
assert(#BLOCKED==0,'protected frame changes')
print('Farm recommendations, pins, vendor/unknown fallback, opt-in flights, fares, faction, reachability and combat checks PASS')
""")
