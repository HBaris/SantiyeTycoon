import time
import json
import os
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    time.sleep(3)
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. Update slots via client network
    script_1 = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER" end

    local Network = require(ReplicatedStorage.Shared.Network)
    
    -- Assign shops to all 6 slots
    Network.ChangePromenadeSlotEvent:FireServer(1, 1, "Bakery")
    Network.ChangePromenadeSlotEvent:FireServer(1, 2, "Market")
    Network.ChangePromenadeSlotEvent:FireServer(1, 3, "Fountain")
    Network.ChangePromenadeSlotEvent:FireServer(1, 4, "Barber")
    Network.ChangePromenadeSlotEvent:FireServer(1, 5, "PetShop")
    Network.ChangePromenadeSlotEvent:FireServer(1, 6, "Restaurant")
    
    return "SLOTS_ASSIGNED"
    """
    res1 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": script_1
    })
    print("Slots assignment:", res1.get("content", [{}])[0].get("text", ""))

    # Wait for debounced rebuild to complete
    time.sleep(1.5)

    # 2. Open Customizer UI, select Fountain, and position camera nicely
    script_2 = """
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

    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
        local plotOrigin = (plot and plot:FindFirstChild("PlotGround") and plot.PlotGround.Position) or Vector3.new(0, 4.4, 0)
        -- Place player on the road, facing diagonally towards the promenade shops and building
        hrp.CFrame = CFrame.new(plotOrigin.X - 12, plotOrigin.Y + 4, plotOrigin.Z + 36) * CFrame.Angles(0, math.rad(150), 0)
    end

    -- Return promenade info
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    local count = prom and #prom:GetChildren() or 0
    return "UI_READY_SHOPS_" .. tostring(count)
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": script_2
    })
    print("UI & Viewport Setup:", res2.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
