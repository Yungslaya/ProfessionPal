--[[ ProfessionPal - Auto-learn at the trainer (OPTION, OFF by default)
  Only works while YOU have a trainer window open. It learns:
    - the next profession rank (Journeyman, Expert, ...)
    - recipes the guide uses, and trainer recipes for your gear picks
  It never spends more than your limit (Settings, gold per trainer visit).
  Same kind of thing as auto-repair addons: it only uses the open trainer window.
  NOT VERIFIED in Forever: trainer API names (GetTrainerServiceInfo etc.).
]]

local _, PP = ...
local safe = PP.safe

local function pack(...) return { n = select("#", ...), ... } end

local function Money(c)
    c = math.floor(c or 0)
    local g, s, cp = math.floor(c / 10000), math.floor((c % 10000) / 100), c % 100
    local t = {}
    if g > 0 then t[#t + 1] = g .. "g" end
    if s > 0 then t[#t + 1] = s .. "s" end
    if cp > 0 or #t == 0 then t[#t + 1] = cp .. "c" end
    return table.concat(t, " ")
end
PP.MoneyText = Money

local RANK_WORDS = { apprentice = true, journeyman = true, expert = true, artisan = true }

-- Names of things worth learning (lower case)
function PP:WantedServices()
    local want, profs = {}, {}
    for _, def in ipairs(self.professions) do
        local skill = self:GetSkill(def)
        if skill then
            profs[#profs + 1] = def.name:lower()
            for _, st in ipairs(def.steps or {}) do want[st.text:lower()] = true end
            if def.altSteps then
                for _, st in ipairs(def.altSteps.steps) do want[st.text:lower()] = true end
            end
            for _, name in ipairs(def.learn or {}) do want[name:lower()] = true end
            for _, sp in ipairs(def.spells or {}) do want[sp.name:lower()] = true end
            if self.GearBySlot then
                for _, row in ipairs(self:GearBySlot(def, skill)) do
                    if row.now and row.now.it.src == "T" then want[row.now.it.name:lower()] = true end
                    if row.next and row.next.it.src == "T" then want[row.next.it.name:lower()] = true end
                end
            end
        end
    end
    return want, profs
end

local function IsRank(name, sub, profs)
    local n, s = (name or ""):lower(), (sub or ""):lower()
    for _, p in ipairs(profs) do
        if n == p or n:find(p, 1, true) then
            if n == p or RANK_WORDS[s] then return true end
            for w in pairs(RANK_WORDS) do if n:find(w, 1, true) then return true end end
        end
    end
    return false
end

local state = { open = false, busy = false, spent = 0, tried = {}, warned = false, bought = 0 }

local function Scan()
    if not (PP.db and PP.db.autoLearn and state.open) or state.busy then return end
    if not (GetNumTrainerServices and GetTrainerServiceInfo and BuyTrainerService) then return end
    if PP.InCombat and PP:InCombat() then return end
    local n = safe(GetNumTrainerServices) or 0
    if type(n) ~= "number" then return end
    local want, profs = PP:WantedServices()
    local cap = (PP.db.autoLearnMax or 10) * 10000
    for i = 1, n do
        local info = pack(safe(GetTrainerServiceInfo, i))
        local name, sub, typ = info[1], info[2], info[3]
        if typ == "available" and type(name) == "string" then
            local key = name .. "|" .. tostring(sub)
            local lname = name:lower()
            if not state.tried[key] and (want[lname] or IsRank(name, sub, profs)) then
                local cost = safe(GetTrainerServiceCost, i) or 0
                if type(cost) ~= "number" then cost = 0 end
                local money = safe(GetMoney) or 0
                if state.spent + cost > cap then
                    -- over your limit: skip this one, keep going with cheaper ones
                    state.tried[key] = true
                    PP:Print("Skipped " .. name .. " (" .. Money(cost) .. "): over your " .. Money(cap) .. " limit.")
                elseif type(money) == "number" and money < cost then
                    state.tried[key] = true
                    PP:Print("Not enough gold to learn " .. name .. " (" .. Money(cost) .. ").")
                else
                state.tried[key] = true
                state.busy = true
                if pcall(BuyTrainerService, i) then
                    state.spent = state.spent + cost
                    state.bought = state.bought + 1
                    PP:Print("Learned: " .. name .. ((sub and sub ~= "") and (" (" .. sub .. ")") or "") .. "  -  " .. Money(cost))
                end
                -- wait for the trainer list to refresh, then look again
                local function again() state.busy = false; Scan() end
                if C_Timer and C_Timer.After and state.bought < 40 then C_Timer.After(0.4, again) else state.busy = false end
                return
                end
            end
        end
    end
end
PP.AutoLearnScan = Scan

local ev = CreateFrame("Frame")
for _, e in ipairs({ "TRAINER_SHOW", "TRAINER_UPDATE", "TRAINER_CLOSED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, e)
    if e == "TRAINER_SHOW" then
        state.open, state.busy, state.spent, state.tried, state.warned, state.bought = true, false, 0, {}, false, 0
        if PP.db and PP.db.autoLearn then
            if SetTrainerServiceTypeFilter then pcall(SetTrainerServiceTypeFilter, "available", 1) end
            if C_Timer and C_Timer.After then C_Timer.After(0.3, Scan) else Scan() end
        end
    elseif e == "TRAINER_UPDATE" then
        if not state.busy and C_Timer and C_Timer.After then C_Timer.After(0.2, Scan) end
    elseif e == "TRAINER_CLOSED" then
        state.open = false
    end
end)
