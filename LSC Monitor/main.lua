local component = require("component")
local util = require("LSC_Util")
local glasses = component.glasses


glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = util.getLSC_List()
for a,b in pairs(LSC_List) do
    print(a,b)
end

local energyBarText = glasses.addTextLabel()
energyBarText.setText("Energy Monitor by FrostyFire1")
energyBarText.setScale(1.3)
energyBarText.setColor(247, 67, 7)
energyBarText.setPosition(0,util.height * 0.85)

local energyBarOffsetX = 0
local energyBarOffsetY = util.height * 0.95
local energyBarWidth = 150
local energyBarHeight = 20
local triangleRatio = 0.9

local energyBarBorder = glasses.addQuad()
local borderThickness = 5

energyBarBorder.setVertex(1, energyBarOffsetX, energyBarOffsetY)
energyBarBorder.setVertex(2, energyBarOffsetX + energyBarWidth*triangleRatio, energyBarOffsetY)
energyBarBorder.setVertex(3, energyBarOffsetX, energyBarOffsetY - energyBarHeight)
energyBarBorder.setVertex(4, energyBarOffsetX + energyBarWidth, energyBarOffsetY)
energyBarBorder.setColor(87 , 7, 247)