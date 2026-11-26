local DataService = require(game:GetService("ServerScriptService").Server.Services.DataService)
-- Check if DataService has any profiles
local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local prof = DataService.LoadPlayer(p) -- If not loaded, loads it!
return string.format("Loaded profile for %s: Cash=%d, Level=%d", p.Name, prof.Cash, prof.Plots[1].BuildingLevel)
