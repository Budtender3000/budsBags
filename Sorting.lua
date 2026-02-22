local _, addon = ...
addon.Sorting = {}
local S = addon.Sorting

local f = CreateFrame("Frame")
f:Hide()
local sortMoves = {}
local timer = 0

local function GetItemData(bag, slot)
    local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bag, slot)
    if not link then return nil end
    local name, _, rarity, ilvl, _, itype, isubtype, maxStack = GetItemInfo(link)
    local catId = addon.Categories:GetItemCategory(bag, slot)
    return {
        bag = bag, slot = slot, link = link, name = name, count = count,
        maxStack = maxStack or 1, locked = locked, catId = catId,
        rarity = rarity or 0, ilvl = ilvl or 0
    }
end

function S:SortBags()
    if f:IsShown() then return end
    
    sortMoves = {}
    local items = {}
    
    -- Gather items
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local data = GetItemData(bag, slot)
            if data and not data.locked then
                table.insert(items, data)
            end
        end
    end
    
    -- Stack items together
    for i = 1, #items do
        for j = i + 1, #items do
            local a = items[i]
            local b = items[j]
            if a.name == b.name and a.count < a.maxStack and b.count < b.maxStack then
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
    
    if #sortMoves > 0 then
        print("|cFF00FF00budsBags:|r Stapele Gegenstände...")
        timer = 0
        f:Show()
    else
        print("|cFF00FF00budsBags:|r Gegenstände sind bereits gestapelt. Visuelle Sortierung greift.")
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
    timer = timer + elapsed
    if timer > 0.1 then -- 100ms delay between moves to avoid locking
        timer = 0
        
        if CursorHasItem() then
            ClearCursor()
            return
        end
        
        local move = table.remove(sortMoves, 1)
        if move then
            local _, _, locked1 = GetContainerItemInfo(move.src.bag, move.src.slot)
            local _, _, locked2 = GetContainerItemInfo(move.dst.bag, move.dst.slot)
            
            if not locked1 and not locked2 then
                PickupContainerItem(move.src.bag, move.src.slot)
                PickupContainerItem(move.dst.bag, move.dst.slot)
            else
                -- Put back in queue if locked
                table.insert(sortMoves, move)
            end
        else
            self:Hide()
            print("|cFF00FF00budsBags:|r Stapeln abgeschlossen.")
            if addon.UI and addon.UI.MainFrame:IsShown() then
                addon.UI:UpdateAllBags()
            end
        end
    end
end)
