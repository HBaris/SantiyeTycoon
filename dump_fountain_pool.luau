local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
local prom = plotFolder and plotFolder:FindFirstChild("CommercialPromenade")
local fp = prom and prom:FindFirstChild("FountainPool")
if not fp then return "No FountainPool found in plot" end

local lines = {}
for _, d in ipairs(fp:GetDescendants()) do
    if d:IsA("BasePart") or d:IsA("Model") then
        local pName = d.Parent and d.Parent.Name or "None"
        table.insert(lines, string.format("%s (%s, parent=%s, size=%.1f,%.1f,%.1f)", d.Name, d.ClassName, pName, 
            d:IsA("BasePart") and d.Size.X or 0,
            d:IsA("BasePart") and d.Size.Y or 0,
            d:IsA("BasePart") and d.Size.Z or 0))
    end
end
return table.concat(lines, "\n")
