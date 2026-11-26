local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local ConstructionService = require(game:GetService("ServerScriptService").Server.Services.ConstructionService)

local prof = DataService.GetProfile(p)
prof.Cash = 1000000

local log = {}
table.insert(log, "Initial level: " .. tostring(prof.Plots[1].BuildingLevel))
for i = 1, 4 do
    ConstructionService.HandleUpgradeBuilding(p, 1)
    table.insert(log, string.format("After upgrade %d -> level: %d, cash: %d", i, prof.Plots[1].BuildingLevel, prof.Cash))
end

return table.concat(log, "\n")
