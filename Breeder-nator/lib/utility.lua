local component = require("component")

local utility = {}

function utility.createBreedingChain(beeName, breeder, storageSide)
    local startingParents = table.unpack(breeder.getBeeParents(beeName))
    if(startingParents == nil) then
        print("Bee has no parents!")
        return {}
    end
    local breedingChain = {startingParents}
    local queue = {startingParents}
    local current = {}

    while next(queue) ~= nil do
        for _,parentPair in pairs(queue) do
            print("Processing: " .. parentPair.allele1.name .. " and " .. parentPair.allele2.name)
            local leftParents = table.unpack(breeder.getBeeParents(parentPair.allele1.name))
            local rightParents = table.unpack(breeder.getBeeParents(parentPair.allele2.name))

            if leftParents ~= nil then
                print(leftParents.allele1.name .. " " .. leftParents.allele2.name)
                table.insert(current, leftParents)
            end
            if rightParents ~= nil then
                print(rightParents.allele1.name .. " " .. rightParents.allele2.name)
                table.insert(current, rightParents)
            end
            os.sleep(0.5)
        end
        queue = {}
        for _,newParents in pairs(current) do
            table.insert(queue, newParents)
            table.insert(breedingChain, newParents)
        end
        current = {}
    end
    return breedingChain
end

return utility