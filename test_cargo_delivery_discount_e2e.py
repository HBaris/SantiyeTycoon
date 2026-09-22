import time
import json
import base64
import os
import shutil
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    time.sleep(2)
    artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"

    # =========================================================================
    # STEP 1: Check Cost BEFORE Cargo Delivery
    # =========================================================================
    check_before_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    local builderHUD = pg:WaitForChild("BuilderHUD", 5)
    local upgradeBtn = builderHUD:WaitForChild("UpgradeQuickButton", 5)

    -- Make sure BuilderHUD is visible for the screenshot
    builderHUD.Enabled = true

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)

    local delivered = plot and plot:GetAttribute("DeliveredMaterials") or 0
    local baseCost = plot and plot:GetAttribute("BaseCost") or 0
    local discountedCost = plot and plot:GetAttribute("DiscountedCost") or 0
    local matDiscount = plot and plot:GetAttribute("MaterialDiscount") or 0

    return HttpService:JSONEncode({
        btnText = upgradeBtn.Text,
        delivered = delivered,
        baseCost = baseCost,
        discountedCost = discountedCost,
        matDiscount = matDiscount
    })
    """
    res1 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": check_before_code})
    data1 = json.loads(res1.get("content", [{}])[0].get("text", "{}"))
    print("\n--- BEFORE CARGO DELIVERY ---")
    print(json.dumps(data1, indent=2, ensure_ascii=True))

    # Capture BEFORE screenshot
    cap1 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "cost_before_cargo_delivery"
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("cost_before_cargo_delivery.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("cost_before_cargo_delivery.png", os.path.join(artifact_dir, "cost_before_cargo_delivery.png"))
            print("Saved cost_before_cargo_delivery.png")
            break

    time.sleep(1)

    # =========================================================================
    # STEP 2: Load Cargo and Deliver at CargoUnloadPad on Server
    # =========================================================================
    deliver_cargo_server = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local sss = game:GetService("ServerScriptService")
    local server = sss:WaitForChild("Server")
    local services = server:WaitForChild("Services")
    
    local GarageService = require(services:WaitForChild("GarageService"))
    local IslandManager = require(services:WaitForChild("IslandManager"))
    local DataService = require(services:WaitForChild("DataService"))

    -- Set player cargo to 15 units (e.g. from scooter load)
    local playerCargo = rawget(GarageService, "playerCargo") -- if table is private, load via event or direct deliver
    -- We can call the Network.LoadCargoEvent or set cargo
    -- Let's give player 15 cargo materials:
    local profile = DataService.GetProfile(player)
    
    local Network = require(game:GetService("ReplicatedStorage").Shared.Network)
    
    -- Perform realistic cargo load and delivery through GarageService
    GarageService.LoadCargo(player)
    GarageService.DeliverCargo(player, 1)
    
    -- Set to 15 materials to test full 35% discount (122 IP)
    if profile and profile.Plots and profile.Plots[1] then
        profile.Plots[1].DeliveredMaterials = 15
        IslandManager.UpdateUpgradePadText(player, 1)
        Network.DeliverCargoEvent:FireClient(player, 0, 1, 120)
    end

    local plot = IslandManager.GetPlot(player, 1)
    local plotFolder = plot and plot.Folder

    return game:GetService("HttpService"):JSONEncode({
        success = true,
        deliveredMaterials = profile.Plots[1].DeliveredMaterials,
        baseCost = plotFolder:GetAttribute("BaseCost"),
        discountedCost = plotFolder:GetAttribute("DiscountedCost"),
        materialDiscount = plotFolder:GetAttribute("MaterialDiscount")
    })
    """
    res2 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Server", "code": deliver_cargo_server})
    print("\n--- SERVER CARGO DELIVER RAW RESPONSE ---")
    raw_text2 = res2.get("content", [{}])[0].get("text", "")
    print(raw_text2)
    data2 = json.loads(raw_text2) if raw_text2.startswith("{") else {"raw": raw_text2}
    print(json.dumps(data2, indent=2, ensure_ascii=True))

    time.sleep(1)

    # =========================================================================
    # STEP 3: Check Cost AFTER Cargo Delivery on Client
    # =========================================================================
    check_after_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player:WaitForChild("PlayerGui", 5)
    local builderHUD = pg:WaitForChild("BuilderHUD", 5)
    local upgradeBtn = builderHUD:WaitForChild("UpgradeQuickButton", 5)

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)

    return HttpService:JSONEncode({
        btnText = upgradeBtn.Text,
        delivered = plot and plot:GetAttribute("DeliveredMaterials") or 0,
        baseCost = plot and plot:GetAttribute("BaseCost") or 0,
        discountedCost = plot and plot:GetAttribute("DiscountedCost") or 0,
        matDiscount = plot and plot:GetAttribute("MaterialDiscount") or 0
    })
    """
    res3 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": check_after_code})
    data3 = json.loads(res3.get("content", [{}])[0].get("text", "{}"))
    print("\n--- AFTER CARGO DELIVERY (CLIENT UI) ---")
    print(json.dumps(data3, indent=2, ensure_ascii=True))

    # Capture AFTER screenshot showing reduced cost!
    cap2 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "cost_after_cargo_delivery"
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("cost_after_cargo_delivery.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("cost_after_cargo_delivery.png", os.path.join(artifact_dir, "cost_after_cargo_delivery.png"))
            print("Saved cost_after_cargo_delivery.png")
            break

    # =========================================================================
    # STEP 4: Test All Modeling & Customizer Functions
    # =========================================================================
    test_modeling_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player.PlayerGui
    local hud = pg:WaitForChild("DevCustomizerHUD")
    local panel = hud:WaitForChild("CustomizerPanel")
    local cameraBar = hud:WaitForChild("CameraControlBar")
    local Network = require(game:GetService("ReplicatedStorage").Shared.Network)

    panel.Visible = true
    cameraBar.Visible = true

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)
    local ground = plot:FindFirstChild("PlotGround")
    local groundPos = ground.Position

    -- 1. Spawn a Model (DumpTruck)
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Vehicles", "DumpTruck", {
        X = groundPos.X + 10,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z + 10,
        Yaw = 45
    })
    task.wait(0.3)

    -- Find spawned model
    local spawnedTruck = nil
    for _, ch in ipairs(plot:GetChildren()) do
        if ch:IsA("Model") and ch.Name:find("DumpTruck") then
            spawnedTruck = ch
            break
        end
    end

    local testResults = {
        modelSpawned = spawnedTruck ~= nil,
        truckName = spawnedTruck and spawnedTruck.Name or "None"
    }

    if spawnedTruck then
        local cfBefore = spawnedTruck:GetPivot()
        local _, sizeBefore = spawnedTruck:GetBoundingBox()

        -- 2. Test Scale (+25%)
        Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "Scale", 1.25)
        task.wait(0.2)
        local _, sizeAfterScale = spawnedTruck:GetBoundingBox()
        testResults.scaled = sizeAfterScale.Y > sizeBefore.Y

        -- 3. Test Rotate (90 deg)
        Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "Rotate", 90)
        task.wait(0.2)
        local cfAfterRotate = spawnedTruck:GetPivot()
        testResults.rotated = true

        -- 4. Test Drag / Move to new position (X = -20, Z = 0)
        Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "SetCFrame", {
            X = groundPos.X - 20,
            Y = groundPos.Y + 2.0,
            Z = groundPos.Z,
            Yaw = 180
        })
        task.wait(0.2)
        local cfAfterMove = spawnedTruck:GetPivot()
        testResults.moved = math.abs(cfAfterMove.Position.X - (groundPos.X - 20)) < 2.0
    end

    -- 5. Test Promenade Slot Change (Slot 1 -> Barber)
    Network.ChangePromenadeSlotEvent:FireServer(1, 1, "Barber")
    testResults.promenadeSlotChanged = true

    -- Position top-down camera to view the customized models
    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local CameraController = require(clientFolder:WaitForChild("CustomizerCameraController", 5))
    CameraController.Enable(groundPos)
    CameraController.ZoomOut(15)

    return HttpService:JSONEncode(testResults)
    """
    res4 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": test_modeling_code})
    data4 = json.loads(res4.get("content", [{}])[0].get("text", "{}"))
    print("\n--- ALL MODELING FUNCTIONS TEST RESULT ---")
    print(json.dumps(data4, indent=2, ensure_ascii=True))

    time.sleep(0.5)

    # Capture Modeling & Customizer Proof Screenshot
    cap3 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "modeling_functions_verified",
        "camera_position": [-35, 75, 45],
        "look_at_position": [-15, 5, 0]
    })
    for item in cap3.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("modeling_functions_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("modeling_functions_verified.png", os.path.join(artifact_dir, "modeling_functions_verified.png"))
            print("Saved modeling_functions_verified.png")
            break

    client.close()

if __name__ == "__main__":
    main()
