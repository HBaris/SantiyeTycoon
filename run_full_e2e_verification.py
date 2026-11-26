import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Ensure character is loaded and sitting in scooter
    setup_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    if not p then return "NO_PLAYER" end

    -- Load character if not yet loaded
    if not p.Character then
        p:LoadCharacter()
    end
    local char = p.Character or p.CharacterAdded:Wait()
    local hum = char:WaitForChild("Humanoid", 5)

    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then
        local GarageService = require(game:GetService("ServerScriptService").Server.Services.GarageService)
        veh = GarageService.SpawnVehicle(p, "Scooter")
    end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat

    root:SetNetworkOwner(p)
    seat:Sit(hum)

    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    return string.format("Setup OK: Pos=%s, LookVec=%s, WF_Shape=%s, WR_Shape=%s, Occupant=%s",
        tostring(root.Position), tostring(root.CFrame.LookVector), tostring(wF and wF.Shape), tostring(wR and wR.Shape),
        tostring(seat.Occupant and seat.Occupant.Parent.Name))
    """

    res_s = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": setup_code
    })
    print("Step 1 (Setup):\n", res_s.get("content", [{}])[0].get("text", ""))

    time.sleep(1.0)

    # Step 2: Test driving forward on highway
    drive_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    local p0 = root.Position
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 15 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude))
    end
    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    return string.format("Drive Forward: Dist=%.2f studs\\nLog:\\n%s", dist, table.concat(log, "\\n"))
    """

    res_d = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_code
    })
    print("Step 2 (Drive Forward):\n", res_d.get("content", [{}])[0].get("text", ""))

    # Capture driving screenshot
    cap1 = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_highway_smooth",
        "camera_position": [-40.0, 11.0, 75.0],
        "look_at_position": [-20.0, 5.5, 60.0]
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            with open("scooter_highway_smooth.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_highway_smooth.png")
            break

    client.close()

if __name__ == "__main__":
    main()
