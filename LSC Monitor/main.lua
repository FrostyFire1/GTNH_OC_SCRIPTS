local component = require("component")
local util = require("LSC_Util")
local glasses = component.glasses


glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = util.getLSC_List()
print(LSC_List)

local testWidget = glasses.addTextLabel()
testWidget.setText("This program is working properly")
testWidget.setScale(1)
testWidget.setColor()
testWidget.setPosition(0,util.height * 0.9)