--[[ ProfessionPal - Market Ledger   (/ppauction)
  Looks at your bags and tells you what to auction, vendor, craft or keep.

  Layout of this file:
    1. Helpers      safe API reads, saved prices, item info
    2. Selling      fill the Auction House sell form, sell to a vendor, craft
    3. Plan tab     the to-do list an AI wrote for you (LedgerPlan.lua)
    4. Ledger       turns bags + prices into rows and the AI report
    5. Price scan   one throttled Auction House search per item
    6. AI Help      walks you through scan -> save -> ask the AI -> plan
    7. Window and events

  Rules it keeps: every auction, vendor sale and craft needs its own click from you.
  Nothing is posted, sold or bought on a timer. The AI hand-off is a file on your PC
  (SavedVariables out, LedgerPlan.lua in). The game never talks to a website.
]]

local _, PP = ...
local floor, min, max = math.floor, math.min, math.max
local ah = C_AuctionHouse
local ui = C_TradeSkillUI
local now = time or os.time

-- ---------- 1. Helpers ----------

-- Call a game function safely. Returns nil on an error or a hidden ("secret") value.
local function read(fn, ...)
    if not fn then return end
    local ok, value = pcall(fn, ...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end

local function charKey() return UnitName("player") .. "-" .. GetRealmName() end

local function clampPercent(value) return max(0, min(100, floor(tonumber(value) or 50))) end

local function savedPrices()
    PP.db.ledgerPrices = PP.db.ledgerPrices or {}
    local key = GetRealmName() .. ":" .. UnitFactionGroup("player")
    PP.db.ledgerPrices[key] = PP.db.ledgerPrices[key] or {}
    return PP.db.ledgerPrices[key]
end

local function blacklist()
    PP.db.ledgerBlacklist = PP.db.ledgerBlacklist or {}
    return PP.db.ledgerBlacklist
end

-- Items the next price scan should look up: signature -> Auction House item key.
local wanted = {}

-- Saved price of an item (link or ID). Returns what you keep after the 5% cut, then the listed price.
local function price(link)
    local id = type(link) == "number" and link or tonumber(link:match("item:(%d+)"))
    if not id or not ah or blacklist()[id] then return end
    local key = (type(link) == "string" and read(ah.GetItemKeyFromItemLink, link)) or read(ah.MakeItemKey, id)
    if not key then return end
    local signature = table.concat({key.itemID, key.itemLevel or 0, key.itemSuffix or 0, key.battlePetSpeciesID or 0}, ":")
    wanted[signature] = key
    local listed = savedPrices()[signature]
    if listed then return floor(listed * 0.95), listed end
end

-- GetItemInfo returns the name first and the vendor price eleventh.
local function nameAndVendor(ok, name, _, _, _, _, _, _, _, _, _, vendor)
    if not ok then return end
    if issecretvalue and (issecretvalue(name) or issecretvalue(vendor)) then return end
    return name, vendor
end

local function itemDetails(link)
    local lookup = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if lookup then return nameAndVendor(pcall(lookup, link)) end
end

local function money(value)
    if value == nil then return "—" end
    return ("%dg %02ds %02dc"):format(floor(value / 10000), floor(value / 100) % 100, value % 100)
end

local function ago(when)
    local seconds = max(0, now() - when)
    if seconds < 90 then return "just now" end
    if seconds < 5400 then return ("%d min ago"):format(floor(seconds / 60 + 0.5)) end
    if seconds < 172800 then return ("%d hours ago"):format(floor(seconds / 3600 + 0.5)) end
    return ("%d days ago"):format(floor(seconds / 86400 + 0.5))
end

-- Quest items are never offered. When the game hides the answer, play safe and treat it as one.
local function isQuestItem(bag, slot)
    local lookup = C_Container.GetContainerItemQuestInfo or GetContainerItemQuestInfo
    if not lookup then return false end
    local ok, info, _, active = pcall(lookup, bag, slot)
    if not ok then return false end
    if issecretvalue and issecretvalue(info) then return true end
    if type(info) == "table" then
        if issecrettable and issecrettable(info) then return true end
        local questItem, isActive = info.isQuestItem, info.isActive
        if issecretvalue and (issecretvalue(questItem) or issecretvalue(isActive)) then return true end
        return questItem == true or isActive == true
    end
    if issecretvalue and issecretvalue(active) then return true end
    return info == true or active == true
end

-- Calls fn(bag, slot, item) for every filled bag slot. Stops early when fn returns true.
local function eachBagItem(fn)
    for bag = 0, NUM_BAG_SLOTS + (NUM_REAGENTBAG_SLOTS or 0) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = read(C_Container.GetContainerItemInfo, bag, slot)
            if item and fn(bag, slot, item) then return true end
        end
    end
end

-- Output link and schematic of a recipe. Recipes never change, so each is looked up once per session.
local recipeCache = {}
local function recipeData(id)
    local data = recipeCache[id]
    if not data then
        data = { output = read(ui and ui.GetRecipeItemLink, id), schematic = read(ui and ui.GetRecipeSchematic, id, false) }
        if type(data.output) == "string" and type(data.schematic) == "table" then recipeCache[id] = data end
    end
    return data.output, data.schematic
end

local function professionKey(recipeID)
    local info = read(ui and ui.GetProfessionInfoByRecipeID, recipeID)
    if not info then return end
    for _, def in ipairs(PP.professions) do
        if def.skillLine == info.professionID or def.skillLine == info.skillLineID then return def.key end
    end
end

-- ---------- shared state ----------

local panel, refresh
local open, merchant            -- Auction House / vendor window is open
local page = "Auction"          -- selected tab
local adviceReport              -- latest report text for the AI
local unsaved = false           -- a scan finished this session and is not on disk yet

local function setStatus(text) panel.status:SetText(text) end

-- ---------- 2. Selling ----------

local prepareRequest = 0
local preparedRow, submitPrepared
local prepareLog = {}
local function trace(message)
    prepareLog[#prepareLog + 1] = message
    if #prepareLog > 16 then table.remove(prepareLog, 1) end
end

SLASH_PROFESSIONPALLEDGERDEBUG1 = "/ppauctiondebug"
SlashCmdList.PROFESSIONPALLEDGERDEBUG = function()
    if #prepareLog == 0 then PP:Print("Click Prepare first."); return end
    for _, message in ipairs(prepareLog) do PP:Print(message) end
end

local function isPrepared(entry)
    return preparedRow ~= nil and entry.link == preparedRow.link
        and entry.qty == preparedRow.qty and entry.listed == preparedRow.listed
end

local function clearPrepared()
    if preparedRow then preparedRow.button = "Prepare" end
    preparedRow, submitPrepared = nil, nil
end

-- Sets the button label on every visible row for this item.
local function labelRows(link, text)
    for _, card in ipairs(panel.cards) do
        if card.entry and card.entry.link == link then card.button:SetText(text) end
    end
end

-- First bag stack of this item that the Auction House will accept.
local function findAuctionStack(link)
    local foundBag, foundSlot, foundItem, foundLocation
    eachBagItem(function(bag, slot, item)
        if item.hyperlink ~= link or item.isBound or item.isLocked or isQuestItem(bag, slot) then return end
        local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
        if read(ah.IsSellItemValid, location) == false then return end
        foundBag, foundSlot, foundItem, foundLocation = bag, slot, item, location
        return true
    end)
    return foundBag, foundSlot, foundItem, foundLocation
end

-- Step 1 of an auction: put the item, amount and price into WoW's own sell form.
-- Step 2 (a second click) presses WoW's Create Auction button. Nothing is posted without that click.
local function prepare(row)
    clearPrepared()
    prepareRequest = prepareRequest + 1
    local request = prepareRequest
    trace(("Prepare #%d: quantity %s, unit price %s"):format(request, tostring(row.qty), tostring(row.listed)))
    if not open or PP:InCombat() then trace("Auction House closed or player in combat."); return end
    local frame = AuctionHouseFrame
    if not frame or not frame.SetPostItem then
        trace("Sell form unavailable.")
        setStatus("Drag this item to the Sell tab.")
        return
    end
    local bag, slot, item, location = findAuctionStack(row.link)
    if not bag then
        trace("No eligible bag stack matched the recommendation.")
        setStatus("Could not find an eligible stack. Scan Bags again.")
        return
    end

    -- The sell form (commodity or item) that currently holds our stack.
    local function selectedForm()
        for _, field in ipairs({"CommoditiesSellFrame", "ItemSellFrame"}) do
            local sell = frame[field]
            local selected = sell and sell:IsShown() and read(sell.GetItem, sell)
            if selected then
                local ok, selectedBag, selectedSlot = pcall(selected.GetBagAndSlot, selected)
                if (ok and selectedBag == bag and selectedSlot == slot)
                    or read(C_Item.GetItemLink, selected) == row.link then
                    return sell, field
                end
            end
        end
    end
    if not selectedForm() then
        local ok, err = pcall(frame.SetPostItem, frame, location)
        if not ok then trace("SetPostItem failed: " .. tostring(err)) end
    end
    local quantity = min(row.qty, item.stackCount)

    -- Second click: check the form still says what we set, then press WoW's post button.
    local function post(sell, field)
        local button = sell.PostButton
        local input = sell.QuantityInput and sell.QuantityInput.InputBox
        if input and input:HasFocus() then input:ClearFocus() end
        if not open or PP:InCombat() or selectedForm() ~= sell
            or not button:IsVisible()
            or read(sell.GetQuantity, sell) ~= quantity
            or read(sell.PriceInput.GetAmount, sell.PriceInput) ~= row.listed then
            trace("Sell form changed. Prepare the listing again.")
            setStatus("Sell form changed. Click Prepare again.")
            preparedRow, submitPrepared = nil, nil
            refresh()
            return
        end
        if field == "CommoditiesSellFrame" and sell.GetPostDetails then
            local ok, _, _, postQuantity, postPrice = pcall(sell.GetPostDetails, sell)
            trace(("WoW post details: quantity %s, unit price %s"):format(tostring(postQuantity), tostring(postPrice)))
            if not ok or postQuantity ~= quantity or postPrice ~= row.listed then
                setStatus("WoW changed the listing. Check quantity and unit price in Sell.")
                return
            end
        end
        if not button:IsEnabled() then
            trace("WoW posting button disabled.")
            setStatus("WoW is not ready to post. Check the Sell form.")
            return
        end
        preparedRow, submitPrepared = nil, nil
        row.button = "Prepare"
        labelRows(row.link, row.button)
        local posted, err = pcall(button.Click, button)
        trace(posted and ("Create Auction clicked for " .. quantity .. " at " .. row.listed .. " each.")
            or ("Post button error: " .. tostring(err)))
        setStatus(posted and "Check WoW for the auction result." or "Click Create Auction in WoW.")
    end

    -- Returns true when the form shows our amount and price, false to try again, nil when cancelled.
    local function fill()
        if not open or request ~= prepareRequest or PP:InCombat() then return end
        local sell, field = selectedForm()
        if not sell then trace("Sell form has not selected the requested item."); return false end
        local ok, err = pcall(function()
            sell.QuantityInput:SetQuantity(quantity)
            sell.PriceInput:SetAmount(row.listed)
        end)
        if not ok then trace(field .. " input error: " .. tostring(err)); return false end
        local actualQty = read(sell.GetQuantity, sell) or read(sell.QuantityInput.GetQuantity, sell.QuantityInput)
        local actualPrice = read(sell.PriceInput.GetAmount, sell.PriceInput)
        trace(("%s readback: quantity %s, price %s"):format(field, tostring(actualQty), tostring(actualPrice)))
        if actualQty ~= quantity or actualPrice ~= row.listed then return false end
        if sell.PostButton then
            preparedRow = row
            row.button = "Create Auction"
            labelRows(row.link, row.button)
            submitPrepared = function() post(sell, field) end
        end
        setStatus("Review quantity, price and deposit before posting.")
        return true
    end

    if fill() == false then
        C_Timer.After(0.2, function()
            if fill() == false then
                setStatus(("Enter %d at %s each. See /ppauctiondebug."):format(quantity, money(row.listed)))
            end
        end)
    end
end

-- One click sells one stack. A stack bigger than the plan is split first, then sold on the next click.
local function sellToVendor(entry)
    if not merchant or not MerchantFrame or not MerchantFrame:IsShown() or PP:InCombat() then
        setStatus("Open a vendor to sell this item.")
        return
    end
    local splitBag, splitSlot
    local handled = eachBagItem(function(bag, slot, item)
        if item.hyperlink ~= entry.link or (item.isBound == true) ~= entry.bound or item.isLocked
            or isQuestItem(bag, slot) then return end
        local _, vendor = itemDetails(item.hyperlink)
        if item.hasNoValue or type(vendor) ~= "number" or vendor <= 0 then
            setStatus("This item has no vendor value.")
            return true
        end
        if item.stackCount > entry.qty then
            splitBag, splitSlot = bag, slot
            return
        end
        local ok = pcall(C_Container.UseContainerItem, bag, slot)
        setStatus(ok and "Sale requested. Check Buyback to verify."
            or "WoW blocked the sale. Right-click the stack in your bags.")
        return true
    end)
    if handled then return end
    if splitBag and entry.qty > 0 and GetCursorInfo and not GetCursorInfo() then
        for slot = 1, C_Container.GetContainerNumSlots(0) do
            if not read(C_Container.GetContainerItemInfo, 0, slot) then
                local ok = pcall(C_Container.SplitContainerItem, splitBag, splitSlot, entry.qty)
                if ok and GetCursorInfo() == "item" then
                    pcall(C_Container.PickupContainerItem, 0, slot)
                    if not GetCursorInfo() then
                        setStatus("Stack split. Click Sell again to sell " .. entry.qty .. ".")
                    else
                        setStatus("Place the split stack in your bags, then click Sell again.")
                    end
                    return
                end
                break
            end
        end
    end
    setStatus("Split off " .. entry.qty .. " or fewer before selling.")
end

local function craftMaterials(entry)
    if not panel.materials then
        local f = PP.UIWindow("ProfessionPalLedgerMaterials", 360, "Craft materials")
        f:SetPoint("CENTER", UIParent, "CENTER")
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f.lines = PP.UIText(f, 15, PP.C.white)
        f.lines:SetPoint("TOPLEFT", 18, -52)
        f.lines:SetWidth(324)
        panel.materials = f
    end
    local lines = {entry.title}
    for id, count in pairs(entry.costs) do
        lines[#lines + 1] = ("%s   %d / %d"):format(itemDetails(id) or ("Item " .. id), PP:Count(id, true), count * entry.qty)
    end
    lines[#lines + 1] = "Suggested listing: " .. money(entry.outputPrice) .. " each"
    panel.materials.lines:SetText(table.concat(lines, "\n\n"))
    panel.materials:SetHeight(panel.materials.lines:GetStringHeight() + 72)
    panel.materials:Show()
end

-- The button on a row was clicked.
local function act(entry)
    if entry.page == "Blacklist" then
        blacklist()[entry.id] = nil
        refresh()
        return
    end
    if entry.id and blacklist()[entry.id] then return end
    if entry.page == "Auction" then
        if submitPrepared and isPrepared(entry) then submitPrepared()
        elseif open then prepare(entry)
        else setStatus("Open the Auction House to prepare a listing.") end
    elseif entry.page == "Vendor" then
        sellToVendor(entry)
    elseif entry.page == "PlanCraft" then
        local window = _G.ProfessionsFrame or _G.TradeSkillFrame
        local shown = window and window.IsShown and window:IsShown()
        PP:CraftGear(entry.recipe, entry.qty)
        setStatus(shown and ("Making " .. entry.qty .. ". Stay still until it finishes.")
            or "Crafting window opened. Click Craft again.")
    elseif entry.page == "Craft" then
        if not entry.recipe then craftMaterials(entry); return end
        for id, need in pairs(entry.costs) do
            if PP:Count(id, true) < need then craftMaterials(entry); return end
        end
        PP:CraftGear(entry.recipe)
    end
end

-- ---------- 3. Plan tab ----------
-- A to-do list read from LedgerPlan.lua (PP.ledgerPlan). Steps tick off as items leave or enter the bags.

local function planProgress(char)
    local plan = PP.ledgerPlan
    if type(plan) ~= "table" or type(plan.steps) ~= "table" or #plan.steps == 0 then return end
    PP.db.ledgerPlanProgress = PP.db.ledgerPlanProgress or {}
    local progress = PP.db.ledgerPlanProgress[char]
    if not progress or progress.at ~= plan.at then
        progress = { at = plan.at, ids = {}, start = {}, done = {} }
        PP.db.ledgerPlanProgress[char] = progress
    end
    return plan, progress
end

local function isSellStep(step) return step.action == "Auction" or step.action == "Vendor" end

-- "Auction" / "Vendor" step: done when the planned amount has left the bags.
local function sellStepLine(i, step, name, match, progress)
    if match and not progress.ids[i] then
        progress.ids[i] = match.id
        progress.start[i] = PP:Count(match.id, true)
    end
    local qty = tonumber(step.qty) or 1
    local left = qty
    if progress.ids[i] then
        -- Count from the most ever held, so items crafted after the plan was made still tick off.
        local have = PP:Count(progress.ids[i], true)
        progress.start[i] = max(progress.start[i], have)
        left = qty - (progress.start[i] - have)
        if left <= 0 then progress.done[i] = true end
    end
    if progress.done[i] then return end
    left = max(1, min(left, qty))
    local auction = step.action == "Auction" and type(step.price) == "number"
    return { title = name .. " ×" .. left, plan = i, note = step.note, page = step.action,
        action = match and (step.note or step.action) or "Not in bags",
        auction = auction and money(step.price) or "", vendor = match and money(match.vendor) or "",
        link = match and match.link, bound = match and match.bound, qty = left, listed = step.price,
        button = match and (auction and "Prepare" or step.action == "Vendor" and "Sell") or nil, canSkip = true }
end

-- "Craft" step with an amount: one button makes them all. Done when they show up in the bags,
-- or when the step that sells them is done.
local function craftStepLine(i, step, name, plan, progress, char)
    local recipeName = step.recipe or name
    local ids = PP.db.recipeIDs and PP.db.recipeIDs[char]
    local recipeID = ids and ids[recipeName]
    local output, schematic
    if recipeID then output, schematic = recipeData(recipeID) end
    local itemID = type(output) == "string" and tonumber(output:match("item:(%d+)")) or progress.ids[i]
    local per = type(schematic) == "table" and type(schematic.quantityMin) == "number"
        and schematic.quantityMin > 0 and schematic.quantityMin or 1
    local qty = tonumber(step.qty)
    local left = qty
    if itemID then
        local have = PP:Count(itemID, true)
        if not progress.ids[i] then progress.ids[i], progress.start[i] = itemID, have end
        left = qty - floor((have - progress.start[i]) / per)
        if left <= 0 then progress.done[i] = true end
    end
    for j = i + 1, #plan.steps do
        local later = plan.steps[j]
        if progress.done[j] and later.name == step.name and isSellStep(later) then progress.done[i] = true end
    end
    if progress.done[i] then return end
    left = max(1, min(left, qty))
    local ready = recipeID and itemID
    local probe = { name = recipeName }
    local short = ready and PP:GearMats(probe) and not PP:MatsReady(probe)
    return { title = name .. " ×" .. left, plan = i, note = step.note, page = "PlanCraft",
        action = not ready and "Recipe unknown" or short and "No materials" or step.note or "Craft",
        auction = "", vendor = "", qty = left,
        recipe = ready and { name = recipeName, id = itemID, profKey = professionKey(recipeID) } or nil,
        button = ready and not short and ("Craft ×" .. left) or nil, canSkip = true }
end

local function planLines(rows, char)
    local plan, progress = planProgress(char)
    if not plan then return {{ title = "No plan yet. Click AI Help to get one." }} end
    -- First bag row for each item name: any row for vendoring, an unbound one for auctions.
    local anyRow, freeRow = {}, {}
    for _, row in ipairs(rows) do
        if row.name then
            anyRow[row.name] = anyRow[row.name] or row
            if not row.bound then freeRow[row.name] = freeRow[row.name] or row end
        end
    end
    local todo, finished, total = {}, {}, 0
    for i, step in ipairs(plan.steps) do
        local name = tostring(step.name or "?")
        local tracked = isSellStep(step) or (step.action == "Craft" and tonumber(step.qty) ~= nil)
        local line
        if isSellStep(step) then
            line = sellStepLine(i, step, name, step.action == "Vendor" and anyRow[name] or freeRow[name], progress)
        elseif tracked then
            line = craftStepLine(i, step, name, plan, progress, char)
        else
            -- Reminder steps (Keep, Hold, Check) stay in plan order with the sell steps.
            line = { title = name .. (step.note and (" - " .. step.note) or ""), plan = i, note = step.note,
                page = "Plan", action = tostring(step.action or "") }
        end
        if tracked then total = total + 1 end
        if line then
            todo[#todo + 1] = line
        else
            finished[#finished + 1] = { title = name, plan = i, note = step.note, page = "Plan", action = "Done" }
        end
    end
    local complete = total > 0 and #finished == total
    local lines = {{ title = complete and "Plan complete" or ("Plan: %d of %d done"):format(#finished, total) }}
    if plan.scan and PP.db.ledgerScanAt and PP.db.ledgerScanAt > plan.scan then
        lines[#lines + 1] = { title = "Prices were rescanned. Click AI Help for a new plan." }
    end
    for _, line in ipairs(todo) do lines[#lines + 1] = line end
    for _, line in ipairs(finished) do lines[#lines + 1] = line end
    return lines
end

-- ---------- 4. Ledger ----------

-- One row per item in the bags (bound and unbound copies are kept apart).
local function scanBags()
    local seen, rows = {}, {}
    local hidden = blacklist()
    eachBagItem(function(bag, slot, item)
        if not item.hyperlink or hidden[item.itemID] or item.isLocked or isQuestItem(bag, slot) then return end
        local bound = item.isBound == true
        if not bound and read(C_Item.CanBeAuctioned, ItemLocation:CreateFromBagAndSlot(bag, slot)) == false then return end
        local key = bound and ("bound:" .. item.hyperlink) or item.hyperlink
        local row = seen[key]
        if not row then
            local name, vendor = itemDetails(item.hyperlink)
            local net, listed
            if not bound then net, listed = price(item.hyperlink) end
            row = { id = item.itemID, link = item.hyperlink, key = key, bound = bound, count = 0,
                name = name, vendor = item.hasNoValue and 0 or vendor, net = net, listed = listed }
            seen[key] = row
            rows[#rows + 1] = row
        end
        row.count = row.count + item.stackCount
    end)
    return rows
end

-- What the profession guide still needs (kept out of every offer), and which items are profession tools.
local function guideNeeds()
    local reserve, tools = {}, {}
    for _, def in ipairs(PP.professions) do
        if def.tool and def.tool[1] then tools[def.tool[1]] = true end
        local skill = PP:GetSkill(def)
        local step = skill and skill > 0 and PP:StepFor(def, skill)
        for _, mat in ipairs(step and step.mats or {}) do
            local needed = PP.CraftsFor(step, skill, step.to) * (mat[2] or 1)
            reserve[mat[1]] = (reserve[mat[1]] or 0) + needed
        end
    end
    return reserve, tools
end

local function byGain(a, b)
    local gainA = max(0, (a.net or 0) - (a.vendor or 0)) * a.count
    local gainB = max(0, (b.net or 0) - (b.vendor or 0)) * b.count
    if gainA ~= gainB then return gainA > gainB end
    return a.link < b.link
end

-- How much of each item was held back when the stock limit was last set. Reset by a new limit or a new scan.
local function stockPlan(char, pct)
    PP.db.ledgerStockPlans = PP.db.ledgerStockPlans or {}
    local plan = PP.db.ledgerStockPlans[char]
    if not plan or plan.percent ~= pct or plan.v ~= 2 then
        plan = { percent = pct, keep = {}, v = 2 }
        PP.db.ledgerStockPlans[char] = plan
    end
    return plan
end

-- Known recipes that sell for at least 20% more than their materials, best first.
local function craftOptions(char, stock, market)
    local crafts = {}
    local known = PP.db.recipeIDs and PP.db.recipeIDs[char]
    for name, id in pairs(known or {}) do
        local output, schematic = recipeData(id)
        if output and schematic and type(schematic.quantityMin) == "number" and schematic.quantityMin > 0 then
            local net, outputPrice = price(output)
            local costs, cost = {}, 0
            local slots = schematic.reagentSlotSchematics or {}
            local valid, hasSpare = net ~= nil and #slots > 0, false
            for _, slot in ipairs(slots) do
                local reagent = slot.reagents and #slot.reagents == 1 and slot.reagents[1]
                local item = reagent and reagent.itemID
                local ingredientValue = item and (market[item] or price(item))
                if not ingredientValue or slot.required == false or type(slot.quantityRequired) ~= "number"
                    or slot.quantityRequired <= 0 then
                    valid = false
                    break
                end
                costs[item] = (costs[item] or 0) + slot.quantityRequired
                cost = cost + slot.quantityRequired * ingredientValue
                hasSpare = hasSpare or (stock[item] or 0) > 0
            end
            if valid and hasSpare and net * schematic.quantityMin > cost * 1.2 then
                crafts[#crafts + 1] = { name = name, costs = costs, gain = net * schematic.quantityMin - cost,
                    outputPrice = outputPrice, itemID = tonumber(output:match("item:(%d+)")), profKey = professionKey(id) }
            end
        end
    end
    table.sort(crafts, function(a, b)
        if a.gain == b.gain then return a.name < b.name end
        return a.gain > b.gain
    end)
    return crafts
end

local REPORT_COLUMNS = "Items: name | bag quantity | available after reserves | already allocated to craft"
    .. " | recommended action | recommended quantity | vendor each | auction ask each | estimated auction net each"

-- Reads the bags and saved prices. Returns the rows to show on tab `wantPage`, the AI report text, and the bag rows.
local function compute(pct, wantPage)
    local char = charKey()
    local plan = stockPlan(char, pct)
    wanted = {}
    local rows = scanBags()
    local reserve, tools = guideNeeds()
    table.sort(rows, byGain)

    -- How many of each item may be offered: spare stock (after the guide's needs) times the stock limit.
    local stock, market = {}, {}
    for _, row in ipairs(rows) do
        local held = reserve[row.id] or reserve[row.name] or 0
        row.spare = max(0, row.count - held)
        reserve[row.id] = max(0, held - row.count)
        local keep = plan.keep[row.key]
        -- A lone spare item is offered whole (half of 1 rounds down to 0), except profession tools.
        local single = row.spare == 1 and pct > 0 and not tools[row.id]
        if keep == nil then
            local offer = single and 1 or floor(row.spare * pct / 100)
            keep = row.spare - offer
            plan.keep[row.key] = keep
        end
        row.offer = max(0, row.spare - keep)
        if not single then row.offer = min(row.offer, floor(row.spare * pct / 100)) end
        -- Always keep one of each profession tool, even at 100%.
        if tools[row.id] then row.offer = min(row.offer, max(0, row.spare - 1)) end
        if not row.bound then stock[row.id] = (stock[row.id] or 0) + row.offer end
        if row.net and row.vendor then market[row.id] = max(row.net, row.vendor) end
    end

    -- Crafts take their materials out of the offered stock first.
    local allocated, lines, recipeReport = {}, {}, {}
    for _, craft in ipairs(craftOptions(char, stock, market)) do
        local count = math.huge
        local ingredients = {}
        for id, need in pairs(craft.costs) do
            count = min(count, floor((stock[id] or 0) / need))
            ingredients[#ingredients + 1] = (itemDetails(id) or tostring(id)) .. " x" .. need
        end
        table.sort(ingredients)
        recipeReport[#recipeReport + 1] = ("%s | craftable %d | output ask %d | extra net per craft %d | %s"):format(
            craft.name, count, craft.outputPrice, craft.gain, table.concat(ingredients, ", "))
        if count > 0 then
            for id, need in pairs(craft.costs) do
                stock[id] = stock[id] - count * need
                allocated[id] = (allocated[id] or 0) + count * need
            end
            if wantPage == "Craft" then
                lines[#lines + 1] = { title = craft.name .. " ×" .. count, page = "Craft",
                    action = "Craft", auction = "+" .. money(count * craft.gain),
                    qty = count, costs = craft.costs, outputPrice = craft.outputPrice,
                    button = "Craft it", recipe = { name = craft.name, id = craft.itemID, profKey = craft.profKey } }
            end
        elseif wantPage == "Craft" then
            lines[#lines + 1] = { title = craft.name, page = "Craft", action = "Materials",
                auction = "+" .. money(craft.gain), qty = 1, costs = craft.costs,
                outputPrice = craft.outputPrice, button = "Materials" }
        end
    end

    local report = { "Market Ledger report v1", "All prices are copper per unit. Listings are asking prices.",
        "Stock limit: " .. pct .. "%",
        "Last completed scan (Unix time): " .. tostring(PP.db.ledgerScanAt or "unknown"), REPORT_COLUMNS }
    for _, row in ipairs(rows) do
        local used = row.bound and 0 or min(row.offer, allocated[row.id] or 0)
        allocated[row.id] = (allocated[row.id] or 0) - used
        local qty = row.offer - used
        local action = "Check price"
        if qty == 0 then action = used > 0 and "Craft" or "Keep"
        elseif row.bound then
            action = row.vendor and row.vendor > 0 and "Vendor" or "Keep"
        elseif row.vendor and row.net then
            if row.net > row.vendor then action = "Auction"
            elseif row.vendor > 0 then action = "Vendor"
            else action = "Keep" end
        end
        -- Bound items with no vendor value (Hearthstone, quest tokens) can't be sold: leave them out.
        if not (row.bound and (row.vendor or 0) == 0) then
            report[#report + 1] = table.concat({ row.name or tostring(row.id), row.count, row.offer, used,
                action, qty, row.vendor or "unknown", row.listed or "unknown", row.net or "unknown" }, " | ")
        end
        local category = (action == "Auction" or action == "Vendor") and action or "Keep"
        if category == wantPage and (used == 0 or qty > 0 or row.count > used) then
            local reason = "Stock limit"
            if used > 0 then reason = "For crafting"
            elseif row.spare < row.count then reason = "For your guide"
            elseif tools[row.id] and qty == 0 then reason = "Tool"
            elseif action == "Check price" then reason = "Price unknown"
            elseif row.offer > 0 and row.vendor == 0 then reason = "No sale value" end
            lines[#lines + 1] = {
                title = (row.name or row.link:match("%[(.-)%]") or row.link) .. " ×" .. row.count,
                page = category, id = row.id, name = row.name, action = action .. (qty > 0 and " ×" .. qty or ""),
                auction = money(row.net), vendor = money(row.vendor), reason = reason,
                link = row.link, bound = row.bound, qty = qty, listed = row.listed,
                button = category == "Auction" and "Prepare" or category == "Vendor" and "Sell" or nil,
            }
        end
    end
    report[#report + 1] = "Craft opportunities with known prices:"
    for _, recipe in ipairs(recipeReport) do report[#report + 1] = recipe end
    if #recipeReport == 0 then report[#report + 1] = "none" end

    if wantPage == "Plan" then
        lines = planLines(rows, char)
    elseif wantPage == "Blacklist" then
        lines = {}
        for id, name in pairs(blacklist()) do
            lines[#lines + 1] = { id = id, title = name, page = "Blacklist", button = "Restore" }
        end
        table.sort(lines, function(a, b) return a.title < b.title end)
        if #lines == 0 then lines[1] = { title = "No blacklisted items" } end
    elseif wantPage and #lines == 0 then
        lines[1] = { title = "No " .. wantPage:lower() .. " picks" }
    end
    return lines, table.concat(report, "\n"), rows
end

-- Puts the report where the desktop companion can read it. WoW writes it to disk on /reload or logout.
local function exportReport(report)
    local encoded = report:gsub(".", function(char) return ("%02x"):format(char:byte()) end)
    PP.db.ledgerAdviceExport = "PPLEDGER1:" .. encoded
    PP.db.ledgerExportScan = PP.db.ledgerScanAt
end

-- ---------- rows on screen ----------

local function ledgerText(parent, size, color)
    local text = PP.UIText(parent, size, color)
    text:SetFont(STANDARD_TEXT_FONT or PP.TITLE_FONT, size, "")
    text:SetWordWrap(false)
    return text
end

local function columns(row)
    row.item = ledgerText(row, 13, PP.C.white)
    row.item:SetPoint("LEFT", 9, 0)
    row.item:SetPoint("RIGHT", row, "RIGHT", -336, 0)
    row.action = ledgerText(row, 12, PP.C.gold)
    row.action:SetPoint("RIGHT", row, "RIGHT", -330, 0)
    row.auction = ledgerText(row, 12, PP.C.white)
    row.auction:SetPoint("RIGHT", row, "RIGHT", -221, 0)
    row.vendor = ledgerText(row, 12, PP.C.white)
    row.vendor:SetPoint("RIGHT", row, "RIGHT", -115, 0)
end

-- Right-click: tick a plan step, or blacklist an item.
local function onRowMouseUp(self, button)
    local entry = self.entry
    if button ~= "RightButton" or not entry then return end
    if entry.plan then
        local _, progress = planProgress(charKey())
        if progress and (entry.canSkip or progress.done[entry.plan]) then
            progress.done[entry.plan] = not progress.done[entry.plan] or nil
            refresh()
        end
        return
    end
    if not entry.id or entry.page == "Blacklist" then return end
    blacklist()[entry.id] = entry.name or entry.title
    refresh()
    setStatus("Item blacklisted. Restore it from the Blacklist tab.")
end

local function onRowEnter(self)
    local entry = self.entry
    if not entry then return end
    if entry.plan then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText(entry.note or entry.title, 1, 1, 1, 1, true)
        if entry.canSkip then GameTooltip:AddLine("Right-click to mark done") end
        GameTooltip:Show()
    elseif entry.id and entry.page ~= "Blacklist" then
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetText("Right-click to blacklist this item")
        GameTooltip:Show()
    end
end

local function onRowLeave(self)
    if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
end

local function createRow(i)
    local row = CreateFrame("Frame", nil, panel.body, "BackdropTemplate")
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * 32)
    row:SetPoint("RIGHT", panel.body, "RIGHT", 0, 0)
    if i % 2 == 1 then PP.Skin(row, nil, { bg = PP.THEME.inset }) end
    columns(row)
    row:EnableMouse(true)
    row:SetScript("OnMouseUp", onRowMouseUp)
    row:SetScript("OnEnter", onRowEnter)
    row:SetScript("OnLeave", onRowLeave)
    row.button = PP.UIButton(row, "Prepare", 102, 23, function(_, button)
        if button == "RightButton" and row.entry.page == "Craft" then craftMaterials(row.entry)
        elseif button == "LeftButton" then act(row.entry) end
    end)
    row.button:GetFontString():SetFont(STANDARD_TEXT_FONT or PP.TITLE_FONT, 11, "")
    row.button:SetPoint("RIGHT", -8, 0)
    row.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    return row
end

local function display(entries)
    for i, entry in ipairs(entries) do
        local row = panel.cards[i]
        if not row then
            row = createRow(i)
            panel.cards[i] = row
        end
        row.entry = entry
        -- Stop the name before the Plan column so the two never overlap; message rows use the full width.
        local plain = not (entry.action or entry.reason or entry.button)
        row.item:SetPoint("RIGHT", row, "RIGHT", plain and -9 or entry.plan and -460 or -430, 0)
        row.item:SetText(entry.title)
        row.action:SetText(entry.page == "Keep" and entry.reason or entry.action or "")
        row.auction:SetText(entry.auction or "")
        row.vendor:SetText(entry.vendor or "")
        row.button:SetText(entry.page == "Auction" and isPrepared(entry) and "Create Auction" or entry.button or "")
        row.button:SetShown(entry.button ~= nil)
        row:Show()
    end
    for i = #entries + 1, #panel.cards do panel.cards[i]:Hide() end
    panel.body:SetHeight(max(1, #entries * 32))
end

-- ---------- 6. AI Help ----------
-- Four steps: scan -> save -> ask the AI -> follow the plan. The window marks the step you are on.

local GUIDE = {
    { "Scan prices", "At the Auction House, click Scan Bags.", "Scan Bags" },
    { "Save the scan", "Click Save and reload. This writes your scan to your PC.", "Save and reload" },
    { "Ask the AI", "On your PC, open Market Ledger Companion and follow its steps. Then click Reload.", "Reload" },
    { "Follow the plan", "Work down the Plan tab. Rows tick off as you sell.", "Open Plan tab" },
}
local GUIDE_NEXT = {
    "Next: go to the Auction House and click Scan Bags.",
    "Next: click Save and reload.",
    "Next: open Market Ledger Companion on your PC.",
    "Next: work down the Plan tab.",
}
local OLD_SCAN = 2 * 60 * 60

-- Which step the player is on.
local function aiStep()
    local scanAt = PP.db.ledgerScanAt
    if not scanAt then return 1 end
    local plan = PP.ledgerPlan
    local planScan = type(plan) == "table" and tonumber(plan.scan) or 0
    -- A plan made from this scan proves the scan reached the disk.
    if unsaved or (PP.db.ledgerExportScan ~= scanAt and planScan ~= scanAt) then return 2 end
    if planScan < scanAt then return 3 end
    return 4
end

local scan, selectTab   -- defined below

local function reloadNow()
    local reload = (C_UI and C_UI.Reload) or ReloadUI
    if reload then reload() end
end

local function guideAction()
    local step = aiStep()
    if step == 1 then
        scan()
    elseif step == 4 then
        selectTab("Plan")
        panel.guide:Hide()
    else
        -- Steps 2 and 3 both end with a reload: it saves the scan and loads a new plan.
        refresh()
        if adviceReport then exportReport(adviceReport) end
        reloadNow()
    end
end

local function updateGuide()
    local guide = panel and panel.guide
    if not guide or not guide:IsShown() then return end
    local step = aiStep()
    local scanAt = PP.db.ledgerScanAt
    for i, row in ipairs(guide.rows) do
        local state, color = "", PP.C.gray
        if i < step then state, color = "Done", PP.C.green
        elseif i == step then state, color = "Do this now", PP.C.gold end
        if i == 1 and scanAt then state = "Done, " .. ago(scanAt) end
        row.state:SetText(state)
        row.state:SetTextColor(unpack(color))
        row.number:SetTextColor(unpack(i == step and PP.C.gold or PP.C.gray))
        row.title:SetTextColor(unpack(i == step and PP.C.gold or PP.C.white))
    end
    local nextLine = GUIDE_NEXT[step]
    -- Old prices only matter before the AI has seen them.
    if (step == 2 or step == 3) and now() - scanAt > OLD_SCAN then
        nextLine = "Your prices are " .. ago(scanAt):gsub(" ago", "") .. " old. Scan again for better advice."
    end
    guide.next:SetText(nextLine)
    guide.button:SetText(GUIDE[step][3])
end

local function showGuide()
    if not panel.guide then
        local guide = PP.UIWindow("ProfessionPalLedgerAdvice", 480, "AI Help")
        guide:SetPoint("CENTER")
        guide:SetFrameStrata("FULLSCREEN_DIALOG")
        guide:SetHeight(388)
        guide.next = PP.UIText(guide, 16, PP.C.gold)
        guide.next:SetPoint("TOPLEFT", 18, -52)
        guide.next:SetWidth(444)
        guide.rows = {}
        for i, step in ipairs(GUIDE) do
            local y = -96 - (i - 1) * 58
            local row = {}
            row.number = PP.UIText(guide, 18, PP.C.gray)
            row.number:SetPoint("TOPLEFT", 18, y)
            row.number:SetText(tostring(i))
            row.title = PP.UIText(guide, 16, PP.C.white)
            row.title:SetPoint("TOPLEFT", 46, y)
            row.title:SetText(step[1])
            row.state = PP.UIText(guide, 14, PP.C.gray, "RIGHT")
            row.state:SetPoint("TOPRIGHT", -18, y)
            row.detail = PP.UIText(guide, 14, PP.C.gray)
            row.detail:SetPoint("TOPLEFT", 46, y - 20)
            row.detail:SetWidth(416)
            row.detail:SetText(step[2])
            guide.rows[i] = row
        end
        guide.button = PP.UIButton(guide, "", 200, 30, guideAction)
        guide.button:SetPoint("BOTTOM", 0, 16)
        panel.guide = guide
    end
    panel.guide:Show()
    updateGuide()
end

refresh = function()
    if not PP.db or not panel then return end
    local pct = clampPercent(panel.percent:GetText())
    PP.db.auctionTestPercent = pct
    panel.percent:SetText(tostring(pct))
    local lines
    lines, adviceReport = compute(pct, page)
    display(lines)
    updateGuide()
end

-- ---------- 5. Price scan ----------
-- Searches the Auction House for one item at a time and saves the lowest unit price.

local queue, index, current
local generation = 0   -- bumps when a scan starts or the Auction House closes, so late timers do nothing

local function advance()
    if not open or not queue then return end
    local run = generation
    if ah.IsThrottledMessageSystemReady and not read(ah.IsThrottledMessageSystemReady) then
        C_Timer.After(0.4, function() if generation == run then advance() end end)
        return
    end
    index = index + 1
    current = queue[index]
    if not current then
        queue = nil
        PP.db.ledgerScanAt = now()
        unsaved = true
        refresh()
        setStatus("Scan complete. Click AI Help for a sell plan.")
        return
    end
    setStatus(("Checking prices %d / %d"):format(index, #queue))
    if blacklist()[current.key.itemID] then
        current = nil
        C_Timer.After(0, function() if generation == run then advance() end end)
        return
    end
    local ok = pcall(ah.SendSearchQuery, current.key, {}, true)
    local request = current
    -- Move on if no answer comes back.
    C_Timer.After(ok and 4 or 0.4, function()
        if generation == run and current == request then
            current = nil
            advance()
        end
    end)
end

scan = function()
    if queue then return end
    if not open then setStatus("Open the Auction House to scan prices."); return end
    if not ah or not ah.SendSearchQuery then
        setStatus("Auction House search is unavailable.")
        return
    end
    -- A new scan starts a new stock plan.
    if PP.db.ledgerStockPlans then PP.db.ledgerStockPlans[charKey()] = nil end
    refresh()
    queue, index = {}, 0
    for signature, key in pairs(wanted) do queue[#queue + 1] = { signature = signature, key = key } end
    if #queue == 0 then
        queue = nil
        setStatus("No items to scan.")
        return
    end
    generation = generation + 1
    advance()
end

local function receive(event, resultKey)
    if not current or not resultKey then return end
    local best
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
        if resultKey ~= current.key.itemID then return end
        for i = 1, read(ah.GetNumCommoditySearchResults, resultKey) or 0 do
            local row = read(ah.GetCommoditySearchResultInfo, resultKey, i)
            local value = row and row.unitPrice
            if type(value) == "number" and value > 0 then best = min(best or value, value) end
        end
    else
        local key = current.key
        if resultKey.itemID ~= key.itemID or resultKey.itemLevel ~= key.itemLevel or
            resultKey.itemSuffix ~= key.itemSuffix or resultKey.battlePetSpeciesID ~= key.battlePetSpeciesID then return end
        for i = 1, read(ah.GetNumItemSearchResults, resultKey) or 0 do
            local row = read(ah.GetItemSearchResultInfo, resultKey, i)
            local value = row and row.buyoutAmount
            if type(value) == "number" and value > 0 then
                value = value / max(1, row.quantity or 1)
                best = min(best or value, value)
            end
        end
    end
    savedPrices()[current.signature] = best and floor(best) or nil
    current = nil
    local run = generation
    C_Timer.After(0.35, function() if generation == run then advance() end end)
end

-- ---------- 7. Window and events ----------

local function build()
    panel = PP.UIWindow("ProfessionPalAuctionWindow", 720, "Market Ledger")
    panel:SetSize(max(640, PP.db.ledgerWidth or 720), PP.db.ledgerHeight or 520)
    panel:SetResizable(true)
    panel:SetResizeBounds(640, 320, 1050, 800)
    panel:SetScale(PP.db.ledgerScale or 1)
    panel:SetPoint("CENTER", UIParent, "CENTER", 265, 0)
    panel:SetFrameStrata("DIALOG")
    if PP.ledgerPlan then page = "Plan" end

    -- top row: stock limit on the left, scale and scan on the right
    local label = PP.UIText(panel, 15, PP.C.gold)
    label:SetPoint("TOPLEFT", 18, -55)
    label:SetText("Sell up to")
    panel.percent = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
    PP.Skin(panel.percent, nil, { bg = PP.THEME.btn, border = PP.THEME.btnBorder })
    panel.percent:SetFont(PP.FONT, 16, "")
    panel.percent:SetTextColor(unpack(PP.C.white))
    panel.percent:SetJustifyH("CENTER")
    panel.percent:SetSize(42, 24)
    panel.percent:SetPoint("LEFT", label, "RIGHT", 10, 0)
    panel.percent:SetAutoFocus(false)
    panel.percent:SetNumeric(true)
    panel.percent:SetMaxLetters(3)
    panel.percent:SetText(tostring(PP.db.auctionTestPercent or 50))
    panel.percent:SetScript("OnEnterPressed", function(self) self:ClearFocus(); refresh() end)
    local suffix = PP.UIText(panel, 15, PP.C.white)
    suffix:SetPoint("LEFT", panel.percent, "RIGHT", 4, 0)
    suffix:SetText("% of spare stock")

    local scale = PP.UIButton(panel, "Scale", 68, 28, function(self)
        local nextScale = (PP.db.ledgerScale or 1) + 0.1
        if nextScale > 1.21 then nextScale = 0.8 end
        PP.db.ledgerScale = nextScale
        panel:SetScale(nextScale)
        self:SetText(("%.0f%%"):format(nextScale * 100))
    end)
    scale:SetText(("%.0f%%"):format((PP.db.ledgerScale or 1) * 100))
    scale:SetPoint("TOPRIGHT", -126, -49)
    PP.UIButton(panel, "Scan Bags", 100, 28, scan):SetPoint("TOPRIGHT", -18, -49)
    PP.UIButton(panel, "AI Help", 94, 24, showGuide):SetPoint("TOPRIGHT", -36, -8)
    PP.UIButton(panel, "Clear Prices", 96, 25, function()
        if queue then setStatus("Wait for the scan to finish."); return end
        wipe(savedPrices())
        refresh()
        setStatus("Saved prices cleared.")
    end):SetPoint("TOPRIGHT", -18, -106)

    panel.status = PP.UIText(panel, 14, PP.C.muted or PP.C.white)
    panel.status:SetPoint("TOPLEFT", 18, -86)

    -- column titles and the scrolling list
    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 18, -138)
    header:SetPoint("TOPRIGHT", -36, -138)
    header:SetHeight(25)
    columns(header)
    header.item:SetText("Item")
    header.action:SetText("Plan")
    header.auction:SetText("AH net / gain")
    header.vendor:SetText("Vendor")
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -166)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    panel.body = CreateFrame("Frame", nil, scroll)
    panel.body:SetSize(panel:GetWidth() - 54, 1)
    scroll:SetScrollChild(panel.body)
    panel.cards = {}
    panel:SetScript("OnSizeChanged", function(_, width) panel.body:SetWidth(width - 54) end)

    local grip = PP.UIButton(panel, "↘", 23, 20)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetScript("OnMouseDown", function() panel:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        PP.db.ledgerWidth, PP.db.ledgerHeight = panel:GetSize()
    end)

    local tabs = {}
    selectTab = function(name)
        page = name
        header.action:SetText(name == "Keep" and "Reason" or "Plan")
        for tabName, button in pairs(tabs) do button:SetSelected(tabName == page) end
        scroll:SetVerticalScroll(0)
        refresh()
    end
    for position, name in ipairs({"Plan", "Auction", "Vendor", "Craft", "Keep", "Blacklist"}) do
        local tab = PP.UIButton(panel, name, 80, 25, function() selectTab(name) end)
        tab:SetPoint("TOPLEFT", 18 + (position - 1) * 85, -106)
        tab:SetSelected(name == page)
        tabs[name] = tab
    end
end

-- The line shown when the window opens: the one thing to do next.
local function openingStatus()
    if not PP.db.ledgerScanAt then
        return open and "Click Scan Bags to price your bags." or "Go to the Auction House, then click Scan Bags."
    end
    if page == "Plan" and PP.ledgerPlan then return "Work down the list. Right-click a row to mark it done." end
    return open and "Saved prices shown. Scan Bags to refresh." or "Saved prices shown. Refresh at the Auction House."
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED", "MERCHANT_SHOW", "MERCHANT_CLOSED",
    "BAG_UPDATE_DELAYED", "COMMODITY_SEARCH_RESULTS_UPDATED", "ITEM_SEARCH_RESULTS_UPDATED", "PLAYER_LOGOUT" }) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, key)
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_UPDATED" then
        receive(event, key)
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_CLOSED" then
        merchant = event == "MERCHANT_SHOW"
    elseif event == "BAG_UPDATE_DELAYED" then
        if panel and panel:IsShown() then refresh() end
    elseif event == "PLAYER_LOGOUT" then
        -- Save a fresh report on every /reload and logout, so the companion always reads the current bags.
        if PP.db and PP.db.ledgerScanAt then
            local ok, _, report, rows = pcall(compute, clampPercent(PP.db.auctionTestPercent))
            if ok and report and #rows > 0 then exportReport(report) end
        end
    else
        open = event == "AUCTION_HOUSE_SHOW"
        if not open then
            generation = generation + 1
            queue, current = nil, nil
            preparedRow, submitPrepared = nil, nil
            prepareRequest = prepareRequest + 1
            if panel then panel:Hide() end
        end
    end
end)

function PP:ToggleMarketLedger()
    if not PP.db then return end
    if panel and panel:IsShown() then panel:Hide(); return end
    if not panel then build() end
    panel:Show()
    refresh()
    if not queue then setStatus(openingStatus()) end
end

SLASH_PROFESSIONPALBAGPRICES1 = "/ppauction"
SlashCmdList.PROFESSIONPALBAGPRICES = function() PP:ToggleMarketLedger() end
