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
            local species,type = getBee(bee)


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
--Assumes bee is not scanned (so the new purebreds can stack together)
function utility.convertPrincess(beeName, storageSide, breederSide)
    print("Converting princess to " .. beeName)
    local droneSlot = nil
    local targetGenes = nil
    local princessSlot = nil
    local princessName = nil
    local size = transposer.getInventorySize(storageSide)
    --Alveary has 3 less slots (because no frames) so offset needs to be determined
    local isApiary = transposer.getInventorySize(breederSide) == 12
    local offset = 0
    if isApiary then 
        offset = 3
    end

    for i=1,size do
        if droneSlot == nil and princessSlot == nil then
            local bee = transposer.getStackInSlot(storageSide,i)
            if bee ~= nil then
                local species,type = getBee(bee)
                if species == beeName and type == "Drone" and bee.size >= 16 and droneSlot == nil then
                    droneSlot = i
                    targetGenes = bee.individual
                elseif type == "Princess" and princessSlot == nil then
                    princessSlot = i
                    princessName = species
                end
            end
        end
    end
    --Insert bees into the apiary
    --First number is the amount of items transferred, the second is the slot number of the container items are transferred to
    print("Beginning conversion therapy using " .. beeName .. " drones and " .. princessName .. " princess")
    transposer.transferItem(storageSide,breederSide, 16, droneSlot, 2) --Slot 2 for apiary is the drone slot
    transposer.transferItem(storageSide,breederSide, 1, princessSlot, 1) --Slot 1 for apiary is the princess slot

    local princessConverted = false
    while(not princessConverted) do
        --Cycle finished if slot 1 is empty
        if transposer.getStackInSlot(breederSide, 1) == nil then
            for i=(3+offset),(9+offset) do
                local bee = transposer.getStackInSlot(breederSide,i)

                if bee ~= nil then
                    local species,type = getBee(bee)
                    if type == "Princess" then
                        transposer.transferItem(breederSide, breederSide, 1, i, 1)
                        
                    end
                end
            end
        end
        os.sleep(1)
    end

end

function utility.getBee(bee)
    local words = {}
    for word in string.gmatch(bee.label,"%S+") do
        table.insert(words,word)
    end
    local species = ""
    for i=1,(#words-1) do
        species = species .. " " .. words[i]
    end
    local type = words[#words]
    return table.unpack({species,type})
end


return utility

