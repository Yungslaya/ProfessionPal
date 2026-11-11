local _, PP = ...
local floor, min = math.floor, math.min
local function read(fn, ...)
    if not fn then return end
    local ok, value = pcall(fn, ...)
    if ok and not (issecretvalue and issecretvalue(value)) then return value end
end

local ah = C_AuctionHouse
local wanted = {}
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
local function itemDetails(link)
    local lookup = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if not lookup then return end
    local ok, name, vendor = (function(success, itemName, ...)
        return success, itemName, select(10, ...)
    end)(pcall(lookup, link))
    if not ok then return end
    if issecretvalue and (issecretvalue(name) or issecretvalue(vendor)) then return end
    return name, vendor
end

local function money(value)
    if value == nil then return "—" end
    return ("%dg %02ds %02dc"):format(floor(value / 10000), floor(value / 100) % 100, value % 100)
end

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

local panel, open, merchant, refresh
local page = "Auction"
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

local function prepare(row)
    if preparedRow then preparedRow.button = "Prepare" end
    preparedRow, submitPrepared = nil, nil
    prepareRequest = prepareRequest + 1
    local request = prepareRequest
    trace(("Prepare #%d: quantity %s, unit price %s"):format(request, tostring(row.qty), tostring(row.listed)))
    if not open or PP:InCombat() then trace("Auction House closed or player in combat."); return end
    local frame = AuctionHouseFrame
    if not frame or not frame.SetPostItem then
        trace("Sell form unavailable.")
        panel.status:SetText("Drag this item to the Sell tab.")
        return
    end
    for bag = 0, NUM_BAG_SLOTS + (NUM_REAGENTBAG_SLOTS or 0) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = read(C_Container.GetContainerItemInfo, bag, slot)
            if item and item.hyperlink == row.link and not item.isBound and not item.isLocked and not isQuestItem(bag, slot) then
                local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if read(ah.IsSellItemValid, location) ~= false then
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
                    local function fill()
                        if not open or request ~= prepareRequest or PP:InCombat() then return end
                        local sell, field = selectedForm()
                        if not sell then trace("Sell form has not selected the requested item."); return false end
                        local ok, err = pcall(function()
                            sell.QuantityInput:SetQuantity(quantity)
                            sell.PriceInput:SetAmount(row.listed)
                        end)
                        if not ok then trace(field .. " input error: " .. tostring(err)); return false end
                        local actualQty = read(sell.GetQuantity, sell)
                            or read(sell.QuantityInput.GetQuantity, sell.QuantityInput)
                        local actualPrice = read(sell.PriceInput.GetAmount, sell.PriceInput)
                        trace(("%s readback: quantity %s, price %s"):format(field, tostring(actualQty), tostring(actualPrice)))
                        if actualQty ~= quantity or actualPrice ~= row.listed then return false end
                        local post = sell.PostButton
                        if post then
                            preparedRow = row
                            row.button = "Create Auction"
                            for _, card in ipairs(panel.cards) do
                                if card.entry and card.entry.link == row.link then card.button:SetText(row.button) end
                            end
                            submitPrepared = function()
                                local input = sell.QuantityInput and sell.QuantityInput.InputBox
                                if input and input:HasFocus() then input:ClearFocus() end
                                if not open or PP:InCombat() or selectedForm() ~= sell
                                    or not post:IsVisible()
                                    or read(sell.GetQuantity, sell) ~= quantity
                                    or read(sell.PriceInput.GetAmount, sell.PriceInput) ~= row.listed then
                                    trace("Sell form changed. Prepare the listing again.")
                                    panel.status:SetText("Sell form changed. Click Prepare again.")
                                    preparedRow, submitPrepared = nil, nil
                                    refresh()
                                    return
                                end
                                if field == "CommoditiesSellFrame" and sell.GetPostDetails then
                                    local ok, _, _, postQuantity, postPrice = pcall(sell.GetPostDetails, sell)
                                    trace(("WoW post details: quantity %s, unit price %s"):format(
                                        tostring(postQuantity), tostring(postPrice)))
                                    if not ok or postQuantity ~= quantity or postPrice ~= row.listed then
                                        panel.status:SetText("WoW changed the listing. Check quantity and unit price in Sell.")
                                        return
                                    end
                                end
                                if not post:IsEnabled() then
                                    trace("WoW posting button disabled.")
                                    panel.status:SetText("WoW is not ready to post. Check the Sell form.")
                                    return
                                end
                                preparedRow, submitPrepared = nil, nil
                                row.button = "Prepare"
                                for _, card in ipairs(panel.cards) do
                                    if card.entry and card.entry.link == row.link then card.button:SetText(row.button) end
                                end
                                local posted, err = pcall(post.Click, post)
                                trace(posted and ("Create Auction clicked for " .. quantity .. " at " .. row.listed .. " each.") or ("Post button error: " .. tostring(err)))
                                panel.status:SetText(posted and "Check WoW for the auction result." or "Click Create Auction in WoW.")
                            end
                        end
                        panel.status:SetText("Review quantity, price and deposit before posting.")
                        return true
                    end
                    if fill() == false then
                        C_Timer.After(0.2, function()
                            if fill() == false then
                                panel.status:SetText(("Enter %d at %s each. See /ppauctiondebug."):format(quantity, money(row.listed)))
                            end
                        end)
                    end
                    return
                end
            end
        end
    end
    trace("No eligible bag stack matched the recommendation.")
    panel.status:SetText("Could not find an eligible stack. Scan Bags again.")
