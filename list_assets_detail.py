import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()
    
    code = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:FindFirstChild("Assets")
    if not assets then return "NO_ASSETS" end
    
    local categories = {}
    for _, folder in ipairs(assets:GetChildren()) do
        local items = {}
        for _, child in ipairs(folder:GetChildren()) do
            table.insert(items, child.Name)
        end
        categories[folder.Name] = items
    end
    
    return game:GetService("HttpService"):JSONEncode(categories)
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
