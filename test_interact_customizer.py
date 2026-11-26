import time
import json
from roblox_mcp_client import RobloxStudioMCPClient

def main():
    client = RobloxStudioMCPClient()
    studio_id = client.get_studio_id()
    print("Connected Studio ID:", studio_id)

    # 1. On Client: open Customizer UI, select Slot 1 as Bakery, Slot 2 as Market
    test_code = """
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players:GetPlayers()[1]
    if not player then return "NO_PLAYER" end

    local Network = require(ReplicatedStorage.Shared.Network)
    
    -- Change Slot 1 to Bakery, Slot 2 to Market, Slot 3 to Fountain
    Network.ChangePromenadeSlotEvent:FireServer(1, 1, "Bakery")
    Network.ChangePromenadeSlotEvent:FireServer(1, 2, "Market")
    Network.ChangePromenadeSlotEvent:FireServer(1, 3, "Fountain")
    
    -- Open Customizer UI
    local pg = player:FindFirstChild("PlayerGui")
    if pg then
        local hud = pg:FindFirstChild("DevCustomizerHUD")
        if hud then
            local panel = hud:FindFirstChild("CustomizerPanel")
            if panel then
                panel.Visible = true
            end
        end
    end
    
    return "COMMANDS_SENT"
    """

    res = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": test_code
    })
    print("Test Code Result:", res.get("content", [{}])[0].get("text", ""))

    # Wait 2 seconds for server to process and rebuild promenade
    time.sleep(2.5)

    # 2. Check Promenade on Client
    verify_code = """
    local Players = game:GetService("Players")
    local player = Players:GetPlayers()[1]
    local plot = workspace:FindFirstChild(string.format("Plot_%s_1", player.Name))
    local prom = plot and plot:FindFirstChild("CommercialPromenade")
    
    local shops = {}
    if prom then
        for _, child in ipairs(prom:GetChildren()) do
            if child:IsA("Model") then
                local cf, sz = child:GetBoundingBox()
                table.insert(shops, {
                    name = child.Name,
                    size = {math.round(sz.X), math.round(sz.Y), math.round(sz.Z)},
                    pos = {math.round(cf.Position.X), math.round(cf.Position.Y), math.round(cf.Position.Z)}
                })
            end
        end
    end
    
    return game:GetService("HttpService"):JSONEncode({
        promenadeFound = prom ~= nil,
        shopCount = #shops,
        shops = shops
    })
    """
    res2 = client.call_tool("execute_luau", {
        "studio_id": studio_id,
        "datamodel_type": "Client",
        "code": verify_code
    })
    print("Verify Result:", res2.get("content", [{}])[0].get("text", ""))

    client.close()

if __name__ == "__main__":
    main()
