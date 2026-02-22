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
    
    local slider = CreateFrame("Slider", "budsBagsColumnsSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", btnSort, "BOTTOMLEFT", 0, -30)
    slider:SetMinMaxValues(4, 24)
    slider:SetValueStep(1)
    
    -- Initialize value after variables loaded
    panel:SetScript("OnShow", function()
        if addon.db and addon.db.profile then
            slider:SetValue(addon.db.profile.columns or 10)
        end
    end)
    
    _G[slider:GetName().."Low"]:SetText("4")
    _G[slider:GetName().."High"]:SetText("24")
    _G[slider:GetName().."Text"]:SetText("Columns (Breite)")
    
    slider:SetScript("OnValueChanged", function(self, value)
        local stepValue = math.floor(value + 0.5) -- Manual step adherence
        if addon.db and addon.db.profile then
            if addon.db.profile.columns ~= stepValue then
                addon.db.profile.columns = stepValue
                if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
                    addon.UI:UpdateAllBags()
                end
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
