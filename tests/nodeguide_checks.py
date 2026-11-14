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
assert(#P.db.harvestNodes[map]==1 and P.db.harvestNodes[map][1].source=='minimap','hover saves an approximate historical sighting')
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
assert(P.db.harvestNodes[map][1].name=='Copper Vein','unconfirmed spot not deleted')
-- Different character profession: never guide a herbalist to stored ore.
STATE.profs={{name='Herbalism',line=182,rank=100,max=300}}; FIRE('SKILL_LINES_CHANGED')
px=.42; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'history filtered by current character profession')
-- Combined node names must not be treated as one unknown node or flicker by order.
over=true; px=.5; py=.5; cx=150; cy=100
P:HarvestGuideCommand('debug on')
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Peacebloom\nSilverleaf'}}})
-- Invisible spaces, named colors, embedded textures and links must still match.
for _,name in ipairs({'\194\160Silverleaf\194\160','|cnGREEN_FONT_COLOR:Silverleaf|r',
    '|TInterface\\Icons\\INV_Misc_Herb_10:12|tSilverleaf',
    '|Hthing:1|hSilverleaf|h','\226\128\139Silverleaf'}) do
    TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText=name}}})
    assert(P.harvestNavigation.name=='Silverleaf','formatted Silverleaf missed')
end
for _,name in ipairs({'Silverleaf (Above)','Silverleaf (Below)',
    'Silverleaf [Above]','\226\150\178 Silverleaf','Silverleaf \226\150\188'}) do
    TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText=name}}})
    assert(P.harvestNavigation.name=='Silverleaf','elevated node name missed')
