import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    local p0 = root.Position
    seat:SetAttribute("TestThrottle", -1)
    task.wait(1.0)
    seat:SetAttribute("TestThrottle", 0)

    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    local vel = root.AssemblyLinearVelocity.Magnitude

    return string.format("Reverse test: Dist moved=%.2f studs, Vel=%.2f", dist, vel)
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
