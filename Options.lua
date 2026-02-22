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

    -- Hide Empty Checkout
    local hideEmptyCb = CreateFrame("CheckButton", "budsBagsHideEmptyCB", panel, "InterfaceOptionsCheckButtonTemplate")
    hideEmptyCb:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -20)
    _G[hideEmptyCb:GetName() .. "Text"]:SetText("Hide Empty Slots")
    
    panel:SetScript("OnShow", function()
        if addon.db and addon.db.profile then
            slider:SetValue(addon.db.profile.columns or 10)
            scaleSlider:SetValue(addon.db.profile.scale or 1.0)
            hideEmptyCb:SetChecked(addon.db.profile.hideEmpty or false)
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
    
    hideEmptyCb:SetScript("OnClick", function(self)
        if addon.db and addon.db.profile then
             addon.db.profile.hideEmpty = self:GetChecked()
             if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                 addon.UI:UpdateAllBags()
             end
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
