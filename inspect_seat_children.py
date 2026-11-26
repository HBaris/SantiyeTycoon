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
    local lines = {}
    table.insert(lines, "Seat Class: " .. seat.ClassName)
    table.insert(lines, "Seat Occupant: " .. tostring(seat.Occupant and seat.Occupant:GetFullName()))
    for _, ch in ipairs(seat:GetChildren()) do
        table.insert(lines, string.format("Child: %s (%s)", ch.Name, ch.ClassName))
        if ch:IsA("Weld") or ch:IsA("WeldConstraint") then
            table.insert(lines, string.format("  Part0=%s, Part1=%s", tostring(ch.Part0), tostring(ch.Part1)))
        end
    end
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
