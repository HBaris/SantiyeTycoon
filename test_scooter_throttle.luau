local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "No seat" end

local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
if not mover then return "No mover" end

-- Let's test setting VectorVelocity directly on mover to (0, 0, -28)
local initialVel = root.AssemblyLinearVelocity
local initialPos = root.Position

mover.MaxAxesForce = Vector3.new(0, 0, 350000)
mover.VectorVelocity = Vector3.new(0, 0, -28)

task.wait(0.3)
local afterVel = root.AssemblyLinearVelocity
local afterPos = root.Position
local dist = (afterPos - initialPos).Magnitude

-- Reset
mover.VectorVelocity = Vector3.zero

return string.format("Applied (0, 0, -28). InitialPos=(%.1f, %.1f, %.1f), AfterPos=(%.1f, %.1f, %.1f), DistMoved=%.2f studs, AfterVel=(%.1f, %.1f, %.1f)",
    initialPos.X, initialPos.Y, initialPos.Z,
    afterPos.X, afterPos.Y, afterPos.Z,
    dist,
    afterVel.X, afterVel.Y, afterVel.Z)
