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

    # 1. Run client inspection Luau
    test_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local plotName = string.format("Plot_%s_1", player.Name)
    local plot = workspace:FindFirstChild(plotName)
    if not plot then
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name:find("Plot_") then
                plot = child
                break
            end
        end
    end
    if not plot then return HttpService:JSONEncode({ error = "NO_PLOT_FOUND" }) end

    -- Inspect Plot children
    local plotChildren = {}
    for _, ch in ipairs(plot:GetChildren()) do
        table.insert(plotChildren, { name = ch.Name, className = ch.ClassName })
    end

    -- Inspect ShowroomPalette
    local showroom = plot:FindFirstChild("ShowroomPalette")
    local showroomModels = {}
    if showroom then
        for _, ch in ipairs(showroom:GetChildren()) do
            if ch:IsA("Model") then
                local pivot = ch:GetPivot().Position
                table.insert(showroomModels, { name = ch.Name, pos = { X = math.round(pivot.X*10)/10, Y = math.round(pivot.Y*10)/10, Z = math.round(pivot.Z*10)/10 } })
            end
        end
    end

    -- Check UI
    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg and pg:FindFirstChild("DevCustomizerHUD")
    local toggleBtn = hud and hud:FindFirstChild("CustomizerToggleBtn")
    local panel = hud and hud:FindFirstChild("CustomizerPanel")
    local cameraBar = hud and hud:FindFirstChild("CameraControlBar")

    local toggleBtnPos = toggleBtn and {
        ScaleY = toggleBtn.Position.Y.Scale,
        OffsetY = toggleBtn.Position.Y.Offset
    } or nil

    -- Open Customizer and enable top-down camera
    local sps = player:WaitForChild("PlayerScripts", 5)
    local clientFolder = sps:WaitForChild("Client", 5)
    local camModule = clientFolder:WaitForChild("CustomizerCameraController", 5)
    local CameraController = require(camModule)

    local ground = plot:FindFirstChild("PlotGround")
    local groundPos = ground and ground.Position or Vector3.new(0, 4.4, 0)
    
    CameraController.Enable(groundPos)
    CameraController.RotateRight(45)

    if panel then panel.Visible = true end
    if cameraBar then cameraBar.Visible = true end

    local cam = workspace.CurrentCamera

    return HttpService:JSONEncode({
        plotName = plot.Name,
        plotChildren = plotChildren,
        showroomCount = #showroomModels,
        showroomModels = showroomModels,
        toggleBtnPos = toggleBtnPos,
        camPos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        camLook = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z },
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })

    raw_text = res.get("content", [{}])[0].get("text", "")
    print("Execution output:")
    res_data = {}
    try:
        res_data = json.loads(raw_text)
        print(json.dumps(res_data, indent=2, ensure_ascii=False))
    except Exception:
        print(raw_text)

    time.sleep(1)

    c_pos = res_data.get("camPos", [-40, 60, 40])
    c_look = res_data.get("camLook", [0.6, -0.6, -0.6])
    target = [c_pos[0] + c_look[0]*60, c_pos[1] + c_look[1]*60, c_pos[2] + c_look[2]*60]

    # 2. Capture screenshot
    print("\nCapturing screenshot of empty plot with showroom palette...")
    capture_res = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "empty_plot_palette_verified",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "empty_plot_palette_verified.png"
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
