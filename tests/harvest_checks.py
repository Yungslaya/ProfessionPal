from pathlib import Path
import sys
from lupa import lua51
b=Path(__file__).resolve().parent.parent
L=lua51.LuaRuntime(unpack_returned_tuples=True)
L.execute((b/'Tests/harness.lua').read_text(encoding='utf-8-sig'))
L.execute(r'''
UNITS={}; TOOLTIP_CALLBACKS={}; HARVEST_TIME=1000
function GetFileIDFromPath(path)
    if path=='Interface\\Cursor\\Mine' then return 9990 end
    if path=='Interface\\Cursor\\UnableMine' then return 9991 end
end
Enum={TooltipDataType={Object=1,Unit=2,Item=3,Spell=4,MinimapMouseover=5}}
TooltipDataProcessor={AddTooltipPostCall=function(k,fn) TOOLTIP_CALLBACKS[k]=fn end}
function UnitExists(u) return UNITS[u]~=nil and not UNITS[u].object end
function UnitIsGameObject(u) return UNITS[u] and UNITS[u].object or false end
function UnitIsDead(u) return UNITS[u] and UNITS[u].dead or false end
function UnitIsDeadOrGhost() return false end
function UnitName(u) return UNITS[u] and UNITS[u].name end
function UnitIsInInteractRange(u) return UNITS[u] and UNITS[u].range end
function SetUnitCursorTexture(tex,u)
    local node=UNITS[u]; tex:SetTexture(node and node.cursor)
    return node~=nil
end
C_TooltipInfo={GetUnit=function(u) return UNITS[u] and UNITS[u].tip end}
GameTooltip.HookScript=function(self,key,fn) self._scripts[key]=fn end
GameTooltip.Hide=function(self) self._shown=false; if self._scripts.OnHide then self._scripts.OnHide(self) end end
function SetCVar() error('must not change settings') end
function InteractUnit() error('must not gather') end
function TargetUnit() error('must not target') end
function CastSpellByName() error('must not cast') end
''')
ns=L.eval('{}')
for file in (b/'ProfessionPal/ProfessionPal.toc').read_text().splitlines():
    if file and not file.startswith('#'):
        chunk=L.eval('loadstring')((b/'ProfessionPal'/file).read_text(encoding='utf-8-sig'),file)
        if isinstance(chunk,tuple): raise AssertionError(chunk)
        chunk('ProfessionPal',ns)
