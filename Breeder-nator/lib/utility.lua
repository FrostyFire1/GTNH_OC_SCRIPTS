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

function utility.breed(beeName, parentPair, storageSide)

end

--Converts the first princess found in storage to the given bee type
--Assumes bee is scanned (Only scanned bees expose genes)
function utility.convertPrincess(beeName, storageSide, breederSide, garbageSide, scannerSide, outputSide)
    print("Converting princess to " .. beeName)
    local droneSlot = nil
    local stackSize = nil
    local targetGenes = nil
    local princessSlot = nil
    local princessName = nil

    local size = transposer.getInventorySize(storageSide)
    --Since frame slots are slots 10,11,12 for the apiary there is no need to make any offsets

    for i=1,size do
        if droneSlot == nil or princessSlot == nil then
            local bee = transposer.getStackInSlot(storageSide,i)
            if bee ~= nil then
                local species,type = utility.getBee(bee)
                if species == beeName and type == "Drone" and bee.size >= 16 and droneSlot == nil then
                    droneSlot = i
                    stackSize = bee.size
                    targetGenes = bee.individual
                elseif type == "Princess" and princessSlot == nil then
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
    if princessSlot == nil then
        print("Can't find princess! Aborting.")
        return
    end
    --Insert bees into the apiary
    print("Beginning conversion therapy using " .. beeName .. " drones and " .. princessName .. " princess")
    --First number is the amount of items transferred, the second is the slot number of the container items are transferred to
    --Move only 1 drone at a time to leave the apiary empty after the cycling is complete (you can't extract from input slots)
    transposer.transferItem(storageSide,breederSide, 1, droneSlot, 2) --Slot 2 for apiary is the drone slot
    transposer.transferItem(storageSide,breederSide, 1, princessSlot, 1) --Slot 1 for apiary is the princess slot

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
        transposer.transferItem(breederSide,scannerSide,64,i)
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

