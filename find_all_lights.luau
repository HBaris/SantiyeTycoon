local RS = game:GetService("ReplicatedStorage")
local lights = {}
for _, d in ipairs(RS:GetDescendants()) do
    if d:IsA("Light") or d:IsA("Beam") or d:IsA("Highlight") or d:IsA("ParticleEmitter") then
        table.insert(lights, string.format("RS: %s (%s) @ %s, color=%s, bright=%.1f", d.Name, d.ClassName, d.Parent.Name, tostring(d:IsA("Light") and d.Color or ""), (d:IsA("Light") and d.Brightness or 0)))
    end
end
return table.concat(lights, "\n")