L.execute(r'''
FIRE('PLAYER_LOGIN')
local P=ProfessionPal
P.db.harvestAlert=true;P.db.harvestGuide=true -- opt into gathering helpers
local function prof(key,line,rank)
    STATE.profs={{name=key,line=line,rank=rank,max=300}}
    FIRE('SKILL_LINES_CHANGED')
end
local function clear() UNITS={}; GameTooltip:Hide(); P:HarvestScan() end
local function shown(status,kind)
    assert(P.harvestFrame:IsShown(),'expected alert')
    assert(P.harvestState.status==status,'status '..tostring(P.harvestState.status)..' expected '..status)
    assert(P.harvestState.kind==kind,'wrong profession')
end
local copper={object=true,name='Copper Vein',cursor='Interface\\Cursor\\Mine',range=true}
UNITS.softinteract=copper; P:HarvestScan()
assert(not P.harvestFrame:IsShown(),'non-gatherer gets no alert')
prof('Mining',186,50); P:HarvestScan(); shown('ready','mining')
copper.cursor=9990; P:HarvestScan(); shown('ready','mining')
copper.cursor=9991; P:HarvestScan(); shown('blocked','mining')
copper.cursor='Mine'
copper.range=false; P:HarvestScan(); shown('far','mining')
copper.range=nil; P:HarvestScan(); shown('nearby','mining')
copper.range=true; copper.cursor='Cursor_Crosshair_UnableMine_64'
P:HarvestScan(); shown('blocked','mining')
copper.tip={lines={{leftText='Tin Vein'},{leftText='Requires Mining (65)'}}}
P:HarvestScan(); shown('skill','mining')
prof('Mining',186,60); P:HarvestScan()
assert(P.harvestFrame.status:GetText():find('60',1,true),'skill text stays fresh')
clear(); prof('Herbalism',182,100)
UNITS.softinteract={object=true,name='Peacebloom',cursor='Interface\\Cursor\\GatherHerbs',range=true}
P:HarvestScan(); shown('ready','herbalism')
prof('Mining',186,100); P:HarvestScan(); assert(not P.harvestFrame:IsShown(),'wrong profession hidden')
clear(); prof('Skinning',393,100)
UNITS.softinteract={dead=true,name='Wolf',cursor='Interface\\Cursor\\Skin',range=true}
P:HarvestScan(); shown('ready','skinning')
UNITS.softinteract.dead=false; P:HarvestScan(); assert(not P.harvestFrame:IsShown(),'living unit hidden')
clear()
UNITS.target={dead=true,name='Wolf',tip={lines={{leftText='Wolf'},{leftText='Skinnable'}}},range=true}
P:HarvestScan(); shown('nearby','skinning') -- no positive skin cursor: no READY claim
clear(); prof('Herbalism',182,100)
UNITS.mouseover={object=true,name='Peacebloom',cursor='GatherHerbs',range=true}
P:HarvestScan(); shown('ready','herbalism')
STATE.combat=true; FIRE('PLAYER_REGEN_DISABLED'); assert(not P.harvestFrame:IsShown(),'combat hidden')
STATE.combat=false; FIRE('PLAYER_REGEN_ENABLED'); shown('ready','herbalism')
SlashCmdList.PROFESSIONPAL('harvest off'); assert(not P.harvestFrame:IsShown(),'off hides immediately')
SlashCmdList.PROFESSIONPAL('harvest on'); shown('ready','herbalism')
clear(); prof('Mining',186,1)
GameTooltip:Show()
TOOLTIP_CALLBACKS[1](GameTooltip,{lines={{leftText='Copper Vein'},{leftText='Requires Mining (1)'}}})
P:HarvestScan(); shown('nearby','mining')
TOOLTIP_CALLBACKS[3](GameTooltip,{lines={{leftText='Mining Pick'}}}); P:HarvestScan()
assert(not P.harvestFrame:IsShown(),'item tooltip clears world hint')
TOOLTIP_CALLBACKS[1](GameTooltip,{lines={{leftText='Tin Vein'},{leftText='Requires Mining (65)'}}})
P:HarvestScan(); shown('skill','mining')
GameTooltip:Hide(); assert(not P.harvestFrame:IsShown(),'tooltip hide clears hint')
-- Secrets are ignored, never compared or formatted into ordinary strings.
local mt={__lt=function() error('secret comparison') end,__le=function() error('secret comparison') end,
          __concat=function() error('secret concat') end,__index=function() error('secret index') end}
local S=setmetatable({secret=true},mt)
UNITS.softinteract={object=true,name=S,cursor='Mine',range=S}
P:HarvestScan(); shown('nearby','mining')
UNITS.softinteract.cursor=S; P:HarvestScan(); assert(not P.harvestFrame:IsShown(),'secret cursor hidden')
GameTooltip:Show(); TOOLTIP_CALLBACKS[1](GameTooltip,{lines=S}); P:HarvestScan()
assert(not P.harvestFrame:IsShown(),'secret tooltip hidden')
clear(); SlashCmdList.PROFESSIONPAL('harvest test'); shown('preview','mining')
HARVEST_TIME=HARVEST_TIME+6; P:HarvestScan(); assert(not P.harvestFrame:IsShown(),'preview expires')
SlashCmdList.PROFESSIONPAL('harvest unlock'); shown('preview','mining')
SlashCmdList.PROFESSIONPAL('harvest lock'); assert(not P.harvestFrame:IsShown(),'lock restores live scan')
assert(#BLOCKED==0,'no protected frame operations in combat')
print('Harvest checks PASS: professions, herbs/ore/skin, range, skill, mouseover/soft/target, tooltips, combat, secrets, controls')
''')
print('ALL HARVEST CHECKS PASSED')
