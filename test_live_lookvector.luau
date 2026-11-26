local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "No scooter" end

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
local root = veh.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity

-- Setup Option B: World LookVector
mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
mover.RelativeTo = Enum.ActuatorRelativeTo.World
mover.LineDirection = root.CFrame.LookVector
mover.LineVelocity = 25
mover.MaxForce = 350000

local pStart = root.Position
task.wait(0.5)
local pEnd = root.Position
local dist = (pEnd - pStart).Magnitude
local vel = root.AssemblyLinearVelocity

-- Stop
mover.LineVelocity = 0

return string.format("World LookVector Test:\nDist=%.2f studs, Vel=(%.1f, %.1f, %.1f), Heading=%s",
    dist, vel.X, vel.Y, vel.Z, tostring(root.CFrame.LookVector))
