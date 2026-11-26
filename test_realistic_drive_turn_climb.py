import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Reset scooter at highway X = -25, facing East (Yaw = -90)
    # The ramp is at X = 0, Z = 43. Highway is at Z = 54.
    # So driving from X = -25 to X = 0, then steering left (A) turns towards Z = 43 (the ramp)!
    reset_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    -- Unsit and sit to cleanly reset currentYaw on client
    if hum.SeatPart then hum.Sit = false end
    task.wait(0.2)

    root.CFrame = CFrame.new(-25, 5.5, 54) * CFrame.Angles(0, math.rad(-90), 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    task.wait(0.2)
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return "Reset at " .. tostring(root.Position)
    """

    res_r = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": reset_code
    })
    print("Reset:", res_r.get("content", [{}])[0].get("text", ""))

    time.sleep(1.0)

    # Step 2: Drive along highway, steer left towards the ramp, and climb!
    drive_turn_climb_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    local log = {}

    -- Phase 1: Drive straight East along highway for 0.8s towards X = -5
    seat:SetAttribute("TestThrottle", 1)
    seat:SetAttribute("TestSteer", 0)
    for i = 1, 8 do
        task.wait(0.1)
        table.insert(log, string.format("Phase1 t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f, yaw=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude, root.Orientation.Y))
    end

    -- Phase 2: Steer left (turn north towards ramp at X=0, Z=43) while throttling for 0.6s
    seat:SetAttribute("TestSteer", -1)
    for i = 1, 6 do
        task.wait(0.1)
        table.insert(log, string.format("Phase2 (Turn) t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f, yaw=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude, root.Orientation.Y))
    end

    -- Phase 3: Straighten out and climb the ramp onto the plot for 1.2s!
    seat:SetAttribute("TestSteer", 0)
    for i = 1, 12 do
        task.wait(0.1)
        table.insert(log, string.format("Phase3 (Climb) t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f, Y=%.2f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude, root.Position.Y))
    end

    seat:SetAttribute("TestThrottle", 0)
    seat:SetAttribute("TestSteer", 0)

    return table.concat(log, "\\n")
    """

    res_dtc = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_turn_climb_code
    })
    print("Drive-Turn-Climb Log:\n", res_dtc.get("content", [{}])[0].get("text", ""))

    # Capture screenshot of scooter at the plot after climbing
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_climbed_plot_final",
        "camera_position": [20.0, 14.0, 50.0],
        "look_at_position": [5.0, 7.0, 30.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_climbed_plot_final.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_climbed_plot_final.png")
            break

    client.close()

if __name__ == "__main__":
    main()
