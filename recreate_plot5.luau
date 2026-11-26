local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local IM = require(game:GetService("ServerScriptService").Server.Services.IslandManager)

-- Remove old plot folder if any
local old = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if old then old:Destroy() end

local plot = IM.CreatePlot(p, 1, 1, 5, "SingleBuilding")
return string.format("Recreated plot for %s at Level 5! PlotFolder: %s", p.Name, plot.Folder.Name)
