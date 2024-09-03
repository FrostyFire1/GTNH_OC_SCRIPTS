local component = require("component")
local config = require("config")
local utility = {}

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
        for _,parentPair in pairs(queue) do
            print("Processing: " .. parentPair.allele1.name .. " and " .. parentPair.allele2.name)
            local leftParents = utility.processBee(parentPair.allele1.name, breeder)
            local rightParents = utility.processBee(parentPair.allele2.name, breeder)

            if leftParents ~= nil then
                print(parentPair.allele1.name .. ": " .. leftParents.allele1.name .. " + " .. leftParents.allele2.name)
                current[parentPair.allele1.name] = leftParents
            end
            if rightParents ~= nil then
                print(parentPair.allele2.name .. ": " .. rightParents.allele1.name .. " + " .. rightParents.allele2.name)
                current[parentPair.allele2.name] = rightParents
            end
        end
        queue = {}
        for child,newParents in pairs(current) do
            --Skip the bee if it's already present in the breeding chain
            if breedingChain[child] == nil and queue[child] == nil then
            queue[child] = newParents
            end
            if breedingChain[child] == nil then
            breedingChain[child] = newParents
            end
        end
        current = {}
    end
    return breedingChain
end

function utility.processBee(beeName, breeder)
    local parentPairs = breeder.getBeeParents(beeName)
    if #parentPairs == 0 then
        return nil
    elseif #parentPairs == 1 then
        return table.unpack(parentPairs)
    else
        local preference = config.preference[beeName]
        if preference == nil then
            return utility.resolveConflict(parentPairs)
        end
        for _,pair in pairs(parentPairs) do
            if (pair.allele1.name == preference[1] and pair.allele2.name == preference[2]) then
                return pair 
            end
        end
    end
    return nil
end

function utility.resolveConflict(parentPairs)
    print("CONFLICT RESOLUTION NOT YET IMPLEMENTED. CLOSING.")
    os.exit()
end
return utility