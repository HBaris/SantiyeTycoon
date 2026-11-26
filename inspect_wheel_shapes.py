import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Test ramp climbing with smooth sphere collision vs square block wheels
    test_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    -- Check shapes
    local wfShape = wF and wF.Shape and wF.Shape.Name or "nil"
    local wrShape = wR and wR.Shape and wR.Shape.Name or "nil"

    -- Place scooter in front of ramp (X=0, Z=52, Y=5.5) FACING NORTH (-Z)
    root.CFrame = CFrame.new(0, 5.5, 52) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    -- Ensure client owns network
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return string.format("WF Shape: %s, WR Shape: %s, Scooter placed facing ramp", wfShape, wrShape)
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": test_code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
