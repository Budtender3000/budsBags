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
    f:SetResizable(true)
    f:SetMinResize(200, 200)
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

    local searchBox = CreateFrame("EditBox", "budsBagsSearchBox", f, "InputBoxTemplate")
    searchBox:SetSize(120, 20)
    searchBox:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -10, -3)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(20)
    searchBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText():lower()
        UI:FilterItems(text)
    end)
    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    local searchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    searchLabel:SetPoint("RIGHT", searchBox, "LEFT", -5, 0)
    searchLabel:SetText("Search:")

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
    optBtn:SetScript("OnClick", function() InterfaceOptionsFrame_OpenToCategory(addon.Options.Panel) end)
    
    -- Bag Bar
    local bagBar = CreateFrame("Frame", "budsBagsBagBar", f)
    bagBar:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    bagBar:SetSize(200, 30)
    
    for i = 0, 4 do
        local bb = CreateFrame("Button", "budsBagsBagBtn"..i, bagBar, "ItemButtonTemplate")
        bb:SetSize(28, 28)
        bb:SetPoint("LEFT", bagBar, "LEFT", i * 30, 0)
        
        bb:SetBackdrop(T.backdrop)
        bb:SetBackdropColor(0.1, 0.1, 0.1, 1)
        bb:SetBackdropBorderColor(unpack(T.borderColor))
        
        if i == 0 then
            bb.icon = _G[bb:GetName().."IconTexture"]
            bb.icon:SetTexture("Interface\\Buttons\\Button-Backpack-Up")
            bb.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            bb.icon:SetPoint("TOPLEFT", 1, -1)
            bb.icon:SetPoint("BOTTOMRIGHT", -1, 1)
            bb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(BACKPACK_TOOLTIP, 1, 1, 1)
                GameTooltip:Show()
            end)
            bb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        else
            bb:SetID(i)
            local invSlot = ContainerIDToInventoryID(i)
            
            bb:SetScript("OnEvent", function(self, event, ...)
                if event == "BAG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                    local texture = GetInventoryItemTexture("player", invSlot)
                    if texture then
                        _G[self:GetName().."IconTexture"]:SetTexture(texture)
                        _G[self:GetName().."IconTexture"]:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        _G[self:GetName().."IconTexture"]:Show()
                        self:SetNormalTexture("")
                    else
                        _G[self:GetName().."IconTexture"]:Hide()
                        self:SetNormalTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                        self:GetNormalTexture():SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    end
                end
            end)
            bb:RegisterEvent("BAG_UPDATE")
            bb:RegisterEvent("PLAYER_ENTERING_WORLD")
            
            bb:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local hasItem, hasCooldown, repairCost = GameTooltip:SetInventoryItem("player", invSlot)
                if not hasItem then
                    GameTooltip:SetText(EQUIP_CONTAINER, 1, 1, 1)
                end
                CursorUpdate(self)
            end)
            bb:SetScript("OnLeave", function()
                GameTooltip:Hide()
                ResetCursor()
            end)
            bb:SetScript("OnClick", function(self)
                if CursorHasItem() then
                    PutItemInBag(invSlot)
                else
                    PickupBagFromSlot(invSlot)
                end
            end)
            bb:SetScript("OnReceiveDrag", function(self)
                PutItemInBag(invSlot)
            end)
            bb:SetScript("OnDragStart", function(self)
                PickupBagFromSlot(invSlot)
            end)
            bb:RegisterForDrag("LeftButton")
            bb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        end
        UI.BagFrames[i] = bb
    end
    
    -- Bank Bag Bar (hidden by default)
    local bankBagBar = CreateFrame("Frame", "budsBagsBankBagBar", f)
    bankBagBar:SetPoint("LEFT", bagBar, "RIGHT", 10, 0)
    bankBagBar:SetSize(7 * 30, 30)
    bankBagBar:Hide() -- Only show when at bank
    f.BankBagBar = bankBagBar
    
    local bankBtn = CreateFrame("Button", "budsBagsBankBtn_Bank", bankBagBar, "ItemButtonTemplate")
    bankBtn:SetSize(28, 28)
    bankBtn:SetPoint("LEFT", bankBagBar, "LEFT", 0, 0)
    bankBtn.icon = _G[bankBtn:GetName().."IconTexture"]
    bankBtn.icon:SetTexture("Interface\\Icons\\INV_Box_02") -- Placeholder for Bank
    bankBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    bankBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Bank", 1, 1, 1)
        GameTooltip:Show()
    end)
    bankBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    UI.BagFrames[-1] = bankBtn

    for i = 1, 7 do
        local bagId = i + 4
        local bb = CreateFrame("Button", "budsBagsBankBagBtn"..bagId, bankBagBar, "ItemButtonTemplate")
        bb:SetSize(28, 28)
        bb:SetPoint("LEFT", bankBagBar, "LEFT", i * 30, 0)
        
        local invSlot = BankButtonIDToInvSlotID(i)
        
        bb:SetScript("OnEvent", function(self, event)
            if event == "BANKFRAME_OPENED" or event == "PLAYERBANKBAGS_CHANGED" then
                local texture = GetInventoryItemTexture("player", invSlot)
                if texture then
                    _G[self:GetName().."IconTexture"]:SetTexture(texture)
                    _G[self:GetName().."IconTexture"]:Show()
                else
                    _G[self:GetName().."IconTexture"]:Hide()
                end
            end
        end)
        bb:RegisterEvent("BANKFRAME_OPENED")
        bb:RegisterEvent("PLAYERBANKBAGS_CHANGED")
        
        bb:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetInventoryItem("player", invSlot)
            CursorUpdate(self)
        end)
        bb:SetScript("OnLeave", function() GameTooltip:Hide(); ResetCursor(); end)
        bb:SetScript("OnClick", function()
             if CursorHasItem() then PutItemInBag(invSlot) else PickupBagFromSlot(invSlot) end
        end)
        
        UI.BagFrames[bagId] = bb
    end
    
    self.MainFrame = f
    
    tinsert(UISpecialFrames, "budsBagsMainFrame")
    
    -- Register Bank Events on MainFrame
    f:RegisterEvent("BANKFRAME_OPENED")
    f:RegisterEvent("BANKFRAME_CLOSED")
    f:SetScript("OnEvent", function(self, event)
        if event == "BANKFRAME_OPENED" then
            self:Show()
            self.BankBagBar:Show()
            UI:UpdateAllBags()
        elseif event == "BANKFRAME_CLOSED" then
            self.BankBagBar:Hide()
            UI:UpdateAllBags()
            self:Hide()
        end
    end)
