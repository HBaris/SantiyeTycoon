local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "No scooter" end

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
local root = veh.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity
local stab = root:FindFirstChild("VehicleStabilizer") :: AlignOrientation

-- 1. Configure wheels low friction so they glide
for _, d in ipairs(veh:GetDescendants()) do
    if d:IsA("BasePart") and d.Name:find("Wheel") then
        d.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.1, 1, 1)
    end
end

-- 2. Configure mover in Line Mode
mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
mover.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
mover.LineDirection = Vector3.new(0, 0, -1)
mover.MaxForce = 350000

-- 3. Configure stab MaxTorque to 250k
stab.MaxTorque = 250000
stab.Responsiveness = 30

-- 4. Test driving forward for 0.5 seconds at speed 25
local pStart = root.Position
mover.LineVelocity = 25

task.wait(0.5)
local pMid = root.Position
local distForward = (pMid - pStart).Magnitude
local velForward = root.AssemblyLinearVelocity

-- Stop
mover.LineVelocity = 0
task.wait(0.2)

return string.format("Live Test Result:\nStartPos=(%.1f, %.1f, %.1f)\nMidPos=(%.1f, %.1f, %.1f)\nDistMovedForward=%.2f studs\nVelocity=(%.1f, %.1f, %.1f)",
    pStart.X, pStart.Y, pStart.Z,
    pMid.X, pMid.Y, pMid.Z,
    distForward,
    velForward.X, velForward.Y, velForward.Z)
