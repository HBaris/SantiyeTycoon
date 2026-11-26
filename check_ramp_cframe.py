from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local ramp = workspace.Plot_Garkjha_1.PlotEntranceRamp
    return string.format("Ramp Pos=%s, Orientation=%s, Size=%s, CFrame=%s",
        tostring(ramp.Position), tostring(ramp.Orientation), tostring(ramp.Size), tostring(ramp.CFrame))
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
