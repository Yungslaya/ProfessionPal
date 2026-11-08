-- ProfessionPal harvest reminders. Display only: no targeting, gathering or CVar changes.
-- Reads Blizzard's current soft-interact unit, mouseover, target and visible tooltips.
local _, PP = ...
local secret = issecretvalue or function() return false end
local function hidden(v) return secret(v) or (issecrettable and type(v) == "table" and issecrettable(v)) end
local function read(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, v = pcall(fn, ...)
    if ok and not hidden(v) then return v end
end
local function text(v)
    if hidden(v) or type(v) ~= "string" then return nil end
    return v:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end
local KINDS = {
    herbalism = {verb="HERB", icon="Interface\\Icons\\Spell_Nature_NatureTouchGrow"},
    mining = {verb="MINE", icon="Interface\\Icons\\Trade_Mining"},
    skinning = {verb="SKIN", icon="Interface\\Icons\\INV_Misc_Pelt_Wolf_01"},
}
local skills, cursorIDs, tip = {}, {}, nil
local frame, probe, previewEnd, unlocked = nil, nil, nil, false
local refreshAt, elapsed, lastKey = 0, 0, nil
local function now() return GetTime() end

local function refreshSkills()
    for key in pairs(skills) do skills[key] = nil end
    for key in pairs(KINDS) do
        local def = PP.byKey[key]
        local skill = def and read(PP.GetSkill, PP, def)
        if type(skill) == "number" and skill > 0 then skills[key] = skill end
    end
    refreshAt = now() + 5
end
local function kindFromCursor(value)
    if hidden(value) then return nil end
    if type(value) == "number" then
        local entry = cursorIDs[value]
        if entry then return entry[1], entry[2] end
        return nil
    end
    if type(value) ~= "string" then return nil end
    local s = value:lower()
    local kind = s:find("gatherherb", 1, true) and "herbalism"
        or s:find("mining", 1, true) and "mining" or s:find("mine", 1, true) and "mining"
        or s:find("skin", 1, true) and "skinning"
    return kind, s:find("unable", 1, true) ~= nil
end
local function cursor(unit)
    if not probe or not SetUnitCursorTexture then return nil end
    probe:SetTexture(nil)
    local ok = pcall(SetUnitCursorTexture, probe, unit, nil, true, true)
    if not ok then return nil end
    local kind, blocked = kindFromCursor(read(probe.GetTexture, probe))
    if kind then return kind, blocked end
    return kindFromCursor(read(probe.GetAtlas, probe))
end
-- Requirement text is only read from a real world-object / corpse tooltip.
local function tooltipInfo(data, isObject)
    if hidden(data) or type(data) ~= "table" then return nil end
    local lines = data.lines
    if hidden(lines) or type(lines) ~= "table" then return nil end
    local title, kind, need, skin = nil, nil, nil, false
    for i, line in ipairs(lines) do
        if not hidden(line) and type(line) == "table" then
            local s = text(line.leftText)
            if s then
                if i == 1 then title = s end
                s = s:lower()
                if s:find("skinnable", 1, true) then skin = true end
                for key in pairs(KINDS) do
                    if s:find(key, 1, true) then
                        local number = s:match(key .. "[^%d]*(%d+)")
                        -- Avoid identifying a player or mob whose name happens to contain a profession.
                        if i > 1 and (number or s:find("requires", 1, true)) then
                            kind, need = key, tonumber(number)
                        end
                    end
                end
            end
        end
    end
    if skin then kind = "skinning" end
    if kind and (isObject or kind == "skinning") then
        return {kind=kind, name=title, required=need}
    end
end
local function candidate(unit)
    local isObject = read(UnitIsGameObject, unit) == true
    if not isObject and read(UnitExists, unit) ~= true then return nil end
    -- A living unit is never a harvest node, regardless of its name.
    if not isObject and read(UnitIsDead, unit) ~= true then return nil end
    local kind, blocked = cursor(unit)
    local cursorKind = kind
    local info = C_TooltipInfo and tooltipInfo(read(C_TooltipInfo.GetUnit, unit), isObject)
    kind = kind or (info and info.kind)
    if not kind or not skills[kind] then return nil end
    if kind ~= "skinning" and not isObject then return nil end
    local name = text(read(UnitName, unit)) or (info and info.name)
    local required = info and info.kind == kind and info.required or nil
    local range = read(UnitIsInInteractRange, unit)
    local status = "nearby"
    if required and skills[kind] < required then status = "skill"
    elseif range == false then status = "far"
    elseif blocked then status = "blocked"
    elseif range == true and cursorKind == kind then status = "ready" end
    return {kind=kind, name=name, required=required, skill=skills[kind], status=status, unit=unit}
end
local function hide()
    PP.harvestState = nil; lastKey = nil
    if frame then frame:Hide() end
end
local function show(state)
    local def = KINDS[state.kind]
    if not frame or not def then return end
    PP.harvestState = state
    local key = state.kind .. ":" .. (state.name or "") .. ":" .. state.status .. ":" .. tostring(state.required) .. ":" .. tostring(state.skill)
    if key ~= lastKey then
        lastKey = key
        frame.icon:SetTexture(def.icon)
        frame.title:SetText(def.verb .. (state.name and ("  " .. state.name) or ""))
        local message, color
        if state.status == "ready" then message, color = "In reach", PP.C.green
        elseif state.status == "far" then message, color = "Move closer", PP.C.yellow
        elseif state.status == "skill" then message, color = "Needs " .. state.required .. " - you have " .. state.skill, PP.C.red
        elseif state.status == "blocked" then message, color = "Can't gather yet - check the tooltip", PP.C.yellow
        elseif state.status == "preview" then message, color = "Preview - drag to move", PP.C.gold
        else message, color = "Nearby - range not confirmed", PP.C.gray end
        frame.status:SetText(message); frame.status:SetTextColor(unpack(color))
    end
    frame:Show()
end
function PP:HarvestScan()
    if not self.db or not frame then return end
    -- The frame is unprotected and contains no action buttons, so hiding is safe in combat.
    if self.db.harvestAlert == false or read(InCombatLockdown) == true or read(UnitIsDeadOrGhost, "player") == true then hide(); return end
    if previewEnd and now() < previewEnd then
        show({kind="mining", name="Harvest reminder", status="preview"}); return
    end
    previewEnd = nil
    if now() >= refreshAt then refreshSkills() end
    -- Prefer what the user is pointing at, then the game's nearby interaction target.
    for _, unit in ipairs({"mouseover", "softinteract", "target"}) do
        local state = candidate(unit)
        if state then
            if self.HarvestRemember then self:HarvestRemember(state) end
            show(state); return
        end
    end
    if tip and GameTooltip and read(GameTooltip.IsShown, GameTooltip) and skills[tip.kind] then
        local state = {kind=tip.kind, name=tip.name, required=tip.required, skill=skills[tip.kind], status="nearby"}
        if state.required and state.skill < state.required then state.status = "skill" end
        show(state); return
    end
    hide()
end
local function place()
    frame:ClearAllPoints()
    local p = PP.db.harvestPoint
    if type(p) == "table" and type(p[1]) == "string" and type(p[3]) == "number" and type(p[4]) == "number" then
        frame:SetPoint(p[1], UIParent, p[2] or p[1], p[3], p[4])
    else frame:SetPoint("CENTER", UIParent, "CENTER", 0, -90) end
end
local function build()
    if frame then return end
    frame = CreateFrame("Frame", "ProfessionPalHarvest", UIParent)
    PP.harvestFrame = frame
    frame:SetSize(330, 44); frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true)
    frame:SetMovable(true); frame:EnableMouse(false); frame:RegisterForDrag("LeftButton")
    frame.icon = frame:CreateTexture(nil, "ARTWORK"); frame.icon:SetSize(38, 38)
    frame.icon:SetPoint("LEFT"); frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFont(PP.TITLE_FONT, 18, "OUTLINE"); frame.title:SetPoint("TOPLEFT", 48, -1)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -1); frame.title:SetHeight(22); frame.title:SetJustifyH("LEFT"); frame.title:SetWordWrap(false)
    frame.status = frame:CreateFontString(nil, "OVERLAY")
    frame.status:SetFont(PP.FONT, 15, "OUTLINE"); frame.status:SetPoint("BOTTOMLEFT", 48, 2)
    frame.status:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2); frame.status:SetHeight(18); frame.status:SetJustifyH("LEFT"); frame.status:SetWordWrap(false)
    frame:SetScript("OnDragStart", function(f) if unlocked then f:StartMoving() end end)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        local p, _, rp, x, y = f:GetPoint()
        PP.db.harvestPoint = {p, rp, x, y}
    end)
    place(); frame:Hide()
    probe = UIParent:CreateTexture(nil, "BACKGROUND"); probe:Hide()
    for path, kind in pairs({Mine="mining", GatherHerbs="herbalism", Skin="skinning", Skinning="skinning"}) do
        for _, prefix in ipairs({"", "Unable"}) do
            local full = "Interface\\Cursor\\" .. prefix .. path
            local id = read(GetFileIDFromPath, full) or read(GetFileIDFromPath, full .. ".blp")
            if type(id) == "number" and id > 0 then cursorIDs[id] = {kind, prefix ~= ""} end
        end
    end
    refreshSkills()
    local v = read((C_CVar and C_CVar.GetCVar) or GetCVar, "SoftTargetInteract")
    if next(skills) and tonumber(v) == 0 then
        PP:Print("Harvest reminders: enable Interact Key in WoW Options > Controls for nearby alerts. Hovered or selected harvest targets also work.")
    end
