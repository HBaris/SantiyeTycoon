from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if not veh then return "No scooter" end

    local root = veh.PrimaryPart
    local stab = root:FindFirstChild("VehicleStabilizer")
    local mover = root:FindFirstChild("VehicleMover")

    local lines = {}
    table.insert(lines, "Root Orientation: " .. tostring(root.Orientation))
    table.insert(lines, "Root LookVector: " .. tostring(root.CFrame.LookVector))
    table.insert(lines, "Root RightVector: " .. tostring(root.CFrame.RightVector))
    table.insert(lines, "Root UpVector: " .. tostring(root.CFrame.UpVector))
    table.insert(lines, "Stabilizer CFrame LookVector: " .. tostring(stab.CFrame.LookVector))
    table.insert(lines, "Stabilizer CFrame UpVector: " .. tostring(stab.CFrame.UpVector))
    table.insert(lines, "Mover LineDirection: " .. tostring(mover.LineDirection))
    table.insert(lines, "Mover LineVelocity: " .. tostring(mover.LineVelocity))

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
