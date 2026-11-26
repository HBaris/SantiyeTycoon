local RS = game:GetService("ReplicatedStorage")
local f = RS:FindFirstChild("CleanFountain")
if not f then return "No CleanFountain" end
local parts = {}
for _, d in ipairs(f:GetDescendants()) do
    if d:IsA("BasePart") then
        table.insert(parts, string.format("%s: size=(%.1f, %.1f, %.1f), mat=%s", d.Name, d.Size.X, d.Size.Y, d.Size.Z, d.Material.Name))
    end
end
return table.concat(parts, "\n")
