local cam = workspace.CurrentCamera
local pos = cam.CFrame.Position
local look = cam.CFrame.LookVector
local nearby = {}
for _, p in ipairs(workspace:GetDescendants()) do
    if p:IsA("BasePart") then
        local d = (p.Position - pos).Magnitude
        if d < 10 then
            table.insert(nearby, string.format("%s (size: %s, dist: %.1f)", p:GetFullName(), tostring(p.Size), d))
        end
    end
end
return string.format("Cam pos: %s | look: %s | nearby parts (<10s): %s", tostring(pos), tostring(look), table.concat(nearby, ", "))
