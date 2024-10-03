local component = require("component")
local config = require("config")
local filesystem = require("filesystem")
local event = require("event")
local utility = {}
local transposer = component.transposer
local modem = nil
if next(component.list("modem")) ~= nil then
    modem = component.modem
end

function utility.createBreedingChain(beeName, breeder, sideConfig, existingBees)
    local startingParents = utility.processBee(beeName, breeder, "TARGET BEE!")
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
    return table.unpack({breedingChain,existingBees})
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

function utility.listBeesInStorage(sideConfig)
    local size = transposer.getInventorySize(sideConfig.storage)
    local bees = {}

    for i=1,size do
        local bee = transposer.getStackInSlot(sideConfig.storage, i)
        if bee ~= nil then
            local species,type = utility.getItemName(bee)


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
function utility.convertPrincess(beeName, sideConfig)
    print("Converting princess to " .. beeName)
    local droneSlot = nil
    local targetGenes = nil
    local princess = transposer.getStackInSlot(sideConfig.breeder, 1)
    local princessSlot = nil
    local princessName = nil
    if princess ~= nil then
        local species,_ = utility.getItemName(princess)
        princessName = species
    end
    local size = transposer.getInventorySize(sideConfig.storage)
    --Since frame slots are slots 10,11,12 for the apiary there is no need to make any offsets

    for i=1,size do
        if droneSlot == nil or princess == nil then
            local bee = transposer.getStackInSlot(sideConfig.storage,i)
            if bee ~= nil then
                local species,type = utility.getItemName(bee)
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
        print("Can't find drone or you don't have the required amount of drones (16)! Aborting.")
        return
    end
    if targetGenes == nil or targetGenes.active == nil then
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
    safeTransfer(sideConfig.storage,sideConfig.breeder, 1, droneSlot, "storage", "breeder")
    if princessSlot ~= nil then
        safeTransfer(sideConfig.storage,sideConfig.breeder, 1, princessSlot, "storage", "breeder")
    end

    local princessConverted = false
    while(not princessConverted) do
        --Cycle finished if slot 1 is empty
        if transposer.getStackInSlot(sideConfig.breeder, 1) == nil then
            for i=3,9 do
                local item = transposer.getStackInSlot(sideConfig.breeder,i)
                if item ~= nil then
                    local species,type = utility.getItemName(item)
                    if type == "Drone" and item.size == targetGenes.active.fertility and species == beeName then
                        print("Scanning princess...")
                        princessConverted = utility.checkPrincess(sideConfig) --This call will move the princess to sideConfig.output
                        if (not princessConverted) then
                            print("Princess is not a perfect copy! Continuing.")
                            safeTransfer(sideConfig.output,sideConfig.breeder, 1, 1, "output", "breeder") --Move princess back to input
                            safeTransfer(sideConfig.storage, sideConfig.breeder, 1, droneSlot, "storage", "breeder") --Move drone from storage to breed slot
                        end
                    end
                end
            end
            if(not princessConverted) then
                for i=3,9 do
                    local item = transposer.getStackInSlot(sideConfig.breeder,i)
                    if item ~= nil then
                        local species,type = utility.getItemName(item)
                        if type == "Princess" then
                            safeTransfer(sideConfig.breeder, sideConfig.breeder, 1, i, "breeder", "breeder") --Move princess back to input slot
                            safeTransfer(sideConfig.storage, sideConfig.breeder, 1, droneSlot, "storage", "breeder") --Move drone from storage to breed slot
                        else
                            safeTransfer(sideConfig.breeder, sideConfig.garbage, item.size, i, "breeder", "garbage")
                        end
                    end
                end
            end
        end
        os.sleep(1)
    end
    print("Conversion complete!")
    for i=3,9 do --clean up the drones
        local item = transposer.getStackInSlot(sideConfig.breeder, i)
        if item ~= nil then
            safeTransfer(sideConfig.breeder, sideConfig.garbage, item.size, i, "breeder", "garbage")
        end
    end
    safeTransfer(sideConfig.output,sideConfig.storage, 1, 1, "output", "storage")
    print(beeName .. " princess moved to storage.")
end

