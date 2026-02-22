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
    
    local tokenFrame = CreateFrame("Frame", "budsBagsTokenFrame", f)
    tokenFrame:SetSize(200, 20)
    tokenFrame:SetPoint("BOTTOMRIGHT", moneyFrame, "BOTTOMLEFT", -20, 0)
    
    local tokenBtns = {}
    for i = 1, 3 do
        local tb = CreateFrame("Button", "budsBagsTokenBtn"..i, tokenFrame)
        tb:SetSize(40, 20)
        tb:SetPoint("RIGHT", tokenFrame, "RIGHT", -((i-1)*50), 0)
        
        tb.icon = tb:CreateTexture(nil, "OVERLAY")
        tb.icon:SetSize(16, 16)
        tb.icon:SetPoint("RIGHT", 0, 0)
        tb.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        
        tb.text = tb:CreateFontString(nil, "OVERLAY")
        tb.text:SetFont(T.font, 12, "OUTLINE")
        tb.text:SetPoint("RIGHT", tb.icon, "LEFT", -2, 0)
        tb.text:SetTextColor(1, 1, 1)
        tb.text:SetJustifyH("RIGHT")
        
        tb:SetScript("OnEnter", function(self)
            if self.currencyId then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetCurrencyToken(self.currencyId)
                GameTooltip:Show()
            end
        end)
        tb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tb:Hide()
        tokenBtns[i] = tb
    end
    f.tokenBtns = tokenBtns
    
    f:SetScript("OnShow", function()
        MoneyFrame_Update("budsBagsMoneyFrame", GetMoney())
        UI:UpdateCurrencies()
    end)
    
    f:RegisterEvent("PLAYER_MONEY")
    f:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    f:SetScript("OnEvent", function(self, event)
        if event == "PLAYER_MONEY" and self:IsShown() then
            MoneyFrame_Update("budsBagsMoneyFrame", GetMoney())
        elseif event == "CURRENCY_DISPLAY_UPDATE" and self:IsShown() then
            UI:UpdateCurrencies()
        end
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
    
    -- Keyring Btn
    local keyringBtn = CreateFrame("Button", "budsBagsBagBtn_Keyring", bagBar, "ItemButtonTemplate")
    keyringBtn:SetSize(28, 28)
    keyringBtn:SetPoint("LEFT", bagBar, "LEFT", 5 * 30, 0)
    keyringBtn.icon = _G[keyringBtn:GetName().."IconTexture"]
    keyringBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Key_14")
    keyringBtn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    keyringBtn.icon:Show()
    keyringBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(KEYRING, 1, 1, 1)
        GameTooltip:Show()
    end)
    keyringBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    keyringBtn:SetScript("OnClick", function()
        ToggleKeyRing()
    end)
    UI.BagFrames[-2] = keyringBtn
    
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
    
    -- Chain existing OnEvent
    local oldOnEvent = f:GetScript("OnEvent")
    f:SetScript("OnEvent", function(self, event, ...)
        if oldOnEvent then oldOnEvent(self, event, ...) end
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

function UI:UpdateCurrencies()
    if not self.MainFrame or not self.MainFrame.tokenBtns then return end
    
    for i = 1, 3 do self.MainFrame.tokenBtns[i]:Hide() end
    
    local numTokens = GetCurrencyListSize()
    local displayIndex = 1
    
    for i = 1, numTokens do
        local name, isHeader, isExpanded, isUnused, isWatched, count, icon, extraCurrencyType, itemID = GetCurrencyListInfo(i)
        if not isHeader and isWatched and displayIndex <= 3 then
            local tb = self.MainFrame.tokenBtns[displayIndex]
            tb.currencyId = i
            tb.icon:SetTexture(icon)
            tb.text:SetText(count)
            tb:Show()
            displayIndex = displayIndex + 1
        end
    end
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
            if IsAltKeyDown() and button == "LeftButton" then
                if btn.itemLink then
                    UI:ToggleCategoryDropdown(btn, bag, slot)
                end
                return
            end
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
        
        local searchOverlay = btn:CreateTexture(nil, "OVERLAY")
        searchOverlay:SetAllPoints(btn)
        searchOverlay:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        searchOverlay:SetBlendMode("ADD")
        searchOverlay:Hide()
        btn.searchOverlay = searchOverlay
        
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
            if btn.searchOverlay then btn.searchOverlay:Hide() end
        end
        return
    end
    
    for _, btn in pairs(self.ItemButtons) do
        if btn:IsShown() and btn.name and btn.name ~= "ZZZ" and btn.name ~= "Unknown" then
            if btn.name:lower():find(text, 1, true) then
                btn:SetAlpha(1)
                if btn.searchOverlay then btn.searchOverlay:Show() end
            else
                btn:SetAlpha(0.2)
                if btn.searchOverlay then btn.searchOverlay:Hide() end
            end
        elseif btn.name == "ZZZ" then
             btn:SetAlpha(0.2)
             if btn.searchOverlay then btn.searchOverlay:Hide() end
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
    
    
    local showRarity = true
    if addon.db and addon.db.profile and addon.db.profile.showRarity ~= nil then
        showRarity = addon.db.profile.showRarity
    end
    
    local r, g, b = unpack(T.borderColor)
    if showRarity and btn.rarity and btn.rarity > 1 then
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
        
        if not catMapPool.initialized then
            for _, group in ipairs(addon.Categories.Groups) do
                catMapPool[group.id] = {}
            end
            catMapPool["OTHER"] = {}
            catMapPool["EMPTY"] = {}
            catMapPool.initialized = true
        end
        
        for k, v in pairs(catMapPool) do
            if type(v) == "table" then wipe(v) end
        end
        
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
            -- Skip regular tracking for -2 (Keyring) if it's not the actual iteration pass, we will do it explicitly
            local bagsToIterate = {bag}
            if bag == 0 and not atBank then 
                table.insert(bagsToIterate, KEYRING_CONTAINER or -2)
            end
            
            for _, currentBag in ipairs(bagsToIterate) do
                local maxSlots = GetContainerNumSlots(currentBag)
                if currentBag == -1 then maxSlots = 28 end
                
                for slot = 1, maxSlots do
                    local texture, itemCount, locked, quality, readable, _, itemLink = GetContainerItemInfo(currentBag, slot)
                    
                    local btn = self:GetItemButton(currentBag, slot)
                    btn:Show()
                    self:UpdateSlot(currentBag, slot)
                    
                    local catId = "OTHER"
                    if itemLink then
                         catId = addon.Categories:GetItemCategory(currentBag, slot, itemLink)
                    elseif not texture then
                         catId = "EMPTY"
                    end
                    
                    
                    if (hideEmpty and catId == "EMPTY") or 
                       (addon.db and addon.db.profile and addon.db.profile.hiddenCategories and addon.db.profile.hiddenCategories[catId]) then
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
        end
        
        for i = dataIdx, #btnDataMap do
            btnDataMap[i] = nil
        end
        
        local reverseSort = false
        if addon.db and addon.db.profile and addon.db.profile.sortReverse then
             reverseSort = addon.db.profile.sortReverse
        end
        
        table.sort(btnDataMap, function(a, b)
            if a.rarity ~= b.rarity then
                if reverseSort then return a.rarity < b.rarity else return a.rarity > b.rarity end
            end
            if reverseSort then return a.name > b.name else return a.name < b.name end
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
    if addon.db and addon.db.profile and addon.db.profile.buttonSize then
        buttonSize = addon.db.profile.buttonSize
    end
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
            
             local showRarity = true
             if addon.db and addon.db.profile and addon.db.profile.showRarity ~= nil then
                 showRarity = addon.db.profile.showRarity
             end
             
             local r, g, b = unpack(T.borderColor)
             if showRarity and btn.rarity and btn.rarity > 1 then
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
        if not (addon.db and addon.db.profile and addon.db.profile.hiddenCategories and addon.db.profile.hiddenCategories[catData.id]) then
            LayoutGroup(catData.id, catData.name, catMap[catData.id])
        end
    end
    if not (addon.db and addon.db.profile and addon.db.profile.hiddenCategories and addon.db.profile.hiddenCategories["OTHER"]) then
        LayoutGroup("OTHER", "Other", catMap["OTHER"])
    end
    if not hideEmpty then
        LayoutGroup("EMPTY", "Empty Slots", catMap["EMPTY"])
    end
    
    local finalHeight = math.abs(currentY) + 45
    if finalHeight < 150 then finalHeight = 150 end
    
    self.MainFrame:SetSize(totalWidth, finalHeight)
end

function UI:ToggleCategoryDropdown(btn, bag, slot)
    if not self.CategoryDropdown then
        local d = CreateFrame("Frame", "budsBagsCategoryDropdown", UIParent, "UIDropDownMenuTemplate")
        self.CategoryDropdown = d
    end
    
    local d = self.CategoryDropdown
    local itemID = tonumber(btn.itemLink:match("item:(%d+)"))
    
    local function OnClick(self, arg1, arg2, checked)
        if addon.db and addon.db.profile then
            addon.db.profile.customCategories = addon.db.profile.customCategories or {}
            
            if arg1 == "DEFAULT" then
                addon.db.profile.customCategories[itemID] = nil
            else
                addon.db.profile.customCategories[itemID] = arg1
            end
            
            if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                addon.UI:UpdateAllBags()
            end
        end
    end
    
    local function InitializeDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Assign to Category"
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Reset Default"
        info.arg1 = "DEFAULT"
        info.func = OnClick
        info.checked = (not addon.db.profile.customCategories[itemID])
        UIDropDownMenu_AddButton(info, level)
        
        for _, cat in ipairs(addon.Categories.Groups) do
            info = UIDropDownMenu_CreateInfo()
            info.text = cat.name
            info.arg1 = cat.id
            info.func = OnClick
            info.checked = (addon.db.profile.customCategories[itemID] == cat.id)
            UIDropDownMenu_AddButton(info, level)
        end
        
        info = UIDropDownMenu_CreateInfo()
        info.text = "Other"
        info.arg1 = "OTHER"
        info.func = OnClick
        info.checked = (addon.db.profile.customCategories[itemID] == "OTHER")
        UIDropDownMenu_AddButton(info, level)
    end
    
    UIDropDownMenu_Initialize(d, InitializeDropdown, "MENU")
    ToggleDropDownMenu(1, nil, d, btn, 0, 0)
end
