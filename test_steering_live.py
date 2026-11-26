import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # 1. Reset scooter to highway near depot
    reset_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    -- Place at depot facing highway (-Z direction)
    root.CFrame = CFrame.new(-54, 5.5, 63) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return "Scooter reset at " .. tostring(root.Position)
    """

    res_reset = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": reset_code
    })
    print("Reset:", res_reset.get("content", [{}])[0].get("text", ""))
    time.sleep(0.5)

    # 2. Test forward + steering left and right on client
    drive_test_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    -- Turn Left while moving forward for 1 second
    seat:SetAttribute("TestThrottle", 1)
    seat:SetAttribute("TestSteer", -1) -- steer left

    local initialYaw = root.Orientation.Y
    task.wait(1.0)
    local yawAfterLeft = root.Orientation.Y

    -- Now steer right for 1 second
    seat:SetAttribute("TestSteer", 1)
    task.wait(1.0)
    local yawAfterRight = root.Orientation.Y

    -- Stop
    seat:SetAttribute("TestThrottle", 0)
    seat:SetAttribute("TestSteer", 0)

    return string.format("InitialYaw=%.1f, LeftTurnYaw=%.1f, RightTurnYaw=%.1f, FinalPos=(%.1f, %.1f, %.1f), Vel=%.1f",
        initialYaw, yawAfterLeft, yawAfterRight, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude)
    """

    res_turn = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_test_code
    })
    print("Turn test:", res_turn.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
