local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "Client: Not seated on a VehicleSeat" end

local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
if not mover then return "Client: No mover" end

-- Let's test if pressing W works on client!
-- We simulate UserInputService or seat.ThrottleFloat for 1.0 second
local pStart = root.Position
local vStart = root.AssemblyLinearVelocity

-- We will record positions over 10 frames
local log = {}
for i = 1, 10 do
    seat.ThrottleFloat = 1
    task.wait(0.1)
    table.insert(log, string.format("t=%.1f: pos=(%.1f, %.1f), vel=(%.1f, %.1f), lineVel=%.1f",
        i * 0.1, root.Position.X, root.Position.Z,
        root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Z,
        mover.LineVelocity))
end

seat.ThrottleFloat = 0
local pEnd = root.Position
local dist = (pEnd - pStart).Magnitude

return string.format("CLIENT REAL DRIVE TEST:\nStartPos=(%.1f, %.1f), EndPos=(%.1f, %.1f)\nDistMoved=%.2f studs\n%s",
    pStart.X, pStart.Z, pEnd.X, pEnd.Z, dist, table.concat(log, "\n"))
