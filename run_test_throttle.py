import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")

    -- Set test throttle on seat
    local p0 = root.Position
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 20 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: vel=%.2f, lineVel=%.1f, pos=(%.1f, %.1f, %.1f)",
            i * 0.1, root.AssemblyLinearVelocity.Magnitude, mover.LineVelocity, root.Position.X, root.Position.Y, root.Position.Z))
    end

    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    return string.format("Total Dist: %.2f studs\\nLog:\\n%s", dist, table.concat(log, "\\n"))
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
