local util = require("lib.utility")
local component = require("component")
local config = require("lib.config")
local shell = require("shell")
local args,flags = shell.parse(...)
local event = require("event")

local programMode = args[1]
local targetBee = args[2]
function printUsage()
    print("Usage: BreederTron3000 ProgramMode TargetBee [Flags]")
    print("TargetBee needed in ProgramMode \"breed\" and \"convert\"")
    print("Available Modes: breed, imprint, convert")
    print("Supported flags: --noFinalImprint || If used in breed mode the final bee won't have its genes imprinted (in case you want a gene from this bee)")
end
if programMode == nil then
    print("PROGRAM MODE NOT PROVIDED! TERMINATING!")
    printUsage()
    os.exit()
end
if targetBee == nil and programMode:lower() == "breed" then
    print("TARGET BEE NOT PROVIDED! TERMINATING!")
    printUsage()
    os.exit()
end
local breeder = nil
-- The program assumes only one adapter and one transposer is present in the network
local transposer = component.transposer
local modem = nil
if next(component.list("modem")) ~= nil then
    modem = component.modem
end
local robotMode = false
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

if flags["noFinalImprint"] == true then
    print("------------------------------")
    print(string.format("The program will skip imprinting of the %s bee", targetBee))
    print("------------------------------")
end

print("Checking storage for existing bees...")
local beeCount = util.listBeesInStorage(sideConfig)
print("Done!")
if beeCount == nil then
    print("THERE ARE NO BEES! TERMINATING PROGRAM!")
    os.exit()
end


local princessCount = 0
for _,data in pairs(beeCount) do
    if data["Princess"] ~= nil then
        princessCount = princessCount + data["Princess"]
    end
end
if princessCount == 0 then
    print("There are 0 princesses in storage! Terminating.")
    os.exit()
end
print(string.format("Located %d princesses in the storage chest.", princessCount))

if programMode:lower() == "breed" or programMode:lower() == "imprint" then
    print("Populating underpopulated bee pairs...")
    for name,data in pairs(beeCount) do
        if data["Princess"] ~= nil and data["Drone"] ~= nil then
            if data["Drone"] < 16 then
                util.populateBee(name, sideConfig, 16)
            end
        end
    end
end

if programMode:lower() == "breed" then
    local storageSize = transposer.getInventorySize(sideConfig.storage)
    local hasTemplates = transposer.getStackInSlot(sideConfig.storage, storageSize) ~= nil

    if modem == nil or (not modem.isWireless()) then
        print("WARNING: No network card or card isn't wireless!")
    else
        print("Wireless network card detected!")
        modem.open(config.port)
        print("Opened port " .. config.port)
        print("Searching for a robot...")
        modem.broadcast(config.robotPort, "check")
        local _, _, _, _, _, message = event.pull(5,"modem_message")
        if message then
            print("Found a robot! Enabling robot mode...")
            robotMode = true
        else
            print("Can't locate any robots! Robot mode will stay disabled.")
        end
    end

    local breedingChain = util.createBreedingChain(targetBee, breeder, sideConfig, beeCount) 
    print("The breeding list:")
    for beeName,breedData in pairs(breedingChain) do
        print(beeName)
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
                            util.populateBee(parent1, sideConfig, 16)
                        end
                    elseif beeCount[parent2].Princess then
                        if beeCount[parent2].Drone < 32 then
                            util.populateBee(parent2, sideConfig, 16)
                        end
                    else
                        util.convertPrincess(parent1, sideConfig)
                        if beeCount[parent1].Drone < 32 then
                            util.populateBee(parent1, sideConfig, 16)
                        end
                    end
                    util.breed(beeName, breedData, sideConfig, robotMode)
                    
                    if hasTemplates and not (beeName == targetBee and flags["noFinalImprint"] == true) then
                        while (transposer.getStackInSlot(sideConfig.storage, storageSize) == nil) do
                            print("YOU RAN OUT OF TEMPLATE DRONES! PLEASE PROVIDE MORE!")
                            os.sleep(5)
                        end
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
elseif programMode:lower() == "imprint" then
    local size = transposer.getInventorySize(sideConfig.storage)
    local templateDrone = transposer.getStackInSlot(sideConfig.storage, size)
    if templateDrone == nil then
        print("PROGRAM IS IN IMPRINT MODE BUT NO TEMPLATE DRONES ARE PRESENT! TERMINATING!")
        os.exit()
    end
    local templateSpecies,_ = util.getItemName(templateDrone)
    if targetBee ~= nil then
        if beeCount[targetBee].Princess == nil then
            util.convertPrincess(targetBee, sideConfig)
        else
            if beeCount[targetBee].Drone < 8 then
                util.populateBee(targetBee, sideConfig, 8)
                if (util.imprintFromTemplate(name, sideConfig, templateDrone.individual.active) == true) then
                    util.populateBee(name, sideConfig, 32)
                end
            end
        end
    else
        for name,count in pairs(beeCount) do
            if name == templateSpecies then
                goto continue
            end
            if count.Princess ~= nil and count.Drone ~= nil then
                if count.Drone < 8 then
                    util.populateBee(name, sideConfig, 8)
                end
                if (util.imprintFromTemplate(name, sideConfig, templateDrone.individual.active) == true) then
                    util.populateBee(name, sideConfig, 32)
                end
                beeCount[name] = nil
            end
            ::continue::
        end
        for name,count in pairs(beeCount) do
            if name == templateSpecies then
                goto continue
            end
            if(count.Drone == nil or count.Drone < 16) then
                print(string.format("THERE ARE LESS THAN 16 %s DRONES IN STORAGE. SKIPPING IMPRINT.", name))
                goto continue
            end
            local droneSlot = util.findBeeWithType(name, "Drone", sideConfig)
            local drone = transposer.getStackInSlot(sideConfig.storage, droneSlot)
            if not (util.isGeneticallyEquivalent(drone, templateDrone, templateDrone.individual.active, true)) then
                util.convertPrincess(name, sideConfig)
                util.populateBee(name, sideConfig, 8)
                if (util.imprintFromTemplate(name, sideConfig, templateDrone.individual.active) == true) then
                    util.populateBee(name, sideConfig, 32)
                end
            else
                print(string.format("%s bee already has template genes. skipping.", name))
            end
            ::continue::
        end
    end
    
elseif programMode:lower() == "convert" then
    if beeCount[targetBee] == nil or beeCount[targetBee].Drone == nil then
        print(string.format("You don't have the drones to convert a princess to %s!",targetBee))
    elseif beeCount[targetBee].Drone < config.convertDroneReq then
        print(string.format("You only have %d %s drones. Would you like to proceed anyway? (This could crash the program) Y/N", beeCount[targetBee].Drone, targetBee))
        local ans = io.read()
        if ans ~= nil and ans:upper() == "Y" then
            util.convertPrincess(targetBee, sideConfig, 0)
            util.populateBee(targetBee, sideConfig, 16)
        end
    else
        util.convertPrincess(targetBee, sideConfig)
        util.populateBee(targetBee, sideConfig, 16)
    end
else
    printUsage()
end
