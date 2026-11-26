local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("Assets")
if not assets then return "No Assets folder" end

local out = {}
for _, cat in ipairs(assets:GetChildren()) do
    table.insert(out, "=== CATEGORY: " .. cat.Name .. " ===")
    for _, item in ipairs(cat:GetChildren()) do
        if item:IsA("Model") then
            local cf, sz = item:GetBoundingBox()
            table.insert(out, string.format("  Model '%s': size=(%.1f, %.1f, %.1f), descendants=%d",
                item.Name, sz.X, sz.Y, sz.Z, #item:GetDescendants()))
        else
            table.insert(out, string.format("  %s '%s' (%s)", item.ClassName, item.Name, item.ClassName))
        end
    end
end
return table.concat(out, "\n")
