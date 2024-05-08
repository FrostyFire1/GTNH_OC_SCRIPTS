local component = require("component")
local glasses = component.glasses
local height = 345
local width = 640

glasses.removeAll()
print(glasses.getBindPlayers())

local LSC_List = {}
for address,_ in component.list("gt_machine") do
    local proxy = component.proxy(address)
    if proxy.getName() == "multimachine.supercapacitor" then
        table.insert(LSC_LIST, proxy)
    end
end
print(LSC_List)

local testWidget = glasses.addTextLabel()
testWidget.setText("This program is working properly")
testWidget.setPosition(0,345)