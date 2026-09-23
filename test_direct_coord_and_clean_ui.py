import time
import json
import base64
import os
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. UI Structure check & open Customizer
    test_luau = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    if not player then return "ERROR: NO_PLAYER" end

    local pg = player:WaitForChild("PlayerGui", 10)
    local hud = pg:WaitForChild("DevCustomizerHUD", 10)
    if not hud then return "ERROR: NO_HUD" end

    local panel = hud:WaitForChild("CustomizerPanel", 5)
    local toggleBtn = hud:WaitForChild("CustomizerToggleBtn", 5)

    -- Open the panel
    if not panel.Visible then
        panel.Visible = true
        hud.CameraControlBar.Visible = true
    end

    local page1 = panel:WaitForChild("TabPage_1", 5)
    local scroll = page1:WaitForChild("Page1Scroll", 5)
    
    local cards = {}
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(cards, child.Name)
        end
    end

    local boxX, boxY, boxZ = nil, nil, nil
    local goBtn = nil
    local groundBtn = nil
    local stepBtn = nil
    for _, d in ipairs(scroll:GetDescendants()) do
        if d:IsA("TextBox") then
            local p = d.Position.X.Scale
            if p < 0.2 then boxX = d
            elseif p < 0.5 then boxY = d
            else boxZ = d end
        end
        if d:IsA("TextButton") then
            if d.Text:find("Koordinata Git") then goBtn = d end
            if d.Text:find("Zemine İndir") then groundBtn = d end
            if d.Text:find("Adım:") then stepBtn = d end
        end
    end

    return string.format("UI_CHECK_OK | cards=%d | boxX=%s, boxY=%s, boxZ=%s | goBtn=%s | groundBtn=%s | stepBtn=%s",
        #cards,
        tostring(boxX ~= nil), tostring(boxY ~= nil), tostring(boxZ ~= nil),
        tostring(goBtn ~= nil), tostring(groundBtn ~= nil), tostring(stepBtn ~= nil)
    )
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_luau
    })
    print("UI Structure check:", res.get("content", [{}])[0].get("text", ""))

    # 2. Test spawning a container model and applying direct coordinates
    coord_test_luau = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local Network = require(ReplicatedStorage.Shared.Network)

    local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    if not plotFolder then return "ERROR: NO_PLOT" end

    -- Spawn a SiteContainer for direct coordinate testing
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Cargo", "SiteContainer")
    task.wait(1.0)

    local targetModel = nil
    for _, child in ipairs(plotFolder:GetChildren()) do
        if child:IsA("Model") and child.Name:find("SiteContainer") then
            targetModel = child
            break
        end
    end

    if not targetModel then
        return "ERROR: SPAWN_FAILED"
    end

    local initialPos = targetModel:GetPivot().Position

    -- Test moving to exact coordinates X = 20.0, Y = 6.0, Z = -15.0
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "SetPosition", {
        X = 20.0,
        Y = 6.0,
        Z = -15.0
    })
    task.wait(0.5)

    local newPos = targetModel:GetPivot().Position
    local diffX = math.abs(newPos.X - 20.0)
    local diffY = math.abs(newPos.Y - 6.0)
    local diffZ = math.abs(newPos.Z - (-15.0))

    local passCoord = (diffX < 0.2 and diffY < 0.2 and diffZ < 0.2)

    -- Test SnapGround
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "SnapGround")
    task.wait(0.4)
    local groundPos = targetModel:GetPivot().Position

    return string.format("COORD_TEST_OK | target=%s | initial=(%.1f,%.1f,%.1f) | newPos=(%.1f,%.1f,%.1f) | passCoord=%s | groundY=%.1f",
        targetModel.Name,
        initialPos.X, initialPos.Y, initialPos.Z,
        newPos.X, newPos.Y, newPos.Z,
        tostring(passCoord), groundPos.Y
    )
    """

    res2 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": coord_test_luau
    })
    print("Direct Coordinate Test:", res2.get("content", [{}])[0].get("text", ""))

    # 3. Capture screenshots
    time.sleep(0.5)
    artifact_dir = r"C:\Users\Monster\.gemini\antigravity\brain\03546efd-d2fd-4681-99a5-598800761051"
    os.makedirs(artifact_dir, exist_ok=True)

    # Screenshot focused on the clean UI panel
    print("Capturing level_creator_clean_ui.png...")
    shot_res = client.call_tool("screen_capture", {
        "studio_id": studio_id,
        "camera_position": [-10, 35, 60],
        "look_at_position": [0, 6, 0]
    })
    shot_data = shot_res.get("content", [{}])[0].get("text", "")
    if shot_data:
        raw_b64 = shot_data.split(",")[-1] if "," in shot_data else shot_data
        img_bytes = base64.b64decode(raw_b64)
        out_path = os.path.join(artifact_dir, "level_creator_clean_ui.png")
        with open(out_path, "wb") as f:
            f.write(img_bytes)
        print("Saved UI screenshot to:", out_path)

    client.close()

if __name__ == "__main__":
    main()
