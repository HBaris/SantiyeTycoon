local out = {}
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("BasePart") then
        local p = obj.Position
        if p.X >= -35 and p.X <= 5 and p.Z >= -5 and p.Z <= 45 and p.Y >= 10 then
            table.insert(out, string.format("Part '%s' [%s] at (%.1f, %.1f, %.1f) size (%.1f, %.1f, %.1f) parent='%s'",
                obj.Name, obj.ClassName, p.X, p.Y, p.Z, obj.Size.X, obj.Size.Y, obj.Size.Z, obj.Parent and obj.Parent:GetFullName() or "nil"))
        end
    end
end
return table.concat(out, "\n")
