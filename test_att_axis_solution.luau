local part = Instance.new("Part")
local att = Instance.new("Attachment")
att.Axis = Vector3.new(0, 0, -1)
att.Parent = part

local lv = Instance.new("LinearVelocity")
lv.Attachment0 = att
lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
lv.Parent = part

local lineDir = tostring(lv.LineDirection)
part:Destroy()

return "LineDirection with att.Axis=(0,0,-1): " .. lineDir
