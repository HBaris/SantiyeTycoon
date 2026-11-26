local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local char = lp.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local seat = hum and hum.SeatPart :: VehicleSeat?
if not seat then return "No seat" end
local root = seat.Parent and seat.Parent.PrimaryPart or seat
local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?

-- Let's test the CFrame calculation
local currentYaw = root.Orientation.Y
local currentPitch = math.clamp(root.Orientation.X, -25, 25)
local goalCF = CFrame.Angles(0, math.rad(currentYaw), 0) * CFrame.Angles(math.rad(currentPitch), 0, 0)

return string.format("CurrentYaw: %.1f deg, CurrentPitch: %.1f deg, GoalCF: %s, MoverLineDir: %s, MoverMode: %s",
    currentYaw, currentPitch, tostring(goalCF), tostring(mover and mover.LineDirection), mover and mover.VelocityConstraintMode.Name or "nil")
