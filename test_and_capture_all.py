import base64
import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # 1. Sit player on scooter and position at Depot
    sit_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    if not p or not p.Character then return "No char" end
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    local veh = workspace:FindFirstChild("Scooter_" .. p.Name) or workspace:FindFirstChildWhichIsA("Model")
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name:find("Scooter") then veh = v break end
    end
    if not veh then return "No scooter" end
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    if seat and hum then
        seat:Sit(hum)
    end
    -- Position at loading pad
    veh:PivotTo(CFrame.new(-56.0, 5.5, 48.0) * CFrame.Angles(0, math.rad(-90), 0))
    return "Seated at Depot: " .. tostring(seat.Occupant ~= nil)
    """
    res1 = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": sit_code
    })
    print("Sit result:", res1.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Capture 1: Scooter at Depot Loading Pad
    cap1 = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_depot_final",
        "camera_position": [-68.0, 10.0, 56.0],
        "look_at_position": [-56.0, 5.5, 48.0]
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            with open("scooter_depot_final.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Saved scooter_depot_final.png")
            break

    # 2. Position scooter driving up the PlotEntranceRamp
    ramp_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh
    for _, v in ipairs(workspace:GetChildren()) do
        if v.Name:find("Scooter") then veh = v break end
    end
    if veh then
        -- Ramp is at (-22.0, 5.4, 38.0). Position scooter right on the ramp climbing up!
        veh:PivotTo(CFrame.new(-22.0, 5.8, 38.0) * CFrame.Angles(math.rad(-11), 0, 0))
    end
    return "Positioned on ramp"
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": ramp_code
    })
    print("Ramp position:", res2.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Capture 2: Scooter climbing entrance ramp
    cap2 = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "entrance_ramp_final",
        "camera_position": [-10.0, 11.0, 46.0],
        "look_at_position": [-22.0, 6.0, 36.0]
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            with open("entrance_ramp_final.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Saved entrance_ramp_final.png")
            break

    # Capture 3: Promenade Full Clean View
    cap3 = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "promenade_verified_final",
        "camera_position": [-18.0, 14.0, 50.0],
        "look_at_position": [-22.0, 7.0, 15.0]
    })
    for item in cap3.get("content", []):
        if item.get("type") == "image":
            with open("promenade_verified_final.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Saved promenade_verified_final.png")
            break

    client.close()

if __name__ == "__main__":
    main()