function utility.populateBee(beeName, sideConfig, targetCount)
    local droneOutput = nil
    print("Populating " .. beeName .. " bee.")
    local princessSlot, droneSlot = utility.findPairString(beeName, beeName, sideConfig)
    if(princessSlot == -1 or droneSlot == -1) then
        print("Couldn't find princess or drone! Aborting.")
        return
    end
    local princess = transposer.getStackInSlot(sideConfig.storage, princessSlot)
    local genes = princess.individual.active
    if genes.fertility == 1 then
        print("This bee has 1 fertility! I can't populate this! Aborting.")
        return
    end
    print(beeName .. " bees found!")
    --Because the drones in storage are scanned you can only insert 1. the rest will be taken from output of the following cycles
    safeTransfer(sideConfig.storage, sideConfig.breeder, 1, princessSlot, "storage", "breeder")
    safeTransfer(sideConfig.storage, sideConfig.breeder, 1, droneSlot, "storage", "breeder")
    local item = nil
    while(item == nil or item.size < targetCount) do
        while(transposer.getStackInSlot(sideConfig.breeder,1) ~= nil) do --Wait until cycle is finished
            os.sleep(1)
        end
        if droneOutput == nil then
            for i=3,9 do
                local candidate = transposer.getStackInSlot(sideConfig.breeder,i)
                if candidate ~= nil then
                    local _,type = utility.getItemName(candidate)
                    if type == "Drone" then
                        print("Drones located in slot: " .. i)
                        if droneOutput ~= nil then
                            print("HEY! YOU'RE NOT SUPPOSED TO MAKE MORE THAN 2 DRONE STACKS WHEN POPULATING! TERMINATING PROGRAM.")
                            os.exit()
                        end
                        droneOutput = i
                    end
                end
            end
        else
            item = transposer.getStackInSlot(sideConfig.breeder, droneOutput)
            print("Populating progress: " .. item.size .. "/" .. targetCount)
            if (item.size < targetCount) then
                safeTransfer(sideConfig.breeder,sideConfig.breeder, 1, droneOutput, "breeder", "breeder") --Move a single drone back to the breeding slot
                for i=3,9 do
                    local candidate = transposer.getStackInSlot(sideConfig.breeder,i)
                    if candidate ~= nil then
                        local _,type = utility.getItemName(candidate)
                        if type == "Princess" then
                            safeTransfer(sideConfig.breeder,sideConfig.breeder,1, i, "breeder", "breeder") --Move princess back to breeding slot
                        end
                    end
                end
            end
        end
    end
    print("Populating complete! Sending " .. beeName .. " bees to scanner.")
    for i=3,9 do
        local item = transposer.getStackInSlot(sideConfig.breeder,i)
        if item ~= nil then
            local _,type = utility.getItemName(item)
            if type ~= "Princess" and type ~= "Drone" then
                safeTransfer(sideConfig.breeder,sideConfig.garbage,64,i, "breeder", "garbage")
            else
                safeTransfer(sideConfig.breeder,sideConfig.scanner,64,i, "breeder", "scanner")
            end
        end
    end
    while transposer.getStackInSlot(sideConfig.output, 2) == nil do
        os.sleep(1)
    end
    safeTransfer(sideConfig.output,sideConfig.storage,64,1, "output", "storage")
    safeTransfer(sideConfig.output,sideConfig.storage,64,2, "output", "storage")

    print("Scanned! " .. beeName .. " bees sent to storage.")
end


