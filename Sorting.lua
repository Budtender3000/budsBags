local _, addon = ...
addon.Sorting = {}
local S = addon.Sorting

local f = CreateFrame("Frame")
f:Hide()
local sortMoves = {}
local timer = 0
local isSorting = false

local function GetItemData(bag, slot)
    -- WotLK 3.3.5a API
    local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
    if not link then return nil end
    local name, itemLink, rarity, ilvl, reqLevel, itype, isubtype, maxStack, equipSlot, icon, vendorPrice = GetItemInfo(link)
    local catId = addon.Categories:GetItemCategory(bag, slot, link)
    
    -- We need order for sorting later.
    local catOrder = addon.Categories.OrderMap[catId] or 100

    -- Return table with all data needed for sorting
    return {
        bag = bag, slot = slot, link = link, name = name or "Unknown", count = count or 0,
        maxStack = maxStack or 1, locked = locked, catId = catId, catOrder = catOrder,
        rarity = rarity or 0, ilvl = ilvl or 0
    }
end

-- Compare function for sorting items
local function CompareItems(a, b)
    -- 1. By Category (lowest order first)
    if a.catOrder ~= b.catOrder then
        return a.catOrder < b.catOrder
    end
    -- 2. By Quality (highest rarity first)
    if a.rarity ~= b.rarity then
        return a.rarity > b.rarity
    end
    -- 3. By Item Level (highest first)
    if a.ilvl ~= b.ilvl then
        return a.ilvl > b.ilvl
    end
    -- 4. By Name (alphabetical)
    return a.name < b.name
end

function S:SortBags()
    if isSorting then return end
    
    sortMoves = {}
    local items = {}
    local emptySlots = {}
    
    -- 1. Gather all items and empty slots
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local data = GetItemData(bag, slot)
            if data then
                if data.locked then
                    -- If any item is locked, we abort sorting to prevent getting stuck
                    print("|cFFFF0000budsBags:|r Sortierung abgebrochen: Gegenstand gelockt. Bitte warten oder UI reloaden.")
                    return
                end
                table.insert(items, data)
            else
                table.insert(emptySlots, {bag = bag, slot = slot})
            end
        end
    end
    
    -- Stack items together
    local function GetItemID(link)
        return link and tonumber(link:match("item:(%d+)"))
    end

    for i = 1, #items do
        for j = i + 1, #items do
            local a = items[i]
            local b = items[j]
            if GetItemID(a.link) == GetItemID(b.link) and a.maxStack > 1 and a.count < a.maxStack and b.count < b.maxStack then
                table.insert(sortMoves, {src = {bag=b.bag, slot=b.slot}, dst = {bag=a.bag, slot=a.slot}})
                -- Predicting the stack merge
                local space = a.maxStack - a.count
                if b.count <= space then
                    a.count = a.count + b.count
                    b.count = 0
                else
                    a.count = a.maxStack
                    b.count = b.count - space
                end
            end
        end
    end
    
    -- Remove empty items from the list that were fully stacked into others
    for i = #items, 1, -1 do
        if items[i].count == 0 then
            table.remove(items, i)
        end
    end

    -- 3. Logical Sort
    table.sort(items, CompareItems)
    
    -- 4. Map Target Positions
    -- We want to place `items` sequentially into all available slots (0,1 -> 0,2 -> ...)
    local targetSlots = {}
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            table.insert(targetSlots, {bag = bag, slot = slot})
        end
    end
    
    -- 5. Generate Move Commands for Ordering
    -- Simple approach: For each item in its logical sorted order, figure out where it is,
    -- and move it to where it should be (targetSlots). 
    -- Note: Doing this cleanly in the WoW API is very complex because moving items swaps them.
    -- To keep it performant for the MVP, we only stack first. This is phase 1.
    -- Real sorting algorithms that deal with swapping need a virtual inventory map to track state.
    
    -- We will build a virtual map to track current locations
    local currentMap = {}
    for _, item in ipairs(items) do
        currentMap[item.bag .. "_" .. item.slot] = item
    end
    
    for i, targetItem in ipairs(items) do
        local targetPos = targetSlots[i]
        
        -- If the item is not already at its target position
        if targetItem.bag ~= targetPos.bag or targetItem.slot ~= targetPos.slot then
             -- Find what is currently at the target position
             local occupant = currentMap[targetPos.bag .. "_" .. targetPos.slot]
             
             -- Generate a move: from targetItem's current location TO the target position
             table.insert(sortMoves, {src = {bag=targetItem.bag, slot=targetItem.slot}, dst = {bag=targetPos.bag, slot=targetPos.slot}})
             
             -- Update virtual map (they swap in WOW)
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
    if timer > 0.05 then -- 50ms delay
        timer = 0
        
        local move = table.remove(sortMoves, 1)
        if move then
            local _, _, locked1 = GetContainerItemInfo(move.src.bag, move.src.slot)
            local _, _, locked2 = GetContainerItemInfo(move.dst.bag, move.dst.slot)
            
            if not locked1 and not locked2 then
                ClearCursor() -- Security hook
                PickupContainerItem(move.src.bag, move.src.slot)
                PickupContainerItem(move.dst.bag, move.dst.slot)
                
                -- Explicitly intercept overflow buffers directly to origin
                if CursorHasItem() then
                    PickupContainerItem(move.src.bag, move.src.slot)
                end
            else
                -- Put back in queue and wait for unlock
                table.insert(sortMoves, 1, move)
            end
        else
            self:Hide()
            isSorting = false
            print("|cFF00FF00budsBags:|r Sortieren abgeschlossen.")
            if addon.UI and addon.UI.MainFrame:IsShown() then
                addon.UI:UpdateAllBags()
            end
        end
    end
end)
