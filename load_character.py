from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    if p then
        if not p.Character then
            p:LoadCharacter()
            return "LoadCharacter called"
        else
            return "Character already present: " .. p.Character.Name
        end
    end
    return "No player"
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
