local part = Instance.new("Part")
local att = Instance.new("Attachment")
att.Parent = part

local lv = Instance.new("LinearVelocity")
lv.Attachment0 = att
lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
lv.Parent = part

local s1 = tostring(lv.LineDirection)

local success, err = pcall(function()
    lv.LineDirection = Vector3.new(0, 0, -1)
end)

local s2 = tostring(lv.LineDirection)

local s3
pcall(function()
    lv.LineDirection = Vector3.new(0, 1, 0)
end)
s3 = tostring(lv.LineDirection)

part:Destroy()

return string.format("Default: %s, Set (0,0,-1) err: %s, Result: %s, Set (0,1,0): %s",
    s1, tostring(err), s2, s3)
