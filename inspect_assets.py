import json
from roblox_mcp_client import RobloxStudioMCPClient

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

inspect_code = """
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
if not assets then return "NO_ASSETS" end

local results = {}
for _, folder in ipairs(assets:GetChildren()) do
    table.insert(results, "=== Folder: " .. folder.Name .. " ===")
    for _, model in ipairs(folder:GetChildren()) do
        if model:IsA("Model") then
            local cf, size = model:GetBoundingBox()
            local pCount = 0
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") then pCount += 1 end
            end
            table.insert(results, string.format("  [%s] Parts: %d, Size: (%.1f, %.1f, %.1f)", model.Name, pCount, size.X, size.Y, size.Z))
        end
    end
end
return table.concat(results, "\\n")
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "datamodel_type": "Edit",
    "code": inspect_code
})
txt = res.get("content", [{}])[0].get("text", "")
print(txt)
