local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("Assets")
if not assets then return "No Assets folder" end
local comm = assets:FindFirstChild("Commercial")
if not comm then return "No Commercial folder" end

local info = {}
for _, child in ipairs(comm:GetChildren()) do
    local parts = {}
    for _, d in ipairs(child:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Model") or d:IsA("MeshPart") then
            table.insert(parts, d.Name .. ":" .. d.ClassName)
        end
    end
    table.insert(info, string.format("[%s]: %s", child.Name, table.concat(parts, ", ")))
end
return table.concat(info, "\n\n")
