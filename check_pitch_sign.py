from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local cf = CFrame.Angles(math.rad(10), 0, 0)
    local p = Instance.new("Part")
    p.CFrame = cf
    local orient = p.Orientation
    local lookY = cf.LookVector.Y

    return string.format("cf.LookVector.Y = %.4f, p.Orientation.X = %.4f", lookY, orient.X)
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
