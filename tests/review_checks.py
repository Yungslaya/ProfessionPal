from pathlib import Path
import os, sys, subprocess
from lupa import lua51
base=Path(__file__).resolve().parent.parent
addon=base/'ProfessionPal'
old=Path(__file__).resolve().parent
def runtime():
 l=lua51.LuaRuntime(unpack_returned_tuples=True)
 l.execute((old/'harness.lua').read_text(encoding='utf-8-sig'))
 ns=l.eval('{}')
 for n in (addon/'ProfessionPal.toc').read_text().splitlines():
  if n and not n.startswith('#'):
   chunk=l.eval('loadstring')((addon/n).read_text(encoding='utf-8-sig'),n)
   if isinstance(chunk,tuple):raise AssertionError(chunk)
   chunk('ProfessionPal',ns)
 g=l.eval('{}')
 for f in (old/'guides').glob('*.txt'):g[f.stem]=f.read_text(encoding='utf-8-sig')
 l.globals().GUIDES=g
 l.execute('FIRE("PLAYER_LOGIN")')
 return l
l=runtime()
l.execute('''
local P=ProfessionPal
local calls=0
local player="Alpha"
UnitName=function() return player end
GetRealmName=function() return "TestRealm" end
STATE.level=40; STATE.class="WARRIOR"; STATE.equip={}
STATE.profs={{name="Blacksmithing",line=164,rank=150,max=225}}
P.db.selected="blacksmithing"
local it={name="Test Sword",id=777,src="T",profKey="blacksmithing",mats={{2840,10}}}
local bank,bag=20,0
C_Item.GetItemCount=function(_,includeBank) return includeBank and bank or bag end
assert(P:Count(2840)==20 and P:Count(2840,true)==0,"bank and bags distinct")
assert(not P:CanCraft(it),"unlearned recipe blocked")
C_TradeSkillUI.GetAllRecipeIDs=function() return {501} end
local wrong=false
C_TradeSkillUI.GetRecipeInfo=function() return {name=wrong and "Other Sword" or "Test Sword",learned=true} end
C_TradeSkillUI.GetRecipeSchematic=function() return {reagentSlotSchematics={{reagents={{itemID=2840}},quantityRequired=10,required=true}}} end
P:ScanKnownRecipes()
assert(not P:CanCraft(it),"bank-only materials not craft ready")
bag=10
assert(P:CanCraft(it),"learned plus bag materials ready")
ProfessionsFrame=CreateFrame("Frame"); ProfessionsFrame:Show()
C_TradeSkillUI.CraftRecipe=function(id,n) assert(id==501 and n==1); calls=calls+1 end
C_TradeSkillUI.GetCraftableCount=function() return 1 end
wrong=true; P:CraftGear(it); assert(calls==0,"wrong recipe blocked")
wrong=false; P:CraftGear(it); assert(calls==1,"one click one craft")
C_TradeSkillUI.GetCraftableCount=function() return 0 end
P:CraftGear(it); assert(calls==1,"unavailable recipe not crafted")
player="Beta"; assert(not P:CanCraft(it),"other character cannot reuse known recipe")
P:CraftGear(it); assert(calls==1,"other character cannot use recipe id")
C_TradeSkillUI.IsTradeSkillLinked=function() return true end
P:ScanKnownRecipes(); assert(not P:KnowsCraft(it.name),"linked recipes not remembered")
C_TradeSkillUI.IsTradeSkillLinked=nil
-- Empty recipe materials must not look ready.
it.name="Unknown Recipe"; it.mats={}; assert(not P:MatsReady(it),"unknown materials cannot be ready")
-- No future level or plate recommendations on a level 39 warrior.
STATE.level=39
for _,row in ipairs(P:GearBySlot(P.byKey.blacksmithing,300)) do
 if row.now then assert(row.now.it.level<=39 and row.now.it.sub~=4,"level/plate gate") end
end
-- Imported steps take over mid-way through a built-in recipe in shopping totals.
local def={key="test",name="Test",ranks={{cap=75,skill=0}},steps={{from=1,to=75,text="Base",crafts=74,total=true,mats={{1,74,"Base mat"}}}}}
P.db.guides.test={title="Custom",steps={{from=10,to=20,text="Custom",crafts=10,total=true,imported=true,mats={{2,10,"Custom mat"}}}}}
P.db.useGuide.test=true
local shopping=P:ShoppingList(def,1,75)
local found=false;for _,m in ipairs(shopping) do if m.item==2 then found=m.need==10 end end
assert(found,"imported mid-step materials included")
-- Plans outstanding: never say everything is ready.
local plan={name="Guard's Chain Belt",id=250514,src="P",profKey="blacksmithing",slot=6,q=3,mats={{2840,10}},plan={cost=30}}
P:ShowGearShop({plan})
assert(P.gearShop.status:GetText()=="Recipe needed","plans checked in status")
assert(P.gearShop.body and P.gearShop.scroll,"shopping viewport exists")
P.gearShop.scroll:GetScript("OnMouseWheel")(P.gearShop.scroll,-1)
assert(P.gearShop.offset>=0 and P.gearShop.offset<=P.gearShop.maxScroll,"scroll clamped")
-- Cost API failure is never treated as free.
STATE.profs={{name="Blacksmithing",line=164,rank=50,max=75}}
P.db.autoLearn=true; BOUGHT={}; STATE.trainer={{name="Bronze Warhammer",sub="",typ="available",cost=99999}}
GetTrainerServiceCost=function() return nil end
FIRE("TRAINER_SHOW"); assert(#BOUGHT==0,"unknown price not purchased")
print("PASS: bank, recipes, characters, linked data, craft guards, armor, import boundaries, plans, scroll, trainer price")
''')
for name in ['zonetest.lua','recipetest.lua','importtest.lua','importtest2.lua','traveltest.lua','favortest.lua','tiptest.lua','shoptest.lua','scantest.lua']:
 try:
  ll=runtime();ll.execute((old/name).read_text(encoding='utf-8-sig')); print('PASS:',name)
 except Exception as e: print('FAIL:',name,e);sys.exit(1)
ll=runtime()
ll.execute('''
local P=ProfessionPal
STATE.profs={{name="Blacksmithing",line=164,rank=50,max=75}}
STATE.class="WARRIOR"; STATE.level=14; STATE.equip={}
P.db.selected="blacksmithing"; P.frame:Show(); P:Refresh()
assert(P.frame.stepPanel:IsShown(),"step card visible")
assert(P.FONT=="Fonts\\\\ARIALN.TTF","readable body font")
STATE.combat=true; FIRE("PLAYER_REGEN_DISABLED"); P:Refresh()
assert(#BLOCKED==0,"visual changes obey combat lockdown")
STATE.combat=false; FIRE("PLAYER_REGEN_ENABLED")
print("PASS: step card, font and combat layout")
''')
print('ALL REVIEW CHECKS PASSED')

