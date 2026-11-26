import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    # Let's inspect what happens if we set currentSeat.Throttle = 1 or if we set a test flag in VehicleController
    # Or let's test the physics with throttle = 1 on client:
    code = """
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")

    -- Let's test if ThrottleFloat or Throttle can be set, or let's test if mover works when driven
    -- Wait, let's check what happens if we simulate W key press using VirtualInputManager!
    local vim = game:GetService("VirtualInputManager")
    local pos0 = root.Position
    local velList = {}

    -- Press W
    vim:SendKeyEvent(true, Enum.KeyCode.W, false, game)
    
    for i = 1, 30 do
        task.wait(0.05)
        table.insert(velList, string.format("step %d: vel=%.2f, pos=(%.1f, %.1f, %.1f), ThrottleFloat=%.1f",
            i, root.AssemblyLinearVelocity.Magnitude, root.Position.X, root.Position.Y, root.Position.Z, seat.ThrottleFloat))
    end

    -- Release W
    vim:SendKeyEvent(false, Enum.KeyCode.W, false, game)

    local pos1 = root.Position
    local dist = (pos1 - pos0).Magnitude

    return string.format("VIM W Press Result: Dist = %.2f studs\\n%s", dist, table.concat(velList, "\\n"))
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
