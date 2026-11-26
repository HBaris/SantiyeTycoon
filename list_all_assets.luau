local RS = game:GetService("ReplicatedStorage")
local assets = RS:FindFirstChild("Assets")
if not assets then return "No Assets" end

local function listFolder(folder, indent)
    local res = {}
    for _, item in ipairs(folder:GetChildren()) do
        table.insert(res, string.rep("  ", indent) .. item.Name .. " (" .. item.ClassName .. ")")
        if item:IsA("Folder") or item:IsA("Model") then
            local sub = listFolder(item, indent + 1)
            if sub ~= "" then
                table.insert(res, sub)
            end
        end
    end
    return table.concat(res, "\n")
end

return listFolder(assets, 0)
