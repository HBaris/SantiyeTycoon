local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
local bm = workspace["Plot_" .. p.Name .. "_1"]:FindFirstChild("BuildingModel")
if not bm then return "No BuildingModel" end
local names = {}
for _, c in ipairs(bm:GetChildren()) do
    table.insert(names, string.format("%s (%s)", c.Name, c.ClassName))
end
return table.concat(names, ", ")