end
function PP:HarvestCommand(arg)
    if not self.db then return end
    arg = (arg or ""):lower():match("^%s*(.-)%s*$")
    if self.HarvestGuideCommand and self:HarvestGuideCommand(arg) then return end
    if arg == "off" then self.db.harvestAlert = false; previewEnd = nil; hide(); if self.HarvestGuideUpdate then self:HarvestGuideUpdate() end; self:Print("Harvest reminders off.")
    elseif arg == "on" then self.db.harvestAlert = true; self:Print("Harvest reminders on."); self:HarvestScan()
    elseif arg == "test" or arg == "unlock" then
        self.db.harvestAlert = true
        unlocked = arg == "unlock"; frame:EnableMouse(unlocked)
        previewEnd = now() + (unlocked and 3600 or 5); lastKey = nil; self:HarvestScan()
        self:Print(unlocked and "Drag the harvest reminder, then /prof harvest lock." or "Harvest preview for 5 seconds.")
    elseif arg == "lock" then unlocked = false; frame:EnableMouse(false); previewEnd = nil; self:HarvestScan(); self:Print("Harvest reminder locked.")
    elseif arg == "reset" then self.db.harvestPoint = nil; place(); self:Print("Harvest reminder position reset.")
    else
        self:Print("Harvest: /prof harvest on | off | test | unlock | lock | reset | map | skip | guide on | guide off")
        self:Print("Nearby detection uses WoW's Interact Key setting. Enable it in Options > Controls. Hovered and selected harvest targets also work. Reminders hide in combat.")
        if not next(skills) then self:Print("This character has no learned Mining, Herbalism or Skinning.") end
    end
