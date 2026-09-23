import time
import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connecting to Studio ID:", studio_id)

    # 1. Verify HUD isolation & UI cards
    test_ui_code = """
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local pg = player:WaitForChild("PlayerGui", 10)
    local devHud = pg:WaitForChild("DevCustomizerHUD", 10)
    local cityHud = pg:FindFirstChild("CityStatsHUD") or pg:FindFirstChild("CityStatsUI")
    local upgradeHud = pg:FindFirstChild("UpgradeScreen") or pg:FindFirstChild("UpgradeHUD")
    
    local panel = devHud:WaitForChild("CustomizerPanel", 5)
    
    -- Simulate opening panel
    panel.Visible = true
    
    -- Check other HUD visibilities
    local cityVisible = cityHud and cityHud.Enabled
    local page1 = panel:WaitForChild("TabPage_1", 5)
    local scroll = page1:WaitForChild("Page1Scroll", 5)
    
    local cardNames = {}
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(cardNames, child.Name)
        end
    end
    
    -- Check coordinate boxes
    local boxCount = 0
    for _, d in ipairs(scroll:GetDescendants()) do
        if d:IsA("TextBox") then
            boxCount = boxCount + 1
        end
    end
    
    return game:GetService("HttpService"):JSONEncode({
        panelOpen = panel.Visible,
        cards = #cardNames,
        textBoxes = boxCount,
        cardList = cardNames
    })
    """

    res_ui = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_ui_code
    })
    print("1. UI Structure & Cards Test:", res_ui.get("content", [{}])[0].get("text", ""))

    # 2. Test Spawning an asset, setting exact coordinates, snapping to ground, scaling, and rotating
    test_model_operations = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = game:GetService("Workspace")
    local player = Players.LocalPlayer or Players:GetPlayers()[1]
    local Network = require(ReplicatedStorage.Shared.Network)

    local plotFolder = Workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    if not plotFolder then return "ERROR: NO_PLOT" end

    -- Spawn a SiteContainer for full testing
    Network.SpawnAssetOnPlotEvent:FireServer(1, "Cargo", "SiteContainer")
    task.wait(0.8)

    local targetModel = nil
    for _, child in ipairs(plotFolder:GetChildren()) do
        if child:IsA("Model") and child.Name:find("SiteContainer") then
            targetModel = child
            break
        end
    end
    if not targetModel then return "ERROR: SPAWN_FAILED" end

    -- A. Direct SetPosition
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "SetPosition", {
        X = 25.0,
        Y = 10.0,
        Z = -20.0,
        Yaw = 45
    })
    task.wait(0.4)
    local pPos = targetModel:GetPivot().Position
    local posSuccess = (math.abs(pPos.X - 25.0) < 0.5 and math.abs(pPos.Z - (-20.0)) < 0.5)

    -- B. Scale test (1.5x)
    local _, bSizeBefore = targetModel:GetBoundingBox()
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "Scale", 1.5)
    task.wait(0.4)
    local _, bSizeAfter = targetModel:GetBoundingBox()
    local scaleSuccess = (bSizeAfter.X > bSizeBefore.X)

    -- C. Snap to ground
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "SnapGround")
    task.wait(0.4)
    local gPos = targetModel:GetPivot().Position
    local snapSuccess = (gPos.Y < 10.0)

    -- D. Delete the test object
    Network.CustomizeModelEvent:FireServer(1, targetModel.Name, "Delete")
    task.wait(0.3)
    local deleted = (targetModel.Parent == nil)

    return game:GetService("HttpService"):JSONEncode({
        target = targetModel.Name,
        posSuccess = posSuccess,
        finalPos = {math.round(pPos.X), math.round(pPos.Y), math.round(pPos.Z)},
        scaleSuccess = scaleSuccess,
        snapSuccess = snapSuccess,
        groundY = math.round(gPos.Y),
        deletedCleanly = deleted
    })
    """

    res_op = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_model_operations
    })
    print("2. Model Operations Test (Coords, Scale, Snap, Delete):", res_op.get("content", [{}])[0].get("text", ""))

    # 3. Check Garage position and ensure no rogue forklift
    test_env_code = """
    local Workspace = game:GetService("Workspace")
    local garage = Workspace:FindFirstChild("GarageEnvironment")
    local depot = garage and garage:FindFirstChild("CentralCargoDepot")
    local depotPos = depot and depot.Position
    
    local forkliftFound = false
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d.Name:lower():find("forklift") then
            forkliftFound = true
            break
        end
    end

    return game:GetService("HttpService"):JSONEncode({
        garageFound = (garage ~= nil),
        depotPosition = depotPos and {math.round(depotPos.X), math.round(depotPos.Y), math.round(depotPos.Z)},
        forkliftPresent = forkliftFound
    })
    """

    res_env = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_env_code
    })
    print("3. Environment & Isolation Check:", res_env.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
