import sys
from roblox_mcp_client import RobloxStudioMCPClient

sys.stdout.reconfigure(encoding='utf-8')
client = RobloxStudioMCPClient()
sid = client.get_studio_id()

code = """
local rs = game:GetService("ReplicatedStorage")
local comm = rs.Assets.Commercial
local out = {}

for _, name in ipairs({"Bakery", "Market", "Fountain", "Barber", "PetShop", "Restaurant"}) do
    local item = comm:FindFirstChild(name)
    if item then
        local names = {}
        for _, d in ipairs(item:GetDescendants()) do
            if d:IsA("BasePart") then
                table.insert(names, d.Name)
            end
        end
        out[name] = { Class = item.ClassName, PartCount = #names, Parts = table.concat(names, ", ") }
    else
        out[name] = "MISSING"
    end
end

return game:GetService("HttpService"):JSONEncode(out)
"""

res = client.call_tool("execute_luau", {"studio_id": sid, "code": code, "datamodel_type": "Edit"})
print(res.get("content", [{}])[0].get("text", ""))
client.close()