function utility.breed(beeName, breedData, sideConfig, robotMode)
    print("Breeding " .. beeName .. " bee.")
    local basePrincessSlot, baseDroneSlot = utility.findPair(breedData, sideConfig)
    if basePrincessSlot == -1 or baseDroneSlot == -1 then
        print("Couldn't find the parents of " .. beeName .. " bee! Aborting.")
        return
    end
    local basePrincess = transposer.getStackInSlot(sideConfig.storage, basePrincessSlot) --In case princess needs to be converted
    local basePrincessSpecies,_ = utility.getItemName(basePrincess)
    local chance = breedData.chance

    local breederSize = transposer.getInventorySize(sideConfig.breeder)
    if(breederSize == 12) then --Apiary exclusive.
        for i=10,12 do
            local frame = transposer.getStackInSlot(sideConfig.breeder,i)
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
    local requirements = breedData.specialConditions
    local botPlaced = false
    if next(requirements) ~= nil then
        print("This bee has the following special requirements: ")
        for _, req in pairs(requirements) do
            print(req)
            local foundationBlock = req:match("Requires ([a-zA-Z ]+) as a foundation")
            if robotMode and foundationBlock ~= nil then
                print("Telling the robot to place: " .. foundationBlock)
                modem.broadcast(config.robotPort, "place " .. foundationBlock)
                os.sleep(0.5)
                local _, _, _, _, _, actionTaken = event.pull("modem_message")
                if actionTaken  == true then
                    print("Robot successfuly placed: " .. foundationBlock)
                    botPlaced = true
                else
                    print("Robot could not place " .. foundationBlock .. ". Please do it yourself.")
                end
            end
        end
        if #requirements == 1 and botPlaced then
            print("The robot dealt with all of the requirements! Proceeding.")
        else
            print("Press enter when you've made sure the conditions are met.")
            io.read()
        end
        
    end

    safeTransfer(sideConfig.storage,sideConfig.breeder, 1, basePrincessSlot, "storage", "breeder")
    safeTransfer(sideConfig.storage,sideConfig.breeder, 1, baseDroneSlot, "storage", "breeder")
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

    while(not isPure) or (not isGeneticallyPerfect) do
        while(transposer.getStackInSlot(sideConfig.breeder,1) ~= nil) do
            os.sleep(1)
        end
        print("Scanning bees...")
        scanCount = utility.dumpBreeder(sideConfig, true)
        if scanCount == 0 then
            print("HEY! YOU TOOK OUT THE BEE! PUT A PRINCESS + DRONE IN THE BREEDER!")
            while(transposer.getStackInSlot(sideConfig.breeder,3) == nil) do
                os.sleep(1)
            end
            print("Continuing...")
            goto continue
        end
        while(transposer.getStackInSlot(sideConfig.output, scanCount) == nil) do
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
            local item = transposer.getStackInSlot(sideConfig.output, i) --Previous loop ensures the slots aren't empty
            local _,type = utility.getItemName(item)
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
            isGeneticallyPerfect = utility.ensureGeneticEquivalence(princessSlot, bestDroneSlot, sideConfig) --Makes sure all genes are equal. will move genetically equivalent bee to storage
            if not isGeneticallyPerfect then
                print("Target bee is not genetically consistent! continuing")
                safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder") --Send princess to breeding slot
                safeTransfer(sideConfig.output, sideConfig.breeder, 1, bestDroneSlot, "output", "breeder") --Send drone to breeding slot
                dumpOutput(sideConfig, scanCount)
            end
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
            safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder") --Send princess to breeding slot
            safeTransfer(sideConfig.output, sideConfig.breeder, 1, bestDroneSlot, "output", "breeder") --Send drone to breeding slot
            for i=1,scanCount do --Move the other drones to the garbage container
                safeTransfer(sideConfig.output, sideConfig.garbage, 64, i, "output", "garbage")
            end
        else
            print("TARGET SPECIES LOST!")
            safeTransfer(sideConfig.output,sideConfig.breeder, 1, princessSlot, "output", "breeder") -- Move to breeder for conversion
            for i=1,scanCount do --Get rid of the useless bees
                safeTransfer(sideConfig.output, sideConfig.garbage, 64, i, "output", "garbage")
            end
            utility.convertPrincess(basePrincessSpecies, sideConfig)

            local otherDroneSlot = utility.findBeeWithType(basePrincessSpecies, "Drone", sideConfig) --other drone species is the same as the base princess species
            local otherDrone = transposer.getStackInSlot(sideConfig.storage, otherDroneSlot)
            if otherDrone.size < 32 then
                utility.populateBee(basePrincessSpecies, sideConfig, 16)
            end
            messageSent = false
            return utility.breed(beeName, breedData, sideConfig)
        end
        ::continue::
    end
    for i=1,scanCount do
        if i ~= bestDroneSlot and i ~= princessSlot then
            safeTransfer(sideConfig.output,sideConfig.garbage, 64, i, "output", "garbage") --Move irrelevant drones to garbage
        end
    end
    print("Breeding finished. " .. beeName .. " princess and its drones moved to storage.")
end

