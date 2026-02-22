local addonName, addon = ...
addon.UI = addon.UI or {}
local UI = addon.UI

UI.MainFrame = nil
UI.ItemButtons = {}
UI.BagFrames = {}
UI.CategoryFrames = {}

function UI:Initialize()
    self:CreateMainFrame()
    self:HookStandardBags()
end

function UI:CreateMainFrame()
    local f = CreateFrame("Frame", "budsBagsMainFrame", UIParent)
    f:SetSize(600, 600)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)
    f:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("budsBags")
    
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    local sortBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    sortBtn:SetSize(80, 22)
    sortBtn:SetPoint("TOPLEFT", 10, -10)
    sortBtn:SetText("Sort")
    sortBtn:SetScript("OnClick", function() addon.Sorting:SortBags() end)
    
    self.MainFrame = f
    
    -- Hidden bag parent frames so standard Container functionality works.
    for bag = 0, 4 do
        local bagFrame = CreateFrame("Frame", "budsBags_Bag"..bag, f)
        bagFrame:SetID(bag)
        self.BagFrames[bag] = bagFrame
    end
    
    tinsert(UISpecialFrames, "budsBagsMainFrame")
end

function UI:HookStandardBags()
    local oToggleBackpack = ToggleBackpack
    ToggleBackpack = function()
        if UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
        else
            UI.MainFrame:Show()
            UI:UpdateAllBags()
        end
    end
    
    local oOpenAllBags = OpenAllBags
    OpenAllBags = function(...)
        if not UI.MainFrame:IsShown() then
            UI.MainFrame:Show()
            UI:UpdateAllBags()
        elseif UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
        end
    end
    
    local oCloseAllBags = CloseAllBags
    CloseAllBags = function(...)
        if UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
        end
        return oCloseAllBags(...)
    end
end

function UI:GetItemButton(bag, slot)
    local buttonId = bag .. "_" .. slot
    if not self.ItemButtons[buttonId] then
        local bagFrame = self.BagFrames[bag]
        local btn = CreateFrame("Button", "budsBags_Item_"..bag.."_"..slot, bagFrame, "ContainerFrameItemButtonTemplate")
        btn:SetID(slot)
        
        local font = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        font:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        font:SetTextColor(1, 1, 0)
        btn.iLvlText = font
        
        self.ItemButtons[buttonId] = btn
    end
    return self.ItemButtons[buttonId]
end

function UI:GetCategoryFrame(catId, catName)
    if not self.CategoryFrames[catId] then
        local cf = CreateFrame("Frame", nil, self.MainFrame)
        local fs = cf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 0, 0)
        fs:SetText(catName)
        cf.Title = fs
        cf.items = {}
        self.CategoryFrames[catId] = cf
    end
    self.CategoryFrames[catId].items = {}
    return self.CategoryFrames[catId]
end

function UI:UpdateAllBags()
    for _, btn in pairs(self.ItemButtons) do
        btn:Hide()
    end
    for _, cf in pairs(self.CategoryFrames) do
        cf:Hide()
    end
    
    local catMap = {}
    
    for bag = 0, 4 do
        local maxSlots = GetContainerNumSlots(bag)
        for slot = 1, maxSlots do
            local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot)
            
            local btn = self:GetItemButton(bag, slot)
            btn:Show()
            
            SetItemButtonTexture(btn, texture)
            SetItemButtonCount(btn, itemCount)
            SetItemButtonDesaturated(btn, locked)
            
            btn.iLvlText:SetText("")
            local catId = "OTHER"
            if itemLink then
                local level = select(4, GetItemInfo(itemLink))
                if level and level > 1 then
                    btn.iLvlText:SetText(level)
                end
                catId = addon.Categories:GetItemCategory(bag, slot)
            end
            
            if not texture then
                btn:SetNormalTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
                btn.iLvlText:SetText("")
                catId = "OTHER" 
            else
                btn:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
            end
            
            if not catMap[catId] then catMap[catId] = {} end
            table.insert(catMap[catId], btn)
            
            if GameTooltip:IsOwned(btn) then
                if texture and ContainerFrameItemButton_OnEnter then
                    ContainerFrameItemButton_OnEnter(btn)
                else
                    GameTooltip:Hide()
                end
            end
        end
    end
    
    self:LayoutCategories(catMap)
end

function UI:LayoutCategories(catMap)
    local startX = 15
    local currentY = -40
    local buttonSize = 37
    local spacing = 4
    local columns = 12
    
    for _, catData in ipairs(addon.Categories.Groups) do
        local catId = catData.id
        local items = catMap[catId]
        
        if items and #items > 0 then
            local catFrame = self:GetCategoryFrame(catId, catData.name)
            catFrame:Show()
            catFrame:SetPoint("TOPLEFT", self.MainFrame, "TOPLEFT", startX, currentY)
            
            local col, row = 0, 0
            for i, btn in ipairs(items) do
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", catFrame, "TOPLEFT", col * (buttonSize + spacing), -(row * (buttonSize + spacing)) - 15)
                
                col = col + 1
                if col >= columns then
                    col, row = 0, row + 1
                end
            end
            
            currentY = currentY - ((row + (col > 0 and 1 or 0)) * (buttonSize + spacing)) - 35
        end
    end
    
    if catMap["OTHER"] and #catMap["OTHER"] > 0 then
        local catFrame = self:GetCategoryFrame("OTHER", "Freie Plätze / Sonstiges")
        catFrame:Show()
        catFrame:SetPoint("TOPLEFT", self.MainFrame, "TOPLEFT", startX, currentY)
        
        local col, row = 0, 0
        for i, btn in ipairs(catMap["OTHER"]) do
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", catFrame, "TOPLEFT", col * (buttonSize + spacing), -(row * (buttonSize + spacing)) - 15)
            col = col + 1
            if col >= columns then
                col, row = 0, row + 1
            end
        end
        currentY = currentY - ((row + (col > 0 and 1 or 0)) * (buttonSize + spacing)) - 35
    end
    
    self.MainFrame:SetHeight(abs(currentY) + 20)
end
