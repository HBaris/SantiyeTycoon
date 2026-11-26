local Players = game:GetService("Players")
local p = Players.LocalPlayer
local char = p.Character
if char then
    local targetCF = CFrame.lookAt(Vector3.new(-22, 10, 36), Vector3.new(-22, 8, 10))
    char:PivotTo(targetCF)
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(Vector3.new(-22, 14, 42), Vector3.new(-22, 8, 15))
    return "Teleported character and set camera facing Promenade!"
end
return "No character"
