import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Check scooter spawn position & orientation
    check_spawn_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "NO_SCOOTER" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    seat:Sit(hum)
    root:SetNetworkOwner(p)

    return string.format("Spawned at Pos=%s, LookVec=%s, WF_Shape=%s, SeatTorque=%s, Occupant=%s",
        tostring(root.Position), tostring(root.CFrame.LookVector), tostring(wF and wF.Shape), tostring(seat.Torque), tostring(seat.Occupant and seat.Occupant.Parent.Name))
    """

    res_spawn = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": check_spawn_code
    })
    print("Step 1 (Spawn & Sit):", res_spawn.get("content", [{}])[0].get("text", ""))

    time.sleep(1.0)

    # Step 2: Drive forward along highway towards plot
    drive_highway_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    local p0 = root.Position
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 20 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude))
    end
    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    return string.format("Highway Drive: Dist=%.2f studs, Start=(%.1f, %.1f), End=(%.1f, %.1f)\\nLog:\\n%s",
        dist, p0.X, p0.Z, p1.X, p1.Z, table.concat(log, "\\n"))
    """

    res_drive = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_highway_code
    })
    print("Step 2 (Highway Drive):\n", res_drive.get("content", [{}])[0].get("text", ""))

    # Capture screenshot of scooter driving
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_driving_forward",
        "camera_position": [-30.0, 10.0, 75.0],
        "look_at_position": [-10.0, 5.5, 60.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_driving_forward.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_driving_forward.png")
            break

    client.close()

if __name__ == "__main__":
    main()
