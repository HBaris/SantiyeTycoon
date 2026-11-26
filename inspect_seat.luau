local depotX, depotZ = -70, 55
local spawnCFrame = CFrame.new(depotX + 16, 5.5, depotZ + 8) * CFrame.Angles(0, math.rad(90), 0)

local seat = Instance.new("VehicleSeat")
seat.Size = Vector3.new(2, 0.8, 5)
seat.CFrame = spawnCFrame * CFrame.new(0, 1.4, 0)
seat.Parent = workspace

local att = Instance.new("Attachment")
att.Parent = seat

local lin = Instance.new("LinearVelocity")
lin.Attachment0 = att
lin.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
lin.LineDirection = Vector3.new(0, 0, -1)
lin.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
lin.Parent = seat

local res = string.format("Seat Orient: %s | Seat Look: %s | Att Axis: %s | Att SecondaryAxis: %s",
    tostring(seat.Orientation), tostring(seat.CFrame.LookVector), tostring(att.Axis), tostring(att.SecondaryAxis))

seat:Destroy()
return res
