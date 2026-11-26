from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh and veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    return string.format("Veh: %s, Seat: %s, Seat.Occupant: %s, Hum.SeatPart: %s",
        tostring(veh), tostring(seat), tostring(seat and seat.Occupant), tostring(hum and hum.SeatPart))
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
