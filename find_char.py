from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local found = workspace:FindFirstChild(p.Name)
    local char = p.Character

    local info = {}
    table.insert(info, "p.Character: " .. tostring(char and char:GetFullName()))
    table.insert(info, "workspace:FindFirstChild(p.Name): " .. tostring(found and found:GetFullName()))
    if found then
        local hum = found:FindFirstChildOfClass("Humanoid")
        table.insert(info, "Humanoid Health: " .. tostring(hum and hum.Health))
        local hrp = found:FindFirstChild("HumanoidRootPart")
        table.insert(info, "HRP Pos: " .. tostring(hrp and hrp.Position))
    end
    return table.concat(info, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
