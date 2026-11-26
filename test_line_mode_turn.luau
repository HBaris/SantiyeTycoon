local part = Instance.new("Part")
part.Size = Vector3.new(2, 1, 4)
part.Position = Vector3.new(0, 5, 0)
part.Anchored = false
part.Parent = workspace

local att = Instance.new("Attachment")
att.Parent = part

local mover = Instance.new("LinearVelocity")
mover.Attachment0 = att
mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
mover.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
mover.LineDirection = Vector3.new(0, 0, -1)
mover.LineVelocity = 25
mover.MaxForce = 350000
mover.Parent = part

local stab = Instance.new("AlignOrientation")
stab.Attachment0 = att
stab.Mode = Enum.OrientationAlignmentMode.OneAttachment
stab.MaxTorque = 5000000
stab.Responsiveness = 35
stab.CFrame = CFrame.Angles(0, 0, 0)
stab.Parent = part

local path = {}
local yaw = 0

for i = 1, 10 do
    task.wait(0.1)
    -- Turn yaw by 10 degrees each step
    yaw += 10
    stab.CFrame = CFrame.Angles(0, math.rad(yaw), 0)
    table.insert(path, string.format("Step %d (Yaw=%d deg): Pos=(%.1f, %.1f), Vel=(%.1f, %.1f), Speed=%.1f",
        i, yaw, part.Position.X, part.Position.Z, part.AssemblyLinearVelocity.X, part.AssemblyLinearVelocity.Z,
        Vector2.new(part.AssemblyLinearVelocity.X, part.AssemblyLinearVelocity.Z).Magnitude))
end

part:Destroy()
return table.concat(path, "\n")
