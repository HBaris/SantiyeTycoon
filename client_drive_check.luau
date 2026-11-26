local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart
if not seat then return "Client: Not seated on a seat" end

local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
if not mover then return "Client: No mover" end

local pStart = root.Position
local frames = {}

for i = 1, 8 do
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.LineDirection = root.CFrame.LookVector
    mover.LineVelocity = 28
    mover.MaxForce = 350000
    task.wait(0.1)
    table.insert(frames, string.format("f%d: pos=(%.1f, %.1f), vel=(%.1f, %.1f)",
        i, root.Position.X, root.Position.Z,
        root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Z))
end

local pEnd = root.Position
local dist = (pEnd - pStart).Magnitude
local velFinal = root.AssemblyLinearVelocity
mover.LineVelocity = 0

return string.format("CLIENT FORWARD DRIVE SUCCESS!\nDistMoved=%.2f studs\nFinalVel=(%.1f, %.1f, %.1f)\n%s",
    dist, velFinal.X, velFinal.Y, velFinal.Z, table.concat(frames, "\n"))
