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

    local root = veh.PrimaryPart
    local mover = root:FindFirstChild("VehicleMover")
    local stab = root:FindFirstChild("VehicleStabilizer")
    local wF = veh:FindFirstChild("WheelFront")
    local wR = veh:FindFirstChild("WheelBack")

    local results = {}

    -- Check what root touches right now
    local touching = root:GetTouchingParts()
    local touchNames = {}
    for _, tp in ipairs(touching) do
        table.insert(touchNames, tp:GetFullName())
    end
    table.insert(results, "Root Touching: " .. table.concat(touchNames, ", "))

    local touchingWF = wF and wF:GetTouchingParts() or {}
    local wfNames = {}
    for _, tp in ipairs(touchingWF) do
        table.insert(wfNames, tp:GetFullName())
    end
    table.insert(results, "WheelFront Touching: " .. table.concat(wfNames, ", "))

    local touchingWR = wR and wR:GetTouchingParts() or {}
    local wrNames = {}
    for _, tp in ipairs(touchingWR) do
        table.insert(wrNames, tp:GetFullName())
    end
    table.insert(results, "WheelBack Touching: " .. table.concat(wrNames, ", "))

    -- TEST 1: Disable stabilizer, set CanCollide=false on wheels, apply velocity
    local origWFCanCollide = wF.CanCollide
    local origWRCanCollide = wR.CanCollide
    wF.CanCollide = false
    wR.CanCollide = false

    local p0 = root.Position
    mover.LineVelocity = 28
    task.wait(0.5)
    local p1 = root.Position
    local dist1 = (p1 - p0).Magnitude
    table.insert(results, string.format("Test 1 (Wheels CanCollide=false): dist=%.2f, vel=%.2f", dist1, root.AssemblyLinearVelocity.Magnitude))

    -- TEST 2: Also disable stabilizer
    stab.Enabled = false
    local p2 = root.Position
    mover.LineVelocity = 28
    task.wait(0.5)
    local p3 = root.Position
    local dist2 = (p3 - p2).Magnitude
    table.insert(results, string.format("Test 2 (No Stab, No Wheel Collide): dist=%.2f, vel=%.2f", dist2, root.AssemblyLinearVelocity.Magnitude))

    -- Restore stab
    stab.Enabled = true

    -- TEST 3: Lift up by 3 studs in air
    root.CFrame = root.CFrame + Vector3.new(0, 3, 0)
    task.wait(0.1)
    local p4 = root.Position
    mover.LineVelocity = 28
    task.wait(0.5)
    local p5 = root.Position
    local dist3 = (p5 - p4).Magnitude
    table.insert(results, string.format("Test 3 (Lifted in air): dist=%.2f, vel=%.2f", dist3, root.AssemblyLinearVelocity.Magnitude))

    -- Reset mover
    mover.LineVelocity = 0
    wF.CanCollide = origWFCanCollide
    wR.CanCollide = origWRCanCollide

    return table.concat(results, "\\n")
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
