local util = require("lib.utility")
local component = require("component")
local config = require("lib.config")
local shell = require("shell")
local targetBee,_ = shell.parse(...)

local targetBee = targetBee[1]
if targetBee == nil then
    print("Target bee not provided! Terminating.")
    os.exit()
end
local breederSide = nil
local storageSide = nil
local breeder = nil
-- The program assumes only one adapter and one transposer is present in the network
local transposer = component.transposer
-- for i=0,5 do 
--     local invSize = transposer.getInventorySize(i)
--     if(invSize ~= nil) then
--         --Assumption that the hooked up storage container has more than 18 slots
--         if (invSize > 18 and storageSide == nil) then
--             print("Storage container found!")
--             storageSide = i
--         --Alvearies have 9 slots, apiaries have 12 (additional 3 for the frames)
--         elseif ((invSize == 12 or invSize == 9) and breederSide == nil) then
--             breederSide = i
--         end
--     end
-- end


-- if (next(component.list("for_alveary_0")) ~= nil and breeder == nil) then
--     print("Alveary found!")
--     breeder = component.for_alveary_0
-- elseif (next(component.list("tile_for_apiculture_0_name")) ~= nil and breeder == nil) then
--     print("Apiary found!")
--     breeder = component.tile_for_apiculture_0_name
-- end

-- if (breederSide == nil or breeder == nil) then
--     print("Could not find apiary/alveary! Closing.")
--     os.exit()
-- elseif (storageSide == nil) then
--     print("Could not find storage container! Closing.")
--     os.exit()
-- end

local breedingChain, beeCount = util.createBreedingChain(targetBee, breeder, config.devConfig) 

for beeName,breedData in pairs(breedingChain) do
    for a,b in pairs(breedData) do
        print(a,b)
    end
end
for a,b in pairs(beeCount) do
    print(a,b)
end
while breedingChain[targetBee] ~= nil do
    local bredBee = false
    for beeName,breedData in pairs(breedingChain) do
        if breedData ~= nil then
            local parent1 = breedData.allele1.name
            local parent2 = breedData.allele2.name
            if beeCount[parent1] == nil or beeCount[parent2] == nil then
                print("Cannot breed " .. beeName .. ". Skipping.")
            elseif beeCount[parent1].Drone ~= nil and beeCount[parent2].Drone ~= nil then
                if beeCount[parent1].Princess then
                    if beeCount[parent1].Drone < 32 then
                        util.populateBee(parent1, config.devConfig)
                    end
                elseif beeCount[parent2].Princess then
                    if beeCount[parent2].Drone < 32 then
                        util.populateBee(parent2, config.devConfig)
                    end
                else
                    util.convertPrincess(parent1, config.devConfig)
                    if beeCount[parent1].Drone < 32 then
                        util.populateBee(parent1, config.devConfig)
                    end
                end
                util.breed(beeName, breedData, config.devConfig)
                util.populateBee(beeName, config.devConfig)
                util.imprintFromTemplate(beeName, config.devConfig)
                breedingChain[beeName] = nil
                bredBee = true
                print("Updating bee list...")
                beeCount = util.listBeesInStorage(config.devConfig)
            end
        end
    end
    if not bredBee then
        print("Cannot breed any required bee with bees in storage! Aborting.")
        os.exit()
    end
end