end
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Peacebloom\nSilverleaf'}}})
local chosen=P.harvestNavigation.name
assert(chosen=='Peacebloom' or chosen=='Silverleaf','stacked tooltip not recognized')
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Silverleaf\nPeacebloom'}}})
assert(P.harvestNavigation.name==chosen,'stacked tooltip order changed selection')
assert(not P.harvestNodeDebug.last:find('Unrecognized'),'recognized stack reported unknown')
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Earthroot'}}})
assert(P.harvestNavigation.name=='Earthroot','new hover failed to replace previous node')
P:HarvestGuideCommand('debug off')
-- Historical pins survive navigation clearing, and never appear on another zone map.
WorldMapFrame=CreateFrame('Frame'); local canvas=CreateFrame('Frame')
WorldMapFrame.GetCanvas=function() return canvas end
WorldMapFrame.GetMapID=function() return map end
canvas.GetWidth=function() return 1000 end; canvas.GetHeight=function() return 800 end
Minimap:Show(); rotate='0'; px=.5; py=.5
P.db.harvestNodes[map]={{map=map,name='Earthroot',kind='herbalism',x=.55,y=.5}}
P:HarvestPinsUpdate()
assert(P.harvestMapPins[1]:IsShown() and P.harvestMiniPins[1]:IsShown(),'map and minimap historical markers')
local point=P.harvestMiniPins[1]._points[1]
assert(math.abs(point[4]-50)<.001 and math.abs(point[5])<.001,'minimap marker coordinate')
rotate='1'; facing=math.pi/2; P:HarvestPinsUpdate()
point=P.harvestMiniPins[1]._points[1]
assert(math.abs(point[4])<.001 and math.abs(point[5]+50)<.001,'rotating minimap marker')
WorldMapFrame.GetMapID=function() return 999999 end; P:HarvestPinsUpdate()
assert(not P.harvestMapPins[1]:IsShown(),'wrong world map marker hidden')
P:HarvestGuideCommand('guide off'); P:HarvestPinsUpdate()
assert(P.harvestMiniPins[1]:IsShown(),'markers should remain with guidance off')
P:HarvestGuideCommand('markers off')
assert(not P.harvestMiniPins[1]:IsShown() and #P.db.harvestNodes[map]==1,'hide markers preserves history')
P:HarvestGuideCommand('markers on')
assert(P.harvestMiniPins[1]:IsShown(),'marker setting restores pins')
px=S; P:HarvestPinsUpdate(); assert(not P.harvestMiniPins[1]:IsShown(),'restricted position never guessed')
px=.5
-- Ignoring a hovered node clears its arrow without deleting its marker or reselecting it.
P.db.harvestGuide=true; P.db.harvestNodes[map]={}; UNITS={}
over=true; px=.5; py=.5; rotate='0'; cx=150; cy=100
FIRE('ZONE_CHANGED_NEW_AREA')
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Silverleaf'}}})
assert(P.harvestNavigation,'ignored-node test did not start')
over=false; px=.47; P:HarvestGuideUpdate()
HARVEST_TIME=HARVEST_TIME+2.1; P:HarvestGuideUpdate()
assert(not P.harvestNavigation and not P.harvestArrow:IsShown(),'walking away left arrow stuck')
HARVEST_TIME=HARVEST_TIME+3; P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'ignored saved copy immediately reacquired')
assert(#P.db.harvestNodes[map]==1,'ignoring deleted marker')
-- A fresh explicit hover can select a new sighting, but idle guidance expires too.
over=true; px=.5
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Earthroot'}}})
assert(P.harvestNavigation,'new sighting did not start')
over=false; HARVEST_TIME=HARVEST_TIME+21; P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'stationary ignored arrow never expired')
-- Distance cutoff applies to fresh minimap sightings as well as history.
over=true; px=.5
TOOLTIP_CALLBACKS[5](GameTooltip,{lines={{leftText='Peacebloom'}}})
over=false; px=.3; P:HarvestGuideUpdate()
assert(not P.harvestNavigation,'far-away minimap sighting retained arrow')
STATE.combat=true; P:HarvestGuideUpdate(); assert(not P.harvestArrow:IsShown(),'arrow hidden in combat')
STATE.combat=false
SlashCmdList.PROFESSIONPAL('harvest guide off'); assert(not P.harvestArrow:IsShown(),'guide off')
SlashCmdList.PROFESSIONPAL('harvest guide on')
assert(#BLOCKED==0,'no protected-frame changes')
print('Saved-node checks PASS: minimap transform, arrow bearing, rotating map, arrival-only persistence, automatic revisit, no false confirmation, expiry and profession filtering')
''')
print('ALL SAVED-NODE CHECKS PASSED')

# Guide spots: in a zone where you have found nothing yourself, the arrow and the minimap marks
# use the guide's own spot data (Data_Nodes.lua), for things your skill can gather.
L.execute(r"""
local P=ProfessionPal
local map=1417                       -- Arathi Highlands: nothing saved here
P.db.harvestNodes[map]={}
STATE.combat=false; P.db.harvestAlert=true; P.db.harvestGuide=true; P.db.harvestMarkers=true
STATE.profs={{name='Mining',line=186,rank=137,max=225}}
FIRE('SKILL_LINES_CHANGED'); HARVEST_TIME=HARVEST_TIME+10
local iron=P:NodePoints('Iron Deposit',map)[5]
local px,py=iron[1]/100-.05,iron[2]/100          -- 50 yards west of a known iron spot (map is 1000 yards wide here)
C_Map.GetBestMapForUnit=function() return map end
C_Map.GetMapWorldSize=function() return 1000,1000 end
C_Map.GetPlayerMapPosition=function() return {GetXY=function() return px,py end} end
GetCVar=function() return '0' end; GetPlayerFacing=function() return 0 end
UNITS={}; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate()
local n=P.harvestNavigation
assert(P.harvestArrow:IsShown() and n and n.source=='guide','arrow points at a guide spot in a new zone')
assert(n.name=='Iron Deposit' or n.name=='Gold Vein' or n.name=='Silver Vein' or n.name=='Tin Vein',n.name)
assert(#P.db.harvestNodes[map]==0,'guide spots are never written into your saved finds')
P:HarvestPinsUpdate()
assert(P.harvestMiniPins[1]:IsShown(),'guide spots show on the minimap')
-- Mithril needs 175 mining: no arrow for it at 137, even standing on a mithril spot.
local mithril=P:NodePoints('Mithril Deposit',map)
if mithril then
  local alone
  for _,m in ipairs(mithril) do
    local near=false
    for _,name in ipairs({'Iron Deposit','Gold Vein','Silver Vein','Tin Vein'}) do
      for _,q in ipairs(P:NodePoints(name,map) or {}) do if math.abs(q[1]-m[1])+math.abs(q[2]-m[2])<22 then near=true end end
    end
    if not near then alone=m end
  end
  if alone then
    px,py=alone[1]/100,alone[2]/100; HARVEST_TIME=HARVEST_TIME+30; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate()
    assert(not P.harvestArrow:IsShown(),'no arrow for a vein above your skill')
  end
end
-- a profession you do not have: nothing
STATE.profs={{name='Blacksmithing',line=164,rank=100,max=150}}; FIRE('SKILL_LINES_CHANGED')
px,py=iron[1]/100-.05,iron[2]/100; HARVEST_TIME=HARVEST_TIME+30; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate(); P:HarvestPinsUpdate()
assert(not P.harvestArrow:IsShown() and not P.harvestMiniPins[1]:IsShown(),'no mining, no mining spots')
-- the switch: guide spots off leaves only your own finds
STATE.profs={{name='Mining',line=186,rank=137,max=225}}; FIRE('SKILL_LINES_CHANGED')
P.db.harvestGuideSpots=false; HARVEST_TIME=HARVEST_TIME+30; FIRE('ZONE_CHANGED_NEW_AREA'); P:HarvestGuideUpdate(); P:HarvestPinsUpdate()
assert(not P.harvestArrow:IsShown() and not P.harvestMiniPins[1]:IsShown(),'guide spots can be switched off')
P.db.harvestGuideSpots=nil
assert(#BLOCKED==0,'no protected-frame changes')
print('ALL GUIDE-SPOT CHECKS PASSED')
""")
