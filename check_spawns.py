from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local spawns = {}
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("SpawnLocation") then
            table.insert(spawns, string.format("Spawn: %s at %s, Enabled=%s, Neutral=%s",
                desc:GetFullName(), tostring(desc.Position), tostring(desc.Enabled), tostring(desc.Neutral)))
        end
    end
    if #spawns == 0 then return "No SpawnLocations found!" end
    return table.concat(spawns, "\\n")
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
