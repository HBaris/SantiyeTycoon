local RS = game:GetService("ReplicatedStorage")
local f = RS.Assets.Commercial:FindFirstChild("Fountain")
if not f then return "No Fountain" end
local names = {}
for _, c in ipairs(f:GetChildren()) do
    table.insert(names, string.format("%s (%s)", c.Name, c.ClassName))
    for _, sub in ipairs(c:GetChildren()) do
        table.insert(names, string.format("  -> %s (%s)", sub.Name, sub.ClassName))
    end
end
return table.concat(names, "\n")
