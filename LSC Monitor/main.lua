local component = require("component")
local util = require("LSC_Util")
local math = require("math")
local glasses = component.glasses


glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = util.getLSC_List()
for a,b in pairs(LSC_List) do
    print(a,b)
end

util.addGraphicalComponents(glasses)

