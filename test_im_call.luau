local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local IM = require(game:GetService("ServerScriptService").Server.Services.IslandManager)

local plot = IM.GetPlot(p, 1)
if not plot then return "No plot in IM" end

local s, err = pcall(function()
    IM.UpdateBuildingVisuals(p, 1, 5)
end)

return string.format("Update success: %s, error: %s", tostring(s), tostring(err))
