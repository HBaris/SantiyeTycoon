import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # 1. Place scooter in front of ramp (X=0, Z=54, Y=5.5) facing ramp (-Z)
    prep_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    -- Setup cylinders
    for _, w in ipairs({ wF, wR }) do
        if w then
            w.Shape = Enum.PartType.Cylinder
            w.Size = Vector3.new(0.8, 1.8, 1.8)
            w.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.01, 0.0, 100, 100)
        end
    end

    root.CFrame = CFrame.new(0, 5.5, 54) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return "Prepped at " .. tostring(root.Position)
    """

    res_prep = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": prep_code
    })
    print("Prep:", res_prep.get("content", [{}])[0].get("text", ""))
    time.sleep(0.5)

    # 2. On client: run custom driving loop with ground-normal alignment for 2.5 seconds
    client_climb_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")
    local stab = root:FindFirstChild("VehicleStabilizer")

    local yaw = 0 -- facing north (-Z)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { veh, p.Character }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local log = {}
    for i = 1, 25 do
        task.wait(0.1)

        -- Raycast down
        local ray = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -7, 0), rayParams)
        local normal = ray and ray.Normal or Vector3.new(0, 1, 0)

        local forwardHoriz = (CFrame.Angles(0, math.rad(yaw), 0) * Vector3.new(0, 0, -1)).Unit
        local projectedLook = (forwardHoriz - normal * forwardHoriz:Dot(normal)).Unit
        local rightVec = projectedLook:Cross(normal).Unit

        stab.CFrame = CFrame.fromMatrix(root.Position, rightVec, normal)

        mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
        mover.RelativeTo = Enum.ActuatorRelativeTo.World
        mover.LineDirection = root.CFrame.LookVector
        mover.LineVelocity = 24
        mover.MaxForce = 350000

        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f, ground=%s",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude,
            ray and ray.Instance.Name or "air"))
    end

    mover.LineVelocity = 0

    return table.concat(log, "\\n")
    """

    res_climb = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": client_climb_code
    })
    print("Climb Output:\n", res_climb.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
