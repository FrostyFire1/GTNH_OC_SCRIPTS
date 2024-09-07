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
local breeder = nil
-- The program assumes only one adapter and one transposer is present in the network
local transposer = component.transposer
local sideConfig = util.getOrCreateConfig()

if (next(component.list("for_alveary_0")) ~= nil) then
    print("Alveary found!")
    breeder = component.for_alveary_0
elseif (next(component.list("tile_for_apiculture_0_name")) ~= nil) then
    print("Apiary found!")
    breeder = component.tile_for_apiculture_0_name
else
    print("Can't find breeder block! Terminating.")
    os.exit()
end
for i=0,5 do
    local size = transposer.getInventorySize(i)
    if size == 9 or size == 12 then
        sideConfig.breeder = i
    end
end

local breedingChain, beeCount = util.createBreedingChain(targetBee, breeder, sideConfig) 
if beeCount == nil then
    print("Exiting...")
    os.exit()
end
for beeName,breedData in pairs(breedingChain) do
    for a,b in pairs(breedData) do
        print(a,b)
    end
end
for a,b in pairs(beeCount) do
    print(a,b)
end

local storageSize = transposer.getInventorySize(sideConfig.storage)
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
                        util.populateBee(parent1, sideConfig, 8)
                    end
                elseif beeCount[parent2].Princess then
                    if beeCount[parent2].Drone < 32 then
                        util.populateBee(parent2, sideConfig, 8)
                    end
                else
                    util.convertPrincess(parent1, sideConfig)
                    if beeCount[parent1].Drone < 32 then
                        util.populateBee(parent1, sideConfig, 8)
                    end
                end
                util.breed(beeName, breedData, sideConfig)
                
                if transposer.getStackInSlot(sideConfig.storage, storageSize) ~= nil then
                    util.populateBee(beeName, sideConfig, 8)
                    util.imprintFromTemplate(beeName, sideConfig)
                end
                util.populateBee(beeName, sideConfig, 32)
                breedingChain[beeName] = nil
                bredBee = true
                print("Updating bee list...")
                beeCount = util.listBeesInStorage(sideConfig)
            end
        end
    end
    if not bredBee then
        print("Cannot breed any required bee with bees in storage! Aborting.")
        os.exit()
    end
end