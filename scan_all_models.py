import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()
    
    code = """
    local function scan(inst, depth)
        if depth > 3 then return {} end
        local res = {}
        for _, ch in ipairs(inst:GetChildren()) do
            if ch:IsA("Model") or ch:IsA("Folder") then
                res[ch.Name] = scan(ch, depth + 1)
            end
        end
        return res
    end
    
    local rs = game:GetService("ReplicatedStorage")
    local ss = game:GetService("ServerStorage")
    
    return game:GetService("HttpService"):JSONEncode({
        RS = scan(rs, 1),
        SS = scan(ss, 1)
    })
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
