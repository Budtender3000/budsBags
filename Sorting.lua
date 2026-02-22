local _, addon = ...
addon.Sorting = {}
local S = addon.Sorting

-- Note: The logic here is separated for future deep ElvUI-like item 
-- swapping (moving items between bags to save space).
-- Currently, visual sorting is handled during UI layout.
function S:SortBags()
    print("|cFF00FF00budsBags:|r Item-Optimierung wird in zukünftigen Updates implementiert. " ..
          "Derzeit sortiert das Addon visuell nach Kategorien.")
end
