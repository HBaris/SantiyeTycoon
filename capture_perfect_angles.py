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

    # 1. Perspective from South looking North (Shows Entrance, Signboard Outside, Spawn Outside, Empty Plot, Road)
    set_cam1 = """
    local cam = workspace.CurrentCamera
    -- Stand south on the highway looking north towards plot
    local target = Vector3.new(0, 5, 10)
    local pos = Vector3.new(25, 38, 70)
    cam.CFrame = CFrame.lookAt(pos, target)
    return game:GetService("HttpService"):JSONEncode({ pos = {pos.X, pos.Y, pos.Z}, target = {target.X, target.Y, target.Z} })
    """
    res1 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": set_cam1})
    data1 = json.loads(res1.get("content", [{}])[0].get("text", "{}"))
    time.sleep(0.3)

    cap1 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "signs_outside_verified",
        "camera_position": data1.get("pos", [25, 38, 70]),
        "look_at_position": data1.get("target", [0, 5, 10])
    })
    for item in cap1.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("signs_outside_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("signs_outside_verified.png", os.path.join(artifact_dir, "signs_outside_verified.png"))
            print("Saved signs_outside_verified.png")
            break

    # 2. Katalog Tab Scrolled to Vehicles & Cargo
    scroll_katalog = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player.PlayerGui
    local hud = pg:WaitForChild("DevCustomizerHUD")
    local panel = hud:WaitForChild("CustomizerPanel")
    
    -- Open tab 3
    for _, ch in ipairs(panel:GetChildren()) do
        if ch.Name == "TabPage_3" then
            ch.Visible = true
            local catScroll = ch:FindFirstChildOfClass("ScrollingFrame")
            if catScroll then
                -- Scroll down to reveal Vehicles and Cargo
                catScroll.CanvasPosition = Vector2.new(0, 320)
            end
        elseif ch.Name:find("TabPage_") then
            ch.Visible = false
        end
    end

    local cam = workspace.CurrentCamera
    local pos = Vector3.new(-35, 75, 45)
    local target = Vector3.new(-20, 5, 0)
    cam.CFrame = CFrame.lookAt(pos, target)
    return game:GetService("HttpService"):JSONEncode({ pos = {pos.X, pos.Y, pos.Z}, target = {target.X, target.Y, target.Z} })
    """
    res2 = client.call_tool("execute_luau", {"studio_id": studio_id, "datamodel_type": "Client", "code": scroll_katalog})
    data2 = json.loads(res2.get("content", [{}])[0].get("text", "{}"))
    time.sleep(0.3)

    cap2 = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "katalog_vehicles_cargo_verified",
        "camera_position": data2.get("pos", [-35, 75, 45]),
        "look_at_position": data2.get("target", [-20, 5, 0])
    })
    for item in cap2.get("content", []):
        if item.get("type") == "image":
            img_bytes = base64.b64decode(item.get("data", ""))
            with open("katalog_vehicles_cargo_verified.png", "wb") as f:
                f.write(img_bytes)
            shutil.copyfile("katalog_vehicles_cargo_verified.png", os.path.join(artifact_dir, "katalog_vehicles_cargo_verified.png"))
            print("Saved katalog_vehicles_cargo_verified.png")
            break

    client.close()

if __name__ == "__main__":
    main()
