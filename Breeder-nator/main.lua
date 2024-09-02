local util = require("lib.utility")
local component = require("component")

local breederSide = nil
local storageSide = nil
local breeder = nil
-- The program assumes only one adapter and one transposer is present in the network
local transposer = component.transposer
for i=0,5 do 
    local invSize = transposer.getInventorySize(i)
    if(invSize ~= nil) then
        --Assumption that the hooked up storage container has more than 18 slots
        if (invSize > 18 and storageSide == nil) then
            print("Storage container found!")
            storageSide = i
        --Alvearies have 9 slots, apiaries have 12 (additional 3 for the frames)
        elseif ((invSize == 12 or invSize == 9) and breederSide == nil) then
            breederSide = i
        end
    end
end


if (next(component.list("for_alveary_0")) ~= nil and breeder == nil) then
    print("Alveary found!")
    breeder = component.for_alveary_0
elseif (next(component.list("tile_for_apiculture_0_name")) ~= nil and breeder == nil) then
    print("Apiary found!")
    breeder = component.tile_for_apiculture_0_name
end

if (breederSide == nil or breeder == nil) then
    print("Could not find apiary/alveary! Closing.")
    os.exit()
elseif (storageSide == nil) then
    print("Could not find storage container! Closing.")
    os.exit()
end

