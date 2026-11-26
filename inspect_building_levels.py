import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()
    
    code = """
    local rs = game:GetService("ReplicatedStorage")
    local b = rs.Assets.Buildings
    local s = rs.Assets:FindFirstChild("Services")
    local t = { Buildings = {}, Services = {} }
    for _, ch in ipairs(b:GetChildren()) do
        local cf, sz = ch:GetBoundingBox()
        t.Buildings[ch.Name] = {
            parts = #ch:GetDescendants(),
            size = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)}
        }
    end
    if s then
        for _, ch in ipairs(s:GetChildren()) do
            local cf, sz = ch:GetBoundingBox()
            t.Services[ch.Name] = {
                parts = #ch:GetDescendants(),
                size = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)}
            }
        end
    end
    return game:GetService("HttpService"):JSONEncode(t)
    """
    
    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
