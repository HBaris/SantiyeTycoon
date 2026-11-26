local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end

local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)
local veh = GS.SpawnVehicle(p, "Scooter")
local root = veh.PrimaryPart

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
if seat and p.Character then
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        seat:Sit(hum)
        root:SetNetworkOwner(p)
    end
end

local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
return string.format("Scooter Respawned! Name=%s, Mode=%s, LineDir=%s, Seated=%s",
    veh.Name,
    mover and mover.VelocityConstraintMode.Name or "nil",
    mover and tostring(mover.LineDirection) or "nil",
    tostring(seat and seat.Occupant ~= nil))
