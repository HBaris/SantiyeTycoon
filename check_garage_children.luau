local garage = workspace:FindFirstChild("GarageFacility")
if not garage then return "No GarageFacility" end

local items = {}
for _, c in ipairs(garage:GetChildren()) do
    if c:IsA("BasePart") then
        table.insert(items, string.format("Part '%s' pos=(%.1f, %.1f, %.1f), size=(%.1f, %.1f, %.1f)", c.Name, c.Position.X, c.Position.Y, c.Position.Z, c.Size.X, c.Size.Y, c.Size.Z))
    elseif c:IsA("Model") then
        local cf, sz = c:GetBoundingBox()
        table.insert(items, string.format("Model '%s' pos=(%.1f, %.1f, %.1f), size=(%.1f, %.1f, %.1f)", c.Name, cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z))
    else
        table.insert(items, string.format("%s '%s'", c.ClassName, c.Name))
    end
end
return table.concat(items, "\n")
