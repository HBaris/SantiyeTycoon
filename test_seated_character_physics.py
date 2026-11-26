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
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")

    local lines = {}

    -- Put player back in seat
    seat:Sit(hum)
    task.wait(0.3)
    table.insert(lines, "Sitting: " .. tostring(seat.Occupant ~= nil))
    table.insert(lines, "AssemblyRootPart: " .. tostring(root.AssemblyRootPart.Name))

    -- Check all character parts CanCollide and touching
    for _, part in ipairs(p.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(lines, string.format("CharPart %s: CanCollide=%s, Mass=%.1f", part.Name, tostring(part.CanCollide), part.Mass))
        end
    end

    -- TEST A: Try moving now (baseline with player sitting)
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.LineDirection = Vector3.new(0, 0, -1)
    mover.LineVelocity = 28
    mover.MaxForce = 350000
    local pA0 = root.Position
    task.wait(0.4)
    local distA = (root.Position - pA0).Magnitude
    table.insert(lines, string.format("Test A (Normal sitting): dist=%.2f, vel=%.2f", distA, root.AssemblyLinearVelocity.Magnitude))

    -- TEST B: Set CanCollide=false on ALL character parts (including HRP, feet, etc.)
    for _, part in ipairs(p.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    local pB0 = root.Position
    task.wait(0.4)
    local distB = (root.Position - pB0).Magnitude
    table.insert(lines, string.format("Test B (Char CanCollide=false): dist=%.2f, vel=%.2f", distB, root.AssemblyLinearVelocity.Magnitude))

    -- TEST C: What if Humanoid.PlatformStand = true?
    hum.PlatformStand = true
    local pC0 = root.Position
    task.wait(0.4)
    local distC = (root.Position - pC0).Magnitude
    table.insert(lines, string.format("Test C (PlatformStand=true): dist=%.2f, vel=%.2f", distC, root.AssemblyLinearVelocity.Magnitude))
    hum.PlatformStand = false

    -- TEST D: What if VehicleSeat.Torque = 0, MaxSpeed = 0?
    local origTorque = seat.Torque
    local origMaxSpeed = seat.MaxSpeed
    seat.Torque = 0
    seat.MaxSpeed = 0
    local pD0 = root.Position
    task.wait(0.4)
    local distD = (root.Position - pD0).Magnitude
    table.insert(lines, string.format("Test D (Seat Torque=0, MaxSpeed=0): dist=%.2f, vel=%.2f", distD, root.AssemblyLinearVelocity.Magnitude))
    seat.Torque = origTorque
    seat.MaxSpeed = origMaxSpeed

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
