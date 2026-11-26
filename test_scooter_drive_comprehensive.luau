local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p or not p.Character then return "No player/character" end

local hum = p.Character:FindFirstChildOfClass("Humanoid")
local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)

-- Ensure scooter exists and player is seated
local veh = GS.SpawnVehicle(p, "Scooter")
local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
if seat and hum then
    seat:Sit(hum)
    veh.PrimaryPart:SetNetworkOwner(p)
end

task.wait(0.3)

local root = veh.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
if not mover then return "No VehicleMover" end

-- 1. Test forward motion (LineVelocity = 25)
local p0 = root.Position
mover.LineVelocity = 25
task.wait(0.8)
local p1 = root.Position
local distFwd = (p1 - p0).Magnitude
local velFwd = root.AssemblyLinearVelocity

-- 2. Test reverse motion (LineVelocity = -15)
mover.LineVelocity = -15
task.wait(0.8)
local p2 = root.Position
local distRev = (p2 - p1).Magnitude
local velRev = root.AssemblyLinearVelocity

-- Stop
mover.LineVelocity = 0

return string.format("COMPREHENSIVE DRIVE TEST:\n1. Forward: Dist=%.2f studs, Vel=(%.1f, %.1f, %.1f)\n2. Reverse: Dist=%.2f studs, Vel=(%.1f, %.1f, %.1f)\nTotal Movement Success: %s",
    distFwd, velFwd.X, velFwd.Y, velFwd.Z,
    distRev, velRev.X, velRev.Y, velRev.Z,
    tostring(distFwd > 5 and distRev > 3))
