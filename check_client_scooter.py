import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    client_diag = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "Client: No scooter found" end

    local seat = veh:FindFirstChildWhichIsA("VehicleSeat", true)
    local root = veh.PrimaryPart or seat
    local mover = root:FindFirstChild("VehicleMover")
    local stab = root:FindFirstChild("VehicleStabilizer")
    local att = root:FindFirstChild("DriveAttachment")

    local lines = {}
    table.insert(lines, "=== CLIENT DIAGNOSTICS ===")
    table.insert(lines, "Seat: " .. tostring(seat and seat:GetFullName()))
    table.insert(lines, "Seat Occupant: " .. tostring(seat and seat.Occupant and seat.Occupant.Parent.Name))
    table.insert(lines, "ThrottleFloat: " .. tostring(seat and seat.ThrottleFloat))
    table.insert(lines, "SteerFloat: " .. tostring(seat and seat.SteerFloat))
    table.insert(lines, "Attachment0 valid: " .. tostring(mover and mover.Attachment0 == att))
    table.insert(lines, "Mover Enabled: " .. tostring(mover and mover.Enabled))
    table.insert(lines, "Mover Active: " .. tostring(mover and mover.Active))
    table.insert(lines, "Mover LineVelocity: " .. tostring(mover and mover.LineVelocity))
    table.insert(lines, "Mover LineDirection: " .. tostring(mover and mover.LineDirection))
    table.insert(lines, "Mover MaxForce: " .. tostring(mover and mover.MaxForce))
    table.insert(lines, "Stabilizer Active: " .. tostring(stab and stab.Active))
    table.insert(lines, "Root AssemblyLinearVelocity: " .. tostring(root.AssemblyLinearVelocity))

    return table.concat(lines, "\\n")
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Client",
        "code": client_diag
    })
    print(res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
