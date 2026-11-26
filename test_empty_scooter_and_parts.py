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
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    local lines = {}

    -- Step 1: Make player jump out of seat
    if hum and hum.SeatPart then
        hum.Sit = false
        task.wait(0.2)
    end
    table.insert(lines, "Player in seat: " .. tostring(seat.Occupant ~= nil))

    -- Step 2: Now that seat is empty, try mover on scooter
    local p0 = root.Position
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.LineDirection = Vector3.new(0, 0, -1)
    mover.LineVelocity = 28
    mover.MaxForce = 350000

    task.wait(0.5)
    local p1 = root.Position
    local distEmpty = (p1 - p0).Magnitude
    local velEmpty = root.AssemblyLinearVelocity.Magnitude
    table.insert(lines, string.format("Empty scooter: dist=%.2f, vel=%.2f", distEmpty, velEmpty))

    -- Step 3: Test a plain block with LinearVelocity
    local testPart = Instance.new("Part")
    testPart.Size = Vector3.new(2, 2, 2)
    testPart.Position = Vector3.new(0, 20, 0)
    testPart.Anchored = false
    testPart.CanCollide = false
    local att = Instance.new("Attachment", testPart)
    local lv = Instance.new("LinearVelocity", testPart)
    lv.Attachment0 = att
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.LineDirection = Vector3.new(0, 0, -1)
    lv.LineVelocity = 28
    lv.MaxForce = 350000
    testPart.Parent = workspace

    task.wait(0.5)
    local testVel = testPart.AssemblyLinearVelocity.Magnitude
    local testDist = (testPart.Position - Vector3.new(0, 20, 0)).Magnitude
    table.insert(lines, string.format("TestPart in air: dist=%.2f, vel=%.2f", testDist, testVel))
    testPart:Destroy()

    -- Reset mover
    mover.LineVelocity = 0

    return table.concat(lines, "\\n")
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
