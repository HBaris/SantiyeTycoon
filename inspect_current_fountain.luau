local RS = game:GetService("ReplicatedStorage")
local f = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Commercial") and RS.Assets.Commercial:FindFirstChild("Fountain")
if not f then return "No Fountain in Commercial" end

local cf, sz = f:GetBoundingBox()
local lines = { string.format("Fountain: size=(%.1f, %.1f, %.1f), descendants=%d", sz.X, sz.Y, sz.Z, #f:GetDescendants()) }
for _, c in ipairs(f:GetChildren()) do
    table.insert(lines, string.format("  Child: %s (%s)", c.Name, c.ClassName))
end
return table.concat(lines, "\n")
