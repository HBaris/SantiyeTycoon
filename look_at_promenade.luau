local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
if char then
    local targetCF = CFrame.lookAt(Vector3.new(-22, 9.4, 44), Vector3.new(-22, 9.4, 15))
    char:PivotTo(targetCF)
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(Vector3.new(-22, 14, 48), Vector3.new(-22, 9, 15))
    return "Camera positioned in front of Promenade entrance!"
end
return "No char"
