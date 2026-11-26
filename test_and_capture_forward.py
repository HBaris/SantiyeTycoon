import base64
import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Ensure character is seated on the scooter and positioned facing the road
    prep_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    if not p or not p.Character then return "No character" end

    local GS = require(game:GetService("ServerScriptService").Server.Services.GarageService)
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then
        veh = GS.SpawnVehicle(p, "Scooter")
    end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    if seat and hum and seat.Occupant ~= hum then
        seat:Sit(hum)
        veh.PrimaryPart:SetNetworkOwner(p)
    end

    -- Orient scooter facing along highway towards plot (towards -Z)
    veh:PivotTo(CFrame.new(-54.0, 5.5, 60.0) * CFrame.Angles(0, 0, 0))

    return string.format("Prepped! Seated: %s, Heading: %s",
        tostring(seat and seat.Occupant ~= nil),
        tostring(veh.PrimaryPart.CFrame.LookVector))
    """
    res1 = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": prep_code
    })
    print("Prep:", res1.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Step 2: Drive forward on the Client for 1.2 seconds and track movement
    drive_test_code = """
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local char = lp.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart :: VehicleSeat?
    if not seat then return "Client: No seat" end

    local root = seat.Parent and seat.Parent.PrimaryPart or seat
    local mover = root:FindFirstChild("VehicleMover") :: LinearVelocity?
    if not mover then return "Client: No mover" end

    local pStart = root.Position
    local frames = {}

    -- Apply forward drive: LineDirection = LookVector, LineVelocity = 28
    for i = 1, 8 do
        mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
        mover.RelativeTo = Enum.ActuatorRelativeTo.World
        mover.LineDirection = root.CFrame.LookVector
        mover.LineVelocity = 28
        mover.MaxForce = 350000
        task.wait(0.1)
        table.insert(frames, string.format("f%d: pos=(%.1f, %.1f), vel=(%.1f, %.1f)",
            i, root.Position.X, root.Position.Z,
            root.AssemblyLinearVelocity.X, root.AssemblyLinearVelocity.Z))
    end

    local pEnd = root.Position
    local dist = (pEnd - pStart).Magnitude
    local velFinal = root.AssemblyLinearVelocity

    return string.format("CLIENT FORWARD DRIVE SUCCESS! Dist=%.2f studs, FinalVel=(%.1f, %.1f, %.1f)\n%s",
        dist, velFinal.X, velFinal.Y, velFinal.Z, table.concat(frames, ", "))
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": drive_test_code
    })
    print("Drive Test Result:\n", res2.get("content", [{}])[0].get("text", ""))

    time.sleep(0.3)

    # Step 3: Capture screenshot of the scooter driving forward on the highway
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_driving_forward_success",
        "camera_position": [-45.0, 10.0, 52.0],
        "look_at_position": [-54.0, 6.0, 36.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_driving_forward_success.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_driving_forward_success.png")
            break

    client.close()

if __name__ == "__main__":
    main()
