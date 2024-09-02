local util = require("lib.utility")
local component = require("component")

local breederSide = nil
local storageSide = nil
local breederContainer = nil
-- The program assumes only one adapter and one transposer is present in the network
local transposer = component.transposer
for i=0,5 do 
    local invSize = transposer.getInventorySize(i)
    --Assumption that the hooked up storage container has more than 18 slots
    if (invSize > 18 and storageSide == nil) then
        storageSide = i
    --Alvearies have 9 slots, apiaries have 12 (additional 3 for the frames)
    else if ((invSize == 12 or invSize == 9) and breederSide == nil) then
        breederSide = i
    end

    if (component.tile_for_alveary and breederContainer == nil) then
        breederContainer = component.tile_for_alveary
    else if (component.tile_for_apiculture_0_name and breederContainer == nil) then
        breederContainer = component.tile_for_apiculture_0_name
    end
end

