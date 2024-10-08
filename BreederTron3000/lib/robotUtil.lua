local component = require("component")
local robot = component.robot
local invControl = component.inventory_controller
local modem = component.modem
local robotUtil = {}
robotUtil.port = 3000
robotUtil.computerPort = 3001
function robotUtil.check(_)
    print("Reporting status")
    modem.broadcast(robotUtil.computerPort, true)
end

function robotUtil.place(block)
    local item = nil
    local placed = false
    for i=1, robot.inventorySize() do
        item =  invControl.getStackInInternalSlot(i)
        if item ~= nil then
            if item.label == block and (not placed) then
                print("Located " .. block)
                robot.select(i)
                robot.swing(3) --3 is front of the robot
                if not robot.place(3) then
                    print("Front obstructed or this isn't a block!")
                else
                    print("Placed " .. block)
                    placed = true
                end
            end
        end
    end
    print("placed: ")
    print(placed)
    modem.broadcast(robotUtil.computerPort, placed)
end


return robotUtil
