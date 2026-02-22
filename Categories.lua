local _, addon = ...
addon.Categories = {}
local C = addon.Categories

C.Groups = {
    { id = "GEAR", name = "Equipment", order = 1 },
    { id = "CONSUMABLE", name = "Consumables", order = 2 },
    { id = "TRADEGOODS", name = "Trade Goods", order = 3 },
    { id = "QUEST", name = "Quest Items", order = 4 },
    { id = "TRASH", name = "Junk", order = 5 },
    { id = "OTHER", name = "Other", order = 6 },
}

C.OrderMap = {}
for _, group in ipairs(C.Groups) do
    C.OrderMap[group.id] = group.order
end

function C:GetItemCategory(bag, slot, itemLink)
    itemLink = itemLink or GetContainerItemLink(bag, slot)
    if not itemLink then return "OTHER" end
    
    local itemID = tonumber(itemLink:match("item:(%d+)"))
    
    -- Check Custom Overrides First
    if itemID and addon.db and addon.db.profile and addon.db.profile.customCategories and addon.db.profile.customCategories[itemID] then
        return addon.db.profile.customCategories[itemID]
    end
    
    local _, _, rarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemType then return "OTHER" end
    
    if rarity == 0 then return "TRASH" end
    
    if itemType == "Quest" or itemType == "Questgegenstand" then 
        return "QUEST" 
    end
    
    if itemType == _G.ARMOR or itemType == _G.ENCHSLOT_WEAPON or itemType == "Rüstung" or itemType == "Waffe" or itemType == "Armor" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "") then
        return "GEAR"
    end
    
    if itemType == "Consumable" or itemType == "Verbrauchsmaterial" then 
        return "CONSUMABLE" 
    end
    
    if itemType == "Trade Goods" or itemType == "Handwerkswaren" or itemType == "Reagenzie" or itemType == "Reagent" or itemType == "Juwelenschleifen" or itemType == "Gem" or itemType == "Rezept" or itemType == "Recipe" then 
        return "TRADEGOODS" 
    end
    
    return "OTHER"
end
