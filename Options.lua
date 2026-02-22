local addonName, addon = ...
addon.Options = {}
local O = addon.Options

function O:Initialize()
    local panel = CreateFrame("Frame", "budsBagsOptionsPanel")
    panel.name = "budsBags"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("budsBags Options")
    
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    fs:SetText("Configuration for the bag addon.")
    
    local btnSort = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btnSort:SetSize(120, 25)
    btnSort:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -20)
    btnSort:SetText("Sort Bags")
    btnSort:SetScript("OnClick", function()
        addon.Sorting:SortBags()
    end)
    
    -- Columns Slider
    local slider = CreateFrame("Slider", "budsBagsColumnsSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", btnSort, "BOTTOMLEFT", 0, -30)
    slider:SetMinMaxValues(4, 24)
    slider:SetValueStep(1)
    
    _G[slider:GetName().."Low"]:SetText("4")
    _G[slider:GetName().."High"]:SetText("24")
    _G[slider:GetName().."Text"]:SetText("Columns (Breite)")
    
    -- Scale Slider
    local scaleSlider = CreateFrame("Slider", "budsBagsScaleSlider", panel, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    
    _G[scaleSlider:GetName().."Low"]:SetText("0.5x")
    _G[scaleSlider:GetName().."High"]:SetText("2.0x")
    _G[scaleSlider:GetName().."Text"]:SetText("Scale (Größe)")

    scaleSlider:SetScript("OnValueChanged", function(self, value)
        -- floor to 1 decimal place
        local stepValue = math.floor(value * 10 + 0.5) / 10
        if addon.db and addon.db.profile then
            if addon.db.profile.scale ~= stepValue then
                addon.db.profile.scale = stepValue
                if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                    addon.UI.MainFrame:SetScale(stepValue)
                end
            end
        end
    end)
    
    -- Button Size Slider
    local btnSizeSlider = CreateFrame("Slider", "budsBagsBtnSizeSlider", panel, "OptionsSliderTemplate")
    btnSizeSlider:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -30)
    btnSizeSlider:SetMinMaxValues(20, 60)
    btnSizeSlider:SetValueStep(1)
    
    _G[btnSizeSlider:GetName().."Low"]:SetText("20")
    _G[btnSizeSlider:GetName().."High"]:SetText("60")
    _G[btnSizeSlider:GetName().."Text"]:SetText("Button Size (Item Größe)")
    
    btnSizeSlider:SetScript("OnValueChanged", function(self, value)
        local stepValue = math.floor(value + 0.5)
        if addon.db and addon.db.profile then
            if addon.db.profile.buttonSize ~= stepValue then
                addon.db.profile.buttonSize = stepValue
                if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                    addon.UI:UpdateAllBags()
                end
            end
        end
    end)
    
    -- Hide Empty Checkbox
    local hideEmptyCb = CreateFrame("CheckButton", "budsBagsHideEmptyCB", panel, "InterfaceOptionsCheckButtonTemplate")
    hideEmptyCb:SetPoint("TOPLEFT", btnSizeSlider, "BOTTOMLEFT", 0, -20)
    _G[hideEmptyCb:GetName() .. "Text"]:SetText("Hide Empty Slots")
    
    hideEmptyCb:SetScript("OnClick", function(self)
        if addon.db and addon.db.profile then
             addon.db.profile.hideEmpty = self:GetChecked()
             if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                 addon.UI:UpdateAllBags()
             end
        end
    end)
    
    slider:SetScript("OnValueChanged", function(self, value)
        local stepValue = math.floor(value + 0.5)
        if addon.db and addon.db.profile then
            if addon.db.profile.columns ~= stepValue then
                addon.db.profile.columns = stepValue
                if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                    addon.UI:UpdateAllBags()
                end
            end
        end
    end)
    
    -- Show Rarity Checkbox
    local showRarityCb = CreateFrame("CheckButton", "budsBagsShowRarityCB", panel, "InterfaceOptionsCheckButtonTemplate")
    showRarityCb:SetPoint("TOPLEFT", hideEmptyCb, "BOTTOMLEFT", 0, -10)
    _G[showRarityCb:GetName() .. "Text"]:SetText("Show Item Rarity Border")
    
    showRarityCb:SetScript("OnClick", function(self)
        if addon.db and addon.db.profile then
             addon.db.profile.showRarity = self:GetChecked()
             if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                 addon.UI:UpdateAllBags()
             end
        end
    end)
    
    -- Reverse Sort Checkbox
    local reverseSortCb = CreateFrame("CheckButton", "budsBagsReverseSortCB", panel, "InterfaceOptionsCheckButtonTemplate")
    reverseSortCb:SetPoint("TOPLEFT", showRarityCb, "BOTTOMLEFT", 0, -10)
    _G[reverseSortCb:GetName() .. "Text"]:SetText("Reverse Sort Direction")
    
    reverseSortCb:SetScript("OnClick", function(self)
        if addon.db and addon.db.profile then
             addon.db.profile.sortReverse = self:GetChecked()
             if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                 addon.UI:UpdateAllBags()
             end
        end
    end)
    
    panel:SetScript("OnShow", function()
        if addon.db and addon.db.profile then
            slider:SetValue(addon.db.profile.columns or 10)
            scaleSlider:SetValue(addon.db.profile.scale or 1.0)
            btnSizeSlider:SetValue(addon.db.profile.buttonSize or 34)
            hideEmptyCb:SetChecked(addon.db.profile.hideEmpty or false)
            showRarityCb:SetChecked(addon.db.profile.showRarity or false)
            reverseSortCb:SetChecked(addon.db.profile.sortReverse or false)
        end
    end)
    
    -- Default Options Registration for 3.3.5a
    InterfaceOptions_AddCategory(panel)
    self.Panel = panel
end

-- Hook into Core
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    O:Initialize()
end)
