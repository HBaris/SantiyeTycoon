local lighting = game:GetService("Lighting")
local sky = lighting:FindFirstChildOfClass("Sky")
if sky then
    return string.format("Sky found: SkyboxBk=%s, SkyboxUp=%s", tostring(sky.SkyboxBk), tostring(sky.SkyboxUp))
else
    return "No Sky object in Lighting"
end
