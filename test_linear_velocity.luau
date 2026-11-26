local part = Instance.new("Part")
part.Position = Vector3.new(0, 10, 0)
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

task.wait(0.2)
local velAfter = part.AssemblyLinearVelocity
local props = {
    MaxForce = lv.MaxForce,
    MaxAxesForce = tostring(lv.MaxAxesForce),
    ForceLimitsEnabled = lv.ForceLimitsEnabled,
    VelocityAfter = tostring(velAfter)
}
part:Destroy()

local out = {}
for k, v in pairs(props) do
    table.insert(out, k .. " = " .. tostring(v))
end
return table.concat(out, "\n")
