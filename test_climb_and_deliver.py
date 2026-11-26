import time
import base64
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Step 1: Load cargo first via server to ensure we have 15 cargo
    load_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local GarageService = require(game:GetService("ServerScriptService").Server.Services.GarageService)
    local loaded = GarageService.LoadCargo(p)
    return "Cargo loaded: " .. tostring(loaded) .. " Cargo amount: " .. tostring(GarageService.GetCargo(p))
    """
    res_load = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": load_code
    })
    print("Step 1 (Load Cargo):", res_load.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Step 2: Position scooter at the base of PlotEntranceRamp facing UP the ramp (north, -Z)
    # PlotEntranceRamp is at X=0, Z=43, Size=(16, 2, 10). Base of ramp is at Z=48.
    # Highway is at Z=52.
    position_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    -- Teleport to base of ramp facing north towards plot
    root.CFrame = CFrame.new(0, 5.2, 50) * CFrame.Angles(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root:SetNetworkOwner(p)
    seat:Sit(hum)

    return "Positioned at base of ramp: " .. tostring(root.Position)
    """
    res_pos = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": position_code
    })
    print("Step 2 (Position):", res_pos.get("content", [{}])[0].get("text", ""))

    time.sleep(0.5)

    # Step 3: Drive forward UP the ramp onto the plot!
    climb_code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart

    -- Drive forward
    seat:SetAttribute("TestThrottle", 1)

    local log = {}
    for i = 1, 15 do
        task.wait(0.1)
        table.insert(log, string.format("t=%.1fs: pos=(%.1f, %.1f, %.1f), vel=%.1f",
            i * 0.1, root.Position.X, root.Position.Y, root.Position.Z, root.AssemblyLinearVelocity.Magnitude))
    end
    seat:SetAttribute("TestThrottle", 0)

    return table.concat(log, "\\n")
    """
    res_climb = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": climb_code
    })
    print("Step 3 (Climb Log):\n", res_climb.get("content", [{}])[0].get("text", ""))

    # Capture screenshot on the plot
    cap = client.call_tool("screen_capture", {
        "studio_id": sid,
        "capture_id": "scooter_on_plot_successful",
        "camera_position": [15.0, 12.0, 45.0],
        "look_at_position": [0.0, 7.5, 32.0]
    })
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open("scooter_on_plot_successful.png", "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print("Captured scooter_on_plot_successful.png")
            break

    client.close()

if __name__ == "__main__":
    main()
