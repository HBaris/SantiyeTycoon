local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local IslandManager = require(game:GetService("ServerScriptService").Server.Services.Island.IslandManager)
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if not plotFolder then return "No plot folder" end

-- Update building visuals and landscape to Level 5
IslandManager.UpdateBuildingVisuals(p, 1, 5)

return "Plot 1 updated to Level 5 with clean trees!"
