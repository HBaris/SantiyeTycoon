import json
import sys
from roblox_mcp_client import RobloxStudioMCPClient

sys.stdout.reconfigure(encoding='utf-8')

client = RobloxStudioMCPClient()
studio_id = client.get_studio_id()

inspect_code = """
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local assets = ReplicatedStorage:FindFirstChild("Assets")
local comm = assets and assets:FindFirstChild("Commercial")
local props = assets and assets:FindFirstChild("Props")

local out = {}

local function inspectModel(m)
    if not m then return "NIL" end
    local parts = {}
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then
            table.insert(parts, string.format("%s (Color:%s, Mat:%s, Size:%.1f,%.1f,%.1f)", d.Name, tostring(d.Color), d.Material.Name, d.Size.X, d.Size.Y, d.Size.Z))
        end
    end
    return parts
end

if comm then
    for _, ch in ipairs(comm:GetChildren()) do
        out[ch.Name] = inspectModel(ch)
    end
end
if props then
    for _, ch in ipairs(props:GetChildren()) do
        out[ch.Name] = inspectModel(ch)
    end
end

return game:GetService("HttpService"):JSONEncode(out)
"""

res = client.call_tool("execute_luau", {
    "studio_id": studio_id,
    "code": inspect_code,
    "datamodel_type": "Edit"
})

txt = res.get("content", [{}])[0].get("text", str(res))
print(txt[:3000])
client.close()
