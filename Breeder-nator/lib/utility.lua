local component = require("component")
local config = require("config")
local utility = {}
local transposer = component.transposer

function utility.createBreedingChain(beeName, breeder, storageSide)
    print("Checking storage for existing bees...")
    local existingBees = utility.listBeesInStorage(storageSide)
    print("Done!")
    local startingParents = utility.processBee(beeName, breeder)
    if(startingParents == nil) then
        print("Bee has no parents!")
        return {}
    end
    if(existingBees[beeName]) then
        print("You already have the " .. beeName .. " bee!")
        return {}
    end
    local breedingChain = {[beeName] = startingParents}
    local queue = {[beeName] = startingParents}
    local current = {}

    while next(queue) ~= nil do
        for child,parentPair in pairs(queue) do
            local leftName = parentPair.allele1.name
            local rightName = parentPair.allele2.name
            print("Processing parents of " .. child .. ": " .. leftName .. " and " .. rightName)

            local leftParents = utility.processBee(leftName, breeder, child)
            local rightParents = utility.processBee(rightName, breeder, child)

            if leftParents ~= nil then
                print(leftName .. ": " .. leftParents.allele1.name .. " + " .. leftParents.allele2.name)
                current[leftName] = leftParents
            end
            if rightParents ~= nil then
                print(rightName .. ": " .. rightParents.allele1.name .. " + " .. rightParents.allele2.name)
                current[rightName] = rightParents
            end
        end
        queue = {}
        for child,parents in pairs(current) do
            --Skip the bee if it's already present in the breeding chain, the queue or in storage
            if breedingChain[child] == nil and queue[child] == nil and existingBees[child] == nil then
            queue[child] = parents
            end
            if breedingChain[child] == nil and existingBees[child] == nil then
            breedingChain[child] = parents
            end
        end
        current = {}
    end
    return breedingChain
end

function utility.processBee(beeName, breeder, child)
    local parentPairs = breeder.getBeeParents(beeName)
    if #parentPairs == 0 then
        return nil
    elseif #parentPairs == 1 then
        return table.unpack(parentPairs)
    else
        local preference = config.preference[beeName]
        if preference == nil then
            return utility.resolveConflict(beeName, parentPairs, child)
        end
        for _,pair in pairs(parentPairs) do
            if (pair.allele1.name == preference[1] and pair.allele2.name == preference[2]) then
                return pair 
            end
        end
    end
    return nil
end

