local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p or not p.Character then return "No character" end

local hum = p.Character:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "Player is NOT sitting on a seat!" end

local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
local stab = root:FindFirstChild("VehicleStabilizer") :: AlignOrientation?

local details = {
    SeatName = seat.Name,
    SeatClass = seat.ClassName,
    SeatMaxSpeed = seat.MaxSpeed,
    SeatTorque = seat.Torque,
    Throttle = seat.Throttle,
    ThrottleFloat = seat.ThrottleFloat,
    Steer = seat.Steer,
    SteerFloat = seat.SteerFloat,
    MoverClass = mover and mover.ClassName or "nil",
    MoverMode = mover and mover.VelocityConstraintMode.Name or "nil",
    MoverRel = mover and mover.RelativeTo.Name or "nil",
    MoverMaxAxesForce = mover and tostring(mover.MaxAxesForce) or "nil",
    MoverMaxForce = mover and mover.MaxForce or "nil",
    MoverVectorVel = mover and tostring(mover.VectorVelocity) or "nil",
    MoverLineVel = mover and mover.LineVelocity or "nil",
    MoverEnabled = mover and tostring(mover.Enabled) or "nil",
    StabEnabled = stab and tostring(stab.Enabled) or "nil",
    StabMode = stab and stab.Mode.Name or "nil",
    AssemblyLinearVelocity = tostring(root.AssemblyLinearVelocity),
    RootAnchored = tostring(root.Anchored)
}

local lines = {}
for k, v in pairs(details) do
    table.insert(lines, k .. ": " .. tostring(v))
end
return table.concat(lines, "\n")
