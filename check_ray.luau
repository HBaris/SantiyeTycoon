local cam = workspace.CurrentCamera
local ray = Ray.new(cam.CFrame.Position, cam.CFrame.LookVector * 200)
local hit, pos, normal, mat = workspace:FindPartOnRay(ray)
if hit then
    return string.format("Hit: %s (color: %s, mat: %s, size: %s, trans: %.2f) at pos: %s",
        hit:GetFullName(), tostring(hit.Color), hit.Material.Name, tostring(hit.Size), hit.Transparency, tostring(pos))
else
    return "Ray hit nothing (looking into sky/void)!"
end
