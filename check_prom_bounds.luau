local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
local prom = plotFolder and plotFolder:FindFirstChild("CommercialPromenade")
if not prom then return "No CommercialPromenade" end

local out = {}
for _, c in ipairs(prom:GetChildren()) do
    if c:IsA("Model") then
        local cf, sz = c:GetBoundingBox()
        table.insert(out, string.format("Model '%s': pos=(%.1f, %.1f, %.1f), size=(%.1f, %.1f, %.1f)", 
            c.Name, cf.Position.X, cf.Position.Y, cf.Position.Z, sz.X, sz.Y, sz.Z))
    elseif c:IsA("BasePart") then
        table.insert(out, string.format("Part '%s': pos=(%.1f, %.1f, %.1f), size=(%.1f, %.1f, %.1f)", 
            c.Name, c.Position.X, c.Position.Y, c.Position.Z, c.Size.X, c.Size.Y, c.Size.Z))
    end
end
return table.concat(out, "\n")
