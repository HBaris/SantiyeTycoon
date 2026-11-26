local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local IM = require(game:GetService("ServerScriptService").Server.Services.IslandManager)
local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)
local DS = require(game:GetService("ServerScriptService").Server.Services.DataService)

-- Recreate plot at Level 5
local old = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if old then old:Destroy() end

local plot = IM.CreatePlot(p, 1, 1, 5, "SingleBuilding")

-- Spawn scooter
local veh = GS.SpawnVehicle(p, "Scooter")

-- Load cargo
local loaded = GS.LoadCargo(p)

return string.format("Plot created (Level 5), Scooter spawned: %s, Cargo loaded: %s", 
    tostring(veh ~= nil), tostring(loaded))