function utility.ensureGeneticEquivalence(princessSlot, droneSlot, sideConfig)
    local princess = transposer.getStackInSlot(sideConfig.output,princessSlot)
    local drone = transposer.getStackInSlot(sideConfig.output,droneSlot)
    local targetGenes = princess.individual.active
    local isEquivalent = utility.isGeneticallyEquivalent(princess, drone, princess.individual.active, false)
    if isEquivalent then
        print("Target bee is genetically consistent!")
        safeTransfer(sideConfig.output, sideConfig.storage, 1, princessSlot, "output", "storage")
        safeTransfer(sideConfig.output, sideConfig.storage, 64, droneSlot, "output", "storage")
        return true
    end
    return false
end

function utility.imprintFromTemplate(beeName, sideConfig, templateGenes)
    print("Imprinting template genes onto " .. beeName .. " bee.")
    local size = transposer.getInventorySize(sideConfig.storage)

    local templateDrone = transposer.getStackInSlot(sideConfig.storage, size)
    if templateDrone == nil then
        print("You don't have a template drone (It goes in the last slot of your storage container)! Aborting.")
        return false
    end

    local basePrincessSlot, baseDroneSlot = utility.findPairString(beeName, beeName, sideConfig)
    if basePrincessSlot == nil or baseDroneSlot == nil then
        print("This species doesn't have both drones and a princess in your storage container! Aborting.")
        return false
    end

    local basePrincess = transposer.getStackInSlot(sideConfig.storage, basePrincessSlot)
    local baseDrone = transposer.getStackInSlot(sideConfig.storage, baseDroneSlot)
    if templateGenes == nil then
        templateGenes = templateDrone.individual.active
    end

    if utility.isGeneticallyEquivalent(basePrincess, templateDrone, templateGenes, true) then
        print("This bee already has template genes! Aborting.")
        return false
    end


    safeTransfer(sideConfig.storage, sideConfig.breeder, 1, basePrincessSlot, "storage", "breeder")
    safeTransfer(sideConfig.storage, sideConfig.breeder, 1, size, "storage", "breeder") -- Last slot in storage is reserved for template bees.

    
    local isImprinted = false
    local princess = nil
    local princessScore = 0
    local PrincessSlot = nil
    local bestDrone = nil
    local bestDroneScore = -1
    local bestDroneSlot = nil
    local scanCount = 0

    local bestReserveDrone = nil
    local bestReserveScore = -1
    local bestReserveSlot = nil
    while not isImprinted do
        local scanCount = 0
        princessScore = 0
        princessPureness = 0
        princessSlot = nil
        bestDroneScore = -1
        bestDronePureness = 0
        bestDroneSlot = nil
        scanCount = 0
        while transposer.getStackInSlot(sideConfig.breeder, 1) ~= nil do --Wait for cycle finish
            os.sleep(1)
        end
        scanCount = utility.dumpBreeder(sideConfig, true)
        if scanCount == 0 then
            print("HEY! YOU TOOK OUT THE BEE! PUT A PRINCESS + DRONE IN THE BREEDER!")
            while(transposer.getStackInSlot(sideConfig.breeder,3) == nil) do
                os.sleep(1)
            end
            print("Continuing...")
            goto continue
        end
        print("Scanning...")
        while transposer.getStackInSlot(sideConfig.output, scanCount) == nil do --Wait for scan finish
            os.sleep(1)
        end
        print("Grading...")
        for i=1,scanCount do
            local bee = transposer.getStackInSlot(sideConfig.output, i) --scanCount guarantees there are bees in these slots
            local _,type = utility.getItemName(bee)
            if type == "Princess" then
                princess = bee
                princessScore = utility.getGeneticScore(bee, templateGenes, basePrincess.individual.active.species)
                princessPureness = utility.getBeePureness(beeName, bee)
                princessSlot = i
            else
                local droneScore = utility.getGeneticScore(bee, templateGenes, basePrincess.individual.active.species)
                if droneScore > bestDroneScore then
                    bestDrone = bee
                    bestDroneScore = droneScore
                    bestDronePureness = utility.getBeePureness(beeName, bee)
                    bestDroneSlot = i
                end
            end
        end

        local geneticSum = princessScore + bestDroneScore
        print("Genetic score: " .. geneticSum .. "/" .. config.targetSum*2)
        if (tostring(geneticSum) == tostring(config.targetSum*2)) then --Avoids floating point arithmetic errors
            print("Genetic imprint succeeded!")
            print("Dumping original drones...")
            utility.dumpDrones(beeName, sideConfig)
            safeTransfer(sideConfig.output, sideConfig.storage, 1, princessSlot, "output", "storage")
            safeTransfer(sideConfig.output, sideConfig.storage, 64, bestDroneSlot, "output", "storage")
            print("Imprinted bee moved to storage.")
            dumpOutput(sideConfig, scanCount)
            return true
        end

        if (princessPureness + bestDronePureness) == 4 then
            print("PRINCESS AND DRONE ARE PURELY ORIGINAL SPECIES!")
            if utility.hasTargetGenes(princess, bestDrone, templateGenes) then
                print("Target gene pool reachable. Continuing.")
                continueImprinting(sideConfig, princessSlot, bestDroneSlot, scanCount)
            else
                print("Target gene pool unreachable. substituting drone for template drone.")
                safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder")
                safeTransfer(sideConfig.storage, sideConfig.breeder, 1, size, "storage", "breeder") -- Last slot in storage is reserved for template bees.
                for i=1,scanCount do
                    safeTransfer(sideConfig.output, sideConfig.garbage, 64, i, "output", "garbage")
                end
            end

        elseif (princessPureness + bestDronePureness) == 0 then
            print("ORIGINAL SPECIES LOST!")
            print("Looking for reserve drone...")
            bestReserveDrone = nil
            bestReserveScore, bestReserveSlot = getBestReserve(beeName, sideConfig, templateGenes)
            bestReserveDrone = transposer.getStackInSlot(sideConfig.garbage, bestReserveSlot)
            if bestReserveDrone ~= nil then
                print("Found reserve drone with genetic score " .. bestReserveScore .. "/" .. config.targetSum)
                safeTransfer(sideConfig.garbage, sideConfig.breeder, 1, bestReserveSlot, "garbage", "breeder")
                safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder")
                dumpOutput(sideConfig, scanCount)
            else
                print("Couldn't find reserve drone! Substituting base drone")
                safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder")
                if (safeTransfer(sideConfig.storage, sideConfig.breeder, 1, baseDroneSlot, "storage", "breeder") == 0) then
                    print("OUT OF BASE DRONES! TERMINATING.")
                    os.exit()
                end
                dumpOutput(sideConfig, scanCount)
            end
        elseif (princessPureness + bestDronePureness) == 1 then
            print("BEE AT RISK OF LOSING ORIGINAL SPECIES!")
            continueImprinting(sideConfig, princessSlot, bestDroneSlot, scanCount)
        else
            continueImprinting(sideConfig, princessSlot, bestDroneSlot, scanCount)
        end
        ::continue::
    end
    return false
