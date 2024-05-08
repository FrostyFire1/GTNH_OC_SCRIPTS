local component = require("component")
local math = require("math")

local LSC_Util = {}
local GUI_SCALE = 3
LSC_Util.height = 1080 / GUI_SCALE
LSC_Util.width = 1920 / GUI_SCALE

local textScale = 1
local miniTextScale = 0.8
local energyBarOffsetX = 5
local energyBarOffsetY = LSC_Util.height - 5*GUI_SCALE*miniTextScale - GUI_SCALE*0.5
local energyBarWidth = 150
local energyBarHeight = 15
local triangleRatio = 0.9
local borderThickness = 5 / 2


function getLSC_List()
    local LSC_LIST = {}
    for address,_ in component.list("gt_machine") do
        local proxy = component.proxy(address)
        if proxy.getName() == "multimachine.supercapacitor" then
            table.insert(LSC_LIST, proxy)
        end
    end
    return LSC_LIST
end

LSC_Util.getLSC_List = getLSC_List




function addGraphicalComponents(glasses)
    local result = {}



    local energyBarBorder = glasses.addQuad()
    energyBarBorder.setVertex(1, energyBarOffsetX, energyBarOffsetY)
    energyBarBorder.setVertex(2, energyBarOffsetX + energyBarWidth*triangleRatio, energyBarOffsetY)
    energyBarBorder.setVertex(3, energyBarOffsetX + energyBarWidth, energyBarOffsetY - energyBarHeight)
    energyBarBorder.setVertex(4, energyBarOffsetX, energyBarOffsetY - energyBarHeight)
    energyBarBorder.setColor(247/255 , 9/255, 41/255)

    local energyBarEmpty = glasses.addQuad()
    energyBarEmpty.setVertex(1, energyBarOffsetX + borderThickness, energyBarOffsetY - borderThickness)
    energyBarEmpty.setVertex(2, energyBarOffsetX + energyBarWidth*triangleRatio - borderThickness, energyBarOffsetY - borderThickness)
    energyBarEmpty.setVertex(3, energyBarOffsetX + energyBarWidth - math.sqrt(borderThickness*borderThickness*2)*2, energyBarOffsetY - energyBarHeight + borderThickness)
    energyBarEmpty.setVertex(4, energyBarOffsetX + borderThickness, energyBarOffsetY - energyBarHeight + borderThickness)
    energyBarEmpty.setColor(0/255 , 0/255, 0/255)
    -- 9, 41, 247
    local energyBar = glasses.addQuad()
    energyBar.setVertex(1, energyBarOffsetX, energyBarOffsetY)
    energyBar.setVertex(2, energyBarOffsetX, energyBarOffsetY)
    energyBar.setVertex(3, energyBarOffsetX, energyBarOffsetY)
    energyBar.setVertex(4, energyBarOffsetX, energyBarOffsetY)
    energyBar.setColor(0/255 , 0/255, 0/255)

    local currentEU = glasses.addTextLabel()
    currentEU.setText("Test")
    currentEU.setScale(textScale)
    currentEU.setColor(247/255, 67/255, 7/255)
    currentEU.setPosition(energyBarOffsetX ,energyBarOffsetY+5*GUI_SCALE/3)

    local maxEU = glasses.addTextLabel()
    maxEU.setText("Test 2")
    maxEU.setScale(textScale)
    maxEU.setColor(247/255, 67/255, 7/255)
    local textOffset = currentEU.getText():len() * GUI_SCALE*2 * (miniTextScale+1)
    maxEU.setPosition(energyBarOffsetX + textOffset ,energyBarOffsetY+5*GUI_SCALE/3)

    result.energyBarText = energyBarText
    result.energyBar = energyBar
    result.energyBarBorder = energyBarBorder
    result.energyBarEmpty = energyBarEmpty
    result.currentEU = currentEU
    result.maxEU = maxEU
    return result
end

LSC_Util.addGraphicalComponents = addGraphicalComponents


function updateEUStored(graphicalComponents)
    local currentEU = graphicalComponents.currentEU
    local maxEU = graphicalComponents.maxEU
    local LSC_List = getLSC_List()
    local mainLSC = LSC_List[1]

    local curEU_Val = mainLSC.getEUStored()
    local curEU_Exponent = math.log(curEU_Val, 10) - math.log(curEU_Val, 10) % 3
    local curEU_String = string.format("%.2f",curEU_Val / math.pow(10,curEU_Exponent)) .. "e" .. string.format("%.f", curEU_Exponent)
    
    local maxEU_Val = mainLSC.getEUMaxStored()
    local maxEU_Exponent = math.log(maxEU_Val, 10) - math.log(maxEU_Val, 10) % 3
    local maxEU_String = string.format("%.2f",maxEU_Val / math.pow(10,maxEU_Exponent)) .. "e" .. string.format("%.f", maxEU_Exponent)

    currentEU.setText(curEU_String .. " /")

    local textOffset = currentEU.getText():len() * GUI_SCALE * (miniTextScale+1)
    maxEU.setText(maxEU_String)
    maxEU.setPosition(energyBarOffsetX + textOffset, energyBarOffsetY+5*GUI_SCALE/3)
    
end
LSC_Util.updateEUStored = updateEUStored
return LSC_Util

