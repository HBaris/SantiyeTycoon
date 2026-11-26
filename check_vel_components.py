import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    test_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    -- Check current velocity
    local v = root.AssemblyLinearVelocity
    local forward = root.CFrame.LookVector
    local right = root.CFrame.RightVector
    local up = root.CFrame.UpVector

    local fSpeed = v:Dot(forward)
    local rSpeed = v:Dot(right)
    local uSpeed = v:Dot(up)

    return string.format("AssemblyVel: Mag=%.1f (Forward=%.1f, LateralRight=%.1f, Up=%.1f)",
        v.Magnitude, fSpeed, rSpeed, uSpeed)
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": test_code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
