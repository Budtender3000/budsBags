local _, addon = ...
addon.Sorting = {}
local S = addon.Sorting

local f = CreateFrame("Frame")
f:Hide()
local sortMoves = {}
local timer = 0
local isSorting = false
local currentMoveIndex = 1

local function GetItemData(bag, slot)
    local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
    if not link then return nil end
    local name, itemLink, rarity, ilvl, reqLevel, itype, isubtype, maxStack, equipSlot, icon, vendorPrice = GetItemInfo(link)
    local catId = addon.Categories:GetItemCategory(bag, slot, link)
    
    local catOrder = addon.Categories.OrderMap[catId] or 100

    return {
        bag = bag, slot = slot, link = link, name = name or "Unknown", count = count or 0,
        maxStack = maxStack or 1, locked = locked, catId = catId, catOrder = catOrder,
        rarity = rarity or 0, ilvl = ilvl or 0
    }
end

local function CompareItems(a, b)
    if a.catOrder ~= b.catOrder then return a.catOrder < b.catOrder end
    if a.rarity ~= b.rarity then return a.rarity > b.rarity end
    if a.ilvl ~= b.ilvl then return a.ilvl > b.ilvl end
    return a.name < b.name
end

function S:SortBags()
    if isSorting then return end
    
    sortMoves = {}
    currentMoveIndex = 1
    local items = {}
    local emptySlots = {}
    
    local atBank = addon.UI.MainFrame and addon.UI.MainFrame.BankBagBar and addon.UI.MainFrame.BankBagBar:IsShown()
    local iterStart = atBank and -1 or 0
    local iterEnd = atBank and 11 or 4
    
    for bag = iterStart, iterEnd do
        local maxSlots = GetContainerNumSlots(bag)
        if bag == -1 then maxSlots = 28 end
        for slot = 1, maxSlots do
            local data = GetItemData(bag, slot)
            if data then
                if data.locked then
                    print("|cFFFF0000budsBags:|r Sortierung abgebrochen: Gegenstand gelockt. Bitte warten oder UI reloaden.")
                    return
                end
                table.insert(items, data)
            else
                table.insert(emptySlots, {bag = bag, slot = slot})
            end
        end
    end
    
    local function GetItemID(link)
        return link and tonumber(link:match("item:(%d+)"))
    end

    local incompleteStacks = {}
    for i = 1, #items do
        local item = items[i]
        local itemID = GetItemID(item.link)
        if itemID and item.maxStack > 1 and item.count < item.maxStack then
            local targets = incompleteStacks[itemID]
            if targets then
                for _, targetIndex in ipairs(targets) do
                    local tItem = items[targetIndex]
                    if tItem.count < tItem.maxStack and item.count > 0 then
                        table.insert(sortMoves, {src = {bag=item.bag, slot=item.slot}, dst = {bag=tItem.bag, slot=tItem.slot}})
                        local space = tItem.maxStack - tItem.count
                        if item.count <= space then
                            tItem.count = tItem.count + item.count
                            item.count = 0
                        else
                            tItem.count = tItem.maxStack
                            item.count = item.count - space
                        end
                    end
                end
            end
            if item.count > 0 and item.count < item.maxStack then
                incompleteStacks[itemID] = incompleteStacks[itemID] or {}
                table.insert(incompleteStacks[itemID], i)
            end
        end
    end
    
    for i = #items, 1, -1 do
        if items[i].count == 0 then
            table.remove(items, i)
        end
    end

    table.sort(items, CompareItems)
    
    local targetSlots = {}
    for bag = iterStart, iterEnd do
        local maxSlots = GetContainerNumSlots(bag)
        if bag == -1 then maxSlots = 28 end
        for slot = 1, maxSlots do
            table.insert(targetSlots, {bag = bag, slot = slot})
        end
    end
    
    local currentMap = {}
    for _, item in ipairs(items) do
        currentMap[item.bag .. "_" .. item.slot] = item
    end
    
    for i, targetItem in ipairs(items) do
        local targetPos = targetSlots[i]
        
        if targetItem.bag ~= targetPos.bag or targetItem.slot ~= targetPos.slot then
             local occupant = currentMap[targetPos.bag .. "_" .. targetPos.slot]
             table.insert(sortMoves, {src = {bag=targetItem.bag, slot=targetItem.slot}, dst = {bag=targetPos.bag, slot=targetPos.slot}})
             currentMap[targetItem.bag .. "_" .. targetItem.slot] = occupant
             if occupant then
                 occupant.bag = targetItem.bag
                 occupant.slot = targetItem.slot
             end
             
             targetItem.bag = targetPos.bag
             targetItem.slot = targetPos.slot
             currentMap[targetPos.bag .. "_" .. targetPos.slot] = targetItem
        end
    end

    if #sortMoves > 0 then
        print("|cFF00FF00budsBags:|r Inventar wird sortiert...")
        isSorting = true
        timer = 0
        f:Show()
    else
        print("|cFF00FF00budsBags:|r Gegenstände sind bereits sortiert.")
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
    if not isSorting then
        self:Hide()
        return
    end
    
    timer = timer + elapsed
    if timer > 0.05 then
        timer = 0
        
        local move = sortMoves[currentMoveIndex]
        if move then
            local _, _, locked1 = GetContainerItemInfo(move.src.bag, move.src.slot)
            local _, _, locked2 = GetContainerItemInfo(move.dst.bag, move.dst.slot)
            
            if CursorHasItem() then
                -- Wait for user to drop item
                return
            end
            
            if not locked1 and not locked2 then
                ClearCursor()
                PickupContainerItem(move.src.bag, move.src.slot)
                PickupContainerItem(move.dst.bag, move.dst.slot)
                
                if CursorHasItem() then
                    PickupContainerItem(move.src.bag, move.src.slot)
                end
                currentMoveIndex = currentMoveIndex + 1
            else
                -- Ignore this tick, wait for items to unlock since we're not removing elements anymore
            end
        else
            self:Hide()
            isSorting = false
            currentMoveIndex = 1
            print("|cFF00FF00budsBags:|r Sortieren abgeschlossen.")
            if addon.UI and addon.UI.MainFrame:IsShown() then
                addon.UI:UpdateAllBags()
            end
        end
    end
end)
