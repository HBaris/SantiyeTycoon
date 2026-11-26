import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Client-side reset + drive up ramp
    drive_ramp_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    -- Align directly towards -Z facing ramp
    root.CFrame = CFrame.new(0, 5.5, 54) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    -- Wait 1 frame so Heartbeat picks up currentYaw = 0
    task.wait(0.1)

    -- Now apply throttle
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 20 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f, pitch=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude, root.Orientation.X))
    end
    seat:SetAttribute("TestThrottle", 0)

    return table.concat(log, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_ramp_code
    })
    print("Ramp Climb Test:\n", res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
