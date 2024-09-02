local component = require("component")

local utility = {}

function utility.createBreedingChain(beeName, breeder, storageSide, transposer)
    local startingParents = table.unpack(breeder.getBeeParents(beeName))
    if(next(startingparents) == nil) then
        return {}
    end
    local breedingChain = {startingParents}
    local queue = {startingParents}
    local current = {}

    while next(queue) ~= nil then
        for _,parentPair in pairs(queue) do
            local leftParents = table.unpack(breeder.getBeeParents(parentPair.allele1.name))
            local rightParents = table.unpack(breeder.getBeeParents(parentPair.allele2.name))

            if leftParents ~= nil then
                table.insert(current, leftParents)
            end
            if rightParents ~= nil then
                table.insert(current, rightParents)
            end
        end
        queue = {}
        for _,parentPair in pairs(current) do
            table.insert(queue, parentPair)
            table.insert(breedingChain, parentPair)
        end
        current = {}
    end
    return breedingChain
end

return utility