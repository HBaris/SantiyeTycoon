from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local ao = Instance.new("AlignOrientation")
    local info = {}
    table.insert(info, "AlignType: " .. tostring(ao.AlignType))
    table.insert(info, "Mode: " .. tostring(ao.Mode))
    table.insert(info, "PrimaryAxisOnly: " .. tostring(ao.PrimaryAxisOnly))
    table.insert(info, "ReactionTorqueEnabled: " .. tostring(ao.ReactionTorqueEnabled))
    ao:Destroy()
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