function utility.resolveConflict(beeName, parentPairs, child)
    local choice = nil

    print("Detected conflict! Please choose one of the following parents for the " .. beeName .. " bee (Breeds into " .. child .. " bee): ")
    for i,pair in pairs(parentPairs) do
        print(i .. ": " .. pair.allele1.name .. " + " .. pair.allele2.name)
    end

    while(choice == nil or choice < 1 or choice > #parentPairs) do
    print("Please type the number of the correct pair")
    choice = io.read("*n")
    end

    print("Selected: " .. parentPairs[choice].allele1.name .. " + " .. parentPairs[choice].allele2.name)
    return parentPairs[choice]
end

function utility.listBeesInStorage(storageSide)
    local size = transposer.getInventorySize(storageSide)
    local bees = {}

    for i=1,size do
        local bee = transposer.getStackInSlot(storageSide, i)
        if bee ~= nil then
            local species,type = utility.getBee(bee)


            if bees[species] == nil then
                bees[species] = {[type] = bee.size}
            elseif bees[species][type] == nil then
                bees[species][type] = bee.size
            else
                bees[species][type] = bees[species][type] + bee.size
            end
        end
    end
    return bees
end

--Converts a princess to the given bee type
--Assumes bee is scanned (Only scanned bees expose genes)
function utility.convertPrincess(beeName, storageSide, breederSide, garbageSide, scannerSide, outputSide)
    print("Converting princess to " .. beeName)
    local droneSlot = nil
    local targetGenes = nil
    local princess = transposer.getStackInSlot(breederSide, 1)
    local princessSlot = nil
    local princessName = nil
    if princess ~= nil then
        local species,_ = utility.getBee(princess)
        princessName = species
    end
    local size = transposer.getInventorySize(storageSide)
    --Since frame slots are slots 10,11,12 for the apiary there is no need to make any offsets

    for i=1,size do
        if droneSlot == nil or princess == nil then
            local bee = transposer.getStackInSlot(storageSide,i)
            if bee ~= nil then
                local species,type = utility.getBee(bee)
                if species == beeName and type == "Drone" and bee.size >= 16 and droneSlot == nil then
                    droneSlot = i
                    targetGenes = bee.individual
                elseif type == "Princess" and princess == nil then
                    princess = bee
                    princessSlot = i
                    princessName = species
                end
            end
        end
    end
    if droneSlot == nil then
        print("Can't find drone! Aborting.")
        return
    end
    if targetGenes == nil then
        print("Drone not scanned! Aborting.")
        return
    end
    if princess == nil then
        print("Can't find princess! Aborting.")
        return
    end
    --Insert bees into the apiary
    print("Converting " .. princessName .. " princess to " .. beeName)
    --First number is the amount of items transferred, the second is the slot number of the container items are transferred to
    --Move only 1 drone at a time to leave the apiary empty after the cycling is complete (you can't extract from input slots)
    transposer.transferItem(storageSide,breederSide, 1, droneSlot, 2) --Slot 2 for apiary is the drone slot
    if princessSlot ~= nil then
        transposer.transferItem(storageSide,breederSide, 1, princessSlot, 1) --Slot 1 for apiary is the princess slot
    end

    local princessConverted = false
    while(not princessConverted) do
        --Cycle finished if slot 1 is empty
        if transposer.getStackInSlot(breederSide, 1) == nil then
            for i=3,9 do
                local item = transposer.getStackInSlot(breederSide,i)
                if item ~= nil then
                    local species,type = utility.getBee(item)
                    if type == "Drone" and item.size == targetGenes.active.fertility and species == beeName then
                        print("Scanning princess...")
                        princessConverted = utility.checkPrincess(breederSide, scannerSide, outputSide) --This call will move the princess to outputSide
                        if (not princessConverted) then
                            print("Princess is not a perfect copy! Continuing.")
                            transposer.transferItem(outputSide,breederSide, 1, 1, 1) --Move princess back to input
                            transposer.transferItem(storageSide, breederSide, 1, droneSlot, 2) --Move drone from storage to breed slot
                        end
                    end
                end
            end
            if(not princessConverted) then
                for i=3,9 do
                    local item = transposer.getStackInSlot(breederSide,i)
                    if item ~= nil then
                        local species,type = utility.getBee(item)
                        if type == "Princess" then
                            transposer.transferItem(breederSide, breederSide, 1, i, 1) --Move princess back to input slot
                            transposer.transferItem(storageSide, breederSide, 1, droneSlot, 2) --Move drone from storage to breed slot
                        else
                            transposer.transferItem(breederSide, garbageSide, item.size, i)
                        end
                    end
                end
            end
        end
        os.sleep(1)
    end
    print("Conversion complete!")
    for i=3,9 do --clean up the drones
        local item = transposer.getStackInSlot(breederSide, i)
        if item ~= nil then
            transposer.transferItem(breederSide, garbageSide, item.size)
        end
    end
    transposer.transferItem(outputSide,storageSide, 1, 1)
    print(beeName .. " princess moved to storage.")
end

function utility.populateBee(beeName, storageSide, breederSide, scannerSide, outputSide)
    local droneOutput = nil
    print("Populating " .. beeName .. " bee.")
    local princessSlot, droneSlot = utility.findPairString(beeName, beeName, storageSide)
    if(princessSlot == -1 or droneSlot == -1) then
        print("Couldn't find princess or drone! Aborting.")
        return
    end
    print(beeName .. " bees found!")
    --Because the drones in storage are scanned you can only insert 1. the rest will be taken from output of the following cycles
    transposer.transferItem(storageSide, breederSide, 1, princessSlot, 1)
    transposer.transferItem(storageSide, breederSide, 1, droneSlot, 2)
    local item = nil
    while(item == nil or item.size < 32) do
        while(transposer.getStackInSlot(breederSide,1) ~= nil) do --Wait until cycle is finished
            os.sleep(1)
        end
        if droneOutput == nil then
            for i=3,9 do
                local candidate = transposer.getStackInSlot(breederSide,i)
                if candidate ~= nil then
                    local _,type = utility.getBee(candidate)
                    if type == "Drone" then
                        print("Drones located in slot: " .. i)
                        droneOutput = i
                    end
                end
            end
        else
            item = transposer.getStackInSlot(breederSide, droneOutput)
            print("Populating progress: " .. item.size .. "/32")
            if (item.size < 32) then
                transposer.transferItem(breederSide,breederSide, 1, droneOutput, 2) --Move a single drone back to the breeding slot
                for i=3,9 do
                    local candidate = transposer.getStackInSlot(breederSide,i)
                    if candidate ~= nil then
                        local _,type = utility.getBee(candidate)
                        if type == "Princess" then
                            transposer.transferItem(breederSide,breederSide,1, i, 1) --Move princess back to breeding slot
                        end
                    end
                end
            end
        end
    end
    print("Populating complete! Sending " .. beeName .. " bees to scanner.")
    for i=3,9 do
        local item = transposer.getStackInSlot(breederSide,i)
        if item ~= nil then
            local _,type = utility.getBee(item)
            if type ~= "Princess" and type ~= "Drone" then
                transposer.transferItem(breederSide,garbageSide,64,i)
            else
                transposer.transferItem(breederSide,scannerSide,64,i)
            end
        end
    end
    local remainingScans = 2 --1 drone stack + 1 princess stack
    while remainingScans > 0 do
        for i=1,2 do
            if transposer.transferItem(outputSide,storageSide, 64, i) > 0 then
                remainingScans = remainingScans - 1
            end
        end
        os.sleep(1)
    end
    print("Scanned! " .. beeName .. " bees sent to storage.")
end


function utility.breed(beeName, breedData, storageSide, breederSide, garbageSide, scannerSide, outputSide)
    print("Breeding " .. beeName .. " bee.")
    local basePrincessSlot, baseDroneSlot = utility.findPair(breedData, storageSide)
    if basePrincessSlot == -1 or baseDroneSlot == -1 then
        print("Couldn't find the parents of " .. beeName .. " bee! Aborting.")
        return
    end
    local basePrincess = transposer.getStackInSlot(storageSide, basePrincessSlot) --In case princess needs to be converted
    local basePrincessSpecies,_ = utility.getBee(basePrincess)
    local chance = breedData.chance

    local breederSize = transposer.getInventorySize(breederSide)
    if(breederSize == 12) then --Apiary exclusive.
        for i=10,12 do
            local frame = transposer.getStackInSlot(breederSide,i)
            if frame ~= nil and frame.name == "MagicBees:item.frenziedFrame"then
                chance = math.min(100, chance*10)
            end
        end
    end
    if chance ~= breedData.chance then
        print("Mutation altering frames detected!")
    end
    
    print("Base chance: " .. breedData.chance .. "%")
    if breederSize == 12 then
        print("Actual chance: " .. chance .. "%. MIGHT PRODUCE OTHER MUTATIONS!")
    else
        print("Actual chance unknown (using alveary). MIGHT PRODUCE OTHER MUTATIONS!")
    end
    local requirements = table.unpack(breedData.specialConditions)
    if requirements ~= nil then
        print("This bee has the following special requirements: " .. requirements)
        print("Press enter when you've made sure the conditions are met.")
        io.read()
    end

    transposer.transferItem(storageSide,breederSide, 1, basePrincessSlot, 1)
    transposer.transferItem(storageSide,breederSide, 1, baseDroneSlot, 2)
    local isPure = false
    local isGeneticallyPerfect = false --In this case genetic perfection refers to the bee having the same active and inactive genes
    local messageSent = false --About mutation frames

    local princess = nil
    local princessPureness = 0
    local princessSlot = nil
    local bestDrone = nil
    local bestDronePureness = -1
    local bestDroneSlot = nil
    local scanCount = 0

    while(not isPure) do
        while(transposer.getStackInSlot(breederSide,1) ~= nil) do
            os.sleep(1)
        end
        scanCount = 0
        print("Scanning bees...")
        for i=3,9 do
            local item = transposer.getStackInSlot(breederSide,i)
            if item ~= nil then
                local _,type = utility.getBee(item)
                if type ~= "Princess" and type ~= "Drone" then
                    transposer.transferItem(breederSide, garbageSide, 64, i)
                else
                    transposer.transferItem(breederSide, scannerSide, 64, i)
                    scanCount = scanCount + 1
                end
            end
        end
        while(transposer.getStackInSlot(outputSide, scanCount) == nil) do
            os.sleep(1)
        end

        print("Assessing...")
        princess = nil
        princessPureness = 0
        princessSlot = nil
        bestDrone = nil
        bestDronePureness = -1
        bestDroneSlot = nil

        for i=1,scanCount do
            local item = transposer.getStackInSlot(outputSide, i) --Previous loop ensures the slots aren't empty
            local _,type = utility.getBee(item)
            if type == "Princess" then
                princessSlot = i
                princess = item
                if item.individual.active.species.name == beeName then
                    princessPureness = princessPureness + 1
                end
                if item.individual.inactive.species.name == beeName then
                    princessPureness = princessPureness + 1
                end
            else
                local dronePureness = 0
                if item.individual.active.species.name == beeName then
                    dronePureness = dronePureness + 1
                end
                if item.individual.inactive.species.name == beeName then
                    dronePureness = dronePureness + 1
                end
                if dronePureness > bestDronePureness then
                    bestDronePureness = dronePureness
                    bestDroneSlot = i
                    bestDrone = item
                end
            end
        end

        if (princessPureness + bestDronePureness) == 4 then
            print("Target bee is pure!")
            isPure = true
        elseif (princessPureness + bestDronePureness) > 0 then
            if (not messageSent) then
                messageSent = true
                print("Target species present!")
                print("IT IS RECOMMENDED THAT YOU TAKE OUT ANY MUTATION ALTERING FRAMES TO REDUCE THE RISK OF UNWANTED MUTATIONS.")
                os.sleep(5)
            end
            local princessSpecies = princess.individual.active.species.name .. "/" .. princess.individual.inactive.species.name
            local droneSpecies = bestDrone.individual.active.species.name .. "/" .. bestDrone.individual.inactive.species.name
            print("Breeding " .. princessSpecies .. " princess with " .. droneSpecies .. " drone.")
            transposer.transferItem(outputSide, breederSide, 1, princessSlot, 1) --Send princess to breeding slot
            transposer.transferItem(outputSide, breederSide, 1, bestDroneSlot, 2) --Send drone to breeding slot
            for i=1,scanCount do --Move the other drones to the garbage container
                transposer.transferItem(outputSide, garbageSide, 64, i)
            end
        else
            print("TARGET SPECIES LOST!")
            transposer.transferItem(outputSide,breederSide, 1, princessSlot) -- Move to breeder for conversion
            for i=1,scanCount do --Get rid of the useless bees
                transposer.transferItem(outputSide, garbageSide, 64, i)
            end
            utility.convertPrincess(basePrincessSpecies, storageSide, breederSide, garbageSide, scannerSide, outputSide)

            local otherDroneSlot = utility.findBeeWithType(basePrincessSpecies, "Drone", storageSide) --other drone species is the same as the base princess species
            local otherDrone = transposer.getStackInSlot(storageSide, otherDroneSlot)
            if otherDrone.size < 32 then
                utility.populateBee(basePrincessSpecies, storageSide, breederSide, scannerSide, outputSide)
            end
            messageSent = false
            return utility.breed(beeName, breedData, storageSide, breederSide, garbageSide, scannerSide, outputSide)
        end
    end
    for i=1,scanCount do
        if i ~= bestDroneSlot and i ~= princessSlot then
            transposer.transferItem(outputSide,garbageSide, 64, i) --Move irrelevant drones to garbage
        end
    end
    utility.ensureGeneticEquivalence(princessSlot, bestDroneSlot, storageSide, breederSide, garbageSide, scannerSide, outputSide) --Makes sure all genes are equal. will move genetically equivalent bee to storage
    print("Breeding finished. " .. beeName .. " and its drone moved to storage.")
end

function utility.ensureGeneticEquivalence(princessSlot, droneSlot, storageSide, breederSide, garbageSide, scannnerSide, outputSide)
    local princess = transposer.getStackInSlot(outputSide,princessSlot)
    local drone = transposer.getStackInSlot(outputSide,droneSlot)
    local targetGenes = princess.individual.active
    local isEquivalent = utility.isGeneticallyEquivalent(princess, drone)
    if isEquivalent then
        print("Target bee is genetically consistent!")
        transposer.transferItem(outputSide, storageSide, 1, princessSlot)
        transposer.transferItem(outputSide, storageSide, 64, droneSlot)
        return
    else
        print("TARGET BEE SHAT ITSELF. NOT IMPLEMENTED.")
        return
    end
end

function utility.isGeneticallyEquivalent(princess, drone)
    for gene, value in pairs(princess.individual.active) do
        if type(value) == "table" then
            for tName, tValue in pairs(value) do
                if princess.individual.inactive[gene][tName] ~= tValue then
                    return false
                end
                if drone.individual.active[gene][tName] ~= tValue then
                    return false
                end
                if drone.individual.inactive[gene][tName] ~= tValue then
                    return false
                end
            end
        else
            if princess.individual.inactive[gene] ~= value then
                return false
            end
            if drone.individual.active[gene] ~= value then
                return false
            end
            if drone.individual.inactive[gene] ~= value then
                return false
            end
        end
    end
    return true
end

function utility.findBeeWithType(targetName, targetType, storageSide)
    local size = transposer.getInventorySize(storageSide)
    for i=1,size do
        local item = transposer.getStackInSlot(storageSide,i)
        if item ~= nil then
            local species, type = utility.getBee(item)
            if type == targetType and species == targetName then
                return i
            end
        end
    end
    return -1
end

--Takes the table from getBeeParents() 
function utility.findPair(pair, storageSide)
    local size = transposer.getInventorySize(storageSide)
    local princess1 = nil
    local princess2 = nil
    local drone1 = nil
    local drone2 = nil

    for i=1,size do
        local item = transposer.getStackInSlot(storageSide,i)
        if item ~= nil then
            local species, type = utility.getBee(item)
            if type == "Drone" then
                if species == pair.allele1.name then
                    drone1 = i
                end
                if species == pair.allele2.name then
                    drone2 = i
                end
            end
            if type == "Princess" then
                if species == pair.allele1.name then
                    princess1 = i
                end
                if species == pair.allele2.name then
                    princess2 = i
                end
            end
        end
        if princess1 and drone2 then
            return table.unpack({princess1, drone2})
        end
        if princess2 and drone1 then
            return table.unpack({princess2, drone1})
        end
    end
    return table.unpack({-1,-1})
end

function utility.findPairString(bee1, bee2, storageSide)
    local size = transposer.getInventorySize(storageSide)
    local princess1 = nil
    local princess2 = nil
    local drone1 = nil
    local drone2 = nil

    for i=1,size do
        local item = transposer.getStackInSlot(storageSide,i)
        if item ~= nil then
            local species, type = utility.getBee(item)
            if type == "Drone" then
                if species == bee1 then
                    drone1 = i
                end
                if species == bee2 then
                    drone2 = i
                end
            end
            if type == "Princess" then
                if species == bee1 then
                    princess1 = i
                end
                if species == bee2 then
                    princess2 = i
                end
            end
        end
        if princess1 and drone2 then
            return table.unpack({princess1, drone2})
        end
        if princess2 and drone1 then
            return table.unpack({princess2, drone1})
        end
    end
    return table.unpack({-1,-1})
end

function utility.getBee(bee)
    local name = ""
    if bee.label ~= nil then
        name = bee.label
    else
        name = bee.displayName
    end
    local words = {}
    for word in string.gmatch(name,"%S+") do
        table.insert(words,word)
    end
    local species = words[1]
    for i=2,(#words-1) do
        species = species .. " " .. words[i]
    end
    local type = words[#words]
    return table.unpack({species,type})
end

function utility.checkPrincess(breederSide, scannerSide, outputSide)
    for i=3,9 do
        local item = transposer.getStackInSlot(breederSide,i)
        if item ~= nil then
            local species,type = utility.getBee(item)
            if type == "Princess" then
                transposer.transferItem(breederSide,scannerSide, 1, i)
                while transposer.getStackInSlot(outputSide, 1) == nil do
                    os.sleep(1)
                end
                local princess = transposer.getStackInSlot(outputSide, 1)
                return utility.areGenesEqual(princess.individual)
            end
        end
    end
    return false
end

function utility.areGenesEqual(geneTable)
    for gene,value in pairs(geneTable.active) do
        if type(value) == "table" then
            for name,tValue in pairs(value) do
                if geneTable.inactive[gene][name] ~= tValue then
                    return false
                end
            end
        elseif value ~= geneTable.inactive[gene] then
            return false
        end
    end
    return true
end
return utility

