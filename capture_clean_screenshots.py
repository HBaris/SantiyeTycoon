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

    artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"

    # =========================================================================
    # STEP 1: Enable Customizer, Select Forklift, Ensure Orbit Camera
    # =========================================================================
    setup_code = """
    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player:WaitForChild("PlayerGui", 5)
    local devHud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = devHud:WaitForChild("CustomizerPanel", 5)
    local cameraBar = devHud:WaitForChild("CameraControlBar", 5)
    local CustomizerCameraController = require(devHud:WaitForChild("CustomizerCameraController"))

    panel.Visible = true
    cameraBar.Visible = true
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)

    local plotName = string.format("Plot_%s_1", player.Name)
    local plotFolder = workspace:FindFirstChild(plotName)
    local ground = plotFolder and plotFolder:FindFirstChild("PlotGround")
    local origin = ground and ground.Position or Vector3.new(0, 4.4, 0)

    -- Enable Orbit camera
    CustomizerCameraController.Enable(origin)

    -- Select the spawned Custom_Forklift
    local targetModel = nil
    for _, ch in ipairs(plotFolder:GetChildren()) do
        if ch:IsA("Model") and ch.Name:find("Custom_Forklift") then
            targetModel = ch
            break
        end
    end

    -- If not found, pick any model
    if not targetModel then
        for _, ch in ipairs(plotFolder:GetChildren()) do
            if ch:IsA("Model") then targetModel = ch break end
        end
    end

    if targetModel then
        -- Trigger selection via Click or highlight
        local hl = devHud:FindFirstChild("DevHighlight") or Instance.new("Highlight")
        hl.Name = "DevHighlight"
        hl.Adornee = targetModel
        hl.FillColor = Color3.fromRGB(255, 220, 40)
        hl.FillTransparency = 0.7
        hl.OutlineColor = Color3.fromRGB(255, 240, 100)
        hl.Parent = devHud

        local infoCard = panel:FindFirstChild("TabPage_1") and panel.TabPage_1:FindFirstChild("Frame")
        if infoCard then
            local l1 = infoCard:FindFirstChildWhichIsA("TextLabel")
            local cf, sz = targetModel:GetBoundingBox()
            if l1 then l1.Text = "Seçili: " .. targetModel.Name end
        end
    end

    return "SETUP_DONE"
    """
    res = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": setup_code})
    print("Setup result:", res.get("content", [{}])[0].get("text", ""))

    time.sleep(1.5)

    # Capture View 1: Level Creator UI + Top Down Scene
    cap1 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "level_creator_ui_verified"
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("level_creator_ui_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("level_creator_ui_verified.png", os.path.join(artifact_dir, "level_creator_ui_verified.png"))
            print("Saved level_creator_ui_verified.png successfully")
            break

    # =========================================================================
    # STEP 2: Position Camera to View Relocated Garage & Logistics Depot Across Highway
    # =========================================================================
    garage_cam_code = """
    local Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Scriptable
    
    local garage = workspace:FindFirstChild("GarageFacility")
    local floor = garage and garage:FindFirstChild("GarageDepotFloor")
    local floorPos = floor and floor.Position or Vector3.new(15, 4.2, 105)

    -- Look at the garage from the highway / plot entrance perspective
    Camera.CFrame = CFrame.lookAt(Vector3.new(15, 28, 45), floorPos)
    return "GARAGE_CAM_SET"
    """
    client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": garage_cam_code})
    time.sleep(1.5)

    cap2 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "garage_relocated_verified"
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("garage_relocated_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("garage_relocated_verified.png", os.path.join(artifact_dir, "garage_relocated_verified.png"))
            print("Saved garage_relocated_verified.png successfully")
            break

if __name__ == "__main__":
    main()
