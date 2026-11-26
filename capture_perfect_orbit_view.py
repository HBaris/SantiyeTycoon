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

    # 1. Run Client Luau to set the orbit camera and silence HUD
    test_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = hud:WaitForChild("CameraControlBar", 5)

    panel.Visible = true
    cameraBar.Visible = true

    -- Silence all gameplay HUDs
    for _, name in ipairs({ "BuilderHUD", "UpgradeUI", "GarageUI" }) do
        local g = pg:FindFirstChild(name)
        if g and g:IsA("ScreenGui") then
            g.Enabled = false
        end
    end

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)
    local ground = plot and plot:FindFirstChild("PlotGround")
    local groundPos = ground and ground.Position or Vector3.new(0, 4.4, 0)

    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    CameraController.Enable(groundPos)
    -- Zoom out slightly and rotate to see the empty plot and the full showroom palette
    CameraController.ZoomOut(16)
    CameraController.RotateLeft(45)

    -- Wait for camera render loop to update
    for _ = 1, 10 do
        RunService.RenderStepped:Wait()
    end
    task.wait(0.3)

    local cam = workspace.CurrentCamera
    return HttpService:JSONEncode({
        success = true,
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
        print(json.dumps(res_data, indent=2, ensure_ascii=False))
    except Exception:
        print(raw_text)

    time.sleep(0.5)

    c_pos = res_data.get("camPos")
    c_look = res_data.get("camLook")
    g_pos = res_data.get("groundPos", [0, 4.4, 0])

    if not c_pos:
        c_pos = [-60, 65, 45]
        target = [g_pos[0], g_pos[1] + 2, g_pos[2]]
    else:
        target = [c_pos[0] + c_look[0]*80, c_pos[1] + c_look[1]*80, c_pos[2] + c_look[2]*80]

    # 2. Capture screenshot
    print("\nCapturing top-down 360 orbit view of plot and showroom...")
    capture_res = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "empty_plot_and_showroom_orbit",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "empty_plot_and_showroom_orbit.png"
    captured = False
    for item in capture_res.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open(img_path, "wb") as f:
                f.write(img_bytes)
            print(f"Saved {img_path} ({len(img_bytes)} bytes)")

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
