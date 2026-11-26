from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local p = game:GetService("Players").LocalPlayer
    local char = p and p.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local seat = hum and hum.SeatPart

    return string.format("Char: %s, Hum: %s, SeatPart: %s, HRP Pos: %s",
        tostring(char and char.Name), tostring(hum ~= nil), tostring(seat and seat:GetFullName()),
        tostring(hrp and hrp.Position))
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
