local Players = game:GetService("Players")
local p = Players.LocalPlayer
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
local prom = plotFolder and plotFolder:FindFirstChild("CommercialPromenade")
if not prom then return "No CommercialPromenade" end

local names = {}
for _, c in ipairs(prom:GetChildren()) do
    table.insert(names, string.format("Child: %s (%s)", c.Name, c.ClassName))
    for _, sub in ipairs(c:GetChildren()) do
        if sub:IsA("BasePart") or sub:IsA("Model") then
            if sub.Name:find("Rock") or sub.Name:find("Tree") or sub.Name:find("Leaves") or sub.ClassName == "UnionOperation" then
                table.insert(names, string.format("  -> Found: %s (%s) @ %s", sub.Name, sub.ClassName, c.Name))
            end
        end
    end
end
return table.concat(names, "\n")
