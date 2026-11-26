import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # 1. Server: Make player sit in the scooter and set network ownership
    sit_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if seat and hum then
        root:SetNetworkOwner(p)
        seat:Sit(hum)
        return "Seated on server: " .. tostring(seat.Occupant and seat.Occupant.Parent.Name)
    end
    return "Failed to sit"
    """

    res_sit = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": sit_code
    })
    print("Sit result:", res_sit.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # 2. Client: Test driving with TestThrottle = 1
    client_test_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "Client: No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")

    local p0 = root.Position
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 20 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: vel=%.2f, lineVel=%.1f, pos=(%.1f, %.1f, %.1f)",
            i * 0.1, root.AssemblyLinearVelocity.Magnitude, (mover and mover.LineVelocity or -999), root.Position.X, root.Position.Y, root.Position.Z))
    end

    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    return string.format("Total Dist: %.2f studs\\nLog:\\n%s", dist, table.concat(log, "\\n"))
    """

    res_drive = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": client_test_code
    })
    print(res_drive.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
