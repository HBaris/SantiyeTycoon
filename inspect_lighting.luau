local lighting = game:GetService("Lighting")
local res = {}
table.insert(res, "Brightness: " .. tostring(lighting.Brightness))
table.insert(res, "ClockTime: " .. tostring(lighting.ClockTime))
table.insert(res, "OutdoorAmbient: " .. tostring(lighting.OutdoorAmbient))
for _, c in ipairs(lighting:GetChildren()) do
    table.insert(res, string.format("Child: %s (%s)", c.Name, c.ClassName))
    if c:IsA("BloomEffect") then
        table.insert(res, string.format("  Bloom: Intensity=%.2f, Size=%.2f, Threshold=%.2f", c.Intensity, c.Size, c.Threshold))
    end
end
return table.concat(res, "\n")
