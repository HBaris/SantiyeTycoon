local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p or not p.Character then return "Waiting for player..." end

local hum = p.Character:FindFirstChildOfClass("Humanoid")
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "Waiting for scooter..." end

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
local root = veh.PrimaryPart or seat
local mover = root and root:FindFirstChild("VehicleMover") :: LinearVelocity?
local stab = root and root:FindFirstChild("VehicleStabilizer") :: AlignOrientation?

-- Seat player
if seat and hum and seat.Occupant ~= hum then
    seat:Sit(hum)
    root:SetNetworkOwner(p)
end

return string.format("Scooter Status:\nSeated: %s\nMode: %s\nLineDir: %s\nMaxForce: %d\nStabTorque: %d",
    tostring(seat and seat.Occupant ~= nil),
    mover and mover.VelocityConstraintMode.Name or "nil",
    mover and tostring(mover.LineDirection) or "nil",
    mover and mover.MaxForce or 0,
    stab and stab.MaxTorque or 0)
