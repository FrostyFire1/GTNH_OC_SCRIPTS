local component = require("component")


local util = {}

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