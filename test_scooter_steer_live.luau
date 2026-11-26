local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
if not veh then return "No scooter" end

local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
local root = veh.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity
local stab = root:FindFirstChild("VehicleStabilizer") :: AlignOrientation

-- Start driving forward at 20 studs/s and steer right for 1 second
local startPos = root.Position
local startYaw = root.Orientation.Y

mover.LineVelocity = 20
local currentYaw = startYaw

for i = 1, 10 do
    currentYaw += 8 -- Turn 8 degrees right each step
    stab.CFrame = CFrame.Angles(0, math.rad(currentYaw), 0)
    task.wait(0.1)
end

local endPos = root.Position
local endYaw = root.Orientation.Y
mover.LineVelocity = 0

return string.format("Steering Test:\nStartPos=(%.1f, %.1f), EndPos=(%.1f, %.1f)\nStartYaw=%.1f deg, EndYaw=%.1f deg\nTotalDist=%.2f studs",
    startPos.X, startPos.Z, endPos.X, endPos.Z,
    startYaw, endYaw,
    (endPos - startPos).Magnitude)
