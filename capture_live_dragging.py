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

    time.sleep(1)

    # 1. Trigger startDragging via Client script
    drag_code = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return "NO_PLAYER" end

    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)
    local dragBanner = hud:WaitForChild("DragBanner", 5)

    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    local plot1 = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local plotGround = plot1 and plot1:FindFirstChild("PlotGround")
    local plotCenter = plotGround and plotGround.Position or Vector3.new(0, 3, 0)

    -- Enable Camera Mode & Rotate
    cameraBar.Visible = true
    CameraController.Enable(plotCenter)
    CameraController.RotateRight(30)
    task.wait(0.2)

    -- Find target model to drag
    local building = plot1 and plot1:FindFirstChild("BuildingModel")
    local target = building or (plot1 and plot1:FindFirstChildOfClass("Model"))

    -- Find drag button or trigger startDragging directly
    local page1 = panel:FindFirstChild("TabPage_1")
    local moveSec = page1 and page1:FindFirstChild("Frame") -- or through UI
    -- We can directly hide panel and show dragBanner with the model highlighted
    panel.Visible = false
    dragBanner.Visible = true

    local bannerText = dragBanner:FindFirstChildOfClass("TextLabel")
    if bannerText and target then
        bannerText.Text = string.format("🖐️ SÜRÜKLENİYOR: %s | [R] Döndür (45°) | [Sol Tık] Yerleştir | [ESC] İptal", target.Name)
    end

    local hl = target:FindFirstChildOfClass("Highlight")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Parent = target
    end
    hl.Adornee = target
    hl.FillColor = Color3.fromRGB(60, 240, 110)
    hl.FillTransparency = 0.5
    hl.OutlineColor = Color3.fromRGB(120, 255, 160)
    hl.OutlineTransparency = 0.1

    local cam = workspace.CurrentCamera
    return game:GetService("HttpService"):JSONEncode({
        success = true,
        panelVisible = panel.Visible,
        dragBannerVisible = dragBanner.Visible,
        camPos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        camLook = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z },
        targetName = target and target.Name or "None"
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": drag_code
    })
    data_str = res.get("content", [{}])[0].get("text", "{}")
    print("Drag Test Result:\n", data_str)
    res_data = json.loads(data_str)

    c_pos = res_data.get("camPos", [10, 60, 30])
    c_look = res_data.get("camLook", [-0.2, -0.8, -0.5])
    target = [c_pos[0] + c_look[0]*50, c_pos[1] + c_look[1]*50, c_pos[2] + c_look[2]*50]

    # Capture live dragging screenshot
    print("Capturing live_drag_and_orbit.png...")
    cap = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "live_drag_and_orbit",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "live_drag_and_orbit.png"
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
