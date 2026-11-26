from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()

    code = """
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    local char = p.Character
    if not char then return "No character" end

    local lines = {}
    table.insert(lines, "=== CHARACTER TREE & CONSTRAINTS ===")
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Constraint") or desc:IsA("BodyMover") or desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
            local part0 = (desc:IsA("Constraint") and desc.Attachment0 and desc.Attachment0.Parent and desc.Attachment0.Parent.Name) or (desc:IsA("JointInstance") and desc.Part0 and desc.Part0.Name) or "nil"
            local part1 = (desc:IsA("Constraint") and desc.Attachment1 and desc.Attachment1.Parent and desc.Attachment1.Parent.Name) or (desc:IsA("JointInstance") and desc.Part1 and desc.Part1.Name) or "nil"
            table.insert(lines, string.format("%s '%s': Part0=%s, Part1=%s", desc.ClassName, desc.Name, part0, part1))
        end
    end

    -- Also check Seat descendants
    local veh = workspace:FindFirstChild("Vehicle_" .. p.Name .. "_Scooter")
    if veh then
        table.insert(lines, "=== VEHICLE CONSTRAINTS ===")
        for _, desc in ipairs(veh:GetDescendants()) do
            if desc:IsA("Constraint") or desc:IsA("BodyMover") or desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
                table.insert(lines, string.format("%s '%s' in %s", desc.ClassName, desc.Name, desc.Parent.Name))
            end
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
