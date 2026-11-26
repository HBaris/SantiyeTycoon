local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
local IslandManager = require(game:GetService("ServerScriptService").Server.Services.IslandManager)

local prof = DataService.GetProfile(p)
prof.Plots[1].BuildingLevel = 5

IslandManager.UpdateBuildingVisuals(p, 1, 5)
return "Visuals updated to Level 5 with Commercial Promenade and Residents!"