end

function getBestReserve(beeName, sideConfig, targetGenes)
    local reserveSize = transposer.getInventorySize(sideConfig.garbage)
    local bestReserveScore = -1
    local bestReserveSlot = nil
    local nilCounter = 0
    for i=1,reserveSize do
        local bee = transposer.getStackInSlot(sideConfig.garbage, i)
        if bee == nil then
            nilCounter = nilCounter + 1
            if nilCounter > 10 then
                return table.unpack({bestReserveScore, bestReserveSlot})
            end
        else
            if bee.individual == nil or bee.individual.active == nil then
                goto continue
            end
            if bee.individual.active ~= nil then
                local score = -1
                if bee.individual.active.species.name == beeName then
                    score = utility.getGeneticScore(bee, targetGenes, bee.individual.active.species)
                elseif bee.individual.inactive.species.name == beeName then
                    score = utility.getGeneticScore(bee, targetGenes, bee.individual.inactive.species)
                end
                if score > bestReserveScore then
                    bestReserveScore = score
                    bestReserveSlot = i
                end
            end
        end
        ::continue::
    end
    if bestReserveSlot ~= nil and transposer.getStackInSlot(sideConfig.garbage, bestReserveSlot) == nil then
        print("BEST RESERVE DRONE DISAPPEARED! TRYING AGAIN...")
        return getBestReserve(beeName, sideConfig, targetGenes)
    end
    return table.unpack({bestReserveScore, bestReserveSlot})
end
function utility.dumpDrones(beeName, sideConfig)
    local storageSize = transposer.getInventorySize(sideConfig.storage)
    for i=1,storageSize do
        local bee = transposer.getStackInSlot(sideConfig.storage, i)
        if bee ~= nil then
            local species = utility.getItemName(bee)
            if species == beeName then
                safeTransfer(sideConfig.storage, sideConfig.garbage, 64, i, "storage", "garbage")
            end
        end
    end
