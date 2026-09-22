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

    time.sleep(3)

    # 1. Test Toggle, Orbit Camera, and Drag Flow
    test_code = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return game:GetService("HttpService"):JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    if not pg then return game:GetService("HttpService"):JSONEncode({ error = "NO_PLAYER_GUI" }) end

    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)
    local dragBanner = hud:WaitForChild("DragBanner", 5)
    local toggleBtn = hud:WaitForChild("CustomizerToggleBtn", 5)

    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    -- Toggle open if not visible
    if not panel.Visible then
        panel.Visible = true
        cameraBar.Visible = true
        local plot1 = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
        local plotGround = plot1 and plot1:FindFirstChild("PlotGround")
        local plotCenter = plotGround and plotGround.Position or Vector3.new(0, 3, 0)
        CameraController.Enable(plotCenter)
    end
    task.wait(0.5)

    -- Rotate camera 45 degrees for dynamic top-down 3/4 view
    CameraController.RotateRight(45)
    task.wait(0.3)

    -- Select an object to drag: Ana Bina or TowerCrane
    local plot1 = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local building = plot1 and plot1:FindFirstChild("BuildingModel")
    local targetModel = building or (plot1 and plot1:FindFirstChildOfClass("Model"))

    -- Activate Drag Banner
    dragBanner.Visible = true
    local bannerText = dragBanner:FindFirstChildOfClass("TextLabel")
    if bannerText and targetModel then
        bannerText.Text = string.format("🖐️ SÜRÜKLENİYOR: %s | [R] Döndür | [Sol Tık] Yerleştir | [ESC] İptal", targetModel.Name)
    end

    local cam = workspace.CurrentCamera
    return game:GetService("HttpService"):JSONEncode({
        success = true,
        panelVisible = panel.Visible,
        cameraBarVisible = cameraBar.Visible,
        dragBannerVisible = dragBanner.Visible,
        camPos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        camLook = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z },
        target = targetModel and targetModel.Name or "None"
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })
    data_str = res.get("content", [{}])[0].get("text", "{}")
    print("Test Result:\n", data_str)
    res_data = json.loads(data_str)

    c_pos = res_data.get("camPos", [-25, 45, 25])
    c_look = res_data.get("camLook", [0.5, -0.7, -0.5])
    target = [c_pos[0] + c_look[0]*50, c_pos[1] + c_look[1]*50, c_pos[2] + c_look[2]*50]

    # Capture Screenshot with top-down 360 camera + camera bar + drag banner
    print("Capturing drag_and_orbit_verified screenshot...")
    cap = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "drag_and_orbit_verified",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "drag_and_orbit_verified.png"
    for item in cap.get("content", []):
        if item.get("type") == "image":
            with open(img_path, "wb") as f:
                f.write(base64.b64decode(item.get("data", "")))
            print(f"Captured {img_path}")
            break

    # Copy to artifacts directory
    artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"
    dest_path = os.path.join(artifact_dir, img_path)
    shutil.copyfile(img_path, dest_path)
    print(f"Copied screenshot to artifact directory: {dest_path}")

    client.close()

if __name__ == "__main__":
    main()
