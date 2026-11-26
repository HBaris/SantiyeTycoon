import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    diag_code = """
    local Players = game:GetService("Players")
    local p = Players:GetPlayers()[1]
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter found" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")

    local info = {}
    table.insert(info, "=== SCOOTER DIAGNOSTICS ===")
    table.insert(info, "RootPart: " .. root.Name .. " (Class: " .. root.ClassName .. ")")
    table.insert(info, "AssemblyRootPart: " .. tostring(root.AssemblyRootPart and root.AssemblyRootPart.Name))
    table.insert(info, "AssemblyMass: " .. tostring(root.AssemblyMass))
    table.insert(info, "Root Anchored: " .. tostring(root.Anchored))
    table.insert(info, "Root Position: " .. tostring(root.Position))
    table.insert(info, "Root CanCollide: " .. tostring(root.CanCollide))

    local netOwner = "None"
    pcall(function()
        local o = root:GetNetworkOwner()
        netOwner = o and o.Name or "Server"
    end)
    table.insert(info, "NetworkOwner: " .. netOwner)

    for _, desc in ipairs(veh:GetDescendants()) do
        if desc:IsA("BasePart") then
            table.insert(info, string.format("Part '%s': Anchored=%s, CanCollide=%s, Mass=%.2f, Size=%s",
                desc.Name, tostring(desc.Anchored), tostring(desc.CanCollide), desc.Mass, tostring(desc.Size)))
        end
    end

    if hum then
        table.insert(info, "Humanoid SeatPart: " .. tostring(hum.SeatPart and hum.SeatPart.Name))
        table.insert(info, "Humanoid Sit: " .. tostring(hum.Sit))
        table.insert(info, "HRP Anchored: " .. tostring(hrp and hrp.Anchored))
        table.insert(info, "HRP AssemblyRootPart: " .. tostring(hrp and hrp.AssemblyRootPart and hrp.AssemblyRootPart.Name))
    end

    local mover = root:FindFirstChild("VehicleMover")
    if mover then
        table.insert(info, string.format("Mover: Enabled=%s, Active=%s, Mode=%s, RelTo=%s, LineDir=%s, LineVel=%s, MaxForce=%.0f",
            tostring(mover.Enabled), tostring(mover.Active), tostring(mover.VelocityConstraintMode),
            tostring(mover.RelativeTo), tostring(mover.LineDirection), tostring(mover.LineVelocity), mover.MaxForce))
    else
        table.insert(info, "Mover: NOT FOUND")
    end

    local stab = root:FindFirstChild("VehicleStabilizer")
    if stab then
        table.insert(info, string.format("Stabilizer: Enabled=%s, Active=%s, Mode=%s, MaxTorque=%.0f, Responsiveness=%.0f, CFrame=%s",
            tostring(stab.Enabled), tostring(stab.Active), tostring(stab.Mode), stab.MaxTorque, stab.Responsiveness, tostring(stab.CFrame)))
    else
        table.insert(info, "Stabilizer: NOT FOUND")
    end

    return table.concat(info, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Server",
        "code": diag_code
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
