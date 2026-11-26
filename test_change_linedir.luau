local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
local mover = veh and veh.PrimaryPart:FindFirstChild("VehicleMover")
if not mover then return "No mover" end

local before = mover.LineDirection
mover.LineDirection = Vector3.new(0, 0, -1)
local after = mover.LineDirection

return string.format("Before: %s, After: %s", tostring(before), tostring(after))
