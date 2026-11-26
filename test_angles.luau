local cfAngles = CFrame.Angles(0, math.rad(90), 0)
local cfOrient = CFrame.fromOrientation(0, math.rad(90), 0)
return string.format("Angles Look: %s | Orient Look: %s", tostring(cfAngles.LookVector), tostring(cfOrient.LookVector))
