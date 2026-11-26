import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # We run a test on Client where we set currentForwardSpeed to 28 for 100 frames and measure movement!
    test_client_drive = """
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")
    local stab = root:FindFirstChild("VehicleStabilizer")

    local initialPos = root.Position
    local initialCFrame = root.CFrame

    -- Let's apply LineVelocity = 28 directly on client for 60 frames (1 second)
    local heartbeatConn
    local frames = 0
    local speeds = {}

    -- Temporarily set mover
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.LineDirection = root.CFrame.LookVector
    mover.LineVelocity = 28
    mover.MaxForce = 350000

    -- We wait in a task
    local t0 = os.clock()
    while os.clock() - t0 < 1.0 do
        task.wait(0.1)
        mover.LineDirection = root.CFrame.LookVector
        mover.LineVelocity = 28
        table.insert(speeds, string.format("t=%.2f: vel=%.2f, pos=%s", os.clock() - t0, root.AssemblyLinearVelocity.Magnitude, tostring(root.Position)))
    end

    local finalPos = root.Position
    local dist = (finalPos - initialPos).Magnitude

    return string.format("Total Dist moved: %.2f studs\\nHistory:\\n%s", dist, table.concat(speeds, "\\n"))
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": test_client_drive
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
