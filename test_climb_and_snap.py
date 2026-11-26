import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Align scooter right in front of PlotEntranceRamp (X=0, Z=54, Y=5.5) facing north (-Z)
    align_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    -- Place directly at base of ramp facing north towards plot
    root.CFrame = CFrame.new(0, 5.5, 52) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return "Aligned facing ramp: " .. tostring(root.Position)
    """

    res_a = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": align_code
    })
    print("Align:", res_a.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Drive up the ramp onto the plot (throttle = 1 for 1.8s)
    climb_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    local p0 = root.Position
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 18 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude))
    end
    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    return string.format("Climb completed: Start=(%.1f, %.1f, %.1f) -> End=(%.1f, %.1f, %.1f)\\nLog:\\n%s",
        p0.X, p0.Y, p0.Z, p1.X, p1.Y, p1.Z, table.concat(log, "\\n"))
    """

    res_c = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": climb_code
    })
    print("Climb Result:\n", res_c.get("content", [{}])[0].get("text", ""))

    # Capture screenshot on the plot
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_on_plot_climbed",
        "camera_position": [18.0, 12.0, 48.0],
        "look_at_position": [0.0, 7.0, 32.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_on_plot_climbed.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_on_plot_climbed.png")
            break

    client.close()

if __name__ == "__main__":
    main()
