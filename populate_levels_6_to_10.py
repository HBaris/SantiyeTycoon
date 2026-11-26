import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    sid = client.get_studio_id()
    print("Connected Studio ID:", sid)

    luau_code = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:WaitForChild("Assets")
    local buildings = assets:WaitForChild("Buildings")
    local services = assets:FindFirstChild("Services")

    -- Check if Level_6 to 10 already exist
    local l1 = buildings:FindFirstChild("Level_1")
    local l2 = buildings:FindFirstChild("Level_2")
    local l3 = buildings:FindFirstChild("Level_3")
    local l4 = buildings:FindFirstChild("Level_4")
    local l5 = buildings:FindFirstChild("Level_5")

    -- 1. Level_6: Modern İş Merkezi / Business Plaza
    if not buildings:FindFirstChild("Level_6") and l4 then
        local l6 = l4:Clone()
        l6.Name = "Level_6"
        l6.Parent = buildings
        print("Created Level_6 (Modern İş Merkezi) in Edit datamodel")
    end

    -- 2. Level_7: Şehir Kompleksi & Güvenlik Merkezi (FireStation)
    if not buildings:FindFirstChild("Level_7") and services and services:FindFirstChild("FireStation") then
        local l7 = services:FindFirstChild("FireStation"):Clone()
        l7.Name = "Level_7"
        l7.Parent = buildings
        print("Created Level_7 (Şehir Kompleksi) in Edit datamodel")
    end

    -- 3. Level_8: Şehir Sağlık & Tıp Merkezi (Clinic)
    if not buildings:FindFirstChild("Level_8") and services and services:FindFirstChild("Clinic") then
        local l8 = services:FindFirstChild("Clinic"):Clone()
        l8.Name = "Level_8"
        l8.Parent = buildings
        print("Created Level_8 (Sağlık & Tıp Merkezi) in Edit datamodel")
    end

    -- 4. Level_9: Çift Kule Finans Merkezi (Twin Financial Towers)
    if not buildings:FindFirstChild("Level_9") and l5 then
        local l9 = Instance.new("Model")
        l9.Name = "Level_9"
        
        local tower1 = l5:Clone()
        tower1.Name = "EastTower"
        tower1:ScaleTo(0.65)
        local cf1 = tower1:GetPivot()
        tower1:PivotTo(cf1 + Vector3.new(-18, 0, 0))
        tower1.Parent = l9

        local tower2 = l5:Clone()
        tower2.Name = "WestTower"
        tower2:ScaleTo(0.65)
        local cf2 = tower2:GetPivot()
        tower2:PivotTo(cf2 + Vector3.new(18, 0, 0))
        tower2.Parent = l9

        -- Skybridge
        local bridge = Instance.new("Part")
        bridge.Name = "SkyBridge"
        bridge.Size = Vector3.new(24, 6, 12)
        bridge.Position = cf1.Position + Vector3.new(0, 120, 0)
        bridge.Material = Enum.Material.Glass
        bridge.Color = Color3.fromRGB(160, 210, 240)
        bridge.Transparency = 0.3
        bridge.Anchored = true
        bridge.Parent = l9

        l9.PrimaryPart = bridge
        l9.Parent = buildings
        print("Created Level_9 (Çift Kule Finans Merkezi) in Edit datamodel")
    end

    -- 5. Level_10: Metropolis Mega Gökdeleni (Pinnacle Skyscraper)
    if not buildings:FindFirstChild("Level_10") and l5 then
        local l10 = l5:Clone()
        l10.Name = "Level_10"
        l10:ScaleTo(1.15)

        -- Add crowning spire
        local cf10, sz10 = l10:GetBoundingBox()
        local spire = Instance.new("Part")
        spire.Name = "MetropolisSpire"
        spire.Size = Vector3.new(4, 50, 4)
        spire.Position = Vector3.new(cf10.Position.X, cf10.Position.Y + sz10.Y/2 + 25, cf10.Position.Z)
        spire.Material = Enum.Material.Neon
        spire.Color = Color3.fromRGB(255, 230, 80)
        spire.Anchored = true
        spire.Parent = l10

        local beacon = Instance.new("PointLight")
        beacon.Color = Color3.fromRGB(255, 240, 100)
        beacon.Range = 60
        beacon.Brightness = 3
        beacon.Parent = spire

        l10.Parent = buildings
        print("Created Level_10 (Metropolis Mega Gökdelen) in Edit datamodel")
    end

    local count = #buildings:GetChildren()
    local names = {}
    for _, ch in ipairs(buildings:GetChildren()) do
        table.insert(names, ch.Name)
    end
    return game:GetService("HttpService"):JSONEncode({
        totalBuildings = count,
        buildings = names
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": sid,
        "datamodel_type": "Edit",
        "code": luau_code
    })
    print("Result:", res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
