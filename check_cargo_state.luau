local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)
local carried = GS.GetCargo(p)
local cap = GS.GetEffectiveCargoCapacity(p, "Scooter")
return string.format("Carried: %d, Cap: %d", carried, cap)