end
local function sellToVendor(entry)
    if not merchant or not MerchantFrame or not MerchantFrame:IsShown() or PP:InCombat() then
        panel.status:SetText("Open a vendor to sell this item.")
        return
    end
    local splitBag, splitSlot
    for bag = 0, NUM_BAG_SLOTS + (NUM_REAGENTBAG_SLOTS or 0) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = read(C_Container.GetContainerItemInfo, bag, slot)
            if item and item.hyperlink == entry.link and (item.isBound == true) == entry.bound and not item.isLocked and not isQuestItem(bag, slot)
                then
                local _, vendor = itemDetails(item.hyperlink)
                if item.hasNoValue or type(vendor) ~= "number" or vendor <= 0 then
                    panel.status:SetText("This item has no vendor value.")
                    return
                end
                if item.stackCount > entry.qty then
                    splitBag, splitSlot = bag, slot
                else
                local ok = pcall(C_Container.UseContainerItem, bag, slot)
                if ok then
                    panel.status:SetText("Sale requested. Check Buyback to verify.")
                else
                    panel.status:SetText("WoW blocked the sale. Right-click the stack in your bags.")
                end
                return
                end
            end
        end
    end
    if splitBag and entry.qty > 0 and GetCursorInfo and not GetCursorInfo() then
        for slot = 1, C_Container.GetContainerNumSlots(0) do
            if not read(C_Container.GetContainerItemInfo, 0, slot) then
                local ok = pcall(C_Container.SplitContainerItem, splitBag, splitSlot, entry.qty)
                if ok and GetCursorInfo() == "item" then
                    pcall(C_Container.PickupContainerItem, 0, slot)
                    if not GetCursorInfo() then
                        panel.status:SetText("Stack split. Click Sell again to sell " .. entry.qty .. ".")
                    else
                        panel.status:SetText("Place the split stack in your bags, then click Sell again.")
                    end
                    return
                end
                break
            end
        end
    end
    panel.status:SetText("Split off " .. entry.qty .. " or fewer before selling.")
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
        local needed = count * entry.qty
        local have = PP:Count(id, true)
        lines[#lines + 1] = ("%s   %d / %d"):format(itemDetails(id) or ("Item " .. id), have, needed)
    end
    lines[#lines + 1] = "Suggested listing: " .. money(entry.outputPrice) .. " each"
    panel.materials.lines:SetText(table.concat(lines, "\n\n"))
    panel.materials:SetHeight(panel.materials.lines:GetStringHeight() + 72)
    panel.materials:Show()
end

local function act(entry)
    if entry.page == "Blacklist" then
        blacklist()[entry.id] = nil
        refresh()
        return
    end
    if entry.id and blacklist()[entry.id] then return end
    if entry.page == "Auction" then
        if preparedRow and submitPrepared and entry.link == preparedRow.link
            and entry.qty == preparedRow.qty and entry.listed == preparedRow.listed then submitPrepared()
        elseif open then prepare(entry)
        else panel.status:SetText("Open the Auction House to prepare a listing.") end
    elseif entry.page == "Vendor" then
        sellToVendor(entry)
    elseif entry.page == "Craft" then
        if not entry.recipe then craftMaterials(entry); return end
        for id, need in pairs(entry.costs) do
            if PP:Count(id, true) < need then craftMaterials(entry); return end
        end
        PP:CraftGear(entry.recipe)

    end
end
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

local function display(entries)
    for i, entry in ipairs(entries) do
        local row = panel.cards[i]
        if not row then
            row = CreateFrame("Frame", nil, panel.body, "BackdropTemplate")
            row:SetHeight(30)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * 32)
            row:SetPoint("RIGHT", panel.body, "RIGHT", 0, 0)
            if i % 2 == 1 then PP.Skin(row, nil, {bg = PP.THEME.inset}) end
            columns(row)
            row:EnableMouse(true)
            row:SetScript("OnMouseUp", function(self, button)
                local entry = self.entry
                if button ~= "RightButton" or not entry or not entry.id or entry.page == "Blacklist" then return end
                blacklist()[entry.id] = entry.name or entry.title
                refresh()
                panel.status:SetText("Item blacklisted. Restore it from the Blacklist tab.")
            end)
            row:SetScript("OnEnter", function(self)
                local entry = self.entry
                if not entry or not entry.id or entry.page == "Blacklist" then return end
                GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                GameTooltip:SetText("Right-click to blacklist this item")
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
            end)
            row.button = PP.UIButton(row, "Prepare", 102, 23, function(_, button)
                if button == "RightButton" and row.entry.page == "Craft" then craftMaterials(row.entry)
                elseif button == "LeftButton" then act(row.entry) end
            end)
            row.button:GetFontString():SetFont(STANDARD_TEXT_FONT or PP.TITLE_FONT, 11, "")
            row.button:SetPoint("RIGHT", -8, 0)
            panel.cards[i] = row
        end
        row.entry = entry
        row.item:SetText(entry.title)
        row.action:SetText(entry.page == "Keep" and entry.reason or entry.action or "")
        row.auction:SetText(entry.auction or "")
        row.vendor:SetText(entry.vendor or "")
        local prepared = entry.page == "Auction" and preparedRow and entry.link == preparedRow.link
            and entry.qty == preparedRow.qty and entry.listed == preparedRow.listed
        row.button:SetText(prepared and "Create Auction" or entry.button or "")
        row.button:SetShown(entry.button ~= nil)
        row.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:Show()
    end
    for i = #entries + 1, #panel.cards do panel.cards[i]:Hide() end
    panel.body:SetHeight(math.max(1, #entries * 32))
end
refresh = function()
    if not PP.db then return end
    local pct = tonumber(panel.percent:GetText()) or 50
    pct = math.max(0, min(100, floor(pct)))
    PP.db.auctionTestPercent = pct
    local char = UnitName("player") .. "-" .. GetRealmName()
    PP.db.ledgerStockPlans = PP.db.ledgerStockPlans or {}
    local plan = PP.db.ledgerStockPlans[char]
    if not plan or plan.percent ~= pct then
        plan = { percent = pct, keep = {} }
        PP.db.ledgerStockPlans[char] = plan
    end
    panel.percent:SetText(tostring(pct))
    wanted = {}
    local bags, rows = {}, {}
    for bag = 0, NUM_BAG_SLOTS + (NUM_REAGENTBAG_SLOTS or 0) do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = read(C_Container.GetContainerItemInfo, bag, slot)
            if item and item.hyperlink and not blacklist()[item.itemID] and not item.isLocked and not isQuestItem(bag, slot) then
                local bound = item.isBound == true
                local location = ItemLocation:CreateFromBagAndSlot(bag, slot)
                if bound or read(C_Item.CanBeAuctioned, location) ~= false then
                    local key = bound and ("bound:" .. item.hyperlink) or item.hyperlink
                    local row = bags[key]
                    if not row then
                        local name, vendor = itemDetails(item.hyperlink)
                        local net, listed
                        if not bound then net, listed = price(item.hyperlink) end
                        row = { id = item.itemID, link = item.hyperlink, key = key, bound = bound, count = 0,
                            name = name, vendor = item.hasNoValue and 0 or vendor, net = net, listed = listed }
                        bags[key] = row
                        rows[#rows + 1] = row
                    end
                    row.count = row.count + item.stackCount
                end
            end
        end
    end
    local reserve, stock, market = {}, {}, {}
    for _, def in ipairs(PP.professions) do
        local skill = PP:GetSkill(def)
        local step = skill and skill > 0 and PP:StepFor(def, skill)
        for _, mat in ipairs(step and step.mats or {}) do
            local needed = PP.CraftsFor(step, skill, step.to) * (mat[2] or 1)
            reserve[mat[1]] = (reserve[mat[1]] or 0) + needed
        end
    end
    table.sort(rows, function(a, b)
        local gainA = math.max(0, (a.net or 0) - (a.vendor or 0)) * a.count
        local gainB = math.max(0, (b.net or 0) - (b.vendor or 0)) * b.count
        if gainA ~= gainB then return gainA > gainB end
        return a.link < b.link
    end)
    for _, row in ipairs(rows) do
        local held = reserve[row.id] or reserve[row.name] or 0
        row.spare = math.max(0, row.count - held)
        reserve[row.id] = math.max(0, held - row.count)
        local keep = plan.keep[row.key]
        if keep == nil then
            local offer = row.bound and row.spare == 1 and pct > 0 and 1 or floor(row.spare * pct / 100)
            keep = row.spare - offer
            plan.keep[row.key] = keep
        end
        row.offer = math.max(0, row.spare - keep)
        if not (row.bound and row.spare == 1 and pct > 0) then
            row.offer = min(row.offer, floor(row.spare * pct / 100))
        end
        if not row.bound then stock[row.id] = (stock[row.id] or 0) + row.offer end
        if row.net and row.vendor then market[row.id] = math.max(row.net, row.vendor) end
    end

    local crafts = {}
    local ui = C_TradeSkillUI
    local known = PP.db.recipeIDs and PP.db.recipeIDs[char]
    for name, id in pairs(known or {}) do
        local output = read(ui and ui.GetRecipeItemLink, id)
        local schematic = read(ui and ui.GetRecipeSchematic, id, false)
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
                local info = read(ui.GetProfessionInfoByRecipeID, id)
                local profKey
                for _, def in ipairs(PP.professions) do
                    if info and (def.skillLine == info.professionID or def.skillLine == info.skillLineID) then
                        profKey = def.key
                        break
                    end
                end
                crafts[#crafts + 1] = { name = name, costs = costs, gain = net * schematic.quantityMin - cost,
                    outputPrice = outputPrice, itemID = tonumber(output:match("item:(%d+)")), profKey = profKey }
            end
        end
    end
    table.sort(crafts, function(a, b)
        if a.gain == b.gain then return a.name < b.name end
        return a.gain > b.gain
    end)
    local allocated, lines = {}, {}
    for _, craft in ipairs(crafts) do
        local count = math.huge
        for id, need in pairs(craft.costs) do count = min(count, floor((stock[id] or 0) / need)) end
        if count > 0 then
            for id, need in pairs(craft.costs) do
                stock[id] = stock[id] - count * need
                allocated[id] = (allocated[id] or 0) + count * need
            end
            if page == "Craft" then
                lines[#lines + 1] = { title = craft.name .. " ×" .. count, page = "Craft",
                    action = "Craft", auction = "+" .. money(count * craft.gain),
                    qty = count, costs = craft.costs, outputPrice = craft.outputPrice,
                    button = "Craft it", recipe = {name = craft.name, id = craft.itemID, profKey = craft.profKey} }
            end
        elseif page == "Craft" then
            lines[#lines + 1] = {title = craft.name, page = "Craft", action = "Materials",
                auction = "+" .. money(craft.gain), qty = 1, costs = craft.costs,
                outputPrice = craft.outputPrice, button = "Materials"}
        end
    end

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
        local category = (action == "Auction" or action == "Vendor") and action or "Keep"
        if category == page and (used == 0 or qty > 0 or row.count > used) then
            local reason = "Stock limit"
            if used > 0 then reason = "For crafting"
            elseif row.spare < row.count then reason = "For your guide"
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
    if #lines == 0 then lines[1] = { title = "No " .. page:lower() .. " picks" } end
    if page == "Blacklist" then
        lines = {}
        for id, name in pairs(blacklist()) do
            lines[#lines + 1] = {id = id, title = name, page = "Blacklist", button = "Restore"}
        end
        table.sort(lines, function(a, b) return a.title < b.title end)
        if #lines == 0 then lines[1] = {title = "No blacklisted items"} end
    end
    display(lines)
end
local queue, index, current, generation
generation = 0
local function advance()
    if not open or not queue then return end
    if ah.IsThrottledMessageSystemReady and not read(ah.IsThrottledMessageSystemReady) then
        local scan = generation
        C_Timer.After(0.4, function() if generation == scan then advance() end end)
        return
    end
    index = index + 1
    current = queue[index]
    if not current then
        queue = nil
        refresh()
        panel.status:SetText("Scan complete. Prices are based on current listings.")
        return
    end
    panel.status:SetText(("Checking prices %d / %d"):format(index, #queue))
    if blacklist()[current.key.itemID] then
        current = nil
        local scan = generation
        C_Timer.After(0, function() if generation == scan then advance() end end)
        return
    end
    local ok = pcall(ah.SendSearchQuery, current.key, {}, true)
    local scan, request = generation, current
    C_Timer.After(ok and 4 or 0.4, function()
        if generation == scan and current == request then
            current = nil
            advance()
        end
    end)
end

local function scan()
    if queue then return end
    if not open then panel.status:SetText("Open the Auction House to scan prices."); return end
    if not ah or not ah.SendSearchQuery then
        panel.status:SetText("Auction House search is unavailable.")
        return
    end

    if PP.db.ledgerStockPlans then
        local char = UnitName("player") .. "-" .. GetRealmName()
        PP.db.ledgerStockPlans[char] = nil
    end
    refresh()
    queue, index = {}, 0
    for signature, key in pairs(wanted) do queue[#queue + 1] = {signature = signature, key = key} end
    if #queue == 0 then
        queue = nil
        panel.status:SetText("No items to scan.")
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
                value = value / math.max(1, row.quantity or 1)
                best = min(best or value, value)
            end
        end
    end
    savedPrices()[current.signature] = best and floor(best) or nil
    current = nil
    local scan = generation
    C_Timer.After(0.35, function() if generation == scan then advance() end end)
end
local function build()
    panel = PP.UIWindow("ProfessionPalAuctionWindow", 720, "Market Ledger")
    panel:SetSize(PP.db.ledgerWidth or 720, PP.db.ledgerHeight or 520)
    panel:SetResizable(true)
    panel:SetResizeBounds(570, 320, 1050, 800)
    panel:SetScale(PP.db.ledgerScale or 1)
    local scale = PP.UIButton(panel, "Scale", 68, 28, function(self)
        local nextScale = (PP.db.ledgerScale or 1) + 0.1
        if nextScale > 1.21 then nextScale = 0.8 end
        PP.db.ledgerScale = nextScale
        panel:SetScale(nextScale)
        self:SetText(("%.0f%%"):format(nextScale * 100))
    end)
    scale:SetText(("%.0f%%"):format((PP.db.ledgerScale or 1) * 100))
    scale:SetPoint("TOPRIGHT", -126, -49)
    local clear = PP.UIButton(panel, "Clear Prices", 96, 25, function()
        if queue then panel.status:SetText("Wait for the scan to finish."); return end
        wipe(savedPrices())
        refresh()
        panel.status:SetText("Saved prices cleared.")
    end)
    clear:SetPoint("TOPRIGHT", -18, -106)
    local grip = PP.UIButton(panel, "↘", 23, 20)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetScript("OnMouseDown", function() panel:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        panel:StopMovingOrSizing()
        PP.db.ledgerWidth, PP.db.ledgerHeight = panel:GetSize()
    end)
    panel:SetPoint("CENTER", UIParent, "CENTER", 265, 0)
    panel:SetFrameStrata("DIALOG")
    local refreshButton = PP.UIButton(panel, "Scan Bags", 100, 28, scan)
    refreshButton:SetPoint("TOPRIGHT", -18, -49)
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
    panel.status = PP.UIText(panel, 14, PP.C.muted or PP.C.white)
    panel.status:SetPoint("TOPLEFT", 18, -86)
    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -166)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    panel.body = CreateFrame("Frame", nil, scroll)
    panel.body:SetSize(panel:GetWidth() - 54, 1)
    panel:SetScript("OnSizeChanged", function(_, width) panel.body:SetWidth(width - 54) end)
    local header = CreateFrame("Frame", nil, panel)
    header:SetPoint("TOPLEFT", 18, -138)
    header:SetPoint("TOPRIGHT", -36, -138)
    header:SetHeight(25)
    columns(header)
    header.item:SetText("Item")
    header.action:SetText("Plan")
    header.auction:SetText("AH net / gain")
    header.vendor:SetText("Vendor")
    scroll:SetScrollChild(panel.body)
    panel.cards = {}
    local tabs = {}
    for index, name in ipairs({"Auction", "Vendor", "Craft", "Keep", "Blacklist"}) do
        local tab = PP.UIButton(panel, name, 80, 25, function()
            page = name
            header.action:SetText(name == "Keep" and "Reason" or "Plan")
            for label, button in pairs(tabs) do button:SetSelected(label == page) end
            scroll:SetVerticalScroll(0)
            refresh()
        end)
        tab:SetPoint("TOPLEFT", 18 + (index - 1) * 85, -106)
        tab:SetSelected(name == page)
        tabs[name] = tab
    end
end
local events = CreateFrame("Frame")
events:RegisterEvent("AUCTION_HOUSE_SHOW")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("AUCTION_HOUSE_CLOSED")
events:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
events:RegisterEvent("ITEM_SEARCH_RESULTS_UPDATED")
events:SetScript("OnEvent", function(_, event, key)
    if event == "COMMODITY_SEARCH_RESULTS_UPDATED" or event == "ITEM_SEARCH_RESULTS_UPDATED" then
        receive(event, key)
        return
    end
    if event == "MERCHANT_SHOW" or event == "MERCHANT_CLOSED" then
        merchant = event == "MERCHANT_SHOW"
        return
    end
    if event == "BAG_UPDATE_DELAYED" then
        if panel and panel:IsShown() then refresh() end
        return
    end
    open = event == "AUCTION_HOUSE_SHOW"
    if not open then
        generation = generation + 1
        queue, current = nil, nil
        preparedRow, submitPrepared = nil, nil
        prepareRequest = prepareRequest + 1
        if panel then panel:Hide() end
    end
end)
SLASH_PROFESSIONPALBAGPRICES1 = "/ppauction"
function PP:ToggleMarketLedger()
    if not PP.db then return end

    if panel and panel:IsShown() then panel:Hide(); return end
    if not panel then build() end
    panel:Show()
    refresh()
    if not queue then
        panel.status:SetText(open and "Saved prices shown. Scan Bags to refresh." or "Saved prices shown. Refresh at the Auction House.")
    end
end
SlashCmdList.PROFESSIONPALBAGPRICES = function() PP:ToggleMarketLedger() end
