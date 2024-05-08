local component = require("component")
local glasses = component.glasses
local testWidget = glasses.addTextLabel()
local height = 345
local width = 640

glasses.removeAll()

print(glasses.getBindPlayers())
testWidget.setText("This program is working properly")
testWidget.setPosition(0,345)