import base64
import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    drive_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if seat and hum and seat.Occupant ~= hum then
        seat:Sit(hum)
        root:SetNetworkOwner(p)
    end

    local mover = root:FindFirstChild("VehicleMover")
    if mover then
        mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
        mover.LineDirection = Vector3.new(0, 0, -1)
        mover.LineVelocity = 28
        mover.MaxForce = 350000
    end

    return "Driving forward initiated"
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": drive_code
    })
    print("Drive result:", res.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Capture driving screenshot from third person camera
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_driving_active",
        "camera_position": [-50.0, 10.0, 68.0],
        "look_at_position": [-40.0, 6.0, 50.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_driving_active.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_driving_active.png")
            break

    # Measure position after driving
    measure_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end
    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")
    local speed = root.AssemblyLinearVelocity.Magnitude
    local pos = root.Position

    -- Slow down
    if mover then mover.LineVelocity = 0 end

    return string.format("Scooter at Pos=(%.1f, %.1f, %.1f), Speed=%.1f studs/s (%d km/h)",
        pos.X, pos.Y, pos.Z, speed, math.floor(speed * 2.2))
    """
    res_m = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": measure_code
    })
    print("Measure result:", res_m.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
