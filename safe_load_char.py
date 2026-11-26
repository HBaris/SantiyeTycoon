import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    if p then
        task.spawn(function()
            p:LoadCharacter()
        end)
        return "Spawned LoadCharacter task"
    end
    return "No player"
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))

    time.sleep(2.0)

    # Check if character spawned
    code2 = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local char = p and p.Character
    return string.format("Char: %s, Pos: %s",
        tostring(char and char.Name),
        tostring(char and char.PrimaryPart and char.PrimaryPart.Position))
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": code2
    })
    print(res2.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
