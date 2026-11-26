local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local pgui = lp:FindFirstChild("PlayerGui")
if not pgui then return "No PlayerGui" end

local names = {}
for _, c in ipairs(pgui:GetChildren()) do
    table.insert(names, c.Name .. " (" .. c.ClassName .. ")")
    for _, sub in ipairs(c:GetChildren()) do
        table.insert(names, "  -> " .. sub.Name .. " (" .. sub.ClassName .. ")")
    end
end
return table.concat(names, "\n")
