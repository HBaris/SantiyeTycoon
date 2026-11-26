local Players = game:GetService("Players")
local p = Players:GetPlayers()[1]
if not p then return "No player" end
local plotFolder = workspace:FindFirstChild("Plot_" .. p.Name .. "_1")
if not plotFolder then return "No plot" end

local findings = {}
for _, d in ipairs(plotFolder:GetDescendants()) do
    if d:IsA("BasePart") then
        local lowerName = d.Name:lower()
        if lowerName:find("tree") or lowerName:find("rock") or lowerName:find("bush") or lowerName:find("leaf") or lowerName:find("leaves") or lowerName:find("plant") then
            table.insert(findings, string.format("Part '%s' in '%s' (pos=%.1f, %.1f, %.1f, size=%.1f, %.1f, %.1f, mat=%s)",
                d.Name, d.Parent and d.Parent:GetFullName() or "nil",
                d.Position.X, d.Position.Y, d.Position.Z,
                d.Size.X, d.Size.Y, d.Size.Z,
                d.Material.Name))
        end
    end
end
return table.concat(findings, "\n")
