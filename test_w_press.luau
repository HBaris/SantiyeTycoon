local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "No seat" end
local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?

local pStart = root.Position

-- Simulate pressing W for 1 second
local steps = {}
for i = 1, 10 do
    seat.ThrottleFloat = 1
    task.wait(0.1)
    table.insert(steps, string.format("t=%.1fs: pos=(%.2f, %.2f, %.2f), vel=(%.2f, %.2f, %.2f), moverVel=%s",
        i * 0.1,
        root.Position.X, root.Position.Y, root.Position.Z,
        root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Y, root.AssemblyLinearVelocity.Z,
        mover and tostring(mover.VectorVelocity) or "nil"))
end

seat.ThrottleFloat = 0
local pEnd = root.Position
local dist = (pEnd - pStart).Magnitude

return string.format("Dist moved: %.2f studs\n%s", dist, table.concat(steps, "\n"))
