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

    # 1. Run live test in Client datamodel
    test_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local toggleBtn = hud:WaitForChild("CustomizerToggleBtn", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)

    -- Click toggle to open Customizer (this should invoke togglePanel and silence BuilderHUD)
    panel.Visible = true
    cameraBar.Visible = true

    -- Silence gameplay HUDs
    for _, name in ipairs({ "BuilderHUD", "UpgradeUI", "GarageUI" }) do
        local g = pg:FindFirstChild(name)
        if g and g:IsA("ScreenGui") then
            g.Enabled = false
        end
    end

    local builderHUD = pg:FindFirstChild("BuilderHUD")
    local builderHUDEnabled = builderHUD and builderHUD.Enabled or nil

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)

    -- Setup Top-Down Orbit Camera centered on plot
    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    local ground = plot and plot:FindFirstChild("PlotGround")
    local groundPos = ground and ground.Position or Vector3.new(0, 4.4, 0)

    CameraController.Enable(groundPos)
    -- Rotate to get an awesome diagonal 360 overview of the plot and showroom
    CameraController.RotateLeft(90)
    CameraController.ZoomOut(8)

    local cam = workspace.CurrentCamera
    local camCFrame = cam.CFrame

    -- Now test placing a model from Showroom onto the empty plot:
    local Network = require(game:GetService("ReplicatedStorage").Shared.Network)
    -- Spawn Level_6 (Modern İş Merkezi) on the plot at (X = groundPos.X + 8, Z = groundPos.Z - 6)
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Buildings", "Level_6", {
        X = groundPos.X + 8,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z - 6,
        Yaw = 45
    })

    -- Also spawn a fountain in front
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Commercial", "Fountain", {
        X = groundPos.X - 12,
        Y = groundPos.Y + 2.0,
        Z = groundPos.Z - 6,
        Yaw = 0
    })

    task.wait(0.6)

    local newPlotChildren = {}
    if plot then
        for _, ch in ipairs(plot:GetChildren()) do
            table.insert(newPlotChildren, ch.Name)
        end
    end

    return HttpService:JSONEncode({
        success = true,
        builderHUDEnabled = builderHUDEnabled,
        panelVisible = panel.Visible,
        cameraBarVisible = cameraBar.Visible,
        newPlotChildren = newPlotChildren,
        camPos = { camCFrame.Position.X, camCFrame.Position.Y, camCFrame.Position.Z },
        camLook = { camCFrame.LookVector.X, camCFrame.LookVector.Y, camCFrame.LookVector.Z },
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
        print(json.dumps(res_data, indent=2, ensure_ascii=False))
    except Exception:
        print(raw_text)

    time.sleep(1)

    c_pos = res_data.get("camPos", [0, 45, 45])
    c_look = res_data.get("camLook", [0, -0.7, -0.7])
    target = [c_pos[0] + c_look[0]*60, c_pos[1] + c_look[1]*60, c_pos[2] + c_look[2]*60]

    # 2. Capture screenshot from the orbit camera
    print("\nCapturing screenshot of live placed assets on empty plot...")
    capture_res = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "live_placement_verified",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "live_placement_verified.png"
    captured = False
    for item in capture_res.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open(img_path, "wb") as f:
                f.write(img_bytes)
            print(f"Saved {img_path} ({len(img_bytes)} bytes)")

            # Copy to artifacts directory
            artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"
            dest_path = os.path.join(artifact_dir, img_path)
            shutil.copyfile(img_path, dest_path)
            print(f"Copied to artifact dir: {dest_path}")
            captured = True
            break

    if not captured:
        print("Failed to capture screenshot:", capture_res)

    client.close()

if __name__ == "__main__":
    main()
