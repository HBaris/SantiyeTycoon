local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "No seat" end

local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
if not mover then return "No mover" end

local pos1 = root.Position

-- Test 1: Set ForceLimitsEnabled = false, VectorVelocity = (0, 0, -28)
mover.ForceLimitsEnabled = false
mover.VectorVelocity = Vector3.new(0, 0, -28)

task.wait(0.3)
local pos2 = root.Position
local dist = (pos2 - pos1).Magnitude

-- Reset
mover.VectorVelocity = Vector3.zero
mover.ForceLimitsEnabled = true

return string.format("With ForceLimitsEnabled=false: InitialPos=(%.1f, %.1f, %.1f), AfterPos=(%.1f, %.1f, %.1f), DistMoved=%.2f studs, Vel=(%.1f, %.1f, %.1f)",
    pos1.X, pos1.Y, pos1.Z,
    pos2.X, pos2.Y, pos2.Z,
    dist,
    root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z)
