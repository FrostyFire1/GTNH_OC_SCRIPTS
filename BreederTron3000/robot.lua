local component = require("component")
local event = require("event")
local robot = component.robot
local modem = component.modem
local robotUtil = require("lib.robotUtil")
if robot == nil then
    print("This isn't a robot! Terminating.")
    os.exit()
end
if modem == nil then
    print("This robot doesn't have a wireless network card! Terminating.")
    os.exit()
end
if not modem.isWireless() then
    print("This network card isn't wireless! Terminating.")
    os.exit()
end
modem.open(robotUtil.port)
print("Opened port " .. robotUtil.port)
while true do
    print("Awaiting message...")
    local _, _, _, _, _, message = event.pull("modem_message")
    print(message)
    if message ~= nil then
        local command, arg = message:match("(%w+) ([a-zA-Z0-9 ]+)")
        print(command, arg)
        print(robotUtil[command] == nil)
        if robotUtil[command] ~= nil then
            print(string.format("Executing command %s with argument: %s",command, arg))
            os.sleep(0.5)
            robotUtil[command](arg)
        else
            modem.broadcast(robotUtil.port, string.format("Command %s not recognised!", command))
        end
    end
end


