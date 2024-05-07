--Pattern Fixer by FrostyFire1
local constants = require("constants")
local component = require("component")
local term = require("term")

local interfaces = {}
local db = component.database
local dbAddress = db.address
local preferedInputs = {}

function processItem(itemStack, slotNum, inputNum, interface)
    local count,name = itemStack["count"], itemStack["name"]


    --Check if input is in the unwanted list
    local running = true
    for _, table in ipairs(constants.dbRows) do
        local key,dbRow = table[1], table[2]
        --matchDB is a 2D Array of every unwanted item in every voltage tier, ascending.
        matchDB = constants[key]
        local foundUnwanted = nil
        local itemTier = nil
        if running then 
        	checkResult = checkUnwanted(name, matchDB)
            foundUnwanted = checkResult[1] 
            itemTier = checkResult[2]
            running = not foundUnwanted
        end
		
        if foundUnwanted then
        	replaceItem(name,key,itemTier, dbRow, count, slotNum, inputNum, interface)    
        end
    end
end

--Checks if input item is unwanted. returns wether that's true and the tier of the item if applicable.
function checkUnwanted(name, matchDB)
    --matchArray is a 1D Array of every unwanted item in a given voltage tier.
    for tier, matchArray in pairs(matchDB) do 
        --matchItem is an inside the matchArray
        for _, matchItem in pairs(matchArray) do
            if name == matchItem and notInPreferedList(name) then return {true, tier} end 
        end
    end
    return {false, -1}
end

function replaceItem(name, key, tier, dbRow, count, slotNum, inputNum, interface)
    local position = dbRow*9 + tier
    local replacement = db.get(position)
    local replacementName = replacement["label"]
    print("MATCH FOUND: " .. name .. " || REPLACING WITH: " .. replacementName)
    interface.setInterfacePatternInput(slotNum, dbAddress, position, count, inputNum)
end

function notInPreferedList(name)
	for _, preferedInput in pairs(preferedInputs) do
        if name == preferedInput then return false end
    end
    return true
end
term.clear()

--Read prefered inputs from the text file
inputFile = io.open(constants.preferedInputPath)
for line in inputFile:lines() do
    table.insert(preferedInputs, line)
end

for address, _ in component.list("me_interface") do
   table.insert(interfaces, component.proxy(address))
end
    
for _, interface in pairs(interfaces) do
    for i = 1,36,1 do
        local pattern = interface.getInterfacePattern(i)

        if pattern then
            local inputs = pattern.inputs
            local outputs = pattern.outputs
            local outputString = ""
            for _,outputTable in pairs(outputs) do 
                if outputTable["name"] then
                    outputString = outputString .. outputTable["name"] .. ", " 
                end
            end
            print("Processing pattern for: " .. outputString)
            for inputNum,itemStack in pairs(inputs) do
                processItem(itemStack, i, inputNum, interface)


            end

        end

    end
end
