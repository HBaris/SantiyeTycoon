local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)
local veh = GS.SpawnVehicle(p, "Scooter")
if not veh then return "Could not spawn scooter" end

-- Position scooter right near the CargoLoadingPad
local pad = workspace.GarageFacility:FindFirstChild("CargoLoadingPad")
if pad then
    veh:PivotTo(pad.CFrame * CFrame.new(0, 2, 0))
end

-- Sit player on scooter
local char = p.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
if hum and seat then
    seat:Sit(hum)
end

-- Test LoadCargo
local loaded = GS.LoadCargo(p)

return string.format("Scooter spawned, player seated=%s, cargoLoaded=%s, pos=(%.1f, %.1f, %.1f)", 
    tostring(seat and seat.Occupant ~= nil), tostring(loaded),
    veh:GetPivot().Position.X, veh:GetPivot().Position.Y, veh:GetPivot().Position.Z)
