local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if not plotFolder then return "No plot folder" end
local names = {}
for _, c in ipairs(plotFolder:GetChildren()) do
    table.insert(names, string.format("%s (%s)", c.Name, c.ClassName))
end
return table.concat(names, "\n")
