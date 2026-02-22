local _, addon = ...
addon.Categories = {}
local C = addon.Categories

C.Groups = {
    { id = "GEAR", name = "Ausrüstung", order = 1 },
    { id = "CONSUMABLE", name = "Verbrauchsgüter", order = 2 },
    { id = "TRADEGOODS", name = "Handwerkswaren", order = 3 },
    { id = "QUEST", name = "Quest-Gegenstände", order = 4 },
    { id = "TRASH", name = "Müll", order = 5 },
    { id = "OTHER", name = "Sonstiges", order = 6 },
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
    
    -- Rüstung & Waffen
    if itemType == "Rüstung" or itemType == "Waffe" or itemType == "Armor" or itemType == "Weapon" then
        return "GEAR"
    -- Verbrauchsgüter
    elseif itemType == "Verbrauchsmaterial" or itemType == "Consumable" or itemType == "Trank" or itemType == "Flask" then
        return "CONSUMABLE"
    -- Handwerk
    elseif itemType == "Handwerkswaren" or itemType == "Trade Goods" or itemType == "Reagenzie" or itemType == "Reagent" or itemType == "Juwelenschleifen" or itemType == "Gem" then
        return "TRADEGOODS"
    -- Quest items
    elseif itemType == "Quest" then
        return "QUEST"
    else
        return "OTHER"
    end
end