end
local ev = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UPDATE_MOUSEOVER_UNIT", "PLAYER_TARGET_CHANGED", "PLAYER_SOFT_INTERACT_CHANGED", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "LOOT_CLOSED", "UNIT_SPELLCAST_SUCCEEDED"}) do
    pcall(ev.RegisterEvent, ev, event)
end
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not PP.db then return end
        if PP.db.harvestAlert == nil then PP.db.harvestAlert = false end
        build()
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL" then refreshAt = 0 end
    if event == "UPDATE_MOUSEOVER_UNIT" or event == "PLAYER_TARGET_CHANGED" or event == "LOOT_CLOSED" or event == "PLAYER_REGEN_DISABLED" then tip = nil end
    if event == "PLAYER_REGEN_DISABLED" then hide() else PP:HarvestScan() end
end)
ev:SetScript("OnUpdate", function(_, dt)
    if not PP.db or PP.db.harvestAlert == false then return end
    elapsed = elapsed + dt
    if elapsed < 0.2 then return end
    elapsed = 0
    PP:HarvestScan()
end)
-- Observe the visible tooltip, including world objects that have no regular unit token.
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    local types = Enum.TooltipDataType
    for _, key in ipairs({"Object", "Unit", "Item", "Spell"}) do
        local typ = types[key]
        local tooltipKind = key
        if typ then
            TooltipDataProcessor.AddTooltipPostCall(typ, function(tt, data)
                if tt ~= GameTooltip then return end
                tip = nil
                if tooltipKind == "Object" then tip = tooltipInfo(data, true)
                elseif tooltipKind == "Unit" and read(UnitIsDead, "mouseover") == true then tip = tooltipInfo(data, false) end
                PP:HarvestScan()
            end)
        end
    end
    if GameTooltip and GameTooltip.HookScript then
        GameTooltip:HookScript("OnHide", function() tip = nil; PP:HarvestScan() end)
    end
end

