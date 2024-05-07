local component = require("component")
local constants = require("constants")
local db = component.database
local dbAddress = db.address
local path = constants.preferedInputPath

file = io.open(path,"w")
for i = 1,81,1 do
    dbItem = db.get(i)
    if dbItem then
        print("Found database entry: " .. dbItem["label"])
        file:write(dbItem["label"] .. "\n")
    end
end
print("Changes saved to: " .. path)