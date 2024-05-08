local component = require("component")


local LSC_Util = {}

LSC_Util.height = 350
LSC_Util.width = 650
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

return LSC_Util
