import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Check scooter and sit player
    seat_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then
        -- Spawn if not present
        local GarageService = require(game:GetService("ServerScriptService").Server.Services.GarageService)
        veh = GarageService.SpawnVehicle(p, "Scooter")
    end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    if seat and hum then
        root:SetNetworkOwner(p)
        seat:Sit(hum)
    end

    local mover = root:FindFirstChild("VehicleMover")
    local stab = root:FindFirstChild("VehicleStabilizer")
    local wF = veh:FindFirstChild("WheelFront")

    return string.format("Scooter at %s, WF_Shape=%s, Occupant=%s, MoverEnabled=%s, StabEnabled=%s",
        tostring(root.Position), tostring(wF and wF.Shape), tostring(seat.Occupant and seat.Occupant.Parent.Name),
        tostring(mover and mover.Enabled), tostring(stab and stab.Enabled))
    """

    res_seat = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": seat_code
    })
    print("Step 1 (Seat):", res_seat.get("content", [{}])[0].get("text", ""))

    time.sleep(1.0)

    # Step 2: Drive forward on highway using TestThrottle = 1
    drive_code = """
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
    return string.format("Drive result: Dist=%.2f studs, Start=(%.1f, %.1f), End=(%.1f, %.1f)\\nLog:\\n%s",
        dist, p0.X, p0.Z, p1.X, p1.Z, table.concat(log, "\\n"))
    """

    res_drive = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_code
    })
    print("Step 2 (Drive):\n", res_drive.get("content", [{}])[0].get("text", ""))

    # Step 3: Capture screenshot of moving scooter with speedometer
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_highway_driving",
        "camera_position": [-35.0, 11.0, 74.0],
        "look_at_position": [-15.0, 5.5, 60.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_highway_driving.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_highway_driving.png")
            break

    client.close()

if __name__ == "__main__":
    main()
