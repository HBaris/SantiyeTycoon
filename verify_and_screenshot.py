import time
import json
import os
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. Setup scene: ensure promenade is built, open UI, select a model
    setup_code = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER" end

    local Network = require(ReplicatedStorage.Shared.Network)
    
    -- Ensure promenade is populated with diverse shops
    Network.ChangePromenadeSlotEvent:FireServer(1, 1, "Bakery")
    Network.ChangePromenadeSlotEvent:FireServer(1, 2, "Market")
    Network.ChangePromenadeSlotEvent:FireServer(1, 3, "Fountain")
    Network.ChangePromenadeSlotEvent:FireServer(1, 4, "Barber")
    Network.ChangePromenadeSlotEvent:FireServer(1, 5, "PetShop")
    Network.ChangePromenadeSlotEvent:FireServer(1, 6, "Restaurant")
    
    return "SLOTS_REQUESTED"
    """
    res1 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": setup_code
    })
    print("Setup Result:", res1.get("content", [{}])[0].get("text", ""))

    time.sleep(2.5)

    # 2. On Client: open Tasarım Motoru panel and select Shop_Slot1_Bakery
    open_ui_code = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return "NO_PG" end

    local hud = pg:FindFirstChild("DevCustomizerHUD")
    if not hud then return "NO_HUD" end

    local panel = hud:FindFirstChild("CustomizerPanel")
    if panel then
        panel.Visible = true
    end

    -- Update selection to Shop_Slot1_Bakery or Fountain
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    local fountain = prom and prom:FindFirstChild("Shop_Slot3_Fountain")
    local bakery = prom and prom:FindFirstChild("Shop_Slot1_Bakery")
    
    -- Position player camera / character to look at the promenade and customizer UI
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        -- Place player on the road facing the promenade and building
        local plotOrigin = (plot and plot:FindFirstChild("PlotGround") and plot.PlotGround.Position) or Vector3.new(0, 4.4, 0)
        hrp.CFrame = CFrame.new(plotOrigin.X - 10, plotOrigin.Y + 4, plotOrigin.Z + 30) * CFrame.Angles(0, math.rad(140), 0)
    end

    return "UI_OPENED_AND_POSITIONED"
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": open_ui_code
    })
    print("Open UI Result:", res2.get("content", [{}])[0].get("text", ""))

    time.sleep(1.5)

    # 3. Test scaling Shop_Slot1_Bakery by 1.25x
    scale_code = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players:GetPlayers()[1]
    local Network = require(ReplicatedStorage.Shared.Network)

    Network.CustomizeModelEvent:FireServer(1, "Shop_Slot1_Bakery", "Scale", 1.25)
    return "SCALED_SLOT1"
    """
    res3 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": scale_code
    })
    print("Scale Result:", res3.get("content", [{}])[0].get("text", ""))

    time.sleep(2)

    # 4. Verify model bounds and ground alignment
    verify_code = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    
    local details = {}
    if prom then
        for _, c in ipairs(prom:GetChildren()) do
            if c:IsA("Model") then
                local cf, sz = c:GetBoundingBox()
                table.insert(details, {
                    name = c.Name,
                    size = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)},
                    minY = math.round(cf.Position.Y - sz.Y / 2)
                })
            end
        end
    end
    return game:GetService("HttpService"):JSONEncode(details)
    """
    res4 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": verify_code
    })
    print("Verification Details:", res4.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
