local part = Instance.new("Part")
part.Position = Vector3.new(0, 5, 0)
part.Size = Vector3.new(2, 1, 4)
part.Anchored = false
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

local out = {}
for i = 1, 5 do
    task.wait(0.1)
    table.insert(out, string.format("Step %d: Pos=(%.2f, %.2f, %.2f), Vel=(%.2f, %.2f, %.2f)",
        i, part.Position.X, part.Position.Y, part.Position.Z,
        part.AssemblyLinearVelocity.X, part.AssemblyLinearVelocity.Y, part.AssemblyLinearVelocity.Z))
end

part:Destroy()
return table.concat(out, "\n")
