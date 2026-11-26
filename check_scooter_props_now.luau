local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "No scooter" end

local root = veh.PrimaryPart
local mover = root and root:FindFirstChild("VehicleMover") :: LinearVelocity?
local stab = root and root:FindFirstChild("VehicleStabilizer") :: AlignOrientation?

return string.format("Mover: mode=%s, lineDir=%s, lineVel=%.1f, maxForce=%d, stabTorque=%d",
    mover and mover.VelocityConstraintMode.Name or "nil",
    mover and tostring(mover.LineDirection) or "nil",
    mover and mover.LineVelocity or 0,
    mover and mover.MaxForce or 0,
    stab and stab.MaxTorque or 0)
