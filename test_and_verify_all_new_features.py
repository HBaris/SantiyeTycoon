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

    # 1. Inspect Plot and Showroom in Client datamodel
    test_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)
    if not plot then return HttpService:JSONEncode({ error = "NO_PLOT" }) end

    -- Check signage and spawn positions
    local signPost = plot:FindFirstChild("SignPost")
    local signBoard = plot:FindFirstChild("SignBoard")
    local spawnLocation = plot:FindFirstChild("PlotSpawn")
    local cargoPad = plot:FindFirstChild("CargoUnloadPad")

    local posInfo = {
        signPost = signPost and { X = signPost.Position.X, Y = signPost.Position.Y, Z = signPost.Position.Z },
        signBoard = signBoard and { X = signBoard.Position.X, Y = signBoard.Position.Y, Z = signBoard.Position.Z },
        spawn = spawnLocation and { X = spawnLocation.Position.X, Y = spawnLocation.Position.Y, Z = spawnLocation.Position.Z },
        cargoPad = cargoPad and { X = cargoPad.Position.X, Y = cargoPad.Position.Y, Z = cargoPad.Position.Z },
    }

    -- Check Showroom models
    local showroom = plot:FindFirstChild("ShowroomPalette")
    local showroomItems = {}
    if showroom then
        for _, ch in ipairs(showroom:GetChildren()) do
            if ch:IsA("Model") then
                local pivot = ch:GetPivot().Position
                table.insert(showroomItems, {
                    name = ch.Name,
                    category = ch:GetAttribute("Category"),
                    assetId = ch:GetAttribute("AssetId"),
                    pos = { X = math.round(pivot.X*10)/10, Y = math.round(pivot.Y*10)/10, Z = math.round(pivot.Z*10)/10 }
                })
            end
        end
    end

    -- Setup Top-Down Camera and silence HUDs
    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)
    panel.Visible = true
    cameraBar.Visible = true

    for _, name in ipairs({ "BuilderHUD", "UpgradeUI", "GarageUI" }) do
        local g = pg:FindFirstChild(name)
        if g and g:IsA("ScreenGui") then g.Enabled = false end
    end

    local ground = plot:FindFirstChild("PlotGround")
    local groundPos = ground and ground.Position or Vector3.new(0, 4.4, 0)

    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    CameraController.Enable(groundPos)
    CameraController.ZoomOut(20)

    -- Test spawning items on and outside plot:
    local Network = require(game:GetService("ReplicatedStorage").Shared.Network)
    
    -- 1. Outside plot: CypressTree at X = 50, Z = 15
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Trees", "CypressTree", {
        X = groundPos.X + 52,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z + 15,
        Yaw = 0
    })

    -- 2. Outside plot: DumpTruck on entrance road at X = -8, Z = 52
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Vehicles", "DumpTruck", {
        X = groundPos.X - 8,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z + 52,
        Yaw = 90
    })

    -- 3. On plot: BrickPallet
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Cargo", "BrickPallet", {
        X = groundPos.X + 12,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z + 8,
        Yaw = 0
    })

    -- 4. On plot: Forklift
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Vehicles", "Forklift", {
        X = groundPos.X - 12,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z - 8,
        Yaw = 45
    })

    task.wait(0.5)

    -- Wait for camera render loop
    for _ = 1, 8 do
        RunService.RenderStepped:Wait()
    end
    task.wait(0.2)

    local cam = workspace.CurrentCamera
    return HttpService:JSONEncode({
        success = true,
        posInfo = posInfo,
        showroomCount = #showroomItems,
        showroomItems = showroomItems,
        camPos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        camLook = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z },
        groundPos = { groundPos.X, groundPos.Y, groundPos.Z }
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })

    raw_text = res.get("content", [{}])[0].get("text", "{}")
    print("Execution output:")
    res_data = {}
    try:
        res_data = json.loads(raw_text)
        print(f"Success: {res_data.get('success')}")
        print(f"Positions Info: {json.dumps(res_data.get('posInfo'), indent=2)}")
        print(f"Showroom Count: {res_data.get('showroomCount')}")
    except Exception as e:
        print("Parse error:", e, raw_text)

    time.sleep(0.5)

    artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"

    # --- Capture 1: Showroom Plaza View (looking at the vehicle/cargo showroom and empty plot) ---
    print("\nCapturing 1: Showroom Plaza View...")
    c_pos = [-95, 75, 20]
    target = [-60, 5, 0]
    cap1 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "rich_showroom_plaza",
        "camera_position": c_pos,
        "look_at_position": target
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("rich_showroom_plaza.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("rich_showroom_plaza.png", os.path.join(artifact_dir, "rich_showroom_plaza.png"))
            print("Saved and copied rich_showroom_plaza.png")
            break

    # --- Capture 2: Plot View showing signage outside & placed models ---
    print("\nCapturing 2: Signs Outside & Placed Models View...")
    c_pos2 = [20, 85, 75]
    target2 = [0, 4, 15]
    cap2 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "signs_outside_and_clean_plot",
        "camera_position": c_pos2,
        "look_at_position": target2
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("signs_outside_and_clean_plot.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("signs_outside_and_clean_plot.png", os.path.join(artifact_dir, "signs_outside_and_clean_plot.png"))
            print("Saved and copied signs_outside_and_clean_plot.png")
            break

    client.close()

if __name__ == "__main__":
    main()
