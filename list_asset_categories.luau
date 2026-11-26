local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("Assets")
if not assets then return "No Assets" end

local res = {}
for _, f in ipairs(assets:GetChildren()) do
    local names = {}
    for _, item in ipairs(f:GetChildren()) do
        table.insert(names, item.Name)
    end
    table.insert(res, f.Name .. " => " .. table.concat(names, ", "))
end
return table.concat(res, "\n")
