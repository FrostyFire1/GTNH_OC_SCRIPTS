local component = require("component")
local util = require("LSC_Util")
local glasses = component.glasses


glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = getLSC_List()
print(LSC_List)

local testWidget = glasses.addTextLabel()
testWidget.setText("This program is working properly")
testWidget.setScale(1)
testWidget.setColor(7,47,247)
testWidget.setPosition(0,LSC_Util.height * 0.9)