local part = Instance.new("Part")
part.Position = Vector3.new(0, 5, 0)
part.Size = Vector3.new(2, 1, 4)
part.CustomPhysicalProperties = PhysicalProperties.new(Enum.Material.Rubber)
part.Parent = workspace

local att = Instance.new("Attachment")
att.Parent = part

local lv = Instance.new("LinearVelocity")
lv.Attachment0 = att
lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
lv.MaxAxesForce = Vector3.new(0, 0, 350000)
lv.VectorVelocity = Vector3.new(0, 0, -30)
lv.Parent = part

task.wait(0.2)
local v1 = part.AssemblyLinearVelocity.Z

lv.MaxForce = 350000
task.wait(0.2)
local v2 = part.AssemblyLinearVelocity.Z

part:Destroy()

return string.format("Default MaxForce (1000): Vel=%.2f, With MaxForce=350000: Vel=%.2f", v1, v2)
