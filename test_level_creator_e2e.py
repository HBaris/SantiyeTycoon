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
    # TEST 1: Check Garage Relocation
    # =========================================================================
    check_garage_code = """
    local sss = game:GetService("ServerScriptService")
    local garageFacility = workspace:FindFirstChild("GarageFacility")
    local floor = garageFacility and garageFacility:FindFirstChild("GarageDepotFloor")
    local building = garageFacility and garageFacility:FindFirstChild("DepotBuilding")
    local loadingPad = garageFacility and garageFacility:FindFirstChild("CargoLoadingPad")

    return game:GetService("HttpService"):JSONEncode({
        facilityFound = garageFacility ~= nil,
        floorPos = floor and { X = floor.Position.X, Y = floor.Position.Y, Z = floor.Position.Z },
        buildingPos = building and { X = building.Position.X, Y = building.Position.Y, Z = building.Position.Z },
        loadingPadPos = loadingPad and { X = loadingPad.Position.X, Y = loadingPad.Position.Y, Z = loadingPad.Position.Z },
        isAcrossRoad = floor and floor.Position.Z > 80,
        isAwayFromShowroom = floor and math.abs(floor.Position.X - (-70)) > 50
    })
    """
    res1 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Server", "code": check_garage_code})
    data1 = json.loads(res1.get("content", [{}])[0].get("text", "{}"))
    print("\n--- GARAGE RELOCATION RESULT ---")
    print(json.dumps(data1, indent=2, ensure_ascii=True))

    # =========================================================================
    # TEST 2: Open Design Engine & Check Chat Suppression and UI Layout
    # =========================================================================
    open_design_code = """
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player:WaitForChild("PlayerGui", 5)
    local devHud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = devHud:WaitForChild("CustomizerPanel", 5)
    local toggleBtn = devHud:WaitForChild("CustomizerToggleBtn", 5)

    -- Open the panel if closed
    if not panel.Visible then
        panel.Visible = true
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    end

    return game:GetService("HttpService"):JSONEncode({
        panelVisible = panel.Visible,
        panelPos = { X = panel.Position.X.Offset, Y = panel.Position.Y.Offset, ScaleY = panel.Position.Y.Scale },
        panelSize = { X = panel.Size.X.Offset, Y = panel.Size.Y.Offset }
    })
    """
    res2 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": open_design_code})
    data2 = json.loads(res2.get("content", [{}])[0].get("text", "{}"))
    print("\n--- DESIGN ENGINE UI RESULT ---")
    print(json.dumps(data2, indent=2, ensure_ascii=True))

    # =========================================================================
    # TEST 3: Spawn a Model, Test Top-Level Selection, Height Nudge, and Snap to Ground
    # =========================================================================
    test_level_creator_code = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local Network = require(game:GetService("ReplicatedStorage").Shared.Network)
    local plotName = string.format("Plot_%s_1", player.Name)
    local plotFolder = workspace:FindFirstChild(plotName)

    -- 1. Spawn a Forklift from Vehicles category
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Vehicles", "Forklift", { X = 0, Y = 6, Z = 0, Yaw = 0 })
    task.wait(0.5)

    local spawnedTruck = nil
    for _, child in ipairs(plotFolder:GetChildren()) do
        if child:IsA("Model") and child.Name:find("Custom_Forklift") then
            spawnedTruck = child
            break
        end
    end

    if not spawnedTruck then
        return game:GetService("HttpService"):JSONEncode({ error = "SPAWN_FAILED" })
    end

    local initialCF = spawnedTruck:GetPivot()
    local initialY = initialCF.Position.Y

    -- 2. Test Vertical Up Nudge (+5 Y)
    Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "Nudge", Vector3.new(0, 5, 0))
    task.wait(0.2)
    local afterUpY = spawnedTruck:GetPivot().Position.Y

    -- 3. Test SnapGround (Bring down to earth)
    Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "SnapGround")
    task.wait(0.2)
    local groundedCF = spawnedTruck:GetPivot()
    local groundedY = groundedCF.Position.Y

    -- 4. Test Horizontal Nudge (+3 X, -4 Z)
    Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "Nudge", Vector3.new(3, 0, -4))
    task.wait(0.2)
    local afterNudgePos = spawnedTruck:GetPivot().Position

    -- 5. Test Scale (+25%)
    Network.CustomizeModelEvent:FireServer(1, spawnedTruck.Name, "Scale", 1.25)
    task.wait(0.2)
    local scaledSize = spawnedTruck:GetExtentsSize()

    return game:GetService("HttpService"):JSONEncode({
        success = true,
        modelName = spawnedTruck.Name,
        initialY = initialY,
        afterUpY = afterUpY,
        upDiff = afterUpY - initialY,
        groundedY = groundedY,
        groundDiff = afterUpY - groundedY,
        afterNudgePos = { X = afterNudgePos.X, Y = afterNudgePos.Y, Z = afterNudgePos.Z },
        scaledSize = { X = scaledSize.X, Y = scaledSize.Y, Z = scaledSize.Z }
    })
    """
    res3 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": test_level_creator_code})
    data3 = json.loads(res3.get("content", [{}])[0].get("text", "{}"))
    print("\n--- LEVEL CREATOR TRANSFORM TEST RESULT ---")
    print(json.dumps(data3, indent=2, ensure_ascii=True))

    # =========================================================================
    # STEP 4: Camera View 1 - Level Creator Panel & Selected Model on Plot
    # =========================================================================
    cam_script1 = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local plotName = string.format("Plot_%s_1", player.Name)
    local plotFolder = workspace:FindFirstChild(plotName)
    local truck = nil
    for _, ch in ipairs(plotFolder:GetChildren()) do
        if ch:IsA("Model") and ch.Name:find("Custom_") then
            truck = ch
            break
        end
    end
    local truckPos = truck and truck:GetPivot().Position or Vector3.new(3, 8.4, -4)
    local camPos = truckPos + Vector3.new(20, 16, 26)

    Camera.CFrame = CFrame.lookAt(camPos, truckPos)
    return game:GetService("HttpService"):JSONEncode({
        camPos = { camPos.X, camPos.Y, camPos.Z },
        target = { truckPos.X, truckPos.Y, truckPos.Z }
    })
    """
    res_c1 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": cam_script1})
    c1_data = json.loads(res_c1.get("content", [{}])[0].get("text", "{}"))
    time.sleep(1)

    cap1 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "level_creator_ui_verified",
        "camera_position": c1_data.get("camPos", [23, 24, 22]),
        "look_at_position": c1_data.get("target", [3, 8.4, -4])
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("level_creator_ui_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("level_creator_ui_verified.png", os.path.join(artifact_dir, "level_creator_ui_verified.png"))
            print("Saved level_creator_ui_verified.png")
            break

    # =========================================================================
    # STEP 5: Camera View 2 - Garage Facility Relocated Across Highway
    # =========================================================================
    cam_script2 = """
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    local garage = workspace:FindFirstChild("GarageFacility")
    local floor = garage and garage:FindFirstChild("GarageDepotFloor")
    local floorPos = floor and floor.Position or Vector3.new(15, 4.2, 105)
    local camPos = floorPos + Vector3.new(-38, 34, -42)

    -- View garage and its connection to highway, showing isolation from showroom
    Camera.CFrame = CFrame.lookAt(camPos, floorPos)
    return game:GetService("HttpService"):JSONEncode({
        camPos = { camPos.X, camPos.Y, camPos.Z },
        target = { floorPos.X, floorPos.Y, floorPos.Z }
    })
    """
    res_c2 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": cam_script2})
    c2_data = json.loads(res_c2.get("content", [{}])[0].get("text", "{}"))
    time.sleep(1)

    cap2 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "garage_relocated_verified",
        "camera_position": c2_data.get("camPos", [-23, 38, 63]),
        "look_at_position": c2_data.get("target", [15, 4.2, 105])
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("garage_relocated_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("garage_relocated_verified.png", os.path.join(artifact_dir, "garage_relocated_verified.png"))
            print("Saved garage_relocated_verified.png")
            break

if __name__ == "__main__":
    main()
