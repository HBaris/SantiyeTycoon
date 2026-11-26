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

    # 1. Switch to Tab 3 (Katalog)
    test_code = """
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return HttpService:JSONEncode({ error = "NO_PLAYER" }) end

    local pg = player:WaitForChild("PlayerGui", 5)
    local hud = pg:WaitForChild("DevCustomizerHUD", 5)
    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local tabBar = panel:WaitForChild("TabBar", 5)

    -- TabButtons: 1 is Model Incele, 2 is Carsi, 3 is Katalog
    local tabButtons = {}
    for _, ch in ipairs(tabBar:GetChildren()) do
        if ch:IsA("TextButton") then
            table.insert(tabButtons, ch)
        end
    end

    -- TabPages
    local tabPages = {}
    for _, ch in ipairs(panel:GetChildren()) do
        if ch.Name:find("TabPage_") then
            table.insert(tabPages, ch)
        end
    end
    table.sort(tabPages, function(a, b) return a.Name < b.Name end)

    -- Switch to Tab 3
    for i, p in ipairs(tabPages) do
        p.Visible = (i == 3)
    end
    for i, b in ipairs(tabButtons) do
        b.BackgroundColor3 = (b.Text:find("Katalog")) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(25, 28, 35)
        b.TextColor3 = (b.Text:find("Katalog")) and Color3.fromRGB(255, 225, 80) or Color3.fromRGB(180, 185, 195)
    end

    local cam = workspace.CurrentCamera
    return HttpService:JSONEncode({
        success = true,
        camPos = { cam.CFrame.Position.X, cam.CFrame.Position.Y, cam.CFrame.Position.Z },
        camLook = { cam.CFrame.LookVector.X, cam.CFrame.LookVector.Y, cam.CFrame.LookVector.Z },
    })
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })

    raw_text = res.get("content", [{}])[0].get("text", "{}")
    print("Execution output:", raw_text)
    res_data = json.loads(raw_text)

    time.sleep(0.5)

    c_pos = res_data.get("camPos", [-37, 81, 37])
    c_look = res_data.get("camLook", [0.4, -0.8, -0.4])
    target = [c_pos[0] + c_look[0]*80, c_pos[1] + c_look[1]*80, c_pos[2] + c_look[2]*80]

    # 2. Capture screenshot
    print("\nCapturing Katalog Tab view...")
    capture_res = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "capture_id": "catalog_10_levels_verified",
        "camera_position": [float(c_pos[0]), float(c_pos[1]), float(c_pos[2])],
        "look_at_position": [float(target[0]), float(target[1]), float(target[2])]
    })

    img_path = "catalog_10_levels_verified.png"
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
            break

    client.close()

if __name__ == "__main__":
    main()
