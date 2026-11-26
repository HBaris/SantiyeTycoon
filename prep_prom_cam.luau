local Players = game:GetService("Players")
local p = Players.LocalPlayer
local pg = p:FindFirstChild("PlayerGui")
if pg then
    local pss = pg:FindFirstChild("ProjectSelectionScreen")
    if pss then pss.Enabled = false end
end

local char = p.Character
if char then
    local targetCF = CFrame.lookAt(Vector3.new(-22, 10, 48), Vector3.new(-22, 9, 15))
    char:PivotTo(targetCF)
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    -- Position camera above and behind player looking straight into the promenade
    cam.CFrame = CFrame.lookAt(Vector3.new(-22, 15, 52), Vector3.new(-22, 8, 15))
    return "Ready to capture Promenade!"
end
return "No char"
