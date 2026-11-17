-- Optional Farm Planner diagnostics. No chat, character name or account data collected.
local _, PP = ...
local entries, enabled, previous, handler = {}, false
local function value(v)
    if issecretvalue and issecretvalue(v) then return "<restricted>" end
    if type(v) == "string" then return v:sub(1, 1200) end
    if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
    return v == nil and "nil" or "<" .. type(v) .. ">"
end
function PP:FarmDebugLog(kind, message)
    if not enabled then return end
    entries[#entries + 1] = kind .. ": " .. value(message)
    if #entries > 30 then table.remove(entries, 1) end
end
local function packed(...) return { n = select("#", ...), ... } end
local function query(fn, ...)
    if type(fn) ~= "function" then return "unavailable" end
    local result = packed(pcall(fn, ...))
    local out = {}
    for i = 1, result.n do out[#out + 1] = value(result[i]) end
    return table.concat(out, " | ")
end
function PP:FarmDebugReport()
    local version = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local out = { "ProfessionPal diagnostic report", "Version: " .. query(version, "ProfessionPal", "Version"),
        "Build: " .. query(GetBuildInfo), "Faction: " .. value(self:Faction()),
        "Current map: " .. query(self.CurrentMap, self), "Capture: " .. tostring(enabled),
        "ShortestPathForever: " .. query(version, "ShortestPathForever", "Version"),
        "GetProfessions: " .. query(GetProfessions) }
    if GetProfessions and GetProfessionInfo then
        local indexes = { pcall(GetProfessions) }
        for i = 2, 7 do
            local idx = indexes[i]
            if type(idx) == "number" then out[#out+1] = "Profession API: " .. query(GetProfessionInfo, idx) end
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        local ok, count = pcall(GetNumSkillLines)
        if ok and type(count) == "number" then
            for i = 1, math.min(count, 300) do
                local good, name = pcall(GetSkillLineInfo, i)
                if good then
                    for _, def in ipairs(self.professions or {}) do
                        if name == def.name then out[#out+1] = "Classic skill API: " .. query(GetSkillLineInfo, i) end
                    end
                end
            end
        end
    end
    for _, def in ipairs(self.professions or {}) do
        out[#out+1] = def.key .. ": " .. query(self.GetSkill, self, def)
        if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
            local ok, info = pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID, def.skillLine)
            if ok and type(info) == "table" then
                out[#out+1] = "Trade API: " .. value(info.professionName) .. " skill=" .. value(info.skillLevel) .. " max=" .. value(info.maxSkillLevel)
            end
        end
    end
    local target = self.db and self.db.guideTarget
    if target then
        for _, key in ipairs({ "m", "x", "y", "title", "what", "skinning", "areaOnly", "routed", "retry", "paused", "note" }) do
            out[#out+1] = "Target " .. key .. ": " .. value(target[key])
        end
        out[#out+1] = "Node groups: " .. table.concat(target.groups or {}, ", ")
    else out[#out+1] = "No active farming destination" end
    out[#out+1] = "Recent events/errors:"
    for _, line in ipairs(entries) do out[#out+1] = line end
    return table.concat(out, "\n")
end
local window
function PP:ShowFarmText(title, text)
    if not window then
        window = self.UIWindow("ProfessionPalFarmReport", 680, title)
        window:SetHeight(470)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
        if type(sw) == "number" and type(sh) == "number" and sw > 0 and sh > 0 then window:SetScale(math.min(1, sw / 720, sh / 510)) end
        local help = self.UIText(window, 13, self.C.gray)
        help:SetPoint("TOPLEFT", 20, -48)
        help:SetText("Click the text, then Ctrl+A and Ctrl+C to copy. Escape releases the text cursor.")
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -78)
        scroll:SetPoint("BOTTOMRIGHT", -40, 20)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetMaxLetters(0)
        edit:SetFont(self.FONT, 14, ""); edit:SetTextColor(1, 1, 1)
        edit:SetWidth(600); edit:SetHeight(360)
        edit:SetScript("OnEscapePressed", function(e) e:ClearFocus() end)
        scroll:SetScrollChild(edit)
        window.edit, window.scroll = edit, scroll
    end
    window.title:SetText(title)
    window.edit:SetText(text)
    window.scroll:SetVerticalScroll(0)
    window:Show()
end
function PP:FarmDebugCommand(arg)
    if arg == "off" then
        enabled = false
        if handler and geterrorhandler and geterrorhandler() == handler then seterrorhandler(previous) end
        handler, previous = nil, nil
        self:Print("Debug capture off.")
        return
    end
    if arg == "clear" then entries = {} end
    if arg == "on" or arg == "" or arg == nil then
        enabled = true
        if not handler and geterrorhandler and seterrorhandler then
            previous = geterrorhandler()
            local nextHandler = previous
            handler = function(err)
                if type(err) == "string" and err:find("ProfessionPal", 1, true) then
                    PP:FarmDebugLog("Lua error", err)
                end
                if nextHandler then return nextHandler(err) end
            end
            seterrorhandler(handler)
        end
        self:Print("Debug capture on. Reproduce the problem, then /prof debug report to copy it. /prof debug off stops capture.")
    end
    self:ShowFarmText("ProfessionPal debug report", self:FarmDebugReport())
end
