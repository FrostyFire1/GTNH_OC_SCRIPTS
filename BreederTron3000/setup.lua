local shell = require("shell")
local filesystem = require("filesystem")
local scripts = {"lib/config.lua", "lib/utility.lua", "BreederTron3000.lua"}

local paths = {"lib"}

local function exists(filename)
    return filesystem.exists(shell.getWorkingDirectory() .. "/" .. filename)
end

local repo = "https://raw.githubusercontent.com/FrostyFire1/GTNH_OC_Scripts/";
local branch = "master/BreederTron3000"

for i = 1, #paths do
    if not filesystem.exists(shell.getWorkingDirectory() .. "/" .. paths[i]) then
        filesystem.makeDirectory(shell.getWorkingDirectory() .. "/" .. paths[i]);
    end
end

for i = 1, #scripts do
    if exists(scripts[i]) then
        filesystem.remove(shell.getWorkingDirectory() .. "/" .. scripts[i]);
    end

    shell.execute(string.format("wget %s%s/%s %s", repo, branch, scripts[i], scripts[i]));
end

shell.execute("reboot");