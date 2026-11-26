local IM = require(game:GetService("ServerScriptService").Server.Services.IslandManager)
local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local allPlots = IM.GetAllPlots(p)
return string.format("Player: %s (UserId: %d) | allPlots count: %d", p.Name, p.UserId, #allPlots)
