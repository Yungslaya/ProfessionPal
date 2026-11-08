from pathlib import Path
import runpy
ctx=runpy.run_path(str(Path(__file__).with_name('harvest_checks.py')))
L=ctx['L']
L.execute(r'''
local P=ProfessionPal
UNITS={}; GameTooltip:Hide()
STATE.combat=false; P.db.harvestAlert=true; P.db.harvestGuide=true
STATE.profs={{name='Mining',line=186,rank=75,max=300}}
FIRE('SKILL_LINES_CHANGED')
local px,py,map,facing,rotate=.5,.5,1454,0,'0'
local cx,cy=150,100
local over=true
Minimap=CreateFrame('Minimap')
Minimap.IsMouseOver=function() return over end
Minimap.GetWidth=function() return 200 end
Minimap.GetHeight=function() return 200 end
Minimap.GetEffectiveScale=function() return 1 end
Minimap.GetCenter=function() return 100,100 end
C_Minimap={GetViewRadius=function() return 100 end}
C_Map.GetBestMapForUnit=function() return map end
C_Map.GetMapWorldSize=function() return 1000,1000 end
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return px,py end} end
GetPlayerFacing=function() return facing end
GetCursorPosition=function() return cx,cy end
GetCVar=function() return rotate end
-- One real minimap hover gives an approximate location; it isn't a saved/live node yet.
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Copper Vein'}}})
local n=P.harvestNavigation
assert(n and n.name=='Copper Vein' and n.source=='minimap' and not n.confirmed,'minimap hint provenance')
assert(math.abs(n.x-.55)<.000001 and math.abs(n.y-.5)<.000001,'minimap coordinate transform')
assert(not P.db.harvestNodes or #(P.db.harvestNodes[map] or {})==0,'hover alone must not save a confirmed spot')
P.harvestArrow.pic.SetRotation=function(self,a) self.angle=a end
P:HarvestGuideUpdate()
assert(math.abs(P.harvestArrow.pic.angle+math.pi/2)<.00001,'east points right')
-- Leave the minimap: the arrow continues without keeping the mouse there.
over=false; px=.52; P:HarvestGuideUpdate()
assert(P.harvestNavigation and P.harvestNavigation.distance<31,'guidance follows movement')
-- Actually reach a detected node: persist its approximate location.
px=.547
UNITS.softinteract={object=true,name='Copper Vein',cursor='Mine',range=true}
P:HarvestScan(); P:HarvestGuideUpdate()
assert(#P.db.harvestNodes[map]==1,'arrival saved a spot')
assert(ProfessionPalDB.harvestNodes==P.db.harvestNodes,'history lives in SavedVariables')
assert(P.harvestNavigation.confirmed,'live detection confirms existence')
HARVEST_TIME=HARVEST_TIME+6; P:HarvestScan()
assert(#P.db.harvestNodes[map]==1,'one node not recorded every tick')
-- Later revisit, without hovering any node: automatically select the saved spot.
UNITS={}; px=.42; P:HarvestScan(); FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate()
n=P.harvestNavigation
assert(n and n.source=='history' and not n.confirmed and n.name=='Copper Vein','automatic historical guidance')
assert(n.distance>120 and n.distance<130,'distance based on saved coordinates')
-- A rotating minimap: the upper dot is ahead (west when facing west).
over=true; px=.5; py=.5; cx=100; cy=150; facing=math.pi/2; rotate='1'
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Tin Vein'}}})
n=P.harvestNavigation
assert(n and n.source=='minimap' and math.abs(n.x-.45)<.000001 and math.abs(n.y-.5)<.000001,'rotating minimap transform')
assert(math.abs(P.harvestArrow.pic.angle)<.00001,'arrow straight ahead when facing dot')
-- No guessing when map position is secret; no auto-confirmation at an empty saved spot.
local S={secret=true}
px=S; P:HarvestGuideUpdate(); assert(not P.harvestArrow:IsShown(),'secret map position hidden')
px=.547; py=.5; over=false; facing=0; rotate='0'
FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestScan(); P:HarvestGuideUpdate()
assert(P.harvestNavigation and not P.harvestNavigation.confirmed,'arrival alone is not live confirmation')
HARVEST_TIME=HARVEST_TIME+13; P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'unconfirmed spot stops nagging after wait')
assert(#P.db.harvestNodes[map]==1,'unconfirmed spot not deleted')
-- Different character profession: never guide a herbalist to stored ore.
STATE.profs={{name='Herbalism',line=182,rank=100,max=300}}; FIRE('SKILL_LINES_CHANGED')
px=.42; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'history filtered by current character profession')
STATE.combat=true; P:HarvestGuideUpdate(); assert(not P.harvestArrow:IsShown(),'arrow hidden in combat')
STATE.combat=false
SlashCmdList.PROFESSIONPAL('harvest guide off'); assert(not P.harvestArrow:IsShown(),'guide off')
SlashCmdList.PROFESSIONPAL('harvest guide on')
assert(#BLOCKED==0,'no protected-frame changes')
print('Saved-node checks PASS: minimap transform, arrow bearing, rotating map, arrival-only persistence, automatic revisit, no false confirmation, expiry and profession filtering')
''')
print('ALL SAVED-NODE CHECKS PASSED')
