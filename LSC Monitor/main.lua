local component = require("component")
local util = require("LSC_Util")
local math = require("math")
local glasses = component.glasses
local readingFrequency = 5
local readings = {}
local readingsLimit = (60 / readingFrequency) * 60

glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = util.getLSC_List()
for a,b in pairs(LSC_List) do
    print(a,b)
end

graphicalComponents = util.addGraphicalComponents(glasses)

while true do
    local lastReading = util.updateEUStored(graphicalComponents)
    table.insert(readings, lastReading)
    util.updateReadings(readings, lastReading, graphicalComponents)
    os.sleep(readingFrequency)
end
