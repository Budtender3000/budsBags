local addonName, addon = ...
addon.UI = addon.UI or {}
local UI = addon.UI

UI.MainFrame = nil
UI.ItemButtons = {}
UI.BagFrames = {}
UI.CategoryFrames = {}

local T = {
    backdrop = {
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    },
    backdropColor = {0.05, 0.05, 0.05, 0.85},
    borderColor = {0, 0, 0, 1},
    font = "Fonts\\ARIALN.TTF",
    blue = {0.22, 0.55, 0.86} -- budsUI branding blue
}

function UI:Initialize()
    self:CreateMainFrame()
    self:HookStandardBags()
end

function UI:CreateMainFrame()
    local f = CreateFrame("Frame", "budsBagsMainFrame", UIParent)
    f:SetFrameStrata("HIGH")
    f:SetPoint("CENTER")
    f:SetBackdrop(T.backdrop)
    f:SetBackdropColor(unpack(T.backdropColor))
    f:SetBackdropBorderColor(unpack(T.borderColor))
    
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont(T.font, 14, "OUTLINE")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("budsBags")
    title:SetTextColor(unpack(T.blue))
    
    local closeBtn = CreateFrame("Button", "budsBags_CloseButton", f, "UIPanelCloseButton")
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    local moneyFrame = CreateFrame("Frame", "budsBagsMoneyFrame", f, "SmallMoneyFrameTemplate")
    moneyFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 10)
    SmallMoneyFrame_OnLoad(moneyFrame)
    MoneyFrame_SetType(moneyFrame, "PLAYER")
    f:SetScript("OnShow", function()
        MoneyFrame_Update("budsBagsMoneyFrame", GetMoney())
    end)
    
    local sortBtn = CreateFrame("Button", nil, f)
    sortBtn:SetSize(60, 20)
    sortBtn:SetPoint("BOTTOMLEFT", 10, 8)
    sortBtn:SetBackdrop(T.backdrop)
    sortBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    sortBtn:SetBackdropBorderColor(unpack(T.borderColor))
    sortBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(T.blue)) end)
    sortBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
    local sortText = sortBtn:CreateFontString(nil, "OVERLAY")
    sortText:SetFont(T.font, 12, "OUTLINE")
    sortText:SetPoint("CENTER", 0, 0)
    sortText:SetText("Sort")
    sortBtn:SetScript("OnClick", function() addon.Sorting:SortBags() end)
    
    local optBtn = CreateFrame("Button", nil, f)
    optBtn:SetSize(60, 20)
    optBtn:SetPoint("LEFT", sortBtn, "RIGHT", 5, 0)
    optBtn:SetBackdrop(T.backdrop)
    optBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    optBtn:SetBackdropBorderColor(unpack(T.borderColor))
    optBtn:SetScript("OnEnter", function(self) self:SetBackdropColor(unpack(T.blue)) end)
    optBtn:SetScript("OnLeave", function(self) self:SetBackdropColor(0.15, 0.15, 0.15, 1) end)
    local optText = optBtn:CreateFontString(nil, "OVERLAY")
    optText:SetFont(T.font, 12, "OUTLINE")
    optText:SetPoint("CENTER", 0, 0)
    optText:SetText("Config")
    optBtn:SetScript("OnClick", function() InterfaceOptionsFrame_OpenToCategory(addon.Options.Panel) InterfaceOptionsFrame_OpenToCategory(addon.Options.Panel) end)
    
    self.MainFrame = f
    
    for bag = 0, 4 do
        local bagFrame = CreateFrame("Frame", "budsBags_Bag"..bag, f)
        bagFrame:SetID(bag)
        self.BagFrames[bag] = bagFrame
    end
    
    tinsert(UISpecialFrames, "budsBagsMainFrame")
end

