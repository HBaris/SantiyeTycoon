local seat = Instance.new("VehicleSeat")
seat.Size = Vector3.new(2, 0.8, 5)
seat.CFrame = CFrame.new(0, 10, 0) * CFrame.Angles(0, math.rad(90), 0)
seat.Anchored = false
seat.Parent = workspace

local att = Instance.new("Attachment")
att.Parent = seat

local lin = Instance.new("LinearVelocity")
lin.Attachment0 = att
lin.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
lin.LineDirection = Vector3.new(0, 0, -1)
lin.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
lin.MaxForce = 100000
lin.LineVelocity = 20
lin.Parent = seat

task.wait(0.2)
local vel = seat.AssemblyLinearVelocity
local res = string.format("Seat Look: %s | Assembly Velocity: %s", tostring(seat.CFrame.LookVector), tostring(vel))
seat:Destroy()
return res
