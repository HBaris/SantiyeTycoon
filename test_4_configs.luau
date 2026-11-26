-- Test 4 different configurations of LinearVelocity on a part on the ground
local function testConfig(name, setupFn)
    local part = Instance.new("Part")
    part.Size = Vector3.new(2, 1, 4)
    part.Position = Vector3.new(0, 5, 0)
    part.Anchored = false
    part.Parent = workspace

    local att = Instance.new("Attachment")
    att.Parent = part

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0 = att
    setupFn(lv, part)
    lv.Parent = part

    local pStart = part.Position
    for _ = 1, 5 do task.wait(0.1) end
    local pEnd = part.Position
    local dist = (pEnd - pStart).Magnitude
    local vel = part.AssemblyLinearVelocity

    part:Destroy()
    return string.format("%s: Dist=%.2f studs, Vel=(%.1f, %.1f, %.1f)", name, dist, vel.X, vel.Y, vel.Z)
end

local results = {}

-- Config 1: Current code (Vector, Rel=Attachment0, MaxAxesForce=(0, 0, 350000), VectorVel=(0, 0, -28))
table.insert(results, testConfig("1. Current Vector Mode", function(lv)
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    lv.MaxAxesForce = Vector3.new(0, 0, 350000)
    lv.VectorVelocity = Vector3.new(0, 0, -28)
end))

-- Config 2: Vector, Rel=Attachment0, MaxForce=350000, MaxAxesForce=(350000, 350000, 350000)
table.insert(results, testConfig("2. Vector MaxAxes All 350k", function(lv)
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    lv.MaxAxesForce = Vector3.new(350000, 350000, 350000)
    lv.MaxForce = 350000
    lv.VectorVelocity = Vector3.new(0, 0, -28)
end))

-- Config 3: Line mode, Rel=Attachment0, LineDirection=(0, 0, -1), LineVelocity=28, MaxForce=350000
table.insert(results, testConfig("3. Line Mode (Rel=Attachment0)", function(lv)
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
    lv.LineDirection = Vector3.new(0, 0, -1)
    lv.LineVelocity = 28
    lv.MaxForce = 350000
end))

-- Config 4: Vector mode, Rel=World, VectorVelocity=(forward in world)
table.insert(results, testConfig("4. Vector Rel=World", function(lv, part)
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.MaxForce = 350000
    lv.VectorVelocity = Vector3.new(0, 0, -28)
end))

return table.concat(results, "\n")
