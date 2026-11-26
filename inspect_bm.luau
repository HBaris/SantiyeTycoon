local RS = game:GetService("ReplicatedStorage")
local comm = RS.Assets.Commercial
local lines = {}
for _, name in ipairs({"Bakery", "Market"}) do
    local m = comm:FindFirstChild(name)
    if m then
        local children = {}
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BasePart") and d.Material == Enum.Material.Neon then
                table.insert(children, "NEON: " .. d.Name .. " (" .. tostring(d.Color) .. ")")
            end
            if d:IsA("Light") then
                table.insert(children, "LIGHT: " .. d.Name .. " (" .. tostring(d.Brightness) .. ")")
            end
        end
        table.insert(lines, name .. " => " .. table.concat(children, "; "))
    end
end
return table.concat(lines, "\n")
