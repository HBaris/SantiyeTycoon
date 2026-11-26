from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")

    -- Make player sit from SERVER
    seat:Sit(hum)
    root:SetNetworkOwner(p)
    task.wait(0.5)

    local lines = {}
    table.insert(lines, "Server Seat Occupant: " .. tostring(seat.Occupant and seat.Occupant.Parent.Name))
    for _, ch in ipairs(seat:GetChildren()) do
        if ch:IsA("Weld") or ch.Name:find("Weld") then
            table.insert(lines, string.format("Weld in Seat: %s (%s) Part0=%s, Part1=%s", ch.Name, ch.ClassName, tostring(ch.Part0), tostring(ch.Part1)))
        end
    end
    for _, ch in ipairs(p.Character.HumanoidRootPart:GetChildren()) do
        if ch:IsA("Weld") or ch.Name:find("Weld") then
            table.insert(lines, string.format("Weld in HRP: %s (%s) Part0=%s, Part1=%s", ch.Name, ch.ClassName, tostring(ch.Part0), tostring(ch.Part1)))
        end
    end

    table.insert(lines, "AssemblyRootPart: " .. tostring(root.AssemblyRootPart and root.AssemblyRootPart:GetFullName()))
    table.insert(lines, "AssemblyMass: " .. tostring(root.AssemblyMass))

    -- Try mover on Server
    local mover = root:FindFirstChild("VehicleMover")
    mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
    mover.RelativeTo = Enum.ActuatorRelativeTo.World
    mover.LineDirection = root.CFrame.LookVector
    mover.LineVelocity = 28
    mover.MaxForce = 350000

    local p0 = root.Position
    task.wait(0.5)
    local p1 = root.Position
    local dist = (p1 - p0).Magnitude
    table.insert(lines, string.format("Movement with server sit: dist=%.2f, vel=%.2f", dist, root.AssemblyLinearVelocity.Magnitude))

    mover.LineVelocity = 0

    return table.concat(lines, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
