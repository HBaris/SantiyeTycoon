local Players = game:GetService("Players")
local p = Players.LocalPlayer
local pg = p:FindFirstChild("PlayerGui")
if not pg then return "No pg" end
local names = {}
for _, c in ipairs(pg:GetChildren()) do
    table.insert(names, c.Name)
end
return table.concat(names, ", ")