function UI:HookStandardBags()
    hooksecurefunc("ToggleBackpack", function()
        if UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
        else
            UI.MainFrame:Show()
            UI:UpdateAllBags()
        end
    end)
    
    hooksecurefunc("OpenAllBags", function()
        if not UI.MainFrame:IsShown() then
            UI.MainFrame:Show()
            UI:UpdateAllBags()
        end
    end)
    
    hooksecurefunc("CloseAllBags", function()
        if UI.MainFrame:IsShown() then
            UI.MainFrame:Hide()
        end
    end)
    
    local hiddenParent = CreateFrame("Frame")
    hiddenParent:Hide()
    for i = 1, NUM_CONTAINER_FRAMES or 13 do
        if _G["ContainerFrame"..i] then
            _G["ContainerFrame"..i]:SetParent(hiddenParent)
        end
    end
end

function UI:GetItemButton(bag, slot)
    local buttonId = bag .. "_" .. slot
    if not self.ItemButtons[buttonId] then
        local btn = CreateFrame("Button", "budsBags_Item_"..bag.."_"..slot, self.MainFrame, "ContainerFrameItemButtonTemplate")
        btn:SetID(slot)
        
        btn:SetNormalTexture("")
        if btn:GetHighlightTexture() then
            btn:GetHighlightTexture():SetTexture(1, 1, 1, 0.3)
            btn:GetHighlightTexture():SetAllPoints()
        end
        if btn:GetPushedTexture() then
            btn:GetPushedTexture():SetTexture(0.9, 0.8, 0.1, 0.3)
            btn:GetPushedTexture():SetAllPoints()
        end

        btn:SetBackdrop(T.backdrop)
        btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
        btn:SetBackdropBorderColor(unpack(T.borderColor))
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetBagItem(bag, slot)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self, button)
            if button == "RightButton" then
                UseContainerItem(bag, slot)
            else
                PickupContainerItem(bag, slot)
            end
        end)
        
        local font = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        font:SetFont(T.font, 12, "OUTLINE")
        font:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        font:SetTextColor(1, 1, 0)
        btn.iLvlText = font
        
        local count = _G[btn:GetName().."Count"]
        if count then
            count:ClearAllPoints()
            count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            count:SetFont(T.font, 12, "OUTLINE")
        end

        local icon = _G[btn:GetName().."IconTexture"]
        if icon then
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
            icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
        end
        
        -- Default background for empty slots (using empty slot icon texture)
        local emptyTex = btn:CreateTexture(nil, "BACKGROUND")
        emptyTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
        emptyTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        emptyTex:SetAllPoints(btn)
        -- Keep track of it to hide/show when item is present
        btn.emptyTex = emptyTex
        
        self.ItemButtons[buttonId] = btn
    end
    return self.ItemButtons[buttonId]
end

function UI:GetCategoryFrame(catId, catName)
    if not self.CategoryFrames[catId] then
        local cf = CreateFrame("Frame", nil, self.MainFrame)
        cf:SetSize(200, 20)
        local fs = cf:CreateFontString(nil, "OVERLAY")
        fs:SetFont(T.font, 12, "OUTLINE")
        fs:SetPoint("LEFT", 0, 0)
        fs:SetTextColor(unpack(T.blue))
        fs:SetText(catName)
        cf.Title = fs
        cf.items = {}
        self.CategoryFrames[catId] = cf
    end
    self.CategoryFrames[catId].items = {}
    return self.CategoryFrames[catId]
end

local catMapPool = {}
local btnDataMapPool = {}