end
function continueImprinting(sideConfig, princessSlot, droneSlot, scanCount)
    safeTransfer(sideConfig.output, sideConfig.breeder, 1, princessSlot, "output", "breeder")
    safeTransfer(sideConfig.output, sideConfig.breeder, 1, droneSlot, "output", "breeder")
    dumpOutput(sideConfig, scanCount)
end

function dumpOutput(sideConfig, scanCount)
    for i=1,scanCount do
        safeTransfer(sideConfig.output, sideConfig.garbage, 64, i, "output", "garbage")
    end
end
function utility.hasTargetGenes(princess, drone, targetGenes)
    for gene, value in pairs(targetGenes) do
        if gene == "species" then
        elseif type(value) == "table" then
            for tName, tValue in pairs(value) do
                if princess.individual.active[gene][tName] ~= tValue and drone.individual.active[gene][tName] ~= tValue and 
                    princess.individual.inactive[gene][tName] ~= tValue and drone.individual.inactive[gene][tName] ~= tValue then
                    return false
                end
            end
        else
            if princess.individual.active[gene] ~= value and princess.individual.inactive[gene] ~= value and
                drone.individual.active[gene] ~= value and drone.individual.inactive[gene] ~= value then
                return false
            end
        end
    end
    return true
end
function utility.getBeePureness(beeName, bee)
    local pureness = 0
    if bee.individual.active.species.name == beeName then
        pureness = pureness + 1
    end
    if bee.individual.inactive.species.name == beeName then
        pureness = pureness + 1
    end
    return pureness
end
function utility.getGeneticScore(bee, targetGenes, speciesTarget)
    local geneticScore = 0
    for gene, value in pairs(targetGenes) do
        local weight = config.geneWeights[gene]
        local bonusExp = 1
        if gene == "species" then
            bonusExp = 0
            value = speciesTarget
        end
        if weight ~= nil then
            if type(value) == "table" then
                local matchesActive = true
                local matchesInactive = true
                for tName, tValue in pairs(value) do
                    if bee.individual.active[gene][tName] ~= tValue then
                        matchesActive = false
                    end
                    if bee.individual.inactive[gene][tName] ~= tValue then
                        matchesInactive = false
                    end
                end
                if matchesActive then
                    geneticScore = geneticScore + weight*(config.activeBonus^bonusExp)
                end
                if matchesInactive then
                    geneticScore = geneticScore + weight
                end
            else
                if bee.individual.active[gene] == value then
                    geneticScore = geneticScore + weight*(config.activeBonus^bonusExp)
                end
                if bee.individual.inactive[gene] == value then
                    geneticScore = geneticScore + weight
                end
            end
        end
    end
    return geneticScore
end
function utility.dumpBreeder(sideConfig, scanDrones)
    local dumpedBees = 0
    for i=3,9 do
        local item = transposer.getStackInSlot(sideConfig.breeder, i)
        if item ~= nil then
            local name,type = utility.getItemName(item)
            if type == "Comb" then
                safeTransfer(sideConfig.breeder, sideConfig.garbage, 64, i, "breeder", "garbage")
            else
                if scanDrones or type == "Princess" then
                    dumpedBees = dumpedBees + 1
                    safeTransfer(sideConfig.breeder, sideConfig.scanner, 64, i, "breeder", "scanner")
                else
                    safeTransfer(sideConfig.breeder, sideConfig.garbage, 64, i, "breeder", "garbage")
                end
            end
        end
    end
    return dumpedBees
end
function utility.isGeneticallyEquivalent(princess, drone, targetGenes, omitSpecies)
    for gene, value in pairs(targetGenes) do
        if gene == "species" and omitSpecies then
        elseif type(value) == "table" then
            for tName, tValue in pairs(value) do
                if princess.individual.active[gene][tName] ~= tValue then
                    return false
                end
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
            if princess.individual.active[gene] ~= value then
                return false
            end
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

function utility.findBeeWithType(targetName, targetType, sideConfig)
    local size = transposer.getInventorySize(sideConfig.storage)
    for i=1,size do
        local item = transposer.getStackInSlot(sideConfig.storage,i)
        if item ~= nil then
            local species, type = utility.getItemName(item)
            if type == targetType and species == targetName then
                return i
            end
        end
    end
    return -1
