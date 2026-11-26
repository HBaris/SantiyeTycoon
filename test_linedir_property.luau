local mover = Instance.new("LinearVelocity")
local d0 = mover.LineDirection
mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
local d1 = mover.LineDirection
mover.LineDirection = Vector3.new(0, 0, -1)
local d2 = mover.LineDirection

return string.format("Default: %s, After Mode=Line: %s, After set (0,0,-1): %s",
    tostring(d0), tostring(d1), tostring(d2))
