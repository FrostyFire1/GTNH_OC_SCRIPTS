local component = require("component")


local LSC_Util = {}

LSC_Util.height = 1080 / 3
LSC_Util.width = 1920 / 3
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
    
    local energyBarOffsetX = 5
    local energyBarOffsetY = LSC_Util.height - 30*textScale - 5
    local energyBarWidth = 150
    local energyBarHeight = 15
    local triangleRatio = 0.9
    local borderThickness = 5 / 2
    local textScale = 1

    local energyBarText = glasses.addTextLabel()
    energyBarText.setText("Energy Monitor by FrostyFire1")
    energyBarText.setScale(textScale)
    energyBarText.setColor(247/255, 67/255, 7/255)
    energyBarText.setPosition(energyBarOffsetX ,energyBarOffsetY - textScale * 30)



    local energyBarBorder = glasses.addQuad()
    energyBarBorder.setVertex(1, energyBarOffsetX, energyBarOffsetY)
    energyBarBorder.setVertex(2, energyBarOffsetX + energyBarWidth*triangleRatio, energyBarOffsetY)
    energyBarBorder.setVertex(3, energyBarOffsetX + energyBarWidth, energyBarOffsetY - energyBarHeight)
    energyBarBorder.setVertex(4, energyBarOffsetX, energyBarOffsetY - energyBarHeight)
    energyBarBorder.setColor(247/255 , 9/255, 41/255)

    local energyBarEmpty = glasses.addQuad()
    energyBarEmpty.setVertex(1, energyBarOffsetX + borderThickness, energyBarOffsetY - borderThickness)
    energyBarEmpty.setVertex(2, energyBarOffsetX + energyBarWidth*triangleRatio - borderThickness, energyBarOffsetY - borderThickness)
    energyBarEmpty.setVertex(3, energyBarOffsetX + energyBarWidth - math.sqrt(borderThickness*borderThickness*2), energyBarOffsetY - energyBarHeight + borderThickness)
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

    local maxEU = glasses.addTextLabel()
    result.energyBarText = energyBarText
    result.energyBar = energyBar
    result.energyBarBorder = energyBarBorder
    result.energyBarEmpty = energyBarEmpty
    result.currentEU = currentEU
    result.maxEU = maxEU
    return result
end

LSC_Util.addGraphicalComponents = addGraphicalComponents

return LSC_Util