end

--Takes the table from getBeeParents() 
function utility.findPair(pair, sideConfig)
    local size = transposer.getInventorySize(sideConfig.storage)
    local princess1 = nil
    local princess2 = nil
    local drone1 = nil
    local drone2 = nil

    for i=1,size do
        local item = transposer.getStackInSlot(sideConfig.storage,i)
        if item ~= nil then
            local species, type = utility.getItemName(item)
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

function utility.findPairString(bee1, bee2, sideConfig)
    local size = transposer.getInventorySize(sideConfig.storage)
    local princess1 = nil
    local princess2 = nil
    local drone1 = nil
    local drone2 = nil

    for i=1,size do
        local item = transposer.getStackInSlot(sideConfig.storage,i)
        if item ~= nil then
            local species, type = utility.getItemName(item)
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

function utility.getItemName(bee)
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

function utility.checkPrincess(sideConfig)
    for i=3,9 do
        local item = transposer.getStackInSlot(sideConfig.breeder,i)
        if item ~= nil then
            local species,type = utility.getItemName(item)
            if type == "Princess" then
                safeTransfer(sideConfig.breeder,sideConfig.scanner, 1, i, "breeder", "scanner")
                while transposer.getStackInSlot(sideConfig.output, 1) == nil do
                    os.sleep(1)
                end
                local princess = transposer.getStackInSlot(sideConfig.output, 1)
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


function utility.getOrCreateConfig()
    if filesystem.exists("/home/sideConfig.lua") then
        local sideConfig = require("sideConfig")
        return sideConfig
    end
    local directions = {"down","up","north","south","west","east"}
    local remainingDirections = {"down","up","north","south","west","east"}
    local configOrder = {"storage","scanner","output","garbage"}
    local newConfig = {}

    print("It looks like this might be your first time running this program. Let's set up your containers!")
    print("All directions are relative to the transposer.")

    for _,container in pairs(configOrder) do
        print(string.format("Which side is the: %s? Select one of the following:", container))
        for i,direction in pairs(directions) do
            if indexInTable(remainingDirections, direction) ~= 0 then
                print(string.format("%d. %s", i, direction))
            end
        end
        local answeredCorrectly = false
        while not answeredCorrectly do
            local answer = io.read()
            if tonumber(answer) ~= nil then
                answer = tonumber(answer)
                if answer >= 1 and answer <= #directions then --Check if answer within bounds
                    newConfig[container] = answer - 1
                    table.remove(remainingDirections, indexInTable(remainingDirections, directions[answer]))
                    answeredCorrectly = true
                end
            else
                local index = indexInTable(directions, string.lower(answer))
                if index ~= 0 then
                    newConfig[container] = index - 1
                    table.remove(remainingDirections, indexInTable(remainingDirections, answer))
                    answeredCorrectly = true
                end
            end
            if not answeredCorrectly then
                print("I can't process this answer! Try again.")
            end
        end
    end
    print("Creating sideConfig.lua...")
    local file = filesystem.open("/home/sideConfig.lua", "w")
    file:write("local sideConfig = {\n")
    for container,side in pairs(newConfig) do
        file:write(string.format("[\"%s\"] = %d, \n", container, side))
    end
    file:write("}\n")
    file:write("return sideConfig")
    file:close()
    print("Done! Setup Complete!")
    return newConfig
end

function safeTransfer(sideIn, sideOut, amount, slot, sideInName, sideOutName)
    if (transposer.transferItem(sideIn, sideOut, amount, slot) == 0 and transposer.getStackInSlot(sideIn, slot) ~= nil) then
        print(string.format("TRANSFER FROM SLOT %d OF CONTAINER: %s TO CONTAINER: %s FAILED! PLEASE DO IT MANUALLY OR CLEAN THE %s CONTAINER!", slot, sideInName:upper(), sideOutName:upper(), sideOutName:upper()))
        while(transposer.getStackInSlot(sideIn, slot) ~= nil) do
            os.sleep(1)
            transposer.transferItem(sideIn, sideOut, amount, slot)
        end
    end
end
function indexInTable(tbl, target)
    for i,value in pairs(tbl) do
        if value == target then
            return i
        end
    end
    return 0
end

return utility

