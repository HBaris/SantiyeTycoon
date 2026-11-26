import time
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. Stop play mode to edit assets in Edit datamodel
    print("Stopping play mode...")
    try:
        client.call_tool("start_stop_play", {
            "studio_id": studio_id,
            "is_start": False
        })
    except Exception as e:
        print("Stop play note:", e)

    time.sleep(2)
    client.close()

    # 2. Reconnect and create assets in Edit datamodel
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()

    create_assets_code = """
    local rs = game:GetService("ReplicatedStorage")
    local assets = rs:FindFirstChild("Assets")
    if not assets then
        assets = Instance.new("Folder")
        assets.Name = "Assets"
        assets.Parent = rs
    end

    local function getOrCreateFolder(parent: Instance, name: string): Folder
        local f = parent:FindFirstChild(name)
        if not f then
            f = Instance.new("Folder")
            f.Name = name
            f.Parent = parent
        end
        return f
    end

    local cargoFolder = getOrCreateFolder(assets, "Cargo")
    local vehiclesFolder = getOrCreateFolder(assets, "Vehicles")
    local propsFolder = getOrCreateFolder(assets, "Props")
    local treesFolder = getOrCreateFolder(assets, "Trees")

    local function makePart(parent: Instance, name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material): Part
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = col
        p.Material = mat
        p.Anchored = true
        p.CanCollide = true
        p.Parent = parent
        return p
    end

    -- ========================================================================
    -- 1. CARGO ASSETS (Yük & Şantiye Malzemeleri)
    -- ========================================================================

    -- A. BrickPallet (Ahşap palet üzerinde dizili kırmızı tuğlalar)
    if not cargoFolder:FindFirstChild("BrickPallet") then
        local m = Instance.new("Model")
        m.Name = "BrickPallet"
        local base = makePart(m, "PalletBase", Vector3.new(4, 0.4, 4), CFrame.new(0, 0.2, 0), Color3.fromRGB(160, 120, 70), Enum.Material.WoodPlanks)
        m.PrimaryPart = base

        -- Tuğla katmanları
        for y = 0, 2 do
            local brickLayer = makePart(m, "Bricks_" .. y, Vector3.new(3.6, 0.7, 3.6), CFrame.new(0, 0.4 + 0.35 + (y * 0.7), 0), Color3.fromRGB(180, 50, 35), Enum.Material.Brick)
        end
        -- Plastik ambalaj şeridi
        makePart(m, "Strap", Vector3.new(3.8, 2.2, 0.1), CFrame.new(0, 1.4, 0), Color3.fromRGB(30, 30, 30), Enum.Material.SmoothPlastic)
        m.Parent = cargoFolder
        print("Created BrickPallet asset")
    end

    -- B. CementBags (Palet üzerinde dizili çimento torbaları)
    if not cargoFolder:FindFirstChild("CementBags") then
        local m = Instance.new("Model")
        m.Name = "CementBags"
        local base = makePart(m, "PalletBase", Vector3.new(4.2, 0.4, 4.2), CFrame.new(0, 0.2, 0), Color3.fromRGB(150, 115, 65), Enum.Material.WoodPlanks)
        m.PrimaryPart = base

        for layer = 0, 2 do
            for ix = -1, 1 do
                for iz = -1, 1 do
                    local bag = makePart(m, string.format("Bag_%d_%d_%d", layer, ix, iz), Vector3.new(1.2, 0.6, 1.2), CFrame.new(ix * 1.3, 0.4 + 0.3 + (layer * 0.6), iz * 1.3), Color3.fromRGB(210, 210, 215), Enum.Material.Fabric)
                end
            end
        end
        m.Parent = cargoFolder
        print("Created CementBags asset")
    end

    -- C. CargoCrate (Endüstriyel ahşap kargo sandığı)
    if not cargoFolder:FindFirstChild("CargoCrate") then
        local m = Instance.new("Model")
        m.Name = "CargoCrate"
        local box = makePart(m, "CrateBody", Vector3.new(4, 4, 4), CFrame.new(0, 2, 0), Color3.fromRGB(190, 150, 95), Enum.Material.Wood)
        m.PrimaryPart = box

        -- Demir köşe braketleri
        for dx = -1, 1, 2 do
            for dy = 0, 1 do
                for dz = -1, 1, 2 do
                    makePart(m, "Bracket", Vector3.new(0.6, 0.6, 0.6), CFrame.new(dx * 1.9, 0.5 + dy * 3.0, dz * 1.9), Color3.fromRGB(50, 55, 60), Enum.Material.Metal)
                end
            end
        end
        m.Parent = cargoFolder
        print("Created CargoCrate asset")
    end

    -- D. SteelRebar (İnşaat demir donatı demetleri)
    if not cargoFolder:FindFirstChild("SteelRebar") then
        local m = Instance.new("Model")
        m.Name = "SteelRebar"
        local base = makePart(m, "RebarBase", Vector3.new(1.8, 0.4, 8), CFrame.new(0, 0.2, 0), Color3.fromRGB(120, 100, 70), Enum.Material.Wood)
        m.PrimaryPart = base

        for i = 1, 12 do
            local angle = (i / 12) * math.pi * 2
            local r = 0.55
            local ox = math.cos(angle) * r
            local oy = math.sin(angle) * r + 1.1
            makePart(m, "Bar_" .. i, Vector3.new(0.25, 0.25, 8.5), CFrame.new(ox, oy, 0), Color3.fromRGB(75, 80, 85), Enum.Material.CorrodedMetal)
        end
        -- Demir bağlama telleri
        for _, z in ipairs({ -3, 0, 3 }) do
            makePart(m, "Wire_" .. z, Vector3.new(1.6, 1.6, 0.2), CFrame.new(0, 1.1, z), Color3.fromRGB(240, 180, 20), Enum.Material.SmoothPlastic)
        end
        m.Parent = cargoFolder
        print("Created SteelRebar asset")
    end

    -- E. OilBarrels (Şantiye akaryakıt & madeni yağ varilleri)
    if not cargoFolder:FindFirstChild("OilBarrels") then
        local m = Instance.new("Model")
        m.Name = "OilBarrels"
        local base = makePart(m, "PalletBase", Vector3.new(4, 0.3, 4), CFrame.new(0, 0.15, 0), Color3.fromRGB(140, 110, 60), Enum.Material.WoodPlanks)
        m.PrimaryPart = base

        local offsets = {
            { -1, -1, Color3.fromRGB(200, 40, 40) }, -- Kırmızı Benzin
            {  1, -1, Color3.fromRGB(40, 100, 210) }, -- Mavi Dizel
            { -1,  1, Color3.fromRGB(230, 180, 30) }, -- Sarı Yağ
            {  1,  1, Color3.fromRGB(40, 160, 80) },  -- Yeşil Hidrolik
        }
        for idx, o in ipairs(offsets) do
            local barrel = makePart(m, "Barrel_" .. idx, Vector3.new(1.6, 2.8, 1.6), CFrame.new(o[1], 1.7, o[2]), o[3], Enum.Material.Metal)
            barrel.Shape = Enum.PartType.Cylinder
            barrel.CFrame = CFrame.new(o[1], 1.7, o[2]) * CFrame.Angles(0, 0, math.rad(90))
        end
        m.Parent = cargoFolder
        print("Created OilBarrels asset")
    end

    -- F. SiteContainer (Modern prefabrik şantiye ofisi konteyneri)
    if not cargoFolder:FindFirstChild("SiteContainer") then
        local m = Instance.new("Model")
        m.Name = "SiteContainer"
        local body = makePart(m, "ContainerBody", Vector3.new(7, 4.5, 14), CFrame.new(0, 2.25, 0), Color3.fromRGB(45, 90, 140), Enum.Material.Metal)
        m.PrimaryPart = body

        -- Çatı & Köşeler
        makePart(m, "Roof", Vector3.new(7.2, 0.4, 14.2), CFrame.new(0, 4.6, 0), Color3.fromRGB(230, 235, 240), Enum.Material.SmoothPlastic)
        -- Kapı
        makePart(m, "Door", Vector3.new(1.8, 3.2, 0.2), CFrame.new(0, 1.8, 7.05), Color3.fromRGB(240, 240, 245), Enum.Material.SmoothPlastic)
        -- Pencereler
        makePart(m, "Window1", Vector3.new(0.2, 1.6, 2.4), CFrame.new(3.55, 2.6, -2), Color3.fromRGB(160, 210, 245), Enum.Material.Glass)
        makePart(m, "Window2", Vector3.new(0.2, 1.6, 2.4), CFrame.new(-3.55, 2.6, -2), Color3.fromRGB(160, 210, 245), Enum.Material.Glass)
        m.Parent = cargoFolder
        print("Created SiteContainer asset")
    end

    -- ========================================================================
    -- 2. VEHICLE ASSETS (Müteahhit Araçları)
    -- ========================================================================

    -- A. Forklift (Şantiye Ağır Yük Forklifti)
    if not vehiclesFolder:FindFirstChild("Forklift") then
        local m = Instance.new("Model")
        m.Name = "Forklift"
        local chassis = makePart(m, "Chassis", Vector3.new(3.8, 1.2, 5.5), CFrame.new(0, 1.2, 0), Color3.fromRGB(245, 180, 20), Enum.Material.SmoothPlastic)
        m.PrimaryPart = chassis

        -- Karşı ağırlık (arka)
        makePart(m, "Counterweight", Vector3.new(3.6, 2.0, 1.8), CFrame.new(0, 2.2, 2.0), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
        -- Operatör kafesi
        makePart(m, "RollCage", Vector3.new(3.2, 3.6, 3.0), CFrame.new(0, 3.4, 0.2), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
        -- Asansör direkleri (ön)
        makePart(m, "Mast", Vector3.new(2.4, 5.0, 0.4), CFrame.new(0, 3.0, -2.8), Color3.fromRGB(40, 45, 50), Enum.Material.DiamondPlate)
        -- Çatallar (Forks)
        makePart(m, "ForkLeft", Vector3.new(0.4, 0.15, 3.2), CFrame.new(-0.8, 0.35, -4.2), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
        makePart(m, "ForkRight", Vector3.new(0.4, 0.15, 3.2), CFrame.new(0.8, 0.35, -4.2), Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
        -- Tekerlekler
        for _, z in ipairs({ -1.8, 1.8 }) do
            for _, x in ipairs({ -1.8, 1.8 }) do
                local w = makePart(m, "Wheel", Vector3.new(0.8, 1.4, 1.4), CFrame.new(x, 0.7, z), Color3.fromRGB(20, 20, 20), Enum.Material.Rubber)
            end
        end
        m.Parent = vehiclesFolder
        print("Created Forklift asset")
    end

    -- B. DumpTruck (Şantiye Damperli Kamyonu)
    if not vehiclesFolder:FindFirstChild("DumpTruck") then
        local m = Instance.new("Model")
        m.Name = "DumpTruck"
        local chassis = makePart(m, "Chassis", Vector3.new(5.0, 1.2, 11), CFrame.new(0, 1.4, 0), Color3.fromRGB(40, 40, 45), Enum.Material.Metal)
        m.PrimaryPart = chassis

        -- Kamyon Kabini (Ön)
        makePart(m, "Cab", Vector3.new(4.8, 3.6, 3.6), CFrame.new(0, 3.4, -3.5), Color3.fromRGB(240, 160, 20), Enum.Material.SmoothPlastic)
        -- Ön cam
        makePart(m, "Windshield", Vector3.new(4.2, 1.8, 0.2), CFrame.new(0, 4.0, -5.35), Color3.fromRGB(180, 220, 250), Enum.Material.Glass)
        -- Damper Kasası (Arka)
        makePart(m, "DumpBed", Vector3.new(5.2, 3.2, 7.0), CFrame.new(0, 3.5, 1.8), Color3.fromRGB(210, 140, 15), Enum.Material.DiamondPlate)
        -- 6 Adet Ağır Hizmet Tekerleği
        for _, z in ipairs({ -3.5, 1.0, 3.8 }) do
            for _, x in ipairs({ -2.5, 2.5 }) do
                local w = makePart(m, "HeavyWheel", Vector3.new(1.0, 2.0, 2.0), CFrame.new(x, 1.0, z), Color3.fromRGB(25, 25, 25), Enum.Material.Rubber)
            end
        end
        m.Parent = vehiclesFolder
        print("Created DumpTruck asset")
    end

    -- ========================================================================
    -- 3. LANDSCAPE & NATURE ASSETS (Peyzaj & Çevre)
    -- ========================================================================

    -- A. HedgeBush (Şantiye sınır çalı çiti)
    if not treesFolder:FindFirstChild("HedgeBush") then
        local m = Instance.new("Model")
        m.Name = "HedgeBush"
        local base = makePart(m, "Bush", Vector3.new(6, 3, 2), CFrame.new(0, 1.5, 0), Color3.fromRGB(45, 120, 50), Enum.Material.Grass)
        m.PrimaryPart = base
        m.Parent = treesFolder
        print("Created HedgeBush asset")
    end

    -- B. StoneRock (Peyzaj Granit Kayası)
    if not propsFolder:FindFirstChild("StoneRock") then
        local m = Instance.new("Model")
        m.Name = "StoneRock"
        local base = makePart(m, "RockBody", Vector3.new(4.5, 3.2, 4.0), CFrame.new(0, 1.6, 0), Color3.fromRGB(115, 120, 125), Enum.Material.Slate)
        m.PrimaryPart = base
        m.Parent = propsFolder
        print("Created StoneRock asset")
    end

    return "ASSETS_POPULATED_SUCCESSFULLY"
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Edit",
        "code": create_assets_code
    })

    print("Populate assets result:", res.get("content", [{}])[0].get("text", ""))
    client.close()

if __name__ == "__main__":
    main()
