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

local updatePending = false

if not Core.UpdateFrame then
    Core.UpdateFrame = CreateFrame("Frame")
    Core.UpdateFrame:Hide()
    Core.UpdateFrame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer >= 0.1 then
            if updatePending then
                addon.UI:UpdateAllBags()
                updatePending = false
            end
            self:Hide()
        end
    end)
end

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
            local bag = ...
            if type(bag) == "number" and bag >= 0 and bag <= 4 then
                updatePending = true
                Core.UpdateFrame.timer = 0
                Core.UpdateFrame:Show()
            end
        end
    end
end
Core:SetScript("OnEvent", Core.OnEvent)

function Core:Initialize()
    budsBagsDB = budsBagsDB or {}
    budsBagsDB.profile = budsBagsDB.profile or { columns = 10 }
    addon.db = budsBagsDB
    
    print("|cFF00FF00" .. addonName .. "|r geladen. Version 1.0.0.")
end

function Core:OnLogin()
    if addon.UI and addon.UI.Initialize then
        addon.UI:Initialize()
        addon.UI:UpdateAllBags()
    end
end
