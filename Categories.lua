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

function C:GetItemCategory(bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    if not itemLink then return "OTHER" end
    
    local _, _, rarity, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(itemLink)
    if not itemType then return "OTHER" end
    -- Grey items are trash
    if rarity == 0 then
        return "TRASH"
    end
    
    -- Quest items
    if itemType == "Quest" then
        return "QUEST"
    end
    
    -- Rüstung & Waffen
    if itemType == _G.ARMOR or itemType == _G.ENCHSLOT_WEAPON or itemType == "Rüstung" or itemType == "Waffe" or itemType == "Armor" or itemType == "Weapon" or (itemEquipLoc and itemEquipLoc ~= "") then
        return "GEAR"
    end
    
    -- Verbrauchsgüter
    if itemType == "Verbrauchsmaterial" or itemType == "Consumable" then
        return "CONSUMABLE"
    end
    
    -- Handwerk
    if itemType == "Handwerkswaren" or itemType == "Trade Goods" or itemType == "Reagenzie" or itemType == "Reagent" or itemType == "Juwelenschleifen" or itemType == "Gem" or itemType == "Rezept" or itemType == "Recipe" then
        return "TRADEGOODS"
    end
    
    return "OTHER"
end
