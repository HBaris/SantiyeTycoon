import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    test_luau = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    -- Convert wheels to Cylinders
    if wF then
        wF.Shape = Enum.PartType.Cylinder
        wF.Size = Vector3.new(0.8, 1.8, 1.8)
        wF.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.01, 0.0, 100, 100)
    end
    if wR then
        wR.Shape = Enum.PartType.Cylinder
        wR.Size = Vector3.new(0.8, 1.8, 1.8)
        wR.CustomPhysicalProperties = PhysicalProperties.new(0.5, 0.01, 0.0, 100, 100)
    end

    -- Test ground normal calculation at ramp
    local rampPos = Vector3.new(0, 5.2, 43)
    local ray = workspace:Raycast(rampPos + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0))
    local rampNormal = ray and ray.Normal or Vector3.new(0, 1, 0)

    return string.format("WF Shape=%s, Size=%s; Ramp Normal=%s, HitPart=%s",
        tostring(wF.Shape), tostring(wF.Size), tostring(rampNormal), tostring(ray and ray.Instance.Name))
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": test_luau
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