end

function UI:HookStandardBags()
    hooksecurefunc("ToggleBackpack", function()
        if UI.MainFrame:IsShown() and not UI.MainFrame.BankBagBar:IsShown() then
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
    if BankFrame then BankFrame:SetParent(hiddenParent) end
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
            if bag == -1 then
                GameTooltip:SetInventoryItem("player", BankButtonIDToInvSlotID(slot, 1))
            else
                GameTooltip:SetBagItem(bag, slot)
            end
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
        
        local emptyTex = btn:CreateTexture(nil, "BACKGROUND")
        emptyTex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
        emptyTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        emptyTex:SetAllPoints(btn)
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

function UI:FilterItems(text)
    if not text or text == "" then
        for _, btn in pairs(self.ItemButtons) do
            btn:SetAlpha(1)
        end
        return
    end
    
    for _, btn in pairs(self.ItemButtons) do
        if btn:IsShown() and btn.name and btn.name ~= "ZZZ" and btn.name ~= "Unknown" then
            if btn.name:lower():find(text, 1, true) then
                btn:SetAlpha(1)
                btn:SetBackdropBorderColor(0, 1, 0, 1)
            else
                btn:SetAlpha(0.2)
                local r, g, b = unpack(T.borderColor)
                if btn.rarity and btn.rarity > 1 then
                    r, g, b = GetItemQualityColor(btn.rarity)
                end
                btn:SetBackdropBorderColor(r, g, b, 1)
            end
        elseif btn.name == "ZZZ" then
             btn:SetAlpha(0.2)
        end
    end
end

-- Efficient Update Function
function UI:UpdateSlot(bag, slot)
    local texture, itemCount, locked, quality, readable, lootable, itemLink = GetContainerItemInfo(bag, slot)
    
    local btn = self:GetItemButton(bag, slot)
    if not btn then return end
    
    if texture then
        SetItemButtonTexture(btn, texture)
        if _G[btn:GetName().."IconTexture"] then _G[btn:GetName().."IconTexture"]:Show() end
        btn.emptyTex:Hide()
    else
        if _G[btn:GetName().."IconTexture"] then _G[btn:GetName().."IconTexture"]:Hide() end
        btn.emptyTex:Show()
    end
    
    SetItemButtonCount(btn, itemCount or 0)
    SetItemButtonDesaturated(btn, locked or false)
    
    btn.iLvlText:SetText("")
    btn.name = "Unknown"
    btn.rarity = 0
    btn.itemLink = itemLink
    
    if itemLink then
        local itemName, _, itemQuality, itemLevel = GetItemInfo(itemLink)
        btn.name = itemName or btn.name
        btn.rarity = itemQuality or 0
        if itemLevel and itemLevel > 1 then
            btn.iLvlText:SetText(itemLevel)
        end
    elseif not texture then
        btn.name = "ZZZ"
        btn.rarity = -2
    end
    
    local r, g, b = unpack(T.borderColor)
    if btn.rarity and btn.rarity > 1 then
        r, g, b = GetItemQualityColor(btn.rarity)
    end
    btn:SetBackdropBorderColor(r, g, b, 1)
end

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
        
        local atBank = self.MainFrame.BankBagBar and self.MainFrame.BankBagBar:IsShown()
        
        -- Config options
        local hideEmpty = false
        local scale = 1.0
        if addon.db and addon.db.profile then
            hideEmpty = addon.db.profile.hideEmpty or false
            scale = addon.db.profile.scale or 1.0
        end
        self.MainFrame:SetScale(scale)
        
        local iterStart = atBank and -1 or 0
        local iterEnd = atBank and 11 or 4

        for bag = iterStart, iterEnd do
            local maxSlots = GetContainerNumSlots(bag)
            if bag == -1 then maxSlots = 28 end
            
            for slot = 1, maxSlots do
                local texture, itemCount, locked, quality, readable
                local itemLink
                if bag == -1 then
                   texture, itemCount, locked, quality, readable, _, itemLink = GetContainerItemInfo(bag, slot)
                else
                   texture, itemCount, locked, quality, readable, _, itemLink = GetContainerItemInfo(bag, slot)
                end
                
                local btn = self:GetItemButton(bag, slot)
                btn:Show()
                self:UpdateSlot(bag, slot)
                
                local catId = "OTHER"
                if itemLink then
                     catId = addon.Categories:GetItemCategory(bag, slot, itemLink)
                elseif not texture then
                     catId = "EMPTY"
                end
                
                if hideEmpty and catId == "EMPTY" then
                    btn:Hide()
                else
                    if not catMap[catId] then catMap[catId] = {} end
                    
                    if not btnDataMap[dataIdx] then btnDataMap[dataIdx] = {} end
                    local data = btnDataMap[dataIdx]
                    data.btn = btn
                    data.catId = catId
                    data.rarity = btn.rarity
                    data.name = btn.name
                    
                    dataIdx = dataIdx + 1
                end
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
    local startY = -70
    local currentY = startY
    local buttonSize = 34
    local spacing = 4
    local columns = 10
    if addon.db and addon.db.profile and addon.db.profile.columns then
        columns = addon.db.profile.columns
    end
    
    local totalWidth = (startX * 2) + (columns * buttonSize) + ((columns - 1) * spacing)
    
    if self.MainFrame.BankBagBar and self.MainFrame.BankBagBar:IsShown() then
        if totalWidth < 450 then totalWidth = 450 end
    else
        if totalWidth < 250 then totalWidth = 250 end
    end
    
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
    
    local finalHeight = math.abs(currentY) + 45
    if finalHeight < 150 then finalHeight = 150 end
    
    self.MainFrame:SetSize(totalWidth, finalHeight)
end
