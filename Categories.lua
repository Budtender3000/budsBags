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
    
    local _, _, rarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemType then return "OTHER" end
    
    if rarity == 0 then return "TRASH" end
    
    if itemType == (_G.ITEM_CLASSES and _G.ITEM_CLASSES[12]) or itemType == "Quest" or itemType == "Questgegenstand" then 
        return "QUEST" 
    end
    
    if itemType == _G.ARMOR or itemType == _G.ENCHSLOT_WEAPON or itemType == "Rüstung" or itemType == "Waffe" or itemType == "Armor" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "") then
        return "GEAR"
    end
    
    if itemType == (_G.ITEM_CLASSES and _G.ITEM_CLASSES[0]) or itemType == "Consumable" or itemType == "Verbrauchsmaterial" then 
        return "CONSUMABLE" 
    end
    
    if itemType == (_G.ITEM_CLASSES and _G.ITEM_CLASSES[7]) or itemType == "Trade Goods" or itemType == "Handwerkswaren" or itemType == "Reagenzie" or itemType == "Reagent" or itemType == "Juwelenschleifen" or itemType == "Gem" or itemType == "Rezept" or itemType == "Recipe" then 
        return "TRADEGOODS" 
    end
    
    return "OTHER"
end
