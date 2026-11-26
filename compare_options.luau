-- Test Option A: att.CFrame rotated 90 deg so local X points along -Z
local function testOptionA()
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 1, 4)
    part.Position = Vector3.new(0, 5, 0)
    part.Anchored = false
    part.Parent = workspace

    local att = Instance.new("Attachment")
    att.CFrame = CFrame.Angles(0, math.rad(90), 0)
    att.Parent = part

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    lv.LineVelocity = 28
    lv.MaxForce = 350000
    lv.Parent = part

    local pStart = part.Position
    task.wait(0.3)
    local pEnd = part.Position
    local dist = (pEnd - pStart).Magnitude
    local vel = part.AssemblyLinearVelocity
    part:Destroy()

    return string.format("Option A (Rotated Att): Dist=%.2f, Vel=(%.1f, %.1f, %.1f), ForwardZ=%.1f",
        dist, vel.X, vel.Y, vel.Z, vel.Z)
end

-- Test Option B: RelativeTo = World with LineDirection = root.CFrame.LookVector
local function testOptionB()
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 1, 4)
    part.Position = Vector3.new(0, 5, 0)
    part.Anchored = false
    part.Parent = workspace

    local att = Instance.new("Attachment")
    att.Parent = part

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.LineDirection = part.CFrame.LookVector
    lv.LineVelocity = 28
    lv.MaxForce = 350000
    lv.Parent = part

    local pStart = part.Position
    task.wait(0.3)
    local pEnd = part.Position
    local dist = (pEnd - pStart).Magnitude
    local vel = part.AssemblyLinearVelocity
    part:Destroy()

    return string.format("Option B (World LookVector): Dist=%.2f, Vel=(%.1f, %.1f, %.1f), ForwardZ=%.1f",
        dist, vel.X, vel.Y, vel.Z, vel.Z)
end

return testOptionA() .. "\n" .. testOptionB()
