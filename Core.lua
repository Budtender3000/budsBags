local addonName, addon = ...
addon.name = addonName

-- Global
budsBagsDB = budsBagsDB or {}
_G["budsBags"] = addon

local Core = CreateFrame("Frame", "budsBagsCoreFrame")
addon.Core = Core

Core:RegisterEvent("ADDON_LOADED")
Core:RegisterEvent("PLAYER_LOGIN")
Core:RegisterEvent("BAG_UPDATE")

function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            self:Initialize()
        end
    elseif event == "PLAYER_LOGIN" then
        self:OnLogin()
    elseif event == "BAG_UPDATE" then
        if addon.UI and addon.UI.MainFrame and addon.UI.MainFrame:IsShown() then
            -- We only update bags if UI is shown
            local bag = ...
            if type(bag) == "number" and bag >= 0 and bag <= 4 then
                addon.UI:UpdateAllBags()
            end
        end
    end
end
Core:SetScript("OnEvent", Core.OnEvent)

function Core:Initialize()
    print("|cFF00FF00" .. addonName .. "|r geladen. Version 1.0.0.")
end

function Core:OnLogin()
    if addon.UI and addon.UI.Initialize then
        addon.UI:Initialize()
    end
end