do -- Remember discovered herb/ore spots. Historical spots are never presented as live nodes.
    local names = {}
    local function nodeName(value)
        -- Only normalize readable text. Never inspect restricted tooltip values.
        value=text(value)
        if not value then return nil end
        value=value:gsub("|T.-|t",""):gsub("|A.-|a","")
            :gsub("|H.-|h(.-)|h","%1"):gsub("|cn[%w_]+:","")
            :gsub("\194\160"," "):gsub("\226\128\175"," ")
            :gsub("\226\128\139",""):gsub("\239\187\191","")
            :gsub("[%z\1-\8\11\12\14-\31\127]","")
        -- Elevation labels belong to the minimap blip, not the herb name.
        value=value:gsub("\226\150\178", ""):gsub("\226\150\188", "")
            :gsub("\226\134\145", ""):gsub("\226\134\147", "")
        value=value:match("^%s*(.-)%s*$")
        local base,level=value:match("^(.-)%s*%(([%a%s]+)%)$")
        if not base then base,level=value:match("^(.-)%s*%[([%a%s]+)%]$") end
        if level then
            level=level:lower():match("^%s*(.-)%s*$")
            if level=="above" or level=="below" or level=="higher" or level=="lower" then
                value=base:match("^%s*(.-)%s*$")
            end
        end
        return value
    end
    local nodeDebug = {enabled=false, entries={}}
    PP.harvestNodeDebug = nodeDebug
    local function trace(reason)
        if not nodeDebug.enabled or nodeDebug.last==reason then return end
        nodeDebug.last=reason
        local entries=nodeDebug.entries
        entries[#entries+1]=reason
        if #entries>12 then table.remove(entries,1) end
    end
    local function add(kind, list)
        for _, name in ipairs(list) do names[name:lower()] = kind end
    end
    add("mining", {"Copper Vein","Tin Vein","Silver Vein","Iron Deposit","Gold Vein","Mithril Deposit","Truesilver Deposit","Dark Iron Deposit","Small Thorium Vein","Rich Thorium Vein","Ooze Covered Silver Vein","Ooze Covered Gold Vein","Ooze Covered Mithril Deposit","Ooze Covered Truesilver Deposit","Ooze Covered Thorium Vein","Ooze Covered Rich Thorium Vein"})
    add("herbalism", {"Peacebloom","Silverleaf","Earthroot","Mageroyal","Briarthorn","Stranglekelp","Bruiseweed","Wild Steelbloom","Grave Moss","Kingsblood","Liferoot","Fadeleaf","Goldthorn","Khadgar's Whisker","Wintersbite","Firebloom","Purple Lotus","Arthas' Tears","Sungrass","Blindweed","Ghost Mushroom","Gromsblood","Golden Sansam","Dreamfoil","Mountain Silversage","Plaguebloom","Icecap","Black Lotus"})
    local arrow, title, detail, goal, lastSave, arrived = nil, nil, nil, nil, nil, nil
    local skipped = {} -- transient cooldowns for visited spots, not proof they are empty
    local tick, searchAt, lastLabel = 0, 0, nil
    local function numeric(v) return not hidden(v) and type(v) == "number" and v == v end
    local function position()
        if not C_Map or not C_Map.GetMapWorldSize then return nil end
        local map = read(C_Map.GetBestMapForUnit, "player")
        if not numeric(map) then return nil end
        local p = read(C_Map.GetPlayerMapPosition, map, "player")
        if not p or not p.GetXY then return nil end
        local ok, x, y = pcall(p.GetXY, p)
        if not ok or not numeric(x) or not numeric(y) or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
        local okw, w, h = pcall(C_Map.GetMapWorldSize, map)
        if not okw or not numeric(w) or not numeric(h) or w <= 0 or h <= 0 then return nil end
        return {map=map,x=x,y=y,w=w,h=h}
    end
    local function distance(p, node)
        return math.sqrt(((node.x-p.x)*p.w)^2+((node.y-p.y)*p.h)^2)
    end
    local function list(map)
        if not PP.db then return {} end
        if type(PP.db.harvestNodes) ~= "table" then PP.db.harvestNodes={} end
        local t = PP.db.harvestNodes[map]
        if type(t) ~= "table" then t={}; PP.db.harvestNodes[map]=t end
        return t
    end
    local function valid(n)
        return type(n)=="table" and (n.kind=="mining" or n.kind=="herbalism")
            and type(n.name)=="string" and numeric(n.x) and numeric(n.y)
            and n.x>=0 and n.x<=1 and n.y>=0 and n.y<=1
    end
    local function canUse(n)
        return valid(n) and skills[n.kind] and (not numeric(n.required) or skills[n.kind]>=n.required)
    end
    local function quiet()
        PP.harvestNavigation=nil
        if arrow then arrow:Hide() end
    end
    local function createArrow()
        if arrow then return end
        arrow=CreateFrame("Frame","ProfessionPalHarvestArrow",UIParent)
        PP.harvestArrow=arrow
        arrow:SetSize(300,90); arrow:SetFrameStrata("MEDIUM"); arrow:EnableMouse(false)
        arrow:SetPoint("CENTER",UIParent,"CENTER",0,110)
        arrow.pic=arrow:CreateTexture(nil,"ARTWORK"); arrow.pic:SetSize(38,38)
        arrow.pic:SetPoint("TOP",0,0)
        if arrow.pic.SetAtlas then arrow.pic:SetAtlas("MiniMap-QuestArrow")
        else arrow.pic:SetTexture("Interface\\Minimap\\MinimapArrow") end
        title=arrow:CreateFontString(nil,"OVERLAY"); title:SetFont(PP.TITLE_FONT,18,"OUTLINE")
        title:SetPoint("TOP",0,-42); title:SetWidth(300); title:SetWordWrap(false)
        detail=arrow:CreateFontString(nil,"OVERLAY"); detail:SetFont(PP.FONT,14,"OUTLINE")
        detail:SetPoint("TOP",0,-64); detail:SetWidth(300); detail:SetWordWrap(false)
        arrow:Hide()
    end
    function PP:HarvestRemember(state)
        if not self.db or not state or state.status~="ready" or (state.kind~="mining" and state.kind~="herbalism") or not state.name then return end
        names[state.name:lower()]=state.kind
        local p=position(); if not p then return end
        if lastSave and lastSave.map==p.map and lastSave.name==state.name and now()-lastSave.at<5 and distance(p,lastSave)<6 then return end
        lastSave={map=p.map,name=state.name,x=p.x,y=p.y,at=now()}
        local records=list(p.map)
        local found
        for _, n in ipairs(records) do
            if valid(n) and n.kind==state.kind and n.name==state.name and distance(p,n)<18 then found=n; break end
        end
        if not found then
            if #records>=300 then return end -- bounded history; no silent deletion of the user's spots
            found={kind=state.kind,name=state.name}; records[#records+1]=found
        end
        -- An in-reach player's position is within gathering distance of the node.
        -- This is deliberately labelled approximate, never a precise node coordinate.
        found.x,found.y,found.map=p.x,p.y,p.map
        found.source=nil -- close-range detection replaces the old minimap-only provenance
        found.required=state.required or found.required
        found.observedAt=read(time) or 0
        goal=found; skipped[found]=nil; arrived=nil; searchAt=0
    end
    local function minimapSpot()
        if not Minimap or read(Minimap.IsMouseOver,Minimap)~=true then return nil end
        local p=position(); if not p then return nil end
        local radius=C_Minimap and read(C_Minimap.GetViewRadius)
        local scale=read(Minimap.GetEffectiveScale,Minimap)
        local w,h=read(Minimap.GetWidth,Minimap),read(Minimap.GetHeight,Minimap)
        local ok,cx,cy=pcall(Minimap.GetCenter,Minimap)
        local okm,mx,my=pcall(GetCursorPosition)
        if not ok or not okm or not numeric(radius) or radius<=0 or not numeric(scale) or scale<=0
            or not numeric(w) or not numeric(h) or w<=0 or h<=0 or not numeric(cx) or not numeric(cy) or not numeric(mx) or not numeric(my) then return nil end
        local dx,dy=(mx/scale-cx)/(w/2),(my/scale-cy)/(h/2)
        if math.abs(dx)>1 or math.abs(dy)>1 then return nil end
        local rotate=read((C_CVar and C_CVar.GetCVar) or GetCVar,"rotateMinimap")
        if rotate~="0" and rotate~="1" then return nil end
        if C_Minimap and read(C_Minimap.IsRotateMinimapIgnored)==true then rotate="0" end
        local facing=0
        if rotate=="1" then facing=read(GetPlayerFacing); if not numeric(facing) then return nil end end
        local east=radius*(dx*math.cos(facing)-dy*math.sin(facing))
        local north=radius*(dx*math.sin(facing)+dy*math.cos(facing))
        local x,y=p.x+east/p.w,p.y-north/p.h
        if x<0 or x>1 or y<0 or y>1 then return nil end
        return {map=p.map,x=x,y=y,w=p.w,h=p.h,expires=now()+90,source="minimap"}
    end
    function PP:HarvestMinimapHint(data)
        if not self.db or self.db.harvestAlert==false or self.db.harvestGuide==false then trace("Node guide or harvest reminders are off"); return end
        if read(InCombatLockdown)==true then trace("Paused in combat"); return end
        if hidden(data) or type(data)~="table" or hidden(data.lines) or type(data.lines)~="table" then trace("Tooltip data unavailable"); return end
        if now()>=refreshAt then refreshSkills() end
        local p=minimapSpot(); if not p then trace("Minimap position unavailable: check hover, map, zoom and rotation"); return end
        local candidates, seen, missing, unknown = {}, {}, nil, nil
        for _, l in ipairs(data.lines) do
            if not hidden(l) and type(l)=="table" then
                local value=text(l.leftText)
                if value then
                    -- Stacked minimap blips can share one multiline tooltip field.
                    for line in value:gmatch("[^\r\n]+") do
                        local name=nodeName(line)
                        local kind=names[name:lower()]
                        if kind and skills[kind] then
                            local person=false
                            for _,u in ipairs({"player","party1","party2","party3","party4","pet"}) do
                                if read(UnitName,u)==name then person=true; break end
                            end
                            if not person and not seen[name] then
                                seen[name]=true; candidates[#candidates+1]={name=name,kind=kind}
                            end
                        elseif kind then missing=kind
                        elseif name~="" then
                            unknown=name
                            if nodeDebug.enabled then
                                local bytes={}
                                for i=1,math.min(#line,80) do bytes[#bytes+1]=string.format("%02X",line:byte(i)) end
                                nodeDebug.rawUnknown=table.concat(bytes," ")
                            end
                        end
                    end
                end
            end
        end
        if #candidates==0 then
            trace(missing and ("Profession not learned: "..missing)
                or unknown and ("Unrecognized tooltip: "..unknown) or "No readable node name")
            return
        end
        table.sort(candidates,function(a,b) return a.name<b.name end)
        local chosen=candidates[1]
        -- Keep the same herb while its name remains in a stacked tooltip.
        if goal and goal.source=="minimap" and goal.map==p.map then
            for _,candidate in ipairs(candidates) do
                if candidate.name==goal.name then chosen=candidate; break end
            end
        end
        p.name,p.kind=chosen.name,chosen.kind
        -- A hover is a historical sighting, never proof a node is still present.
        local records=list(p.map)
        local found
        for _,n in ipairs(records) do
            if valid(n) and n.name==p.name and distance(p,n)<18 then found=n; break end
        end
        if not found and #records<300 then
            found={name=p.name,kind=p.kind,map=p.map,x=p.x,y=p.y,source="minimap"}
            records[#records+1]=found
        end
        if found then found.observedAt=read(time) or 0 end
        if not goal or goal.name~=p.name or distance(p,goal)>18 then arrived=nil end
        goal=p
        trace("Tracking "..p.name.." (approximate minimap position)")
        self:HarvestGuideUpdate()
    end
    function PP:HarvestGuideUpdate()
        if not self.db or self.db.harvestAlert==false or self.db.harvestGuide==false or read(InCombatLockdown)==true or read(UnitIsDeadOrGhost,"player")==true then quiet(); return end
        createArrow()
        local p=position(); if not p then quiet(); return end
        if goal and (goal.map~=p.map or not canUse(goal) or (goal.expires and now()>goal.expires) or (skipped[goal] and now()<skipped[goal])) then goal=nil; arrived=nil end
        if not goal and now()>=searchAt then
            searchAt=now()+1
            local best=150 -- automatic reminders for previously discovered spots within 150 yards
            for _,n in ipairs(list(p.map)) do
                if canUse(n) and (not skipped[n] or now()>skipped[n]) then
                    local d=distance(p,n)
                    if d<best then goal=n; best=d end
                end
            end
        end
        if not goal then quiet(); return end
        local d=distance(p,goal)
        if not goal.expires and d>180 then goal=nil; quiet(); return end
        local live=PP.harvestState
        local detected=live and d<=25 and live.kind==goal.kind and live.name==goal.name
        if d<=10 and not detected then
            arrived=arrived or now()
            if now()-arrived>3 then
                skipped[goal]=now()+600
                for _,n in ipairs(list(p.map)) do
                    if valid(n) and distance(p,n)<=18 then skipped[n]=now()+600 end
                end
                goal=nil; arrived=nil; quiet(); return
            end
        else arrived=nil end
        local label=(detected and "" or goal.source=="minimap" and "Last seen: " or "Possible: ")..goal.name
        local status=detected and "Detected nearby" or d<=10 and "Search nearby - not confirmed"
            or ("~"..math.floor(d+0.5).." yd - "..(goal.source=="minimap" and "minimap sighting" or "saved spot"))
        if not self.db.harvestGuideDetails then
            label=goal.name
            status=detected and "Nearby" or d<=10 and "Check nearby" or ("~"..math.floor(d+0.5).." yd")
        end
        local key=label..status
        if key~=lastLabel then title:SetText(label); detail:SetText(status); lastLabel=key end
        title:SetTextColor(unpack(detected and live.status=="ready" and PP.C.green or PP.C.gold))
        local f=read(GetPlayerFacing)
        if numeric(f) and d>10 then
            local east,north=(goal.x-p.x)*p.w,(p.y-goal.y)*p.h
            local bearing=math.atan2(east,north)
            arrow.pic:SetRotation(-(bearing+f)); arrow.pic:Show()
        else arrow.pic:Hide() end
        arrow.pic:SetSize(self.db.harvestGuideDetails and 38 or 26,self.db.harvestGuideDetails and 38 or 26)
        title:ClearAllPoints(); title:SetPoint("TOP",0,self.db.harvestGuideDetails and -42 or -29)
        detail:ClearAllPoints(); detail:SetPoint("TOP",0,self.db.harvestGuideDetails and -64 or -49)
        arrow:Show()
        PP.harvestNavigation={name=goal.name,kind=goal.kind,source=detected and "live" or goal.source or "history",distance=d,confirmed=detected and true or false,x=goal.x,y=goal.y,map=goal.map}
    end
    function PP:HarvestGuideCommand(arg)
        if arg=="debug on" then nodeDebug.enabled=true; nodeDebug.last=nil; self:Print("Node debug on. Hover the node, then /prof harvest debug.")
        elseif arg=="debug off" then nodeDebug.enabled=false; self:Print("Node debug off.")
        elseif arg=="debug" then
            self:Print("Node debug: "..(nodeDebug.enabled and "on" or "off").."; reminders="..tostring(self.db.harvestAlert).."; guide="..tostring(self.db.harvestGuide))
            for _,line in ipairs(nodeDebug.entries) do self:Print(line) end
            if nodeDebug.rawUnknown then self:Print("Last unknown tooltip bytes: "..nodeDebug.rawUnknown) end
        elseif arg=="guide off" then self.db.harvestGuide=false; quiet(); self:Print("Saved-node guidance off.")
        elseif arg=="guide on" then self.db.harvestGuide=true; searchAt=0; self:HarvestGuideUpdate(); self:Print("Saved-node guidance on.")
        elseif arg=="skip" then if goal then skipped[goal]=now()+120 end; goal=nil; arrived=nil; quiet(); self:Print("Skipping this spot for two minutes.")
        elseif arg=="markers off" then self.db.harvestMarkers=false; self:HarvestPinsUpdate(); self:Print("Saved node markers off.")
        elseif arg=="markers on" then self.db.harvestMarkers=true; self:HarvestPinsUpdate(); self:Print("Saved node markers on.")
        elseif arg=="map" then
            local p=position(); local count=p and #list(p.map) or 0
            self:Print(count.." saved herb/ore spots in this zone. Hover a new minimap node to guide toward it; reaching a detected node saves the spot.")
        else return false end
        return true
    end

    -- Historical markers are separate from the navigation goal and its expiry.
    local mapPins, miniPins = {}, {}
    PP.harvestMapPins,PP.harvestMiniPins=mapPins,miniPins
    local function pin(pool,index,parent,node)
        local f=pool[index]
        if not f then
            f=CreateFrame("Frame",nil,parent); f:SetSize(9,9); f:EnableMouse(false)
            f.pic=f:CreateTexture(nil,"OVERLAY"); f.pic:SetAllPoints()
            f.pic:SetTexture("Interface\\COMMON\\Indicator-Yellow")
            pool[index]=f
        end
        f:SetParent(parent)
        if node.kind=="herbalism" then f.pic:SetVertexColor(0.3,1,0.45,0.85)
        else f.pic:SetVertexColor(1,0.7,0.2,0.85) end
        f:ClearAllPoints(); f:Show(); return f
    end
    function PP:HarvestPinsUpdate()
        for _,f in ipairs(mapPins) do f:Hide() end
        for _,f in ipairs(miniPins) do f:Hide() end
        if not self.db or self.db.harvestMarkers==false then return end
        if now()>=refreshAt then refreshSkills() end
        local map=WorldMapFrame
        local canvas=map and map.GetCanvas and read(map.GetCanvas,map)
        local id=map and map.GetMapID and read(map.GetMapID,map)
        if canvas and numeric(id) and read(map.IsShown,map)==true then
            local w,h=read(canvas.GetWidth,canvas),read(canvas.GetHeight,canvas)
            if numeric(w) and numeric(h) and w>0 and h>0 then
                local index=0
                for _,n in ipairs(list(id)) do
                    if valid(n) and skills[n.kind] then
                        index=index+1
                        pin(mapPins,index,canvas,n):SetPoint("CENTER",canvas,"TOPLEFT",n.x*w,-n.y*h)
                    end
                end
            end
        end
        local p=position()
        if not p or not Minimap or read(Minimap.IsShown,Minimap)~=true then return end
        local radius=C_Minimap and read(C_Minimap.GetViewRadius)
        local w,h=read(Minimap.GetWidth,Minimap),read(Minimap.GetHeight,Minimap)
        if not numeric(radius) or radius<=0 or not numeric(w) or not numeric(h) or w<=0 or h<=0 then return end
        local rotate=read((C_CVar and C_CVar.GetCVar) or GetCVar,"rotateMinimap")
        if C_Minimap and read(C_Minimap.IsRotateMinimapIgnored)==true then rotate="0" end
        if rotate~="0" and rotate~="1" then return end
        local facing=rotate=="1" and read(GetPlayerFacing) or 0
        if not numeric(facing) then return end
        local index=0
        for _,n in ipairs(list(p.map)) do
            if valid(n) and skills[n.kind] then
                local east,north=(n.x-p.x)*p.w,(p.y-n.y)*p.h
                local dx=(east*math.cos(facing)+north*math.sin(facing))/radius
                local dy=(-east*math.sin(facing)+north*math.cos(facing))/radius
                -- Keep the entire marker inside a round minimap, including its border.
                if dx*dx+dy*dy<0.88*0.88 then
                    index=index+1
                    pin(miniPins,index,Minimap,n):SetPoint("CENTER",Minimap,"CENTER",dx*w/2,dy*h/2)
                end
            end
        end
    end
    local pinsDriver=CreateFrame("Frame")
    local pinsTick=0
    pinsDriver:SetScript("OnUpdate",function(_,dt)
        pinsTick=pinsTick+dt
        if pinsTick<0.25 then return end
        pinsTick=0; PP:HarvestPinsUpdate()
    end)
    local events=CreateFrame("Frame")
    for _,e in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","LOOT_CLOSED"}) do pcall(events.RegisterEvent,events,e) end
    events:SetScript("OnEvent",function(_,e)
        if not PP.db then return end
        if e=="PLAYER_LOGIN" then
            if PP.db.harvestGuide==nil then PP.db.harvestGuide=false end
            for _,records in pairs(type(PP.db.harvestNodes)=="table" and PP.db.harvestNodes or {}) do
                if type(records)=="table" then for _,n in ipairs(records) do if valid(n) then names[n.name:lower()]=n.kind end end end
            end
        else
            if e=="LOOT_CLOSED" then
                local p=position()
                if goal and p and goal.map==p.map and distance(p,goal)<15 then skipped[goal]=now()+120; goal=nil end
            else goal=nil; arrived=nil; searchAt=0; skipped={} end
        end
        PP:HarvestGuideUpdate()
    end)
    events:SetScript("OnUpdate",function(_,dt)
        if not PP.db or PP.db.harvestGuide==false or PP.db.harvestAlert==false then return end
        tick=tick+dt; if tick<0.2 then return end; tick=0
        -- Some minimap tooltip updates do not fire the data callback again.
        -- Read only the visible tooltip while the pointer is over the minimap.
        if Minimap and read(Minimap.IsMouseOver,Minimap)==true and GameTooltip and read(GameTooltip.IsShown,GameTooltip)==true then
            local data=C_TooltipInfo and read(C_TooltipInfo.GetMinimapMouseover)
            if data then PP:HarvestMinimapHint(data) end
            local lines={}
            for i=1,math.min(read(GameTooltip.NumLines,GameTooltip) or 0,12) do
                local region=_G["GameTooltipTextLeft"..i]
                local value=region and text(read(region.GetText,region))
                if value then lines[#lines+1]={leftText=value} end
            end
            if not data and #lines>0 then PP:HarvestMinimapHint({lines=lines}) end
        end
        PP:HarvestGuideUpdate()
    end)
    local typ=Enum and Enum.TooltipDataType and Enum.TooltipDataType.MinimapMouseover
    if typ and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(typ,function(tt,data)
            if tt==GameTooltip then PP:HarvestMinimapHint(data) end
        end)
    end
end
