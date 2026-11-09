-- Farming areas are recommendations, not live mob scans or guaranteed spawns.
-- Classic ingredients/areas: Wowhead cooking farming guide (2026-11-08).
-- Forever recipe progression: Icy Veins Forever Cooking leveling guide.
-- Pins mark approximate area centers; they are not measured spawn coordinates.
local _,PP=...
local secret=issecretvalue or function() return false end
local function plain(v) if not secret(v) then return v end end
local function num(v) return not secret(v) and type(v)=="number" and v==v end
local function call(fn,...)
    if type(fn)~="function" then return end
    local ok,v=pcall(fn,...); if ok and not secret(v) then return v end
end
local function area(map,x,y,zone,mobs,level,faction)
    return {m=map,x=x,y=y,p=zone,n=zone,mobs=mobs,level=level,faction=faction,approx=true}
end
local boar={
 area(1429,35,84,"Elwynn Forest - Stonefield Farm","Boars in the fields",6,"Alliance"),
 area(1432,37,34,"Loch Modan - western fields","Mountain boars",12,"Alliance"),
 area(1411,48,43,"Durotar - Razor Hill outskirts","Mottled boars",6,"Horde"),
}
local eggs={area(1437,37,31,"Wetlands - western raptor fields","Raptors",24),
 area(1417,46,65,"Arathi Highlands - central plains","Raptors",33),
 area(1434,30,26,"Stranglethorn Vale - northern jungle","Raptors",33)}
local flesh={eggs[2],eggs[3]}
PP.farmSources={
 [769]=boar,
 [2673]={area(1436,53,34,"Westfall - north of Sentinel Hill","Coyotes",12)},
 [2677]={area(1436,51,40,"Westfall - northern farms","Goretusks",14,"Alliance"),boar[2]},
 [3685]=eggs,[12184]=flesh,
 [12208]={area(1425,25,49,"The Hinterlands - western hills","Wolves",43),
 area(1446,44,33,"Tanaris - northern desert","Hyenas",43)},
 [2672]={area(1429,46,54,"Elwynn Forest - Goldshire woods","Wolves",6,"Alliance"),
 area(1420,49,55,"Tirisfal Glades - western fields","Darkhounds",7,"Horde")},
 [6889]={area(1438,56,57,"Teldrassil - Dolanaar woods","Owls",7,"Alliance"),
 area(1412,48,58,"Mulgore - Bloodhoof outskirts","Swoops",8,"Horde")},
 [2589]={area(1436,45,44,"Westfall - northern camps","Humanoids",14,"Alliance"),
 area(1413,56,26,"The Barrens - northeastern camps","Humanoids",14,"Horde")},
 [2678]={vendor=true,text="Buy Mild Spices from a cooking supplies vendor."},
 [2692]={vendor=true,text="Buy Hot Spices from a cooking supplies vendor."},
 [3713]={vendor=true,text="Buy Soothing Spices from a cooking supplies vendor."},
}
-- Reuse actual discovered gathering locations for ore/herbs rather than inventing nodes.
local nodeKinds={[2770]={"Copper Vein","Poor Copper Vein"},[2771]={"Tin Vein"},[2772]={"Iron Deposit"},
 [2775]={"Silver Vein"},[2776]={"Gold Vein"},[3858]={"Mithril Deposit"},[7911]={"Truesilver Deposit"},
 [10620]={"Small Thorium Vein","Rich Thorium Vein"},[765]={"Silverleaf"},[2447]={"Peacebloom"},[2449]={"Earthroot"}}
