local RS = game:GetService("ReplicatedStorage")
local trees = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Trees")
if not trees then return "No Trees folder" end

local out = {}
for _, t in ipairs(trees:GetChildren()) do
    table.insert(out, string.format("Tree: %s (%s)", t.Name, t.ClassName))
    for _, c in ipairs(t:GetChildren()) do
        table.insert(out, string.format("  child: %s (%s)", c.Name, c.ClassName))
        for _, sub in ipairs(c:GetChildren()) do
            table.insert(out, string.format("    sub: %s (%s)", sub.Name, sub.ClassName))
        end
    end
end
return table.concat(out, "\n")
