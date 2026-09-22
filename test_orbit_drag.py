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

    # 1. Test Client-side camera and drag functionality
    test_code = """
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return game:GetService("HttpService"):JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    if not pg then return game:GetService("HttpService"):JSONEncode({ error = "NO_PLAYER_GUI" }) end

    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    if not hud then return game:GetService("HttpService"):JSONEncode({ error = "NO_HUD" }) end

    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)
    local dragBanner = hud:WaitForChild("DragBanner", 5)
    local toggleBtn = hud:WaitForChild("CustomizerToggleBtn", 5)

    -- Require CameraController
    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    -- Get Plot Center
    local plot1 = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local plotGround = plot1 and plot1:FindFirstChild("PlotGround")
    local plotCenter = plotGround and plotGround.Position or Vector3.new(0, 3, 0)

    -- Step 1: Open Design Mode via toggle button or direct call
    if not panel.Visible then
        -- Fire toggle
        panel.Visible = true
        cameraBar.Visible = true
        CameraController.Enable(plotCenter)
    end
    task.wait(0.3)

    local cam = workspace.CurrentCamera
    local initialCamType = tostring(cam.CameraType)
    local initialCamPos = cam.CFrame.Position
    local initialDist = (initialCamPos - plotCenter).Magnitude

    -- Step 2: Test 360 Orbit Camera Rotation
    CameraController.RotateRight(90)
    task.wait(0.2)
    local rot90CamPos = cam.CFrame.Position

    CameraController.RotateRight(90)
    task.wait(0.2)
    local rot180CamPos = cam.CFrame.Position

    -- Step 3: Test Zoom
    CameraController.ZoomIn(15)
    task.wait(0.2)
    local zoomedDist = (cam.CFrame.Position - plotCenter).Magnitude

    -- Step 4: Test Drag and Drop
    local promenade = plot1 and plot1:FindFirstChild("CommercialPromenade")
    local testShop = promenade and promenade:FindFirstChild("Shop_1")
    local initialShopPos = nil
    if testShop then
        local cf = testShop:GetBoundingBox()
        initialShopPos = { cf.Position.X, cf.Position.Y, cf.Position.Z }
    end

    -- Return comprehensive diagnostic report
    return game:GetService("HttpService"):JSONEncode({
        success = true,
        panelVisible = panel.Visible,
        cameraBarVisible = cameraBar.Visible,
        dragBannerFound = (dragBanner ~= nil),
        initialCamType = initialCamType,
        initialDist = math.round(initialDist),
        zoomedDist = math.round(zoomedDist),
        initialPos = { math.round(initialCamPos.X), math.round(initialCamPos.Y), math.round(initialCamPos.Z) },
        rot90Pos = { math.round(rot90CamPos.X), math.round(rot90CamPos.Y), math.round(rot90CamPos.Z) },
        rot180Pos = { math.round(rot180CamPos.X), math.round(rot180CamPos.Y), math.round(rot180CamPos.Z) },
        testShopFound = (testShop ~= nil),
        initialShopPos = initialShopPos
    })
    """

    print("Running Client Orbit and UI Verification...")
    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })
    output_text = res.get("content", [{}])[0].get("text", "")
    print("Test Result:\n", output_text)

    # Step 5: Screen capture top-down builder camera view
    print("Capturing 360 top-down builder camera view...")
    cam_info_code = """
    local cam = workspace.CurrentCamera
    return game:GetService("HttpService"):JSONEncode({
        pos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        look = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z }
    })
    """
    cam_res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": cam_info_code
    })
    cam_data = json.loads(cam_res.get("content", [{}])[0].get("text", "{}"))
    print("Camera data:", cam_data)

    c_pos = cam_data.get("pos", [0, 50, 60])
    c_look = cam_data.get("look", [0, -0.7, -0.7])
    target = [c_pos[0] + c_look[0]*50, c_pos[1] + c_look[1]*50, c_pos[2] + c_look[2]*50]

    cap = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "top_down_orbit_camera",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "top_down_orbit_camera.png"
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