function PP:FarmOptions(id)
    local faction,level=self:Faction(),self:PlayerLevel()
    local candidates={}
    local source=self.farmSources[id]
    for _,v in ipairs(source or {}) do
        if not v.faction or v.faction==faction then
            local a={}; for k,value in pairs(v) do a[k]=value end
            a.distance=self:Distance(a.m,a.x,a.y)
            a.tooHigh=level<a.level
            candidates[#candidates+1]=a
        end
    end
    local wanted=nodeKinds[id]
    if wanted then
        for map,records in pairs(self.db.harvestNodes or {}) do
            if type(records)=="table" then for _,n in ipairs(records) do
                if type(n)=="table" and num(n.x) and num(n.y) and num(map) then
                    for _,name in ipairs(wanted) do if n.name==name then
                        local a=area(map,n.x*100,n.y*100,"Saved "..name,name,1)
                        a.tooHigh=false; a.distance=self:Distance(map,a.x,a.y); candidates[#candidates+1]=a; break
                    end end
                end
            end end
        end
    end
    local current=self:CurrentMap()
    table.sort(candidates,function(a,b)
        if a.tooHigh~=b.tooHigh then return not a.tooHigh end
        if (a.m==current)~=(b.m==current) then return a.m==current end
        if (a.distance or 1e8)~=(b.distance or 1e8) then return (a.distance or 1e8)<(b.distance or 1e8) end
        return a.p<b.p
    end)
    return candidates,source and source.text
end
function PP:SelectFarm(id,index)
    if call(InCombatLockdown)==true then self:Print("Choose a farming spot after combat.");return end
    local options=self:FarmOptions(id); local a=options[index or 1]
    if not a then return end
    local name=self:MatName(id)
    self.farmTrip={item=id,m=a.m,x=a.x,y=a.y,n=name,p=a.p,expires=GetTime()+1800}
    self:Pin(self.farmTrip)
    self:Print(a.p..": "..a.mobs..". Pin marks an approximate farming area.")
    return self.farmTrip
end
local window
function PP:OpenFarm(id)
    if not window then
        local w=CreateFrame("Frame","ProfessionPalFarmGuide",UIParent);window=w;self.farmWindow=w
        w:SetSize(500,470); w:SetPoint("CENTER");w:SetFrameStrata("DIALOG")
        w:SetMovable(true);w:EnableMouse(true);w:RegisterForDrag("LeftButton");w:SetClampedToScreen(true)
        w:SetScript("OnDragStart",function(f) f:StartMoving() end)
        w:SetScript("OnDragStop",function(f) f:StopMovingOrSizing() end)
        if self.StyleWindow then self:StyleWindow(w) else
            local bg=w:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints();bg:SetColorTexture(.03,.055,.09,1)
        end
        local function label(size,x,y,width)
            local t=w:CreateFontString(nil,"OVERLAY"); t:SetFont(PP.FONT,size,"")
            t:SetPoint("TOPLEFT",x,y);t:SetWidth(width);t:SetJustifyH("LEFT");return t
        end
        w.title=label(18,18,-18,415);w.note=label(14,18,-51,460)
        local close=PP.UIButton(w,"X",28,26,function() w:Hide() end);close:SetPoint("TOPRIGHT",-10,-10)
        w.rows={}
        for i=1,4 do
            local row={};w.rows[i]=row
            row.text=label(14,18,-100-(i-1)*65,350)
            row.button=PP.UIButton(w,"Pin",72,28,function() PP:SelectFarm(w.item,i) end)
            row.button:SetPoint("TOPRIGHT",-18,-100-(i-1)*65)
        end
        w.fly=CreateFrame("CheckButton",nil,w,"UICheckButtonTemplate");w.fly:SetPoint("BOTTOMLEFT",14,44)
        local caption=label(14,48,-382,430);caption:SetText("Auto-fly toward my selected farming spot")
        w.fly:SetScript("OnClick",function(f) PP.db.farmAutoFly=f:GetChecked() and true or false end)
        local help=label(12,18,-424,460);help:SetText("Uses a known, reachable flight when you open a flight master. Fares apply.")
        table.insert(UISpecialFrames,"ProfessionPalFarmGuide")
    end
    window.item=id;window.title:SetText("Find "..self:MatName(id));window.fly:SetChecked(self.db.farmAutoFly==true)
    local options,note=self:FarmOptions(id)
    window.note:SetText(note or (#options>0 and "Recommended areas for your location and level. Approximate pins."
        or self:MatWhere(id).." No mapped farming spot saved yet."))
    for i,row in ipairs(window.rows) do
        local a=options[i]
        row.button:SetShown(a~=nil);row.text:SetShown(a~=nil)
        if a then row.text:SetText((i==1 and "Recommended: " or "")..a.p.."\n"..a.mobs.." - level "..a.level.."+"..(a.tooHigh and " (higher than you)" or "")) end
    end
    window:Show()
end
function PP:BindFarmRow(row,id)
    if not row.find then
        row.find=PP.UIButton(row,"Find",58,25,function() PP:OpenFarm(row.farmItem) end)
        row.find:SetPoint("RIGHT",row,"RIGHT",0,0)
    end
    row.farmItem=id;row.find:Show()
    row.name:SetWidth(200);row.count:ClearAllPoints();row.count:SetPoint("RIGHT",row,"RIGHT",-66,0);row.count:SetWidth(100)
end
-- Normal taxi selection only: never unlock, retry a blocked call, or select unknown routes.
PP.farmFlight={status="Off"}
function PP:FarmFlightOpened()
    local state=self.farmFlight;state.status="Off"
    if not self.db.farmAutoFly then return end
    local target=self.farmTrip
    if not target or GetTime()>target.expires then state.status="Choose a farming pin first";return end
    if call(InCombatLockdown)==true then state.status="Paused in combat";return end
    if not C_TaxiMap or not C_TaxiMap.GetTaxiNodesForMap or not C_TaxiMap.GetAllTaxiNodes then
        state.status="Flight data unavailable; choose your flight normally";self:Print(state.status);return
    end
    local nodes=call(C_TaxiMap.GetTaxiNodesForMap,target.m)
    if type(nodes)~="table" then state.status="No mapped flight near this spot";self:Print(state.status);return end
    local reachable={}
    local map=self:CurrentMap()
    for _=1,6 do
        if not num(map) then break end
        local all=call(C_TaxiMap.GetAllTaxiNodes,map)
        if type(all)=="table" then for _,n in ipairs(all) do
            if not secret(n) and type(n)=="table" and num(n.nodeID) and num(n.slotIndex) and num(n.state) then
                if n.state==1 or n.state==0 then reachable[n.nodeID]=n end
            end
        end end
        local info=C_Map and call(C_Map.GetMapInfo,map)
        map=type(info)=="table" and plain(info.parentMapID) or nil
        if map==0 then break end
    end
    local w,h
    if C_Map and C_Map.GetMapWorldSize then
        local ok,a,b=pcall(C_Map.GetMapWorldSize,target.m);if ok and num(a) and num(b) then w,h=a,b end
    end
    if not w or not h or w<=0 or h<=0 then state.status="Flight distance unavailable";return end
    local chosen,best
    local own=self:Faction()=="Horde" and 1 or 2
    for _,n in ipairs(nodes) do
        if not secret(n) and type(n)=="table" and num(n.nodeID) and plain(n.isUndiscovered)==false
            and (plain(n.faction)==0 or plain(n.faction)==own) then
            local route=reachable[n.nodeID]; local pos=plain(n.position)
            if route and pos and not secret(pos) then
                local x,y
                if pos.GetXY then local ok,a,b=pcall(pos.GetXY,pos);if ok and num(a) and num(b) then x,y=a,b end
                elseif num(pos.x) and num(pos.y) then x,y=pos.x,pos.y end
                if x and y then
                    local d=((x-target.x/100)*w)^2+((y-target.y/100)*h)^2
                    if not best or d<best then chosen,best=route,d end
                end
            end
        end
    end
    if not chosen then state.status="No known reachable flight near this farming area";self:Print(state.status);return end
    if chosen.state==0 then state.status="Already at the closest flight point";self:Print(state.status);return end
    local cost=call(TaxiNodeCost,chosen.slotIndex) or call(GetTaxiCost,chosen.slotIndex)
    local money=call(GetMoney)
    if not num(cost) or not num(money) then state.status="Fare unavailable; select the flight manually";self:Print(state.status);return end
    if cost>money then state.status="Not enough money for this flight";self:Print(state.status);return end
    if type(TakeTaxiNode)~="function" then state.status="Select the flight manually";self:Print(state.status);return end
    local ok=pcall(TakeTaxiNode,chosen.slotIndex)
    if ok then
        state.status="Flight requested: "..(plain(chosen.name) or target.p)
        self.farmTrip=nil -- one trip per explicit farming selection
    else state.status="Flight selection blocked; choose it manually" end
    self:Print(state.status)
end
local events=CreateFrame("Frame");events:RegisterEvent("TAXIMAP_OPENED")
events:SetScript("OnEvent",function() if PP.db then PP:FarmFlightOpened() end end)
