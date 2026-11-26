local lighting = game:GetService("Lighting")
local res = {}
table.insert(res, "Brightness: " .. tostring(lighting.Brightness))
table.insert(res, "ClockTime: " .. tostring(lighting.ClockTime))
table.insert(res, "OutdoorAmbient: " .. tostring(lighting.OutdoorAmbient))
table.insert(res, "Ambient: " .. tostring(lighting.Ambient))
table.insert(res, "FogColor: " .. tostring(lighting.FogColor))
table.insert(res, "FogEnd: " .. tostring(lighting.FogEnd))
table.insert(res, "ExposureCompensation: " .. tostring(lighting.ExposureCompensation))
table.insert(res, "GlobalShadows: " .. tostring(lighting.GlobalShadows))

for _, c in ipairs(lighting:GetChildren()) do
    table.insert(res, string.format("Child: %s (%s)", c.Name, c.ClassName))
    if c:IsA("Atmosphere") then
        table.insert(res, string.format("  Atmosphere: Density=%.2f, Offset=%.2f, Color=%s, Decay=%s, Glare=%.2f, Haze=%.2f",
            c.Density, c.Offset, tostring(c.Color), tostring(c.Decay), c.Glare, c.Haze))
    elseif c:IsA("BloomEffect") then
        table.insert(res, string.format("  Bloom: Intensity=%.2f, Size=%.2f, Threshold=%.2f", c.Intensity, c.Size, c.Threshold))
    elseif c:IsA("ColorCorrectionEffect") then
        table.insert(res, string.format("  ColorCorrection: Brightness=%.2f, Contrast=%.2f, Saturation=%.2f, Tint=%s",
            c.Brightness, c.Contrast, c.Saturation, tostring(c.TintColor)))
    end
end
return table.concat(res, "\n")