function UI:UpdateAllBags()
    local success, err = pcall(function()
        for _, btn in pairs(self.ItemButtons) do
            btn:Hide()
        end
        for _, cf in pairs(self.CategoryFrames) do
            cf:Hide()
        end
        
        wipe(catMapPool)
        
        local catMap = catMapPool
        local btnDataMap = btnDataMapPool
        local dataIdx = 1
        
        for bag = 0, 4 do
            local maxSlots = GetContainerNumSlots(bag)
            for slot = 1, maxSlots do
                local texture, itemCount, locked, quality, readable = GetContainerItemInfo(bag, slot)
                local itemLink = GetContainerItemLink(bag, slot)
                
                local btn = self:GetItemButton(bag, slot)
                btn:Show()
                
                if texture then
                    pcall(SetItemButtonTexture, btn, texture)
                    if _G[btn:GetName().."IconTexture"] then _G[btn:GetName().."IconTexture"]:Show() end
                    btn.emptyTex:Hide()
                else
                    if _G[btn:GetName().."IconTexture"] then _G[btn:GetName().."IconTexture"]:Hide() end
                    btn.emptyTex:Show()
                end
                
                pcall(SetItemButtonCount, btn, itemCount or 0)
                pcall(SetItemButtonDesaturated, btn, locked or false)
                
                btn.iLvlText:SetText("")
                local catId = "OTHER"
                local rarity = 0
                local name = "Unknown"
                
                if itemLink then
                    local itemName, _, itemQuality, itemLevel = GetItemInfo(itemLink)
                    name = itemName or name
                    rarity = itemQuality or 0
                    if itemLevel and itemLevel > 1 then
                        pcall(function() btn.iLvlText:SetText(itemLevel) end)
                    end
                    catId = addon.Categories:GetItemCategory(bag, slot)
                end
                
                if not texture then
                    catId = "EMPTY"
                    pcall(function() btn.iLvlText:SetText("") end)
                    rarity = -2
                    name = "ZZZ" 
                end
                
                -- Save rarity on button for border coloring
                btn.rarity = rarity
                
                if not catMap[catId] then catMap[catId] = {} end
                
                if not btnDataMap[dataIdx] then btnDataMap[dataIdx] = {} end
                local data = btnDataMap[dataIdx]
                data.btn = btn
                data.catId = catId
                data.rarity = rarity
                data.name = name
                
                dataIdx = dataIdx + 1
            end
        end
        
        for i = dataIdx, #btnDataMap do
            btnDataMap[i] = nil
        end
        
        table.sort(btnDataMap, function(a, b)
            if a.rarity ~= b.rarity then
                return a.rarity > b.rarity
            end
            return a.name < b.name
        end)
        
        for _, data in ipairs(btnDataMap) do
             table.insert(catMap[data.catId], data.btn)
        end
        
        self:LayoutCategories(catMap)
    end)
    
    if not success then
        print("|cFFFF0000budsBags Error in UpdateAllBags:|r", tostring(err))
    end
end

function UI:LayoutCategories(catMap)
    local startX = 10
    local startY = -35
    local currentY = startY
    local buttonSize = 34
    local spacing = 4
    -- Use user config column count or fallback to 10
    local columns = 10
    if addon.db and addon.db.profile and addon.db.profile.columns then
        columns = addon.db.profile.columns
    end
    
    local totalWidth = (startX * 2) + (columns * buttonSize) + ((columns - 1) * spacing)
    
    local function LayoutGroup(catId, catName, items)
        if not items or #items == 0 then return end
        
        local catFrame = self:GetCategoryFrame(catId, catName)
        catFrame:Show()
        catFrame:ClearAllPoints()
        catFrame:SetPoint("TOPLEFT", self.MainFrame, "TOPLEFT", startX, currentY)
        catFrame:SetWidth(totalWidth - (startX * 2))
        
        local rowOffset = 20
        local col, row = 0, 0
        
        for i, btn in ipairs(items) do
            btn:SetParent(catFrame)
            btn:ClearAllPoints()
            btn:SetSize(buttonSize, buttonSize)
            btn:SetPoint("TOPLEFT", catFrame, "TOPLEFT", col * (buttonSize + spacing), -(row * (buttonSize + spacing)) - rowOffset)
            
            -- Set button border based on item rarity
            local r, g, b = unpack(T.borderColor)
            if btn.rarity and btn.rarity > 1 then
                r, g, b = GetItemQualityColor(btn.rarity)
            end
            btn:SetBackdropBorderColor(r, g, b, 1)
            
            col = col + 1
            if col >= columns then
                col, row = 0, row + 1
            end
        end
        
        local heightUsed = rowOffset + ((row + (col > 0 and 1 or 0)) * (buttonSize + spacing))
        currentY = currentY - heightUsed - 5
    end
    
    for _, catData in ipairs(addon.Categories.Groups) do
        LayoutGroup(catData.id, catData.name, catMap[catData.id])
    end
    LayoutGroup("OTHER", "Other", catMap["OTHER"])
    LayoutGroup("EMPTY", "Empty Slots", catMap["EMPTY"])
    
    self.MainFrame:SetSize(totalWidth, math.abs(currentY) + 35)
end
