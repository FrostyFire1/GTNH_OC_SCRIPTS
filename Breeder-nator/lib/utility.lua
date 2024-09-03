local component = require("component")
local config = require("config")
local utility = {}
local transposer = component.transposer

function utility.createBreedingChain(beeName, breeder, storageSide)
    local startingParents = utility.processBee(beeName, breeder)
    if(startingParents == nil) then
        print("Bee has no parents!")
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

            --Process parents only if they're not already in the breeding chain
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
            --Skip the bee if it's already present in the breeding chain or the queue
            if breedingChain[child] == nil and queue[child] == nil then
            queue[child] = parents
            end
            if breedingChain[child] == nil then
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

    print("Detected conflict! Please choose one of the following parents for the " .. beeName .. " bee (Breeds into " .. child .. "bee): ")
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

function utility.listBeesInChest(chestSide)
    local size = transposer.getInventorySize(chestSide)
    local bees = {}

    for i=1,size do
        bee = transposer.getStackInSlot(chestSide, i)
        if bee ~= nil then
            local words = {}
            for word in string.gmatch(bee.label,"%S+") do
                table.insert(words,word)
            end
            local species = words[1]
            local type = words[2]

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
return utility